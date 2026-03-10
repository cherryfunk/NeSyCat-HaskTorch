"""
E_Benchmark/metrics/metrics.py
Shared Python metrics module for binary classification benchmarks.
Mirrors the Haskell E_Benchmark/metrics/Metrics.hs interface.
"""
import numpy as np
from sklearn.metrics import accuracy_score, f1_score


def evaluate_metrics(train_probs, train_labels, test_probs, test_labels):
    """
    Evaluate binary classification metrics.
    All arrays: 1-D numpy float arrays (probs in [0,1], labels in {0,1}).
    Returns a dict with keys: train_acc, test_acc, f1, p_pos, p_neg.
    """
    train_preds = (train_probs > 0.5).astype(float)
    test_preds  = (test_probs  > 0.5).astype(float)
    tl  = train_labels.astype(float)
    tel = test_labels.astype(float)

    train_acc = accuracy_score(tl,  train_preds)
    test_acc  = accuracy_score(tel, test_preds)

    all_probs  = np.concatenate([train_probs, test_probs])
    all_labels = np.concatenate([tl, tel])
    all_preds  = (all_probs > 0.5).astype(float)

    f1   = f1_score(all_labels, all_preds, zero_division=0)
    p_pos = float(all_probs[all_labels == 1].mean()) if (all_labels == 1).any() else 0.0
    p_neg = float(all_probs[all_labels == 0].mean()) if (all_labels == 0).any() else 0.0

    return dict(train_acc=train_acc, test_acc=test_acc, f1=f1, p_pos=p_pos, p_neg=p_neg)


def print_metrics(metrics: dict):
    """Print metrics in the same format as the Haskell Metrics.hs."""
    print("Final Evaluation Metrics:")
    print(f"  Accuracy: Train={metrics['train_acc']:.4f}, Test={metrics['test_acc']:.4f}")
    print(f"  Mean Confidence: P+={metrics['p_pos']:.4f}, P-={metrics['p_neg']:.4f}")
    print(f"  F1 Score: {metrics['f1']:.4f}")


def aggregate(runs: list[dict]):
    """
    Aggregate a list of per-run metric dicts into mean ± std.
    Returns a dict with keys  <metric>_mean  and  <metric>_std.
    """
    keys = runs[0].keys()
    result = {}
    for k in keys:
        vals = [r[k] for r in runs]
        result[f"{k}_mean"] = float(np.mean(vals))
        result[f"{k}_std"]  = float(np.std(vals))
    return result


def print_summary(name: str, n_runs: int, n_epochs: int,
                  agg: dict, speed_mean: float, speed_std: float,
                  sat_mean=None, sat_std=None):
    """Print an aggregated summary block."""
    print(f"\n=== {name} SUMMARY ({n_runs} runs x {n_epochs} epochs) ===")
    print(f"Speed:    {speed_mean:.4f} +/- {speed_std:.4f} ms/epoch")
    if sat_mean is not None:
        print(f"Sat:      {sat_mean:.4f} +/- {sat_std:.4f}")
    print(f"TrainAcc: {agg['train_acc_mean']:.4f} +/- {agg['train_acc_std']:.4f}")
    print(f"TestAcc:  {agg['test_acc_mean']:.4f} +/- {agg['test_acc_std']:.4f}")
    print(f"F1:       {agg['f1_mean']:.4f} +/- {agg['f1_std']:.4f}")
    print(f"P+:       {agg['p_pos_mean']:.4f} +/- {agg['p_pos_std']:.4f}")
    print(f"P-:       {agg['p_neg_mean']:.4f} +/- {agg['p_neg_std']:.4f}")
