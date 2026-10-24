target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G10"
target triple = "spirv1.6-unknown-vulkan1.3-compute"

@.nA = private unnamed_addr constant [2 x i8] c"A\00"
@.nB = private unnamed_addr constant [2 x i8] c"B\00"
@.nC = private unnamed_addr constant [2 x i8] c"C\00"

define void @main() #0 {
entry:
  %tid = call i32 @llvm.spv.thread.id.i32(i32 0)
  %hA = call target("spirv.VulkanBuffer", [0 x float], 12, 0) @llvm.spv.resource.handlefrombinding.tspirv.VulkanBuffer_a0f32_12_0t(i32 0, i32 0, i32 1, i32 0, ptr @.nA)
  %hB = call target("spirv.VulkanBuffer", [0 x float], 12, 0) @llvm.spv.resource.handlefrombinding.tspirv.VulkanBuffer_a0f32_12_0t(i32 0, i32 1, i32 1, i32 0, ptr @.nB)
  %hC = call target("spirv.VulkanBuffer", [0 x float], 12, 1) @llvm.spv.resource.handlefrombinding.tspirv.VulkanBuffer_a0f32_12_1t(i32 0, i32 2, i32 1, i32 0, ptr @.nC)
  %pA = call ptr addrspace(11) @llvm.spv.resource.getpointer.p11.tspirv.VulkanBuffer_a0f32_12_0t(target("spirv.VulkanBuffer", [0 x float], 12, 0) %hA, i32 %tid)
  %pB = call ptr addrspace(11) @llvm.spv.resource.getpointer.p11.tspirv.VulkanBuffer_a0f32_12_0t(target("spirv.VulkanBuffer", [0 x float], 12, 0) %hB, i32 %tid)
  %pC = call ptr addrspace(11) @llvm.spv.resource.getpointer.p11.tspirv.VulkanBuffer_a0f32_12_1t(target("spirv.VulkanBuffer", [0 x float], 12, 1) %hC, i32 %tid)
  %a = load float, ptr addrspace(11) %pA, align 4
  %b = load float, ptr addrspace(11) %pB, align 4
  %s = fadd float %a, %b
  store float %s, ptr addrspace(11) %pC, align 4
  ret void
}

declare i32 @llvm.spv.thread.id.i32(i32)
declare target("spirv.VulkanBuffer", [0 x float], 12, 0) @llvm.spv.resource.handlefrombinding.tspirv.VulkanBuffer_a0f32_12_0t(i32, i32, i32, i32, ptr)
declare target("spirv.VulkanBuffer", [0 x float], 12, 1) @llvm.spv.resource.handlefrombinding.tspirv.VulkanBuffer_a0f32_12_1t(i32, i32, i32, i32, ptr)
declare ptr addrspace(11) @llvm.spv.resource.getpointer.p11.tspirv.VulkanBuffer_a0f32_12_0t(target("spirv.VulkanBuffer", [0 x float], 12, 0), i32)
declare ptr addrspace(11) @llvm.spv.resource.getpointer.p11.tspirv.VulkanBuffer_a0f32_12_1t(target("spirv.VulkanBuffer", [0 x float], 12, 1), i32)

attributes #0 = { "hlsl.numthreads"="64,1,1" "hlsl.shader"="compute" }
