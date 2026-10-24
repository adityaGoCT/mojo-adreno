from std.sys.intrinsics import llvm_intrinsic


@always_inline
def global_id_x() -> Int:
    # SPIR-V GlobalInvocationId.x, read through the LLVM SPIR-V backend's intrinsic
    return Int(llvm_intrinsic["llvm.spv.thread.id", Int32](Int32(0)))


@export("vecadd", ABI="C")
def vecadd(a: UnsafePointer[Float32, MutAnyOrigin], b: UnsafePointer[Float32, MutAnyOrigin],
           c: UnsafePointer[Float32, MutAnyOrigin], n: Int):
    var i = global_id_x()
    if i < n:
        c[i] = a[i] + b[i]
