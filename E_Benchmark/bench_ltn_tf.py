#!/usr/bin/env python3
"""LTN TensorFlow benchmark: 10 runs x 1000 epochs.

Three modes:
  EAGER          - no @tf.function, tf.data batching (as in reference script)
  COMPILED_AXIOM - @tf.function on axioms only, direct tensor call (apples-to-
                   apples with NeSyCat torch.jit.trace which also only compiles
                   the forward/axiom graph; optimizer runs outside)
  COMPILED_FULL  - @tf.function on entire train_step incl. optimizer (TF's
                   unique advantage: TF's Adam is built as graph ops so it CAN
                   be compiled; LibTorch/HaskTorch cannot do this because the
                   optimizer state is dynamic and not JIT-traceable)

Both COMPILED modes use a DIRECT TENSOR CALL (no tf.data overhead) to match
NeSyCat's training loop which directly calls `forward scriptMod [...]` --
bypassing any data pipeline overhead.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "nesy_approaches/logictensornetworks_reference"))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "nesy_approaches/logictensornetworks_reference/venv/lib/python3.9/site-packages"))
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"
from metrics.metrics import evaluate_metrics, aggregate, print_summary

import numpy as np, time, tensorflow as tf, ltn

N_RUNS = 10; N_EPOCHS = 1000; LR = 0.001; BATCH_SIZE = 64

Mode = str  # "EAGER" | "COMPILED_AXIOM" | "COMPILED_FULL"

def run_mode(mode: Mode):
    all_ms, all_metrics, all_sat = [], [], []

    for run in range(N_RUNS):
        np_data   = np.random.uniform(0, 1, (100, 2)).astype(np.float32)
        np_labels = (np.sum((np_data - 0.5)**2, axis=1) < 0.09)
        train_data   = tf.constant(np_data[:50])
        train_labels = tf.constant(np_labels[:50])
        test_data    = tf.constant(np_data[50:])
        test_labels  = tf.constant(np_labels[50:])

        A      = ltn.Predicate.MLP([[2]], hidden_layer_sizes=(16, 16))
        Not    = ltn.Wrapper_Connective(ltn.fuzzy_ops.Not_Std())
        Forall = ltn.Wrapper_Quantifier(ltn.fuzzy_ops.Aggreg_pMeanError(p=2), semantics="forall")
        fagg   = ltn.Wrapper_Formula_Aggregator(ltn.fuzzy_ops.Aggreg_pMeanError(p=2))
        opt    = tf.keras.optimizers.Adam(learning_rate=LR)
        tvars  = A.trainable_variables

        def axioms_eager(data, labels):
            x_A     = ltn.Variable("x_A",     data[labels])
            x_not_A = ltn.Variable("x_not_A", data[tf.logical_not(labels)])
            return fagg([Forall(x_A, A(x_A)), Forall(x_not_A, Not(A(x_not_A)))]).tensor

        # --- EAGER: tf.data batching, no compilation (reference script pattern) ---
        if mode == "EAGER":
            ds = tf.data.Dataset.from_tensor_slices(
                (train_data, train_labels)).batch(BATCH_SIZE)
            t0 = time.time()
            for _ in range(N_EPOCHS):
                for d, l in ds:
                    with tf.GradientTape() as tape:
                        loss = 1. - axioms_eager(d, l)
                    opt.apply_gradients(zip(tape.gradient(loss, tvars), tvars))
            ms_per_epoch = (time.time() - t0) * 1000.0 / N_EPOCHS

        # --- COMPILED_AXIOM: axioms-only @tf.function, direct call ---
        # Equivalent scope to NeSyCat's torch.jit.trace:
        #   only the forward/axiom graph is compiled; optimizer runs in Python.
        # Direct call avoids tf.data overhead (NeSyCat does the same: direct
        #   `forward scriptMod [trainData, packedParams]` with no data pipeline).
        elif mode == "COMPILED_AXIOM":
            axioms_compiled = tf.function(axioms_eager)
            axioms_compiled(train_data, train_labels)  # warm-up trace
            t0 = time.time()
            for _ in range(N_EPOCHS):
                with tf.GradientTape() as tape:
                    loss = 1. - axioms_compiled(train_data, train_labels)
                opt.apply_gradients(zip(tape.gradient(loss, tvars), tvars))
            ms_per_epoch = (time.time() - t0) * 1000.0 / N_EPOCHS

        # --- COMPILED_FULL: full train_step (axiom + grad + optimizer) in @tf.function ---
        # TF's unique advantage: tf.keras.optimizers.Adam is itself built as TF
        #   graph ops (tf.Variable state, tf.assign updates), so it CAN be compiled.
        # LibTorch/HaskTorch Adam cannot be JIT-traced: optimizer state is mutable
        #   Python/Haskell state, incompatible with static graph tracing.
        # Direct call, no tf.data overhead.
        elif mode == "COMPILED_FULL":
            @tf.function
            def train_step_full(data, labels):
                with tf.GradientTape() as tape:
                    x_A     = ltn.Variable("x_A",     data[labels])
                    x_not_A = ltn.Variable("x_not_A", data[tf.logical_not(labels)])
                    loss = 1. - fagg([Forall(x_A, A(x_A)),
                                      Forall(x_not_A, Not(A(x_not_A)))]).tensor
                opt.apply_gradients(zip(tape.gradient(loss, tvars), tvars))
                return loss
            train_step_full(train_data, train_labels)  # warm-up trace
            t0 = time.time()
            for _ in range(N_EPOCHS):
                train_step_full(train_data, train_labels)
            ms_per_epoch = (time.time() - t0) * 1000.0 / N_EPOCHS

        else:
            raise ValueError(f"Unknown mode: {mode}")

        # evaluate sat
        def eval_sat(data, labels):
            x_A     = ltn.Variable("x_A",     data[labels])
            x_not_A = ltn.Variable("x_not_A", data[tf.logical_not(labels)])
            return float(fagg([Forall(x_A, A(x_A)), Forall(x_not_A, Not(A(x_not_A)))]).tensor)
        final_sat = eval_sat(train_data, train_labels)

        train_probs = A(ltn.Variable("x", train_data)).tensor.numpy().squeeze()
        test_probs  = A(ltn.Variable("x", test_data )).tensor.numpy().squeeze()
        m = evaluate_metrics(train_probs, np_labels[:50].astype(float),
                             test_probs,  np_labels[50:].astype(float))

        all_ms.append(ms_per_epoch); all_metrics.append(m); all_sat.append(final_sat)
        print(f"[{mode} Run {run+1:2d}] {ms_per_epoch:.4f} ms/epoch | Sat={final_sat:.4f} "
              f"TrainAcc={m['train_acc']:.4f} TestAcc={m['test_acc']:.4f} "
              f"F1={m['f1']:.4f} P+={m['p_pos']:.4f} P-={m['p_neg']:.4f}")

    agg = aggregate(all_metrics)
    print_summary(f"LTN TF {mode}", N_RUNS, N_EPOCHS, agg,
                  float(np.mean(all_ms)), float(np.std(all_ms)),
                  float(np.mean(all_sat)), float(np.std(all_sat)))
    return float(np.mean(all_ms)), float(np.std(all_ms)), agg, \
           float(np.mean(all_sat)), float(np.std(all_sat))

print("Running LTN TensorFlow EAGER (tf.data, no @tf.function) ...")
run_mode("EAGER")
print()
print("Running LTN TensorFlow COMPILED_AXIOM (@tf.function on axioms, direct call) ...")
print("  [Comparable scope to NeSyCat torch.jit.trace: forward graph only]")
run_mode("COMPILED_AXIOM")
print()
print("Running LTN TensorFlow COMPILED_FULL (entire train_step in @tf.function, direct call) ...")
print("  [TF-exclusive: TF Adam is graph ops; LibTorch Adam cannot be JIT-traced]")
run_mode("COMPILED_FULL")
