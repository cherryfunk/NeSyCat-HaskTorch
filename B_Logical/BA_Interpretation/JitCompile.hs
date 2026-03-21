{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | JIT graph compilation for NeSyCat tensor operations.
--
--   Provides a general-purpose @traceForward@ that acts exactly like
--   TensorFlow's @@tf.function@: it traces a forward function once,
--   compiles it into a fused computation graph (via libtorch JIT),
--   and returns a compiled version that can be called repeatedly.
--
--   Usage:
--     1. Define your forward function:  @fwd :: [Tensor] -> IO [Tensor]@
--     2. Compile it:  @compiled <- jitTrace "axiom" fwd exampleInputs@
--     3. Run it:      @result <- compiled [actualInputs]@
--
--   This is completely abstract -- it does not know or care about
--   the formula structure. It compiles whatever operations happen
--   to execute during the trace, just like @@tf.function@.
module B_Logical.BA_Interpretation.JitCompile
  ( jitTrace,
    jitTraceAxiom,
  )
where

import Torch.Script
    ( trace, toScriptModule, runMethod1,
      IValue(..), RawModule, ScriptModule )
import qualified Torch

-- | General-purpose JIT trace compilation.
--
--   Traces a function @f :: [Tensor] -> IO [Tensor]@ with example inputs,
--   producing a compiled 'ScriptModule'.  Subsequent calls to 'runJit'
--   execute the fused graph -- equivalent to TensorFlow's @@tf.function@.
jitTrace :: String -> ([Torch.Tensor] -> IO [Torch.Tensor]) -> [Torch.Tensor] -> IO ScriptModule
jitTrace name f exampleInputs = do
  rawMod <- trace name "forward" f exampleInputs
  toScriptModule rawMod

-- | Run a JIT-compiled ScriptModule on a single tensor input, returning a tensor.
runJit :: ScriptModule -> Torch.Tensor -> Torch.Tensor
runJit scriptMod input =
  case runMethod1 scriptMod "forward" (IVTensor input) of
    IVTensor result -> result
    _               -> error "JitCompile.runJit: unexpected IValue type from forward"

-- | Trace the axiom computation graph.
--
--   Takes the axiom function @(data -> model_params -> loss_tensor)@,
--   traces it with example inputs, and returns a ScriptModule.
--
--   The traced graph captures ALL tensor operations (MLP forward,
--   quantifiers, wedge, 1-sat) as a single fused kernel -- no per-op
--   FFI overhead on subsequent calls.
jitTraceAxiom :: (Torch.Tensor -> Torch.Tensor -> IO Torch.Tensor)
              -> Torch.Tensor  -- ^ example data
              -> Torch.Tensor  -- ^ example model params (flattened)
              -> IO ScriptModule
jitTraceAxiom axiomFn exData exParams = do
  let f [d, p] = do
        result <- axiomFn d p
        return [result]
      f _ = error "jitTraceAxiom: expected 2 inputs"
  jitTrace "axiom" f [exData, exParams]
