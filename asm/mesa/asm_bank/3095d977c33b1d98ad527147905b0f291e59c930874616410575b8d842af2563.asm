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
@const(c1.x)	0x00000800, 0x00001600, 0x00001400, 0x00001200
@const(c2.x)	0x00001000, 0x00000840, 0x00001040, 0x00001800
@const(c3.x)	0x00001840, 0x00010000, 0x00010040, 0x00010800
@const(c4.x)	0x00010840, 0x00011000, 0x00011040, 0x00011800
@const(c5.x)	0x00011840, 0xd0d0d0d0, 0xd0d0d0d0, 0xd0d0d0d0
shps #l31
getone #l31
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 0x1600
mov.u32u32 r49.y, 0x1400
mov.u32u32 r49.z, 0x1200
mov.u32u32 r49.w, 4096
mov.u32u32 r50.x, 2112
mov.u32u32 r50.y, 0x1040
mov.u32u32 r50.z, 0x1800
mov.u32u32 r50.w, 0x1840
mov.u32u32 r51.x, 0x10000
mov.u32u32 r51.y, 0x10040
mov.u32u32 r51.z, 0x10800
mov.u32u32 r51.w, 0x10840
mov.u32u32 r52.x, 0x11000
mov.u32u32 r52.y, 0x11040
mov.u32u32 r52.z, 0x11800
mov.u32u32 r52.w, 0x11840
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 4
stc.u32 c[20], r52.w, 1
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l31:
(jp)(rpt1)add.u r53.x, (r)r48.x, (r)c0.x
mov.u32u32 r54.x, 0
shl.b r53.w, r53.x, 7
shl.b r53.z, r53.y, 6
shr.b r0.w, r0.x, 4
shr.b r1.x, r0.x, 5
and.b r1.y, r0.x, 15
and.b r1.z, r0.x, 31
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
l104:
(rpt1)shr.b r54.y, (r)r53.z, 2
add.u r20.z, r0.x, 128
shl.b r18.x, r0.w, 8
shl.b r18.z, r1.y, 4
shl.b r18.y, r1.x, 9
shr.b r20.z, (last)r20.z, 5
shl.b r18.w, r1.z, 4
(ss)(rpt1)add.u r19.x, r54.x, (r)r0.w
add.u r21.w, r54.x, r20.z
add.u r54.x, r54.x, 8
cmps.u.ge up0.x, r54.x, c1.x
shl.b r20.z, (last)r20.z, 9
(rpt1)shl.b r19.x, (last)(r)r19.x, 9
shl.b r21.w, (last)r21.w, 9
add.u r18.x, (last)r18.x, r18.z
(rpt1)sad.s32 r19.x, (r)r54.y, (r)r19.x, (r)r1.y
sad.s32 r21.w, r54.z, r21.w, r1.z
add.u r18.y, (last)r18.y, r18.w
(rpt1)shl.b r19.x, (last)(r)r19.x, 2
shl.b r21.w, (last)r21.w, 2
add.u r20.z, (last)r20.z, (last)r18.w
add.u r20.w, c2.x, r18.z
add.u r21.x, c1.w, r18.z
add.u r21.y, c1.z, r18.z
isam.v.base0 (u32)(xyzw)r19.z, r19.x, s#0, t#0
add.u r21.z, c1.y, r18.z
isam.v.base0 (u32)(xyzw)r22.y, r19.y, s#0, t#2
shl.b r22.x, r0.w, 2
isam.v.base0 (u32)(xyzw)r23.y, r21.w, s#0, t#2
(sy)stl.u32 l[r18.x], r19.z, 4
stl.u32 l[r18.y+2048], r22.y, 4
nop
stl.u32 l[r20.z+2048], r23.y, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
ldl.u32 r24.y, l[r1.w], 4
ldl.u32 r25.y, l[r1.w+128], 4
ldl.u32 r26.y, l[r18.z+2048], 4
ldl.u32 r27.y, l[r18.z+2304], 4
ldl.u32 r28.y, l[r1.w+256], 4
ldl.u32 r29.y, l[r1.w+384], 4
ldl.u32 r30.z, l[r18.z+2560], 4
(ss)mad.f32 r17.x, r26.y, r24.y, (last)r17.x
mad.f32 r15.x, r26.y, r24.z, (last)r15.x
mad.f32 r13.x, r26.y, r24.w, (last)r13.x
mad.f32 r11.x, r26.y, r25.x, (last)r11.x
mad.f32 r9.x, r26.y, r25.y, (last)r9.x
mad.f32 r7.x, r26.y, r25.z, (last)r7.x
mad.f32 r5.x, r26.y, r25.w, (last)r5.x
mad.f32 r17.y, r26.z, r24.y, (last)r17.y
mad.f32 r15.y, r26.z, r24.z, (last)r15.y
mad.f32 r13.y, r26.z, r24.w, (last)r13.y
mad.f32 r11.y, r26.z, r25.x, (last)r11.y
mad.f32 r9.y, r26.z, r25.y, (last)r9.y
mad.f32 r7.y, r26.z, r25.z, (last)r7.y
mad.f32 r5.y, r26.z, r25.w, (last)r5.y
(rpt1)mad.f32 r16.z, (r)r27.w, r24.y, (r)(last)r16.z
(rpt1)mad.f32 r14.z, (r)r27.w, r24.z, (r)(last)r14.z
(rpt1)mad.f32 r12.z, (r)r27.w, r24.w, (r)(last)r12.z
(rpt1)mad.f32 r10.z, (r)r27.w, r25.x, (r)(last)r10.z
(rpt1)mad.f32 r8.z, (r)r27.w, r25.y, (r)(last)r8.z
(rpt1)mad.f32 r6.z, (r)r27.w, r25.z, (r)(last)r6.z
(rpt1)mad.f32 r4.z, (r)r27.w, r25.w, (r)(last)r4.z
(rpt1)mad.f32 r26.y, (r)(last)r26.y, r26.x, (r)(last)r3.x
(rpt1)mad.f32 r27.w, (r)(last)r27.w, r26.x, (r)(last)r2.z
ldl.u32 r2.z, l[r18.z+2816], 4
ldl.u32 r18.w, l[r1.w+512], 4
ldl.u32 r19.w, l[r1.w+640], 4
ldl.u32 r22.y, l[r18.z+3072], 4
ldl.u32 r23.y, l[r18.z+3328], 4
mad.f32 r17.z, r26.w, r24.y, (last)r17.z
mad.f32 r15.z, r26.w, r24.z, (last)r15.z
mad.f32 r13.z, r26.w, r24.w, (last)r13.z
mad.f32 r11.z, r26.w, r25.x, (last)r11.z
mad.f32 r9.z, r26.w, r25.y, (last)r9.z
mad.f32 r7.z, r26.w, r25.z, (last)r7.z
mad.f32 r5.z, r26.w, r25.w, (last)r5.z
mad.f32 r17.w, r27.x, r24.y, (last)r17.w
mad.f32 r15.w, r27.x, r24.z, (last)r15.w
mad.f32 r13.w, r27.x, r24.w, (last)r13.w
mad.f32 r11.w, r27.x, r25.x, (last)r11.w
mad.f32 r9.w, r27.x, r25.y, (last)r9.w
mad.f32 r7.w, r27.x, r25.z, (last)r7.w
mad.f32 r5.w, r27.x, r25.w, (last)r5.w
mad.f32 r16.x, r27.y, r24.y, (last)r16.x
mad.f32 r14.x, r27.y, r24.z, (last)r14.x
mad.f32 r12.x, r27.y, r24.w, (last)r12.x
mad.f32 r10.x, r27.y, r25.x, (last)r10.x
mad.f32 r8.x, r27.y, r25.y, (last)r8.x
mad.f32 r6.x, r27.y, r25.z, (last)r6.x
mad.f32 r4.x, r27.y, r25.w, (last)r4.x
mad.f32 r16.y, r27.z, r24.y, (last)r16.y
mad.f32 r14.y, r27.z, r24.z, (last)r14.y
mad.f32 r12.y, r27.z, r24.w, (last)r12.y
mad.f32 r10.y, r27.z, r25.x, (last)r10.y
ldl.u32 r24.y, l[r1.w+768], 4
mad.f32 r8.y, r27.z, r25.y, (last)r8.y
mad.f32 r6.y, r27.z, r25.z, (last)r6.y
mad.f32 r4.y, r27.z, r25.w, (last)r4.y
(rpt1)mad.f32 r26.w, (r)(last)r26.w, r26.x, (r)(last)r3.z
(rpt1)mad.f32 r27.y, (r)(last)r27.y, r26.x, (r)(last)r2.x
ldl.u32 r25.y, l[r1.w+896], 4
mad.f32 r17.y, r30.w, r28.y, (last)r17.y
mad.f32 r15.y, r30.w, r28.z, (last)r15.y
mad.f32 r13.y, r30.w, r28.w, (last)r13.y
mad.f32 r11.y, r30.w, r29.x, (last)r11.y
mad.f32 r9.y, r30.w, r29.y, (last)r9.y
mad.f32 r7.y, r30.w, r29.z, (last)r7.y
mad.f32 r5.y, r30.w, r29.w, (last)r5.y
mad.f32 r17.z, r31.x, r28.y, (last)r17.z
mad.f32 r15.z, r31.x, r28.z, (last)r15.z
mad.f32 r13.z, r31.x, r28.w, (last)r13.z
(ss)mad.f32 r16.z, r3.x, r28.y, (last)r16.z
mad.f32 r14.z, r3.x, r28.z, (last)r14.z
mad.f32 r12.z, r3.x, r28.w, (last)r12.z
mad.f32 r10.z, r3.x, r29.x, (last)r10.z
mad.f32 r8.z, r3.x, r29.y, (last)r8.z
mad.f32 r6.z, r3.x, r29.z, (last)r6.z
mad.f32 r4.z, r3.x, r29.w, (last)r4.z
mad.f32 r11.z, r31.x, r29.x, (last)r11.z
mad.f32 r9.z, r31.x, r29.y, (last)r9.z
mad.f32 r7.z, r31.x, r29.z, (last)r7.z
mad.f32 r5.z, r31.x, r29.w, (last)r5.z
mad.f32 r17.w, r31.y, r28.y, (last)r17.w
mad.f32 r15.w, r31.y, r28.z, (last)r15.w
mad.f32 r13.w, r31.y, r28.w, (last)r13.w
mad.f32 r11.w, r31.y, r29.x, (last)r11.w
mad.f32 r9.w, r31.y, r29.y, (last)r9.w
mad.f32 r7.w, r31.y, r29.z, (last)r7.w
mad.f32 r5.w, r31.y, r29.w, (last)r5.w
mad.f32 r16.x, r2.z, r28.y, (last)r16.x
mad.f32 r14.x, r2.z, r28.z, (last)r14.x
mad.f32 r12.x, r2.z, r28.w, (last)r12.x
mad.f32 r10.x, r2.z, r29.x, (last)r10.x
mad.f32 r8.x, r2.z, r29.y, (last)r8.x
mad.f32 r6.x, r2.z, r29.z, (last)r6.x
mad.f32 r4.x, r2.z, r29.w, (last)r4.x
mad.f32 r16.y, r2.w, r28.y, (last)r16.y
mad.f32 r14.y, r2.w, r28.z, (last)r14.y
mad.f32 r12.y, r2.w, r28.w, (last)r12.y
mad.f32 r10.y, r2.w, r29.x, (last)r10.y
mad.f32 r8.y, r2.w, r29.y, (last)r8.y
mad.f32 r6.y, r2.w, r29.z, (last)r6.y
mad.f32 r4.y, r2.w, r29.w, (last)r4.y
mad.f32 r30.w, (last)r30.w, r30.x, (last)r26.z
mad.f32 r3.x, (last)r3.x, r30.x, (last)r27.w
(rpt1)mad.f32 r31.x, (r)(last)r31.x, r30.x, (r)(last)r26.w
mad.f32 r2.z, (last)r2.z, r30.x, (last)r27.y
ldl.u32 r26.z, l[r18.z+3584], 4
mad.f32 r2.w, (last)r2.w, r30.x, (last)r27.z
mad.f32 r17.x, r30.z, r28.y, (last)r17.x
mad.f32 r15.x, r30.z, r28.z, (last)r15.x
mad.f32 r13.x, r30.z, r28.w, (last)r13.x
mad.f32 r11.x, r30.z, r29.x, (last)r11.x
mad.f32 r9.x, r30.z, r29.y, (last)r9.x
mad.f32 r7.x, r30.z, r29.z, (last)r7.x
mad.f32 r5.x, r30.z, r29.w, (last)r5.x
mad.f32 r16.w, r3.y, r28.y, (last)r16.w
mad.f32 r14.w, r3.y, r28.z, (last)r14.w
mad.f32 r12.w, r3.y, r28.w, (last)r12.w
mad.f32 r10.w, r3.y, r29.x, (last)r10.w
mad.f32 r8.w, r3.y, r29.y, (last)r8.w
mad.f32 r6.w, r3.y, r29.z, (last)r6.w
mad.f32 r4.w, r3.y, r29.w, (last)r4.w
mad.f32 r17.y, r22.z, r18.w, (last)r17.y
mad.f32 r15.y, r22.z, r19.x, (last)r15.y
mad.f32 r13.y, r22.z, r19.y, (last)r13.y
mad.f32 r11.y, r22.z, r19.z, (last)r11.y
mad.f32 r9.y, r22.z, r19.w, (last)r9.y
mad.f32 r7.y, r22.z, r20.x, (last)r7.y
mad.f32 r5.y, r22.z, r20.y, (last)r5.y
mad.f32 r17.z, r22.w, r18.w, (last)r17.z
mad.f32 r15.z, r22.w, r19.x, (last)r15.z
mad.f32 r13.z, r22.w, r19.y, (last)r13.z
mad.f32 r16.z, r23.w, r18.w, (last)r16.z
mad.f32 r14.z, r23.w, r19.x, (last)r14.z
mad.f32 r12.z, r23.w, r19.y, (last)r12.z
mad.f32 r10.z, r23.w, r19.z, (last)r10.z
mad.f32 r8.z, r23.w, r19.w, (last)r8.z
mad.f32 r6.z, r23.w, r20.x, (last)r6.z
mad.f32 r4.z, r23.w, r20.y, (last)r4.z
mad.f32 r11.z, r22.w, r19.z, (last)r11.z
mad.f32 r9.z, r22.w, r19.w, (last)r9.z
mad.f32 r7.z, r22.w, r20.x, (last)r7.z
mad.f32 r5.z, r22.w, r20.y, (last)r5.z
mad.f32 r17.w, r23.x, r18.w, (last)r17.w
mad.f32 r15.w, r23.x, r19.x, (last)r15.w
mad.f32 r13.w, r23.x, r19.y, (last)r13.w
mad.f32 r11.w, r23.x, r19.z, (last)r11.w
mad.f32 r9.w, r23.x, r19.w, (last)r9.w
mad.f32 r7.w, r23.x, r20.x, (last)r7.w
mad.f32 r5.w, r23.x, r20.y, (last)r5.w
mad.f32 r16.x, r23.y, r18.w, (last)r16.x
mad.f32 r14.x, r23.y, r19.x, (last)r14.x
mad.f32 r12.x, r23.y, r19.y, (last)r12.x
mad.f32 r10.x, r23.y, r19.z, (last)r10.x
mad.f32 r8.x, r23.y, r19.w, (last)r8.x
mad.f32 r6.x, r23.y, r20.x, (last)r6.x
mad.f32 r4.x, r23.y, r20.y, (last)r4.x
mad.f32 r16.y, r23.z, r18.w, (last)r16.y
mad.f32 r14.y, r23.z, r19.x, (last)r14.y
mad.f32 r12.y, r23.z, r19.y, (last)r12.y
mad.f32 r10.y, r23.z, r19.z, (last)r10.y
mad.f32 r8.y, r23.z, r19.w, (last)r8.y
mad.f32 r6.y, r23.z, r20.x, (last)r6.y
mad.f32 r4.y, r23.z, r20.y, (last)r4.y
mad.f32 r30.z, (last)r30.z, r30.x, (last)r26.y
mad.f32 r3.y, (last)r3.y, r30.x, (last)r28.x
ldl.u32 r27.z, l[r18.z+3840], 4
ldl.u32 r28.z, l[r1.w+1024], 4
ldl.u32 r29.z, l[r1.w+1152], 4
mad.f32 r22.z, (last)r22.z, r20.z, (last)r30.w
mad.f32 r23.w, (last)r23.w, r20.z, (last)r3.x
(rpt1)mad.f32 r22.w, (r)(last)r22.w, r20.z, (r)(last)r31.x
ldl.u32 r30.w, l[r20.w], 4
(rpt1)mad.f32 r23.y, (r)(last)r23.y, r20.z, (r)(last)r2.z
ldl.u32 r2.y, l[r20.w+256], 4
mad.f32 r17.x, r22.y, r18.w, (last)r17.x
mad.f32 r15.x, r22.y, r19.x, (last)r15.x
mad.f32 r13.x, r22.y, r19.y, (last)r13.x
mad.f32 r11.x, r22.y, r19.z, (last)r11.x
mad.f32 r9.x, r22.y, r19.w, (last)r9.x
mad.f32 r7.x, r22.y, r20.x, (last)r7.x
mad.f32 r5.x, r22.y, r20.y, (last)r5.x
mad.f32 r22.y, (last)r22.y, r20.z, (last)r30.z
mad.f32 r16.w, r24.x, r18.w, (last)r16.w
mad.f32 r14.w, r24.x, r19.x, (last)r14.w
(ss)nop
ldl.u32 r18.x, l[r1.w+1280], 4
mad.f32 r12.w, r24.x, r19.y, (last)r12.w
mad.f32 r10.w, r24.x, r19.z, (last)r10.w
mad.f32 r8.w, r24.x, r19.w, (last)r8.w
ldl.u32 r19.x, l[r1.w+1408], 4
mad.f32 r17.y, r26.w, r24.y, (last)r17.y
mad.f32 r15.y, r26.w, r24.z, (last)r15.y
mad.f32 r13.y, r26.w, r24.w, (last)r13.y
mad.f32 r11.y, r26.w, r25.x, (last)r11.y
mad.f32 r9.y, r26.w, r25.y, (last)r9.y
mad.f32 r7.y, r26.w, r25.z, (last)r7.y
mad.f32 r5.y, r26.w, r25.w, (last)r5.y
mad.f32 r17.z, r27.x, r24.y, (last)r17.z
mad.f32 r15.z, r27.x, r24.z, (last)r15.z
mad.f32 r13.z, r27.x, r24.w, (last)r13.z
mad.f32 r11.z, r27.x, r25.x, (last)r11.z
mad.f32 r9.z, r27.x, r25.y, (last)r9.z
mad.f32 r7.z, r27.x, r25.z, (last)r7.z
mad.f32 r5.z, r27.x, r25.w, (last)r5.z
mad.f32 r17.w, r27.y, r24.y, (last)r17.w
mad.f32 r15.w, r27.y, r24.z, (last)r15.w
mad.f32 r13.w, r27.y, r24.w, (last)r13.w
mad.f32 r11.w, r27.y, r25.x, (last)r11.w
mad.f32 r9.w, r27.y, r25.y, (last)r9.w
mad.f32 r7.w, r27.y, r25.z, (last)r7.w
mad.f32 r5.w, r27.y, r25.w, (last)r5.w
mad.f32 r17.x, r26.z, r24.y, (last)r17.x
mad.f32 r15.x, r26.z, r24.z, (last)r15.x
mad.f32 r13.x, r26.z, r24.w, (last)r13.x
mad.f32 r11.x, r26.z, r25.x, (last)r11.x
mad.f32 r9.x, r26.z, r25.y, (last)r9.x
mad.f32 r7.x, r26.z, r25.z, (last)r7.x
mad.f32 r5.x, r26.z, r25.w, (last)r5.x
mad.f32 r26.w, (last)r26.w, r26.x, (last)r22.z
(rpt1)mad.f32 r27.x, (r)(last)r27.x, r26.x, (r)(last)r22.w
mad.f32 r26.z, (last)r26.z, r26.x, (last)r22.y
ldl.u32 r22.y, l[r21.x], 4
mad.f32 r6.w, r24.x, r20.x, (last)r6.w
mad.f32 r4.w, r24.x, r20.y, (last)r4.w
mad.f32 r24.x, (last)r24.x, r20.z, (last)r3.y
mad.f32 r16.x, r27.z, r24.y, (last)r16.x
mad.f32 r14.x, r27.z, r24.z, (last)r14.x
mad.f32 r12.x, r27.z, r24.w, (last)r12.x
mad.f32 r10.x, r27.z, r25.x, (last)r10.x
mad.f32 r8.x, r27.z, r25.y, (last)r8.x
mad.f32 r6.x, r27.z, r25.z, (last)r6.x
mad.f32 r4.x, r27.z, r25.w, (last)r4.x
mad.f32 r16.y, r27.w, r24.y, (last)r16.y
mad.f32 r14.y, r27.w, r24.z, (last)r14.y
mad.f32 r12.y, r27.w, r24.w, (last)r12.y
mad.f32 r10.y, r27.w, r25.x, (last)r10.y
mad.f32 r8.y, r27.w, r25.y, (last)r8.y
mad.f32 r6.y, r27.w, r25.z, (last)r6.y
mad.f32 r4.y, r27.w, r25.w, (last)r4.y
mad.f32 r16.z, r28.x, r24.y, (last)r16.z
mad.f32 r14.z, r28.x, r24.z, (last)r14.z
mad.f32 r12.z, r28.x, r24.w, (last)r12.z
mad.f32 r10.z, r28.x, r25.x, (last)r10.z
mad.f32 r8.z, r28.x, r25.y, (last)r8.z
mad.f32 r6.z, r28.x, r25.z, (last)r6.z
mad.f32 r4.z, r28.x, r25.w, (last)r4.z
mad.f32 r16.w, r28.y, r24.y, (last)r16.w
mad.f32 r14.w, r28.y, r24.z, (last)r14.w
mad.f32 r12.w, r28.y, r24.w, (last)r12.w
mad.f32 r10.w, r28.y, r25.x, (last)r10.w
mad.f32 r8.w, r28.y, r25.y, (last)r8.w
mad.f32 r17.y, r31.x, r28.z, (last)r17.y
mad.f32 r15.y, r31.x, r28.w, (last)r15.y
mad.f32 r13.y, r31.x, r29.x, (last)r13.y
mad.f32 r11.y, r31.x, r29.y, (last)r11.y
mad.f32 r9.y, r31.x, r29.z, (last)r9.y
mad.f32 r7.y, r31.x, r29.w, (last)r7.y
mad.f32 r5.y, r31.x, r30.x, (last)r5.y
mad.f32 r17.z, r31.y, r28.z, (last)r17.z
mad.f32 r15.z, r31.y, r28.w, (last)r15.z
mad.f32 r13.z, r31.y, r29.x, (last)r13.z
mad.f32 r11.z, r31.y, r29.y, (last)r11.z
mad.f32 r9.z, r31.y, r29.z, (last)r9.z
mad.f32 r7.z, r31.y, r29.w, (last)r7.z
mad.f32 r5.z, r31.y, r30.x, (last)r5.z
mad.f32 r17.w, r31.z, r28.z, (last)r17.w
mad.f32 r15.w, r31.z, r28.w, (last)r15.w
mad.f32 r13.w, r31.z, r29.x, (last)r13.w
mad.f32 r11.w, r31.z, r29.y, (last)r11.w
mad.f32 r9.w, r31.z, r29.z, (last)r9.w
mad.f32 r7.w, r31.z, r29.w, (last)r7.w
mad.f32 r5.w, r31.z, r30.x, (last)r5.w
mad.f32 r17.x, r30.w, r28.z, (last)r17.x
mad.f32 r15.x, r30.w, r28.w, (last)r15.x
mad.f32 r13.x, r30.w, r29.x, (last)r13.x
mad.f32 r11.x, r30.w, r29.y, (last)r11.x
mad.f32 r9.x, r30.w, r29.z, (last)r9.x
mad.f32 r7.x, r30.w, r29.w, (last)r7.x
mad.f32 r5.x, r30.w, r30.x, (last)r5.x
mad.f32 r6.w, r28.y, r25.z, (last)r6.w
mad.f32 r4.w, r28.y, r25.w, (last)r4.w
(rpt1)mad.f32 r27.z, (r)(last)r27.z, r26.x, (r)(last)r23.y
mad.f32 r28.x, (last)r28.x, r26.x, (last)r23.w
mad.f32 r31.x, (last)r31.x, r30.y, (last)r26.w
(rpt1)mad.f32 r31.y, (r)(last)r31.y, r30.y, (r)(last)r27.x
mad.f32 r30.w, (last)r30.w, r30.y, (last)r26.z
mad.f32 r28.y, (last)r28.y, r26.x, (last)r24.x
ldl.u32 r23.z, l[r21.x+256], 4
ldl.u32 r24.z, l[r1.w+1536], 4
ldl.u32 r25.z, l[r1.w+1664], 4
ldl.u32 r26.z, l[r21.y], 4
mad.f32 r16.x, r2.y, r28.z, (last)r16.x
mad.f32 r14.x, r2.y, r28.w, (last)r14.x
mad.f32 r12.x, r2.y, r29.x, (last)r12.x
mad.f32 r10.x, r2.y, r29.y, (last)r10.x
mad.f32 r8.x, r2.y, r29.z, (last)r8.x
mad.f32 r6.x, r2.y, r29.w, (last)r6.x
mad.f32 r4.x, r2.y, r30.x, (last)r4.x
mad.f32 r16.y, r2.z, r28.z, (last)r16.y
mad.f32 r14.y, r2.z, r28.w, (last)r14.y
mad.f32 r12.y, r2.z, r29.x, (last)r12.y
mad.f32 r10.y, r2.z, r29.y, (last)r10.y
mad.f32 r8.y, r2.z, r29.z, (last)r8.y
mad.f32 r6.y, r2.z, r29.w, (last)r6.y
mad.f32 r4.y, r2.z, r30.x, (last)r4.y
mad.f32 r16.z, r2.w, r28.z, (last)r16.z
mad.f32 r14.z, r2.w, r28.w, (last)r14.z
mad.f32 r12.z, r2.w, r29.x, (last)r12.z
mad.f32 r10.z, r2.w, r29.y, (last)r10.z
mad.f32 r8.z, r2.w, r29.z, (last)r8.z
mad.f32 r6.z, r2.w, r29.w, (last)r6.z
mad.f32 r4.z, r2.w, r30.x, (last)r4.z
mad.f32 r16.w, r3.x, r28.z, (last)r16.w
mad.f32 r14.w, r3.x, r28.w, (last)r14.w
mad.f32 r12.w, r3.x, r29.x, (last)r12.w
mad.f32 r10.w, r3.x, r29.y, (last)r10.w
mad.f32 r8.w, r3.x, r29.z, (last)r8.w
(ss)mad.f32 r17.y, r22.z, r18.x, (last)r17.y
mad.f32 r15.y, r22.z, r18.y, (last)r15.y
mad.f32 r13.y, r22.z, r18.z, (last)r13.y
mad.f32 r11.y, r22.z, r18.w, (last)r11.y
mad.f32 r9.y, r22.z, r19.x, (last)r9.y
mad.f32 r7.y, r22.z, r19.y, (last)r7.y
mad.f32 r5.y, r22.z, r19.z, (last)r5.y
mad.f32 r17.z, r22.w, r18.x, (last)r17.z
mad.f32 r15.z, r22.w, r18.y, (last)r15.z
mad.f32 r13.z, r22.w, r18.z, (last)r13.z
mad.f32 r11.z, r22.w, r18.w, (last)r11.z
mad.f32 r9.z, r22.w, r19.x, (last)r9.z
mad.f32 r7.z, r22.w, r19.y, (last)r7.z
mad.f32 r5.z, r22.w, r19.z, (last)r5.z
mad.f32 r17.w, r23.x, r18.x, (last)r17.w
mad.f32 r15.w, r23.x, r18.y, (last)r15.w
mad.f32 r13.w, r23.x, r18.z, (last)r13.w
mad.f32 r11.w, r23.x, r18.w, (last)r11.w
mad.f32 r9.w, r23.x, r19.x, (last)r9.w
mad.f32 r7.w, r23.x, r19.y, (last)r7.w
mad.f32 r5.w, r23.x, r19.z, (last)r5.w
mad.f32 r17.x, r22.y, r18.x, (last)r17.x
mad.f32 r15.x, r22.y, r18.y, (last)r15.x
mad.f32 r13.x, r22.y, r18.z, (last)r13.x
mad.f32 r11.x, r22.y, r18.w, (last)r11.x
mad.f32 r9.x, r22.y, r19.x, (last)r9.x
mad.f32 r7.x, r22.y, r19.y, (last)r7.x
mad.f32 r5.x, r22.y, r19.z, (last)r5.x
mad.f32 r6.w, r3.x, r29.w, (last)r6.w
mad.f32 r4.w, r3.x, r30.x, (last)r4.w
(rpt1)mad.f32 r2.y, (r)(last)r2.y, r30.y, (r)(last)r27.z
mad.f32 r2.w, (last)r2.w, r30.y, (last)r28.x
mad.f32 r22.z, (last)r22.z, r19.w, (last)r31.x
(rpt1)mad.f32 r22.w, (r)(last)r22.w, r19.w, (r)(last)r31.y
mad.f32 r22.y, (last)r22.y, r19.w, (last)r30.w
mad.f32 r3.x, (last)r3.x, r30.y, (last)r28.y
ldl.u32 r27.w, l[r21.y+256], 4
ldl.u32 r28.w, l[r1.w+1792], 4
ldl.u32 r29.w, l[r1.w+1920], 4
ldl.u32 r30.w, l[r21.z], 4
mad.f32 r16.x, r23.z, r18.x, (last)r16.x
mad.f32 r14.x, r23.z, r18.y, (last)r14.x
mad.f32 r12.x, r23.z, r18.z, (last)r12.x
mad.f32 r10.x, r23.z, r18.w, (last)r10.x
mad.f32 r8.x, r23.z, r19.x, (last)r8.x
mad.f32 r6.x, r23.z, r19.y, (last)r6.x
mad.f32 r4.x, r23.z, r19.z, (last)r4.x
mad.f32 r16.y, r23.w, r18.x, (last)r16.y
mad.f32 r14.y, r23.w, r18.y, (last)r14.y
mad.f32 r12.y, r23.w, r18.z, (last)r12.y
(ss)nop
ldl.u32 r20.z, l[r21.z+256], 4
mad.f32 r10.y, r23.w, r18.w, (last)r10.y
mad.f32 r8.y, r23.w, r19.x, (last)r8.y
mad.f32 r6.y, r23.w, r19.y, (last)r6.y
mad.f32 r4.y, r23.w, r19.z, (last)r4.y
mad.f32 r16.z, r24.x, r18.x, (last)r16.z
mad.f32 r14.z, r24.x, r18.y, (last)r14.z
mad.f32 r12.z, r24.x, r18.z, (last)r12.z
mad.f32 r10.z, r24.x, r18.w, (last)r10.z
mad.f32 r8.z, r24.x, r19.x, (last)r8.z
mad.f32 r6.z, r24.x, r19.y, (last)r6.z
mad.f32 r4.z, r24.x, r19.z, (last)r4.z
mad.f32 r16.w, r24.y, r18.x, (last)r16.w
mad.f32 r14.w, r24.y, r18.y, (last)r14.w
mad.f32 r12.w, r24.y, r18.z, (last)r12.w
mad.f32 r10.w, r24.y, r18.w, (last)r10.w
mad.f32 r8.w, r24.y, r19.x, (last)r8.w
mad.f32 r6.w, r24.y, r19.y, (last)r6.w
mad.f32 r4.w, r24.y, r19.z, (last)r4.w
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r19.w, (r)(last)r2.y
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r19.w, (r)(last)r2.w
mad.f32 r17.y, r26.w, r24.z, (last)r17.y
mad.f32 r15.y, r26.w, r24.w, (last)r15.y
mad.f32 r13.y, r26.w, r25.x, (last)r13.y
mad.f32 r11.y, r26.w, r25.y, (last)r11.y
mad.f32 r9.y, r26.w, r25.z, (last)r9.y
mad.f32 r7.y, r26.w, r25.w, (last)r7.y
mad.f32 r5.y, r26.w, r26.x, (last)r5.y
mad.f32 r17.z, r27.x, r24.z, (last)r17.z
mad.f32 r15.z, r27.x, r24.w, (last)r15.z
mad.f32 r13.z, r27.x, r25.x, (last)r13.z
mad.f32 r11.z, r27.x, r25.y, (last)r11.z
mad.f32 r9.z, r27.x, r25.z, (last)r9.z
mad.f32 r7.z, r27.x, r25.w, (last)r7.z
mad.f32 r5.z, r27.x, r26.x, (last)r5.z
mad.f32 r17.w, r27.y, r24.z, (last)r17.w
mad.f32 r15.w, r27.y, r24.w, (last)r15.w
mad.f32 r13.w, r27.y, r25.x, (last)r13.w
mad.f32 r11.w, r27.y, r25.y, (last)r11.w
mad.f32 r9.w, r27.y, r25.z, (last)r9.w
mad.f32 r7.w, r27.y, r25.w, (last)r7.w
mad.f32 r5.w, r27.y, r26.x, (last)r5.w
mad.f32 r17.x, r26.z, r24.z, (last)r17.x
mad.f32 r15.x, r26.z, r24.w, (last)r15.x
mad.f32 r13.x, r26.z, r25.x, (last)r13.x
mad.f32 r11.x, r26.z, r25.y, (last)r11.x
mad.f32 r9.x, r26.z, r25.z, (last)r9.x
mad.f32 r7.x, r26.z, r25.w, (last)r7.x
mad.f32 r5.x, r26.z, r26.x, (last)r5.x
mad.f32 r16.x, r27.w, r24.z, (last)r16.x
mad.f32 r14.x, r27.w, r24.w, (last)r14.x
mad.f32 r12.x, r27.w, r25.x, (last)r12.x
mad.f32 r10.x, r27.w, r25.y, (last)r10.x
mad.f32 r8.x, r27.w, r25.z, (last)r8.x
mad.f32 r6.x, r27.w, r25.w, (last)r6.x
mad.f32 r4.x, r27.w, r26.x, (last)r4.x
mad.f32 r16.y, r28.x, r24.z, (last)r16.y
mad.f32 r14.y, r28.x, r24.w, (last)r14.y
mad.f32 r12.y, r28.x, r25.x, (last)r12.y
mad.f32 r10.y, r28.x, r25.y, (last)r10.y
mad.f32 r8.y, r28.x, r25.z, (last)r8.y
mad.f32 r6.y, r28.x, r25.w, (last)r6.y
mad.f32 r4.y, r28.x, r26.x, (last)r4.y
mad.f32 r16.z, r28.y, r24.z, (last)r16.z
mad.f32 r14.z, r28.y, r24.w, (last)r14.z
mad.f32 r12.z, r28.y, r25.x, (last)r12.z
mad.f32 r10.z, r28.y, r25.y, (last)r10.z
mad.f32 r8.z, r28.y, r25.z, (last)r8.z
mad.f32 r6.z, r28.y, r25.w, (last)r6.z
mad.f32 r4.z, r28.y, r26.x, (last)r4.z
mad.f32 r16.w, r28.z, r24.z, (last)r16.w
mad.f32 r14.w, r28.z, r24.w, (last)r14.w
mad.f32 r12.w, r28.z, r25.x, (last)r12.w
mad.f32 r10.w, r28.z, r25.y, (last)r10.w
mad.f32 r8.w, r28.z, r25.z, (last)r8.w
mad.f32 r6.w, r28.z, r25.w, (last)r6.w
mad.f32 r4.w, r28.z, r26.x, (last)r4.w
mad.f32 r26.w, (last)r26.w, r26.y, (last)r22.z
(rpt1)mad.f32 r27.x, (r)(last)r27.x, r26.y, (r)(last)r22.w
mad.f32 r26.z, (last)r26.z, r26.y, (last)r22.y
(rpt1)mad.f32 r27.w, (r)(last)r27.w, r26.y, (r)(last)r23.z
(rpt1)mad.f32 r28.y, (r)(last)r28.y, r26.y, (r)(last)r24.x
mad.f32 r17.y, r31.x, r28.w, (last)r17.y
mad.f32 r15.y, r31.x, r29.x, (last)r15.y
mad.f32 r13.y, r31.x, r29.y, (last)r13.y
mad.f32 r11.y, r31.x, r29.z, (last)r11.y
mad.f32 r9.y, r31.x, r29.w, (last)r9.y
mad.f32 r7.y, r31.x, r30.x, (last)r7.y
mad.f32 r5.y, r31.x, r30.y, (last)r5.y
mad.f32 r17.z, r31.y, r28.w, (last)r17.z
mad.f32 r15.z, r31.y, r29.x, (last)r15.z
mad.f32 r13.z, r31.y, r29.y, (last)r13.z
mad.f32 r11.z, r31.y, r29.z, (last)r11.z
mad.f32 r9.z, r31.y, r29.w, (last)r9.z
mad.f32 r7.z, r31.y, r30.x, (last)r7.z
mad.f32 r5.z, r31.y, r30.y, (last)r5.z
mad.f32 r17.w, r31.z, r28.w, (last)r17.w
mad.f32 r15.w, r31.z, r29.x, (last)r15.w
mad.f32 r13.w, r31.z, r29.y, (last)r13.w
mad.f32 r11.w, r31.z, r29.z, (last)r11.w
mad.f32 r9.w, r31.z, r29.w, (last)r9.w
mad.f32 r7.w, r31.z, r30.x, (last)r7.w
mad.f32 r5.w, r31.z, r30.y, (last)r5.w
mad.f32 r17.x, r30.w, r28.w, (last)r17.x
mad.f32 r15.x, r30.w, r29.x, (last)r15.x
mad.f32 r13.x, r30.w, r29.y, (last)r13.x
mad.f32 r11.x, r30.w, r29.z, (last)r11.x
mad.f32 r9.x, r30.w, r29.w, (last)r9.x
mad.f32 r7.x, r30.w, r30.x, (last)r7.x
mad.f32 r5.x, r30.w, r30.y, (last)r5.x
(ss)mad.f32 r16.x, r20.z, r28.w, (last)r16.x
mad.f32 r14.x, r20.z, r29.x, (last)r14.x
mad.f32 r12.x, r20.z, r29.y, (last)r12.x
mad.f32 r10.x, r20.z, r29.z, (last)r10.x
mad.f32 r8.x, r20.z, r29.w, (last)r8.x
mad.f32 r6.x, r20.z, r30.x, (last)r6.x
mad.f32 r4.x, r20.z, r30.y, (last)r4.x
mad.f32 r16.y, r20.w, r28.w, (last)r16.y
mad.f32 r14.y, r20.w, r29.x, (last)r14.y
mad.f32 r12.y, r20.w, r29.y, (last)r12.y
mad.f32 r10.y, r20.w, r29.z, (last)r10.y
mad.f32 r8.y, r20.w, r29.w, (last)r8.y
mad.f32 r6.y, r20.w, r30.x, (last)r6.y
mad.f32 r4.y, r20.w, r30.y, (last)r4.y
mad.f32 r16.z, r21.x, r28.w, (last)r16.z
mad.f32 r14.z, r21.x, r29.x, (last)r14.z
mad.f32 r12.z, r21.x, r29.y, (last)r12.z
mad.f32 r10.z, r21.x, r29.z, (last)r10.z
mad.f32 r8.z, r21.x, r29.w, (last)r8.z
mad.f32 r6.z, r21.x, r30.x, (last)r6.z
mad.f32 r4.z, r21.x, r30.y, (last)r4.z
mad.f32 r16.w, r21.y, r28.w, (last)r16.w
mad.f32 r14.w, r21.y, r29.x, (last)r14.w
mad.f32 r12.w, r21.y, r29.y, (last)r12.w
mad.f32 r10.w, r21.y, r29.z, (last)r10.w
mad.f32 r8.w, r21.y, r29.w, (last)r8.w
mad.f32 r6.w, r21.y, r30.x, (last)r6.w
mad.f32 r4.w, r21.y, r30.y, (last)r4.w
mad.f32 r3.y, (last)r31.x, r30.z, (last)r26.w
(rpt1)mad.f32 r3.z, (r)(last)r31.y, r30.z, (r)(last)r27.x
mad.f32 r3.x, (last)r30.w, r30.z, (last)r26.z
(rpt1)mad.f32 r21.z, (r)(last)r20.z, r30.z, (r)(last)r27.w
(rpt1)mad.f32 r22.y, (r)(last)r21.x, r30.z, (r)(last)r28.y
fence.r.w
(sy)(ss)mov.u32u32 r24.z, (last)r1.x
mov.u32u32 r24.w, (last)r1.y
mov.u32u32 r25.x, (last)r1.z
mov.u32u32 r25.y, (last)r1.w
mov.u32u32 r24.x, (last)r0.x
mov.u32u32 r24.y, (last)r0.w
cov.f32f16 hr0.w, r17.y
cov.f32f16 hr4.y, r15.y
cov.f32f16 hr5.y, r13.y
cov.f32f16 hr36.y, r11.y
cov.f32f16 hr37.y, r9.y
cov.f32f16 hr38.y, r7.y
cov.f32f16 hr39.y, r5.y
cov.f32f16 hr1.x, r17.z
cov.f32f16 hr4.z, r15.z
cov.f32f16 hr5.z, r13.z
cov.f32f16 hr36.z, r11.z
cov.f32f16 hr37.z, r9.z
cov.f32f16 hr38.z, r7.z
cov.f32f16 hr39.z, r5.z
cov.f32f16 hr1.y, r17.w
cov.f32f16 hr4.w, r15.w
cov.f32f16 hr5.w, r13.w
cov.f32f16 hr36.w, r11.w
cov.f32f16 hr37.w, r9.w
cov.f32f16 hr38.w, r7.w
cov.f32f16 hr39.w, r5.w
cov.f32f16 hr0.z, r17.x
cov.f32f16 hr4.x, r15.x
cov.f32f16 hr5.x, r13.x
cov.f32f16 hr36.x, r11.x
cov.f32f16 hr37.x, r9.x
cov.f32f16 hr38.x, r7.x
cov.f32f16 hr39.x, r5.x
cov.f32f16 hr45.z, r16.x
cov.f32f16 hr46.z, r14.x
cov.f32f16 hr46.w, r8.x
cov.f32f16 hr47.x, r6.x
cov.f32f16 hr45.w, r16.y
cov.f32f16 hr47.y, r6.y
cov.f32f16 hr46.x, r4.y
(rpt1)cov.f32f16 hr47.z, (r)r16.z
cov.f32f16 hr40.y, r3.y
(rpt1)cov.f32f16 hr40.z, (r)r3.z
cov.f32f16 hr40.x, r3.x
mov.u32u32 r25.z, (last)r3.x
cov.f32f16 hr41.x, r12.x
cov.f32f16 hr41.y, r4.x
cov.f32f16 hr46.y, r21.w
cov.f32f16 hr41.z, r21.z
cov.f32f16 hr41.w, r14.y
cov.f32f16 hr42.x, r10.x
cov.f32f16 hr42.y, r12.y
cov.f32f16 hr42.z, r10.y
cov.f32f16 hr42.w, r8.y
bar.g
(sy)(ss)(rpt1)cov.f32f16 hr2.x, (r)r10.z
(rpt1)cov.f32f16 hr2.z, (r)r8.z
(rpt1)cov.f32f16 hr3.x, (r)r6.z
cov.f32f16 hr3.z, r4.z
cov.f32f16 hr3.w, r22.y
(rpt1)cov.f32f16 hr0.x, (r)r14.z
(rpt1)cov.f32f16 hr1.z, (r)r12.z
cov.f32f16 hr6.x, r4.w
cov.f32f16 hr6.y, r22.z
br p0.x, #l738
mov.u32u32 r2.x, (last)r21.z
mov.u32u32 r2.y, (last)r21.w
mov.u32u32 r3.x, (last)r25.z
mov.u32u32 r2.w, (last)r22.z
mov.u32u32 r2.z, (last)r22.y
mov.u32u32 r0.x, (last)r24.x
mov.u32u32 r0.w, (last)r24.y
mov.u32u32 r1.x, (last)r24.z
mov.u32u32 r1.y, r24.w
mov.u32u32 r1.z, (last)r25.x
mov.u32u32 r1.w, (last)r25.y
jump #l104
l738:
(jp)(eolm)nop
add.u r22.x, r53.z, (last)r22.x
mov.u16u16 hr6.z, (last)hr45.z
mov.u16u16 hr6.w, (last)hr45.w
mov.u16u16 hr7.x, (last)hr47.z
shl.b r22.x, (last)r22.x, 9
mov.u16u16 hr7.y, (last)hr47.w
mov.u16u16 hr9.z, (last)hr46.z
mov.u16u16 hr9.w, (last)hr41.w
sad.s32 r22.x, r54.z, r22.x, (last)r24.w
mov.u16u16 hr10.x, (last)hr0.x
mov.u16u16 hr10.y, (last)hr0.y
nop
(nop3) shl.b r22.x, (last)r22.x, 2
add.u r3.w, r22.x, c1.x
add.u r4.x, r22.x, c2.y
add.u r4.y, r22.x, c2.x
stib.b.untyped.1d.u16.4.imm.base0 hr0.z, r22.x, 4
add.u r4.z, r22.x, c2.z
(ss)mov.u16u16 hr1.x, (last)hr41.x
mov.u16u16 hr1.y, (last)hr42.y
(rpt1)add.u r5.y, r22.x, (r)c2.w
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r22.x+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r3.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r4.x, 4
add.u r5.w, r22.x, c3.y
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r4.y, 4
add.u r6.x, r22.x, c3.z
(rpt1)add.u r6.y, r22.x, (r)c3.w
stib.b.untyped.1d.u16.4.imm.base0 hr1.x, r4.z, 4
(ss)mov.u16u16 hr1.z, (last)hr42.x
mov.u16u16 hr1.w, (last)hr42.z
stib.b.untyped.1d.u16.4.imm.base0 hr36.x, r5.y, 4
(rpt1)add.u r6.w, r22.x, (r)c4.y
mov.u16u16 hr5.y, (last)hr41.y
mov.u16u16 hr5.z, (last)hr46.x
mov.u16u16 hr5.w, (last)hr3.z
add.u r7.y, r22.x, c4.w
stib.b.untyped.1d.u16.4.imm.base0 hr1.z, r5.z, 4
(ss)mov.u16u16 hr2.x, (last)hr46.w
mov.u16u16 hr2.y, (last)hr42.w
stib.b.untyped.1d.u16.4.imm.base0 hr37.x, r5.w, 4
(nop3) add.u r7.z, (last)r22.x, c5.x
(rpt1)nop
stib.b.untyped.1d.u16.4.imm.base0 hr2.x, r6.x, 4
(ss)mov.u16u16 hr2.z, (last)hr47.x
mov.u16u16 hr2.w, (last)hr47.y
stib.b.untyped.1d.u16.4.imm.base0 hr38.x, r6.y, 4
(rpt5)nop
stib.b.untyped.1d.u16.4.imm.base0 hr2.z, r6.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr39.x, r6.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr5.y, r7.x, 4
(ss)mov.u16u16 hr5.z, (last)hr41.z
mov.u16u16 hr5.w, (last)hr46.y
mov.u16u16 hr6.x, (last)hr3.w
stib.b.untyped.1d.u16.4.imm.base0 hr40.x, r7.y, 4
(rpt5)nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r7.z, 4
end
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 826 instr, 26 nops, 800 non-nops, 105 mov, 64 cov, 1602 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 32 full, 8 constlen
; CL prog 23/1: 29 cat0, 169 cat1, 54 cat2, 516 cat3, 0 cat4, 3 cat5, 51 cat6, 4 cat7
; CL prog 23/1: 10 sstall, 16 (ss), 39 systall, 5 (sy), 1 loops
; CL prog 23/1: 8 max_waves, 0 double_threadsize
; 31 preamble-instr, 1 early-preamble
