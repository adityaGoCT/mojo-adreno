// npu/pi0_prefix.cpp's C interface: π0's Gemma 2B prefix on the Hexagon NPU through ONNX Runtime's QNN execution
// provider. pi0/pi0npu.mojo calls it in its own process (the phone); vla/x2's vk_server_npu calls it for the Mac.
#ifndef NPU_PI0_PREFIX_H
#define NPU_PI0_PREFIX_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int pi0npu_open(const char* dir, double* ms);  // the compiled graphs in dir; *ms: the time to load them
int pi0npu_rows(void);                         // rows of a prefix (the graphs' padded rows)
int pi0npu_parts(void);                        // graphs
int pi0npu_part_first(int part);               // part's first layer (pi0npu_parts(): one past the last)
int pi0npu_set_rope(const float* rope, const int32_t* pos, const int32_t* valid, int n);
int pi0npu_set_x(const float* x, int n);       // n rows of fp32 [n][2048] into the first graph's x (fp16)
int pi0npu_start(void);                        // the graphs, one after another, on a worker thread
int pi0npu_part_wait(int part);                // until part's K/V are written
int pi0npu_finish(double* ms);                 // until the last part: *ms from start
void pi0npu_kv(int layer, int which, float* dst, int n);  // K (which 0) or V (1) of a layer, rows 0..n-1, as fp32
const char* pi0npu_error(void);
void pi0npu_close(void);

#ifdef __cplusplus
}
#endif

#endif  // NPU_PI0_PREFIX_H
