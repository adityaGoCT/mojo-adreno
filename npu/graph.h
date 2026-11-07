// npu/graph.cpp's C interface: static ONNX graphs on the Hexagon NPU through ONNX Runtime's QNN execution provider.
#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

const char* npug_error(void);
int npug_compile(const char* model, const char* ctx_out, double* ms);  // saves the HTP context binary
int npug_open(const char* ctx, double* ms);                              // -> a graph handle, or -1
int npug_count(int h, int output);                                       // inputs (0) or outputs (1)
int64_t npug_numel(int h, int output, int i);
int npug_input_is_int(int h, int i);                                     // int32 input (1) or fp32 (0)
int npug_run(int h, const void* const* inputs, float* const* outputs, double* ms);  // graph order, host memory
const char* npug_name(int h, int output, int i);                         // an input's (0) or output's (1) name
int npug_close(int h);                                                   // releases the graph's context

#ifdef __cplusplus
}
#endif
