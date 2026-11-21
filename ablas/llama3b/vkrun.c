// vkrun: run one compute shader on the phone with buffers from files, for kernel unit tests and probes.
//   vkrun kernel.spv GX GY GZ [-p u32,u32,...] [-r REPS] [-o outdir] bI=file | bI=@BYTES ...
// bI=file loads binding I from a file; bI=@BYTES makes a zeroed buffer, bI=~BYTES a random fp16 one. After the run every buffer is written
// to outdir/bI.bin. -r times REPS back-to-back dispatches (GPU timestamps) after the checked run; prints ms.
#include "vkutil.h"

int main(int argc, char** argv) {
  if (argc < 5) { fprintf(stderr, "usage: vkrun spv gx gy gz [-p a,b,..] [-r reps] [-o dir] bI=file|bI=@bytes\n"); return 1; }
  vk_t v;
  vk_init(&v, 4);
  uint32_t gx = atoi(argv[2]), gy = atoi(argv[3]), gz = atoi(argv[4]);
  uint32_t pc[16];
  int npc = 0, reps = 0;
  const char* outdir = ".";
  vbuf_t bufs[NBIND] = {0};
  for (int i = 5; i < argc; ++i) {
    if (!strcmp(argv[i], "-p")) {
      for (char* s = strtok(argv[++i], ","); s && npc < 16; s = strtok(NULL, ",")) pc[npc++] = strtoul(s, NULL, 0);
    } else if (!strcmp(argv[i], "-r")) {
      reps = atoi(argv[++i]);
    } else if (!strcmp(argv[i], "-o")) {
      outdir = argv[++i];
    } else if (argv[i][0] == 'b') {
      int bi = atoi(argv[i] + 1);
      char* eq = strchr(argv[i], '=');
      if (eq[1] == '@') {
        bufs[bi] = vk_buffer(&v, strtoull(eq + 2, NULL, 0));
        memset(bufs[bi].map, 0, bufs[bi].size);
      } else if (eq[1] == '~') {  // pseudo-random fp16 values in [-1, 1) (any bit pattern is a valid Q4_0 quant)
        bufs[bi] = vk_buffer(&v, strtoull(eq + 2, NULL, 0));
        uint16_t* h = bufs[bi].map;
        uint32_t r = 12345u + (uint32_t)bi;
        for (size_t j = 0; j < bufs[bi].size / 2; ++j) {
          r = r * 1664525u + 1013904223u;
          _Float16 f = (_Float16)((float)(r >> 8) / (float)(1u << 23) - 1.0f);
          memcpy(&h[j], &f, 2);
        }
      } else {
        size_t n;
        void* d = read_file(eq + 1, &n);
        bufs[bi] = vk_buffer(&v, n);
        memcpy(bufs[bi].map, d, n);
        free(d);
      }
    }
  }
  VkPipeline p = vk_pipeline_file(&v, argv[1]);
  VkDescriptorBufferInfo bi[NBIND];
  for (int i = 0; i < NBIND; ++i) bi[i] = (VkDescriptorBufferInfo){bufs[i].buf, 0, VK_WHOLE_SIZE};
  VkCommandBuffer c = vk_cmd(&v);
  vk_begin(c);
  vk_dispatch(&v, c, p, bi, NBIND, pc, npc * 4, gx, gy, gz);
  CK(vkEndCommandBuffer(c));
  vk_submit_wait(&v, c);
  char path[512];
  for (int i = 0; i < NBIND; ++i) {
    if (!bufs[i].buf) continue;
    snprintf(path, sizeof path, "%s/b%d.bin", outdir, i);
    FILE* f = fopen(path, "wb");
    fwrite(bufs[i].map, 1, bufs[i].size, f);
    fclose(f);
  }
  if (reps > 0) {
    double best = 1e30;
    for (int t = 0; t < 5; ++t) {
      vk_begin(c);
      vkCmdResetQueryPool(c, v.qp, 0, 2);
      vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, v.qp, 0);
      for (int r = 0; r < reps; ++r) vk_dispatch(&v, c, p, bi, NBIND, pc, npc * 4, gx, gy, gz);
      vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, v.qp, 1);
      CK(vkEndCommandBuffer(c));
      vk_submit_wait(&v, c);
      uint64_t ts[2];
      CK(vkGetQueryPoolResults(v.dev, v.qp, 0, 2, sizeof ts, ts, 8, VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT));
      double ms = (ts[1] - ts[0]) * v.ts_ns * 1e-6 / reps;
      if (ms < best) best = ms;
    }
    printf("ms %.4f\n", best);
  }
  return 0;
}
