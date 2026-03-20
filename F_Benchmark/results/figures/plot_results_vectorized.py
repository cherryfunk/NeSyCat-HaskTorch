import re
import ast
import matplotlib.pyplot as plt
import numpy as np

with open('benchmark/binary_results_vectorized.txt', 'r') as f:
    text = f.read()

epochs = []
train_acc = []
test_acc = []
losses = []

for line in text.split('\n'):
    line = line.strip()
    match = re.search(r'\[Epoch\s+(\d+)/1000\] Loss = ([\d.]+) \| Train Acc = ([\d.]+) \| Test Acc = ([\d.]+)', line)
    if match:
        epochs.append(int(match.group(1)))
        losses.append(float(match.group(2)))
        train_acc.append(float(match.group(3)))
        test_acc.append(float(match.group(4)))

plt.figure(figsize=(10, 5))
plt.subplot(1, 2, 1)
plt.plot(epochs, losses, label='Loss')
plt.title('Training Loss (Batched Grid Integr.)')
plt.xlabel('Epoch')

plt.subplot(1, 2, 2)
plt.plot(epochs, train_acc, label='Train Acc')
plt.plot(epochs, test_acc, label='Test Acc')
plt.title('Accuracy (Batched Grid Integr.)')
plt.xlabel('Epoch')
plt.legend()
plt.tight_layout()
plt.savefig('benchmark/binary_learning_curve_vectorized.png')
print("Successfully saved benchmark/binary_learning_curve_vectorized.png")
