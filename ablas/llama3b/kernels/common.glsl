// Shared by the Llama 3.2 3B kernels. D = hidden size. "R tiles": AdrenoBLAS's packed A operand for an [X, K]
// matrix, element (x, k) at ((x/64)*(K/16) + k/16)*1024 + (x%64)*16 + k%16 (64 x 16 tiles, K contiguous inside).
#extension GL_EXT_shader_explicit_arithmetic_types : require
#extension GL_EXT_shader_16bit_storage : require
#extension GL_KHR_shader_subgroup_basic : require
const uint D = 3072u;
uint rtile(uint x, uint k, uint K) { return ((x / 64u) * (K / 16u) + k / 16u) * 1024u + (x % 64u) * 16u + k % 16u; }
