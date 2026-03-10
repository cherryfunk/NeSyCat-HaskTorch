#!/usr/bin/env python3
"""Binary MLP Baseline: same architecture as LTN/NeSyCat (2->16->16->1, ELU, sigmoid),
trained with pure BCE loss. 10 independent runs x 1000 epochs."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from metrics.metrics import evaluate_metrics, aggregate, print_summary

import torch
import torch.nn as nn
import numpy as np
import time

N_RUNS = 10
N_EPOCHS = 1000
LR = 0.001

class ModelA(nn.Module):
    def __init__(self):
        super().__init__()
        self.layer1 = nn.Linear(2, 16)
        self.layer2 = nn.Linear(16, 16)
        self.layer3 = nn.Linear(16, 1)
        self.elu = nn.ELU()

    def forward(self, x):
        x = self.elu(self.layer1(x))
        x = self.elu(self.layer2(x))
        return torch.sigmoid(self.layer3(x))

all_ms, all_metrics = [], []

for run in range(N_RUNS):
    dataset = torch.rand((100, 2))
    labels  = (torch.sum((dataset - 0.5)**2, dim=1) < 0.09).float()
    train_data, train_labels = dataset[:50], labels[:50]
    test_data,  test_labels  = dataset[50:], labels[50:]

    model     = ModelA()
    optimizer = torch.optim.Adam(model.parameters(), lr=LR)
    criterion = nn.BCELoss()

    t0 = time.time()
    for _ in range(N_EPOCHS):
        optimizer.zero_grad()
        loss = criterion(model(train_data).squeeze(), train_labels)
        loss.backward()
        optimizer.step()
    ms_per_epoch = (time.time() - t0) * 1000.0 / N_EPOCHS

    with torch.no_grad():
        m = evaluate_metrics(
            model(train_data).squeeze().numpy(), train_labels.numpy(),
            model(test_data ).squeeze().numpy(), test_labels.numpy())

    all_ms.append(ms_per_epoch)
    all_metrics.append(m)
    print(f"[Run {run+1:2d}] {ms_per_epoch:.4f} ms/epoch | "
          f"TrainAcc={m['train_acc']:.4f} TestAcc={m['test_acc']:.4f} "
          f"F1={m['f1']:.4f} P+={m['p_pos']:.4f} P-={m['p_neg']:.4f}")

agg = aggregate(all_metrics)
print_summary("MLP BASELINE", N_RUNS, N_EPOCHS, agg,
              float(np.mean(all_ms)), float(np.std(all_ms)))
print(f"\nRESULT_LINE: MLP Baseline | BCE | {np.mean(all_ms):.4f}+/-{np.std(all_ms):.4f}ms"
      f" | TrainAcc={agg['train_acc_mean']:.4f} TestAcc={agg['test_acc_mean']:.4f}"
      f" F1={agg['f1_mean']:.4f} P+={agg['p_pos_mean']:.4f} P-={agg['p_neg_mean']:.4f}")
