#!/usr/bin/env python3
"""
E_Benchmark/aggregate_to_csv.py
Parse all raw benchmark output files and generate a clean CSV summary table.
Also saves a pandas-friendly CSV in results/tables/binary_benchmark_latest.csv.

Usage: python3 E_Benchmark/aggregate_to_csv.py
"""
import re, os, sys, csv, numpy as np
from datetime import datetime

BENCH_DIR = os.path.dirname(__file__)
RAW_HASK  = os.path.join(BENCH_DIR, "results", "raw", "haskell")
RAW_PY    = os.path.join(BENCH_DIR, "results", "raw", "python")
TABLES    = os.path.join(BENCH_DIR, "results", "tables")
os.makedirs(TABLES, exist_ok=True)

# ---------- Haskell parsers ----------

def parse_haskell(path):
    """Parse 10-run Haskell output: return (times_ms, train_accs, test_accs, f1s, ppos, pneg)."""
    text = open(path).read()
    # timing: either "Total Time: Xs" or "Total: Xs | ..."
    times = [float(t) * 1000.0 / 1000.0        # total_ms / 1000 epochs = ms/epoch
             for t in re.findall(r'Total(?:\s+Time)?(?:\s+\(incl\. trace\))?:\s+([\d.]+)s', text)]
    train = [float(x) for x in re.findall(r'Accuracy: Train=([\d.]+)', text)]
    test  = [float(x) for x in re.findall(r'Test=([\d.]+)', text)]
    f1    = [float(x) for x in re.findall(r'F1 Score:\s+([\d.e+-]+)', text)]
    ppos  = [float(x) for x in re.findall(r'P\+=([\d.e+-]+)', text)]
    pneg  = [float(x) for x in re.findall(r'P-=([\d.e+-]+)', text)]
    # final sat per run (epoch 1000)
    blocks = re.split(r'=== \w+ run \d+ ===', text)
    sats   = []
    for b in blocks:
        s = re.findall(r'\[Epoch 1000/1000\].*?Sat=([\d.]+|-[\d.]+)', b)
        if s: sats.append(float(s[-1]))
    return times, sats, train, test, f1, ppos, pneg


def parse_python_summary(path):
    """Parse a Python bench output to extract the === SUMMARY block."""
    text = open(path).read()
    def _val(key): v = re.search(rf'{key}:\s+([\d.]+) \+/- ([\d.]+)', text); return (float(v[1]), float(v[2])) if v else (float('nan'),)*2
    speed  = _val("Speed")
    sat    = _val("Sat")  or (float('nan'), float('nan'))
    train  = _val("TrainAcc")
    test   = _val("TestAcc")
    f1     = _val("F1")
    ppos   = _val("P\\+")
    pneg   = _val("P-")
    return speed, sat, train, test, f1, ppos, pneg

# ---------- Aggregate ----------

def m(arr): return np.mean(arr) if arr else float('nan')
def s(arr): return np.std(arr)  if arr else float('nan')

rows = []  # list of dicts for CSV

def add_hask_row(name, logic, exec_type, filename):
    path = os.path.join(RAW_HASK, filename)
    if not os.path.exists(path):
        print(f"  [SKIP] {filename} not found"); return
    t, sat, ta, te, f1, pp, pn = parse_haskell(path)
    rows.append(dict(
        model=name, logic=logic, exec_type=exec_type,
        speed_mean=round(m(t),4),  speed_std=round(s(t),4),
        sat_mean=round(m(sat),4) if sat else "NA", sat_std=round(s(sat),4) if sat else "NA",
        train_acc_mean=round(m(ta),4), train_acc_std=round(s(ta),4),
        test_acc_mean=round(m(te),4),  test_acc_std=round(s(te),4),
        f1_mean=round(m(f1),4),        f1_std=round(s(f1),4),
        p_pos_mean=round(m(pp),4),     p_pos_std=round(s(pp),4),
        p_neg_mean=round(m(pn),4),     p_neg_std=round(s(pn),4),
        n_runs=len(t), n_epochs=1000,
    ))
    print(f"  [OK] {name} ({exec_type}): {m(t):.4f}+/-{s(t):.4f} ms | TestAcc={m(te):.4f} F1={m(f1):.4f}")

def add_py_row(name, logic, exec_type, filename, section=None):
    path = os.path.join(RAW_PY, filename)
    if not os.path.exists(path):
        print(f"  [SKIP] {filename} not found"); return
    text = open(path).read()

    # If multiple sections (e.g. ltn_tf has EAGER and COMPILED blocks)
    if section:
        chunks = re.split(r'Running LTN TensorFlow (EAGER|COMPILED)[^\n]*\n', text)
        # find the right chunk
        idx = [i for i,c in enumerate(chunks) if section in chunks[max(0,i-1):i]]
        text = chunks[idx[0]] if idx else text

    def _val(key):
        v = re.search(rf'{key}:\s+([\d.]+) \+/- ([\d.]+)', text)
        return (float(v[1]), float(v[2])) if v else (float('nan'), float('nan'))

    speed = _val("Speed"); sat = _val("Sat"); train = _val("TrainAcc")
    test  = _val("TestAcc"); f1 = _val("F1")
    ppos  = _val(r"P\+"); pneg = _val(r"P-")
    # count runs
    n_runs = len(re.findall(r'\[Run +\d+\]', text)) or 10

    rows.append(dict(
        model=name, logic=logic, exec_type=exec_type,
        speed_mean=round(speed[0],4), speed_std=round(speed[1],4),
        sat_mean=round(sat[0],4),     sat_std=round(sat[1],4),
        train_acc_mean=round(train[0],4), train_acc_std=round(train[1],4),
        test_acc_mean=round(test[0],4),   test_acc_std=round(test[1],4),
        f1_mean=round(f1[0],4),           f1_std=round(f1[1],4),
        p_pos_mean=round(ppos[0],4),      p_pos_std=round(ppos[1],4),
        p_neg_mean=round(pneg[0],4),      p_neg_std=round(pneg[1],4),
        n_runs=n_runs, n_epochs=1000,
    ))
    print(f"  [OK] {name} ({exec_type}): {speed[0]:.4f}+/-{speed[1]:.4f} ms | TestAcc={test[0]:.4f} F1={f1[0]:.4f}")

# ---------- Collect ----------
print("Aggregating Haskell results ...")
add_hask_row("NeSyCat (HaskTorch)", "2-ME_U",         "eager",    "uniform_eager_all.txt")
add_hask_row("NeSyCat (HaskTorch)", "2-ME_U",         "compiled", "uniform_jit_all.txt")
add_hask_row("NeSyCat (HaskTorch)", "1.25-LSE_R",     "eager",    "real_eager_all.txt")
add_hask_row("NeSyCat (HaskTorch)", "1.25-LSE_R",     "compiled", "real_jit_all.txt")
add_hask_row("NeSyCat (HaskTorch)", "beta-LSE_R",     "eager",    "real_beta_all.txt")

print("Aggregating Python results ...")
add_py_row("MLP Baseline (PyTorch)", "BCE",   "eager",    "mlp_baseline.txt")
add_py_row("LTNtorch (PyTorch)",     "2-ME",  "eager",    "ltn_torch.txt")
add_py_row("LTN (TensorFlow)",       "2-ME",  "eager",    "ltn_tf.txt",  section="EAGER")
add_py_row("LTN (TensorFlow)",       "2-ME",  "compiled", "ltn_tf.txt",  section="COMPILED")

# ---------- Write CSV ----------
if not rows:
    print("No results found."); sys.exit(0)

ts  = datetime.now().strftime("%Y%m%d_%H%M%S")
out = os.path.join(TABLES, "binary_benchmark_latest.csv")
out_ts = os.path.join(TABLES, f"binary_benchmark_{ts}.csv")

fieldnames = list(rows[0].keys())
for path in [out, out_ts]:
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader(); w.writerows(rows)

print(f"\nCSV saved: {out}")
print(f"Timestamped: {out_ts}")

# Pretty print
print("\n=== SUMMARY TABLE ===")
header = f"{'Model':<28} {'Logic':<14} {'Type':<10} {'ms/ep':>12} {'TestAcc':>10} {'F1':>8} {'P+':>8} {'P-':>8}"
print(header); print("-"*len(header))
for r in rows:
    print(f"{r['model']:<28} {r['logic']:<14} {r['exec_type']:<10} "
          f"{r['speed_mean']:>5.4f}+/-{r['speed_std']:<5.4f} "
          f"{r['test_acc_mean']:>10.4f} {r['f1_mean']:>8.4f} "
          f"{r['p_pos_mean']:>8.4f} {r['p_neg_mean']:>8.4f}")
