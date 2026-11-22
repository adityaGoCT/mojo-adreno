// alias_test: does a descriptor for buffer B at (offset, range) read another buffer A that was bound at the same
// (offset, range) earlier? Packs a [N, K] fp16 window of each of nbuf source buffers with ablas_pack_b (OP_T), one
// waited submission per buffer, then checks which source each packed copy came from.
//   alias_test S OFF N K nbuf [size_step]
//   env: USE_SETS=1 (descriptor sets), RESET_EACH=1 (reset the descriptor pool after each submission), MEMFLAGS=0xf,
//        VK_ALL_FEATURES=1 (every supported device feature, buffers with device addresses: llama.cpp's setup)
#include "llama3b/vkutil.h"
#include "ablas.h"

static vbuf_t buf_flags(vk_t* v, size_t size, uint32_t want) {
  vbuf_t b = {0};
  b.size = size;
  VkBufferCreateInfo bi = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
  bi.size = size;
  bi.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT |
             (v->bda ? VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT : 0);  // as llama.cpp's buffers
  CK(vkCreateBuffer(v->dev, &bi, NULL, &b.buf));
  VkMemoryRequirements mr;
  vkGetBufferMemoryRequirements(v->dev, b.buf, &mr);
  uint32_t type = 99;
  for (uint32_t i = 0; i < v->mem.memoryTypeCount; ++i)
    if ((mr.memoryTypeBits >> i & 1) && (v->mem.memoryTypes[i].propertyFlags & want) == want) { type = i; break; }
  if (type == 99) { printf("no memory type with flags 0x%x\n", want); exit(1); }
  VkMemoryAllocateFlagsInfo fi = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO, NULL, VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT, 0};
  VkMemoryAllocateInfo ai = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO, v->bda ? &fi : NULL, mr.size, type};
  CK(vkAllocateMemory(v->dev, &ai, NULL, &b.mem));
  CK(vkBindBufferMemory(v->dev, b.buf, b.mem, 0));
  CK(vkMapMemory(v->dev, b.mem, 0, VK_WHOLE_SIZE, 0, &b.map));
  return b;
}

int main(int argc, char** argv) {
  size_t S = strtoull(argv[1], 0, 0), OFF = strtoull(argv[2], 0, 0);
  uint32_t N = atoi(argv[3]), K = atoi(argv[4]), nb = atoi(argv[5]);
  size_t step = argc > 6 ? strtoull(argv[6], 0, 0) : 0;
  uint32_t want = getenv("MEMFLAGS") ? strtoul(getenv("MEMFLAGS"), 0, 0) : 0xf;
  setvbuf(stdout, NULL, _IOLBF, 0);
  vk_t v;
  vk_init(&v, 4);
  ablas_handle h;
  if (ablas_create(&h, v.pd, v.dev, v.gipa, v.inst)) { printf("ablas_create failed\n"); return 1; }
  if (getenv("USE_SETS")) ablas_use_descriptor_sets(h);
  size_t wsz = (size_t)N * K * 2;
  vbuf_t src[8], dst[8];
  for (uint32_t i = 0; i < nb; ++i) {
    src[i] = buf_flags(&v, S + i * step, want), dst[i] = buf_flags(&v, wsz, want);
    _Float16* w = (_Float16*)((char*)src[i].map + OFF);
    for (size_t j = 0; j < (size_t)N * K; ++j) w[j] = (_Float16)((float)(i + 1) + (float)(j % 61) / 64.0f);
    memset(dst[i].map, 0, wsz);
  }
  for (uint32_t i = 0; i < nb; ++i) {
    VkCommandBuffer c = vk_cmd(&v);
    vk_begin(c);
    ablas_buf B = {src[i].buf, OFF, wsz}, D = {dst[i].buf, 0, wsz};
    if (ablas_pack_b(h, c, ABLAS_OP_T, K, N, B, D)) { printf("pack failed\n"); return 1; }
    CK(vkEndCommandBuffer(c));
    vk_submit_wait(&v, c);
    if (getenv("RESET_EACH")) ablas_reset_descriptor_sets(h);  // RESET_EACH=1: the next pack reuses the same set
  }
  int bad = 0;
  for (uint32_t i = 0; i < nb; ++i) {  // packed element (n, k) at ((n/64)*(K/16) + k/16)*1024 + (n%64)*16 + k%16
    _Float16* d = dst[i].map;
    size_t wrong = 0;
    for (uint32_t n = 0; n < N; n += 7)
      for (uint32_t k = 0; k < K; k += 5) {
        size_t j = (size_t)n * K + k;
        float want_v = (float)(_Float16)((float)(i + 1) + (float)(j % 61) / 64.0f);
        wrong += (float)d[((size_t)(n / 64) * (K / 16) + k / 16) * 1024 + (n % 64) * 16 + k % 16] != want_v;
      }
    float d0 = (float)d[0];
    bad += wrong != 0;
    printf("buffer %u (size %zu): %zu sampled values wrong; packed[0] = %.4f -> looks like source %d\n", i, S + i * step,
           wrong, d0, (int)d0 - 1);
  }
  printf("RESULT S=%zu OFF=%zu N=%u K=%u nbuf=%u step=%zu sets=%d: %s\n", S, OFF, N, K, nb, step, getenv("USE_SETS") != NULL,
         bad ? "ALIASED" : "PASS");
  return 0;
}
