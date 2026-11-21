; num_ubos:           0
; num_driver_params:  0
; offsets:
;   ubo_ranges                 c0.x (1 vec4)
; ubo_state:
;   num_enabled:      1
;   range[0]:
;     block:          1
;     offset:         c0.x
;     size:           1 vec4 (16b -> 32b)
@in(r0.x)	in0 (wrmask=0x7)
@in(r48.x)	in1 (wrmask=0x7)
@const(c1.x)	0x00000800, 0x00002000, 0x00003e00, 0x00001e00
@const(c2.x)	0x00003c00, 0x00001c00, 0x00003a00, 0x00001a00
@const(c3.x)	0x00003800, 0x00001800, 0x00003600, 0x00001600
@const(c4.x)	0x00003400, 0x00001400, 0x00003200, 0x00001200
@const(c5.x)	0x00003000, 0x00001000, 0x00002e00, 0x00002c00
@const(c6.x)	0x00002a00, 0x00002800, 0x00002600, 0x00002400
@const(c7.x)	0x00002200, 0x00002100, 0x00000840, 0x00001040
@const(c8.x)	0x00001840, 0x00020000, 0x00020040, 0x00020800
@const(c9.x)	0x00020840, 0x00021000, 0x00021040, 0x00021800
@const(c10.x)	0x00021840, 0xd0d0d0d0, 0xd0d0d0d0, 0xd0d0d0d0
shps #l57
getone #l57
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 0x2000
mov.u32u32 r49.y, 0x3e00
mov.u32u32 r49.z, 0x1e00
mov.u32u32 r49.w, 0x3c00
mov.u32u32 r50.x, 0x1c00
mov.u32u32 r50.y, 0x3a00
mov.u32u32 r50.z, 0x1a00
mov.u32u32 r50.w, 0x3800
mov.u32u32 r51.x, 0x1800
mov.u32u32 r51.y, 0x3600
mov.u32u32 r51.z, 0x1600
mov.u32u32 r51.w, 0x3400
mov.u32u32 r52.x, 0x1400
mov.u32u32 r52.y, 0x3200
mov.u32u32 r52.z, 0x1200
mov.u32u32 r52.w, 0x3000
mov.u32u32 r53.x, 4096
mov.u32u32 r53.y, 0x2e00
mov.u32u32 r53.z, 0x2c00
mov.u32u32 r53.w, 0x2a00
mov.u32u32 r54.x, 0x2800
mov.u32u32 r54.y, 0x2600
mov.u32u32 r54.z, 0x2400
mov.u32u32 r54.w, 0x2200
mov.u32u32 r55.x, 0x2100
mov.u32u32 r55.y, 2112
mov.u32u32 r55.z, 0x1040
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
(ss)mov.u32u32 r48.w, 0x1840
mov.u32u32 r49.x, 0x20000
mov.u32u32 r49.y, 0x20040
mov.u32u32 r49.z, 0x20800
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 4
stc.u32 c[20], r52.w, 4
stc.u32 c[24], r53.w, 4
stc.u32 c[28], r54.w, 4
(ss)mov.u32u32 r49.w, 0x20840
mov.u32u32 r50.x, 0x21000
mov.u32u32 r50.y, 0x21040
mov.u32u32 r50.z, 0x21800
mov.u32u32 r50.w, 0x21840
stc.u32 c[32], r48.w, 4
(ss)nop
stc.u32 c[36], r49.w, 4
stc.u32 c[40], r50.w, 1
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l57:
(jp)(rpt1)add.u r51.x, (r)r48.x, (r)c0.x
mov.u32u32 r52.x, 0
shl.b r51.w, r51.x, 7
shl.b r51.z, r51.y, 7
shr.b r0.w, r0.x, 5
and.b r1.x, r0.x, 31
shr.b r1.z, r0.x, 4
and.b r1.y, r0.x, 15
and.b r1.w, r0.x, -16
mov.u32u32 r2.x, 0
mov.u32u32 r2.y, 0
mov.u32u32 r17.w, 0
mov.u32u32 r17.z, 0
mov.u32u32 r17.y, 0
mov.u32u32 r17.x, 0
mov.u32u32 r16.w, 0
mov.u32u32 r16.z, 0
mov.u32u32 r16.y, 0
mov.u32u32 r16.x, 0
mov.u32u32 r15.w, 0
mov.u32u32 r15.z, 0
mov.u32u32 r15.y, 0
mov.u32u32 r15.x, 0
mov.u32u32 r14.w, 0
mov.u32u32 r14.z, 0
mov.u32u32 r14.y, 0
mov.u32u32 r14.x, 0
mov.u32u32 r13.w, 0
mov.u32u32 r13.z, 0
mov.u32u32 r13.y, 0
mov.u32u32 r13.x, 0
mov.u32u32 r12.w, 0
mov.u32u32 r12.z, 0
mov.u32u32 r12.y, 0
mov.u32u32 r12.x, 0
mov.u32u32 r11.w, 0
mov.u32u32 r11.z, 0
mov.u32u32 r11.y, 0
mov.u32u32 r11.x, 0
mov.u32u32 r10.w, 0
mov.u32u32 r10.z, 0
mov.u32u32 r10.y, 0
mov.u32u32 r10.x, 0
mov.u32u32 r9.w, 0
mov.u32u32 r9.z, 0
mov.u32u32 r9.y, 0
mov.u32u32 r9.x, 0
mov.u32u32 r8.w, 0
mov.u32u32 r8.z, 0
mov.u32u32 r8.y, 0
mov.u32u32 r8.x, 0
mov.u32u32 r7.w, 0
mov.u32u32 r7.z, 0
mov.u32u32 r7.y, 0
mov.u32u32 r7.x, 0
mov.u32u32 r6.w, 0
mov.u32u32 r6.z, 0
mov.u32u32 r6.y, 0
mov.u32u32 r6.x, 0
mov.u32u32 r5.w, 0
mov.u32u32 r5.z, 0
mov.u32u32 r5.y, 0
mov.u32u32 r5.x, 0
mov.u32u32 r4.w, 0
mov.u32u32 r4.z, 0
mov.u32u32 r4.y, 0
mov.u32u32 r4.x, 0
mov.u32u32 r3.w, 0
mov.u32u32 r3.z, 0
mov.u32u32 r3.y, 0
mov.u32u32 r3.x, 0
mov.u32u32 r2.w, 0
mov.u32u32 r2.z, 0
l130:
(rpt1)nop
add.u r18.w, r0.x, 256
(ss)add.u r19.y, r52.x, r0.w
shl.b r18.x, r0.w, 9
shl.b r18.y, r1.x, 4
shr.b r18.w, (last)r18.w, 5
shl.b r19.y, (last)r19.y, 11
shl.b r18.z, r1.y, 4
add.u r19.x, r18.x, r18.y
add.u r19.z, r52.x, r18.w
add.u r52.x, r52.x, 16
cmps.u.ge up0.x, r52.x, c1.x
(rpt1)add.u r21.x, (last)r19.y, (r)r51.z
shl.b r18.w, (last)r18.w, 9
shl.b r19.z, (last)r19.z, 11
(rpt1)shr.b r21.x, (last)(r)r21.x, 2
add.u r19.w, r18.w, r18.y
add.u r21.z, r19.z, r51.z
add.u r21.x, (last)r21.x, r1.x
add.u r21.w, (last)r19.z, r51.w
add.u r21.y, (last)r21.y, r1.x
shr.b r21.z, (last)r21.z, 2
shl.b r21.x, (last)r21.x, 2
shr.b r21.w, (last)r21.w, 2
shl.b r21.y, (last)r21.y, 2
add.u r21.z, (last)r21.z, r1.x
add.u r22.z, c1.y, r18.z
add.u r21.w, (last)r21.w, r1.x
add.u r22.w, c7.y, r18.z
isam.v.base0 (u16)(xyzw)hr44.x, r21.x, s#0, t#0
shl.b r21.z, (last)r21.z, 2
sad.s32 r18.x, c1.y, r18.x, r18.y
shl.b r21.w, (last)r21.w, 2
sad.s32 r18.w, c1.y, r18.w, (last)r18.y
add.u r23.x, c7.x, r18.z
add.u r23.y, c6.w, r18.z
add.u r23.z, c6.z, r18.z
isam.v.base0 (u16)(xyzw)hr0.z, r21.z, s#0, t#0
add.u r23.w, c6.y, r18.z
add.u r24.x, c6.x, r18.z
add.u r24.y, c5.w, r18.z
add.u r24.z, c5.z, r18.z
add.u r20.x, c5.y, r1.w
add.u r20.y, c4.w, r1.w
add.u r24.w, c5.x, r18.z
add.u r25.x, c4.z, r18.z
add.u r20.z, c4.y, r1.w
add.u r20.w, c3.w, r1.w
add.u r25.y, c4.x, r18.z
add.u r25.z, c3.z, r18.z
add.u r26.z, c3.y, r1.w
add.u r25.w, c3.x, r18.z
add.u r26.w, c2.w, r1.w
add.u r26.x, c2.z, r18.z
add.u r27.x, c2.y, r1.w
add.u r26.y, c2.x, r18.z
add.u r27.y, c1.w, r1.w
add.u r18.z, c1.z, (last)r18.z
shl.b r27.z, r1.z, 2
(sy)(rpt3)cov.f16f32 r27.w, (last)(r)hr44.x
(rpt5)nop
stl.u32 l[r19.x], r27.w, 4
(ss)(rpt3)cov.f16f32 r27.w, (last)(r)hr0.z
isam.v.base0 (u16)(xyzw)hr0.z, r21.y, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr42.x, r21.w, s#0, t#2
(rpt4)nop
stl.u32 l[r19.w], r27.w, 4
(sy)(rpt2)cov.f16f32 r19.x, (last)(r)hr0.z
(rpt3)cov.f16f32 r21.z, (last)(r)hr42.x
(ss)cov.f16f32 r19.w, (last)hr1.y
(rpt5)nop
stl.u32 l[r18.x], r19.x, 4
stl.u32 l[r18.w], r21.z, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
ldl.u32 r27.w, l[r1.w], 4
ldl.u32 r28.w, l[r1.w+256], 4
ldl.u32 r29.w, l[r22.z], 4
ldl.u32 r30.w, l[r22.w], 4
ldl.u32 r2.x, l[r1.w+512], 4
ldl.u32 r3.x, l[r1.w+768], 4
ldl.u32 r18.w, l[r23.x], 4
ldl.u32 r21.x, l[r23.x+256], 4
ldl.u32 r22.x, l[r1.w+1024], 4
ldl.u32 r27.w, l[r1.w+1280], 4
ldl.u32 r28.w, l[r23.y], 4
ldl.u32 r29.w, l[r23.y+256], 4
ldl.u32 r30.w, l[r1.w+1536], 4
ldl.u32 r2.x, l[r1.w+1792], 4
ldl.u32 r3.x, l[r23.z], 4
ldl.u32 r18.w, l[r23.z+256], 4
ldl.u32 r21.x, l[r1.w+2048], 4
ldl.u32 r22.x, l[r1.w+2304], 4
ldl.u32 r27.w, l[r23.w], 4
ldl.u32 r28.w, l[r23.w+256], 4
ldl.u32 r29.w, l[r1.w+2560], 4
ldl.u32 r30.w, l[r1.w+2816], 4
ldl.u32 r2.x, l[r24.x], 4
ldl.u32 r3.x, l[r24.x+256], 4
ldl.u32 r18.w, l[r1.w+3072], 4
ldl.u32 r21.x, l[r1.w+3328], 4
ldl.u32 r22.x, l[r24.y], 4
ldl.u32 r23.x, l[r24.y+256], 4
ldl.u32 r27.w, l[r1.w+3584], 4
ldl.u32 r28.w, l[r1.w+3840], 4
ldl.u32 r29.w, l[r24.z], 4
ldl.u32 r30.w, l[r24.z+256], 4
ldl.u32 r2.x, l[r20.x], 4
ldl.u32 r3.x, l[r20.x+256], 4
ldl.u32 r18.w, l[r24.w], 4
ldl.u32 r21.x, l[r24.w+256], 4
ldl.u32 r22.x, l[r20.y], 4
ldl.u32 r23.x, l[r20.y+256], 4
ldl.u32 r24.x, l[r25.x], 4
ldl.u32 r27.w, l[r25.x+256], 4
ldl.u32 r28.w, l[r20.z], 4
ldl.u32 r29.w, l[r20.z+256], 4
ldl.u32 r30.w, l[r25.y], 4
ldl.u32 r2.x, l[r25.y+256], 4
ldl.u32 r3.x, l[r20.w], 4
ldl.u32 r18.w, l[r20.w+256], 4
ldl.u32 r19.w, l[r25.z], 4
ldl.u32 r20.w, l[r25.z+256], 4
ldl.u32 r21.w, l[r26.z], 4
ldl.u32 r22.w, l[r26.z+256], 4
ldl.u32 r23.w, l[r25.w], 4
(ss)nop
ldl.u32 r24.w, l[r25.w+256], 4
ldl.u32 r27.w, l[r26.w], 4
ldl.u32 r28.w, l[r26.w+256], 4
ldl.u32 r29.w, l[r26.x], 4
ldl.u32 r30.w, l[r26.x+256], 4
ldl.u32 r2.x, l[r27.x], 4
ldl.u32 r3.x, l[r27.x+256], 4
ldl.u32 r18.w, l[r26.y], 4
ldl.u32 r19.w, l[r26.y+256], 4
ldl.u32 r20.w, l[r27.y], 4
ldl.u32 r21.w, l[r27.y+256], 4
ldl.u32 r22.w, l[r18.z], 4
ldl.u32 r23.w, l[r18.z+256], 4
fence.r.w
(sy)(ss)cov.f32f16 hr0.z, r17.x
cov.f32f16 hr4.x, r15.x
cov.f32f16 hr5.x, r13.x
cov.f32f16 hr36.x, r11.x
cov.f32f16 hr0.w, r17.y
cov.f32f16 hr4.y, r15.y
cov.f32f16 hr5.y, r13.y
cov.f32f16 hr36.y, r11.y
cov.f32f16 hr1.x, r17.z
cov.f32f16 hr4.z, r15.z
cov.f32f16 hr5.z, r13.z
cov.f32f16 hr36.z, r11.z
cov.f32f16 hr1.y, r17.w
cov.f32f16 hr4.w, r15.w
cov.f32f16 hr5.w, r13.w
cov.f32f16 hr36.w, r11.w
cov.f32f16 hr37.x, r4.y
(rpt1)cov.f32f16 hr41.z, (r)r12.x
(rpt1)cov.f32f16 hr42.x, (r)r12.z
(rpt1)cov.f32f16 hr42.z, (r)r10.x
cov.f32f16 hr43.y, r10.w
cov.f32f16 hr43.x, r10.z
(rpt1)cov.f32f16 hr43.z, (r)r8.x
(rpt1)cov.f32f16 hr44.x, (r)r8.z
(rpt1)cov.f32f16 hr44.z, (r)r6.x
(rpt1)cov.f32f16 hr45.z, (r)r5.x
(rpt1)cov.f32f16 hr37.z, (r)r9.x
(rpt1)cov.f32f16 hr46.x, (r)r5.z
(rpt1)cov.f32f16 hr38.x, (r)r9.z
(rpt1)cov.f32f16 hr46.z, (r)r3.x
(rpt1)cov.f32f16 hr38.z, (r)r7.x
cov.f32f16 hr47.w, r24.w
cov.f32f16 hr47.z, r4.x
(rpt1)cov.f32f16 hr39.z, (r)r16.x
cov.f32f16 hr37.y, r25.x
mov.u32u32 r24.x, (last)r0.x
(rpt1)cov.f32f16 hr40.x, (r)r16.z
mov.u32u32 r24.y, (last)r0.w
(rpt1)cov.f32f16 hr40.z, (r)r14.x
(rpt1)cov.f32f16 hr41.x, (r)r14.z
cov.f32f16 hr47.y, r3.w
cov.f32f16 hr47.x, r3.z
(rpt1)cov.f32f16 hr45.x, (r)r6.z
(rpt1)cov.f32f16 hr39.x, (r)r7.z
bar.g
(sy)(ss)cov.f32f16 hr0.x, r4.z
cov.f32f16 hr0.y, r25.y
cov.f32f16 hr1.z, r4.w
cov.f32f16 hr1.w, r25.z
br p0.x, #l1181
mov.u32u32 r2.x, (last)r24.w
mov.u32u32 r2.y, (last)r25.x
mov.u32u32 r2.w, (last)r25.z
mov.u32u32 r2.z, (last)r25.y
mov.u32u32 r0.x, (last)r24.x
mov.u32u32 r0.w, (last)r24.y
jump #l130
l1181:
(jp)(eolm)nop
shr.b r51.w, r51.w, 2
add.u r27.z, r51.z, (last)r27.z
mov.u16u16 hr3.x, (last)hr47.z
mov.u16u16 hr3.y, (last)hr37.x
mov.u16u16 hr3.z, (last)hr0.x
shl.b r27.z, (last)r27.z, 9
mov.u16u16 hr3.w, (last)hr1.z
mov.u16u16 hr6.x, (last)hr47.w
mov.u16u16 hr6.y, (last)hr37.y
(ss)sad.s32 r27.z, r51.w, r27.z, (last)r1.y
mov.u16u16 hr6.z, (last)hr0.y
mov.u16u16 hr6.w, (last)hr1.w
nop
(nop3) shl.b r27.z, (last)r27.z, 2
add.u r3.z, r27.z, c1.x
add.u r3.w, r27.z, c7.z
add.u r4.x, r27.z, c5.y
stib.b.untyped.1d.u16.4.imm.base0 hr0.z, r27.z, 4
add.u r4.y, r27.z, c7.w
add.u r4.z, r27.z, c3.y
(rpt1)add.u r4.w, r27.z, (r)c8.x
(rpt1)add.u r5.y, (r)c8.z, r27.z
(rpt1)add.u r5.w, (r)c9.x, r27.z
(rpt1)add.u r6.y, (r)c9.z, r27.z
stib.b.untyped.1d.u16.4.imm.base0 hr39.z, r27.z+64, 4
(ss)add.u r27.z, c10.x, (last)r27.z
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r3.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr40.z, r3.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r4.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr41.z, r4.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr36.x, r4.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr42.z, r4.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr37.z, r5.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr43.z, r5.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr38.z, r5.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr44.z, r5.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr45.z, r6.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr3.x, r6.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr46.z, r6.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.x, r27.z, 4
end
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1399 instr, 33 nops, 1366 non-nops, 81 mov, 80 cov, 2466 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 32 full, 12 constlen
; CL prog 23/1: 36 cat0, 161 cat1, 83 cat2, 1027 cat3, 0 cat4, 4 cat5, 84 cat6, 4 cat7
; CL prog 23/1: 60 sstall, 21 (ss), 51 systall, 6 (sy), 1 loops
; CL prog 23/1: 8 max_waves, 0 double_threadsize
; 57 preamble-instr, 1 early-preamble
