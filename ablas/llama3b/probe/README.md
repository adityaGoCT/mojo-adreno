# Cooperative-matrix probes on the Adreno 850 (driver E17.52.10.04)

- `map.comp`: which (row, column) each lane's element e holds. Result: B 16x64: lane = column, e = k; A 64x16:
  lane = row, e = k; accumulator 64x64: lane = row, e = column.
- `crash_uninit_element_write.comp` / `ok_init_then_write.comp`: element writes into a cooperative matrix that was
  never initialized segfault the compiler; initializing it first (`B b = B(0.0hf)`) works.
- `q4dbg.py`: identity-A test of the Q4_0 kernel. Showed that a write to element 4 of a B matrix with a constant
  index is dropped (the element keeps its initial value); `gen_q4.py` writes it with a runtime index.
- `crash_const_acc_element_read.comp` / `ok_loop_acc_element_read.comp`: reading accumulator elements with constant
  indices into a vector constructor crashes the compiler (`SPIRVCodeGen::handleOpLoad`); a loop index works.
- (in `../gen_attn.py`, fa3) cooperative-matrix multiplies under per-subgroup branches crash the compiler's layout
  analysis (`CoopMatLayoutNode::getUseCommonMask`); fa3 runs every multiply unconditionally.
Compile-only check on the phone: `vkrun x.spv 0 0 0 b0=@64 b1=@64 b2=@64` (a zero-size dispatch still builds the pipeline).
