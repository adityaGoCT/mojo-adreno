@export("mojo_vecadd", ABI="C")
def mojo_vecadd(a: UnsafePointer[Float32, MutAnyOrigin], b: UnsafePointer[Float32, MutAnyOrigin],
                c: UnsafePointer[Float32, MutAnyOrigin], n: Int):
    for i in range(n):
        c[i] = a[i] + b[i]
