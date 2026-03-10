#!/usr/bin/env python3
"""LTNtorch fair benchmark: 10 runs x 1000 epochs, total wall-clock / 1000 epochs."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "nesy_approaches/LTNtorch_reference"))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "nesy_approaches/LTNtorch_reference/venv/lib/python3.9/site-packages"))
from metrics.metrics import evaluate_metrics, aggregate, print_summary

import torch, ltn, numpy as np, time

N_RUNS = 10; N_EPOCHS = 1000; LR = 0.001

class ModelA(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.layer1 = torch.nn.Linear(2, 16)
        self.layer2 = torch.nn.Linear(16, 16)
        self.layer3 = torch.nn.Linear(16, 1)
        self.elu    = torch.nn.ELU()
    def forward(self, x):
        x = self.elu(self.layer1(x)); x = self.elu(self.layer2(x))
        return torch.sigmoid(self.layer3(x))

Not    = ltn.Connective(ltn.fuzzy_ops.NotStandard())
Forall = ltn.Quantifier(ltn.fuzzy_ops.AggregPMeanError(p=2), quantifier="f")
SatAgg = ltn.fuzzy_ops.SatAgg()

all_ms, all_metrics, all_sat = [], [], []

for run in range(N_RUNS):
    dataset = torch.rand((100, 2))
    lb = torch.sum((dataset - 0.5)**2, dim=1) < 0.09
    lf = lb.float()
    train_data, test_data = dataset[:50], dataset[50:]
    train_lb, test_lb     = lb[:50], lb[50:]
    train_lf, test_lf     = lf[:50], lf[50:]

    A         = ltn.Predicate(ModelA())
    optimizer = torch.optim.Adam(A.parameters(), lr=LR)

    t0 = time.time()
    for _ in range(N_EPOCHS):
        optimizer.zero_grad()
        sat  = SatAgg(Forall(ltn.Variable("x_A",     train_data[train_lb]),    A(ltn.Variable("x_A",     train_data[train_lb]))),
                      Forall(ltn.Variable("x_not_A", train_data[~train_lb]), Not(A(ltn.Variable("x_not_A", train_data[~train_lb])))))
        (1. - sat).backward()
        optimizer.step()
    ms_per_epoch = (time.time() - t0) * 1000.0 / N_EPOCHS

    with torch.no_grad():
        final_sat = float(SatAgg(
            Forall(ltn.Variable("x_A",     train_data[train_lb]),    A(ltn.Variable("x_A",     train_data[train_lb]))),
            Forall(ltn.Variable("x_not_A", train_data[~train_lb]), Not(A(ltn.Variable("x_not_A", train_data[~train_lb]))))
        ).detach())
        m = evaluate_metrics(
            A.model(train_data).squeeze().numpy(), train_lf.numpy(),
            A.model(test_data ).squeeze().numpy(), test_lf.numpy())

    all_ms.append(ms_per_epoch); all_metrics.append(m); all_sat.append(final_sat)
    print(f"[Run {run+1:2d}] {ms_per_epoch:.4f} ms/epoch | Sat={final_sat:.4f} "
          f"TrainAcc={m['train_acc']:.4f} TestAcc={m['test_acc']:.4f} "
          f"F1={m['f1']:.4f} P+={m['p_pos']:.4f} P-={m['p_neg']:.4f}")

agg = aggregate(all_metrics)
print_summary("LTNTORCH 2-ME", N_RUNS, N_EPOCHS, agg,
              float(np.mean(all_ms)), float(np.std(all_ms)),
              float(np.mean(all_sat)), float(np.std(all_sat)))
