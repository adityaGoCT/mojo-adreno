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
@const(c1.x)	0x00000800, 0x00007800, 0x00007000, 0x00006800
@const(c2.x)	0x00006000, 0x00005800, 0x00005000, 0x00004800
@const(c3.x)	0x00004000, 0x00003800, 0x00003000, 0x00002800
@const(c4.x)	0x00002000, 0x00001800, 0x00001000, 0x00007840
@const(c5.x)	0x00007040, 0x00006840, 0x00006040, 0x00005840
@const(c6.x)	0x00005040, 0x00004840, 0x00004040, 0x00003840
@const(c7.x)	0x00003040, 0x00002840, 0x00002040, 0x00001840
@const(c8.x)	0x00001040, 0x00000840, 0x00010000, 0x00010040
@const(c9.x)	0x00010800, 0x00010840, 0x00011000, 0x00011040
@const(c10.x)	0x00011800, 0x00011840, 0xd0d0d0d0, 0xd0d0d0d0
shps #l58
getone #l58
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 0x7800
mov.u32u32 r49.y, 0x7000
mov.u32u32 r49.z, 0x6800
mov.u32u32 r49.w, 0x6000
mov.u32u32 r50.x, 0x5800
mov.u32u32 r50.y, 0x5000
mov.u32u32 r50.z, 0x4800
mov.u32u32 r50.w, 0x4000
mov.u32u32 r51.x, 0x3800
mov.u32u32 r51.y, 0x3000
mov.u32u32 r51.z, 0x2800
mov.u32u32 r51.w, 0x2000
mov.u32u32 r52.x, 0x1800
mov.u32u32 r52.y, 4096
mov.u32u32 r52.z, 0x7840
mov.u32u32 r52.w, 0x7040
mov.u32u32 r53.x, 0x6840
mov.u32u32 r53.y, 0x6040
mov.u32u32 r53.z, 0x5840
mov.u32u32 r53.w, 0x5040
mov.u32u32 r54.x, 0x4840
mov.u32u32 r54.y, 0x4040
mov.u32u32 r54.z, 0x3840
mov.u32u32 r54.w, 0x3040
mov.u32u32 r55.x, 0x2840
mov.u32u32 r55.y, 0x2040
mov.u32u32 r55.z, 0x1840
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
(ss)mov.u32u32 r48.w, 0x1040
mov.u32u32 r49.x, 2112
mov.u32u32 r49.y, 0x10000
mov.u32u32 r49.z, 0x10040
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 4
stc.u32 c[20], r52.w, 4
stc.u32 c[24], r53.w, 4
stc.u32 c[28], r54.w, 4
(ss)mov.u32u32 r49.w, 0x10800
mov.u32u32 r50.x, 0x10840
mov.u32u32 r50.y, 0x11000
mov.u32u32 r50.z, 0x11040
mov.u32u32 r50.w, 0x11800
mov.u32u32 r51.x, 0x11840
stc.u32 c[32], r48.w, 4
(ss)nop
stc.u32 c[36], r49.w, 4
stc.u32 c[40], r50.w, 2
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l58:
(jp)(rpt1)add.u r51.y, (r)r48.x, (r)c0.x
mov.u32u32 r52.y, 0
shl.b r52.x, r51.y, 7
shl.b r51.w, r51.z, 6
shr.b r0.w, r0.x, 4
and.b r1.x, r0.x, 15
and.b r1.y, r0.x, -16
mov.u32u32 r1.z, 0
mov.u32u32 r1.w, 0
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
mov.u32u32 r2.y, 0
mov.u32u32 r2.x, 0
l129:
(rpt1)shr.b r52.z, (r)r51.w, 2
shl.b r53.x, r52.y, 9
add.u r18.x, r0.x, 128
shl.b r17.z, r0.w, 8
shl.b r17.w, r1.x, 4
shl.b r18.y, r0.w, 2
shr.b r18.x, (last)r18.x, 4
(ss)add.u r18.w, r52.y, r0.w
sad.s32 r21.x, r53.x, r1.x, r52.w
add.u r17.z, (last)r17.z, r17.w
shl.b r18.z, r18.x, 8
add.u r18.x, r52.y, (last)r18.x
add.u r52.y, r52.y, 16
cmps.u.ge up0.x, r52.y, c1.x
shl.b r18.w, (last)r18.w, 9
shl.b r21.x, (last)r21.x, 2
add.u r18.z, (last)r18.z, (last)r17.w
shl.b r18.x, (last)r18.x, 9
sad.s32 r18.w, r52.z, r18.w, r1.x
add.u r21.y, r21.x, c1.x
add.u r21.z, r21.x, c8.y
sad.s32 r18.x, r52.z, r18.x, r1.x
shl.b r18.w, (last)r18.w, 2
add.u r21.w, r21.x, c4.z
add.u r22.x, c8.x, r21.x
shl.b r18.x, (last)r18.x, 2
add.u r22.y, c4.y, r21.x
add.u r22.z, c7.w, r21.x
add.u r22.w, c4.x, r21.x
isam.v.base0 (u32)(xyzw)r19.x, r18.w, s#0, t#0
add.u r23.x, c7.z, r21.x
add.u r23.y, c3.w, r21.x
add.u r23.z, c7.y, r21.x
isam.v.base0 (u32)(xyzw)r20.x, r18.x, s#0, t#0
add.u r23.w, c3.z, r21.x
add.u r24.x, c7.x, r21.x
add.u r24.y, c3.y, r21.x
add.u r24.z, c6.w, r21.x
add.u r24.w, c3.x, r21.x
add.u r25.x, c6.z, r21.x
add.u r25.y, c2.w, r21.x
add.u r25.z, c6.y, r21.x
add.u r25.w, c2.z, r21.x
add.u r26.x, c6.x, r21.x
add.u r26.y, c2.y, r21.x
add.u r26.z, c5.w, r21.x
add.u r26.w, c2.x, r21.x
add.u r27.x, c5.z, r21.x
add.u r27.y, c1.w, r21.x
add.u r27.z, c5.y, r21.x
add.u r27.w, c1.z, r21.x
add.u r28.x, c5.x, r21.x
add.u r28.y, c1.y, r21.x
add.u r28.z, c4.w, r21.x
(sy)stl.u32 l[r17.z], r19.x, 4
stl.u32 l[r18.z], r20.x, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
isam.v.base0 (u32)(xyzw)r29.w, r21.x, s#0, t#2
isam.v.base0 (u32)(xyzw)r18.z, r21.x+64, s#0, t#2
ldl.u32 r28.w, l[r1.y], 4
ldl.u32 r30.w, l[r1.y+128], 4
ldl.u32 r19.z, l[r1.y+256], 4
(sy)(ss)mad.f32 r16.z, r29.w, r28.w, (last)r16.z
mad.f32 r14.z, r29.w, r29.x, (last)r14.z
mad.f32 r12.z, r29.w, r29.y, (last)r12.z
mad.f32 r10.z, r29.w, r29.z, (last)r10.z
mad.f32 r16.w, r30.x, r28.w, (last)r16.w
mad.f32 r14.w, r30.x, r29.x, (last)r14.w
mad.f32 r12.w, r30.x, r29.y, (last)r12.w
mad.f32 r10.w, r30.x, r29.z, (last)r10.w
mad.f32 r17.x, r30.y, r28.w, (last)r17.x
mad.f32 r15.x, r30.y, r29.x, (last)r15.x
mad.f32 r13.x, r30.y, r29.y, (last)r13.x
mad.f32 r11.x, r30.y, r29.z, (last)r11.x
mad.f32 r17.y, r30.z, r28.w, (last)r17.y
mad.f32 r15.y, r30.z, r29.x, (last)r15.y
mad.f32 r13.y, r30.z, r29.y, (last)r13.y
mad.f32 r11.y, r30.z, r29.z, (last)r11.y
mad.f32 r15.z, r18.z, r28.w, (last)r15.z
mad.f32 r13.z, r18.z, r29.x, (last)r13.z
mad.f32 r11.z, r18.z, r29.y, (last)r11.z
mad.f32 r9.z, r18.z, r29.z, (last)r9.z
mad.f32 r15.w, r18.w, r28.w, (last)r15.w
mad.f32 r13.w, r18.w, r29.x, (last)r13.w
mad.f32 r11.w, r18.w, r29.y, (last)r11.w
mad.f32 r9.w, r18.w, r29.z, (last)r9.w
(rpt1)mad.f32 r16.x, (r)r19.x, r28.w, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r19.x, r29.x, (r)(last)r14.x
(rpt1)mad.f32 r12.x, (r)r19.x, r29.y, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r19.x, r29.z, (r)(last)r10.x
ldl.u32 r28.w, l[r1.y+384], 4
(rpt1)mad.f32 r8.z, (r)r29.w, r30.w, (r)(last)r8.z
(rpt1)mad.f32 r9.x, (r)r30.y, r30.w, (r)(last)r9.x
(rpt1)mad.f32 r6.z, (r)r29.w, r31.x, (r)(last)r6.z
(rpt1)mad.f32 r7.x, (r)r30.y, r31.x, (r)(last)r7.x
(rpt1)mad.f32 r4.z, (r)r29.w, r31.y, (r)(last)r4.z
(rpt1)mad.f32 r5.x, (r)r30.y, r31.y, (r)(last)r5.x
mad.f32 r7.z, r18.z, r30.w, (last)r7.z
mad.f32 r5.z, r18.z, r31.x, (last)r5.z
mad.f32 r3.z, r18.z, r31.y, (last)r3.z
mad.f32 r7.w, r18.w, r30.w, (last)r7.w
mad.f32 r5.w, r18.w, r31.x, (last)r5.w
mad.f32 r3.w, r18.w, r31.y, (last)r3.w
(rpt1)mad.f32 r8.x, (r)r19.x, r30.w, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r19.x, r31.x, (r)(last)r6.x
(rpt1)mad.f32 r4.x, (r)r19.x, r31.y, (r)(last)r4.x
(rpt1)mad.f32 r29.w, (r)(last)r29.w, r31.z, (r)(last)r2.z
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r31.z, (r)(last)r3.x
ldl.u32 r2.z, l[r1.y+512], 4
(rpt1)mad.f32 r18.z, (r)(last)r18.z, r31.z, (r)(last)r1.z
(rpt1)mad.f32 r19.x, (r)(last)r19.x, r31.z, (r)(last)r2.x
isam.v.base0 (u32)(xyzw)r30.w, r21.y, s#0, t#2
isam.v.base0 (u32)(xyzw)r1.z, r21.z, s#0, t#2
(sy)mad.f32 r16.z, r30.w, r19.z, (last)r16.z
mad.f32 r14.z, r30.w, r19.w, (last)r14.z
mad.f32 r12.z, r30.w, r20.x, (last)r12.z
mad.f32 r10.z, r30.w, r20.y, (last)r10.z
mad.f32 r16.w, r31.x, r19.z, (last)r16.w
mad.f32 r14.w, r31.x, r19.w, (last)r14.w
mad.f32 r12.w, r31.x, r20.x, (last)r12.w
mad.f32 r10.w, r31.x, r20.y, (last)r10.w
mad.f32 r17.x, r31.y, r19.z, (last)r17.x
mad.f32 r15.x, r31.y, r19.w, (last)r15.x
mad.f32 r13.x, r31.y, r20.x, (last)r13.x
mad.f32 r11.x, r31.y, r20.y, (last)r11.x
mad.f32 r17.y, r31.z, r19.z, (last)r17.y
mad.f32 r15.y, r31.z, r19.w, (last)r15.y
mad.f32 r13.y, r31.z, r20.x, (last)r13.y
mad.f32 r11.y, r31.z, r20.y, (last)r11.y
mad.f32 r15.z, r1.z, r19.z, (last)r15.z
mad.f32 r13.z, r1.z, r19.w, (last)r13.z
mad.f32 r11.z, r1.z, r20.x, (last)r11.z
mad.f32 r9.z, r1.z, r20.y, (last)r9.z
mad.f32 r15.w, r1.w, r19.z, (last)r15.w
mad.f32 r13.w, r1.w, r19.w, (last)r13.w
mad.f32 r11.w, r1.w, r20.x, (last)r11.w
mad.f32 r9.w, r1.w, r20.y, (last)r9.w
(rpt1)mad.f32 r16.x, (r)r2.x, r19.z, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r2.x, r19.w, (r)(last)r14.x
(rpt1)mad.f32 r12.x, (r)r2.x, r20.x, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r2.x, r20.y, (r)(last)r10.x
isam.v.base0 (u32)(xyzw)r19.z, r21.w, s#0, t#2
isam.v.base0 (u32)(xyzw)r20.z, r22.x, s#0, t#2
(ss)mad.f32 r7.z, r1.z, r28.w, (last)r7.z
mad.f32 r5.z, r1.z, r29.x, (last)r5.z
mad.f32 r3.z, r1.z, r29.y, (last)r3.z
mad.f32 r7.w, r1.w, r28.w, (last)r7.w
mad.f32 r5.w, r1.w, r29.x, (last)r5.w
mad.f32 r3.w, r1.w, r29.y, (last)r3.w
(rpt1)mad.f32 r8.x, (r)r2.x, r28.w, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r2.x, r29.x, (r)(last)r6.x
(rpt1)mad.f32 r4.x, (r)r2.x, r29.y, (r)(last)r4.x
(rpt1)mad.f32 r1.z, (r)(last)r1.z, r29.z, (r)(last)r18.z
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r29.z, (r)(last)r19.x
ldl.u32 r18.z, l[r1.y+640], 4
mad.f32 r8.z, r30.w, r28.w, (last)r8.z
mad.f32 r6.z, r30.w, r29.x, (last)r6.z
mad.f32 r4.z, r30.w, r29.y, (last)r4.z
mad.f32 r8.w, r31.x, r28.w, (last)r8.w
mad.f32 r6.w, r31.x, r29.x, (last)r6.w
mad.f32 r4.w, r31.x, r29.y, (last)r4.w
mad.f32 r9.x, r31.y, r28.w, (last)r9.x
mad.f32 r7.x, r31.y, r29.x, (last)r7.x
mad.f32 r5.x, r31.y, r29.y, (last)r5.x
mad.f32 r9.y, r31.z, r28.w, (last)r9.y
mad.f32 r7.y, r31.z, r29.x, (last)r7.y
mad.f32 r5.y, r31.z, r29.y, (last)r5.y
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r29.z, (r)(last)r29.w
(rpt1)mad.f32 r31.y, (r)(last)r31.y, r29.z, (r)(last)r30.y
ldl.u32 r28.w, l[r1.y+768], 4
ldl.u32 r29.w, l[r1.y+896], 4
(sy)mad.f32 r16.z, r19.z, r2.z, (last)r16.z
mad.f32 r14.z, r19.z, r2.w, (last)r14.z
mad.f32 r12.z, r19.z, r3.x, (last)r12.z
mad.f32 r10.z, r19.z, r3.y, (last)r10.z
mad.f32 r16.w, r19.w, r2.z, (last)r16.w
mad.f32 r14.w, r19.w, r2.w, (last)r14.w
mad.f32 r12.w, r19.w, r3.x, (last)r12.w
mad.f32 r10.w, r19.w, r3.y, (last)r10.w
mad.f32 r17.x, r20.x, r2.z, (last)r17.x
mad.f32 r15.x, r20.x, r2.w, (last)r15.x
mad.f32 r13.x, r20.x, r3.x, (last)r13.x
mad.f32 r11.x, r20.x, r3.y, (last)r11.x
mad.f32 r17.y, r20.y, r2.z, (last)r17.y
mad.f32 r15.y, r20.y, r2.w, (last)r15.y
mad.f32 r13.y, r20.y, r3.x, (last)r13.y
mad.f32 r11.y, r20.y, r3.y, (last)r11.y
(ss)mad.f32 r8.z, r19.z, r18.z, (last)r8.z
mad.f32 r6.z, r19.z, r18.w, (last)r6.z
mad.f32 r4.z, r19.z, r19.x, (last)r4.z
mad.f32 r8.w, r19.w, r18.z, (last)r8.w
mad.f32 r6.w, r19.w, r18.w, (last)r6.w
mad.f32 r4.w, r19.w, r19.x, (last)r4.w
mad.f32 r9.x, r20.x, r18.z, (last)r9.x
mad.f32 r7.x, r20.x, r18.w, (last)r7.x
mad.f32 r5.x, r20.x, r19.x, (last)r5.x
mad.f32 r9.y, r20.y, r18.z, (last)r9.y
mad.f32 r7.y, r20.y, r18.w, (last)r7.y
mad.f32 r5.y, r20.y, r19.x, (last)r5.y
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r19.y, (r)(last)r30.w
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r19.y, (r)(last)r31.y
isam.v.base0 (u32)(xyzw)r30.w, r22.y, s#0, t#2
mad.f32 r15.z, r20.z, r2.z, (last)r15.z
mad.f32 r13.z, r20.z, r2.w, (last)r13.z
mad.f32 r11.z, r20.z, r3.x, (last)r11.z
mad.f32 r9.z, r20.z, r3.y, (last)r9.z
mad.f32 r15.w, r20.w, r2.z, (last)r15.w
mad.f32 r13.w, r20.w, r2.w, (last)r13.w
mad.f32 r11.w, r20.w, r3.x, (last)r11.w
mad.f32 r9.w, r20.w, r3.y, (last)r9.w
(rpt1)mad.f32 r16.x, (r)r21.x, r2.z, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r21.x, r2.w, (r)(last)r14.x
(rpt1)mad.f32 r12.x, (r)r21.x, r3.x, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r21.x, r3.y, (r)(last)r10.x
ldl.u32 r2.z, l[r1.y+1024], 4
mad.f32 r7.z, r20.z, r18.z, (last)r7.z
mad.f32 r5.z, r20.z, r18.w, (last)r5.z
mad.f32 r3.z, r20.z, r19.x, (last)r3.z
mad.f32 r7.w, r20.w, r18.z, (last)r7.w
mad.f32 r5.w, r20.w, r18.w, (last)r5.w
mad.f32 r3.w, r20.w, r19.x, (last)r3.w
(rpt1)mad.f32 r8.x, (r)r21.x, r18.z, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r21.x, r18.w, (r)(last)r6.x
(rpt1)mad.f32 r4.x, (r)r21.x, r19.x, (r)(last)r4.x
(rpt1)mad.f32 r20.z, (r)(last)r20.z, r19.y, (r)(last)r1.z
(rpt1)mad.f32 r21.x, (r)(last)r21.x, r19.y, (r)(last)r2.x
isam.v.base0 (u32)(xyzw)r1.z, r22.z, s#0, t#2
ldl.u32 r18.z, l[r1.y+1152], 4
(sy)mad.f32 r16.z, r30.w, r28.w, (last)r16.z
ldl.u32 r21.z, l[r1.y+1280], 4
mad.f32 r14.z, r30.w, r29.x, (last)r14.z
mad.f32 r12.z, r30.w, r29.y, (last)r12.z
mad.f32 r10.z, r30.w, r29.z, (last)r10.z
mad.f32 r8.z, r30.w, r29.w, (last)r8.z
mad.f32 r6.z, r30.w, r30.x, (last)r6.z
mad.f32 r4.z, r30.w, r30.y, (last)r4.z
mad.f32 r16.w, r31.x, r28.w, (last)r16.w
mad.f32 r14.w, r31.x, r29.x, (last)r14.w
mad.f32 r12.w, r31.x, r29.y, (last)r12.w
mad.f32 r10.w, r31.x, r29.z, (last)r10.w
mad.f32 r8.w, r31.x, r29.w, (last)r8.w
mad.f32 r6.w, r31.x, r30.x, (last)r6.w
mad.f32 r4.w, r31.x, r30.y, (last)r4.w
mad.f32 r17.x, r31.y, r28.w, (last)r17.x
mad.f32 r15.x, r31.y, r29.x, (last)r15.x
mad.f32 r13.x, r31.y, r29.y, (last)r13.x
mad.f32 r11.x, r31.y, r29.z, (last)r11.x
mad.f32 r9.x, r31.y, r29.w, (last)r9.x
mad.f32 r7.x, r31.y, r30.x, (last)r7.x
mad.f32 r5.x, r31.y, r30.y, (last)r5.x
mad.f32 r17.y, r31.z, r28.w, (last)r17.y
mad.f32 r15.y, r31.z, r29.x, (last)r15.y
mad.f32 r13.y, r31.z, r29.y, (last)r13.y
mad.f32 r11.y, r31.z, r29.z, (last)r11.y
mad.f32 r9.y, r31.z, r29.w, (last)r9.y
mad.f32 r7.y, r31.z, r30.x, (last)r7.y
mad.f32 r5.y, r31.z, r30.y, (last)r5.y
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r30.z, (r)(last)r19.z
(rpt1)mad.f32 r31.y, (r)(last)r31.y, r30.z, (r)(last)r20.x
isam.v.base0 (u32)(xyzw)r19.z, r22.w, s#0, t#2
mad.f32 r15.z, r1.z, r28.w, (last)r15.z
mad.f32 r13.z, r1.z, r29.x, (last)r13.z
mad.f32 r11.z, r1.z, r29.y, (last)r11.z
mad.f32 r9.z, r1.z, r29.z, (last)r9.z
mad.f32 r7.z, r1.z, r29.w, (last)r7.z
mad.f32 r5.z, r1.z, r30.x, (last)r5.z
mad.f32 r3.z, r1.z, r30.y, (last)r3.z
mad.f32 r15.w, r1.w, r28.w, (last)r15.w
mad.f32 r13.w, r1.w, r29.x, (last)r13.w
mad.f32 r11.w, r1.w, r29.y, (last)r11.w
mad.f32 r9.w, r1.w, r29.z, (last)r9.w
mad.f32 r7.w, r1.w, r29.w, (last)r7.w
mad.f32 r5.w, r1.w, r30.x, (last)r5.w
mad.f32 r3.w, r1.w, r30.y, (last)r3.w
(rpt1)mad.f32 r16.x, (r)r2.x, r28.w, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r2.x, r29.x, (r)(last)r14.x
(rpt1)mad.f32 r12.x, (r)r2.x, r29.y, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r2.x, r29.z, (r)(last)r10.x
ldl.u32 r28.w, l[r1.y+1408], 4
(rpt1)mad.f32 r8.x, (r)r2.x, r29.w, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r2.x, r30.x, (r)(last)r6.x
(rpt1)mad.f32 r4.x, (r)r2.x, r30.y, (r)(last)r4.x
(rpt1)mad.f32 r1.z, (r)(last)r1.z, r30.z, (r)(last)r20.z
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r30.z, (r)(last)r21.x
isam.v.base0 (u32)(xyzw)r20.z, r23.x, s#0, t#2
isam.v.base0 (u32)(xyzw)r29.w, r23.y, s#0, t#2
(sy)(ss)mad.f32 r16.z, r19.z, r2.z, (last)r16.z
mad.f32 r14.z, r19.z, r2.w, (last)r14.z
mad.f32 r12.z, r19.z, r3.x, (last)r12.z
mad.f32 r10.z, r19.z, r3.y, (last)r10.z
mad.f32 r8.z, r19.z, r18.z, (last)r8.z
mad.f32 r6.z, r19.z, r18.w, (last)r6.z
mad.f32 r4.z, r19.z, r19.x, (last)r4.z
mad.f32 r16.w, r19.w, r2.z, (last)r16.w
mad.f32 r14.w, r19.w, r2.w, (last)r14.w
mad.f32 r12.w, r19.w, r3.x, (last)r12.w
mad.f32 r10.w, r19.w, r3.y, (last)r10.w
mad.f32 r8.w, r19.w, r18.z, (last)r8.w
mad.f32 r6.w, r19.w, r18.w, (last)r6.w
mad.f32 r4.w, r19.w, r19.x, (last)r4.w
mad.f32 r17.x, r20.x, r2.z, (last)r17.x
mad.f32 r15.x, r20.x, r2.w, (last)r15.x
mad.f32 r13.x, r20.x, r3.x, (last)r13.x
mad.f32 r11.x, r20.x, r3.y, (last)r11.x
mad.f32 r9.x, r20.x, r18.z, (last)r9.x
mad.f32 r7.x, r20.x, r18.w, (last)r7.x
mad.f32 r5.x, r20.x, r19.x, (last)r5.x
mad.f32 r17.y, r20.y, r2.z, (last)r17.y
mad.f32 r15.y, r20.y, r2.w, (last)r15.y
mad.f32 r13.y, r20.y, r3.x, (last)r13.y
mad.f32 r11.y, r20.y, r3.y, (last)r11.y
mad.f32 r9.y, r20.y, r18.z, (last)r9.y
mad.f32 r7.y, r20.y, r18.w, (last)r7.y
mad.f32 r5.y, r20.y, r19.x, (last)r5.y
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r19.y, (r)(last)r30.w
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r19.y, (r)(last)r31.y
isam.v.base0 (u32)(xyzw)r30.w, r23.z, s#0, t#2
mad.f32 r15.z, r20.z, r2.z, (last)r15.z
mad.f32 r13.z, r20.z, r2.w, (last)r13.z
mad.f32 r11.z, r20.z, r3.x, (last)r11.z
mad.f32 r9.z, r20.z, r3.y, (last)r9.z
mad.f32 r7.z, r20.z, r18.z, (last)r7.z
mad.f32 r5.z, r20.z, r18.w, (last)r5.z
mad.f32 r3.z, r20.z, r19.x, (last)r3.z
mad.f32 r15.w, r20.w, r2.z, (last)r15.w
mad.f32 r13.w, r20.w, r2.w, (last)r13.w
mad.f32 r11.w, r20.w, r3.x, (last)r11.w
mad.f32 r9.w, r20.w, r3.y, (last)r9.w
mad.f32 r7.w, r20.w, r18.z, (last)r7.w
mad.f32 r5.w, r20.w, r18.w, (last)r5.w
mad.f32 r3.w, r20.w, r19.x, (last)r3.w
(rpt1)mad.f32 r16.x, (r)r21.x, r2.z, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r21.x, r2.w, (r)(last)r14.x
(rpt1)mad.f32 r12.x, (r)r21.x, r3.x, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r21.x, r3.y, (r)(last)r10.x
(rpt1)mad.f32 r8.x, (r)r21.x, r18.z, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r21.x, r18.w, (r)(last)r6.x
(rpt1)mad.f32 r4.x, (r)r21.x, r19.x, (r)(last)r4.x
mad.f32 r16.z, r29.w, r21.z, (last)r16.z
mad.f32 r14.z, r29.w, r21.w, (last)r14.z
mad.f32 r12.z, r29.w, r22.x, (last)r12.z
mad.f32 r10.z, r29.w, r22.y, (last)r10.z
mad.f32 r8.z, r29.w, r28.w, (last)r8.z
mad.f32 r6.z, r29.w, r29.x, (last)r6.z
mad.f32 r4.z, r29.w, r29.y, (last)r4.z
mad.f32 r16.w, r30.x, r21.z, (last)r16.w
mad.f32 r14.w, r30.x, r21.w, (last)r14.w
mad.f32 r12.w, r30.x, r22.x, (last)r12.w
mad.f32 r10.w, r30.x, r22.y, (last)r10.w
mad.f32 r8.w, r30.x, r28.w, (last)r8.w
mad.f32 r6.w, r30.x, r29.x, (last)r6.w
mad.f32 r4.w, r30.x, r29.y, (last)r4.w
mad.f32 r17.x, r30.y, r21.z, (last)r17.x
mad.f32 r15.x, r30.y, r21.w, (last)r15.x
mad.f32 r13.x, r30.y, r22.x, (last)r13.x
mad.f32 r11.x, r30.y, r22.y, (last)r11.x
mad.f32 r9.x, r30.y, r28.w, (last)r9.x
mad.f32 r7.x, r30.y, r29.x, (last)r7.x
mad.f32 r5.x, r30.y, r29.y, (last)r5.x
mad.f32 r17.y, r30.z, r21.z, (last)r17.y
mad.f32 r15.y, r30.z, r21.w, (last)r15.y
mad.f32 r13.y, r30.z, r22.x, (last)r13.y
mad.f32 r11.y, r30.z, r22.y, (last)r11.y
mad.f32 r9.y, r30.z, r28.w, (last)r9.y
mad.f32 r7.y, r30.z, r29.x, (last)r7.y
mad.f32 r5.y, r30.z, r29.y, (last)r5.y
(rpt1)mad.f32 r20.z, (r)(last)r20.z, r19.y, (r)(last)r1.z
(rpt1)mad.f32 r21.x, (r)(last)r21.x, r19.y, (r)(last)r2.x
isam.v.base0 (u32)(xyzw)r18.z, r23.w, s#0, t#2
ldl.u32 r1.z, l[r1.y+1536], 4
ldl.u32 r2.z, l[r1.y+1664], 4
(rpt1)mad.f32 r29.w, (r)(last)r29.w, r29.z, (r)(last)r19.z
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r29.z, (r)(last)r20.x
isam.v.base0 (u32)(xyzw)r19.z, r24.x, s#0, t#2
isam.v.base0 (u32)(xyzw)r22.z, r24.y, s#0, t#2
(ss)nop
isam.v.base0 (u32)(xyzw)r23.z, r24.z, s#0, t#2
(sy)mad.f32 r15.z, r30.w, r21.z, (last)r15.z
mad.f32 r13.z, r30.w, r21.w, (last)r13.z
mad.f32 r11.z, r30.w, r22.x, (last)r11.z
mad.f32 r9.z, r30.w, r22.y, (last)r9.z
mad.f32 r7.z, r30.w, r28.w, (last)r7.z
mad.f32 r5.z, r30.w, r29.x, (last)r5.z
mad.f32 r3.z, r30.w, r29.y, (last)r3.z
mad.f32 r15.w, r31.x, r21.z, (last)r15.w
mad.f32 r13.w, r31.x, r21.w, (last)r13.w
mad.f32 r11.w, r31.x, r22.x, (last)r11.w
mad.f32 r9.w, r31.x, r22.y, (last)r9.w
mad.f32 r7.w, r31.x, r28.w, (last)r7.w
mad.f32 r5.w, r31.x, r29.x, (last)r5.w
mad.f32 r3.w, r31.x, r29.y, (last)r3.w
(rpt1)mad.f32 r16.x, (r)r31.y, r21.z, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r31.y, r21.w, (r)(last)r14.x
(rpt1)mad.f32 r12.x, (r)r31.y, r22.x, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r31.y, r22.y, (r)(last)r10.x
(rpt1)mad.f32 r8.x, (r)r31.y, r28.w, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r31.y, r29.x, (r)(last)r6.x
(rpt1)mad.f32 r4.x, (r)r31.y, r29.y, (r)(last)r4.x
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r29.z, (r)(last)r20.z
(rpt1)mad.f32 r31.y, (r)(last)r31.y, r29.z, (r)(last)r21.x
ldl.u32 r20.z, l[r1.y+1792], 4
ldl.u32 r21.z, l[r1.y+1920], 4
ldl.u32 r28.w, l[r1.y+2048], 4
mad.f32 r16.z, r18.z, r1.z, (last)r16.z
mad.f32 r14.z, r18.z, r1.w, (last)r14.z
mad.f32 r12.z, r18.z, r2.x, (last)r12.z
mad.f32 r10.z, r18.z, r2.y, (last)r10.z
mad.f32 r16.w, r18.w, r1.z, (last)r16.w
mad.f32 r14.w, r18.w, r1.w, (last)r14.w
mad.f32 r12.w, r18.w, r2.x, (last)r12.w
mad.f32 r10.w, r18.w, r2.y, (last)r10.w
mad.f32 r17.x, r19.x, r1.z, (last)r17.x
mad.f32 r15.x, r19.x, r1.w, (last)r15.x
mad.f32 r13.x, r19.x, r2.x, (last)r13.x
mad.f32 r11.x, r19.x, r2.y, (last)r11.x
mad.f32 r17.y, r19.y, r1.z, (last)r17.y
mad.f32 r15.y, r19.y, r1.w, (last)r15.y
mad.f32 r13.y, r19.y, r2.x, (last)r13.y
mad.f32 r11.y, r19.y, r2.y, (last)r11.y
mad.f32 r15.z, r19.z, r1.z, (last)r15.z
mad.f32 r13.z, r19.z, r1.w, (last)r13.z
mad.f32 r11.z, r19.z, r2.x, (last)r11.z
mad.f32 r9.z, r19.z, r2.y, (last)r9.z
mad.f32 r7.z, r19.z, r2.z, (last)r7.z
mad.f32 r5.z, r19.z, r2.w, (last)r5.z
mad.f32 r3.z, r19.z, r3.x, (last)r3.z
mad.f32 r15.w, r19.w, r1.z, (last)r15.w
mad.f32 r13.w, r19.w, r1.w, (last)r13.w
mad.f32 r11.w, r19.w, r2.x, (last)r11.w
mad.f32 r9.w, r19.w, r2.y, (last)r9.w
mad.f32 r7.w, r19.w, r2.z, (last)r7.w
mad.f32 r5.w, r19.w, r2.w, (last)r5.w
mad.f32 r3.w, r19.w, r3.x, (last)r3.w
(rpt1)mad.f32 r16.x, (r)r20.x, r1.z, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r20.x, r1.w, (r)(last)r14.x
(rpt1)mad.f32 r12.x, (r)r20.x, r2.x, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r20.x, r2.y, (r)(last)r10.x
(rpt1)mad.f32 r8.x, (r)r20.x, r2.z, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r20.x, r2.w, (r)(last)r6.x
(rpt1)mad.f32 r4.x, (r)r20.x, r3.x, (r)(last)r4.x
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r3.y, (r)(last)r30.w
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r3.y, (r)(last)r31.y
isam.v.base0 (u32)(xyzw)r30.w, r24.w, s#0, t#2
isam.v.base0 (u32)(xyzw)r1.z, r25.x, s#0, t#2
(ss)mad.f32 r16.z, r22.z, r20.z, (last)r16.z
mad.f32 r14.z, r22.z, r20.w, (last)r14.z
mad.f32 r12.z, r22.z, r21.x, (last)r12.z
mad.f32 r10.z, r22.z, r21.y, (last)r10.z
mad.f32 r16.w, r22.w, r20.z, (last)r16.w
mad.f32 r14.w, r22.w, r20.w, (last)r14.w
mad.f32 r12.w, r22.w, r21.x, (last)r12.w
mad.f32 r10.w, r22.w, r21.y, (last)r10.w
mad.f32 r17.x, r23.x, r20.z, (last)r17.x
mad.f32 r15.x, r23.x, r20.w, (last)r15.x
mad.f32 r13.x, r23.x, r21.x, (last)r13.x
mad.f32 r11.x, r23.x, r21.y, (last)r11.x
mad.f32 r17.y, r23.y, r20.z, (last)r17.y
mad.f32 r15.y, r23.y, r20.w, (last)r15.y
mad.f32 r13.y, r23.y, r21.x, (last)r13.y
mad.f32 r11.y, r23.y, r21.y, (last)r11.y
mad.f32 r15.z, r23.z, r20.z, (last)r15.z
mad.f32 r13.z, r23.z, r20.w, (last)r13.z
mad.f32 r11.z, r23.z, r21.x, (last)r11.z
mad.f32 r9.z, r23.z, r21.y, (last)r9.z
mad.f32 r7.z, r23.z, r21.z, (last)r7.z
mad.f32 r5.z, r23.z, r21.w, (last)r5.z
mad.f32 r3.z, r23.z, r22.x, (last)r3.z
mad.f32 r15.w, r23.w, r20.z, (last)r15.w
mad.f32 r13.w, r23.w, r20.w, (last)r13.w
mad.f32 r11.w, r23.w, r21.x, (last)r11.w
mad.f32 r9.w, r23.w, r21.y, (last)r9.w
mad.f32 r7.w, r23.w, r21.z, (last)r7.w
mad.f32 r5.w, r23.w, r21.w, (last)r5.w
mad.f32 r3.w, r23.w, r22.x, (last)r3.w
(rpt1)mad.f32 r16.x, (r)r24.x, r20.z, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r24.x, r20.w, (r)(last)r14.x
(rpt1)mad.f32 r12.x, (r)r24.x, r21.x, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r24.x, r21.y, (r)(last)r10.x
(rpt1)mad.f32 r8.x, (r)r24.x, r21.z, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r24.x, r21.w, (r)(last)r6.x
(rpt1)mad.f32 r4.x, (r)r24.x, r22.x, (r)(last)r4.x
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r22.y, (r)(last)r19.z
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r22.y, (r)(last)r20.x
isam.v.base0 (u32)(xyzw)r19.z, r25.y, s#0, t#2
isam.v.base0 (u32)(xyzw)r20.z, r25.z, s#0, t#2
mad.f32 r8.z, r18.z, r2.z, (last)r8.z
mad.f32 r6.z, r18.z, r2.w, (last)r6.z
mad.f32 r4.z, r18.z, r3.x, (last)r4.z
mad.f32 r8.w, r18.w, r2.z, (last)r8.w
mad.f32 r6.w, r18.w, r2.w, (last)r6.w
mad.f32 r4.w, r18.w, r3.x, (last)r4.w
mad.f32 r9.x, r19.x, r2.z, (last)r9.x
mad.f32 r7.x, r19.x, r2.w, (last)r7.x
mad.f32 r5.x, r19.x, r3.x, (last)r5.x
mad.f32 r9.y, r19.y, r2.z, (last)r9.y
mad.f32 r7.y, r19.y, r2.w, (last)r7.y
mad.f32 r5.y, r19.y, r3.x, (last)r5.y
(rpt1)mad.f32 r18.z, (r)(last)r18.z, r3.y, (r)(last)r29.w
(rpt1)mad.f32 r19.x, (r)(last)r19.x, r3.y, (r)(last)r30.y
ldl.u32 r29.w, l[r1.y+2176], 4
ldl.u32 r2.z, l[r1.y+2304], 4
mad.f32 r8.z, r22.z, r21.z, (last)r8.z
mad.f32 r6.z, r22.z, r21.w, (last)r6.z
mad.f32 r4.z, r22.z, r22.x, (last)r4.z
mad.f32 r8.w, r22.w, r21.z, (last)r8.w
mad.f32 r6.w, r22.w, r21.w, (last)r6.w
mad.f32 r4.w, r22.w, r22.x, (last)r4.w
mad.f32 r9.x, r23.x, r21.z, (last)r9.x
mad.f32 r7.x, r23.x, r21.w, (last)r7.x
mad.f32 r5.x, r23.x, r22.x, (last)r5.x
mad.f32 r9.y, r23.y, r21.z, (last)r9.y
mad.f32 r7.y, r23.y, r21.w, (last)r7.y
mad.f32 r5.y, r23.y, r22.x, (last)r5.y
(rpt1)mad.f32 r22.z, (r)(last)r22.z, r22.y, (r)(last)r18.z
(rpt1)mad.f32 r23.x, (r)(last)r23.x, r22.y, (r)(last)r19.x
ldl.u32 r18.z, l[r1.y+2432], 4
ldl.u32 r21.z, l[r1.y+2560], 4
(sy)mad.f32 r16.z, r30.w, r28.w, (last)r16.z
mad.f32 r14.z, r30.w, r29.x, (last)r14.z
mad.f32 r12.z, r30.w, r29.y, (last)r12.z
mad.f32 r10.z, r30.w, r29.z, (last)r10.z
mad.f32 r16.w, r31.x, r28.w, (last)r16.w
mad.f32 r14.w, r31.x, r29.x, (last)r14.w
mad.f32 r12.w, r31.x, r29.y, (last)r12.w
mad.f32 r10.w, r31.x, r29.z, (last)r10.w
mad.f32 r17.x, r31.y, r28.w, (last)r17.x
mad.f32 r15.x, r31.y, r29.x, (last)r15.x
mad.f32 r13.x, r31.y, r29.y, (last)r13.x
mad.f32 r11.x, r31.y, r29.z, (last)r11.x
mad.f32 r17.y, r31.z, r28.w, (last)r17.y
mad.f32 r15.y, r31.z, r29.x, (last)r15.y
mad.f32 r13.y, r31.z, r29.y, (last)r13.y
mad.f32 r11.y, r31.z, r29.z, (last)r11.y
mad.f32 r15.z, r1.z, r28.w, (last)r15.z
mad.f32 r13.z, r1.z, r29.x, (last)r13.z
mad.f32 r11.z, r1.z, r29.y, (last)r11.z
mad.f32 r9.z, r1.z, r29.z, (last)r9.z
mad.f32 r15.w, r1.w, r28.w, (last)r15.w
mad.f32 r13.w, r1.w, r29.x, (last)r13.w
mad.f32 r11.w, r1.w, r29.y, (last)r11.w
mad.f32 r9.w, r1.w, r29.z, (last)r9.w
(rpt1)mad.f32 r16.x, (r)r2.x, r28.w, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r2.x, r29.x, (r)(last)r14.x
(rpt1)mad.f32 r12.x, (r)r2.x, r29.y, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r2.x, r29.z, (r)(last)r10.x
(ss)mad.f32 r7.z, r1.z, r29.w, (last)r7.z
mad.f32 r5.z, r1.z, r30.x, (last)r5.z
mad.f32 r3.z, r1.z, r30.y, (last)r3.z
mad.f32 r7.w, r1.w, r29.w, (last)r7.w
mad.f32 r5.w, r1.w, r30.x, (last)r5.w
mad.f32 r3.w, r1.w, r30.y, (last)r3.w
(rpt1)mad.f32 r8.x, (r)r2.x, r29.w, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r2.x, r30.x, (r)(last)r6.x
(rpt1)mad.f32 r4.x, (r)r2.x, r30.y, (r)(last)r4.x
mad.f32 r8.z, r30.w, r29.w, (last)r8.z
mad.f32 r6.z, r30.w, r30.x, (last)r6.z
mad.f32 r4.z, r30.w, r30.y, (last)r4.z
mad.f32 r8.w, r31.x, r29.w, (last)r8.w
mad.f32 r6.w, r31.x, r30.x, (last)r6.w
mad.f32 r4.w, r31.x, r30.y, (last)r4.w
mad.f32 r9.x, r31.y, r29.w, (last)r9.x
mad.f32 r7.x, r31.y, r30.x, (last)r7.x
mad.f32 r5.x, r31.y, r30.y, (last)r5.x
mad.f32 r9.y, r31.z, r29.w, (last)r9.y
mad.f32 r7.y, r31.z, r30.x, (last)r7.y
mad.f32 r5.y, r31.z, r30.y, (last)r5.y
(rpt1)mad.f32 r1.z, (r)(last)r1.z, r30.z, (r)(last)r23.z
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r30.z, (r)(last)r24.x
isam.v.base0 (u32)(xyzw)r23.z, r25.w, s#0, t#2
isam.v.base0 (u32)(xyzw)r24.z, r26.x, s#0, t#2
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r30.z, (r)(last)r22.z
(rpt1)mad.f32 r31.y, (r)(last)r31.y, r30.z, (r)(last)r23.x
ldl.u32 r22.z, l[r1.y+2688], 4
ldl.u32 r28.w, l[r1.y+2816], 4
ldl.u32 r29.w, l[r1.y+2944], 4
mad.f32 r16.z, r19.z, r2.z, (last)r16.z
mad.f32 r14.z, r19.z, r2.w, (last)r14.z
mad.f32 r12.z, r19.z, r3.x, (last)r12.z
mad.f32 r10.z, r19.z, r3.y, (last)r10.z
mad.f32 r16.w, r19.w, r2.z, (last)r16.w
mad.f32 r14.w, r19.w, r2.w, (last)r14.w
mad.f32 r12.w, r19.w, r3.x, (last)r12.w
mad.f32 r10.w, r19.w, r3.y, (last)r10.w
mad.f32 r17.x, r20.x, r2.z, (last)r17.x
mad.f32 r15.x, r20.x, r2.w, (last)r15.x
mad.f32 r13.x, r20.x, r3.x, (last)r13.x
mad.f32 r11.x, r20.x, r3.y, (last)r11.x
mad.f32 r17.y, r20.y, r2.z, (last)r17.y
mad.f32 r15.y, r20.y, r2.w, (last)r15.y
mad.f32 r13.y, r20.y, r3.x, (last)r13.y
mad.f32 r11.y, r20.y, r3.y, (last)r11.y
mad.f32 r15.z, r20.z, r2.z, (last)r15.z
mad.f32 r13.z, r20.z, r2.w, (last)r13.z
mad.f32 r11.z, r20.z, r3.x, (last)r11.z
mad.f32 r9.z, r20.z, r3.y, (last)r9.z
mad.f32 r15.w, r20.w, r2.z, (last)r15.w
mad.f32 r13.w, r20.w, r2.w, (last)r13.w
mad.f32 r11.w, r20.w, r3.x, (last)r11.w
mad.f32 r9.w, r20.w, r3.y, (last)r9.w
(rpt1)mad.f32 r16.x, (r)r21.x, r2.z, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r21.x, r2.w, (r)(last)r14.x
(rpt1)mad.f32 r12.x, (r)r21.x, r3.x, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r21.x, r3.y, (r)(last)r10.x
ldl.u32 r2.z, l[r1.y+3072], 4
mad.f32 r7.z, r20.z, r18.z, (last)r7.z
mad.f32 r5.z, r20.z, r18.w, (last)r5.z
mad.f32 r3.z, r20.z, r19.x, (last)r3.z
mad.f32 r7.w, r20.w, r18.z, (last)r7.w
mad.f32 r5.w, r20.w, r18.w, (last)r5.w
mad.f32 r3.w, r20.w, r19.x, (last)r3.w
(rpt1)mad.f32 r8.x, (r)r21.x, r18.z, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r21.x, r18.w, (r)(last)r6.x
(rpt1)mad.f32 r4.x, (r)r21.x, r19.x, (r)(last)r4.x
mad.f32 r8.z, r19.z, r18.z, (last)r8.z
mad.f32 r6.z, r19.z, r18.w, (last)r6.z
mad.f32 r4.z, r19.z, r19.x, (last)r4.z
mad.f32 r8.w, r19.w, r18.z, (last)r8.w
mad.f32 r6.w, r19.w, r18.w, (last)r6.w
mad.f32 r4.w, r19.w, r19.x, (last)r4.w
mad.f32 r9.x, r20.x, r18.z, (last)r9.x
mad.f32 r7.x, r20.x, r18.w, (last)r7.x
mad.f32 r5.x, r20.x, r19.x, (last)r5.x
mad.f32 r9.y, r20.y, r18.z, (last)r9.y
mad.f32 r7.y, r20.y, r18.w, (last)r7.y
mad.f32 r5.y, r20.y, r19.x, (last)r5.y
(rpt1)mad.f32 r20.z, (r)(last)r20.z, r19.y, (r)(last)r1.z
(rpt1)mad.f32 r21.x, (r)(last)r21.x, r19.y, (r)(last)r2.x
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r19.y, (r)(last)r30.w
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r19.y, (r)(last)r31.y
isam.v.base0 (u32)(xyzw)r30.w, r26.y, s#0, t#2
isam.v.base0 (u32)(xyzw)r1.z, r26.z, s#0, t#2
ldl.u32 r18.z, l[r1.y+3200], 4
(sy)mad.f32 r16.z, r23.z, r21.z, (last)r16.z
mad.f32 r14.z, r23.z, r21.w, (last)r14.z
mad.f32 r12.z, r23.z, r22.x, (last)r12.z
mad.f32 r10.z, r23.z, r22.y, (last)r10.z
mad.f32 r16.w, r23.w, r21.z, (last)r16.w
mad.f32 r14.w, r23.w, r21.w, (last)r14.w
mad.f32 r12.w, r23.w, r22.x, (last)r12.w
mad.f32 r10.w, r23.w, r22.y, (last)r10.w
mad.f32 r17.x, r24.x, r21.z, (last)r17.x
mad.f32 r15.x, r24.x, r21.w, (last)r15.x
mad.f32 r13.x, r24.x, r22.x, (last)r13.x
mad.f32 r11.x, r24.x, r22.y, (last)r11.x
mad.f32 r17.y, r24.y, r21.z, (last)r17.y
mad.f32 r15.y, r24.y, r21.w, (last)r15.y
mad.f32 r13.y, r24.y, r22.x, (last)r13.y
mad.f32 r11.y, r24.y, r22.y, (last)r11.y
mad.f32 r15.z, r24.z, r21.z, (last)r15.z
mad.f32 r13.z, r24.z, r21.w, (last)r13.z
mad.f32 r11.z, r24.z, r22.x, (last)r11.z
mad.f32 r9.z, r24.z, r22.y, (last)r9.z
mad.f32 r15.w, r24.w, r21.z, (last)r15.w
mad.f32 r13.w, r24.w, r21.w, (last)r13.w
mad.f32 r11.w, r24.w, r22.x, (last)r11.w
mad.f32 r9.w, r24.w, r22.y, (last)r9.w
(rpt1)mad.f32 r16.x, (r)r25.x, r21.z, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r25.x, r21.w, (r)(last)r14.x
(rpt1)mad.f32 r12.x, (r)r25.x, r22.x, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r25.x, r22.y, (r)(last)r10.x
ldl.u32 r21.z, l[r1.y+3328], 4
(ss)mad.f32 r7.z, r24.z, r22.z, (last)r7.z
mad.f32 r5.z, r24.z, r22.w, (last)r5.z
mad.f32 r3.z, r24.z, r23.x, (last)r3.z
mad.f32 r7.w, r24.w, r22.z, (last)r7.w
mad.f32 r5.w, r24.w, r22.w, (last)r5.w
mad.f32 r3.w, r24.w, r23.x, (last)r3.w
(rpt1)mad.f32 r8.x, (r)r25.x, r22.z, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r25.x, r22.w, (r)(last)r6.x
(rpt1)mad.f32 r4.x, (r)r25.x, r23.x, (r)(last)r4.x
mad.f32 r8.z, r23.z, r22.z, (last)r8.z
mad.f32 r6.z, r23.z, r22.w, (last)r6.z
mad.f32 r4.z, r23.z, r23.x, (last)r4.z
mad.f32 r8.w, r23.w, r22.z, (last)r8.w
mad.f32 r6.w, r23.w, r22.w, (last)r6.w
mad.f32 r4.w, r23.w, r23.x, (last)r4.w
mad.f32 r9.x, r24.x, r22.z, (last)r9.x
mad.f32 r7.x, r24.x, r22.w, (last)r7.x
mad.f32 r5.x, r24.x, r23.x, (last)r5.x
mad.f32 r9.y, r24.y, r22.z, (last)r9.y
mad.f32 r7.y, r24.y, r22.w, (last)r7.y
mad.f32 r5.y, r24.y, r23.x, (last)r5.y
(rpt1)mad.f32 r24.z, (r)(last)r24.z, r23.y, (r)(last)r20.z
(rpt1)mad.f32 r25.x, (r)(last)r25.x, r23.y, (r)(last)r21.x
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r23.y, (r)(last)r19.z
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r23.y, (r)(last)r20.x
isam.v.base0 (u32)(xyzw)r19.z, r26.w, s#0, t#2
isam.v.base0 (u32)(xyzw)r20.z, r27.x, s#0, t#2
ldl.u32 r22.z, l[r1.y+3456], 4
ldl.u32 r25.z, l[r1.y+3584], 4
mad.f32 r16.z, r30.w, r28.w, (last)r16.z
mad.f32 r14.z, r30.w, r29.x, (last)r14.z
mad.f32 r12.z, r30.w, r29.y, (last)r12.z
mad.f32 r10.z, r30.w, r29.z, (last)r10.z
mad.f32 r16.w, r31.x, r28.w, (last)r16.w
mad.f32 r14.w, r31.x, r29.x, (last)r14.w
mad.f32 r12.w, r31.x, r29.y, (last)r12.w
mad.f32 r10.w, r31.x, r29.z, (last)r10.w
mad.f32 r17.x, r31.y, r28.w, (last)r17.x
mad.f32 r15.x, r31.y, r29.x, (last)r15.x
mad.f32 r13.x, r31.y, r29.y, (last)r13.x
mad.f32 r11.x, r31.y, r29.z, (last)r11.x
mad.f32 r17.y, r31.z, r28.w, (last)r17.y
mad.f32 r15.y, r31.z, r29.x, (last)r15.y
mad.f32 r13.y, r31.z, r29.y, (last)r13.y
mad.f32 r11.y, r31.z, r29.z, (last)r11.y
mad.f32 r15.z, r1.z, r28.w, (last)r15.z
mad.f32 r13.z, r1.z, r29.x, (last)r13.z
mad.f32 r11.z, r1.z, r29.y, (last)r11.z
mad.f32 r9.z, r1.z, r29.z, (last)r9.z
mad.f32 r15.w, r1.w, r28.w, (last)r15.w
mad.f32 r13.w, r1.w, r29.x, (last)r13.w
mad.f32 r11.w, r1.w, r29.y, (last)r11.w
mad.f32 r9.w, r1.w, r29.z, (last)r9.w
(rpt1)mad.f32 r16.x, (r)r2.x, r28.w, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r2.x, r29.x, (r)(last)r14.x
(rpt1)mad.f32 r12.x, (r)r2.x, r29.y, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r2.x, r29.z, (r)(last)r10.x
mad.f32 r7.z, r1.z, r29.w, (last)r7.z
mad.f32 r5.z, r1.z, r30.x, (last)r5.z
mad.f32 r3.z, r1.z, r30.y, (last)r3.z
mad.f32 r7.w, r1.w, r29.w, (last)r7.w
mad.f32 r5.w, r1.w, r30.x, (last)r5.w
mad.f32 r3.w, r1.w, r30.y, (last)r3.w
(rpt1)mad.f32 r8.x, (r)r2.x, r29.w, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r2.x, r30.x, (r)(last)r6.x
(rpt1)mad.f32 r4.x, (r)r2.x, r30.y, (r)(last)r4.x
mad.f32 r8.z, r30.w, r29.w, (last)r8.z
mad.f32 r6.z, r30.w, r30.x, (last)r6.z
mad.f32 r4.z, r30.w, r30.y, (last)r4.z
mad.f32 r8.w, r31.x, r29.w, (last)r8.w
mad.f32 r6.w, r31.x, r30.x, (last)r6.w
mad.f32 r4.w, r31.x, r30.y, (last)r4.w
mad.f32 r9.x, r31.y, r29.w, (last)r9.x
mad.f32 r7.x, r31.y, r30.x, (last)r7.x
mad.f32 r5.x, r31.y, r30.y, (last)r5.x
mad.f32 r9.y, r31.z, r29.w, (last)r9.y
mad.f32 r7.y, r31.z, r30.x, (last)r7.y
mad.f32 r5.y, r31.z, r30.y, (last)r5.y
(rpt1)mad.f32 r1.z, (r)(last)r1.z, r30.z, (r)(last)r24.z
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r30.z, (r)(last)r25.x
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r30.z, (r)(last)r23.z
(rpt1)mad.f32 r31.y, (r)(last)r31.y, r30.z, (r)(last)r24.x
isam.v.base0 (u32)(xyzw)r23.z, r27.y, s#0, t#2
isam.v.base0 (u32)(xyzw)r24.z, r27.z, s#0, t#2
isam.v.base0 (u32)(xyzw)r28.w, r27.w, s#0, t#2
isam.v.base0 (u32)(xyzw)r29.w, r28.x, s#0, t#2
(ss)nop
ldl.u32 r26.z, l[r1.y+3712], 4
(sy)mad.f32 r12.z, r19.z, r3.x, (last)r12.z
mad.f32 r10.z, r19.z, r3.y, (last)r10.z
mad.f32 r12.w, r19.w, r3.x, (last)r12.w
mad.f32 r10.w, r19.w, r3.y, (last)r10.w
mad.f32 r13.x, r20.x, r3.x, (last)r13.x
mad.f32 r11.x, r20.x, r3.y, (last)r11.x
mad.f32 r13.y, r20.y, r3.x, (last)r13.y
mad.f32 r11.y, r20.y, r3.y, (last)r11.y
mad.f32 r11.z, r20.z, r3.x, (last)r11.z
mad.f32 r9.z, r20.z, r3.y, (last)r9.z
mad.f32 r11.w, r20.w, r3.x, (last)r11.w
mad.f32 r9.w, r20.w, r3.y, (last)r9.w
(rpt1)mad.f32 r12.x, (r)r21.x, r3.x, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r21.x, r3.y, (r)(last)r10.x
mad.f32 r7.z, r20.z, r18.z, (last)r7.z
mad.f32 r5.z, r20.z, r18.w, (last)r5.z
mad.f32 r7.w, r20.w, r18.z, (last)r7.w
mad.f32 r5.w, r20.w, r18.w, (last)r5.w
(rpt1)mad.f32 r8.x, (r)r21.x, r18.z, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r21.x, r18.w, (r)(last)r6.x
mad.f32 r8.z, r19.z, r18.z, (last)r8.z
mad.f32 r6.z, r19.z, r18.w, (last)r6.z
mad.f32 r8.w, r19.w, r18.z, (last)r8.w
mad.f32 r6.w, r19.w, r18.w, (last)r6.w
mad.f32 r9.x, r20.x, r18.z, (last)r9.x
mad.f32 r7.x, r20.x, r18.w, (last)r7.x
mad.f32 r9.y, r20.y, r18.z, (last)r9.y
mad.f32 r7.y, r20.y, r18.w, (last)r7.y
mad.f32 r16.z, r19.z, r2.z, (last)r16.z
mad.f32 r14.z, r19.z, r2.w, (last)r14.z
mad.f32 r16.w, r19.w, r2.z, (last)r16.w
mad.f32 r14.w, r19.w, r2.w, (last)r14.w
mad.f32 r17.x, r20.x, r2.z, (last)r17.x
mad.f32 r15.x, r20.x, r2.w, (last)r15.x
mad.f32 r17.y, r20.y, r2.z, (last)r17.y
mad.f32 r15.y, r20.y, r2.w, (last)r15.y
mad.f32 r15.z, r20.z, r2.z, (last)r15.z
mad.f32 r13.z, r20.z, r2.w, (last)r13.z
mad.f32 r15.w, r20.w, r2.z, (last)r15.w
mad.f32 r13.w, r20.w, r2.w, (last)r13.w
(rpt1)mad.f32 r16.x, (r)r21.x, r2.z, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r21.x, r2.w, (r)(last)r14.x
isam.v.base0 (u32)(xyzw)r2.z, r28.y, s#0, t#2
mad.f32 r12.z, r23.z, r22.x, (last)r12.z
mad.f32 r10.z, r23.z, r22.y, (last)r10.z
mad.f32 r12.w, r23.w, r22.x, (last)r12.w
mad.f32 r10.w, r23.w, r22.y, (last)r10.w
mad.f32 r13.x, r24.x, r22.x, (last)r13.x
mad.f32 r11.x, r24.x, r22.y, (last)r11.x
mad.f32 r13.y, r24.y, r22.x, (last)r13.y
mad.f32 r11.y, r24.y, r22.y, (last)r11.y
mad.f32 r11.z, r24.z, r22.x, (last)r11.z
mad.f32 r9.z, r24.z, r22.y, (last)r9.z
mad.f32 r11.w, r24.w, r22.x, (last)r11.w
mad.f32 r9.w, r24.w, r22.y, (last)r9.w
(rpt1)mad.f32 r12.x, (r)r25.x, r22.x, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r25.x, r22.y, (r)(last)r10.x
mad.f32 r7.z, r24.z, r22.z, (last)r7.z
mad.f32 r5.z, r24.z, r22.w, (last)r5.z
mad.f32 r7.w, r24.w, r22.z, (last)r7.w
mad.f32 r5.w, r24.w, r22.w, (last)r5.w
(rpt1)mad.f32 r8.x, (r)r25.x, r22.z, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r25.x, r22.w, (r)(last)r6.x
mad.f32 r8.z, r23.z, r22.z, (last)r8.z
mad.f32 r6.z, r23.z, r22.w, (last)r6.z
mad.f32 r8.w, r23.w, r22.z, (last)r8.w
mad.f32 r6.w, r23.w, r22.w, (last)r6.w
mad.f32 r9.x, r24.x, r22.z, (last)r9.x
mad.f32 r7.x, r24.x, r22.w, (last)r7.x
mad.f32 r9.y, r24.y, r22.z, (last)r9.y
mad.f32 r7.y, r24.y, r22.w, (last)r7.y
isam.v.base0 (u32)(xyzw)r22.x, r28.z, s#0, t#2
(rpt1)mad.f32 r3.z, (r)r20.z, r19.x, (r)(last)r3.z
(rpt1)mad.f32 r4.x, (r)r21.x, r19.x, (r)(last)r4.x
(rpt1)mad.f32 r4.z, (r)r19.z, r19.x, (r)(last)r4.z
(rpt1)mad.f32 r5.x, (r)r20.x, r19.x, (r)(last)r5.x
(rpt1)mad.f32 r20.z, (r)(last)r20.z, r19.y, (r)(last)r1.z
(rpt1)mad.f32 r21.x, (r)(last)r21.x, r19.y, (r)(last)r2.x
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r19.y, (r)(last)r30.w
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r19.y, (r)(last)r31.y
ldl.u32 r30.w, l[r1.y+3840], 4
ldl.u32 r1.z, l[r1.y+3968], 4
mad.f32 r16.z, r23.z, r21.z, (last)r16.z
mad.f32 r14.z, r23.z, r21.w, (last)r14.z
mad.f32 r16.w, r23.w, r21.z, (last)r16.w
mad.f32 r14.w, r23.w, r21.w, (last)r14.w
mad.f32 r17.x, r24.x, r21.z, (last)r17.x
mad.f32 r15.x, r24.x, r21.w, (last)r15.x
mad.f32 r17.y, r24.y, r21.z, (last)r17.y
mad.f32 r15.y, r24.y, r21.w, (last)r15.y
mad.f32 r15.z, r24.z, r21.z, (last)r15.z
mad.f32 r13.z, r24.z, r21.w, (last)r13.z
mad.f32 r15.w, r24.w, r21.z, (last)r15.w
mad.f32 r13.w, r24.w, r21.w, (last)r13.w
(rpt1)mad.f32 r16.x, (r)r25.x, r21.z, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r25.x, r21.w, (r)(last)r14.x
(rpt1)mad.f32 r3.z, (r)r24.z, r23.x, (r)(last)r3.z
(rpt1)mad.f32 r4.x, (r)r25.x, r23.x, (r)(last)r4.x
(rpt1)mad.f32 r4.z, (r)r23.z, r23.x, (r)(last)r4.z
(rpt1)mad.f32 r5.x, (r)r24.x, r23.x, (r)(last)r5.x
(rpt1)mad.f32 r24.z, (r)(last)r24.z, r23.y, (r)(last)r20.z
(rpt1)mad.f32 r25.x, (r)(last)r25.x, r23.y, (r)(last)r21.x
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r23.y, (r)(last)r19.z
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r23.y, (r)(last)r20.x
mad.f32 r12.z, r28.w, r26.x, (last)r12.z
mad.f32 r10.z, r28.w, r26.y, (last)r10.z
mad.f32 r12.w, r29.x, r26.x, (last)r12.w
mad.f32 r10.w, r29.x, r26.y, (last)r10.w
mad.f32 r13.x, r29.y, r26.x, (last)r13.x
mad.f32 r11.x, r29.y, r26.y, (last)r11.x
mad.f32 r13.y, r29.z, r26.x, (last)r13.y
mad.f32 r11.y, r29.z, r26.y, (last)r11.y
mad.f32 r11.z, r29.w, r26.x, (last)r11.z
mad.f32 r9.z, r29.w, r26.y, (last)r9.z
mad.f32 r11.w, r30.x, r26.x, (last)r11.w
mad.f32 r9.w, r30.x, r26.y, (last)r9.w
(rpt1)mad.f32 r12.x, (r)r30.y, r26.x, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r30.y, r26.y, (r)(last)r10.x
(ss)mad.f32 r7.z, r29.w, r26.z, (last)r7.z
mad.f32 r5.z, r29.w, r26.w, (last)r5.z
mad.f32 r7.w, r30.x, r26.z, (last)r7.w
mad.f32 r5.w, r30.x, r26.w, (last)r5.w
(rpt1)mad.f32 r8.x, (r)r30.y, r26.z, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r30.y, r26.w, (r)(last)r6.x
mad.f32 r8.z, r28.w, r26.z, (last)r8.z
mad.f32 r6.z, r28.w, r26.w, (last)r6.z
mad.f32 r8.w, r29.x, r26.z, (last)r8.w
mad.f32 r6.w, r29.x, r26.w, (last)r6.w
mad.f32 r9.x, r29.y, r26.z, (last)r9.x
mad.f32 r7.x, r29.y, r26.w, (last)r7.x
mad.f32 r9.y, r29.z, r26.z, (last)r9.y
mad.f32 r7.y, r29.z, r26.w, (last)r7.y
mad.f32 r16.z, r28.w, r25.z, (last)r16.z
mad.f32 r14.z, r28.w, r25.w, (last)r14.z
mad.f32 r16.w, r29.x, r25.z, (last)r16.w
mad.f32 r14.w, r29.x, r25.w, (last)r14.w
mad.f32 r17.x, r29.y, r25.z, (last)r17.x
mad.f32 r15.x, r29.y, r25.w, (last)r15.x
mad.f32 r17.y, r29.z, r25.z, (last)r17.y
mad.f32 r15.y, r29.z, r25.w, (last)r15.y
mad.f32 r15.z, r29.w, r25.z, (last)r15.z
mad.f32 r13.z, r29.w, r25.w, (last)r13.z
mad.f32 r15.w, r30.x, r25.z, (last)r15.w
mad.f32 r13.w, r30.x, r25.w, (last)r13.w
(rpt1)mad.f32 r16.x, (r)r30.y, r25.z, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r30.y, r25.w, (r)(last)r14.x
(rpt1)mad.f32 r3.z, (r)r29.w, r27.x, (r)(last)r3.z
(rpt1)mad.f32 r4.x, (r)r30.y, r27.x, (r)(last)r4.x
(rpt1)mad.f32 r4.z, (r)r28.w, r27.x, (r)(last)r4.z
(rpt1)mad.f32 r5.x, (r)r29.y, r27.x, (r)(last)r5.x
(rpt1)mad.f32 r29.w, (r)(last)r29.w, r27.y, (r)(last)r24.z
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r27.y, (r)(last)r25.x
(rpt1)mad.f32 r28.w, (r)(last)r28.w, r27.y, (r)(last)r23.z
(rpt1)mad.f32 r29.y, (r)(last)r29.y, r27.y, (r)(last)r24.x
(sy)mad.f32 r12.z, r2.z, r31.y, (last)r12.z
mad.f32 r10.z, r2.z, r31.z, (last)r10.z
mad.f32 r12.w, r2.w, r31.y, (last)r12.w
mad.f32 r10.w, r2.w, r31.z, (last)r10.w
mad.f32 r13.x, r3.x, r31.y, (last)r13.x
mad.f32 r11.x, r3.x, r31.z, (last)r11.x
mad.f32 r13.y, r3.y, r31.y, (last)r13.y
mad.f32 r11.y, r3.y, r31.z, (last)r11.y
mad.f32 r11.z, r22.x, r31.y, (last)r11.z
mad.f32 r9.z, r22.x, r31.z, (last)r9.z
mad.f32 r11.w, r22.y, r31.y, (last)r11.w
mad.f32 r9.w, r22.y, r31.z, (last)r9.w
(rpt1)mad.f32 r12.x, (r)r22.z, r31.y, (r)(last)r12.x
(rpt1)mad.f32 r10.x, (r)r22.z, r31.z, (r)(last)r10.x
mad.f32 r7.z, r22.x, r1.z, (last)r7.z
mad.f32 r5.z, r22.x, r1.w, (last)r5.z
mad.f32 r7.w, r22.y, r1.z, (last)r7.w
mad.f32 r5.w, r22.y, r1.w, (last)r5.w
(rpt1)mad.f32 r8.x, (r)r22.z, r1.z, (r)(last)r8.x
(rpt1)mad.f32 r6.x, (r)r22.z, r1.w, (r)(last)r6.x
mad.f32 r8.z, r2.z, r1.z, (last)r8.z
mad.f32 r6.z, r2.z, r1.w, (last)r6.z
mad.f32 r8.w, r2.w, r1.z, (last)r8.w
mad.f32 r6.w, r2.w, r1.w, (last)r6.w
mad.f32 r9.x, r3.x, r1.z, (last)r9.x
mad.f32 r7.x, r3.x, r1.w, (last)r7.x
mad.f32 r9.y, r3.y, r1.z, (last)r9.y
mad.f32 r7.y, r3.y, r1.w, (last)r7.y
mad.f32 r16.z, r2.z, r30.w, (last)r16.z
mad.f32 r14.z, r2.z, r31.x, (last)r14.z
mad.f32 r16.w, r2.w, r30.w, (last)r16.w
mad.f32 r14.w, r2.w, r31.x, (last)r14.w
mad.f32 r17.x, r3.x, r30.w, (last)r17.x
mad.f32 r15.x, r3.x, r31.x, (last)r15.x
mad.f32 r17.y, r3.y, r30.w, (last)r17.y
mad.f32 r15.y, r3.y, r31.x, (last)r15.y
mad.f32 r15.z, r22.x, r30.w, (last)r15.z
mad.f32 r13.z, r22.x, r31.x, (last)r13.z
mad.f32 r15.w, r22.y, r30.w, (last)r15.w
mad.f32 r13.w, r22.y, r31.x, (last)r13.w
(rpt1)mad.f32 r16.x, (r)r22.z, r30.w, (r)(last)r16.x
(rpt1)mad.f32 r14.x, (r)r22.z, r31.x, (r)(last)r14.x
(rpt1)mad.f32 r3.z, (r)r22.x, r2.x, (r)(last)r3.z
(rpt1)mad.f32 r4.x, (r)r22.z, r2.x, (r)(last)r4.x
(rpt1)mad.f32 r4.z, (r)r2.z, r2.x, (r)(last)r4.z
(rpt1)mad.f32 r5.x, (r)r3.x, r2.x, (r)(last)r5.x
(rpt1)mad.f32 r23.x, (r)(last)r22.x, r2.y, (r)(last)r29.w
(rpt1)mad.f32 r23.z, (r)(last)r22.z, r2.y, (r)(last)r30.y
(rpt1)mad.f32 r2.z, (r)(last)r2.z, r2.y, (r)(last)r28.w
(rpt1)mad.f32 r3.x, (r)(last)r3.x, r2.y, (r)(last)r29.y
fence.r.w
(sy)(ss)mov.u32u32 r24.z, (last)r1.x
mov.u32u32 r24.w, (last)r1.y
mov.u32u32 r24.x, (last)r0.x
mov.u32u32 r24.y, (last)r0.w
cov.f32f16 hr38.x, r12.z
cov.f32f16 hr39.x, r10.z
cov.f32f16 hr38.y, r12.w
cov.f32f16 hr39.y, r10.w
cov.f32f16 hr38.z, r13.x
cov.f32f16 hr39.z, r11.x
cov.f32f16 hr38.w, r13.y
cov.f32f16 hr39.w, r11.y
cov.f32f16 hr0.w, r5.z
cov.f32f16 hr40.x, r8.z
cov.f32f16 hr41.x, r6.z
cov.f32f16 hr40.y, r8.w
cov.f32f16 hr41.y, r6.w
cov.f32f16 hr40.z, r9.x
cov.f32f16 hr41.z, r7.x
cov.f32f16 hr40.w, r9.y
cov.f32f16 hr41.w, r7.y
cov.f32f16 hr3.w, r5.w
cov.f32f16 hr35.x, r16.z
cov.f32f16 hr37.x, r14.z
cov.f32f16 hr35.y, r16.w
cov.f32f16 hr37.y, r14.w
cov.f32f16 hr35.z, r17.x
cov.f32f16 hr37.z, r15.x
cov.f32f16 hr35.w, r17.y
cov.f32f16 hr37.w, r15.y
cov.f32f16 hr0.z, r15.z
cov.f32f16 hr3.x, r13.z
cov.f32f16 hr3.y, r15.w
cov.f32f16 hr3.z, r13.w
(rpt1)cov.f32f16 hr36.x, (r)r16.x
cov.f32f16 hr1.x, r3.z
(rpt1)cov.f32f16 hr42.x, (r)r4.z
(rpt1)cov.f32f16 hr42.z, (r)r5.x
(rpt1)cov.f32f16 hr4.x, (r)r11.z
cov.f32f16 hr1.y, r23.x
(rpt1)cov.f32f16 hr44.x, (r)r9.z
(rpt1)cov.f32f16 hr44.z, (r)r14.x
(rpt1)cov.f32f16 hr45.x, (r)r7.z
(rpt1)cov.f32f16 hr45.z, (r)r12.x
cov.f32f16 hr43.x, r2.z
mov.u32u32 r25.x, (last)r2.z
cov.f32f16 hr43.y, r2.w
(rpt1)cov.f32f16 hr43.z, (r)r3.x
cov.f32f16 hr4.z, r3.w
cov.f32f16 hr4.w, r23.y
bar.g
(sy)(ss)(rpt1)cov.f32f16 hr2.x, (r)r6.x
cov.f32f16 hr2.z, r4.x
cov.f32f16 hr2.w, r23.z
(rpt1)cov.f32f16 hr0.x, (r)r10.x
(rpt1)cov.f32f16 hr1.z, (r)r8.x
cov.f32f16 hr5.x, r4.y
cov.f32f16 hr5.y, r23.w
br p0.x, #l1154
mov.u32u32 r1.z, (last)r23.x
mov.u32u32 r1.w, (last)r23.y
mov.u32u32 r2.z, (last)r25.x
mov.u32u32 r2.y, (last)r23.w
mov.u32u32 r2.x, (last)r23.z
mov.u32u32 r0.x, (last)r24.x
mov.u32u32 r0.w, (last)r24.y
mov.u32u32 r1.x, r24.z
mov.u32u32 r1.y, (last)r24.w
jump #l129
l1154:
(jp)(eolm)nop
add.u r18.y, r51.w, (last)r18.y
mov.u16u16 hr7.z, (last)hr3.x
mov.u16u16 hr7.w, (last)hr3.z
mov.u16u16 hr8.x, (last)hr44.z
shl.b r18.y, (last)r18.y, 9
mov.u16u16 hr8.y, (last)hr44.w
mov.u16u16 hr8.z, (last)hr4.x
mov.u16u16 hr8.w, (last)hr4.y
sad.s32 r18.y, r52.w, r18.y, (last)r24.z
mov.u16u16 hr9.x, (last)hr45.z
mov.u16u16 hr9.y, (last)hr45.w
mov.u16u16 hr11.z, (last)hr44.x
shl.b r18.y, (last)r18.y, 2
mov.u16u16 hr11.w, (last)hr44.y
mov.u16u16 hr12.x, (last)hr0.x
mov.u16u16 hr12.y, (last)hr0.y
mov.u16u16 hr12.z, (last)hr45.x
mov.u16u16 hr12.w, (last)hr45.y
mov.u16u16 hr13.x, (last)hr1.z
mov.u16u16 hr13.y, (last)hr1.w
mov.u16u16 hr15.z, (last)hr1.x
mov.u16u16 hr15.w, (last)hr4.z
mov.u16u16 hr16.x, (last)hr2.z
mov.u16u16 hr16.y, (last)hr5.x
stib.b.untyped.1d.u16.4.imm.base0 hr35.x, r18.y, 4
add.u r2.w, r18.y, c1.x
add.u r3.x, r18.y, c8.y
add.u r3.y, r18.y, c4.z
add.u r3.z, r18.y, c8.x
add.u r4.w, r18.y, c4.y
add.u r5.x, r18.y, c7.w
(rpt1)add.u r5.y, r18.y, (r)c8.z
(rpt3)add.u r6.w, r18.y, (r)c9.x
(rpt1)add.u r8.y, r18.y, (r)c10.x
mov.u16u16 hr1.z, (last)hr0.w
mov.u16u16 hr1.w, (last)hr3.w
mov.u16u16 hr4.z, (last)hr1.y
mov.u16u16 hr5.x, (last)hr2.w
(ss)mov.u16u16 hr35.z, (last)hr0.z
mov.u16u16 hr35.w, (last)hr3.y
(rpt5)nop
stib.b.untyped.1d.u16.4.imm.base0 hr35.z, r18.y+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr37.x, r2.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r3.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr38.x, r3.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r3.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr39.x, r4.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r5.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr40.x, r5.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r5.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr41.x, r6.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr1.z, r7.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr42.x, r7.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r7.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr43.x, r8.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r8.z, 4
end
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1372 instr, 10 nops, 1362 non-nops, 105 mov, 64 cov, 2432 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 32 full, 12 constlen
; CL prog 23/1: 13 cat0, 169 cat1, 74 cat2, 1028 cat3, 0 cat4, 34 cat5, 50 cat6, 4 cat7
; CL prog 23/1: 25 sstall, 16 (ss), 292 systall, 15 (sy), 1 loops
; CL prog 23/1: 8 max_waves, 0 double_threadsize
; 58 preamble-instr, 1 early-preamble
