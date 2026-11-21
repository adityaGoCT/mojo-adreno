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
@const(c1.x)	0x00000800, 0x00007800, 0x00001e00, 0x00007000
@const(c2.x)	0x00001c00, 0x00006800, 0x00001a00, 0x00006000
@const(c3.x)	0x00001800, 0x00005800, 0x00001600, 0x00005000
@const(c4.x)	0x00001400, 0x00004800, 0x00001200, 0x00004000
@const(c5.x)	0x00001000, 0x00003800, 0x00003000, 0x00002800
@const(c6.x)	0x00002000, 0x00007840, 0x00007040, 0x00006840
@const(c7.x)	0x00006040, 0x00005840, 0x00005040, 0x00004840
@const(c8.x)	0x00004040, 0x00003840, 0x00003040, 0x00002840
@const(c9.x)	0x00002040, 0x00001840, 0x00001040, 0x00000840
@const(c10.x)	0x00020000, 0x00020040, 0x00020800, 0x00020840
@const(c11.x)	0x00021000, 0x00021040, 0x00021800, 0x00021840
shps #l65
getone #l65
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 0x7800
mov.u32u32 r49.y, 0x1e00
mov.u32u32 r49.z, 0x7000
mov.u32u32 r49.w, 0x1c00
mov.u32u32 r50.x, 0x6800
mov.u32u32 r50.y, 0x1a00
mov.u32u32 r50.z, 0x6000
mov.u32u32 r50.w, 0x1800
mov.u32u32 r51.x, 0x5800
mov.u32u32 r51.y, 0x1600
mov.u32u32 r51.z, 0x5000
mov.u32u32 r51.w, 0x1400
mov.u32u32 r52.x, 0x4800
mov.u32u32 r52.y, 0x1200
mov.u32u32 r52.z, 0x4000
mov.u32u32 r52.w, 4096
mov.u32u32 r53.x, 0x3800
mov.u32u32 r53.y, 0x3000
mov.u32u32 r53.z, 0x2800
mov.u32u32 r53.w, 0x2000
mov.u32u32 r54.x, 0x7840
mov.u32u32 r54.y, 0x7040
mov.u32u32 r54.z, 0x6840
mov.u32u32 r54.w, 0x6040
mov.u32u32 r55.x, 0x5840
mov.u32u32 r55.y, 0x5040
mov.u32u32 r55.z, 0x4840
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
(ss)mov.u32u32 r48.w, 0x4040
mov.u32u32 r49.x, 0x3840
mov.u32u32 r49.y, 0x3040
mov.u32u32 r49.z, 0x2840
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 4
stc.u32 c[20], r52.w, 4
stc.u32 c[24], r53.w, 4
stc.u32 c[28], r54.w, 4
(ss)mov.u32u32 r49.w, 0x2040
mov.u32u32 r50.x, 0x1840
mov.u32u32 r50.y, 0x1040
mov.u32u32 r50.z, 2112
mov.u32u32 r50.w, 0x20000
mov.u32u32 r51.x, 0x20040
mov.u32u32 r51.y, 0x20800
mov.u32u32 r51.z, 0x20840
mov.u32u32 r51.w, 0x21000
mov.u32u32 r52.x, 0x21040
mov.u32u32 r52.y, 0x21800
mov.u32u32 r52.z, 0x21840
stc.u32 c[32], r48.w, 4
(ss)nop
stc.u32 c[36], r49.w, 4
stc.u32 c[40], r50.w, 4
stc.u32 c[44], r51.w, 4
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l65:
(jp)(rpt1)add.u r52.w, (r)r48.x, (r)c0.x
mov.u32u32 r53.w, 0
shl.b r53.z, r52.w, 7
shl.b r53.y, r53.x, 7
shr.b r0.w, r0.x, 5
and.b r1.x, r0.x, 31
shr.b r1.y, r0.x, 4
and.b r1.z, r0.x, -16
and.b r1.w, r0.x, 15
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
l138:
(rpt1)shr.b r54.x, (r)r53.y, 2
(nop2) shl.b r54.z, r53.w, 9
add.u r18.z, r0.x, 256
shl.b r18.x, r0.w, 9
shl.b r18.y, r1.x, 4
shl.b r22.y, r1.y, 2
shr.b r18.z, (last)r18.z, 5
add.u r18.w, c5.x, r1.z
(ss)add.u r20.x, r53.w, r0.w
sad.s32 r22.z, r54.z, r1.w, r54.y
shl.b r19.w, r18.z, 9
add.u r18.z, r53.w, (last)r18.z
add.u r53.w, r53.w, 16
cmps.u.ge up0.x, r53.w, c1.x
shl.b r20.x, (last)r20.x, 9
add.u r18.x, (last)r18.x, r18.y
shl.b r22.z, (last)r22.z, 2
shl.b r18.z, (last)r18.z, 9
sad.s32 r20.x, r54.x, r20.x, r1.x
add.u r19.w, (last)r19.w, (last)r18.y
add.u r22.w, r22.z, c1.x
sad.s32 r18.z, r54.x, r18.z, r1.x
shl.b r20.x, (last)r20.x, 2
add.u r23.x, r22.z, c9.w
add.u r23.y, r22.z, c5.x
shl.b r18.z, (last)r18.z, 2
add.u r23.z, c9.z, r22.z
add.u r23.w, c3.x, r22.z
add.u r24.x, c9.y, r22.z
isam.v.base0 (u32)(xyzw)r21.y, r20.x, s#0, t#0
add.u r24.y, c6.x, r22.z
add.u r24.z, c9.x, r22.z
add.u r24.w, c5.w, r22.z
isam.v.base0 (u32)(xyzw)r30.y, r18.z, s#0, t#0
add.u r25.x, c8.w, r22.z
add.u r25.y, c5.z, r22.z
add.u r25.z, c8.z, r22.z
add.u r25.w, c5.y, r22.z
add.u r26.x, c8.y, r22.z
add.u r26.y, c4.w, r22.z
add.u r26.z, c8.x, r22.z
add.u r26.w, c4.y, r22.z
add.u r27.x, c7.w, r22.z
add.u r27.y, c3.w, r22.z
add.u r27.z, c7.z, r22.z
add.u r27.w, c3.y, r22.z
add.u r28.x, c7.y, r22.z
add.u r28.y, c2.w, r22.z
add.u r28.z, c7.x, r22.z
add.u r28.w, c2.y, r22.z
add.u r29.x, c6.w, r22.z
add.u r29.y, c1.w, r22.z
add.u r29.z, c6.z, r22.z
add.u r29.w, c1.y, r22.z
add.u r30.x, c6.y, r22.z
add.u r19.x, c4.z, r1.z
add.u r19.y, c4.x, r1.z
add.u r19.z, c3.z, r1.z
add.u r20.y, c3.x, r1.z
add.u r20.z, c2.z, r1.z
add.u r20.w, c2.x, r1.z
add.u r21.x, c1.z, r1.z
(sy)stl.u32 l[r18.x], r21.y, 4
stl.u32 l[r19.w], r30.y, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
isam.v.base0 (u32)(xyzw)r30.y, r22.z, s#0, t#2
ldl.u32 r21.y, l[r1.z], 4
(sy)mov.u32u32 r0.z, r31.x
(ss)mad.f32 r17.w, r31.x, r21.y, (last)r17.w
mad.f32 r15.w, r31.x, r21.z, (last)r15.w
mad.f32 r13.w, r31.x, r21.w, (last)r13.w
mad.f32 r11.w, (last)r31.x, r22.x, (last)r11.w
isam.v.base0 (u32)(xyzw)r31.x, r22.z+64, s#0, t#2
mov.u32u32 r0.y, (last)r17.w
ldl.u32 r17.w, l[r1.z+256], 4
mad.f32 r17.x, r30.y, r21.y, (last)r17.x
mad.f32 r15.x, r30.y, r21.z, (last)r15.x
mad.f32 r13.x, r30.y, r21.w, (last)r13.x
mad.f32 r11.x, r30.y, r22.x, (last)r11.x
mad.f32 r17.y, r30.z, r21.y, (last)r17.y
mad.f32 r15.y, r30.z, r21.z, (last)r15.y
mad.f32 r13.y, r30.z, r21.w, (last)r13.y
mad.f32 r11.y, r30.z, r22.x, (last)r11.y
mad.f32 r17.z, r30.w, r21.y, (last)r17.z
mad.f32 r15.z, r30.w, r21.z, (last)r15.z
mad.f32 r13.z, r30.w, r21.w, (last)r13.z
mad.f32 r11.z, r30.w, r22.x, (last)r11.z
(ss)(rpt1)mad.f32 r9.x, (r)r30.y, r17.w, (r)(last)r9.x
mad.f32 r9.z, r30.w, r17.w, (last)r9.z
mad.f32 r9.w, r0.z, r17.w, (last)r9.w
(rpt1)mad.f32 r7.x, (r)r30.y, r18.x, (r)(last)r7.x
mad.f32 r7.z, r30.w, r18.x, (last)r7.z
mad.f32 r7.w, r0.z, r18.x, (last)r7.w
(rpt1)mad.f32 r5.x, (r)r30.y, r18.y, (r)(last)r5.x
mad.f32 r5.z, r30.w, r18.y, (last)r5.z
mad.f32 r5.w, r0.z, r18.y, (last)r5.w
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r18.z, (r)(last)r3.x
mad.f32 r30.w, (last)r30.w, r18.z, (last)r3.z
mad.f32 r0.z, (last)r0.z, r18.z, (last)r3.w
ldl.u32 r3.x, l[r1.z+512], 4
(sy)mad.f32 r16.x, r31.x, r21.y, (last)r16.x
mad.f32 r14.x, r31.x, r21.z, (last)r14.x
mad.f32 r12.x, r31.x, r21.w, (last)r12.x
mad.f32 r10.x, r31.x, r22.x, (last)r10.x
mad.f32 r16.y, r31.y, r21.y, (last)r16.y
mad.f32 r14.y, r31.y, r21.z, (last)r14.y
mad.f32 r12.y, r31.y, r21.w, (last)r12.y
mad.f32 r10.y, r31.y, r22.x, (last)r10.y
(rpt1)mad.f32 r16.z, (r)r31.z, r21.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r31.z, r21.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r31.z, r21.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r31.z, r22.x, (r)(last)r10.z
isam.v.base0 (u32)(xyzw)r21.y, r22.w, s#0, t#2
mad.f32 r8.x, r31.x, r17.w, (last)r8.x
mad.f32 r6.x, r31.x, r18.x, (last)r6.x
mad.f32 r4.x, r31.x, r18.y, (last)r4.x
mad.f32 r8.y, r31.y, r17.w, (last)r8.y
mad.f32 r6.y, r31.y, r18.x, (last)r6.y
mad.f32 r4.y, r31.y, r18.y, (last)r4.y
(rpt1)mad.f32 r8.z, (r)r31.z, r17.w, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r31.z, r18.x, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r31.z, r18.y, (r)(last)r4.z
(rpt1)mad.f32 r31.x, (r)(last)r31.x, r18.z, (r)(last)r2.x
(rpt1)mad.f32 r31.z, (r)(last)r31.z, r18.z, (r)(last)r2.z
isam.v.base0 (u32)(xyzw)r2.x, r23.x, s#0, t#2
ldl.u32 r17.w, l[r1.z+768], 4
(sy)(ss)mad.f32 r17.x, r21.y, r3.x, (last)r17.x
mad.f32 r15.x, r21.y, r3.y, (last)r15.x
mad.f32 r13.x, r21.y, r3.z, (last)r13.x
mad.f32 r11.x, r21.y, r3.w, (last)r11.x
mad.f32 r17.y, r21.z, r3.x, (last)r17.y
mad.f32 r15.y, r21.z, r3.y, (last)r15.y
mad.f32 r13.y, r21.z, r3.z, (last)r13.y
mad.f32 r11.y, r21.z, r3.w, (last)r11.y
mad.f32 r17.z, r21.w, r3.x, (last)r17.z
mad.f32 r15.z, r21.w, r3.y, (last)r15.z
mad.f32 r13.z, r21.w, r3.z, (last)r13.z
mad.f32 r11.z, r21.w, r3.w, (last)r11.z
mad.f32 r0.y, r22.x, r3.x, (last)r0.y
mad.f32 r15.w, r22.x, r3.y, (last)r15.w
mad.f32 r13.w, r22.x, r3.z, (last)r13.w
mad.f32 r11.w, r22.x, r3.w, (last)r11.w
mad.f32 r16.x, r2.x, r3.x, (last)r16.x
mad.f32 r14.x, r2.x, r3.y, (last)r14.x
mad.f32 r12.x, r2.x, r3.z, (last)r12.x
mad.f32 r10.x, r2.x, r3.w, (last)r10.x
mad.f32 r16.y, r2.y, r3.x, (last)r16.y
mad.f32 r14.y, r2.y, r3.y, (last)r14.y
mad.f32 r12.y, r2.y, r3.z, (last)r12.y
mad.f32 r10.y, r2.y, r3.w, (last)r10.y
(rpt1)mad.f32 r16.z, (r)r2.z, r3.x, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r2.z, r3.y, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r2.z, r3.z, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r2.z, r3.w, (r)(last)r10.z
mad.f32 r9.x, r21.y, r17.w, (last)r9.x
mad.f32 r7.x, r21.y, r18.x, (last)r7.x
mad.f32 r5.x, r21.y, r18.y, (last)r5.x
mad.f32 r9.y, r21.z, r17.w, (last)r9.y
mad.f32 r7.y, r21.z, r18.x, (last)r7.y
mad.f32 r5.y, r21.z, r18.y, (last)r5.y
mad.f32 r9.z, r21.w, r17.w, (last)r9.z
mad.f32 r7.z, r21.w, r18.x, (last)r7.z
mad.f32 r5.z, r21.w, r18.y, (last)r5.z
mad.f32 r9.w, r22.x, r17.w, (last)r9.w
mad.f32 r7.w, r22.x, r18.x, (last)r7.w
mad.f32 r5.w, r22.x, r18.y, (last)r5.w
mad.f32 r8.x, r2.x, r17.w, (last)r8.x
mad.f32 r6.x, r2.x, r18.x, (last)r6.x
mad.f32 r4.x, r2.x, r18.y, (last)r4.x
mad.f32 r8.y, r2.y, r17.w, (last)r8.y
mad.f32 r6.y, r2.y, r18.x, (last)r6.y
mad.f32 r4.y, r2.y, r18.y, (last)r4.y
(rpt1)mad.f32 r8.z, (r)r2.z, r17.w, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r2.z, r18.x, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r2.z, r18.y, (r)(last)r4.z
(rpt1)mad.f32 r21.y, (r)(last)r21.y, r18.z, (r)(last)r30.y
mad.f32 r21.w, (last)r21.w, r18.z, (last)r30.w
mad.f32 r22.x, (last)r22.x, r18.z, (last)r0.z
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r18.z, (r)(last)r31.x
(rpt1)mad.f32 r2.z, (r)(last)r2.z, r18.z, (r)(last)r31.z
isam.v.base0 (u32)(xyzw)r17.w, r23.y, s#0, t#2
mov.u32u32 r0.z, (last)r22.y
ldl.u32 r22.y, l[r1.z+1024], 4
ldl.u32 r3.x, l[r1.z+1280], 4
ldl.u32 r30.y, l[r1.z+1536], 4
(sy)(ss)mad.f32 r17.x, r17.w, r22.y, (last)r17.x
mad.f32 r15.x, r17.w, r22.z, (last)r15.x
mad.f32 r13.x, r17.w, r22.w, (last)r13.x
mad.f32 r11.x, r17.w, r23.x, (last)r11.x
mad.f32 r17.y, r18.x, r22.y, (last)r17.y
mad.f32 r15.y, r18.x, r22.z, (last)r15.y
mad.f32 r13.y, r18.x, r22.w, (last)r13.y
mad.f32 r11.y, r18.x, r23.x, (last)r11.y
mad.f32 r17.z, r18.y, r22.y, (last)r17.z
mad.f32 r15.z, r18.y, r22.z, (last)r15.z
mad.f32 r13.z, r18.y, r22.w, (last)r13.z
mad.f32 r11.z, r18.y, r23.x, (last)r11.z
mad.f32 r0.y, r18.z, r22.y, (last)r0.y
mad.f32 r15.w, r18.z, r22.z, (last)r15.w
mad.f32 r13.w, r18.z, r22.w, (last)r13.w
mad.f32 r11.w, r18.z, r23.x, (last)r11.w
mad.f32 r9.x, r17.w, r3.x, (last)r9.x
mad.f32 r7.x, r17.w, r3.y, (last)r7.x
mad.f32 r5.x, r17.w, r3.z, (last)r5.x
mad.f32 r9.y, r18.x, r3.x, (last)r9.y
mad.f32 r7.y, r18.x, r3.y, (last)r7.y
mad.f32 r5.y, r18.x, r3.z, (last)r5.y
mad.f32 r9.z, r18.y, r3.x, (last)r9.z
mad.f32 r7.z, r18.y, r3.y, (last)r7.z
mad.f32 r5.z, r18.y, r3.z, (last)r5.z
mad.f32 r9.w, r18.z, r3.x, (last)r9.w
mad.f32 r7.w, r18.z, r3.y, (last)r7.w
mad.f32 r5.w, r18.z, r3.z, (last)r5.w
(rpt1)mad.f32 r17.w, (r)(last)r17.w, r3.w, (r)(last)r21.y
(rpt1)mad.f32 r18.y, (r)(last)r18.y, r3.w, (r)(last)r21.w
isam.v.base0 (u32)(xyzw)r21.y, r23.z, s#0, t#2
(sy)mad.f32 r16.x, r21.y, r22.y, (last)r16.x
mad.f32 r14.x, r21.y, r22.z, (last)r14.x
mad.f32 r12.x, r21.y, r22.w, (last)r12.x
mad.f32 r10.x, r21.y, r23.x, (last)r10.x
mad.f32 r16.y, r21.z, r22.y, (last)r16.y
mad.f32 r14.y, r21.z, r22.z, (last)r14.y
mad.f32 r12.y, r21.z, r22.w, (last)r12.y
mad.f32 r10.y, r21.z, r23.x, (last)r10.y
(rpt1)mad.f32 r16.z, (r)r21.w, r22.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r21.w, r22.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r21.w, r22.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r21.w, r23.x, (r)(last)r10.z
isam.v.base0 (u32)(xyzw)r22.y, r23.w, s#0, t#2
(ss)nop
isam.v.base0 (u32)(xyzw)r23.y, r24.x, s#0, t#2
mad.f32 r8.x, r21.y, r3.x, (last)r8.x
mad.f32 r6.x, r21.y, r3.y, (last)r6.x
mad.f32 r4.x, r21.y, r3.z, (last)r4.x
mad.f32 r8.y, r21.z, r3.x, (last)r8.y
mad.f32 r6.y, r21.z, r3.y, (last)r6.y
mad.f32 r4.y, r21.z, r3.z, (last)r4.y
(rpt1)mad.f32 r8.z, (r)r21.w, r3.x, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r21.w, r3.y, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r21.w, r3.z, (r)(last)r4.z
(rpt1)mad.f32 r21.y, (r)(last)r21.y, r3.w, (r)(last)r2.x
(rpt1)mad.f32 r21.w, (r)(last)r21.w, r3.w, (r)(last)r2.z
ldl.u32 r2.x, l[r1.z+1792], 4
ldl.u32 r3.x, l[r1.z+2048], 4
(sy)mad.f32 r17.x, r22.y, r30.y, (last)r17.x
mad.f32 r15.x, r22.y, r30.z, (last)r15.x
mad.f32 r13.x, r22.y, r30.w, (last)r13.x
mad.f32 r11.x, r22.y, r31.x, (last)r11.x
mad.f32 r17.y, r22.z, r30.y, (last)r17.y
mad.f32 r15.y, r22.z, r30.z, (last)r15.y
mad.f32 r13.y, r22.z, r30.w, (last)r13.y
mad.f32 r11.y, r22.z, r31.x, (last)r11.y
mad.f32 r17.z, r22.w, r30.y, (last)r17.z
mad.f32 r15.z, r22.w, r30.z, (last)r15.z
mad.f32 r13.z, r22.w, r30.w, (last)r13.z
mad.f32 r11.z, r22.w, r31.x, (last)r11.z
mad.f32 r15.w, r23.x, r30.z, (last)r15.w
mad.f32 r13.w, r23.x, r30.w, (last)r13.w
mad.f32 r11.w, r23.x, r31.x, (last)r11.w
mad.f32 r16.x, r23.y, r30.y, (last)r16.x
mad.f32 r14.x, r23.y, r30.z, (last)r14.x
mad.f32 r12.x, r23.y, r30.w, (last)r12.x
mad.f32 r10.x, r23.y, r31.x, (last)r10.x
mad.f32 r16.y, r23.z, r30.y, (last)r16.y
mad.f32 r14.y, r23.z, r30.z, (last)r14.y
mad.f32 r12.y, r23.z, r30.w, (last)r12.y
mad.f32 r10.y, r23.z, r31.x, (last)r10.y
(rpt1)mad.f32 r16.z, (r)r23.w, r30.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r23.w, r30.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r23.w, r30.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r23.w, r31.x, (r)(last)r10.z
(ss)mad.f32 r9.x, r22.y, r2.x, (last)r9.x
mad.f32 r7.x, r22.y, r2.y, (last)r7.x
mad.f32 r5.x, r22.y, r2.z, (last)r5.x
mad.f32 r9.y, r22.z, r2.x, (last)r9.y
mad.f32 r7.y, r22.z, r2.y, (last)r7.y
mad.f32 r5.y, r22.z, r2.z, (last)r5.y
mad.f32 r9.z, r22.w, r2.x, (last)r9.z
mad.f32 r7.z, r22.w, r2.y, (last)r7.z
mad.f32 r5.z, r22.w, r2.z, (last)r5.z
mad.f32 r9.w, r23.x, r2.x, (last)r9.w
mad.f32 r7.w, r23.x, r2.y, (last)r7.w
mad.f32 r5.w, r23.x, r2.z, (last)r5.w
mad.f32 r8.x, r23.y, r2.x, (last)r8.x
mad.f32 r6.x, r23.y, r2.y, (last)r6.x
mad.f32 r4.x, r23.y, r2.z, (last)r4.x
mad.f32 r8.y, r23.z, r2.x, (last)r8.y
mad.f32 r6.y, r23.z, r2.y, (last)r6.y
mad.f32 r4.y, r23.z, r2.z, (last)r4.y
(rpt1)mad.f32 r8.z, (r)r23.w, r2.x, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r23.w, r2.y, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r23.w, r2.z, (r)(last)r4.z
(rpt1)mad.f32 r22.y, (r)(last)r22.y, r2.w, (r)(last)r17.w
mad.f32 r22.w, (last)r22.w, r2.w, (last)r18.y
(rpt1)mad.f32 r23.y, (r)(last)r23.y, r2.w, (r)(last)r21.y
(rpt1)mad.f32 r23.w, (r)(last)r23.w, r2.w, (r)(last)r21.w
ldl.u32 r21.y, l[r1.z+2304], 4
mad.f32 r17.w, r23.x, r30.y, (last)r0.y
isam.v.base0 (u32)(xyzw)r30.y, r24.y, s#0, t#2
mad.f32 r23.x, (last)r23.x, r2.w, (last)r18.z
isam.v.base0 (u32)(xyzw)r2.x, r24.z, s#0, t#2
(sy)mad.f32 r17.x, r30.y, r3.x, (last)r17.x
mad.f32 r15.x, r30.y, r3.y, (last)r15.x
mad.f32 r13.x, r30.y, r3.z, (last)r13.x
mad.f32 r11.x, r30.y, r3.w, (last)r11.x
mad.f32 r17.y, r30.z, r3.x, (last)r17.y
mad.f32 r15.y, r30.z, r3.y, (last)r15.y
(ss)mad.f32 r9.x, r30.y, r21.y, (last)r9.x
mad.f32 r7.x, r30.y, r21.z, (last)r7.x
mad.f32 r5.x, r30.y, r21.w, (last)r5.x
mad.f32 r13.y, r30.z, r3.z, (last)r13.y
mad.f32 r11.y, r30.z, r3.w, (last)r11.y
mad.f32 r9.y, r30.z, r21.y, (last)r9.y
mad.f32 r7.y, r30.z, r21.z, (last)r7.y
mad.f32 r5.y, r30.z, r21.w, (last)r5.y
mad.f32 r17.z, r30.w, r3.x, (last)r17.z
mad.f32 r15.z, r30.w, r3.y, (last)r15.z
mad.f32 r13.z, r30.w, r3.z, (last)r13.z
mad.f32 r11.z, r30.w, r3.w, (last)r11.z
mad.f32 r9.z, r30.w, r21.y, (last)r9.z
mad.f32 r7.z, r30.w, r21.z, (last)r7.z
mad.f32 r5.z, r30.w, r21.w, (last)r5.z
mad.f32 r17.w, r31.x, r3.x, (last)r17.w
mad.f32 r15.w, r31.x, r3.y, (last)r15.w
mad.f32 r13.w, r31.x, r3.z, (last)r13.w
mad.f32 r11.w, r31.x, r3.w, (last)r11.w
mad.f32 r9.w, r31.x, r21.y, (last)r9.w
mad.f32 r7.w, r31.x, r21.z, (last)r7.w
mad.f32 r5.w, r31.x, r21.w, (last)r5.w
mad.f32 r16.x, r2.x, r3.x, (last)r16.x
mad.f32 r14.x, r2.x, r3.y, (last)r14.x
mad.f32 r12.x, r2.x, r3.z, (last)r12.x
mad.f32 r10.x, r2.x, r3.w, (last)r10.x
mad.f32 r8.x, r2.x, r21.y, (last)r8.x
mad.f32 r6.x, r2.x, r21.z, (last)r6.x
mad.f32 r4.x, r2.x, r21.w, (last)r4.x
mad.f32 r16.y, r2.y, r3.x, (last)r16.y
mad.f32 r14.y, r2.y, r3.y, (last)r14.y
mad.f32 r12.y, r2.y, r3.z, (last)r12.y
mad.f32 r10.y, r2.y, r3.w, (last)r10.y
mad.f32 r8.y, r2.y, r21.y, (last)r8.y
mad.f32 r6.y, r2.y, r21.z, (last)r6.y
mad.f32 r4.y, r2.y, r21.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r2.z, r3.x, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r2.z, r3.y, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r2.z, r3.z, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r2.z, r3.w, (r)(last)r10.z
isam.v.base0 (u32)(xyzw)r3.x, r24.w, s#0, t#2
(rpt1)mad.f32 r8.z, (r)r2.z, r21.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r2.z, r21.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r2.z, r21.w, (r)(last)r4.z
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r22.x, (r)(last)r22.y
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r22.x, (r)(last)r22.w
ldl.u32 r22.y, l[r1.z+2560], 4
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r22.x, (r)(last)r23.y
(rpt1)mad.f32 r2.z, (r)(last)r2.z, r22.x, (r)(last)r23.w
isam.v.base0 (u32)(xyzw)r21.y, r25.x, s#0, t#2
ldl.u32 r23.y, l[r1.z+2816], 4
(sy)(ss)mad.f32 r17.x, r3.x, r22.y, (last)r17.x
ldl.u32 r24.y, l[r1.z+3072], 4
mad.f32 r15.x, r3.x, r22.z, (last)r15.x
mad.f32 r13.x, r3.x, r22.w, (last)r13.x
mad.f32 r11.x, r3.x, r23.x, (last)r11.x
mad.f32 r17.y, r3.y, r22.y, (last)r17.y
mad.f32 r15.y, r3.y, r22.z, (last)r15.y
mad.f32 r13.y, r3.y, r22.w, (last)r13.y
mad.f32 r11.y, r3.y, r23.x, (last)r11.y
mad.f32 r17.z, r3.z, r22.y, (last)r17.z
mad.f32 r15.z, r3.z, r22.z, (last)r15.z
mad.f32 r13.z, r3.z, r22.w, (last)r13.z
mad.f32 r11.z, r3.z, r23.x, (last)r11.z
mad.f32 r17.w, r3.w, r22.y, (last)r17.w
mad.f32 r15.w, r3.w, r22.z, (last)r15.w
mad.f32 r13.w, r3.w, r22.w, (last)r13.w
mad.f32 r11.w, r3.w, r23.x, (last)r11.w
mad.f32 r16.x, r21.y, r22.y, (last)r16.x
mad.f32 r14.x, r21.y, r22.z, (last)r14.x
mad.f32 r12.x, r21.y, r22.w, (last)r12.x
mad.f32 r10.x, r21.y, r23.x, (last)r10.x
mad.f32 r16.y, r21.z, r22.y, (last)r16.y
mad.f32 r14.y, r21.z, r22.z, (last)r14.y
mad.f32 r12.y, r21.z, r22.w, (last)r12.y
mad.f32 r10.y, r21.z, r23.x, (last)r10.y
(rpt1)mad.f32 r16.z, (r)r21.w, r22.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r21.w, r22.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r21.w, r22.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r21.w, r23.x, (r)(last)r10.z
isam.v.base0 (u32)(xyzw)r22.y, r25.y, s#0, t#2
mad.f32 r9.x, r3.x, r23.y, (last)r9.x
mad.f32 r7.x, r3.x, r23.z, (last)r7.x
mad.f32 r5.x, r3.x, r23.w, (last)r5.x
mad.f32 r9.y, r3.y, r23.y, (last)r9.y
mad.f32 r7.y, r3.y, r23.z, (last)r7.y
mad.f32 r5.y, r3.y, r23.w, (last)r5.y
mad.f32 r9.z, r3.z, r23.y, (last)r9.z
mad.f32 r7.z, r3.z, r23.z, (last)r7.z
mad.f32 r5.z, r3.z, r23.w, (last)r5.z
mad.f32 r9.w, r3.w, r23.y, (last)r9.w
mad.f32 r7.w, r3.w, r23.z, (last)r7.w
mad.f32 r5.w, r3.w, r23.w, (last)r5.w
mad.f32 r8.x, r21.y, r23.y, (last)r8.x
mad.f32 r6.x, r21.y, r23.z, (last)r6.x
mad.f32 r4.x, r21.y, r23.w, (last)r4.x
mad.f32 r8.y, r21.z, r23.y, (last)r8.y
mad.f32 r6.y, r21.z, r23.z, (last)r6.y
mad.f32 r4.y, r21.z, r23.w, (last)r4.y
(rpt1)mad.f32 r8.z, (r)r21.w, r23.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r21.w, r23.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r21.w, r23.w, (r)(last)r4.z
(rpt1)mad.f32 r3.x, (r)(last)r3.x, r24.x, (r)(last)r30.y
(rpt1)mad.f32 r3.z, (r)(last)r3.z, r24.x, (r)(last)r30.w
ldl.u32 r30.y, l[r1.z+3328], 4
(rpt1)mad.f32 r21.y, (r)(last)r21.y, r24.x, (r)(last)r2.x
(rpt1)mad.f32 r21.w, (r)(last)r21.w, r24.x, (r)(last)r2.z
isam.v.base0 (u32)(xyzw)r23.y, r25.z, s#0, t#2
ldl.u32 r2.x, l[r1.z+3584], 4
(sy)(ss)mad.f32 r16.x, r23.y, r24.y, (last)r16.x
mad.f32 r14.x, r23.y, r24.z, (last)r14.x
mad.f32 r12.x, r23.y, r24.w, (last)r12.x
mad.f32 r10.x, r23.y, r25.x, (last)r10.x
mad.f32 r8.x, r23.y, r30.y, (last)r8.x
mad.f32 r6.x, r23.y, r30.z, (last)r6.x
mad.f32 r4.x, r23.y, r30.w, (last)r4.x
mad.f32 r16.y, r23.z, r24.y, (last)r16.y
mad.f32 r14.y, r23.z, r24.z, (last)r14.y
mad.f32 r12.y, r23.z, r24.w, (last)r12.y
mad.f32 r10.y, r23.z, r25.x, (last)r10.y
mad.f32 r8.y, r23.z, r30.y, (last)r8.y
mad.f32 r6.y, r23.z, r30.z, (last)r6.y
mad.f32 r4.y, r23.z, r30.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r23.w, r24.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r23.w, r24.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r23.w, r24.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r23.w, r25.x, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r23.w, r30.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r23.w, r30.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r23.w, r30.w, (r)(last)r4.z
(rpt1)mad.f32 r23.y, (r)(last)r23.y, r31.x, (r)(last)r21.y
(rpt1)mad.f32 r23.w, (r)(last)r23.w, r31.x, (r)(last)r21.w
isam.v.base0 (u32)(xyzw)r21.y, r25.w, s#0, t#2
mad.f32 r17.x, r22.y, r24.y, (last)r17.x
mad.f32 r15.x, r22.y, r24.z, (last)r15.x
mad.f32 r13.x, r22.y, r24.w, (last)r13.x
mad.f32 r11.x, r22.y, r25.x, (last)r11.x
mad.f32 r17.y, r22.z, r24.y, (last)r17.y
mad.f32 r15.y, r22.z, r24.z, (last)r15.y
mad.f32 r13.y, r22.z, r24.w, (last)r13.y
mad.f32 r11.y, r22.z, r25.x, (last)r11.y
mad.f32 r17.z, r22.w, r24.y, (last)r17.z
mad.f32 r15.z, r22.w, r24.z, (last)r15.z
mad.f32 r13.z, r22.w, r24.w, (last)r13.z
mad.f32 r11.z, r22.w, r25.x, (last)r11.z
mad.f32 r17.w, r23.x, r24.y, (last)r17.w
mad.f32 r15.w, r23.x, r24.z, (last)r15.w
mad.f32 r13.w, r23.x, r24.w, (last)r13.w
mad.f32 r11.w, r23.x, r25.x, (last)r11.w
mad.f32 r9.x, r22.y, r30.y, (last)r9.x
mad.f32 r7.x, r22.y, r30.z, (last)r7.x
mad.f32 r5.x, r22.y, r30.w, (last)r5.x
mad.f32 r9.y, r22.z, r30.y, (last)r9.y
mad.f32 r7.y, r22.z, r30.z, (last)r7.y
mad.f32 r5.y, r22.z, r30.w, (last)r5.y
mad.f32 r9.z, r22.w, r30.y, (last)r9.z
mad.f32 r7.z, r22.w, r30.z, (last)r7.z
mad.f32 r5.z, r22.w, r30.w, (last)r5.z
mad.f32 r9.w, r23.x, r30.y, (last)r9.w
mad.f32 r7.w, r23.x, r30.z, (last)r7.w
mad.f32 r5.w, r23.x, r30.w, (last)r5.w
(rpt1)mad.f32 r22.y, (r)(last)r22.y, r31.x, (r)(last)r3.x
(rpt1)mad.f32 r22.w, (r)(last)r22.w, r31.x, (r)(last)r3.z
ldl.u32 r3.x, l[r1.z+3840], 4
ldl.u32 r24.y, l[r18.w], 4
(sy)mad.f32 r17.x, r21.y, r2.x, (last)r17.x
mad.f32 r15.x, r21.y, r2.y, (last)r15.x
mad.f32 r13.x, r21.y, r2.z, (last)r13.x
mad.f32 r11.x, r21.y, r2.w, (last)r11.x
mad.f32 r17.y, r21.z, r2.x, (last)r17.y
mad.f32 r15.y, r21.z, r2.y, (last)r15.y
mad.f32 r13.y, r21.z, r2.z, (last)r13.y
mad.f32 r11.y, r21.z, r2.w, (last)r11.y
mad.f32 r17.z, r21.w, r2.x, (last)r17.z
mad.f32 r15.z, r21.w, r2.y, (last)r15.z
mad.f32 r13.z, r21.w, r2.z, (last)r13.z
mad.f32 r11.z, r21.w, r2.w, (last)r11.z
mad.f32 r17.w, r22.x, r2.x, (last)r17.w
mad.f32 r15.w, r22.x, r2.y, (last)r15.w
mad.f32 r13.w, r22.x, r2.z, (last)r13.w
mad.f32 r11.w, r22.x, r2.w, (last)r11.w
(ss)mad.f32 r9.x, r21.y, r3.x, (last)r9.x
mad.f32 r7.x, r21.y, r3.y, (last)r7.x
mad.f32 r5.x, r21.y, r3.z, (last)r5.x
mad.f32 r9.y, r21.z, r3.x, (last)r9.y
mad.f32 r7.y, r21.z, r3.y, (last)r7.y
mad.f32 r5.y, r21.z, r3.z, (last)r5.y
mad.f32 r9.z, r21.w, r3.x, (last)r9.z
mad.f32 r7.z, r21.w, r3.y, (last)r7.z
mad.f32 r5.z, r21.w, r3.z, (last)r5.z
mad.f32 r9.w, r22.x, r3.x, (last)r9.w
mad.f32 r7.w, r22.x, r3.y, (last)r7.w
mad.f32 r5.w, r22.x, r3.z, (last)r5.w
(rpt1)mad.f32 r21.y, (r)(last)r21.y, r3.w, (r)(last)r22.y
(rpt1)mad.f32 r21.w, (r)(last)r21.w, r3.w, (r)(last)r22.w
isam.v.base0 (u32)(xyzw)r22.y, r26.x, s#0, t#2
isam.v.base0 (u32)(xyzw)r30.y, r26.y, s#0, t#2
(ss)nop
ldl.u32 r25.y, l[r18.w+256], 4
(sy)mad.f32 r14.x, r22.y, r2.y, (last)r14.x
mad.f32 r12.x, r22.y, r2.z, (last)r12.x
mad.f32 r10.x, r22.y, r2.w, (last)r10.x
mad.f32 r8.x, r22.y, r3.x, (last)r8.x
mad.f32 r14.y, r22.z, r2.y, (last)r14.y
mad.f32 r12.y, r22.z, r2.z, (last)r12.y
mad.f32 r10.y, r22.z, r2.w, (last)r10.y
mad.f32 r8.y, r22.z, r3.x, (last)r8.y
(rpt1)mad.f32 r14.z, (r)r22.w, r2.y, (r)(last)r14.z
(ss)nop
ldl.u32 r18.x, l[r19.x], 4
(rpt1)mad.f32 r12.z, (r)r22.w, r2.z, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r22.w, r2.w, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r22.w, r3.x, (r)(last)r8.z
isam.v.base0 (u32)(xyzw)r2.y, r26.z, s#0, t#2
mad.f32 r16.x, r22.y, r2.x, (last)r16.x
mad.f32 r6.x, r22.y, r3.y, (last)r6.x
mad.f32 r4.x, r22.y, r3.z, (last)r4.x
mad.f32 r16.y, r22.z, r2.x, (last)r16.y
mad.f32 r6.y, r22.z, r3.y, (last)r6.y
mad.f32 r4.y, r22.z, r3.z, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r22.w, r2.x, (r)(last)r16.z
(rpt1)mad.f32 r6.z, (r)r22.w, r3.y, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r22.w, r3.z, (r)(last)r4.z
(rpt1)mad.f32 r22.y, (r)(last)r22.y, r3.w, (r)(last)r23.y
(rpt1)mad.f32 r22.w, (r)(last)r22.w, r3.w, (r)(last)r23.w
mad.f32 r17.x, r30.y, r24.y, (last)r17.x
mad.f32 r15.x, r30.y, r24.z, (last)r15.x
mad.f32 r13.x, r30.y, r24.w, (last)r13.x
mad.f32 r11.x, r30.y, r25.x, (last)r11.x
mad.f32 r17.y, r30.z, r24.y, (last)r17.y
mad.f32 r15.y, r30.z, r24.z, (last)r15.y
mad.f32 r13.y, r30.z, r24.w, (last)r13.y
mad.f32 r11.y, r30.z, r25.x, (last)r11.y
mad.f32 r17.z, r30.w, r24.y, (last)r17.z
mad.f32 r15.z, r30.w, r24.z, (last)r15.z
mad.f32 r13.z, r30.w, r24.w, (last)r13.z
mad.f32 r11.z, r30.w, r25.x, (last)r11.z
mad.f32 r17.w, r31.x, r24.y, (last)r17.w
mad.f32 r15.w, r31.x, r24.z, (last)r15.w
mad.f32 r13.w, r31.x, r24.w, (last)r13.w
mad.f32 r11.w, r31.x, r25.x, (last)r11.w
mad.f32 r9.x, r30.y, r25.y, (last)r9.x
mad.f32 r7.x, r30.y, r25.z, (last)r7.x
mad.f32 r5.x, r30.y, r25.w, (last)r5.x
mad.f32 r9.y, r30.z, r25.y, (last)r9.y
mad.f32 r7.y, r30.z, r25.z, (last)r7.y
mad.f32 r5.y, r30.z, r25.w, (last)r5.y
mad.f32 r9.z, r30.w, r25.y, (last)r9.z
(sy)mad.f32 r14.x, r2.y, r24.z, (last)r14.x
mad.f32 r12.x, r2.y, r24.w, (last)r12.x
mad.f32 r10.x, r2.y, r25.x, (last)r10.x
mad.f32 r8.x, r2.y, r25.y, (last)r8.x
mad.f32 r14.y, r2.z, r24.z, (last)r14.y
mad.f32 r12.y, r2.z, r24.w, (last)r12.y
mad.f32 r10.y, r2.z, r25.x, (last)r10.y
mad.f32 r8.y, r2.z, r25.y, (last)r8.y
(rpt1)mad.f32 r14.z, (r)r2.w, r24.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r2.w, r24.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r2.w, r25.x, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r2.w, r25.y, (r)(last)r8.z
mad.f32 r16.x, r2.y, r24.y, (last)r16.x
mad.f32 r6.x, r2.y, r25.z, (last)r6.x
mad.f32 r4.x, r2.y, r25.w, (last)r4.x
mad.f32 r16.y, r2.z, r24.y, (last)r16.y
mad.f32 r6.y, r2.z, r25.z, (last)r6.y
mad.f32 r4.y, r2.z, r25.w, (last)r4.y
(rpt1)mad.f32 r16.z, (r)r2.w, r24.y, (r)(last)r16.z
(rpt1)mad.f32 r6.z, (r)r2.w, r25.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r2.w, r25.w, (r)(last)r4.z
(rpt1)mad.f32 r2.y, (r)(last)r2.y, r26.x, (r)(last)r22.y
(rpt1)mad.f32 r2.w, (r)(last)r2.w, r26.x, (r)(last)r22.w
isam.v.base0 (u32)(xyzw)r22.y, r26.w, s#0, t#2
isam.v.base0 (u32)(xyzw)r23.y, r27.x, s#0, t#2
(ss)nop
isam.v.base0 (u32)(xyzw)r26.y, r27.y, s#0, t#2
mad.f32 r7.z, r30.w, r25.z, (last)r7.z
mad.f32 r5.z, r30.w, r25.w, (last)r5.z
mad.f32 r9.w, r31.x, r25.y, (last)r9.w
mad.f32 r7.w, r31.x, r25.z, (last)r7.w
mad.f32 r5.w, r31.x, r25.w, (last)r5.w
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r26.x, (r)(last)r21.y
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r26.x, (r)(last)r21.w
ldl.u32 r21.y, l[r19.x+256], 4
ldl.u32 r24.y, l[r19.y], 4
ldl.u32 r25.y, l[r19.y+256], 4
(sy)mad.f32 r17.x, r22.y, r18.x, (last)r17.x
mad.f32 r15.x, r22.y, r18.y, (last)r15.x
mad.f32 r13.x, r22.y, r18.z, (last)r13.x
mad.f32 r11.x, r22.y, r18.w, (last)r11.x
mad.f32 r17.y, r22.z, r18.x, (last)r17.y
mad.f32 r15.y, r22.z, r18.y, (last)r15.y
mad.f32 r13.y, r22.z, r18.z, (last)r13.y
mad.f32 r11.y, r22.z, r18.w, (last)r11.y
mad.f32 r17.z, r22.w, r18.x, (last)r17.z
mad.f32 r15.z, r22.w, r18.y, (last)r15.z
mad.f32 r13.z, r22.w, r18.z, (last)r13.z
mad.f32 r11.z, r22.w, r18.w, (last)r11.z
mad.f32 r17.w, r23.x, r18.x, (last)r17.w
mad.f32 r15.w, r23.x, r18.y, (last)r15.w
mad.f32 r13.w, r23.x, r18.z, (last)r13.w
mad.f32 r11.w, r23.x, r18.w, (last)r11.w
(ss)mad.f32 r9.x, r22.y, r21.y, (last)r9.x
mad.f32 r7.x, r22.y, r21.z, (last)r7.x
mad.f32 r5.x, r22.y, r21.w, (last)r5.x
mad.f32 r9.y, r22.z, r21.y, (last)r9.y
mad.f32 r7.y, r22.z, r21.z, (last)r7.y
mad.f32 r5.y, r22.z, r21.w, (last)r5.y
mad.f32 r9.z, r22.w, r21.y, (last)r9.z
mad.f32 r7.z, r22.w, r21.z, (last)r7.z
mad.f32 r5.z, r22.w, r21.w, (last)r5.z
mad.f32 r9.w, r23.x, r21.y, (last)r9.w
mad.f32 r7.w, r23.x, r21.z, (last)r7.w
mad.f32 r5.w, r23.x, r21.w, (last)r5.w
(rpt1)mad.f32 r22.y, (r)(last)r22.y, r22.x, (r)(last)r30.y
(rpt1)mad.f32 r22.w, (r)(last)r22.w, r22.x, (r)(last)r30.w
isam.v.base0 (u32)(xyzw)r30.y, r27.z, s#0, t#2
mad.f32 r16.x, r23.y, r18.x, (last)r16.x
mad.f32 r14.x, r23.y, r18.y, (last)r14.x
mad.f32 r12.x, r23.y, r18.z, (last)r12.x
mad.f32 r10.x, r23.y, r18.w, (last)r10.x
mad.f32 r16.y, r23.z, r18.x, (last)r16.y
mad.f32 r14.y, r23.z, r18.y, (last)r14.y
mad.f32 r12.y, r23.z, r18.z, (last)r12.y
mad.f32 r10.y, r23.z, r18.w, (last)r10.y
(rpt1)mad.f32 r16.z, (r)r23.w, r18.x, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r23.w, r18.y, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r23.w, r18.z, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r23.w, r18.w, (r)(last)r10.z
isam.v.base0 (u32)(xyzw)r18.y, r27.w, s#0, t#2
mad.f32 r8.x, r23.y, r21.y, (last)r8.x
mad.f32 r6.x, r23.y, r21.z, (last)r6.x
mad.f32 r4.x, r23.y, r21.w, (last)r4.x
mad.f32 r8.y, r23.z, r21.y, (last)r8.y
mad.f32 r6.y, r23.z, r21.z, (last)r6.y
mad.f32 r4.y, r23.z, r21.w, (last)r4.y
(rpt1)mad.f32 r8.z, (r)r23.w, r21.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r23.w, r21.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r23.w, r21.w, (r)(last)r4.z
(rpt1)mad.f32 r23.y, (r)(last)r23.y, r22.x, (r)(last)r2.y
mad.f32 r23.w, (last)r23.w, r22.x, (last)r2.w
ldl.u32 r2.x, l[r19.z], 4
mad.f32 r24.x, (last)r24.x, r22.x, (last)r3.x
ldl.u32 r3.x, l[r19.z+256], 4
ldl.u32 r21.y, l[r20.y], 4
mad.f32 r17.x, r26.y, r24.y, (last)r17.x
mad.f32 r15.x, r26.y, r24.z, (last)r15.x
mad.f32 r13.x, r26.y, r24.w, (last)r13.x
mad.f32 r11.x, r26.y, r25.x, (last)r11.x
mad.f32 r17.y, r26.z, r24.y, (last)r17.y
mad.f32 r15.y, r26.z, r24.z, (last)r15.y
mad.f32 r13.y, r26.z, r24.w, (last)r13.y
mad.f32 r11.y, r26.z, r25.x, (last)r11.y
mad.f32 r17.z, r26.w, r24.y, (last)r17.z
mad.f32 r15.z, r26.w, r24.z, (last)r15.z
(ss)nop
isam.v.base0 (u32)(xyzw)r19.y, r28.x, s#0, t#2
mad.f32 r13.z, r26.w, r24.w, (last)r13.z
mad.f32 r11.z, r26.w, r25.x, (last)r11.z
mad.f32 r17.w, r27.x, r24.y, (last)r17.w
mad.f32 r15.w, r27.x, r24.z, (last)r15.w
mad.f32 r13.w, r27.x, r24.w, (last)r13.w
mad.f32 r11.w, r27.x, r25.x, (last)r11.w
mad.f32 r9.x, r26.y, r25.y, (last)r9.x
mad.f32 r7.x, r26.y, r25.z, (last)r7.x
mad.f32 r5.x, r26.y, r25.w, (last)r5.x
mad.f32 r9.y, r26.z, r25.y, (last)r9.y
mad.f32 r7.y, r26.z, r25.z, (last)r7.y
mad.f32 r5.y, r26.z, r25.w, (last)r5.y
mad.f32 r9.z, r26.w, r25.y, (last)r9.z
mad.f32 r7.z, r26.w, r25.z, (last)r7.z
mad.f32 r5.z, r26.w, r25.w, (last)r5.z
mad.f32 r9.w, r27.x, r25.y, (last)r9.w
mad.f32 r7.w, r27.x, r25.z, (last)r7.w
mad.f32 r5.w, r27.x, r25.w, (last)r5.w
(rpt1)mad.f32 r26.y, (r)(last)r26.y, r26.x, (r)(last)r22.y
(rpt1)mad.f32 r26.w, (r)(last)r26.w, r26.x, (r)(last)r22.w
ldl.u32 r22.y, l[r20.y+256], 4
(sy)mad.f32 r16.x, r30.y, r24.y, (last)r16.x
mad.f32 r14.x, r30.y, r24.z, (last)r14.x
mad.f32 r12.x, r30.y, r24.w, (last)r12.x
mad.f32 r10.x, r30.y, r25.x, (last)r10.x
mad.f32 r16.y, r30.z, r24.y, (last)r16.y
mad.f32 r14.y, r30.z, r24.z, (last)r14.y
mad.f32 r12.y, r30.z, r24.w, (last)r12.y
mad.f32 r10.y, r30.z, r25.x, (last)r10.y
(rpt1)mad.f32 r16.z, (r)r30.w, r24.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r30.w, r24.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r30.w, r24.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r30.w, r25.x, (r)(last)r10.z
mad.f32 r8.x, r30.y, r25.y, (last)r8.x
mad.f32 r6.x, r30.y, r25.z, (last)r6.x
mad.f32 r4.x, r30.y, r25.w, (last)r4.x
mad.f32 r8.y, r30.z, r25.y, (last)r8.y
mad.f32 r6.y, r30.z, r25.z, (last)r6.y
mad.f32 r4.y, r30.z, r25.w, (last)r4.y
(rpt1)mad.f32 r8.z, (r)r30.w, r25.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r30.w, r25.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r30.w, r25.w, (r)(last)r4.z
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r26.x, (r)(last)r23.y
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r26.x, (r)(last)r23.w
isam.v.base0 (u32)(xyzw)r23.y, r28.y, s#0, t#2
isam.v.base0 (u32)(xyzw)r24.y, r28.z, s#0, t#2
isam.v.base0 (u32)(xyzw)r27.y, r28.w, s#0, t#2
(ss)nop
isam.v.base0 (u32)(xyzw)r28.y, r29.x, s#0, t#2
ldl.u32 r25.y, l[r20.z], 4
mad.f32 r17.x, r18.y, r2.x, (last)r17.x
mad.f32 r15.x, r18.y, r2.y, (last)r15.x
mad.f32 r13.x, r18.y, r2.z, (last)r13.x
mad.f32 r11.x, r18.y, r2.w, (last)r11.x
mad.f32 r17.y, r18.z, r2.x, (last)r17.y
mad.f32 r15.y, r18.z, r2.y, (last)r15.y
mad.f32 r13.y, r18.z, r2.z, (last)r13.y
mad.f32 r11.y, r18.z, r2.w, (last)r11.y
mad.f32 r17.z, r18.w, r2.x, (last)r17.z
mad.f32 r15.z, r18.w, r2.y, (last)r15.z
mad.f32 r13.z, r18.w, r2.z, (last)r13.z
mad.f32 r11.z, r18.w, r2.w, (last)r11.z
mad.f32 r17.w, r19.x, r2.x, (last)r17.w
mad.f32 r15.w, r19.x, r2.y, (last)r15.w
mad.f32 r13.w, r19.x, r2.z, (last)r13.w
mad.f32 r11.w, r19.x, r2.w, (last)r11.w
mad.f32 r9.x, r18.y, r3.x, (last)r9.x
mad.f32 r7.x, r18.y, r3.y, (last)r7.x
mad.f32 r5.x, r18.y, r3.z, (last)r5.x
mad.f32 r9.y, r18.z, r3.x, (last)r9.y
mad.f32 r7.y, r18.z, r3.y, (last)r7.y
mad.f32 r5.y, r18.z, r3.z, (last)r5.y
mad.f32 r9.z, r18.w, r3.x, (last)r9.z
mad.f32 r7.z, r18.w, r3.y, (last)r7.z
mad.f32 r5.z, r18.w, r3.z, (last)r5.z
mad.f32 r9.w, r19.x, r3.x, (last)r9.w
mad.f32 r7.w, r19.x, r3.y, (last)r7.w
mad.f32 r5.w, r19.x, r3.z, (last)r5.w
(rpt1)mad.f32 r18.y, (r)(last)r18.y, r3.w, (r)(last)r26.y
(rpt1)mad.f32 r18.w, (r)(last)r18.w, r3.w, (r)(last)r26.w
ldl.u32 r26.y, l[r20.z+256], 4
mad.f32 r16.x, r19.y, r2.x, (last)r16.x
mad.f32 r14.x, r19.y, r2.y, (last)r14.x
mad.f32 r12.x, r19.y, r2.z, (last)r12.x
mad.f32 r10.x, r19.y, r2.w, (last)r10.x
mad.f32 r16.y, r19.z, r2.x, (last)r16.y
mad.f32 r14.y, r19.z, r2.y, (last)r14.y
mad.f32 r12.y, r19.z, r2.z, (last)r12.y
mad.f32 r10.y, r19.z, r2.w, (last)r10.y
(rpt1)mad.f32 r16.z, (r)r19.w, r2.x, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r19.w, r2.y, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r19.w, r2.z, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r19.w, r2.w, (r)(last)r10.z
mad.f32 r8.x, r19.y, r3.x, (last)r8.x
mad.f32 r6.x, r19.y, r3.y, (last)r6.x
mad.f32 r4.x, r19.y, r3.z, (last)r4.x
mad.f32 r8.y, r19.z, r3.x, (last)r8.y
mad.f32 r6.y, r19.z, r3.y, (last)r6.y
mad.f32 r4.y, r19.z, r3.z, (last)r4.y
(rpt1)mad.f32 r8.z, (r)r19.w, r3.x, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r19.w, r3.y, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r19.w, r3.z, (r)(last)r4.z
(rpt1)mad.f32 r19.y, (r)(last)r19.y, r3.w, (r)(last)r30.y
(rpt1)mad.f32 r19.w, (r)(last)r19.w, r3.w, (r)(last)r30.w
ldl.u32 r30.y, l[r20.w], 4
ldl.u32 r2.x, l[r20.w+256], 4
(sy)mad.f32 r17.x, r23.y, r21.y, (last)r17.x
mad.f32 r15.x, r23.y, r21.z, (last)r15.x
mad.f32 r13.x, r23.y, r21.w, (last)r13.x
mad.f32 r11.x, r23.y, r22.x, (last)r11.x
mad.f32 r17.y, r23.z, r21.y, (last)r17.y
mad.f32 r15.y, r23.z, r21.z, (last)r15.y
mad.f32 r13.y, r23.z, r21.w, (last)r13.y
mad.f32 r11.y, r23.z, r22.x, (last)r11.y
mad.f32 r17.z, r23.w, r21.y, (last)r17.z
mad.f32 r15.z, r23.w, r21.z, (last)r15.z
mad.f32 r13.z, r23.w, r21.w, (last)r13.z
mad.f32 r11.z, r23.w, r22.x, (last)r11.z
mad.f32 r17.w, r24.x, r21.y, (last)r17.w
mad.f32 r15.w, r24.x, r21.z, (last)r15.w
mad.f32 r13.w, r24.x, r21.w, (last)r13.w
mad.f32 r11.w, r24.x, r22.x, (last)r11.w
mad.f32 r9.x, r23.y, r22.y, (last)r9.x
mad.f32 r7.x, r23.y, r22.z, (last)r7.x
mad.f32 r5.x, r23.y, r22.w, (last)r5.x
mad.f32 r9.y, r23.z, r22.y, (last)r9.y
mad.f32 r7.y, r23.z, r22.z, (last)r7.y
mad.f32 r5.y, r23.z, r22.w, (last)r5.y
mad.f32 r9.z, r23.w, r22.y, (last)r9.z
mad.f32 r7.z, r23.w, r22.z, (last)r7.z
mad.f32 r5.z, r23.w, r22.w, (last)r5.z
mad.f32 r9.w, r24.x, r22.y, (last)r9.w
mad.f32 r7.w, r24.x, r22.z, (last)r7.w
mad.f32 r5.w, r24.x, r22.w, (last)r5.w
mad.f32 r16.x, r24.y, r21.y, (last)r16.x
mad.f32 r14.x, r24.y, r21.z, (last)r14.x
mad.f32 r12.x, r24.y, r21.w, (last)r12.x
mad.f32 r10.x, r24.y, r22.x, (last)r10.x
mad.f32 r16.y, r24.z, r21.y, (last)r16.y
mad.f32 r14.y, r24.z, r21.z, (last)r14.y
mad.f32 r12.y, r24.z, r21.w, (last)r12.y
mad.f32 r10.y, r24.z, r22.x, (last)r10.y
(rpt1)mad.f32 r16.z, (r)r24.w, r21.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r24.w, r21.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r24.w, r21.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r24.w, r22.x, (r)(last)r10.z
ldl.u32 r21.y, l[r21.x], 4
mad.f32 r8.x, r24.y, r22.y, (last)r8.x
mad.f32 r6.x, r24.y, r22.z, (last)r6.x
mad.f32 r4.x, r24.y, r22.w, (last)r4.x
mad.f32 r8.y, r24.z, r22.y, (last)r8.y
mad.f32 r6.y, r24.z, r22.z, (last)r6.y
mad.f32 r4.y, r24.z, r22.w, (last)r4.y
(rpt1)mad.f32 r8.z, (r)r24.w, r22.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r24.w, r22.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r24.w, r22.w, (r)(last)r4.z
(rpt1)mad.f32 r23.y, (r)(last)r23.y, r23.x, (r)(last)r18.y
(rpt1)mad.f32 r23.w, (r)(last)r23.w, r23.x, (r)(last)r18.w
isam.v.base0 (u32)(xyzw)r18.y, r29.y, s#0, t#2
(rpt1)mad.f32 r24.y, (r)(last)r24.y, r23.x, (r)(last)r19.y
(rpt1)mad.f32 r24.w, (r)(last)r24.w, r23.x, (r)(last)r19.w
isam.v.base0 (u32)(xyzw)r19.y, r29.z, s#0, t#2
ldl.u32 r22.y, l[r21.x+256], 4
fence.r.w
(sy)(ss)mad.f32 r17.x, r27.y, r25.y, (last)r17.x
mad.f32 r15.x, r27.y, r25.z, (last)r15.x
mad.f32 r13.x, r27.y, r25.w, (last)r13.x
mad.f32 r11.x, r27.y, r26.x, (last)r11.x
mad.f32 r17.y, r27.z, r25.y, (last)r17.y
mad.f32 r15.y, r27.z, r25.z, (last)r15.y
mad.f32 r13.y, r27.z, r25.w, (last)r13.y
mad.f32 r11.y, r27.z, r26.x, (last)r11.y
mad.f32 r17.z, r27.w, r25.y, (last)r17.z
mad.f32 r15.z, r27.w, r25.z, (last)r15.z
mad.f32 r13.z, r27.w, r25.w, (last)r13.z
mad.f32 r11.z, r27.w, r26.x, (last)r11.z
mad.f32 r17.w, r28.x, r25.y, (last)r17.w
mad.f32 r15.w, r28.x, r25.z, (last)r15.w
mad.f32 r13.w, r28.x, r25.w, (last)r13.w
mad.f32 r11.w, r28.x, r26.x, (last)r11.w
mad.f32 r9.x, r27.y, r26.y, (last)r9.x
mad.f32 r7.x, r27.y, r26.z, (last)r7.x
mad.f32 r5.x, r27.y, r26.w, (last)r5.x
mad.f32 r9.y, r27.z, r26.y, (last)r9.y
mad.f32 r7.y, r27.z, r26.z, (last)r7.y
mad.f32 r5.y, r27.z, r26.w, (last)r5.y
mad.f32 r9.z, r27.w, r26.y, (last)r9.z
mad.f32 r7.z, r27.w, r26.z, (last)r7.z
mad.f32 r5.z, r27.w, r26.w, (last)r5.z
mad.f32 r9.w, r28.x, r26.y, (last)r9.w
mad.f32 r7.w, r28.x, r26.z, (last)r7.w
mad.f32 r5.w, r28.x, r26.w, (last)r5.w
mad.f32 r16.x, r28.y, r25.y, (last)r16.x
mad.f32 r14.x, r28.y, r25.z, (last)r14.x
mad.f32 r12.x, r28.y, r25.w, (last)r12.x
mad.f32 r10.x, r28.y, r26.x, (last)r10.x
mad.f32 r16.y, r28.z, r25.y, (last)r16.y
mad.f32 r14.y, r28.z, r25.z, (last)r14.y
mad.f32 r12.y, r28.z, r25.w, (last)r12.y
mad.f32 r10.y, r28.z, r26.x, (last)r10.y
(rpt1)mad.f32 r16.z, (r)r28.w, r25.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r28.w, r25.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r28.w, r25.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r28.w, r26.x, (r)(last)r10.z
mad.f32 r8.x, r28.y, r26.y, (last)r8.x
mad.f32 r6.x, r28.y, r26.z, (last)r6.x
mad.f32 r4.x, r28.y, r26.w, (last)r4.x
mad.f32 r8.y, r28.z, r26.y, (last)r8.y
mad.f32 r6.y, r28.z, r26.z, (last)r6.y
mad.f32 r4.y, r28.z, r26.w, (last)r4.y
(rpt1)mad.f32 r8.z, (r)r28.w, r26.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r28.w, r26.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r28.w, r26.w, (r)(last)r4.z
(rpt1)mad.f32 r27.y, (r)(last)r27.y, r27.x, (r)(last)r23.y
(rpt1)mad.f32 r27.w, (r)(last)r27.w, r27.x, (r)(last)r23.w
isam.v.base0 (u32)(xyzw)r23.y, r29.w, s#0, t#2
(rpt1)mad.f32 r28.y, (r)(last)r28.y, r27.x, (r)(last)r24.y
(rpt1)mad.f32 r28.w, (r)(last)r28.w, r27.x, (r)(last)r24.w
isam.v.base0 (u32)(xyzw)r24.y, r30.x, s#0, t#2
mad.f32 r17.x, r18.y, r30.y, (last)r17.x
mad.f32 r15.x, r18.y, r30.z, (last)r15.x
mad.f32 r13.x, r18.y, r30.w, (last)r13.x
mad.f32 r11.x, r18.y, r31.x, (last)r11.x
mad.f32 r17.y, r18.z, r30.y, (last)r17.y
mad.f32 r15.y, r18.z, r30.z, (last)r15.y
mad.f32 r13.y, r18.z, r30.w, (last)r13.y
mad.f32 r11.y, r18.z, r31.x, (last)r11.y
mad.f32 r17.z, r18.w, r30.y, (last)r17.z
mad.f32 r15.z, r18.w, r30.z, (last)r15.z
mad.f32 r13.z, r18.w, r30.w, (last)r13.z
mad.f32 r11.z, r18.w, r31.x, (last)r11.z
mad.f32 r17.w, r19.x, r30.y, (last)r17.w
mad.f32 r15.w, r19.x, r30.z, (last)r15.w
mad.f32 r13.w, r19.x, r30.w, (last)r13.w
mad.f32 r11.w, r19.x, r31.x, (last)r11.w
mad.f32 r9.x, r18.y, r2.x, (last)r9.x
mad.f32 r7.x, r18.y, r2.y, (last)r7.x
mad.f32 r5.x, r18.y, r2.z, (last)r5.x
mad.f32 r9.y, r18.z, r2.x, (last)r9.y
mad.f32 r7.y, r18.z, r2.y, (last)r7.y
mad.f32 r5.y, r18.z, r2.z, (last)r5.y
mad.f32 r9.z, r18.w, r2.x, (last)r9.z
mad.f32 r7.z, r18.w, r2.y, (last)r7.z
mad.f32 r5.z, r18.w, r2.z, (last)r5.z
mad.f32 r9.w, r19.x, r2.x, (last)r9.w
mad.f32 r7.w, r19.x, r2.y, (last)r7.w
mad.f32 r5.w, r19.x, r2.z, (last)r5.w
mad.f32 r16.x, r19.y, r30.y, (last)r16.x
mad.f32 r14.x, r19.y, r30.z, (last)r14.x
mad.f32 r12.x, r19.y, r30.w, (last)r12.x
mad.f32 r10.x, r19.y, r31.x, (last)r10.x
mad.f32 r16.y, r19.z, r30.y, (last)r16.y
mad.f32 r14.y, r19.z, r30.z, (last)r14.y
mad.f32 r12.y, r19.z, r30.w, (last)r12.y
mad.f32 r10.y, r19.z, r31.x, (last)r10.y
(rpt1)mad.f32 r16.z, (r)r19.w, r30.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r19.w, r30.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r19.w, r30.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r19.w, r31.x, (r)(last)r10.z
mad.f32 r8.x, r19.y, r2.x, (last)r8.x
mad.f32 r6.x, r19.y, r2.y, (last)r6.x
mad.f32 r4.x, r19.y, r2.z, (last)r4.x
mad.f32 r8.y, r19.z, r2.x, (last)r8.y
mad.f32 r6.y, r19.z, r2.y, (last)r6.y
mad.f32 r4.y, r19.z, r2.z, (last)r4.y
(rpt1)mad.f32 r8.z, (r)r19.w, r2.x, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r19.w, r2.y, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r19.w, r2.z, (r)(last)r4.z
(rpt1)mad.f32 r18.y, (r)(last)r18.y, r2.w, (r)(last)r27.y
(rpt1)mad.f32 r18.w, (r)(last)r18.w, r2.w, (r)(last)r27.w
(rpt1)mad.f32 r19.y, (r)(last)r19.y, r2.w, (r)(last)r28.y
(rpt1)mad.f32 r19.w, (r)(last)r19.w, r2.w, (r)(last)r28.w
(sy)mad.f32 r17.x, r23.y, r21.y, (last)r17.x
mad.f32 r15.x, r23.y, r21.z, (last)r15.x
mad.f32 r13.x, r23.y, r21.w, (last)r13.x
mad.f32 r11.x, r23.y, r22.x, (last)r11.x
mad.f32 r17.y, r23.z, r21.y, (last)r17.y
mad.f32 r15.y, r23.z, r21.z, (last)r15.y
mad.f32 r13.y, r23.z, r21.w, (last)r13.y
mad.f32 r11.y, r23.z, r22.x, (last)r11.y
mad.f32 r17.z, r23.w, r21.y, (last)r17.z
mad.f32 r15.z, r23.w, r21.z, (last)r15.z
mad.f32 r13.z, r23.w, r21.w, (last)r13.z
mad.f32 r11.z, r23.w, r22.x, (last)r11.z
mad.f32 r17.w, r24.x, r21.y, (last)r17.w
mad.f32 r15.w, r24.x, r21.z, (last)r15.w
mad.f32 r13.w, r24.x, r21.w, (last)r13.w
mad.f32 r11.w, r24.x, r22.x, (last)r11.w
mad.f32 r9.x, r23.y, r22.y, (last)r9.x
mad.f32 r7.x, r23.y, r22.z, (last)r7.x
mad.f32 r5.x, r23.y, r22.w, (last)r5.x
mad.f32 r9.y, r23.z, r22.y, (last)r9.y
mad.f32 r7.y, r23.z, r22.z, (last)r7.y
mad.f32 r5.y, r23.z, r22.w, (last)r5.y
mad.f32 r9.z, r23.w, r22.y, (last)r9.z
mad.f32 r7.z, r23.w, r22.z, (last)r7.z
mad.f32 r5.z, r23.w, r22.w, (last)r5.z
mad.f32 r9.w, r24.x, r22.y, (last)r9.w
mad.f32 r7.w, r24.x, r22.z, (last)r7.w
mad.f32 r5.w, r24.x, r22.w, (last)r5.w
mad.f32 r16.x, r24.y, r21.y, (last)r16.x
mad.f32 r14.x, r24.y, r21.z, (last)r14.x
mad.f32 r12.x, r24.y, r21.w, (last)r12.x
mad.f32 r10.x, r24.y, r22.x, (last)r10.x
mad.f32 r16.y, r24.z, r21.y, (last)r16.y
mad.f32 r14.y, r24.z, r21.z, (last)r14.y
mad.f32 r12.y, r24.z, r21.w, (last)r12.y
mad.f32 r10.y, r24.z, r22.x, (last)r10.y
(rpt1)mad.f32 r16.z, (r)r24.w, r21.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r24.w, r21.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r24.w, r21.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r24.w, r22.x, (r)(last)r10.z
mad.f32 r8.x, r24.y, r22.y, (last)r8.x
mad.f32 r6.x, r24.y, r22.z, (last)r6.x
mad.f32 r4.x, r24.y, r22.w, (last)r4.x
mad.f32 r8.y, r24.z, r22.y, (last)r8.y
mad.f32 r6.y, r24.z, r22.z, (last)r6.y
mad.f32 r4.y, r24.z, r22.w, (last)r4.y
(rpt1)mad.f32 r8.z, (r)r24.w, r22.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r24.w, r22.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r24.w, r22.w, (r)(last)r4.z
(rpt1)mad.f32 r3.x, (r)(last)r23.y, r23.x, (r)(last)r18.y
(rpt1)mad.f32 r3.z, (r)(last)r23.w, r23.x, (r)(last)r18.w
(rpt1)mad.f32 r25.y, (r)(last)r24.y, r23.x, (r)(last)r19.y
(rpt1)mad.f32 r25.w, (r)(last)r24.w, r23.x, (r)(last)r19.w
bar.g
(sy)(ss)cov.f32f16 hr4.x, r17.x
cov.f32f16 hr5.x, r15.x
cov.f32f16 hr36.x, r13.x
cov.f32f16 hr4.y, r17.y
cov.f32f16 hr5.y, r15.y
cov.f32f16 hr36.y, r13.y
cov.f32f16 hr4.z, r17.z
cov.f32f16 hr5.z, r15.z
cov.f32f16 hr4.w, r17.w
cov.f32f16 hr5.w, r15.w
cov.f32f16 hr40.z, r9.x
cov.f32f16 hr41.z, r7.x
cov.f32f16 hr40.w, r9.y
cov.f32f16 hr41.w, r7.y
cov.f32f16 hr41.x, r9.z
cov.f32f16 hr42.x, r7.z
cov.f32f16 hr41.y, r9.w
cov.f32f16 hr42.y, r7.w
cov.f32f16 hr0.z, r5.w
cov.f32f16 hr42.z, r12.x
cov.f32f16 hr43.x, r14.y
cov.f32f16 hr43.y, r12.y
(rpt1)cov.f32f16 hr43.z, (r)r10.x
cov.f32f16 hr0.w, r10.w
cov.f32f16 hr44.y, r14.z
(rpt1)cov.f32f16 hr44.z, (r)r8.x
cov.f32f16 hr45.x, r14.w
cov.f32f16 hr45.y, r12.z
(rpt1)cov.f32f16 hr45.z, (r)r6.x
(rpt1)cov.f32f16 hr46.z, (r)r5.x
(rpt1)cov.f32f16 hr36.z, (r)r13.z
cov.f32f16 hr47.x, r11.y
cov.f32f16 hr47.y, r11.z
cov.f32f16 hr37.x, r11.x
cov.f32f16 hr37.y, r3.x
cov.f32f16 hr37.w, r3.z
cov.f32f16 hr47.z, r11.w
cov.f32f16 hr47.w, r5.z
cov.f32f16 hr37.z, r3.y
cov.f32f16 hr38.x, r3.w
mov.u32u32 r24.x, (last)r0.x
cov.f32f16 hr38.y, r16.x
cov.f32f16 hr42.w, r25.y
mov.u32u32 r24.y, (last)r0.z
cov.f32f16 hr38.z, r16.y
cov.f32f16 hr38.w, r16.z
cov.f32f16 hr44.x, r25.z
mov.u32u32 r24.z, (last)r0.w
cov.f32f16 hr39.x, r16.w
cov.f32f16 hr39.y, r14.x
(rpt1)cov.f32f16 hr39.z, (r)r4.x
cov.f32f16 hr46.x, r12.w
cov.f32f16 hr46.y, r10.z
(rpt1)cov.f32f16 hr40.x, (r)r8.z
(rpt1)cov.f32f16 hr0.x, (r)r6.z
cov.f32f16 hr1.x, r4.z
cov.f32f16 hr1.y, r25.w
cov.f32f16 hr1.z, r4.w
cov.f32f16 hr1.w, r26.x
br p0.x, #l1196
mov.u32u32 r2.x, (last)r25.y
mov.u32u32 r2.y, (last)r25.z
mov.u32u32 r2.w, (last)r26.x
mov.u32u32 r2.z, (last)r25.w
mov.u32u32 r0.x, (last)r24.x
mov.u32u32 r0.w, (last)r24.z
jump #l138
l1196:
(jp)(eolm)nop
add.u r24.y, r53.y, (last)r24.y
mov.u16u16 hr6.x, (last)hr37.x
mov.u16u16 hr6.y, (last)hr47.x
mov.u16u16 hr6.z, (last)hr47.y
shl.b r24.y, (last)r24.y, 9
mov.u16u16 hr6.w, (last)hr47.z
mov.u16u16 hr8.z, (last)hr43.z
mov.u16u16 hr8.w, (last)hr43.w
sad.s32 r24.y, r54.y, r24.y, (last)r1.w
mov.u16u16 hr9.x, (last)hr46.y
mov.u16u16 hr9.y, (last)hr0.w
mov.u16u16 hr9.z, (last)hr44.z
shl.b r24.y, (last)r24.y, 2
mov.u16u16 hr9.w, (last)hr44.w
mov.u16u16 hr10.x, (last)hr40.x
mov.u16u16 hr10.y, (last)hr40.y
add.u r1.x, r24.y, c1.x
mov.u16u16 hr11.z, (last)hr45.z
mov.u16u16 hr11.w, (last)hr45.w
mov.u16u16 hr12.x, (last)hr0.x
mov.u16u16 hr12.y, (last)hr0.y
mov.u16u16 hr13.z, (last)hr46.z
mov.u16u16 hr13.w, (last)hr46.w
mov.u16u16 hr14.x, (last)hr47.w
mov.u16u16 hr14.y, (last)hr0.z
mov.u16u16 hr14.z, (last)hr39.z
mov.u16u16 hr14.w, (last)hr39.w
mov.u16u16 hr15.x, (last)hr1.x
mov.u16u16 hr15.y, (last)hr1.z
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r24.y, 4
add.u r1.y, r24.y, c9.w
add.u r1.z, r24.y, c5.x
add.u r1.w, r24.y, c9.z
add.u r3.z, r24.y, c3.x
add.u r3.w, r24.y, c9.y
add.u r4.x, r24.y, c10.x
(rpt1)add.u r5.y, (r)c10.y, r24.y
(rpt1)add.u r6.y, (r)c10.w, r24.y
(rpt1)add.u r7.w, (r)c11.y, r24.y
mov.u16u16 hr1.x, (last)hr42.w
mov.u16u16 hr1.z, (last)hr1.y
(ss)mov.u16u16 hr4.x, (last)hr39.y
mov.u16u16 hr4.y, (last)hr43.x
mov.u16u16 hr4.z, (last)hr44.y
mov.u16u16 hr4.w, (last)hr45.x
stib.b.untyped.1d.u16.4.imm.base0 hr38.y, r24.y+64, 4
mov.u16u16 hr1.y, (last)hr44.x
(ss)add.u r24.y, c11.w, (last)r24.y
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r1.x, 4
(ss)mov.u16u16 hr5.x, (last)hr42.z
mov.u16u16 hr5.y, (last)hr43.y
mov.u16u16 hr5.z, (last)hr45.y
mov.u16u16 hr5.w, (last)hr46.x
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r1.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr36.x, r1.z, 4
(rpt5)nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r1.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr6.x, r3.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r3.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr40.z, r4.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r5.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr41.z, r5.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r6.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r6.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r7.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr37.y, r8.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr1.x, r24.y, 4
end
nop
nop
nop
nop
nop
nop
nop
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
; CL prog 23/1: 1395 instr, 16 nops, 1379 non-nops, 112 mov, 64 cov, 2560 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 32 full, 12 constlen
; CL prog 23/1: 19 cat0, 176 cat1, 84 cat2, 1028 cat3, 0 cat4, 34 cat5, 50 cat6, 4 cat7
; CL prog 23/1: 58 sstall, 24 (ss), 427 systall, 21 (sy), 1 loops
; CL prog 23/1: 8 max_waves, 0 double_threadsize
; 65 preamble-instr, 1 early-preamble
