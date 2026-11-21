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
(rpt1)shr.b r52.y, (r)r51.z, 2
add.u r18.w, r0.x, 256
shl.b r18.x, r0.w, 9
(rpt1)shl.b r18.y, (r)r1.x, 4
shr.b r18.w, (last)r18.w, 5
add.u r22.x, c5.y, r1.w
(ss)add.u r19.y, r52.x, r0.w
add.u r19.x, r18.x, r18.y
add.u r19.z, r52.x, r18.w
add.u r52.x, r52.x, 16
cmps.u.ge up0.x, r52.x, c1.x
shl.b r18.w, (last)r18.w, 9
shl.b r19.y, (last)r19.y, 9
sad.s32 r18.x, c1.y, r18.x, r18.y
shl.b r19.z, (last)r19.z, 9
add.u r20.w, r18.w, r18.y
(rpt1)sad.s32 r19.w, (r)r52.y, r19.y, r1.x
(rpt1)sad.s32 r20.y, (r)r52.y, r19.z, r1.x
(rpt1)shl.b r19.w, (last)(r)r19.w, 2
(rpt1)shl.b r20.y, (last)(r)r20.y, 2
sad.s32 r18.w, c1.y, r18.w, (last)r18.y
add.u r23.x, c1.y, r18.z
add.u r23.y, c7.y, r18.z
isam.v.base0 (u32)(xyzw)r21.x, r19.w, s#0, t#0
add.u r23.z, c7.x, r18.z
add.u r23.w, c6.w, r18.z
isam.v.base0 (u32)(xyzw)r28.y, r20.y, s#0, t#0
isam.v.base0 (u32)(xyzw)r29.y, r20.x, s#0, t#2
add.u r24.x, c6.z, r18.z
isam.v.base0 (u32)(xyzw)r30.y, r20.z, s#0, t#2
add.u r24.y, c6.y, r18.z
add.u r24.z, c6.x, r18.z
add.u r24.w, c5.w, r18.z
add.u r25.x, c5.z, r18.z
add.u r25.y, c5.x, r18.z
add.u r22.y, c4.w, r1.w
add.u r22.z, c4.y, r1.w
add.u r25.z, c4.z, r18.z
add.u r25.w, c4.x, r18.z
add.u r22.w, c3.w, r1.w
add.u r26.x, c3.z, r18.z
add.u r27.x, c3.y, r1.w
add.u r27.y, c2.w, r1.w
add.u r26.y, c3.x, r18.z
add.u r26.z, c2.z, r18.z
add.u r27.z, c2.y, r1.w
add.u r26.w, c2.x, r18.z
add.u r27.w, c1.w, r1.w
add.u r18.z, c1.z, (last)r18.z
shl.b r28.x, r1.z, 2
(sy)stl.u32 l[r19.x], r21.x, 4
stl.u32 l[r20.w], r28.y, 4
stl.u32 l[r18.x], r29.y, 4
stl.u32 l[r18.w], r30.y, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
ldl.u32 r18.w, l[r1.w], 4
ldl.u32 r19.w, l[r1.w+256], 4
ldl.u32 r20.w, l[r23.x], 4
ldl.u32 r28.y, l[r23.y], 4
ldl.u32 r29.y, l[r1.w+512], 4
ldl.u32 r30.y, l[r1.w+768], 4
(ss)mad.f32 r17.x, r20.w, r18.w, (last)r17.x
mad.f32 r15.x, r20.w, r19.x, (last)r15.x
mad.f32 r13.x, r20.w, r19.y, (last)r13.x
mad.f32 r11.x, r20.w, r19.z, (last)r11.x
mad.f32 r9.x, r20.w, r19.w, (last)r9.x
mad.f32 r7.x, r20.w, r20.x, (last)r7.x
mad.f32 r5.x, r20.w, r20.y, (last)r5.x
mad.f32 r17.y, r21.x, r18.w, (last)r17.y
mad.f32 r15.y, r21.x, r19.x, (last)r15.y
mad.f32 r13.y, r21.x, r19.y, (last)r13.y
mad.f32 r11.y, r21.x, r19.z, (last)r11.y
mad.f32 r17.z, r21.y, r18.w, (last)r17.z
mad.f32 r15.z, r21.y, r19.x, (last)r15.z
mad.f32 r13.z, r21.y, r19.y, (last)r13.z
mad.f32 r11.z, r21.y, r19.z, (last)r11.z
mad.f32 r17.w, r21.z, r18.w, (last)r17.w
mad.f32 r15.w, r21.z, r19.x, (last)r15.w
mad.f32 r13.w, r21.z, r19.y, (last)r13.w
mad.f32 r11.w, r21.z, r19.z, (last)r11.w
mad.f32 r16.x, r28.y, r18.w, (last)r16.x
mad.f32 r14.x, r28.y, r19.x, (last)r14.x
mad.f32 r12.x, r28.y, r19.y, (last)r12.x
mad.f32 r10.x, r28.y, r19.z, (last)r10.x
mad.f32 r16.y, r28.z, r18.w, (last)r16.y
mad.f32 r14.y, r28.z, r19.x, (last)r14.y
mad.f32 r12.y, r28.z, r19.y, (last)r12.y
mad.f32 r10.y, r28.z, r19.z, (last)r10.y
mad.f32 r8.y, r28.z, r19.w, (last)r8.y
mad.f32 r6.y, r28.z, r20.x, (last)r6.y
mad.f32 r4.y, r28.z, r20.y, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r28.w, r18.w, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r28.w, r19.x, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r28.w, r19.y, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r28.w, r19.z, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r28.w, r19.w, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r28.w, r20.x, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r28.w, r20.y, (r)(last)r4.z
mad.f32 r20.w, (last)r20.w, r20.z, (last)r3.x
mad.f32 r28.z, (last)r28.z, r20.z, (last)r2.y
(rpt1)mad.f32 r28.w, (r)(last)r28.w, r20.z, (r)(last)r2.z
ldl.u32 r2.y, l[r23.z], 4
ldl.u32 r18.w, l[r23.z+256], 4
mad.f32 r9.y, r21.x, r19.w, (last)r9.y
mad.f32 r7.y, r21.x, r20.x, (last)r7.y
mad.f32 r5.y, r21.x, r20.y, (last)r5.y
mad.f32 r9.z, r21.y, r19.w, (last)r9.z
mad.f32 r7.z, r21.y, r20.x, (last)r7.z
mad.f32 r5.z, r21.y, r20.y, (last)r5.z
mad.f32 r9.w, r21.z, r19.w, (last)r9.w
mad.f32 r7.w, r21.z, r20.x, (last)r7.w
mad.f32 r5.w, r21.z, r20.y, (last)r5.w
mad.f32 r8.x, r28.y, r19.w, (last)r8.x
mad.f32 r21.x, (last)r21.x, r20.z, (last)r3.y
(rpt1)mad.f32 r21.y, (r)(last)r21.y, r20.z, (r)(last)r3.z
mad.f32 r6.x, r28.y, r20.x, (last)r6.x
mad.f32 r4.x, r28.y, r20.y, (last)r4.x
(ss)mad.f32 r17.x, r2.y, r29.y, (last)r17.x
mad.f32 r15.x, r2.y, r29.z, (last)r15.x
mad.f32 r13.x, r2.y, r29.w, (last)r13.x
mad.f32 r11.x, r2.y, r30.x, (last)r11.x
mad.f32 r9.x, r2.y, r30.y, (last)r9.x
mad.f32 r7.x, r2.y, r30.z, (last)r7.x
mad.f32 r5.x, r2.y, r30.w, (last)r5.x
mad.f32 r17.y, r2.z, r29.y, (last)r17.y
mad.f32 r15.y, r2.z, r29.z, (last)r15.y
mad.f32 r13.y, r2.z, r29.w, (last)r13.y
mad.f32 r11.y, r2.z, r30.x, (last)r11.y
mad.f32 r17.z, r2.w, r29.y, (last)r17.z
mad.f32 r15.z, r2.w, r29.z, (last)r15.z
mad.f32 r13.z, r2.w, r29.w, (last)r13.z
mad.f32 r11.z, r2.w, r30.x, (last)r11.z
mad.f32 r17.w, r3.x, r29.y, (last)r17.w
mad.f32 r15.w, r3.x, r29.z, (last)r15.w
mad.f32 r13.w, r3.x, r29.w, (last)r13.w
mad.f32 r11.w, r3.x, r30.x, (last)r11.w
mad.f32 r16.x, r18.w, r29.y, (last)r16.x
mad.f32 r14.x, r18.w, r29.z, (last)r14.x
mad.f32 r12.x, r18.w, r29.w, (last)r12.x
mad.f32 r10.x, r18.w, r30.x, (last)r10.x
mad.f32 r16.y, r19.x, r29.y, (last)r16.y
mad.f32 r14.y, r19.x, r29.z, (last)r14.y
mad.f32 r12.y, r19.x, r29.w, (last)r12.y
mad.f32 r10.y, r19.x, r30.x, (last)r10.y
mad.f32 r8.y, r19.x, r30.y, (last)r8.y
mad.f32 r6.y, r19.x, r30.z, (last)r6.y
mad.f32 r4.y, r19.x, r30.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r19.y, r29.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r19.y, r29.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r19.y, r29.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r19.y, r30.x, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r19.y, r30.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r19.y, r30.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r19.y, r30.w, (r)(last)r4.z
mad.f32 r9.y, r2.z, r30.y, (last)r9.y
mad.f32 r7.y, r2.z, r30.z, (last)r7.y
mad.f32 r5.y, r2.z, r30.w, (last)r5.y
mad.f32 r9.z, r2.w, r30.y, (last)r9.z
mad.f32 r7.z, r2.w, r30.z, (last)r7.z
mad.f32 r5.z, r2.w, r30.w, (last)r5.z
mad.f32 r9.w, r3.x, r30.y, (last)r9.w
mad.f32 r7.w, r3.x, r30.z, (last)r7.w
mad.f32 r5.w, r3.x, r30.w, (last)r5.w
mad.f32 r8.x, r18.w, r30.y, (last)r8.x
mad.f32 r28.y, (last)r28.y, r20.z, (last)r2.x
ldl.u32 r19.w, l[r1.w+1024], 4
mad.f32 r2.y, (last)r2.y, r31.x, (last)r20.w
mad.f32 r19.x, (last)r19.x, r31.x, (last)r28.z
(rpt1)mad.f32 r19.y, (r)(last)r19.y, r31.x, (r)(last)r28.w
mad.f32 r2.z, (last)r2.z, r31.x, (last)r21.x
(rpt1)mad.f32 r2.w, (r)(last)r2.w, r31.x, (r)(last)r21.y
ldl.u32 r20.w, l[r1.w+1280], 4
ldl.u32 r28.z, l[r23.w], 4
ldl.u32 r29.z, l[r23.w+256], 4
mad.f32 r6.x, r18.w, r30.z, (last)r6.x
mad.f32 r4.x, r18.w, r30.w, (last)r4.x
mad.f32 r18.w, (last)r18.w, r31.x, (last)r28.y
ldl.u32 r30.z, l[r1.w+1536], 4
(ss)mad.f32 r17.x, r28.z, r19.w, (last)r17.x
mad.f32 r15.x, r28.z, r20.x, (last)r15.x
mad.f32 r13.x, r28.z, r20.y, (last)r13.x
mad.f32 r11.x, r28.z, r20.z, (last)r11.x
mad.f32 r9.x, r28.z, r20.w, (last)r9.x
mad.f32 r7.x, r28.z, r21.x, (last)r7.x
mad.f32 r5.x, r28.z, r21.y, (last)r5.x
mad.f32 r17.y, r28.w, r19.w, (last)r17.y
mad.f32 r15.y, r28.w, r20.x, (last)r15.y
mad.f32 r13.y, r28.w, r20.y, (last)r13.y
mad.f32 r11.y, r28.w, r20.z, (last)r11.y
mad.f32 r9.y, r28.w, r20.w, (last)r9.y
mad.f32 r7.y, r28.w, r21.x, (last)r7.y
mad.f32 r5.y, r28.w, r21.y, (last)r5.y
mad.f32 r17.z, r29.x, r19.w, (last)r17.z
mad.f32 r15.z, r29.x, r20.x, (last)r15.z
mad.f32 r13.z, r29.x, r20.y, (last)r13.z
mad.f32 r11.z, r29.x, r20.z, (last)r11.z
mad.f32 r9.z, r29.x, r20.w, (last)r9.z
mad.f32 r7.z, r29.x, r21.x, (last)r7.z
mad.f32 r5.z, r29.x, r21.y, (last)r5.z
mad.f32 r17.w, r29.y, r19.w, (last)r17.w
mad.f32 r15.w, r29.y, r20.x, (last)r15.w
mad.f32 r13.w, r29.y, r20.y, (last)r13.w
mad.f32 r11.w, r29.y, r20.z, (last)r11.w
mad.f32 r9.w, r29.y, r20.w, (last)r9.w
mad.f32 r7.w, r29.y, r21.x, (last)r7.w
mad.f32 r5.w, r29.y, r21.y, (last)r5.w
mad.f32 r16.x, r29.z, r19.w, (last)r16.x
mad.f32 r14.x, r29.z, r20.x, (last)r14.x
mad.f32 r12.x, r29.z, r20.y, (last)r12.x
mad.f32 r10.x, r29.z, r20.z, (last)r10.x
mad.f32 r8.x, r29.z, r20.w, (last)r8.x
mad.f32 r16.y, r29.w, r19.w, (last)r16.y
mad.f32 r14.y, r29.w, r20.x, (last)r14.y
mad.f32 r12.y, r29.w, r20.y, (last)r12.y
mad.f32 r10.y, r29.w, r20.z, (last)r10.y
mad.f32 r8.y, r29.w, r20.w, (last)r8.y
mad.f32 r6.y, r29.w, r21.x, (last)r6.y
mad.f32 r4.y, r29.w, r21.y, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r30.x, r19.w, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r30.x, r20.x, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r30.x, r20.y, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r30.x, r20.z, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r30.x, r20.w, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r30.x, r21.x, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r30.x, r21.y, (r)(last)r4.z
mad.f32 r6.x, r29.z, r21.x, (last)r6.x
mad.f32 r4.x, r29.z, r21.y, (last)r4.x
(rpt1)mad.f32 r28.z, (r)(last)r28.z, r21.z, (r)(last)r2.y
mad.f32 r29.x, (last)r29.x, r21.z, (last)r2.w
ldl.u32 r2.x, l[r1.w+1792], 4
mad.f32 r29.y, (last)r29.y, r21.z, (last)r3.x
mad.f32 r29.w, (last)r29.w, r21.z, (last)r19.x
(rpt1)mad.f32 r30.x, (r)(last)r30.x, r21.z, (r)(last)r19.y
mad.f32 r29.z, (last)r29.z, r21.z, (last)r18.w
ldl.u32 r18.w, l[r24.x], 4
ldl.u32 r19.w, l[r24.x+256], 4
ldl.u32 r20.w, l[r1.w+2048], 4
ldl.u32 r23.x, l[r1.w+2304], 4
(ss)mad.f32 r17.x, r18.w, r30.z, (last)r17.x
mad.f32 r15.x, r18.w, r30.w, (last)r15.x
mad.f32 r13.x, r18.w, r31.x, (last)r13.x
mad.f32 r11.x, r18.w, r31.y, (last)r11.x
mad.f32 r9.x, r18.w, r2.x, (last)r9.x
mad.f32 r7.x, r18.w, r2.y, (last)r7.x
mad.f32 r5.x, r18.w, r2.z, (last)r5.x
mad.f32 r17.y, r19.x, r30.z, (last)r17.y
mad.f32 r15.y, r19.x, r30.w, (last)r15.y
mad.f32 r13.y, r19.x, r31.x, (last)r13.y
mad.f32 r11.y, r19.x, r31.y, (last)r11.y
mad.f32 r9.y, r19.x, r2.x, (last)r9.y
mad.f32 r7.y, r19.x, r2.y, (last)r7.y
mad.f32 r5.y, r19.x, r2.z, (last)r5.y
mad.f32 r17.z, r19.y, r30.z, (last)r17.z
mad.f32 r15.z, r19.y, r30.w, (last)r15.z
mad.f32 r13.z, r19.y, r31.x, (last)r13.z
mad.f32 r11.z, r19.y, r31.y, (last)r11.z
mad.f32 r9.z, r19.y, r2.x, (last)r9.z
mad.f32 r7.z, r19.y, r2.y, (last)r7.z
mad.f32 r5.z, r19.y, r2.z, (last)r5.z
mad.f32 r17.w, r19.z, r30.z, (last)r17.w
mad.f32 r15.w, r19.z, r30.w, (last)r15.w
mad.f32 r13.w, r19.z, r31.x, (last)r13.w
mad.f32 r11.w, r19.z, r31.y, (last)r11.w
mad.f32 r9.w, r19.z, r2.x, (last)r9.w
mad.f32 r7.w, r19.z, r2.y, (last)r7.w
mad.f32 r5.w, r19.z, r2.z, (last)r5.w
mad.f32 r16.x, r19.w, r30.z, (last)r16.x
mad.f32 r14.x, r19.w, r30.w, (last)r14.x
mad.f32 r12.x, r19.w, r31.x, (last)r12.x
mad.f32 r10.x, r19.w, r31.y, (last)r10.x
mad.f32 r8.x, r19.w, r2.x, (last)r8.x
mad.f32 r6.x, r19.w, r2.y, (last)r6.x
mad.f32 r4.x, r19.w, r2.z, (last)r4.x
mad.f32 r16.y, r20.x, r30.z, (last)r16.y
mad.f32 r14.y, r20.x, r30.w, (last)r14.y
mad.f32 r12.y, r20.x, r31.x, (last)r12.y
mad.f32 r10.y, r20.x, r31.y, (last)r10.y
mad.f32 r8.y, r20.x, r2.x, (last)r8.y
mad.f32 r6.y, r20.x, r2.y, (last)r6.y
mad.f32 r4.y, r20.x, r2.z, (last)r4.y
mad.f32 r16.z, r20.y, r30.z, (last)r16.z
mad.f32 r14.z, r20.y, r30.w, (last)r14.z
mad.f32 r12.z, r20.y, r31.x, (last)r12.z
mad.f32 r10.z, r20.y, r31.y, (last)r10.z
mad.f32 r8.z, r20.y, r2.x, (last)r8.z
mad.f32 r6.z, r20.y, r2.y, (last)r6.z
mad.f32 r4.z, r20.y, r2.z, (last)r4.z
(rpt1)mad.f32 r18.w, (r)(last)r18.w, r2.w, (r)(last)r28.z
mad.f32 r19.y, (last)r19.y, r2.w, (last)r29.x
ldl.u32 r28.y, l[r24.y], 4
mad.f32 r19.z, (last)r19.z, r2.w, (last)r29.y
(rpt1)mad.f32 r19.w, (r)(last)r19.w, r2.w, (r)(last)r29.z
mad.f32 r20.y, (last)r20.y, r2.w, (last)r30.x
ldl.u32 r29.y, l[r24.y+256], 4
mad.f32 r16.w, r20.z, r30.z, (last)r16.w
mad.f32 r14.w, r20.z, r30.w, (last)r14.w
mad.f32 r12.w, r20.z, r31.x, (last)r12.w
mad.f32 r10.w, r20.z, r31.y, (last)r10.w
mad.f32 r8.w, r20.z, r2.x, (last)r8.w
mad.f32 r6.w, r20.z, r2.y, (last)r6.w
mad.f32 r4.w, r20.z, r2.z, (last)r4.w
mad.f32 r20.z, (last)r20.z, r2.w, (last)r30.y
ldl.u32 r30.y, l[r1.w+2560], 4
ldl.u32 r2.x, l[r1.w+2816], 4
(ss)mad.f32 r17.x, r28.y, r20.w, (last)r17.x
mad.f32 r15.x, r28.y, r21.x, (last)r15.x
mad.f32 r13.x, r28.y, r21.y, (last)r13.x
mad.f32 r11.x, r28.y, r21.z, (last)r11.x
mad.f32 r9.x, r28.y, r23.x, (last)r9.x
mad.f32 r7.x, r28.y, r23.y, (last)r7.x
mad.f32 r5.x, r28.y, r23.z, (last)r5.x
mad.f32 r17.y, r28.z, r20.w, (last)r17.y
mad.f32 r15.y, r28.z, r21.x, (last)r15.y
mad.f32 r13.y, r28.z, r21.y, (last)r13.y
mad.f32 r11.y, r28.z, r21.z, (last)r11.y
mad.f32 r9.y, r28.z, r23.x, (last)r9.y
mad.f32 r7.y, r28.z, r23.y, (last)r7.y
mad.f32 r5.y, r28.z, r23.z, (last)r5.y
mad.f32 r17.z, r28.w, r20.w, (last)r17.z
mad.f32 r15.z, r28.w, r21.x, (last)r15.z
mad.f32 r13.z, r28.w, r21.y, (last)r13.z
mad.f32 r11.z, r28.w, r21.z, (last)r11.z
mad.f32 r9.z, r28.w, r23.x, (last)r9.z
mad.f32 r7.z, r28.w, r23.y, (last)r7.z
mad.f32 r5.z, r28.w, r23.z, (last)r5.z
mad.f32 r17.w, r29.x, r20.w, (last)r17.w
mad.f32 r15.w, r29.x, r21.x, (last)r15.w
mad.f32 r13.w, r29.x, r21.y, (last)r13.w
mad.f32 r11.w, r29.x, r21.z, (last)r11.w
mad.f32 r9.w, r29.x, r23.x, (last)r9.w
mad.f32 r7.w, r29.x, r23.y, (last)r7.w
mad.f32 r5.w, r29.x, r23.z, (last)r5.w
mad.f32 r16.x, r29.y, r20.w, (last)r16.x
mad.f32 r14.x, r29.y, r21.x, (last)r14.x
mad.f32 r12.x, r29.y, r21.y, (last)r12.x
mad.f32 r10.x, r29.y, r21.z, (last)r10.x
mad.f32 r8.x, r29.y, r23.x, (last)r8.x
mad.f32 r6.x, r29.y, r23.y, (last)r6.x
mad.f32 r4.x, r29.y, r23.z, (last)r4.x
mad.f32 r16.y, r29.z, r20.w, (last)r16.y
mad.f32 r14.y, r29.z, r21.x, (last)r14.y
mad.f32 r12.y, r29.z, r21.y, (last)r12.y
mad.f32 r10.y, r29.z, r21.z, (last)r10.y
mad.f32 r8.y, r29.z, r23.x, (last)r8.y
mad.f32 r6.y, r29.z, r23.y, (last)r6.y
mad.f32 r4.y, r29.z, r23.z, (last)r4.y
mad.f32 r16.z, r29.w, r20.w, (last)r16.z
mad.f32 r14.z, r29.w, r21.x, (last)r14.z
mad.f32 r12.z, r29.w, r21.y, (last)r12.z
mad.f32 r10.z, r29.w, r21.z, (last)r10.z
mad.f32 r8.z, r29.w, r23.x, (last)r8.z
mad.f32 r6.z, r29.w, r23.y, (last)r6.z
mad.f32 r4.z, r29.w, r23.z, (last)r4.z
mad.f32 r16.w, r30.x, r20.w, (last)r16.w
mad.f32 r14.w, r30.x, r21.x, (last)r14.w
mad.f32 r12.w, r30.x, r21.y, (last)r12.w
mad.f32 r10.w, r30.x, r21.z, (last)r10.w
mad.f32 r8.w, r30.x, r23.x, (last)r8.w
mad.f32 r6.w, r30.x, r23.y, (last)r6.w
mad.f32 r4.w, r30.x, r23.z, (last)r4.w
(rpt1)mad.f32 r28.y, (r)(last)r28.y, r23.w, (r)(last)r18.w
(rpt1)mad.f32 r28.w, (r)(last)r28.w, r23.w, (r)(last)r19.y
ldl.u32 r18.w, l[r24.z], 4
(rpt1)mad.f32 r29.y, (r)(last)r29.y, r23.w, (r)(last)r19.w
(rpt1)mad.f32 r29.w, (r)(last)r29.w, r23.w, (r)(last)r20.y
ldl.u32 r19.w, l[r24.z+256], 4
ldl.u32 r20.w, l[r1.w+3072], 4
ldl.u32 r23.x, l[r1.w+3328], 4
(ss)mad.f32 r17.x, r18.w, r30.y, (last)r17.x
mad.f32 r15.x, r18.w, r30.z, (last)r15.x
mad.f32 r13.x, r18.w, r30.w, (last)r13.x
mad.f32 r11.x, r18.w, r31.x, (last)r11.x
mad.f32 r9.x, r18.w, r2.x, (last)r9.x
mad.f32 r7.x, r18.w, r2.y, (last)r7.x
mad.f32 r5.x, r18.w, r2.z, (last)r5.x
mad.f32 r17.y, r19.x, r30.y, (last)r17.y
mad.f32 r15.y, r19.x, r30.z, (last)r15.y
mad.f32 r13.y, r19.x, r30.w, (last)r13.y
mad.f32 r11.y, r19.x, r31.x, (last)r11.y
mad.f32 r9.y, r19.x, r2.x, (last)r9.y
mad.f32 r7.y, r19.x, r2.y, (last)r7.y
mad.f32 r5.y, r19.x, r2.z, (last)r5.y
mad.f32 r17.z, r19.y, r30.y, (last)r17.z
mad.f32 r15.z, r19.y, r30.z, (last)r15.z
mad.f32 r13.z, r19.y, r30.w, (last)r13.z
mad.f32 r11.z, r19.y, r31.x, (last)r11.z
mad.f32 r9.z, r19.y, r2.x, (last)r9.z
mad.f32 r7.z, r19.y, r2.y, (last)r7.z
mad.f32 r5.z, r19.y, r2.z, (last)r5.z
mad.f32 r17.w, r19.z, r30.y, (last)r17.w
mad.f32 r15.w, r19.z, r30.z, (last)r15.w
mad.f32 r13.w, r19.z, r30.w, (last)r13.w
mad.f32 r11.w, r19.z, r31.x, (last)r11.w
mad.f32 r9.w, r19.z, r2.x, (last)r9.w
mad.f32 r7.w, r19.z, r2.y, (last)r7.w
mad.f32 r5.w, r19.z, r2.z, (last)r5.w
mad.f32 r16.x, r19.w, r30.y, (last)r16.x
mad.f32 r14.x, r19.w, r30.z, (last)r14.x
mad.f32 r12.x, r19.w, r30.w, (last)r12.x
mad.f32 r10.x, r19.w, r31.x, (last)r10.x
mad.f32 r8.x, r19.w, r2.x, (last)r8.x
mad.f32 r6.x, r19.w, r2.y, (last)r6.x
mad.f32 r4.x, r19.w, r2.z, (last)r4.x
mad.f32 r16.y, r20.x, r30.y, (last)r16.y
mad.f32 r14.y, r20.x, r30.z, (last)r14.y
mad.f32 r12.y, r20.x, r30.w, (last)r12.y
mad.f32 r10.y, r20.x, r31.x, (last)r10.y
mad.f32 r8.y, r20.x, r2.x, (last)r8.y
mad.f32 r6.y, r20.x, r2.y, (last)r6.y
mad.f32 r4.y, r20.x, r2.z, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r20.y, r30.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r20.y, r30.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r20.y, r30.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r20.y, r31.x, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r20.y, r2.x, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r20.y, r2.y, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r20.y, r2.z, (r)(last)r4.z
(rpt1)mad.f32 r18.w, (r)(last)r18.w, r2.w, (r)(last)r28.y
(rpt1)mad.f32 r19.y, (r)(last)r19.y, r2.w, (r)(last)r28.w
ldl.u32 r28.y, l[r24.w], 4
(rpt1)mad.f32 r19.w, (r)(last)r19.w, r2.w, (r)(last)r29.y
(rpt1)mad.f32 r20.y, (r)(last)r20.y, r2.w, (r)(last)r29.w
ldl.u32 r29.y, l[r24.w+256], 4
ldl.u32 r30.y, l[r1.w+3584], 4
ldl.u32 r2.x, l[r1.w+3840], 4
(ss)mad.f32 r17.x, r28.y, r20.w, (last)r17.x
mad.f32 r15.x, r28.y, r21.x, (last)r15.x
mad.f32 r13.x, r28.y, r21.y, (last)r13.x
mad.f32 r11.x, r28.y, r21.z, (last)r11.x
mad.f32 r9.x, r28.y, r23.x, (last)r9.x
mad.f32 r7.x, r28.y, r23.y, (last)r7.x
mad.f32 r5.x, r28.y, r23.z, (last)r5.x
mad.f32 r17.y, r28.z, r20.w, (last)r17.y
mad.f32 r15.y, r28.z, r21.x, (last)r15.y
mad.f32 r13.y, r28.z, r21.y, (last)r13.y
mad.f32 r11.y, r28.z, r21.z, (last)r11.y
mad.f32 r9.y, r28.z, r23.x, (last)r9.y
mad.f32 r7.y, r28.z, r23.y, (last)r7.y
mad.f32 r5.y, r28.z, r23.z, (last)r5.y
mad.f32 r17.z, r28.w, r20.w, (last)r17.z
mad.f32 r15.z, r28.w, r21.x, (last)r15.z
mad.f32 r13.z, r28.w, r21.y, (last)r13.z
mad.f32 r11.z, r28.w, r21.z, (last)r11.z
mad.f32 r9.z, r28.w, r23.x, (last)r9.z
mad.f32 r7.z, r28.w, r23.y, (last)r7.z
mad.f32 r5.z, r28.w, r23.z, (last)r5.z
mad.f32 r17.w, r29.x, r20.w, (last)r17.w
mad.f32 r15.w, r29.x, r21.x, (last)r15.w
mad.f32 r13.w, r29.x, r21.y, (last)r13.w
mad.f32 r11.w, r29.x, r21.z, (last)r11.w
mad.f32 r9.w, r29.x, r23.x, (last)r9.w
mad.f32 r7.w, r29.x, r23.y, (last)r7.w
mad.f32 r5.w, r29.x, r23.z, (last)r5.w
mad.f32 r16.x, r29.y, r20.w, (last)r16.x
mad.f32 r14.x, r29.y, r21.x, (last)r14.x
mad.f32 r12.x, r29.y, r21.y, (last)r12.x
mad.f32 r10.x, r29.y, r21.z, (last)r10.x
mad.f32 r8.x, r29.y, r23.x, (last)r8.x
mad.f32 r6.x, r29.y, r23.y, (last)r6.x
mad.f32 r4.x, r29.y, r23.z, (last)r4.x
mad.f32 r16.y, r29.z, r20.w, (last)r16.y
mad.f32 r14.y, r29.z, r21.x, (last)r14.y
mad.f32 r12.y, r29.z, r21.y, (last)r12.y
mad.f32 r10.y, r29.z, r21.z, (last)r10.y
mad.f32 r8.y, r29.z, r23.x, (last)r8.y
mad.f32 r6.y, r29.z, r23.y, (last)r6.y
mad.f32 r4.y, r29.z, r23.z, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r29.w, r20.w, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r29.w, r21.x, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r29.w, r21.y, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r29.w, r21.z, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r29.w, r23.x, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r29.w, r23.y, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r29.w, r23.z, (r)(last)r4.z
(rpt1)mad.f32 r28.y, (r)(last)r28.y, r23.w, (r)(last)r18.w
(rpt1)mad.f32 r28.w, (r)(last)r28.w, r23.w, (r)(last)r19.y
ldl.u32 r18.w, l[r25.x], 4
(rpt1)mad.f32 r29.y, (r)(last)r29.y, r23.w, (r)(last)r19.w
(rpt1)mad.f32 r29.w, (r)(last)r29.w, r23.w, (r)(last)r20.y
ldl.u32 r19.w, l[r25.x+256], 4
ldl.u32 r20.w, l[r22.x], 4
ldl.u32 r23.x, l[r22.x+256], 4
(ss)mad.f32 r17.x, r18.w, r30.y, (last)r17.x
ldl.u32 r24.y, l[r25.y], 4
mad.f32 r15.x, r18.w, r30.z, (last)r15.x
mad.f32 r13.x, r18.w, r30.w, (last)r13.x
mad.f32 r11.x, r18.w, r31.x, (last)r11.x
mad.f32 r9.x, r18.w, r2.x, (last)r9.x
mad.f32 r7.x, r18.w, r2.y, (last)r7.x
mad.f32 r5.x, r18.w, r2.z, (last)r5.x
mad.f32 r17.y, r19.x, r30.y, (last)r17.y
mad.f32 r15.y, r19.x, r30.z, (last)r15.y
mad.f32 r13.y, r19.x, r30.w, (last)r13.y
mad.f32 r11.y, r19.x, r31.x, (last)r11.y
mad.f32 r9.y, r19.x, r2.x, (last)r9.y
mad.f32 r7.y, r19.x, r2.y, (last)r7.y
mad.f32 r5.y, r19.x, r2.z, (last)r5.y
mad.f32 r17.z, r19.y, r30.y, (last)r17.z
mad.f32 r15.z, r19.y, r30.z, (last)r15.z
mad.f32 r13.z, r19.y, r30.w, (last)r13.z
mad.f32 r11.z, r19.y, r31.x, (last)r11.z
mad.f32 r9.z, r19.y, r2.x, (last)r9.z
mad.f32 r7.z, r19.y, r2.y, (last)r7.z
mad.f32 r5.z, r19.y, r2.z, (last)r5.z
mad.f32 r17.w, r19.z, r30.y, (last)r17.w
mad.f32 r15.w, r19.z, r30.z, (last)r15.w
mad.f32 r13.w, r19.z, r30.w, (last)r13.w
mad.f32 r11.w, r19.z, r31.x, (last)r11.w
mad.f32 r9.w, r19.z, r2.x, (last)r9.w
mad.f32 r7.w, r19.z, r2.y, (last)r7.w
mad.f32 r5.w, r19.z, r2.z, (last)r5.w
(rpt1)mad.f32 r18.w, (r)(last)r18.w, r2.w, (r)(last)r28.y
(rpt1)mad.f32 r19.y, (r)(last)r19.y, r2.w, (r)(last)r28.w
ldl.u32 r28.y, l[r25.y+256], 4
mad.f32 r16.x, r19.w, r30.y, (last)r16.x
mad.f32 r14.x, r19.w, r30.z, (last)r14.x
mad.f32 r12.x, r19.w, r30.w, (last)r12.x
mad.f32 r10.x, r19.w, r31.x, (last)r10.x
mad.f32 r8.x, r19.w, r2.x, (last)r8.x
mad.f32 r6.x, r19.w, r2.y, (last)r6.x
mad.f32 r4.x, r19.w, r2.z, (last)r4.x
mad.f32 r16.y, r20.x, r30.y, (last)r16.y
mad.f32 r14.y, r20.x, r30.z, (last)r14.y
mad.f32 r12.y, r20.x, r30.w, (last)r12.y
mad.f32 r10.y, r20.x, r31.x, (last)r10.y
mad.f32 r8.y, r20.x, r2.x, (last)r8.y
mad.f32 r6.y, r20.x, r2.y, (last)r6.y
mad.f32 r4.y, r20.x, r2.z, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r20.y, r30.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r20.y, r30.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r20.y, r30.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r20.y, r31.x, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r20.y, r2.x, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r20.y, r2.y, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r20.y, r2.z, (r)(last)r4.z
(rpt1)mad.f32 r19.w, (r)(last)r19.w, r2.w, (r)(last)r29.y
(rpt1)mad.f32 r20.y, (r)(last)r20.y, r2.w, (r)(last)r29.w
ldl.u32 r29.y, l[r22.y], 4
ldl.u32 r30.y, l[r22.y+256], 4
ldl.u32 r2.z, l[r25.z], 4
(ss)mad.f32 r17.x, r24.y, r20.w, (last)r17.x
mad.f32 r15.x, r24.y, r21.x, (last)r15.x
mad.f32 r13.x, r24.y, r21.y, (last)r13.x
mad.f32 r11.x, r24.y, r21.z, (last)r11.x
mad.f32 r9.x, r24.y, r23.x, (last)r9.x
mad.f32 r7.x, r24.y, r23.y, (last)r7.x
mad.f32 r5.x, r24.y, r23.z, (last)r5.x
mad.f32 r17.y, r24.z, r20.w, (last)r17.y
mad.f32 r15.y, r24.z, r21.x, (last)r15.y
mad.f32 r13.y, r24.z, r21.y, (last)r13.y
mad.f32 r11.y, r24.z, r21.z, (last)r11.y
mad.f32 r9.y, r24.z, r23.x, (last)r9.y
mad.f32 r7.y, r24.z, r23.y, (last)r7.y
mad.f32 r5.y, r24.z, r23.z, (last)r5.y
mad.f32 r17.z, r24.w, r20.w, (last)r17.z
mad.f32 r15.z, r24.w, r21.x, (last)r15.z
mad.f32 r13.z, r24.w, r21.y, (last)r13.z
mad.f32 r11.z, r24.w, r21.z, (last)r11.z
mad.f32 r9.z, r24.w, r23.x, (last)r9.z
mad.f32 r7.z, r24.w, r23.y, (last)r7.z
mad.f32 r5.z, r24.w, r23.z, (last)r5.z
mad.f32 r17.w, r25.x, r20.w, (last)r17.w
mad.f32 r15.w, r25.x, r21.x, (last)r15.w
mad.f32 r13.w, r25.x, r21.y, (last)r13.w
mad.f32 r11.w, r25.x, r21.z, (last)r11.w
mad.f32 r9.w, r25.x, r23.x, (last)r9.w
mad.f32 r7.w, r25.x, r23.y, (last)r7.w
mad.f32 r5.w, r25.x, r23.z, (last)r5.w
mad.f32 r16.x, r28.y, r20.w, (last)r16.x
mad.f32 r14.x, r28.y, r21.x, (last)r14.x
mad.f32 r12.x, r28.y, r21.y, (last)r12.x
mad.f32 r10.x, r28.y, r21.z, (last)r10.x
mad.f32 r8.x, r28.y, r23.x, (last)r8.x
mad.f32 r6.x, r28.y, r23.y, (last)r6.x
mad.f32 r4.x, r28.y, r23.z, (last)r4.x
mad.f32 r16.y, r28.z, r20.w, (last)r16.y
mad.f32 r14.y, r28.z, r21.x, (last)r14.y
mad.f32 r12.y, r28.z, r21.y, (last)r12.y
mad.f32 r10.y, r28.z, r21.z, (last)r10.y
mad.f32 r8.y, r28.z, r23.x, (last)r8.y
mad.f32 r6.y, r28.z, r23.y, (last)r6.y
mad.f32 r4.y, r28.z, r23.z, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r28.w, r20.w, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r28.w, r21.x, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r28.w, r21.y, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r28.w, r21.z, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r28.w, r23.x, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r28.w, r23.y, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r28.w, r23.z, (r)(last)r4.z
(rpt1)mad.f32 r24.y, (r)(last)r24.y, r23.w, (r)(last)r18.w
(rpt1)mad.f32 r24.w, (r)(last)r24.w, r23.w, (r)(last)r19.y
ldl.u32 r18.w, l[r25.z+256], 4
(rpt1)mad.f32 r28.y, (r)(last)r28.y, r23.w, (r)(last)r19.w
(rpt1)mad.f32 r28.w, (r)(last)r28.w, r23.w, (r)(last)r20.y
ldl.u32 r19.w, l[r22.z], 4
ldl.u32 r20.w, l[r22.z+256], 4
mad.f32 r17.x, r2.z, r29.y, (last)r17.x
mad.f32 r15.x, r2.z, r29.z, (last)r15.x
mad.f32 r13.x, r2.z, r29.w, (last)r13.x
mad.f32 r11.x, r2.z, r30.x, (last)r11.x
mad.f32 r9.x, r2.z, r30.y, (last)r9.x
mad.f32 r7.x, r2.z, r30.z, (last)r7.x
mad.f32 r5.x, r2.z, r30.w, (last)r5.x
mad.f32 r17.y, r2.w, r29.y, (last)r17.y
mad.f32 r15.y, r2.w, r29.z, (last)r15.y
mad.f32 r13.y, r2.w, r29.w, (last)r13.y
(ss)nop
ldl.u32 r21.w, l[r25.w], 4
ldl.u32 r23.y, l[r25.w+256], 4
mad.f32 r11.y, r2.w, r30.x, (last)r11.y
mad.f32 r9.y, r2.w, r30.y, (last)r9.y
mad.f32 r7.y, r2.w, r30.z, (last)r7.y
mad.f32 r5.y, r2.w, r30.w, (last)r5.y
mad.f32 r17.z, r3.x, r29.y, (last)r17.z
mad.f32 r15.z, r3.x, r29.z, (last)r15.z
mad.f32 r13.z, r3.x, r29.w, (last)r13.z
mad.f32 r11.z, r3.x, r30.x, (last)r11.z
mad.f32 r9.z, r3.x, r30.y, (last)r9.z
mad.f32 r7.z, r3.x, r30.z, (last)r7.z
mad.f32 r5.z, r3.x, r30.w, (last)r5.z
mad.f32 r17.w, r3.y, r29.y, (last)r17.w
mad.f32 r15.w, r3.y, r29.z, (last)r15.w
mad.f32 r13.w, r3.y, r29.w, (last)r13.w
mad.f32 r11.w, r3.y, r30.x, (last)r11.w
mad.f32 r9.w, r3.y, r30.y, (last)r9.w
mad.f32 r7.w, r3.y, r30.z, (last)r7.w
mad.f32 r5.w, r3.y, r30.w, (last)r5.w
mad.f32 r16.x, r18.w, r29.y, (last)r16.x
mad.f32 r14.x, r18.w, r29.z, (last)r14.x
mad.f32 r12.x, r18.w, r29.w, (last)r12.x
mad.f32 r10.x, r18.w, r30.x, (last)r10.x
mad.f32 r8.x, r18.w, r30.y, (last)r8.x
mad.f32 r6.x, r18.w, r30.z, (last)r6.x
mad.f32 r4.x, r18.w, r30.w, (last)r4.x
mad.f32 r16.y, r19.x, r29.y, (last)r16.y
mad.f32 r14.y, r19.x, r29.z, (last)r14.y
mad.f32 r12.y, r19.x, r29.w, (last)r12.y
mad.f32 r10.y, r19.x, r30.x, (last)r10.y
mad.f32 r8.y, r19.x, r30.y, (last)r8.y
mad.f32 r6.y, r19.x, r30.z, (last)r6.y
mad.f32 r4.y, r19.x, r30.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r19.y, r29.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r19.y, r29.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r19.y, r29.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r19.y, r30.x, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r19.y, r30.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r19.y, r30.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r19.y, r30.w, (r)(last)r4.z
(rpt1)mad.f32 r2.z, (r)(last)r2.z, r31.x, (r)(last)r24.y
(rpt1)mad.f32 r3.x, (r)(last)r3.x, r31.x, (r)(last)r24.w
ldl.u32 r24.y, l[r22.w], 4
(rpt1)mad.f32 r18.w, (r)(last)r18.w, r31.x, (r)(last)r28.y
(rpt1)mad.f32 r19.y, (r)(last)r19.y, r31.x, (r)(last)r28.w
ldl.u32 r28.y, l[r22.w+256], 4
ldl.u32 r29.y, l[r26.x], 4
ldl.u32 r30.z, l[r26.x+256], 4
(ss)mad.f32 r17.x, r21.w, r19.w, (last)r17.x
mad.f32 r15.x, r21.w, r20.x, (last)r15.x
mad.f32 r13.x, r21.w, r20.y, (last)r13.x
mad.f32 r11.x, r21.w, r20.z, (last)r11.x
mad.f32 r9.x, r21.w, r20.w, (last)r9.x
mad.f32 r7.x, r21.w, r21.x, (last)r7.x
mad.f32 r5.x, r21.w, r21.y, (last)r5.x
mad.f32 r17.y, r22.x, r19.w, (last)r17.y
mad.f32 r15.y, r22.x, r20.x, (last)r15.y
mad.f32 r13.y, r22.x, r20.y, (last)r13.y
mad.f32 r11.y, r22.x, r20.z, (last)r11.y
mad.f32 r9.y, r22.x, r20.w, (last)r9.y
mad.f32 r7.y, r22.x, r21.x, (last)r7.y
mad.f32 r5.y, r22.x, r21.y, (last)r5.y
mad.f32 r17.z, r22.y, r19.w, (last)r17.z
mad.f32 r15.z, r22.y, r20.x, (last)r15.z
mad.f32 r13.z, r22.y, r20.y, (last)r13.z
mad.f32 r11.z, r22.y, r20.z, (last)r11.z
mad.f32 r9.z, r22.y, r20.w, (last)r9.z
mad.f32 r7.z, r22.y, r21.x, (last)r7.z
mad.f32 r5.z, r22.y, r21.y, (last)r5.z
mad.f32 r17.w, r22.z, r19.w, (last)r17.w
mad.f32 r15.w, r22.z, r20.x, (last)r15.w
mad.f32 r13.w, r22.z, r20.y, (last)r13.w
mad.f32 r11.w, r22.z, r20.z, (last)r11.w
mad.f32 r9.w, r22.z, r20.w, (last)r9.w
mad.f32 r7.w, r22.z, r21.x, (last)r7.w
mad.f32 r5.w, r22.z, r21.y, (last)r5.w
mad.f32 r16.x, r23.y, r19.w, (last)r16.x
mad.f32 r14.x, r23.y, r20.x, (last)r14.x
mad.f32 r12.x, r23.y, r20.y, (last)r12.x
mad.f32 r10.x, r23.y, r20.z, (last)r10.x
mad.f32 r8.x, r23.y, r20.w, (last)r8.x
mad.f32 r6.x, r23.y, r21.x, (last)r6.x
mad.f32 r4.x, r23.y, r21.y, (last)r4.x
mad.f32 r16.y, r23.z, r19.w, (last)r16.y
mad.f32 r14.y, r23.z, r20.x, (last)r14.y
mad.f32 r12.y, r23.z, r20.y, (last)r12.y
mad.f32 r10.y, r23.z, r20.z, (last)r10.y
mad.f32 r8.y, r23.z, r20.w, (last)r8.y
mad.f32 r6.y, r23.z, r21.x, (last)r6.y
mad.f32 r4.y, r23.z, r21.y, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r23.w, r19.w, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r23.w, r20.x, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r23.w, r20.y, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r23.w, r20.z, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r23.w, r20.w, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r23.w, r21.x, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r23.w, r21.y, (r)(last)r4.z
(rpt1)mad.f32 r21.w, (r)(last)r21.w, r21.z, (r)(last)r2.z
ldl.u32 r2.x, l[r27.x], 4
(rpt1)mad.f32 r22.y, (r)(last)r22.y, r21.z, (r)(last)r3.x
ldl.u32 r3.x, l[r27.x+256], 4
(rpt1)mad.f32 r23.y, (r)(last)r23.y, r21.z, (r)(last)r18.w
(rpt1)mad.f32 r23.w, (r)(last)r23.w, r21.z, (r)(last)r19.y
ldl.u32 r18.w, l[r26.y], 4
ldl.u32 r19.w, l[r26.y+256], 4
ldl.u32 r20.w, l[r27.y], 4
mad.f32 r17.x, r29.y, r24.y, (last)r17.x
mad.f32 r15.x, r29.y, r24.z, (last)r15.x
mad.f32 r13.x, r29.y, r24.w, (last)r13.x
mad.f32 r11.x, r29.y, r25.x, (last)r11.x
mad.f32 r9.x, r29.y, r28.y, (last)r9.x
mad.f32 r7.x, r29.y, r28.z, (last)r7.x
mad.f32 r5.x, r29.y, r28.w, (last)r5.x
mad.f32 r17.y, r29.z, r24.y, (last)r17.y
mad.f32 r15.y, r29.z, r24.z, (last)r15.y
mad.f32 r13.y, r29.z, r24.w, (last)r13.y
mad.f32 r11.y, r29.z, r25.x, (last)r11.y
mad.f32 r9.y, r29.z, r28.y, (last)r9.y
mad.f32 r7.y, r29.z, r28.z, (last)r7.y
mad.f32 r5.y, r29.z, r28.w, (last)r5.y
mad.f32 r17.z, r29.w, r24.y, (last)r17.z
mad.f32 r15.z, r29.w, r24.z, (last)r15.z
mad.f32 r13.z, r29.w, r24.w, (last)r13.z
mad.f32 r11.z, r29.w, r25.x, (last)r11.z
mad.f32 r9.z, r29.w, r28.y, (last)r9.z
mad.f32 r7.z, r29.w, r28.z, (last)r7.z
mad.f32 r5.z, r29.w, r28.w, (last)r5.z
mad.f32 r17.w, r30.x, r24.y, (last)r17.w
mad.f32 r15.w, r30.x, r24.z, (last)r15.w
mad.f32 r13.w, r30.x, r24.w, (last)r13.w
mad.f32 r11.w, r30.x, r25.x, (last)r11.w
mad.f32 r9.w, r30.x, r28.y, (last)r9.w
mad.f32 r7.w, r30.x, r28.z, (last)r7.w
mad.f32 r5.w, r30.x, r28.w, (last)r5.w
mad.f32 r16.x, r30.z, r24.y, (last)r16.x
mad.f32 r14.x, r30.z, r24.z, (last)r14.x
mad.f32 r12.x, r30.z, r24.w, (last)r12.x
mad.f32 r10.x, r30.z, r25.x, (last)r10.x
mad.f32 r8.x, r30.z, r28.y, (last)r8.x
mad.f32 r6.x, r30.z, r28.z, (last)r6.x
mad.f32 r4.x, r30.z, r28.w, (last)r4.x
mad.f32 r16.y, r30.w, r24.y, (last)r16.y
mad.f32 r14.y, r30.w, r24.z, (last)r14.y
mad.f32 r12.y, r30.w, r24.w, (last)r12.y
mad.f32 r10.y, r30.w, r25.x, (last)r10.y
mad.f32 r8.y, r30.w, r28.y, (last)r8.y
mad.f32 r6.y, r30.w, r28.z, (last)r6.y
mad.f32 r4.y, r30.w, r28.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r31.x, r24.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r31.x, r24.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r31.x, r24.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r31.x, r25.x, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r31.x, r28.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r31.x, r28.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r31.x, r28.w, (r)(last)r4.z
(rpt1)mad.f32 r29.y, (r)(last)r29.y, r29.x, (r)(last)r21.w
(rpt1)mad.f32 r29.w, (r)(last)r29.w, r29.x, (r)(last)r22.y
ldl.u32 r21.w, l[r27.y+256], 4
(rpt1)mad.f32 r30.z, (r)(last)r30.z, r29.x, (r)(last)r23.y
(rpt1)mad.f32 r31.x, (r)(last)r31.x, r29.x, (r)(last)r23.w
ldl.u32 r23.y, l[r26.z], 4
ldl.u32 r24.y, l[r26.z+256], 4
ldl.u32 r25.y, l[r27.z], 4
ldl.u32 r28.y, l[r27.z+256], 4
(ss)mad.f32 r17.x, r18.w, r2.x, (last)r17.x
mad.f32 r15.x, r18.w, r2.y, (last)r15.x
mad.f32 r13.x, r18.w, r2.z, (last)r13.x
mad.f32 r11.x, r18.w, r2.w, (last)r11.x
mad.f32 r9.x, r18.w, r3.x, (last)r9.x
mad.f32 r7.x, r18.w, r3.y, (last)r7.x
mad.f32 r5.x, r18.w, r3.z, (last)r5.x
mad.f32 r17.y, r19.x, r2.x, (last)r17.y
mad.f32 r15.y, r19.x, r2.y, (last)r15.y
mad.f32 r13.y, r19.x, r2.z, (last)r13.y
mad.f32 r11.y, r19.x, r2.w, (last)r11.y
mad.f32 r9.y, r19.x, r3.x, (last)r9.y
mad.f32 r7.y, r19.x, r3.y, (last)r7.y
mad.f32 r5.y, r19.x, r3.z, (last)r5.y
mad.f32 r17.z, r19.y, r2.x, (last)r17.z
mad.f32 r15.z, r19.y, r2.y, (last)r15.z
mad.f32 r13.z, r19.y, r2.z, (last)r13.z
mad.f32 r11.z, r19.y, r2.w, (last)r11.z
mad.f32 r9.z, r19.y, r3.x, (last)r9.z
mad.f32 r7.z, r19.y, r3.y, (last)r7.z
mad.f32 r5.z, r19.y, r3.z, (last)r5.z
mad.f32 r17.w, r19.z, r2.x, (last)r17.w
mad.f32 r15.w, r19.z, r2.y, (last)r15.w
mad.f32 r13.w, r19.z, r2.z, (last)r13.w
mad.f32 r11.w, r19.z, r2.w, (last)r11.w
mad.f32 r9.w, r19.z, r3.x, (last)r9.w
mad.f32 r7.w, r19.z, r3.y, (last)r7.w
mad.f32 r5.w, r19.z, r3.z, (last)r5.w
(rpt1)mad.f32 r18.w, (r)(last)r18.w, r3.w, (r)(last)r29.y
(rpt1)mad.f32 r19.y, (r)(last)r19.y, r3.w, (r)(last)r29.w
ldl.u32 r29.z, l[r26.w], 4
mad.f32 r16.x, r19.w, r2.x, (last)r16.x
mad.f32 r14.x, r19.w, r2.y, (last)r14.x
mad.f32 r12.x, r19.w, r2.z, (last)r12.x
mad.f32 r10.x, r19.w, r2.w, (last)r10.x
mad.f32 r8.x, r19.w, r3.x, (last)r8.x
mad.f32 r6.x, r19.w, r3.y, (last)r6.x
mad.f32 r4.x, r19.w, r3.z, (last)r4.x
mad.f32 r16.y, r20.x, r2.x, (last)r16.y
mad.f32 r14.y, r20.x, r2.y, (last)r14.y
mad.f32 r12.y, r20.x, r2.z, (last)r12.y
mad.f32 r10.y, r20.x, r2.w, (last)r10.y
mad.f32 r8.y, r20.x, r3.x, (last)r8.y
mad.f32 r6.y, r20.x, r3.y, (last)r6.y
mad.f32 r4.y, r20.x, r3.z, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r20.y, r2.x, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r20.y, r2.y, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r20.y, r2.z, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r20.y, r2.w, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r20.y, r3.x, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r20.y, r3.y, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r20.y, r3.z, (r)(last)r4.z
mad.f32 r17.x, r23.y, r20.w, (last)r17.x
mad.f32 r15.x, r23.y, r21.x, (last)r15.x
mad.f32 r13.x, r23.y, r21.y, (last)r13.x
mad.f32 r11.x, r23.y, r21.z, (last)r11.x
mad.f32 r9.x, r23.y, r21.w, (last)r9.x
mad.f32 r7.x, r23.y, r22.x, (last)r7.x
mad.f32 r5.x, r23.y, r22.y, (last)r5.x
mad.f32 r17.y, r23.z, r20.w, (last)r17.y
mad.f32 r15.y, r23.z, r21.x, (last)r15.y
mad.f32 r13.y, r23.z, r21.y, (last)r13.y
mad.f32 r11.y, r23.z, r21.z, (last)r11.y
mad.f32 r9.y, r23.z, r21.w, (last)r9.y
mad.f32 r7.y, r23.z, r22.x, (last)r7.y
mad.f32 r5.y, r23.z, r22.y, (last)r5.y
mad.f32 r17.z, r23.w, r20.w, (last)r17.z
mad.f32 r15.z, r23.w, r21.x, (last)r15.z
mad.f32 r13.z, r23.w, r21.y, (last)r13.z
mad.f32 r11.z, r23.w, r21.z, (last)r11.z
mad.f32 r9.z, r23.w, r21.w, (last)r9.z
mad.f32 r7.z, r23.w, r22.x, (last)r7.z
mad.f32 r5.z, r23.w, r22.y, (last)r5.z
mad.f32 r17.w, r24.x, r20.w, (last)r17.w
mad.f32 r15.w, r24.x, r21.x, (last)r15.w
mad.f32 r13.w, r24.x, r21.y, (last)r13.w
mad.f32 r11.w, r24.x, r21.z, (last)r11.w
mad.f32 r9.w, r24.x, r21.w, (last)r9.w
mad.f32 r7.w, r24.x, r22.x, (last)r7.w
mad.f32 r5.w, r24.x, r22.y, (last)r5.w
(rpt1)mad.f32 r19.w, (r)(last)r19.w, r3.w, (r)(last)r30.z
(rpt1)mad.f32 r20.y, (r)(last)r20.y, r3.w, (r)(last)r31.x
ldl.u32 r30.z, l[r26.w+256], 4
ldl.u32 r2.x, l[r27.w], 4
ldl.u32 r3.x, l[r27.w+256], 4
(rpt1)mad.f32 r23.y, (r)(last)r23.y, r22.z, (r)(last)r18.w
(rpt1)mad.f32 r23.w, (r)(last)r23.w, r22.z, (r)(last)r19.y
ldl.u32 r18.w, l[r18.z], 4
mad.f32 r16.x, r24.y, r20.w, (last)r16.x
mad.f32 r14.x, r24.y, r21.x, (last)r14.x
mad.f32 r12.x, r24.y, r21.y, (last)r12.x
mad.f32 r10.x, r24.y, r21.z, (last)r10.x
mad.f32 r8.x, r24.y, r21.w, (last)r8.x
mad.f32 r6.x, r24.y, r22.x, (last)r6.x
mad.f32 r4.x, r24.y, r22.y, (last)r4.x
mad.f32 r16.y, r24.z, r20.w, (last)r16.y
mad.f32 r14.y, r24.z, r21.x, (last)r14.y
mad.f32 r12.y, r24.z, r21.y, (last)r12.y
(ss)mad.f32 r17.x, r29.z, r25.y, (last)r17.x
mad.f32 r15.x, r29.z, r25.z, (last)r15.x
mad.f32 r13.x, r29.z, r25.w, (last)r13.x
mad.f32 r11.x, r29.z, r26.x, (last)r11.x
mad.f32 r9.x, r29.z, r28.y, (last)r9.x
mad.f32 r7.x, r29.z, r28.z, (last)r7.x
mad.f32 r5.x, r29.z, r28.w, (last)r5.x
mad.f32 r17.y, r29.w, r25.y, (last)r17.y
mad.f32 r15.y, r29.w, r25.z, (last)r15.y
mad.f32 r13.y, r29.w, r25.w, (last)r13.y
mad.f32 r11.y, r29.w, r26.x, (last)r11.y
mad.f32 r9.y, r29.w, r28.y, (last)r9.y
mad.f32 r7.y, r29.w, r28.z, (last)r7.y
mad.f32 r5.y, r29.w, r28.w, (last)r5.y
mad.f32 r17.z, r30.x, r25.y, (last)r17.z
mad.f32 r15.z, r30.x, r25.z, (last)r15.z
mad.f32 r13.z, r30.x, r25.w, (last)r13.z
mad.f32 r11.z, r30.x, r26.x, (last)r11.z
mad.f32 r9.z, r30.x, r28.y, (last)r9.z
mad.f32 r7.z, r30.x, r28.z, (last)r7.z
mad.f32 r5.z, r30.x, r28.w, (last)r5.z
mad.f32 r17.w, r30.y, r25.y, (last)r17.w
mad.f32 r15.w, r30.y, r25.z, (last)r15.w
mad.f32 r13.w, r30.y, r25.w, (last)r13.w
mad.f32 r11.w, r30.y, r26.x, (last)r11.w
mad.f32 r9.w, r30.y, r28.y, (last)r9.w
mad.f32 r7.w, r30.y, r28.z, (last)r7.w
mad.f32 r5.w, r30.y, r28.w, (last)r5.w
(rpt1)mad.f32 r29.z, (r)(last)r29.z, r29.x, (r)(last)r23.y
(rpt1)mad.f32 r30.x, (r)(last)r30.x, r29.x, (r)(last)r23.w
mad.f32 r10.y, r24.z, r21.z, (last)r10.y
mad.f32 r8.y, r24.z, r21.w, (last)r8.y
mad.f32 r6.y, r24.z, r22.x, (last)r6.y
mad.f32 r4.y, r24.z, r22.y, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r24.w, r20.w, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r24.w, r21.x, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r24.w, r21.y, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r24.w, r21.z, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r24.w, r21.w, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r24.w, r22.x, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r24.w, r22.y, (r)(last)r4.z
mad.f32 r24.y, (last)r24.y, r22.z, (last)r19.w
mad.f32 r17.x, r18.w, r2.x, (last)r17.x
mad.f32 r15.x, r18.w, r2.y, (last)r15.x
mad.f32 r13.x, r18.w, r2.z, (last)r13.x
mad.f32 r11.x, r18.w, r2.w, (last)r11.x
mad.f32 r9.x, r18.w, r3.x, (last)r9.x
mad.f32 r7.x, r18.w, r3.y, (last)r7.x
mad.f32 r5.x, r18.w, r3.z, (last)r5.x
mad.f32 r17.y, r19.x, r2.x, (last)r17.y
mad.f32 r15.y, r19.x, r2.y, (last)r15.y
mad.f32 r13.y, r19.x, r2.z, (last)r13.y
mad.f32 r11.y, r19.x, r2.w, (last)r11.y
mad.f32 r9.y, r19.x, r3.x, (last)r9.y
mad.f32 r7.y, r19.x, r3.y, (last)r7.y
mad.f32 r5.y, r19.x, r3.z, (last)r5.y
mad.f32 r17.z, r19.y, r2.x, (last)r17.z
mad.f32 r15.z, r19.y, r2.y, (last)r15.z
mad.f32 r13.z, r19.y, r2.z, (last)r13.z
mad.f32 r11.z, r19.y, r2.w, (last)r11.z
mad.f32 r9.z, r19.y, r3.x, (last)r9.z
mad.f32 r7.z, r19.y, r3.y, (last)r7.z
mad.f32 r5.z, r19.y, r3.z, (last)r5.z
mad.f32 r17.w, r19.z, r2.x, (last)r17.w
mad.f32 r15.w, r19.z, r2.y, (last)r15.w
mad.f32 r13.w, r19.z, r2.z, (last)r13.w
mad.f32 r11.w, r19.z, r2.w, (last)r11.w
mad.f32 r9.w, r19.z, r3.x, (last)r9.w
mad.f32 r7.w, r19.z, r3.y, (last)r7.w
mad.f32 r5.w, r19.z, r3.z, (last)r5.w
mad.f32 r24.z, (last)r24.z, r22.z, (last)r20.x
(rpt1)mad.f32 r24.w, (r)(last)r24.w, r22.z, (r)(last)r20.y
(rpt1)mad.f32 r19.w, (r)(last)r18.w, r3.w, (r)(last)r29.z
(rpt1)mad.f32 r20.y, (r)(last)r19.y, r3.w, (r)(last)r30.x
ldl.u32 r18.w, l[r18.z+256], 4
mad.f32 r16.x, r30.z, r25.y, (last)r16.x
mad.f32 r14.x, r30.z, r25.z, (last)r14.x
mad.f32 r12.x, r30.z, r25.w, (last)r12.x
mad.f32 r10.x, r30.z, r26.x, (last)r10.x
mad.f32 r8.x, r30.z, r28.y, (last)r8.x
mad.f32 r6.x, r30.z, r28.z, (last)r6.x
mad.f32 r4.x, r30.z, r28.w, (last)r4.x
mad.f32 r16.y, r30.w, r25.y, (last)r16.y
mad.f32 r14.y, r30.w, r25.z, (last)r14.y
mad.f32 r12.y, r30.w, r25.w, (last)r12.y
mad.f32 r10.y, r30.w, r26.x, (last)r10.y
mad.f32 r8.y, r30.w, r28.y, (last)r8.y
mad.f32 r6.y, r30.w, r28.z, (last)r6.y
mad.f32 r4.y, r30.w, r28.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r31.x, r25.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r31.x, r25.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r31.x, r25.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r31.x, r26.x, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r31.x, r28.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r31.x, r28.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r31.x, r28.w, (r)(last)r4.z
(rpt1)mad.f32 r30.z, (r)(last)r30.z, r29.x, (r)(last)r24.y
(rpt1)mad.f32 r31.x, (r)(last)r31.x, r29.x, (r)(last)r24.w
(ss)mad.f32 r16.x, r18.w, r2.x, (last)r16.x
mad.f32 r14.x, r18.w, r2.y, (last)r14.x
mad.f32 r12.x, r18.w, r2.z, (last)r12.x
mad.f32 r10.x, r18.w, r2.w, (last)r10.x
mad.f32 r8.x, r18.w, r3.x, (last)r8.x
mad.f32 r6.x, r18.w, r3.y, (last)r6.x
mad.f32 r4.x, r18.w, r3.z, (last)r4.x
mad.f32 r16.y, r19.x, r2.x, (last)r16.y
mad.f32 r14.y, r19.x, r2.y, (last)r14.y
mad.f32 r12.y, r19.x, r2.z, (last)r12.y
mad.f32 r10.y, r19.x, r2.w, (last)r10.y
mad.f32 r8.y, r19.x, r3.x, (last)r8.y
mad.f32 r6.y, r19.x, r3.y, (last)r6.y
mad.f32 r4.y, r19.x, r3.z, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r19.y, r2.x, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r19.y, r2.y, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r19.y, r2.z, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r19.y, r2.w, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r19.y, r3.x, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r19.y, r3.y, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r19.y, r3.z, (r)(last)r4.z
(rpt1)mad.f32 r23.w, (r)(last)r18.w, r3.w, (r)(last)r30.z
(rpt1)mad.f32 r2.z, (r)(last)r19.y, r3.w, (r)(last)r31.x
cov.f32f16 hr41.z, r17.x
cov.f32f16 hr42.z, r15.x
cov.f32f16 hr43.z, r13.x
cov.f32f16 hr44.z, r11.x
cov.f32f16 hr45.z, r9.x
cov.f32f16 hr46.z, r7.x
cov.f32f16 hr0.z, r5.x
cov.f32f16 hr41.w, r17.y
cov.f32f16 hr42.w, r15.y
cov.f32f16 hr43.w, r13.y
cov.f32f16 hr44.w, r11.y
cov.f32f16 hr45.w, r9.y
cov.f32f16 hr46.w, r7.y
cov.f32f16 hr0.w, r5.y
cov.f32f16 hr42.x, r17.z
cov.f32f16 hr43.x, r15.z
cov.f32f16 hr44.x, r13.z
cov.f32f16 hr46.x, r9.z
cov.f32f16 hr47.x, r7.z
cov.f32f16 hr1.x, r5.z
cov.f32f16 hr42.y, r17.w
cov.f32f16 hr43.y, r15.w
cov.f32f16 hr44.y, r13.w
cov.f32f16 hr46.y, r9.w
cov.f32f16 hr47.y, r7.w
cov.f32f16 hr1.y, r5.w
(rpt1)cov.f32f16 hr45.x, (r)r11.z
(rpt1)cov.f32f16 hr36.x, (r)r19.w
(rpt1)cov.f32f16 hr36.z, (r)r20.y
fence.r.w
(sy)(ss)mov.u32u32 r25.y, (last)r1.z
mov.u32u32 r24.y, (last)r0.x
mov.u32u32 r24.z, (last)r0.w
mov.u32u32 r24.w, (last)r1.x
mov.u32u32 r25.x, (last)r1.y
(rpt1)cov.f32f16 hr37.x, (r)r10.x
cov.f32f16 hr4.x, r16.x
cov.f32f16 hr4.z, r16.y
cov.f32f16 hr4.w, r8.y
(rpt1)cov.f32f16 hr6.x, (r)r14.x
cov.f32f16 hr6.z, r6.y
(rpt1)cov.f32f16 hr7.x, (r)r12.x
cov.f32f16 hr4.y, r23.w
(rpt1)cov.f32f16 hr37.z, (r)r14.z
cov.f32f16 hr6.w, r24.x
cov.f32f16 hr38.x, r8.x
cov.f32f16 hr38.y, r6.x
(rpt1)cov.f32f16 hr38.z, (r)r4.x
(rpt1)cov.f32f16 hr39.x, (r)r12.z
(rpt1)cov.f32f16 hr7.z, (r)r16.z
bar.g
(sy)(ss)cov.f32f16 hr3.x, r4.w
cov.f32f16 hr3.y, r2.w
(rpt1)cov.f32f16 hr0.x, (r)r10.z
(rpt1)cov.f32f16 hr1.z, (r)r8.z
(rpt1)cov.f32f16 hr2.x, (r)r6.z
cov.f32f16 hr2.z, r4.z
cov.f32f16 hr2.w, r2.z
br p0.x, #l1194
mov.u32u32 r2.x, (last)r23.w
mov.u32u32 r2.y, (last)r24.x
mov.u32u32 r3.w, (last)r20.z
mov.u32u32 r3.z, (last)r20.y
mov.u32u32 r3.y, (last)r20.x
mov.u32u32 r3.x, (last)r19.w
mov.u32u32 r0.x, (last)r24.y
mov.u32u32 r0.w, (last)r24.z
mov.u32u32 r1.x, (last)r24.w
mov.u32u32 r1.y, r25.x
mov.u32u32 r1.z, (last)r25.y
jump #l130
l1194:
(jp)(eolm)nop
add.u r28.x, r51.z, (last)r28.x
mov.u16u16 hr5.x, (last)hr4.x
mov.u16u16 hr5.y, (last)hr4.z
mov.u16u16 hr5.z, (last)hr7.z
shl.b r28.x, (last)r28.x, 9
mov.u16u16 hr5.w, (last)hr7.w
mov.u16u16 hr9.z, (last)hr6.x
mov.u16u16 hr9.w, (last)hr6.y
sad.s32 r28.x, r52.z, r28.x, (last)r25.x
mov.u16u16 hr10.x, (last)hr37.z
mov.u16u16 hr10.y, (last)hr37.w
mov.u16u16 hr10.z, (last)hr7.x
shl.b r28.x, (last)r28.x, 2
mov.u16u16 hr10.w, (last)hr7.y
mov.u16u16 hr11.x, (last)hr39.x
mov.u16u16 hr11.y, (last)hr39.y
mov.u16u16 hr13.x, (last)hr37.x
mov.u16u16 hr13.y, (last)hr37.y
mov.u16u16 hr13.z, (last)hr0.x
mov.u16u16 hr13.w, (last)hr0.y
mov.u16u16 hr14.x, (last)hr38.x
mov.u16u16 hr14.y, (last)hr4.w
mov.u16u16 hr14.z, (last)hr1.z
mov.u16u16 hr14.w, (last)hr1.w
mov.u16u16 hr17.x, (last)hr38.z
mov.u16u16 hr17.y, (last)hr38.w
mov.u16u16 hr17.z, (last)hr2.z
mov.u16u16 hr17.w, (last)hr3.x
stib.b.untyped.1d.u16.4.imm.base0 hr41.z, r28.x, 4
add.u r3.w, r28.x, c1.x
add.u r4.x, r28.x, c7.z
add.u r4.y, r28.x, c5.y
add.u r4.z, r28.x, c7.w
add.u r5.w, r28.x, c3.y
(rpt1)add.u r6.x, r28.x, (r)c8.x
(rpt1)add.u r7.z, (r)c8.z, r28.x
(rpt1)add.u r8.x, (r)c9.x, r28.x
(rpt1)add.u r9.x, (r)c9.z, r28.x
mov.u16u16 hr1.z, (last)hr38.y
mov.u16u16 hr1.w, (last)hr6.z
mov.u16u16 hr2.z, (last)hr4.y
mov.u16u16 hr3.x, (last)hr2.w
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r28.x+64, 4
mov.u16u16 hr2.w, (last)hr6.w
(ss)add.u r28.x, c10.x, (last)r28.x
stib.b.untyped.1d.u16.4.imm.base0 hr42.z, r3.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r4.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr43.z, r4.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r4.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr44.z, r5.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.x, r6.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr45.z, r6.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.x, r7.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr46.z, r7.w, 4
(rpt1)nop
stib.b.untyped.1d.u16.4.imm.base0 hr1.z, r8.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr0.z, r8.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr17.x, r9.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr36.x, r9.y, 4
(rpt3)nop
stib.b.untyped.1d.u16.4.imm.base0 hr2.z, r28.x, 4
end
nop
nop
nop
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1381 instr, 9 nops, 1372 non-nops, 110 mov, 64 cov, 2528 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 32 full, 12 constlen
; CL prog 23/1: 12 cat0, 174 cat1, 72 cat2, 1031 cat3, 0 cat4, 4 cat5, 84 cat6, 4 cat7
; CL prog 23/1: 100 sstall, 20 (ss), 19 systall, 5 (sy), 1 loops
; CL prog 23/1: 8 max_waves, 0 double_threadsize
; 57 preamble-instr, 1 early-preamble
