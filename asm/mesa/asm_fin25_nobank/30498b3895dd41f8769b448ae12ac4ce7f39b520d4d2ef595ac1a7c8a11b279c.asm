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
(rpt1)nop
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
add.u r25.z, c4.z, r18.z
add.u r22.z, c4.y, r1.w
add.u r25.w, c4.x, r18.z
add.u r22.w, c3.w, r1.w
add.u r27.x, c3.y, r1.w
add.u r26.x, c3.z, r18.z
add.u r26.y, c3.x, r18.z
add.u r27.y, c2.w, r1.w
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
(ss)mad.f32 r16.x, r28.y, r18.w, (last)r16.x
mad.f32 r14.x, r28.y, r19.x, (last)r14.x
mad.f32 r12.x, r28.y, r19.y, (last)r12.x
mad.f32 r10.x, r28.y, r19.z, (last)r10.x
mad.f32 r8.x, r28.y, r19.w, (last)r8.x
mad.f32 r6.x, r28.y, r20.x, (last)r6.x
mad.f32 r4.x, r28.y, r20.y, (last)r4.x
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
(rpt1)mad.f32 r28.y, (r)(last)r28.y, r20.z, (r)(last)r2.x
(rpt1)mad.f32 r28.w, (r)(last)r28.w, r20.z, (r)(last)r2.z
ldl.u32 r2.x, l[r23.z], 4
mad.f32 r17.x, r20.w, r18.w, (last)r17.x
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
mad.f32 r9.y, r21.x, r19.w, (last)r9.y
mad.f32 r7.y, r21.x, r20.x, (last)r7.y
mad.f32 r5.y, r21.x, r20.y, (last)r5.y
mad.f32 r17.z, r21.y, r18.w, (last)r17.z
mad.f32 r15.z, r21.y, r19.x, (last)r15.z
mad.f32 r13.z, r21.y, r19.y, (last)r13.z
mad.f32 r11.z, r21.y, r19.z, (last)r11.z
mad.f32 r9.z, r21.y, r19.w, (last)r9.z
mad.f32 r7.z, r21.y, r20.x, (last)r7.z
mad.f32 r5.z, r21.y, r20.y, (last)r5.z
mad.f32 r17.w, r21.z, r18.w, (last)r17.w
mad.f32 r15.w, r21.z, r19.x, (last)r15.w
mad.f32 r13.w, r21.z, r19.y, (last)r13.w
mad.f32 r11.w, r21.z, r19.z, (last)r11.w
mad.f32 r9.w, r21.z, r19.w, (last)r9.w
mad.f32 r7.w, r21.z, r20.x, (last)r7.w
mad.f32 r5.w, r21.z, r20.y, (last)r5.w
(rpt1)mad.f32 r20.w, (r)(last)r20.w, r20.z, (r)(last)r3.x
(rpt1)mad.f32 r21.y, (r)(last)r21.y, r20.z, (r)(last)r3.z
ldl.u32 r3.x, l[r23.z+256], 4
ldl.u32 r18.w, l[r1.w+1024], 4
ldl.u32 r19.w, l[r1.w+1280], 4
(ss)mad.f32 r17.x, r2.x, r29.y, (last)r17.x
mad.f32 r15.x, r2.x, r29.z, (last)r15.x
mad.f32 r13.x, r2.x, r29.w, (last)r13.x
mad.f32 r11.x, r2.x, r30.x, (last)r11.x
mad.f32 r9.x, r2.x, r30.y, (last)r9.x
mad.f32 r7.x, r2.x, r30.z, (last)r7.x
mad.f32 r5.x, r2.x, r30.w, (last)r5.x
mad.f32 r17.y, r2.y, r29.y, (last)r17.y
mad.f32 r15.y, r2.y, r29.z, (last)r15.y
mad.f32 r13.y, r2.y, r29.w, (last)r13.y
mad.f32 r11.y, r2.y, r30.x, (last)r11.y
mad.f32 r9.y, r2.y, r30.y, (last)r9.y
mad.f32 r7.y, r2.y, r30.z, (last)r7.y
mad.f32 r5.y, r2.y, r30.w, (last)r5.y
mad.f32 r17.z, r2.z, r29.y, (last)r17.z
mad.f32 r15.z, r2.z, r29.z, (last)r15.z
mad.f32 r13.z, r2.z, r29.w, (last)r13.z
mad.f32 r11.z, r2.z, r30.x, (last)r11.z
mad.f32 r9.z, r2.z, r30.y, (last)r9.z
mad.f32 r7.z, r2.z, r30.z, (last)r7.z
mad.f32 r5.z, r2.z, r30.w, (last)r5.z
mad.f32 r17.w, r2.w, r29.y, (last)r17.w
mad.f32 r15.w, r2.w, r29.z, (last)r15.w
mad.f32 r13.w, r2.w, r29.w, (last)r13.w
mad.f32 r11.w, r2.w, r30.x, (last)r11.w
mad.f32 r9.w, r2.w, r30.y, (last)r9.w
mad.f32 r7.w, r2.w, r30.z, (last)r7.w
mad.f32 r5.w, r2.w, r30.w, (last)r5.w
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r31.x, (r)(last)r20.w
(rpt1)mad.f32 r2.z, (r)(last)r2.z, r31.x, (r)(last)r21.y
ldl.u32 r20.w, l[r23.w], 4
mad.f32 r16.x, r3.x, r29.y, (last)r16.x
mad.f32 r14.x, r3.x, r29.z, (last)r14.x
mad.f32 r12.x, r3.x, r29.w, (last)r12.x
mad.f32 r10.x, r3.x, r30.x, (last)r10.x
mad.f32 r8.x, r3.x, r30.y, (last)r8.x
mad.f32 r6.x, r3.x, r30.z, (last)r6.x
mad.f32 r4.x, r3.x, r30.w, (last)r4.x
mad.f32 r16.y, r3.y, r29.y, (last)r16.y
mad.f32 r14.y, r3.y, r29.z, (last)r14.y
mad.f32 r12.y, r3.y, r29.w, (last)r12.y
(ss)nop
ldl.u32 r23.x, l[r23.w+256], 4
mad.f32 r10.y, r3.y, r30.x, (last)r10.y
mad.f32 r8.y, r3.y, r30.y, (last)r8.y
mad.f32 r6.y, r3.y, r30.z, (last)r6.y
mad.f32 r4.y, r3.y, r30.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r3.z, r29.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r3.z, r29.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r3.z, r29.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r3.z, r30.x, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r3.z, r30.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r3.z, r30.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r3.z, r30.w, (r)(last)r4.z
(rpt1)mad.f32 r3.x, (r)(last)r3.x, r31.x, (r)(last)r28.y
(rpt1)mad.f32 r3.z, (r)(last)r3.z, r31.x, (r)(last)r28.w
ldl.u32 r28.y, l[r1.w+1536], 4
ldl.u32 r29.y, l[r1.w+1792], 4
ldl.u32 r30.y, l[r24.x], 4
mad.f32 r17.x, r20.w, r18.w, (last)r17.x
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
mad.f32 r9.y, r21.x, r19.w, (last)r9.y
mad.f32 r7.y, r21.x, r20.x, (last)r7.y
mad.f32 r5.y, r21.x, r20.y, (last)r5.y
mad.f32 r17.z, r21.y, r18.w, (last)r17.z
mad.f32 r15.z, r21.y, r19.x, (last)r15.z
mad.f32 r13.z, r21.y, r19.y, (last)r13.z
mad.f32 r11.z, r21.y, r19.z, (last)r11.z
mad.f32 r9.z, r21.y, r19.w, (last)r9.z
mad.f32 r7.z, r21.y, r20.x, (last)r7.z
mad.f32 r5.z, r21.y, r20.y, (last)r5.z
mad.f32 r17.w, r21.z, r18.w, (last)r17.w
mad.f32 r15.w, r21.z, r19.x, (last)r15.w
mad.f32 r13.w, r21.z, r19.y, (last)r13.w
mad.f32 r11.w, r21.z, r19.z, (last)r11.w
mad.f32 r9.w, r21.z, r19.w, (last)r9.w
mad.f32 r7.w, r21.z, r20.x, (last)r7.w
mad.f32 r5.w, r21.z, r20.y, (last)r5.w
(ss)mad.f32 r16.x, r23.x, r18.w, (last)r16.x
mad.f32 r14.x, r23.x, r19.x, (last)r14.x
mad.f32 r12.x, r23.x, r19.y, (last)r12.x
mad.f32 r10.x, r23.x, r19.z, (last)r10.x
mad.f32 r8.x, r23.x, r19.w, (last)r8.x
mad.f32 r6.x, r23.x, r20.x, (last)r6.x
mad.f32 r4.x, r23.x, r20.y, (last)r4.x
mad.f32 r16.y, r23.y, r18.w, (last)r16.y
mad.f32 r14.y, r23.y, r19.x, (last)r14.y
mad.f32 r12.y, r23.y, r19.y, (last)r12.y
mad.f32 r10.y, r23.y, r19.z, (last)r10.y
mad.f32 r8.y, r23.y, r19.w, (last)r8.y
mad.f32 r6.y, r23.y, r20.x, (last)r6.y
mad.f32 r4.y, r23.y, r20.y, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r23.z, r18.w, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r23.z, r19.x, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r23.z, r19.y, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r23.z, r19.z, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r23.z, r19.w, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r23.z, r20.x, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r23.z, r20.y, (r)(last)r4.z
(rpt1)mad.f32 r20.w, (r)(last)r20.w, r20.z, (r)(last)r2.x
(rpt1)mad.f32 r21.y, (r)(last)r21.y, r20.z, (r)(last)r2.z
ldl.u32 r2.x, l[r24.x+256], 4
(rpt1)mad.f32 r23.x, (r)(last)r23.x, r20.z, (r)(last)r3.x
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r20.z, (r)(last)r3.z
ldl.u32 r3.x, l[r1.w+2048], 4
ldl.u32 r18.w, l[r1.w+2304], 4
ldl.u32 r19.w, l[r24.y], 4
mad.f32 r17.x, r30.y, r28.y, (last)r17.x
mad.f32 r15.x, r30.y, r28.z, (last)r15.x
mad.f32 r13.x, r30.y, r28.w, (last)r13.x
mad.f32 r11.x, r30.y, r29.x, (last)r11.x
mad.f32 r9.x, r30.y, r29.y, (last)r9.x
mad.f32 r7.x, r30.y, r29.z, (last)r7.x
mad.f32 r5.x, r30.y, r29.w, (last)r5.x
mad.f32 r17.y, r30.z, r28.y, (last)r17.y
mad.f32 r15.y, r30.z, r28.z, (last)r15.y
mad.f32 r13.y, r30.z, r28.w, (last)r13.y
mad.f32 r11.y, r30.z, r29.x, (last)r11.y
mad.f32 r9.y, r30.z, r29.y, (last)r9.y
mad.f32 r7.y, r30.z, r29.z, (last)r7.y
mad.f32 r5.y, r30.z, r29.w, (last)r5.y
mad.f32 r17.z, r30.w, r28.y, (last)r17.z
mad.f32 r15.z, r30.w, r28.z, (last)r15.z
mad.f32 r13.z, r30.w, r28.w, (last)r13.z
mad.f32 r11.z, r30.w, r29.x, (last)r11.z
mad.f32 r9.z, r30.w, r29.y, (last)r9.z
mad.f32 r7.z, r30.w, r29.z, (last)r7.z
mad.f32 r5.z, r30.w, r29.w, (last)r5.z
mad.f32 r17.w, r31.x, r28.y, (last)r17.w
mad.f32 r15.w, r31.x, r28.z, (last)r15.w
mad.f32 r13.w, r31.x, r28.w, (last)r13.w
mad.f32 r11.w, r31.x, r29.x, (last)r11.w
mad.f32 r9.w, r31.x, r29.y, (last)r9.w
mad.f32 r7.w, r31.x, r29.z, (last)r7.w
mad.f32 r5.w, r31.x, r29.w, (last)r5.w
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r30.x, (r)(last)r20.w
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r30.x, (r)(last)r21.y
ldl.u32 r20.w, l[r24.y+256], 4
(ss)mad.f32 r16.x, r2.x, r28.y, (last)r16.x
mad.f32 r14.x, r2.x, r28.z, (last)r14.x
mad.f32 r12.x, r2.x, r28.w, (last)r12.x
mad.f32 r10.x, r2.x, r29.x, (last)r10.x
mad.f32 r8.x, r2.x, r29.y, (last)r8.x
mad.f32 r6.x, r2.x, r29.z, (last)r6.x
mad.f32 r4.x, r2.x, r29.w, (last)r4.x
mad.f32 r16.y, r2.y, r28.y, (last)r16.y
mad.f32 r14.y, r2.y, r28.z, (last)r14.y
mad.f32 r12.y, r2.y, r28.w, (last)r12.y
mad.f32 r10.y, r2.y, r29.x, (last)r10.y
mad.f32 r8.y, r2.y, r29.y, (last)r8.y
mad.f32 r6.y, r2.y, r29.z, (last)r6.y
mad.f32 r4.y, r2.y, r29.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r2.z, r28.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r2.z, r28.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r2.z, r28.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r2.z, r29.x, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r2.z, r29.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r2.z, r29.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r2.z, r29.w, (r)(last)r4.z
mad.f32 r17.x, r19.w, r3.x, (last)r17.x
mad.f32 r15.x, r19.w, r3.y, (last)r15.x
mad.f32 r13.x, r19.w, r3.z, (last)r13.x
mad.f32 r11.x, r19.w, r3.w, (last)r11.x
mad.f32 r9.x, r19.w, r18.w, (last)r9.x
mad.f32 r7.x, r19.w, r19.x, (last)r7.x
mad.f32 r5.x, r19.w, r19.y, (last)r5.x
mad.f32 r17.y, r20.x, r3.x, (last)r17.y
mad.f32 r15.y, r20.x, r3.y, (last)r15.y
mad.f32 r13.y, r20.x, r3.z, (last)r13.y
mad.f32 r11.y, r20.x, r3.w, (last)r11.y
mad.f32 r9.y, r20.x, r18.w, (last)r9.y
mad.f32 r7.y, r20.x, r19.x, (last)r7.y
mad.f32 r5.y, r20.x, r19.y, (last)r5.y
mad.f32 r17.z, r20.y, r3.x, (last)r17.z
mad.f32 r15.z, r20.y, r3.y, (last)r15.z
mad.f32 r13.z, r20.y, r3.z, (last)r13.z
mad.f32 r11.z, r20.y, r3.w, (last)r11.z
mad.f32 r9.z, r20.y, r18.w, (last)r9.z
mad.f32 r7.z, r20.y, r19.x, (last)r7.z
mad.f32 r5.z, r20.y, r19.y, (last)r5.z
mad.f32 r17.w, r20.z, r3.x, (last)r17.w
mad.f32 r15.w, r20.z, r3.y, (last)r15.w
mad.f32 r13.w, r20.z, r3.z, (last)r13.w
mad.f32 r11.w, r20.z, r3.w, (last)r11.w
mad.f32 r9.w, r20.z, r18.w, (last)r9.w
mad.f32 r7.w, r20.z, r19.x, (last)r7.w
mad.f32 r5.w, r20.z, r19.y, (last)r5.w
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r30.x, (r)(last)r23.x
(rpt1)mad.f32 r2.z, (r)(last)r2.z, r30.x, (r)(last)r23.z
ldl.u32 r23.x, l[r1.w+2560], 4
ldl.u32 r28.y, l[r1.w+2816], 4
ldl.u32 r29.y, l[r24.z], 4
(rpt1)mad.f32 r19.w, (r)(last)r19.w, r19.z, (r)(last)r30.y
(rpt1)mad.f32 r20.y, (r)(last)r20.y, r19.z, (r)(last)r30.w
ldl.u32 r30.y, l[r24.z+256], 4
mad.f32 r16.x, r20.w, r3.x, (last)r16.x
mad.f32 r14.x, r20.w, r3.y, (last)r14.x
mad.f32 r12.x, r20.w, r3.z, (last)r12.x
mad.f32 r10.x, r20.w, r3.w, (last)r10.x
mad.f32 r8.x, r20.w, r18.w, (last)r8.x
mad.f32 r6.x, r20.w, r19.x, (last)r6.x
mad.f32 r4.x, r20.w, r19.y, (last)r4.x
mad.f32 r16.y, r21.x, r3.x, (last)r16.y
mad.f32 r14.y, r21.x, r3.y, (last)r14.y
mad.f32 r12.y, r21.x, r3.z, (last)r12.y
mad.f32 r10.y, r21.x, r3.w, (last)r10.y
mad.f32 r8.y, r21.x, r18.w, (last)r8.y
mad.f32 r6.y, r21.x, r19.x, (last)r6.y
mad.f32 r4.y, r21.x, r19.y, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r21.y, r3.x, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r21.y, r3.y, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r21.y, r3.z, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r21.y, r3.w, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r21.y, r18.w, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r21.y, r19.x, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r21.y, r19.y, (r)(last)r4.z
(rpt1)mad.f32 r20.w, (r)(last)r20.w, r19.z, (r)(last)r2.x
(rpt1)mad.f32 r21.y, (r)(last)r21.y, r19.z, (r)(last)r2.z
ldl.u32 r2.x, l[r1.w+3072], 4
ldl.u32 r3.x, l[r1.w+3328], 4
ldl.u32 r18.w, l[r24.w], 4
(ss)mad.f32 r17.x, r29.y, r23.x, (last)r17.x
mad.f32 r15.x, r29.y, r23.y, (last)r15.x
mad.f32 r13.x, r29.y, r23.z, (last)r13.x
mad.f32 r11.x, r29.y, r23.w, (last)r11.x
mad.f32 r9.x, r29.y, r28.y, (last)r9.x
mad.f32 r7.x, r29.y, r28.z, (last)r7.x
mad.f32 r5.x, r29.y, r28.w, (last)r5.x
mad.f32 r17.y, r29.z, r23.x, (last)r17.y
mad.f32 r15.y, r29.z, r23.y, (last)r15.y
mad.f32 r13.y, r29.z, r23.z, (last)r13.y
mad.f32 r11.y, r29.z, r23.w, (last)r11.y
mad.f32 r9.y, r29.z, r28.y, (last)r9.y
mad.f32 r7.y, r29.z, r28.z, (last)r7.y
mad.f32 r5.y, r29.z, r28.w, (last)r5.y
mad.f32 r17.z, r29.w, r23.x, (last)r17.z
mad.f32 r15.z, r29.w, r23.y, (last)r15.z
mad.f32 r13.z, r29.w, r23.z, (last)r13.z
mad.f32 r11.z, r29.w, r23.w, (last)r11.z
mad.f32 r9.z, r29.w, r28.y, (last)r9.z
mad.f32 r7.z, r29.w, r28.z, (last)r7.z
mad.f32 r5.z, r29.w, r28.w, (last)r5.z
mad.f32 r17.w, r30.x, r23.x, (last)r17.w
mad.f32 r15.w, r30.x, r23.y, (last)r15.w
mad.f32 r13.w, r30.x, r23.z, (last)r13.w
mad.f32 r11.w, r30.x, r23.w, (last)r11.w
mad.f32 r9.w, r30.x, r28.y, (last)r9.w
mad.f32 r7.w, r30.x, r28.z, (last)r7.w
mad.f32 r5.w, r30.x, r28.w, (last)r5.w
mad.f32 r16.x, r30.y, r23.x, (last)r16.x
mad.f32 r14.x, r30.y, r23.y, (last)r14.x
mad.f32 r12.x, r30.y, r23.z, (last)r12.x
mad.f32 r10.x, r30.y, r23.w, (last)r10.x
mad.f32 r8.x, r30.y, r28.y, (last)r8.x
mad.f32 r6.x, r30.y, r28.z, (last)r6.x
mad.f32 r4.x, r30.y, r28.w, (last)r4.x
mad.f32 r16.y, r30.z, r23.x, (last)r16.y
mad.f32 r14.y, r30.z, r23.y, (last)r14.y
mad.f32 r12.y, r30.z, r23.z, (last)r12.y
mad.f32 r10.y, r30.z, r23.w, (last)r10.y
mad.f32 r8.y, r30.z, r28.y, (last)r8.y
mad.f32 r6.y, r30.z, r28.z, (last)r6.y
mad.f32 r4.y, r30.z, r28.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r30.w, r23.x, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r30.w, r23.y, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r30.w, r23.z, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r30.w, r23.w, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r30.w, r28.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r30.w, r28.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r30.w, r28.w, (r)(last)r4.z
(rpt1)mad.f32 r29.y, (r)(last)r29.y, r29.x, (r)(last)r19.w
(rpt1)mad.f32 r29.w, (r)(last)r29.w, r29.x, (r)(last)r20.y
ldl.u32 r19.w, l[r24.w+256], 4
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r29.x, (r)(last)r20.w
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r29.x, (r)(last)r21.y
ldl.u32 r20.w, l[r1.w+3584], 4
ldl.u32 r23.x, l[r1.w+3840], 4
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
(ss)nop
ldl.u32 r24.x, l[r25.x], 4
ldl.u32 r28.y, l[r25.x+256], 4
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
(rpt1)mad.f32 r18.w, (r)(last)r18.w, r3.w, (r)(last)r29.y
(rpt1)mad.f32 r19.y, (r)(last)r19.y, r3.w, (r)(last)r29.w
ldl.u32 r29.y, l[r22.x], 4
(rpt1)mad.f32 r19.w, (r)(last)r19.w, r3.w, (r)(last)r30.y
(rpt1)mad.f32 r20.y, (r)(last)r20.y, r3.w, (r)(last)r30.w
ldl.u32 r30.y, l[r22.x+256], 4
ldl.u32 r2.x, l[r25.y], 4
ldl.u32 r3.x, l[r25.y+256], 4
(ss)mad.f32 r17.x, r24.x, r20.w, (last)r17.x
mad.f32 r15.x, r24.x, r21.x, (last)r15.x
mad.f32 r13.x, r24.x, r21.y, (last)r13.x
mad.f32 r11.x, r24.x, r21.z, (last)r11.x
mad.f32 r9.x, r24.x, r23.x, (last)r9.x
mad.f32 r7.x, r24.x, r23.y, (last)r7.x
mad.f32 r5.x, r24.x, r23.z, (last)r5.x
mad.f32 r17.y, r24.y, r20.w, (last)r17.y
mad.f32 r15.y, r24.y, r21.x, (last)r15.y
mad.f32 r13.y, r24.y, r21.y, (last)r13.y
mad.f32 r11.y, r24.y, r21.z, (last)r11.y
mad.f32 r9.y, r24.y, r23.x, (last)r9.y
mad.f32 r7.y, r24.y, r23.y, (last)r7.y
mad.f32 r5.y, r24.y, r23.z, (last)r5.y
mad.f32 r17.z, r24.z, r20.w, (last)r17.z
mad.f32 r15.z, r24.z, r21.x, (last)r15.z
mad.f32 r13.z, r24.z, r21.y, (last)r13.z
mad.f32 r11.z, r24.z, r21.z, (last)r11.z
mad.f32 r9.z, r24.z, r23.x, (last)r9.z
mad.f32 r7.z, r24.z, r23.y, (last)r7.z
mad.f32 r5.z, r24.z, r23.z, (last)r5.z
mad.f32 r17.w, r24.w, r20.w, (last)r17.w
mad.f32 r15.w, r24.w, r21.x, (last)r15.w
mad.f32 r13.w, r24.w, r21.y, (last)r13.w
mad.f32 r11.w, r24.w, r21.z, (last)r11.w
mad.f32 r9.w, r24.w, r23.x, (last)r9.w
mad.f32 r7.w, r24.w, r23.y, (last)r7.w
mad.f32 r5.w, r24.w, r23.z, (last)r5.w
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
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r23.w, (r)(last)r18.w
(rpt1)mad.f32 r24.z, (r)(last)r24.z, r23.w, (r)(last)r19.y
ldl.u32 r18.w, l[r22.y], 4
(rpt1)mad.f32 r28.y, (r)(last)r28.y, r23.w, (r)(last)r19.w
(rpt1)mad.f32 r28.w, (r)(last)r28.w, r23.w, (r)(last)r20.y
ldl.u32 r19.w, l[r22.y+256], 4
ldl.u32 r20.w, l[r25.z], 4
ldl.u32 r23.x, l[r25.z+256], 4
mad.f32 r17.x, r2.x, r29.y, (last)r17.x
mad.f32 r15.x, r2.x, r29.z, (last)r15.x
mad.f32 r13.x, r2.x, r29.w, (last)r13.x
mad.f32 r11.x, r2.x, r30.x, (last)r11.x
mad.f32 r9.x, r2.x, r30.y, (last)r9.x
mad.f32 r7.x, r2.x, r30.z, (last)r7.x
mad.f32 r5.x, r2.x, r30.w, (last)r5.x
mad.f32 r17.y, r2.y, r29.y, (last)r17.y
mad.f32 r15.y, r2.y, r29.z, (last)r15.y
mad.f32 r13.y, r2.y, r29.w, (last)r13.y
mad.f32 r11.y, r2.y, r30.x, (last)r11.y
mad.f32 r9.y, r2.y, r30.y, (last)r9.y
mad.f32 r7.y, r2.y, r30.z, (last)r7.y
mad.f32 r5.y, r2.y, r30.w, (last)r5.y
mad.f32 r17.z, r2.z, r29.y, (last)r17.z
mad.f32 r15.z, r2.z, r29.z, (last)r15.z
mad.f32 r13.z, r2.z, r29.w, (last)r13.z
mad.f32 r11.z, r2.z, r30.x, (last)r11.z
mad.f32 r9.z, r2.z, r30.y, (last)r9.z
mad.f32 r7.z, r2.z, r30.z, (last)r7.z
mad.f32 r5.z, r2.z, r30.w, (last)r5.z
mad.f32 r17.w, r2.w, r29.y, (last)r17.w
mad.f32 r15.w, r2.w, r29.z, (last)r15.w
mad.f32 r13.w, r2.w, r29.w, (last)r13.w
mad.f32 r11.w, r2.w, r30.x, (last)r11.w
mad.f32 r9.w, r2.w, r30.y, (last)r9.w
mad.f32 r7.w, r2.w, r30.z, (last)r7.w
mad.f32 r5.w, r2.w, r30.w, (last)r5.w
mad.f32 r16.x, r3.x, r29.y, (last)r16.x
mad.f32 r14.x, r3.x, r29.z, (last)r14.x
mad.f32 r12.x, r3.x, r29.w, (last)r12.x
mad.f32 r10.x, r3.x, r30.x, (last)r10.x
mad.f32 r8.x, r3.x, r30.y, (last)r8.x
mad.f32 r6.x, r3.x, r30.z, (last)r6.x
mad.f32 r4.x, r3.x, r30.w, (last)r4.x
mad.f32 r16.y, r3.y, r29.y, (last)r16.y
mad.f32 r14.y, r3.y, r29.z, (last)r14.y
mad.f32 r12.y, r3.y, r29.w, (last)r12.y
mad.f32 r10.y, r3.y, r30.x, (last)r10.y
mad.f32 r8.y, r3.y, r30.y, (last)r8.y
mad.f32 r6.y, r3.y, r30.z, (last)r6.y
mad.f32 r4.y, r3.y, r30.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r3.z, r29.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r3.z, r29.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r3.z, r29.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r3.z, r30.x, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r3.z, r30.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r3.z, r30.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r3.z, r30.w, (r)(last)r4.z
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r31.x, (r)(last)r24.x
(rpt1)mad.f32 r2.z, (r)(last)r2.z, r31.x, (r)(last)r24.z
ldl.u32 r24.x, l[r22.z], 4
(rpt1)mad.f32 r3.x, (r)(last)r3.x, r31.x, (r)(last)r28.y
(rpt1)mad.f32 r3.z, (r)(last)r3.z, r31.x, (r)(last)r28.w
ldl.u32 r28.y, l[r22.z+256], 4
ldl.u32 r29.y, l[r25.w], 4
ldl.u32 r30.y, l[r25.w+256], 4
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
mad.f32 r9.y, r21.x, r19.w, (last)r9.y
mad.f32 r7.y, r21.x, r20.x, (last)r7.y
mad.f32 r5.y, r21.x, r20.y, (last)r5.y
mad.f32 r17.z, r21.y, r18.w, (last)r17.z
mad.f32 r15.z, r21.y, r19.x, (last)r15.z
mad.f32 r13.z, r21.y, r19.y, (last)r13.z
mad.f32 r11.z, r21.y, r19.z, (last)r11.z
mad.f32 r9.z, r21.y, r19.w, (last)r9.z
mad.f32 r7.z, r21.y, r20.x, (last)r7.z
mad.f32 r5.z, r21.y, r20.y, (last)r5.z
mad.f32 r17.w, r21.z, r18.w, (last)r17.w
mad.f32 r15.w, r21.z, r19.x, (last)r15.w
mad.f32 r13.w, r21.z, r19.y, (last)r13.w
mad.f32 r11.w, r21.z, r19.z, (last)r11.w
mad.f32 r9.w, r21.z, r19.w, (last)r9.w
mad.f32 r7.w, r21.z, r20.x, (last)r7.w
mad.f32 r5.w, r21.z, r20.y, (last)r5.w
(rpt1)mad.f32 r20.w, (r)(last)r20.w, r20.z, (r)(last)r2.x
(rpt1)mad.f32 r21.y, (r)(last)r21.y, r20.z, (r)(last)r2.z
ldl.u32 r2.x, l[r22.w], 4
mad.f32 r16.x, r23.x, r18.w, (last)r16.x
mad.f32 r14.x, r23.x, r19.x, (last)r14.x
mad.f32 r12.x, r23.x, r19.y, (last)r12.x
mad.f32 r10.x, r23.x, r19.z, (last)r10.x
mad.f32 r8.x, r23.x, r19.w, (last)r8.x
mad.f32 r6.x, r23.x, r20.x, (last)r6.x
mad.f32 r4.x, r23.x, r20.y, (last)r4.x
mad.f32 r16.y, r23.y, r18.w, (last)r16.y
mad.f32 r14.y, r23.y, r19.x, (last)r14.y
mad.f32 r12.y, r23.y, r19.y, (last)r12.y
mad.f32 r10.y, r23.y, r19.z, (last)r10.y
mad.f32 r8.y, r23.y, r19.w, (last)r8.y
mad.f32 r6.y, r23.y, r20.x, (last)r6.y
mad.f32 r4.y, r23.y, r20.y, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r23.z, r18.w, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r23.z, r19.x, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r23.z, r19.y, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r23.z, r19.z, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r23.z, r19.w, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r23.z, r20.x, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r23.z, r20.y, (r)(last)r4.z
mad.f32 r17.x, r29.y, r24.x, (last)r17.x
mad.f32 r15.x, r29.y, r24.y, (last)r15.x
mad.f32 r13.x, r29.y, r24.z, (last)r13.x
mad.f32 r11.x, r29.y, r24.w, (last)r11.x
mad.f32 r9.x, r29.y, r28.y, (last)r9.x
mad.f32 r7.x, r29.y, r28.z, (last)r7.x
mad.f32 r5.x, r29.y, r28.w, (last)r5.x
mad.f32 r17.y, r29.z, r24.x, (last)r17.y
mad.f32 r15.y, r29.z, r24.y, (last)r15.y
mad.f32 r13.y, r29.z, r24.z, (last)r13.y
mad.f32 r11.y, r29.z, r24.w, (last)r11.y
mad.f32 r9.y, r29.z, r28.y, (last)r9.y
mad.f32 r7.y, r29.z, r28.z, (last)r7.y
mad.f32 r5.y, r29.z, r28.w, (last)r5.y
mad.f32 r17.z, r29.w, r24.x, (last)r17.z
mad.f32 r15.z, r29.w, r24.y, (last)r15.z
mad.f32 r13.z, r29.w, r24.z, (last)r13.z
mad.f32 r11.z, r29.w, r24.w, (last)r11.z
mad.f32 r9.z, r29.w, r28.y, (last)r9.z
mad.f32 r7.z, r29.w, r28.z, (last)r7.z
mad.f32 r5.z, r29.w, r28.w, (last)r5.z
mad.f32 r17.w, r30.x, r24.x, (last)r17.w
mad.f32 r15.w, r30.x, r24.y, (last)r15.w
mad.f32 r13.w, r30.x, r24.z, (last)r13.w
mad.f32 r11.w, r30.x, r24.w, (last)r11.w
mad.f32 r9.w, r30.x, r28.y, (last)r9.w
mad.f32 r7.w, r30.x, r28.z, (last)r7.w
mad.f32 r5.w, r30.x, r28.w, (last)r5.w
(rpt1)mad.f32 r23.x, (r)(last)r23.x, r20.z, (r)(last)r3.x
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r20.z, (r)(last)r3.z
ldl.u32 r3.x, l[r22.w+256], 4
ldl.u32 r18.w, l[r26.x], 4
ldl.u32 r19.w, l[r26.x+256], 4
(rpt1)mad.f32 r29.y, (r)(last)r29.y, r29.x, (r)(last)r20.w
(rpt1)mad.f32 r29.w, (r)(last)r29.w, r29.x, (r)(last)r21.y
ldl.u32 r20.w, l[r27.x], 4
ldl.u32 r21.w, l[r27.x+256], 4
mad.f32 r16.x, r30.y, r24.x, (last)r16.x
mad.f32 r14.x, r30.y, r24.y, (last)r14.x
mad.f32 r12.x, r30.y, r24.z, (last)r12.x
mad.f32 r10.x, r30.y, r24.w, (last)r10.x
mad.f32 r8.x, r30.y, r28.y, (last)r8.x
mad.f32 r6.x, r30.y, r28.z, (last)r6.x
mad.f32 r4.x, r30.y, r28.w, (last)r4.x
mad.f32 r16.y, r30.z, r24.x, (last)r16.y
mad.f32 r14.y, r30.z, r24.y, (last)r14.y
mad.f32 r12.y, r30.z, r24.z, (last)r12.y
mad.f32 r10.y, r30.z, r24.w, (last)r10.y
mad.f32 r8.y, r30.z, r28.y, (last)r8.y
mad.f32 r6.y, r30.z, r28.z, (last)r6.y
mad.f32 r4.y, r30.z, r28.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r30.w, r24.x, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r30.w, r24.y, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r30.w, r24.z, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r30.w, r24.w, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r30.w, r28.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r30.w, r28.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r30.w, r28.w, (r)(last)r4.z
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r29.x, (r)(last)r23.x
mad.f32 r30.w, (last)r30.w, r29.x, (last)r23.z
(ss)nop
ldl.u32 r22.w, l[r26.y], 4
mad.f32 r31.x, (last)r31.x, r29.x, (last)r23.w
ldl.u32 r23.w, l[r26.y+256], 4
ldl.u32 r24.w, l[r27.y], 4
ldl.u32 r28.y, l[r27.y+256], 4
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
(rpt1)mad.f32 r18.w, (r)(last)r18.w, r3.w, (r)(last)r29.y
(rpt1)mad.f32 r19.y, (r)(last)r19.y, r3.w, (r)(last)r29.w
ldl.u32 r29.y, l[r26.z], 4
(rpt1)mad.f32 r19.w, (r)(last)r19.w, r3.w, (r)(last)r30.y
(rpt1)mad.f32 r20.y, (r)(last)r20.y, r3.w, (r)(last)r30.w
ldl.u32 r30.y, l[r26.z+256], 4
ldl.u32 r2.x, l[r27.z], 4
ldl.u32 r3.x, l[r27.z+256], 4
(ss)mad.f32 r17.x, r22.w, r20.w, (last)r17.x
mad.f32 r15.x, r22.w, r21.x, (last)r15.x
mad.f32 r13.x, r22.w, r21.y, (last)r13.x
mad.f32 r11.x, r22.w, r21.z, (last)r11.x
mad.f32 r9.x, r22.w, r21.w, (last)r9.x
mad.f32 r7.x, r22.w, r22.x, (last)r7.x
mad.f32 r5.x, r22.w, r22.y, (last)r5.x
mad.f32 r17.y, r23.x, r20.w, (last)r17.y
mad.f32 r15.y, r23.x, r21.x, (last)r15.y
mad.f32 r13.y, r23.x, r21.y, (last)r13.y
mad.f32 r11.y, r23.x, r21.z, (last)r11.y
mad.f32 r9.y, r23.x, r21.w, (last)r9.y
mad.f32 r7.y, r23.x, r22.x, (last)r7.y
mad.f32 r5.y, r23.x, r22.y, (last)r5.y
mad.f32 r17.z, r23.y, r20.w, (last)r17.z
mad.f32 r15.z, r23.y, r21.x, (last)r15.z
mad.f32 r13.z, r23.y, r21.y, (last)r13.z
mad.f32 r11.z, r23.y, r21.z, (last)r11.z
mad.f32 r9.z, r23.y, r21.w, (last)r9.z
mad.f32 r7.z, r23.y, r22.x, (last)r7.z
mad.f32 r5.z, r23.y, r22.y, (last)r5.z
mad.f32 r17.w, r23.z, r20.w, (last)r17.w
mad.f32 r15.w, r23.z, r21.x, (last)r15.w
mad.f32 r13.w, r23.z, r21.y, (last)r13.w
mad.f32 r11.w, r23.z, r21.z, (last)r11.w
mad.f32 r9.w, r23.z, r21.w, (last)r9.w
mad.f32 r7.w, r23.z, r22.x, (last)r7.w
mad.f32 r5.w, r23.z, r22.y, (last)r5.w
mad.f32 r16.x, r23.w, r20.w, (last)r16.x
mad.f32 r14.x, r23.w, r21.x, (last)r14.x
mad.f32 r12.x, r23.w, r21.y, (last)r12.x
mad.f32 r10.x, r23.w, r21.z, (last)r10.x
mad.f32 r8.x, r23.w, r21.w, (last)r8.x
mad.f32 r6.x, r23.w, r22.x, (last)r6.x
mad.f32 r4.x, r23.w, r22.y, (last)r4.x
mad.f32 r16.y, r24.x, r20.w, (last)r16.y
mad.f32 r14.y, r24.x, r21.x, (last)r14.y
mad.f32 r12.y, r24.x, r21.y, (last)r12.y
mad.f32 r10.y, r24.x, r21.z, (last)r10.y
mad.f32 r8.y, r24.x, r21.w, (last)r8.y
mad.f32 r6.y, r24.x, r22.x, (last)r6.y
mad.f32 r4.y, r24.x, r22.y, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r24.y, r20.w, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r24.y, r21.x, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r24.y, r21.y, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r24.y, r21.z, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r24.y, r21.w, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r24.y, r22.x, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r24.y, r22.y, (r)(last)r4.z
(rpt1)mad.f32 r22.w, (r)(last)r22.w, r22.z, (r)(last)r18.w
(rpt1)mad.f32 r23.y, (r)(last)r23.y, r22.z, (r)(last)r19.y
ldl.u32 r18.w, l[r26.w], 4
(rpt1)mad.f32 r23.w, (r)(last)r23.w, r22.z, (r)(last)r19.w
(rpt1)mad.f32 r24.y, (r)(last)r24.y, r22.z, (r)(last)r20.y
ldl.u32 r19.w, l[r26.w+256], 4
ldl.u32 r20.w, l[r27.w], 4
ldl.u32 r21.w, l[r27.w+256], 4
mad.f32 r17.x, r29.y, r24.w, (last)r17.x
mad.f32 r15.x, r29.y, r25.x, (last)r15.x
mad.f32 r13.x, r29.y, r25.y, (last)r13.x
mad.f32 r11.x, r29.y, r25.z, (last)r11.x
mad.f32 r9.x, r29.y, r28.y, (last)r9.x
mad.f32 r7.x, r29.y, r28.z, (last)r7.x
mad.f32 r5.x, r29.y, r28.w, (last)r5.x
mad.f32 r17.y, r29.z, r24.w, (last)r17.y
mad.f32 r15.y, r29.z, r25.x, (last)r15.y
mad.f32 r13.y, r29.z, r25.y, (last)r13.y
mad.f32 r11.y, r29.z, r25.z, (last)r11.y
mad.f32 r9.y, r29.z, r28.y, (last)r9.y
mad.f32 r7.y, r29.z, r28.z, (last)r7.y
mad.f32 r5.y, r29.z, r28.w, (last)r5.y
mad.f32 r17.z, r29.w, r24.w, (last)r17.z
mad.f32 r15.z, r29.w, r25.x, (last)r15.z
mad.f32 r13.z, r29.w, r25.y, (last)r13.z
mad.f32 r11.z, r29.w, r25.z, (last)r11.z
mad.f32 r9.z, r29.w, r28.y, (last)r9.z
mad.f32 r7.z, r29.w, r28.z, (last)r7.z
mad.f32 r5.z, r29.w, r28.w, (last)r5.z
mad.f32 r17.w, r30.x, r24.w, (last)r17.w
mad.f32 r15.w, r30.x, r25.x, (last)r15.w
mad.f32 r13.w, r30.x, r25.y, (last)r13.w
mad.f32 r11.w, r30.x, r25.z, (last)r11.w
mad.f32 r9.w, r30.x, r28.y, (last)r9.w
mad.f32 r7.w, r30.x, r28.z, (last)r7.w
mad.f32 r5.w, r30.x, r28.w, (last)r5.w
mad.f32 r16.x, r30.y, r24.w, (last)r16.x
mad.f32 r14.x, r30.y, r25.x, (last)r14.x
mad.f32 r12.x, r30.y, r25.y, (last)r12.x
mad.f32 r10.x, r30.y, r25.z, (last)r10.x
mad.f32 r8.x, r30.y, r28.y, (last)r8.x
mad.f32 r6.x, r30.y, r28.z, (last)r6.x
mad.f32 r4.x, r30.y, r28.w, (last)r4.x
mad.f32 r16.y, r30.z, r24.w, (last)r16.y
mad.f32 r14.y, r30.z, r25.x, (last)r14.y
mad.f32 r12.y, r30.z, r25.y, (last)r12.y
mad.f32 r10.y, r30.z, r25.z, (last)r10.y
mad.f32 r8.y, r30.z, r28.y, (last)r8.y
mad.f32 r6.y, r30.z, r28.z, (last)r6.y
mad.f32 r4.y, r30.z, r28.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r30.w, r24.w, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r30.w, r25.x, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r30.w, r25.y, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r30.w, r25.z, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r30.w, r28.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r30.w, r28.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r30.w, r28.w, (r)(last)r4.z
(rpt1)mad.f32 r29.y, (r)(last)r29.y, r29.x, (r)(last)r22.w
(rpt1)mad.f32 r29.w, (r)(last)r29.w, r29.x, (r)(last)r23.y
ldl.u32 r22.w, l[r18.z], 4
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r29.x, (r)(last)r23.w
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r29.x, (r)(last)r24.y
ldl.u32 r23.w, l[r18.z+256], 4
fence.r.w
(sy)(ss)mad.f32 r17.x, r18.w, r2.x, (last)r17.x
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
(rpt1)mad.f32 r18.w, (r)(last)r18.w, r3.w, (r)(last)r29.y
(rpt1)mad.f32 r19.y, (r)(last)r19.y, r3.w, (r)(last)r29.w
(rpt1)mad.f32 r19.w, (r)(last)r19.w, r3.w, (r)(last)r30.y
(rpt1)mad.f32 r20.y, (r)(last)r20.y, r3.w, (r)(last)r30.w
mad.f32 r17.x, r22.w, r20.w, (last)r17.x
mad.f32 r15.x, r22.w, r21.x, (last)r15.x
mad.f32 r13.x, r22.w, r21.y, (last)r13.x
mad.f32 r11.x, r22.w, r21.z, (last)r11.x
mad.f32 r9.x, r22.w, r21.w, (last)r9.x
mad.f32 r7.x, r22.w, r22.x, (last)r7.x
mad.f32 r5.x, r22.w, r22.y, (last)r5.x
mad.f32 r17.y, r23.x, r20.w, (last)r17.y
mad.f32 r15.y, r23.x, r21.x, (last)r15.y
mad.f32 r13.y, r23.x, r21.y, (last)r13.y
mad.f32 r11.y, r23.x, r21.z, (last)r11.y
mad.f32 r9.y, r23.x, r21.w, (last)r9.y
mad.f32 r7.y, r23.x, r22.x, (last)r7.y
mad.f32 r5.y, r23.x, r22.y, (last)r5.y
mad.f32 r17.z, r23.y, r20.w, (last)r17.z
mad.f32 r15.z, r23.y, r21.x, (last)r15.z
mad.f32 r13.z, r23.y, r21.y, (last)r13.z
mad.f32 r11.z, r23.y, r21.z, (last)r11.z
mad.f32 r9.z, r23.y, r21.w, (last)r9.z
mad.f32 r7.z, r23.y, r22.x, (last)r7.z
mad.f32 r5.z, r23.y, r22.y, (last)r5.z
mad.f32 r17.w, r23.z, r20.w, (last)r17.w
mad.f32 r15.w, r23.z, r21.x, (last)r15.w
mad.f32 r13.w, r23.z, r21.y, (last)r13.w
mad.f32 r11.w, r23.z, r21.z, (last)r11.w
mad.f32 r9.w, r23.z, r21.w, (last)r9.w
mad.f32 r7.w, r23.z, r22.x, (last)r7.w
mad.f32 r5.w, r23.z, r22.y, (last)r5.w
mad.f32 r16.x, r23.w, r20.w, (last)r16.x
mad.f32 r14.x, r23.w, r21.x, (last)r14.x
mad.f32 r12.x, r23.w, r21.y, (last)r12.x
mad.f32 r10.x, r23.w, r21.z, (last)r10.x
mad.f32 r8.x, r23.w, r21.w, (last)r8.x
mad.f32 r6.x, r23.w, r22.x, (last)r6.x
mad.f32 r4.x, r23.w, r22.y, (last)r4.x
mad.f32 r16.y, r24.x, r20.w, (last)r16.y
mad.f32 r14.y, r24.x, r21.x, (last)r14.y
mad.f32 r12.y, r24.x, r21.y, (last)r12.y
mad.f32 r10.y, r24.x, r21.z, (last)r10.y
mad.f32 r8.y, r24.x, r21.w, (last)r8.y
mad.f32 r6.y, r24.x, r22.x, (last)r6.y
mad.f32 r4.y, r24.x, r22.y, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r24.y, r20.w, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r24.y, r21.x, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r24.y, r21.y, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r24.y, r21.z, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r24.y, r21.w, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r24.y, r22.x, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r24.y, r22.y, (r)(last)r4.z
(rpt1)mad.f32 r3.x, (r)(last)r22.w, r22.z, (r)(last)r18.w
mad.f32 r3.z, (last)r23.y, r22.z, (last)r19.y
(rpt1)mad.f32 r24.w, (r)(last)r23.w, r22.z, (r)(last)r19.w
(rpt1)mad.f32 r25.y, (r)(last)r24.y, r22.z, (r)(last)r20.y
mad.f32 r3.w, (last)r23.z, r22.z, (last)r19.z
bar.g
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
cov.f32f16 hr0.x, r4.z
cov.f32f16 hr0.y, r25.y
cov.f32f16 hr1.z, r4.w
cov.f32f16 hr1.w, r25.z
br p0.x, #l1163
mov.u32u32 r2.x, (last)r24.w
mov.u32u32 r2.y, (last)r25.x
mov.u32u32 r2.w, (last)r25.z
mov.u32u32 r2.z, (last)r25.y
mov.u32u32 r0.x, (last)r24.x
mov.u32u32 r0.w, (last)r24.y
jump #l130
l1163:
(jp)(eolm)nop
(nop3) add.u r28.x, r51.z, (last)r28.x
(nop3) shl.b r28.x, (last)r28.x, 9
(nop3) sad.s32 r28.x, r52.z, r28.x, (last)r1.y
(nop3) shl.b r28.x, (last)r28.x, 2
add.u r1.x, r28.x, c1.x
add.u r1.y, r28.x, c7.z
add.u r1.z, r28.x, c5.y
stib.b.untyped.1d.u16.4.imm.base0 hr0.z, r28.x, 4
add.u r1.w, r28.x, c7.w
add.u r3.x, c8.w, r28.x
(rpt1)add.u r3.y, (r)c9.x, r28.x
add.u r3.w, c9.z, r28.x
(ss)mov.u16u16 hr0.w, (last)hr47.z
mov.u16u16 hr1.x, (last)hr37.x
mov.u16u16 hr1.y, (last)hr0.x
stib.b.untyped.1d.u16.4.imm.base0 hr39.z, r28.x+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r1.x, 4
(ss)add.u r2.x, r28.x, c3.y
add.u r2.y, r28.x, c8.x
stib.b.untyped.1d.u16.4.imm.base0 hr40.z, r1.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r1.z, 4
(ss)add.u r2.z, r28.x, c8.y
add.u r2.w, c8.z, r28.x
add.u r4.x, c9.w, r28.x
stib.b.untyped.1d.u16.4.imm.base0 hr41.z, r1.w, 4
(nop1) add.u r28.x, c10.x, (last)r28.x
stib.b.untyped.1d.u16.4.imm.base0 hr36.x, r2.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr42.z, r2.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr37.z, r2.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr43.z, r2.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr38.z, r3.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr44.z, r3.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr45.z, r3.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr0.w, r3.w, 4
(ss)mov.u16u16 hr1.x, (last)hr47.w
mov.u16u16 hr1.y, (last)hr37.y
mov.u16u16 hr1.z, (last)hr0.y
stib.b.untyped.1d.u16.4.imm.base0 hr46.z, r4.x, 4
(rpt5)nop
stib.b.untyped.1d.u16.4.imm.base0 hr1.x, r28.x, 4
end
nop
nop
nop
nop
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1370 instr, 29 nops, 1341 non-nops, 79 mov, 64 cov, 2432 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 32 full, 12 constlen
; CL prog 23/1: 32 cat0, 143 cat1, 72 cat2, 1031 cat3, 0 cat4, 4 cat5, 84 cat6, 4 cat7
; CL prog 23/1: 79 sstall, 20 (ss), 19 systall, 5 (sy), 1 loops
; CL prog 23/1: 8 max_waves, 0 double_threadsize
; 57 preamble-instr, 1 early-preamble
