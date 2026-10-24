__kernel void vecadd(__global const float* a, __global const float* b, __global float* c, long n) {
  long i = get_global_id(0);
  if (i < n) c[i] = a[i] + b[i];
}
