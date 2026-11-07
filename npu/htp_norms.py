"""fp16-safe RMSNorm and LayerNorm for graphs that run on the Hexagon NPU (HTP), shared by the VLA ports' exports.

The HTP computes in fp16 and flushes subnormals (below 6.1e-5) to zero. A norm's squares of small activations (below
7.8e-3) then vanish, the mean square comes out too small and the output too large; keeping a residual stream divided
by a constant to avoid overflow makes that worse. These scale each row to a fixed maximum first (the norms are
scale-invariant) and carry eps exactly, so residual streams can stay unscaled (fp16 holds up to 65,504). Divisions are
tensor / tensor: a Python scalar divided by a tensor exports as ONNX Reciprocal, whose fp16 constant QNN mis-sizes.
"""
import math

import torch
from torch import nn


def rms16(x, g, eps=1e-6):
    """RMSNorm for the HTP, which computes in fp16 and flushes subnormals to zero: squares of small activations (below
    7.8e-3) would vanish, so each row is first scaled by k / m (m its largest |x|): k = 4 for rows up to 2,048 wide
    (the sum of squares at most 32,768, inside fp16), 2 beyond. RMSNorm is scale-invariant but for eps, which becomes
    eps (k / m)^2, computed as (k sqrt(eps) / m)^2 (eps itself would be a subnormal constant). The same function as
    g x / sqrt(mean(x^2) + eps); rows of zeros give zeros."""
    k = 4.0 if int(x.shape[-1]) <= 2048 else 2.0  # Python numbers: no shape arithmetic in the graph
    m = torch.clamp(x.abs().amax(-1, keepdim=True), min=1e-3)
    z = x / (m * (1.0 / k))  # Divs: QNN's Reciprocal mis-sizes its fp16 constant
    e = torch.full_like(m, k * math.sqrt(eps)) / m  # tensor / tensor: a scalar / tensor exports as a Reciprocal
    return g * (z / torch.sqrt((z * z).mean(-1, keepdim=True) + e * e))


def ln16(x, g=None, b=None, eps=1e-6):
    """LayerNorm for the HTP (see rms16): each row scaled by k / m first, k = 2 for rows up to 1,152 wide (centered
    values within 4, their squares' sum at most 18,432), 1 beyond; eps exact as in rms16. g, b: the affine (None:
    none)."""
    k = 2.0 if int(x.shape[-1]) <= 1152 else 1.0
    m = torch.clamp(x.abs().amax(-1, keepdim=True), min=1e-3)
    z = x / (m * (1.0 / k))
    d = z - z.mean(-1, keepdim=True)
    e = torch.full_like(m, k * math.sqrt(eps)) / m
    y = d / torch.sqrt((d * d).mean(-1, keepdim=True) + e * e)
    return y if g is None else y * g + b


class LN16(nn.Module):
    """An nn.LayerNorm's parameters through ln16 (swap_layernorms puts these in a model's place)."""

    def __init__(self, ln):
        super().__init__()
        self.weight, self.bias, self.eps = ln.weight, ln.bias, ln.eps

    def forward(self, x):
        return ln16(x, self.weight, self.bias, self.eps)


def swap_layernorms(model):
    """Every nn.LayerNorm in model replaced by an LN16 of the same parameters (in place; returns the count)."""
    n = 0
    for name, mod in list(model.named_modules()):
        for child, sub in list(mod.named_children()):
            if isinstance(sub, nn.LayerNorm):
                setattr(mod, child, LN16(sub))
                n += 1
    return n
