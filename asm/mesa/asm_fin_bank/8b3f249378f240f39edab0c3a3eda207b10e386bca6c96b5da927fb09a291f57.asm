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
@const(c1.x)	0x00000800, 0x00001000, 0x00001f00, 0x00001e00
@const(c2.x)	0x00001d00, 0x00001c00, 0x00001b00, 0x00001a00
@const(c3.x)	0x00001900, 0x00001800, 0x00001700, 0x00001600
@const(c4.x)	0x00001500, 0x00001400, 0x00001300, 0x00001200
@const(c5.x)	0x00001100, 0x00001080, 0x00000820, 0x00001020
@const(c6.x)	0x00001820, 0x00010000, 0x00010020, 0x00010800
@const(c7.x)	0x00010820, 0x00011000, 0x00011020, 0x00011800
@const(c8.x)	0x00011820, 0xd0d0d0d0, 0xd0d0d0d0, 0xd0d0d0d0
shps #l46
getone #l46
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 4096
mov.u32u32 r49.y, 0x1f00
mov.u32u32 r49.z, 0x1e00
mov.u32u32 r49.w, 0x1d00
mov.u32u32 r50.x, 0x1c00
mov.u32u32 r50.y, 0x1b00
mov.u32u32 r50.z, 0x1a00
mov.u32u32 r50.w, 0x1900
mov.u32u32 r51.x, 0x1800
mov.u32u32 r51.y, 0x1700
mov.u32u32 r51.z, 0x1600
mov.u32u32 r51.w, 0x1500
mov.u32u32 r52.x, 0x1400
mov.u32u32 r52.y, 0x1300
mov.u32u32 r52.z, 0x1200
mov.u32u32 r52.w, 0x1100
mov.u32u32 r53.x, 0x1080
mov.u32u32 r53.y, 2080
mov.u32u32 r53.z, 0x1020
mov.u32u32 r53.w, 0x1820
mov.u32u32 r54.x, 0x10000
mov.u32u32 r54.y, 0x10020
mov.u32u32 r54.z, 0x10800
mov.u32u32 r54.w, 0x10820
mov.u32u32 r55.x, 0x11000
mov.u32u32 r55.y, 0x11020
mov.u32u32 r55.z, 0x11800
mov.u32u32 r55.w, 0x11820
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 4
stc.u32 c[20], r52.w, 4
stc.u32 c[24], r53.w, 4
stc.u32 c[28], r54.w, 4
stc.u32 c[32], r55.w, 1
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l46:
(jp)(rpt1)add.u r48.z, (r)r48.x, (r)c0.x
mov.u32u32 r49.z, 0
shl.b r49.y, r48.z, 6
shl.b r49.x, r48.w, 6
shr.b r0.w, r0.x, 4
and.b r1.x, r0.x, 15
shr.b r1.z, r0.x, 3
and.b r1.y, r0.x, 7
mov.u32u32 r1.w, 0
mov.u32u32 r2.x, 0
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
mov.u32u32 r2.y, 0
l118:
(rpt1)shr.b r49.w, (r)r49.x, 2
(rpt2)nop
add.u r18.z, r0.x, 64
add.u r18.w, r0.x, 128
add.u r19.x, r0.x, 192
shl.b r17.w, r0.w, 8
(rpt1)shr.b r18.z, (last)(r)r18.z, 4
(ss)add.u r19.z, r49.z, r0.w
shr.b r19.x, (last)r19.x, 4
(rpt1)add.u r21.y, r49.z, (r)r18.z
shl.b r19.z, (last)r19.z, 9
add.u r21.w, r49.z, r19.x
add.u r49.z, r49.z, 16
cmps.u.ge up0.x, r49.z, c1.x
(rpt1)shl.b r21.y, (last)(r)r21.y, 9
sad.s32 r19.w, r49.w, r19.z, r1.x
shl.b r21.w, (last)r21.w, 9
(rpt1)sad.s32 r22.x, r49.w, (r)r21.y, r1.x
shl.b r19.w, (last)r19.w, 2
shl.b r18.x, r1.x, 4
(rpt1)shl.b r23.x, (last)(r)r22.x, 2
(rpt1)shl.b r18.z, (last)(r)r18.z, 8
sad.s32 r20.x, r50.x, r19.z, r1.x
isam.v.base0 (u32)(xyzw)r20.y, r19.w, s#0, t#0
sad.s32 r22.w, r50.x, r21.y, r1.x
sad.s32 r22.z, r49.w, r21.w, r1.x
isam.v.base0 (u32)(xyzw)r27.y, r23.x, s#0, t#0
sad.s32 r21.z, r50.x, r21.z, r1.x
isam.v.base0 (u32)(xyzw)r30.y, r23.y, s#0, t#0
sad.s32 r21.w, r50.x, r21.w, r1.x
add.u r19.y, r17.w, r18.x
(rpt1)add.u r24.x, (r)r18.z, r18.x
shl.b r20.x, (last)r20.x, 2
shl.b r23.w, (last)r22.w, 2
shl.b r23.z, (last)r22.z, 2
(rpt1)shl.b r21.z, (last)(r)r21.z, 2
shl.b r19.x, (last)r19.x, 8
shl.b r24.w, r1.z, 4
sad.s32 r17.w, c1.y, r17.w, r18.x
(rpt1)sad.s32 r18.z, c1.y, (r)r18.z, r18.x
add.u r24.z, r19.x, r18.x
sad.s32 r19.x, c1.y, r19.x, (last)r18.x
shl.b r18.y, r1.y, 4
(nop2) shl.b r25.x, r1.z, 2
add.u r25.y, c1.y, r18.y
add.u r25.z, c5.y, r18.y
add.u r25.w, c5.x, r18.y
add.u r26.x, c4.w, r18.y
add.u r26.y, c4.z, r18.y
add.u r26.z, c4.y, r18.y
add.u r26.w, c4.x, r18.y
add.u r27.x, c3.w, r18.y
add.u r28.y, c3.z, r18.y
add.u r28.z, c3.y, r18.y
add.u r28.w, c3.x, r18.y
add.u r29.x, c2.w, r18.y
add.u r29.y, c2.z, r18.y
add.u r29.z, c2.y, r18.y
add.u r29.w, c2.x, r18.y
add.u r30.x, c1.w, r18.y
add.u r18.y, c1.z, (last)r18.y
(sy)stl.u32 l[r19.y], r20.y, 4
(ss)nop
isam.v.base0 (u32)(xyzw)r20.y, r23.z, s#0, t#0
isam.v.base0 (u32)(xyzw)r22.x, r20.x, s#0, t#2
(ss)nop
isam.v.base0 (u32)(xyzw)r23.x, r23.w, s#0, t#2
stl.u32 l[r24.x], r27.y, 4
(ss)nop
isam.v.base0 (u32)(xyzw)r27.y, r21.z, s#0, t#2
stl.u32 l[r24.y], r30.y, 4
(ss)nop
isam.v.base0 (u32)(xyzw)r30.y, r21.w, s#0, t#2
(sy)stl.u32 l[r24.z], r20.y, 4
stl.u32 l[r17.w], r22.x, 4
stl.u32 l[r18.z], r23.x, 4
stl.u32 l[r18.w], r27.y, 4
stl.u32 l[r19.x], r30.y, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
ldl.u32 r18.z, l[r24.w], 4
ldl.u32 r19.z, l[r24.w+128], 4
ldl.u32 r20.z, l[r25.y], 4
ldl.u32 r21.z, l[r25.z], 4
ldl.u32 r22.z, l[r24.w+256], 4
ldl.u32 r23.z, l[r24.w+384], 4
ldl.u32 r27.y, l[r25.w], 4
ldl.u32 r30.y, l[r25.w+128], 4
(ss)mad.f32 r16.w, r20.z, r18.z, (last)r16.w
mad.f32 r14.w, r20.z, r18.w, (last)r14.w
mad.f32 r12.w, r20.z, r19.x, (last)r12.w
mad.f32 r10.w, r20.z, r19.y, (last)r10.w
mad.f32 r8.w, r20.z, r19.z, (last)r8.w
mad.f32 r6.w, r20.z, r19.w, (last)r6.w
mad.f32 r4.w, r20.z, r20.x, (last)r4.w
mad.f32 r17.x, r20.w, r18.z, (last)r17.x
mad.f32 r15.x, r20.w, r18.w, (last)r15.x
mad.f32 r13.x, r20.w, r19.x, (last)r13.x
mad.f32 r11.x, r20.w, r19.y, (last)r11.x
mad.f32 r9.x, r20.w, r19.z, (last)r9.x
mad.f32 r7.x, r20.w, r19.w, (last)r7.x
mad.f32 r5.x, r20.w, r20.x, (last)r5.x
mad.f32 r17.y, r21.x, r18.z, (last)r17.y
mad.f32 r15.y, r21.x, r18.w, (last)r15.y
mad.f32 r13.y, r21.x, r19.x, (last)r13.y
mad.f32 r11.y, r21.x, r19.y, (last)r11.y
mad.f32 r9.y, r21.x, r19.z, (last)r9.y
mad.f32 r7.y, r21.x, r19.w, (last)r7.y
mad.f32 r5.y, r21.x, r20.x, (last)r5.y
mad.f32 r17.z, r21.y, r18.z, (last)r17.z
mad.f32 r15.z, r21.y, r18.w, (last)r15.z
mad.f32 r13.z, r21.y, r19.x, (last)r13.z
mad.f32 r11.z, r21.y, r19.y, (last)r11.z
mad.f32 r9.z, r21.y, r19.z, (last)r9.z
mad.f32 r7.z, r21.y, r19.w, (last)r7.z
mad.f32 r5.z, r21.y, r20.x, (last)r5.z
mad.f32 r15.w, r21.z, r18.z, (last)r15.w
mad.f32 r13.w, r21.z, r18.w, (last)r13.w
mad.f32 r11.w, r21.z, r19.x, (last)r11.w
mad.f32 r9.w, r21.z, r19.y, (last)r9.w
mad.f32 r7.w, r21.z, r19.z, (last)r7.w
mad.f32 r5.w, r21.z, r19.w, (last)r5.w
mad.f32 r3.w, r21.z, r20.x, (last)r3.w
mad.f32 r16.x, r21.w, r18.z, (last)r16.x
mad.f32 r14.x, r21.w, r18.w, (last)r14.x
mad.f32 r12.x, r21.w, r19.x, (last)r12.x
mad.f32 r10.x, r21.w, r19.y, (last)r10.x
mad.f32 r8.x, r21.w, r19.z, (last)r8.x
mad.f32 r6.x, r21.w, r19.w, (last)r6.x
mad.f32 r4.x, r21.w, r20.x, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r22.x, r18.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r22.x, r18.w, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r22.x, r19.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r22.x, r19.y, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r22.x, r19.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r22.x, r19.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r22.x, r20.x, (r)(last)r4.y
(rpt1)mad.f32 r20.z, (r)(last)r20.z, r20.y, (r)(last)r2.w
(rpt1)mad.f32 r21.x, (r)(last)r21.x, r20.y, (r)(last)r3.y
(rpt1)mad.f32 r21.z, (r)(last)r21.z, r20.y, (r)(last)r1.w
(rpt1)mad.f32 r22.x, (r)(last)r22.x, r20.y, (r)(last)r2.y
ldl.u32 r1.w, l[r24.w+512], 4
ldl.u32 r2.w, l[r24.w+640], 4
ldl.u32 r18.z, l[r26.x], 4
ldl.u32 r19.z, l[r26.x+128], 4
mad.f32 r16.w, r27.y, r22.z, (last)r16.w
mad.f32 r14.w, r27.y, r22.w, (last)r14.w
mad.f32 r12.w, r27.y, r23.x, (last)r12.w
mad.f32 r10.w, r27.y, r23.y, (last)r10.w
mad.f32 r8.w, r27.y, r23.z, (last)r8.w
mad.f32 r6.w, r27.y, r23.w, (last)r6.w
mad.f32 r4.w, r27.y, r24.x, (last)r4.w
mad.f32 r17.x, r27.z, r22.z, (last)r17.x
mad.f32 r15.x, r27.z, r22.w, (last)r15.x
mad.f32 r13.x, r27.z, r23.x, (last)r13.x
mad.f32 r11.x, r27.z, r23.y, (last)r11.x
mad.f32 r9.x, r27.z, r23.z, (last)r9.x
mad.f32 r7.x, r27.z, r23.w, (last)r7.x
mad.f32 r5.x, r27.z, r24.x, (last)r5.x
mad.f32 r17.y, r27.w, r22.z, (last)r17.y
mad.f32 r15.y, r27.w, r22.w, (last)r15.y
mad.f32 r13.y, r27.w, r23.x, (last)r13.y
mad.f32 r11.y, r27.w, r23.y, (last)r11.y
mad.f32 r9.y, r27.w, r23.z, (last)r9.y
mad.f32 r7.y, r27.w, r23.w, (last)r7.y
mad.f32 r5.y, r27.w, r24.x, (last)r5.y
mad.f32 r17.z, r28.x, r22.z, (last)r17.z
mad.f32 r15.z, r28.x, r22.w, (last)r15.z
mad.f32 r13.z, r28.x, r23.x, (last)r13.z
mad.f32 r11.z, r28.x, r23.y, (last)r11.z
mad.f32 r9.z, r28.x, r23.z, (last)r9.z
mad.f32 r7.z, r28.x, r23.w, (last)r7.z
mad.f32 r5.z, r28.x, r24.x, (last)r5.z
mad.f32 r15.w, r30.y, r22.z, (last)r15.w
mad.f32 r13.w, r30.y, r22.w, (last)r13.w
mad.f32 r11.w, r30.y, r23.x, (last)r11.w
mad.f32 r9.w, r30.y, r23.y, (last)r9.w
mad.f32 r7.w, r30.y, r23.z, (last)r7.w
mad.f32 r5.w, r30.y, r23.w, (last)r5.w
mad.f32 r3.w, r30.y, r24.x, (last)r3.w
mad.f32 r16.x, r30.z, r22.z, (last)r16.x
mad.f32 r14.x, r30.z, r22.w, (last)r14.x
mad.f32 r12.x, r30.z, r23.x, (last)r12.x
mad.f32 r10.x, r30.z, r23.y, (last)r10.x
mad.f32 r8.x, r30.z, r23.z, (last)r8.x
mad.f32 r6.x, r30.z, r23.w, (last)r6.x
mad.f32 r4.x, r30.z, r24.x, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r30.w, r22.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r30.w, r22.w, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r30.w, r23.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r30.w, r23.y, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r30.w, r23.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r30.w, r23.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r30.w, r24.x, (r)(last)r4.y
(rpt1)mad.f32 r27.y, (r)(last)r27.y, r24.y, (r)(last)r20.z
(rpt1)mad.f32 r27.w, (r)(last)r27.w, r24.y, (r)(last)r21.x
ldl.u32 r20.z, l[r24.w+768], 4
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r24.y, (r)(last)r21.z
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r24.y, (r)(last)r22.x
ldl.u32 r21.z, l[r24.w+896], 4
ldl.u32 r22.z, l[r26.y], 4
ldl.u32 r23.z, l[r26.y+128], 4
(ss)mad.f32 r16.w, r18.z, r1.w, (last)r16.w
ldl.u32 r25.y, l[r24.w+1024], 4
mad.f32 r14.w, r18.z, r2.x, (last)r14.w
mad.f32 r12.w, r18.z, r2.y, (last)r12.w
mad.f32 r10.w, r18.z, r2.z, (last)r10.w
mad.f32 r8.w, r18.z, r2.w, (last)r8.w
mad.f32 r6.w, r18.z, r3.x, (last)r6.w
mad.f32 r4.w, r18.z, r3.y, (last)r4.w
mad.f32 r17.x, r18.w, r1.w, (last)r17.x
mad.f32 r15.x, r18.w, r2.x, (last)r15.x
mad.f32 r13.x, r18.w, r2.y, (last)r13.x
mad.f32 r11.x, r18.w, r2.z, (last)r11.x
mad.f32 r9.x, r18.w, r2.w, (last)r9.x
mad.f32 r7.x, r18.w, r3.x, (last)r7.x
mad.f32 r5.x, r18.w, r3.y, (last)r5.x
mad.f32 r17.y, r19.x, r1.w, (last)r17.y
mad.f32 r15.y, r19.x, r2.x, (last)r15.y
mad.f32 r13.y, r19.x, r2.y, (last)r13.y
mad.f32 r11.y, r19.x, r2.z, (last)r11.y
mad.f32 r9.y, r19.x, r2.w, (last)r9.y
mad.f32 r7.y, r19.x, r3.x, (last)r7.y
mad.f32 r5.y, r19.x, r3.y, (last)r5.y
mad.f32 r17.z, r19.y, r1.w, (last)r17.z
mad.f32 r15.z, r19.y, r2.x, (last)r15.z
mad.f32 r13.z, r19.y, r2.y, (last)r13.z
mad.f32 r11.z, r19.y, r2.z, (last)r11.z
mad.f32 r9.z, r19.y, r2.w, (last)r9.z
mad.f32 r7.z, r19.y, r3.x, (last)r7.z
mad.f32 r5.z, r19.y, r3.y, (last)r5.z
mad.f32 r15.w, r19.z, r1.w, (last)r15.w
mad.f32 r13.w, r19.z, r2.x, (last)r13.w
mad.f32 r11.w, r19.z, r2.y, (last)r11.w
mad.f32 r9.w, r19.z, r2.z, (last)r9.w
mad.f32 r7.w, r19.z, r2.w, (last)r7.w
mad.f32 r5.w, r19.z, r3.x, (last)r5.w
mad.f32 r3.w, r19.z, r3.y, (last)r3.w
mad.f32 r16.x, r19.w, r1.w, (last)r16.x
mad.f32 r14.x, r19.w, r2.x, (last)r14.x
mad.f32 r12.x, r19.w, r2.y, (last)r12.x
mad.f32 r10.x, r19.w, r2.z, (last)r10.x
mad.f32 r8.x, r19.w, r2.w, (last)r8.x
mad.f32 r6.x, r19.w, r3.x, (last)r6.x
mad.f32 r4.x, r19.w, r3.y, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r20.x, r1.w, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r20.x, r2.x, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r20.x, r2.y, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r20.x, r2.z, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r20.x, r2.w, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r20.x, r3.x, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r20.x, r3.y, (r)(last)r4.y
(rpt1)mad.f32 r18.z, (r)(last)r18.z, r3.z, (r)(last)r27.y
(rpt1)mad.f32 r19.x, (r)(last)r19.x, r3.z, (r)(last)r27.w
ldl.u32 r27.y, l[r24.w+1152], 4
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r3.z, (r)(last)r30.y
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r3.z, (r)(last)r30.w
ldl.u32 r30.y, l[r26.z], 4
ldl.u32 r1.w, l[r26.z+128], 4
ldl.u32 r2.w, l[r24.w+1280], 4
mad.f32 r16.w, r22.z, r20.z, (last)r16.w
mad.f32 r14.w, r22.z, r20.w, (last)r14.w
mad.f32 r12.w, r22.z, r21.x, (last)r12.w
mad.f32 r10.w, r22.z, r21.y, (last)r10.w
mad.f32 r8.w, r22.z, r21.z, (last)r8.w
mad.f32 r6.w, r22.z, r21.w, (last)r6.w
mad.f32 r4.w, r22.z, r22.x, (last)r4.w
mad.f32 r17.x, r22.w, r20.z, (last)r17.x
mad.f32 r15.x, r22.w, r20.w, (last)r15.x
mad.f32 r13.x, r22.w, r21.x, (last)r13.x
mad.f32 r11.x, r22.w, r21.y, (last)r11.x
mad.f32 r9.x, r22.w, r21.z, (last)r9.x
mad.f32 r7.x, r22.w, r21.w, (last)r7.x
mad.f32 r5.x, r22.w, r22.x, (last)r5.x
mad.f32 r17.y, r23.x, r20.z, (last)r17.y
mad.f32 r15.y, r23.x, r20.w, (last)r15.y
mad.f32 r13.y, r23.x, r21.x, (last)r13.y
mad.f32 r11.y, r23.x, r21.y, (last)r11.y
mad.f32 r9.y, r23.x, r21.z, (last)r9.y
mad.f32 r7.y, r23.x, r21.w, (last)r7.y
mad.f32 r5.y, r23.x, r22.x, (last)r5.y
mad.f32 r17.z, r23.y, r20.z, (last)r17.z
mad.f32 r15.z, r23.y, r20.w, (last)r15.z
mad.f32 r13.z, r23.y, r21.x, (last)r13.z
mad.f32 r11.z, r23.y, r21.y, (last)r11.z
mad.f32 r9.z, r23.y, r21.z, (last)r9.z
mad.f32 r7.z, r23.y, r21.w, (last)r7.z
mad.f32 r5.z, r23.y, r22.x, (last)r5.z
mad.f32 r15.w, r23.z, r20.z, (last)r15.w
mad.f32 r13.w, r23.z, r20.w, (last)r13.w
mad.f32 r11.w, r23.z, r21.x, (last)r11.w
mad.f32 r9.w, r23.z, r21.y, (last)r9.w
mad.f32 r7.w, r23.z, r21.z, (last)r7.w
mad.f32 r5.w, r23.z, r21.w, (last)r5.w
mad.f32 r3.w, r23.z, r22.x, (last)r3.w
mad.f32 r16.x, r23.w, r20.z, (last)r16.x
mad.f32 r14.x, r23.w, r20.w, (last)r14.x
mad.f32 r12.x, r23.w, r21.x, (last)r12.x
mad.f32 r10.x, r23.w, r21.y, (last)r10.x
mad.f32 r8.x, r23.w, r21.z, (last)r8.x
mad.f32 r6.x, r23.w, r21.w, (last)r6.x
mad.f32 r4.x, r23.w, r22.x, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r24.x, r20.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r24.x, r20.w, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r24.x, r21.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r24.x, r21.y, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r24.x, r21.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r24.x, r21.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r24.x, r22.x, (r)(last)r4.y
(rpt1)mad.f32 r22.z, (r)(last)r22.z, r22.y, (r)(last)r18.z
(rpt1)mad.f32 r23.x, (r)(last)r23.x, r22.y, (r)(last)r19.x
ldl.u32 r18.z, l[r24.w+1408], 4
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r22.y, (r)(last)r19.z
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r22.y, (r)(last)r20.x
ldl.u32 r19.z, l[r26.w], 4
ldl.u32 r20.z, l[r26.w+128], 4
ldl.u32 r21.z, l[r24.w+1536], 4
(ss)mad.f32 r16.w, r30.y, r25.y, (last)r16.w
mad.f32 r14.w, r30.y, r25.z, (last)r14.w
mad.f32 r12.w, r30.y, r25.w, (last)r12.w
mad.f32 r10.w, r30.y, r26.x, (last)r10.w
mad.f32 r8.w, r30.y, r27.y, (last)r8.w
mad.f32 r6.w, r30.y, r27.z, (last)r6.w
mad.f32 r4.w, r30.y, r27.w, (last)r4.w
mad.f32 r17.x, r30.z, r25.y, (last)r17.x
mad.f32 r15.x, r30.z, r25.z, (last)r15.x
mad.f32 r13.x, r30.z, r25.w, (last)r13.x
mad.f32 r11.x, r30.z, r26.x, (last)r11.x
mad.f32 r9.x, r30.z, r27.y, (last)r9.x
mad.f32 r7.x, r30.z, r27.z, (last)r7.x
mad.f32 r5.x, r30.z, r27.w, (last)r5.x
mad.f32 r17.y, r30.w, r25.y, (last)r17.y
mad.f32 r15.y, r30.w, r25.z, (last)r15.y
mad.f32 r13.y, r30.w, r25.w, (last)r13.y
mad.f32 r11.y, r30.w, r26.x, (last)r11.y
mad.f32 r9.y, r30.w, r27.y, (last)r9.y
mad.f32 r7.y, r30.w, r27.z, (last)r7.y
mad.f32 r5.y, r30.w, r27.w, (last)r5.y
mad.f32 r17.z, r31.x, r25.y, (last)r17.z
mad.f32 r15.z, r31.x, r25.z, (last)r15.z
mad.f32 r13.z, r31.x, r25.w, (last)r13.z
mad.f32 r11.z, r31.x, r26.x, (last)r11.z
mad.f32 r9.z, r31.x, r27.y, (last)r9.z
mad.f32 r7.z, r31.x, r27.z, (last)r7.z
mad.f32 r5.z, r31.x, r27.w, (last)r5.z
mad.f32 r15.w, r1.w, r25.y, (last)r15.w
mad.f32 r13.w, r1.w, r25.z, (last)r13.w
mad.f32 r11.w, r1.w, r25.w, (last)r11.w
mad.f32 r9.w, r1.w, r26.x, (last)r9.w
mad.f32 r7.w, r1.w, r27.y, (last)r7.w
mad.f32 r5.w, r1.w, r27.z, (last)r5.w
mad.f32 r3.w, r1.w, r27.w, (last)r3.w
mad.f32 r16.x, r2.x, r25.y, (last)r16.x
mad.f32 r14.x, r2.x, r25.z, (last)r14.x
mad.f32 r12.x, r2.x, r25.w, (last)r12.x
mad.f32 r10.x, r2.x, r26.x, (last)r10.x
mad.f32 r8.x, r2.x, r27.y, (last)r8.x
mad.f32 r6.x, r2.x, r27.z, (last)r6.x
mad.f32 r4.x, r2.x, r27.w, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r2.y, r25.y, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r2.y, r25.z, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r2.y, r25.w, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r2.y, r26.x, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r2.y, r27.y, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r2.y, r27.z, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r2.y, r27.w, (r)(last)r4.y
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r28.x, (r)(last)r22.z
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r28.x, (r)(last)r23.x
ldl.u32 r22.z, l[r24.w+1664], 4
(rpt1)mad.f32 r1.w, (r)(last)r1.w, r28.x, (r)(last)r23.z
(rpt1)mad.f32 r2.y, (r)(last)r2.y, r28.x, (r)(last)r24.x
ldl.u32 r23.z, l[r27.x], 4
ldl.u32 r25.y, l[r27.x+128], 4
mad.f32 r16.w, r19.z, r2.w, (last)r16.w
mad.f32 r14.w, r19.z, r3.x, (last)r14.w
mad.f32 r12.w, r19.z, r3.y, (last)r12.w
mad.f32 r10.w, r19.z, r3.z, (last)r10.w
mad.f32 r8.w, r19.z, r18.z, (last)r8.w
mad.f32 r6.w, r19.z, r18.w, (last)r6.w
mad.f32 r4.w, r19.z, r19.x, (last)r4.w
mad.f32 r17.x, r19.w, r2.w, (last)r17.x
mad.f32 r15.x, r19.w, r3.x, (last)r15.x
mad.f32 r13.x, r19.w, r3.y, (last)r13.x
(ss)nop
ldl.u32 r26.y, l[r24.w+1792], 4
ldl.u32 r27.y, l[r24.w+1920], 4
mad.f32 r11.x, r19.w, r3.z, (last)r11.x
mad.f32 r9.x, r19.w, r18.z, (last)r9.x
mad.f32 r7.x, r19.w, r18.w, (last)r7.x
mad.f32 r5.x, r19.w, r19.x, (last)r5.x
mad.f32 r17.y, r20.x, r2.w, (last)r17.y
mad.f32 r15.y, r20.x, r3.x, (last)r15.y
mad.f32 r13.y, r20.x, r3.y, (last)r13.y
mad.f32 r11.y, r20.x, r3.z, (last)r11.y
mad.f32 r9.y, r20.x, r18.z, (last)r9.y
mad.f32 r7.y, r20.x, r18.w, (last)r7.y
mad.f32 r5.y, r20.x, r19.x, (last)r5.y
mad.f32 r17.z, r20.y, r2.w, (last)r17.z
mad.f32 r15.z, r20.y, r3.x, (last)r15.z
mad.f32 r13.z, r20.y, r3.y, (last)r13.z
mad.f32 r11.z, r20.y, r3.z, (last)r11.z
mad.f32 r9.z, r20.y, r18.z, (last)r9.z
mad.f32 r7.z, r20.y, r18.w, (last)r7.z
mad.f32 r5.z, r20.y, r19.x, (last)r5.z
mad.f32 r15.w, r20.z, r2.w, (last)r15.w
mad.f32 r13.w, r20.z, r3.x, (last)r13.w
mad.f32 r11.w, r20.z, r3.y, (last)r11.w
mad.f32 r9.w, r20.z, r3.z, (last)r9.w
mad.f32 r7.w, r20.z, r18.z, (last)r7.w
mad.f32 r5.w, r20.z, r18.w, (last)r5.w
mad.f32 r3.w, r20.z, r19.x, (last)r3.w
mad.f32 r16.x, r20.w, r2.w, (last)r16.x
mad.f32 r14.x, r20.w, r3.x, (last)r14.x
mad.f32 r12.x, r20.w, r3.y, (last)r12.x
mad.f32 r10.x, r20.w, r3.z, (last)r10.x
mad.f32 r8.x, r20.w, r18.z, (last)r8.x
mad.f32 r6.x, r20.w, r18.w, (last)r6.x
mad.f32 r4.x, r20.w, r19.x, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r21.x, r2.w, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r21.x, r3.x, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r21.x, r3.y, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r21.x, r3.z, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r21.x, r18.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r21.x, r18.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r21.x, r19.x, (r)(last)r4.y
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r19.y, (r)(last)r30.y
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r19.y, (r)(last)r30.w
ldl.u32 r30.y, l[r28.y], 4
(rpt1)mad.f32 r20.z, (r)(last)r20.z, r19.y, (r)(last)r1.w
(rpt1)mad.f32 r21.x, (r)(last)r21.x, r19.y, (r)(last)r2.y
ldl.u32 r1.w, l[r28.y+128], 4
ldl.u32 r2.w, l[r24.w+2048], 4
ldl.u32 r18.z, l[r24.w+2176], 4
mad.f32 r16.w, r23.z, r21.z, (last)r16.w
mad.f32 r14.w, r23.z, r21.w, (last)r14.w
mad.f32 r12.w, r23.z, r22.x, (last)r12.w
mad.f32 r10.w, r23.z, r22.y, (last)r10.w
mad.f32 r8.w, r23.z, r22.z, (last)r8.w
mad.f32 r6.w, r23.z, r22.w, (last)r6.w
mad.f32 r4.w, r23.z, r23.x, (last)r4.w
mad.f32 r17.x, r23.w, r21.z, (last)r17.x
mad.f32 r15.x, r23.w, r21.w, (last)r15.x
mad.f32 r13.x, r23.w, r22.x, (last)r13.x
mad.f32 r11.x, r23.w, r22.y, (last)r11.x
mad.f32 r9.x, r23.w, r22.z, (last)r9.x
mad.f32 r7.x, r23.w, r22.w, (last)r7.x
mad.f32 r5.x, r23.w, r23.x, (last)r5.x
mad.f32 r17.y, r24.x, r21.z, (last)r17.y
mad.f32 r15.y, r24.x, r21.w, (last)r15.y
mad.f32 r13.y, r24.x, r22.x, (last)r13.y
mad.f32 r11.y, r24.x, r22.y, (last)r11.y
mad.f32 r9.y, r24.x, r22.z, (last)r9.y
mad.f32 r7.y, r24.x, r22.w, (last)r7.y
mad.f32 r5.y, r24.x, r23.x, (last)r5.y
mad.f32 r17.z, r24.y, r21.z, (last)r17.z
mad.f32 r15.z, r24.y, r21.w, (last)r15.z
mad.f32 r13.z, r24.y, r22.x, (last)r13.z
mad.f32 r11.z, r24.y, r22.y, (last)r11.z
mad.f32 r9.z, r24.y, r22.z, (last)r9.z
mad.f32 r7.z, r24.y, r22.w, (last)r7.z
mad.f32 r5.z, r24.y, r23.x, (last)r5.z
mad.f32 r15.w, r25.y, r21.z, (last)r15.w
mad.f32 r13.w, r25.y, r21.w, (last)r13.w
mad.f32 r11.w, r25.y, r22.x, (last)r11.w
mad.f32 r9.w, r25.y, r22.y, (last)r9.w
mad.f32 r7.w, r25.y, r22.z, (last)r7.w
mad.f32 r5.w, r25.y, r22.w, (last)r5.w
mad.f32 r3.w, r25.y, r23.x, (last)r3.w
mad.f32 r16.x, r25.z, r21.z, (last)r16.x
mad.f32 r14.x, r25.z, r21.w, (last)r14.x
mad.f32 r12.x, r25.z, r22.x, (last)r12.x
mad.f32 r10.x, r25.z, r22.y, (last)r10.x
mad.f32 r8.x, r25.z, r22.z, (last)r8.x
mad.f32 r6.x, r25.z, r22.w, (last)r6.x
mad.f32 r4.x, r25.z, r23.x, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r25.w, r21.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r25.w, r21.w, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r25.w, r22.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r25.w, r22.y, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r25.w, r22.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r25.w, r22.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r25.w, r23.x, (r)(last)r4.y
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r23.y, (r)(last)r19.z
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r23.y, (r)(last)r20.x
ldl.u32 r19.z, l[r28.z], 4
(rpt1)mad.f32 r25.y, (r)(last)r25.y, r23.y, (r)(last)r20.z
(rpt1)mad.f32 r25.w, (r)(last)r25.w, r23.y, (r)(last)r21.x
ldl.u32 r20.z, l[r28.z+128], 4
ldl.u32 r21.z, l[r24.w+2304], 4
ldl.u32 r22.z, l[r24.w+2432], 4
(ss)mad.f32 r16.w, r30.y, r26.y, (last)r16.w
mad.f32 r14.w, r30.y, r26.z, (last)r14.w
mad.f32 r12.w, r30.y, r26.w, (last)r12.w
mad.f32 r10.w, r30.y, r27.x, (last)r10.w
mad.f32 r8.w, r30.y, r27.y, (last)r8.w
mad.f32 r6.w, r30.y, r27.z, (last)r6.w
mad.f32 r4.w, r30.y, r27.w, (last)r4.w
mad.f32 r17.x, r30.z, r26.y, (last)r17.x
mad.f32 r15.x, r30.z, r26.z, (last)r15.x
mad.f32 r13.x, r30.z, r26.w, (last)r13.x
mad.f32 r11.x, r30.z, r27.x, (last)r11.x
mad.f32 r9.x, r30.z, r27.y, (last)r9.x
mad.f32 r7.x, r30.z, r27.z, (last)r7.x
mad.f32 r5.x, r30.z, r27.w, (last)r5.x
mad.f32 r17.y, r30.w, r26.y, (last)r17.y
mad.f32 r15.y, r30.w, r26.z, (last)r15.y
mad.f32 r13.y, r30.w, r26.w, (last)r13.y
mad.f32 r11.y, r30.w, r27.x, (last)r11.y
mad.f32 r9.y, r30.w, r27.y, (last)r9.y
mad.f32 r7.y, r30.w, r27.z, (last)r7.y
mad.f32 r5.y, r30.w, r27.w, (last)r5.y
mad.f32 r17.z, r31.x, r26.y, (last)r17.z
mad.f32 r15.z, r31.x, r26.z, (last)r15.z
mad.f32 r13.z, r31.x, r26.w, (last)r13.z
mad.f32 r11.z, r31.x, r27.x, (last)r11.z
mad.f32 r9.z, r31.x, r27.y, (last)r9.z
mad.f32 r7.z, r31.x, r27.z, (last)r7.z
mad.f32 r5.z, r31.x, r27.w, (last)r5.z
mad.f32 r15.w, r1.w, r26.y, (last)r15.w
mad.f32 r13.w, r1.w, r26.z, (last)r13.w
mad.f32 r11.w, r1.w, r26.w, (last)r11.w
mad.f32 r9.w, r1.w, r27.x, (last)r9.w
mad.f32 r7.w, r1.w, r27.y, (last)r7.w
mad.f32 r5.w, r1.w, r27.z, (last)r5.w
mad.f32 r3.w, r1.w, r27.w, (last)r3.w
mad.f32 r16.x, r2.x, r26.y, (last)r16.x
mad.f32 r14.x, r2.x, r26.z, (last)r14.x
mad.f32 r12.x, r2.x, r26.w, (last)r12.x
mad.f32 r10.x, r2.x, r27.x, (last)r10.x
mad.f32 r8.x, r2.x, r27.y, (last)r8.x
mad.f32 r6.x, r2.x, r27.z, (last)r6.x
mad.f32 r4.x, r2.x, r27.w, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r2.y, r26.y, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r2.y, r26.z, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r2.y, r26.w, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r2.y, r27.x, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r2.y, r27.y, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r2.y, r27.z, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r2.y, r27.w, (r)(last)r4.y
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r28.x, (r)(last)r23.z
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r28.x, (r)(last)r24.x
ldl.u32 r23.z, l[r28.w], 4
(rpt1)mad.f32 r1.w, (r)(last)r1.w, r28.x, (r)(last)r25.y
(rpt1)mad.f32 r2.y, (r)(last)r2.y, r28.x, (r)(last)r25.w
ldl.u32 r25.y, l[r28.w+128], 4
ldl.u32 r26.y, l[r24.w+2560], 4
ldl.u32 r27.y, l[r24.w+2688], 4
mad.f32 r16.w, r19.z, r2.w, (last)r16.w
mad.f32 r14.w, r19.z, r3.x, (last)r14.w
mad.f32 r12.w, r19.z, r3.y, (last)r12.w
mad.f32 r10.w, r19.z, r3.z, (last)r10.w
mad.f32 r8.w, r19.z, r18.z, (last)r8.w
mad.f32 r6.w, r19.z, r18.w, (last)r6.w
mad.f32 r4.w, r19.z, r19.x, (last)r4.w
mad.f32 r17.x, r19.w, r2.w, (last)r17.x
mad.f32 r15.x, r19.w, r3.x, (last)r15.x
mad.f32 r13.x, r19.w, r3.y, (last)r13.x
mad.f32 r11.x, r19.w, r3.z, (last)r11.x
mad.f32 r9.x, r19.w, r18.z, (last)r9.x
mad.f32 r7.x, r19.w, r18.w, (last)r7.x
mad.f32 r5.x, r19.w, r19.x, (last)r5.x
mad.f32 r17.y, r20.x, r2.w, (last)r17.y
mad.f32 r15.y, r20.x, r3.x, (last)r15.y
mad.f32 r13.y, r20.x, r3.y, (last)r13.y
mad.f32 r11.y, r20.x, r3.z, (last)r11.y
mad.f32 r9.y, r20.x, r18.z, (last)r9.y
mad.f32 r7.y, r20.x, r18.w, (last)r7.y
mad.f32 r5.y, r20.x, r19.x, (last)r5.y
mad.f32 r17.z, r20.y, r2.w, (last)r17.z
mad.f32 r15.z, r20.y, r3.x, (last)r15.z
mad.f32 r13.z, r20.y, r3.y, (last)r13.z
mad.f32 r11.z, r20.y, r3.z, (last)r11.z
mad.f32 r9.z, r20.y, r18.z, (last)r9.z
mad.f32 r7.z, r20.y, r18.w, (last)r7.z
mad.f32 r5.z, r20.y, r19.x, (last)r5.z
mad.f32 r15.w, r20.z, r2.w, (last)r15.w
mad.f32 r13.w, r20.z, r3.x, (last)r13.w
mad.f32 r11.w, r20.z, r3.y, (last)r11.w
mad.f32 r9.w, r20.z, r3.z, (last)r9.w
mad.f32 r7.w, r20.z, r18.z, (last)r7.w
mad.f32 r5.w, r20.z, r18.w, (last)r5.w
mad.f32 r3.w, r20.z, r19.x, (last)r3.w
mad.f32 r16.x, r20.w, r2.w, (last)r16.x
mad.f32 r14.x, r20.w, r3.x, (last)r14.x
mad.f32 r12.x, r20.w, r3.y, (last)r12.x
mad.f32 r10.x, r20.w, r3.z, (last)r10.x
mad.f32 r8.x, r20.w, r18.z, (last)r8.x
mad.f32 r6.x, r20.w, r18.w, (last)r6.x
mad.f32 r4.x, r20.w, r19.x, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r21.x, r2.w, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r21.x, r3.x, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r21.x, r3.y, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r21.x, r3.z, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r21.x, r18.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r21.x, r18.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r21.x, r19.x, (r)(last)r4.y
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r19.y, (r)(last)r30.y
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r19.y, (r)(last)r30.w
ldl.u32 r30.y, l[r29.x], 4
(rpt1)mad.f32 r20.z, (r)(last)r20.z, r19.y, (r)(last)r1.w
(rpt1)mad.f32 r21.x, (r)(last)r21.x, r19.y, (r)(last)r2.y
ldl.u32 r1.w, l[r29.x+128], 4
ldl.u32 r2.w, l[r24.w+2816], 4
ldl.u32 r18.z, l[r24.w+2944], 4
(ss)mad.f32 r16.w, r23.z, r21.z, (last)r16.w
mad.f32 r14.w, r23.z, r21.w, (last)r14.w
mad.f32 r12.w, r23.z, r22.x, (last)r12.w
mad.f32 r10.w, r23.z, r22.y, (last)r10.w
mad.f32 r8.w, r23.z, r22.z, (last)r8.w
mad.f32 r6.w, r23.z, r22.w, (last)r6.w
mad.f32 r4.w, r23.z, r23.x, (last)r4.w
mad.f32 r17.x, r23.w, r21.z, (last)r17.x
mad.f32 r15.x, r23.w, r21.w, (last)r15.x
mad.f32 r13.x, r23.w, r22.x, (last)r13.x
mad.f32 r11.x, r23.w, r22.y, (last)r11.x
mad.f32 r9.x, r23.w, r22.z, (last)r9.x
mad.f32 r7.x, r23.w, r22.w, (last)r7.x
mad.f32 r5.x, r23.w, r23.x, (last)r5.x
mad.f32 r17.y, r24.x, r21.z, (last)r17.y
mad.f32 r15.y, r24.x, r21.w, (last)r15.y
mad.f32 r13.y, r24.x, r22.x, (last)r13.y
mad.f32 r11.y, r24.x, r22.y, (last)r11.y
mad.f32 r9.y, r24.x, r22.z, (last)r9.y
mad.f32 r7.y, r24.x, r22.w, (last)r7.y
mad.f32 r5.y, r24.x, r23.x, (last)r5.y
mad.f32 r17.z, r24.y, r21.z, (last)r17.z
mad.f32 r15.z, r24.y, r21.w, (last)r15.z
mad.f32 r13.z, r24.y, r22.x, (last)r13.z
mad.f32 r11.z, r24.y, r22.y, (last)r11.z
mad.f32 r9.z, r24.y, r22.z, (last)r9.z
mad.f32 r7.z, r24.y, r22.w, (last)r7.z
mad.f32 r5.z, r24.y, r23.x, (last)r5.z
mad.f32 r15.w, r25.y, r21.z, (last)r15.w
mad.f32 r13.w, r25.y, r21.w, (last)r13.w
mad.f32 r11.w, r25.y, r22.x, (last)r11.w
mad.f32 r9.w, r25.y, r22.y, (last)r9.w
mad.f32 r7.w, r25.y, r22.z, (last)r7.w
mad.f32 r5.w, r25.y, r22.w, (last)r5.w
mad.f32 r3.w, r25.y, r23.x, (last)r3.w
mad.f32 r16.x, r25.z, r21.z, (last)r16.x
mad.f32 r14.x, r25.z, r21.w, (last)r14.x
mad.f32 r12.x, r25.z, r22.x, (last)r12.x
mad.f32 r10.x, r25.z, r22.y, (last)r10.x
mad.f32 r8.x, r25.z, r22.z, (last)r8.x
mad.f32 r6.x, r25.z, r22.w, (last)r6.x
mad.f32 r4.x, r25.z, r23.x, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r25.w, r21.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r25.w, r21.w, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r25.w, r22.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r25.w, r22.y, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r25.w, r22.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r25.w, r22.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r25.w, r23.x, (r)(last)r4.y
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r23.y, (r)(last)r19.z
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r23.y, (r)(last)r20.x
ldl.u32 r19.z, l[r29.y], 4
(rpt1)mad.f32 r25.y, (r)(last)r25.y, r23.y, (r)(last)r20.z
(rpt1)mad.f32 r25.w, (r)(last)r25.w, r23.y, (r)(last)r21.x
ldl.u32 r20.z, l[r29.y+128], 4
ldl.u32 r21.z, l[r24.w+3072], 4
ldl.u32 r22.z, l[r24.w+3200], 4
mad.f32 r16.w, r30.y, r26.y, (last)r16.w
mad.f32 r14.w, r30.y, r26.z, (last)r14.w
mad.f32 r12.w, r30.y, r26.w, (last)r12.w
mad.f32 r10.w, r30.y, r27.x, (last)r10.w
mad.f32 r8.w, r30.y, r27.y, (last)r8.w
mad.f32 r6.w, r30.y, r27.z, (last)r6.w
mad.f32 r4.w, r30.y, r27.w, (last)r4.w
mad.f32 r17.x, r30.z, r26.y, (last)r17.x
mad.f32 r15.x, r30.z, r26.z, (last)r15.x
mad.f32 r13.x, r30.z, r26.w, (last)r13.x
mad.f32 r11.x, r30.z, r27.x, (last)r11.x
mad.f32 r9.x, r30.z, r27.y, (last)r9.x
mad.f32 r7.x, r30.z, r27.z, (last)r7.x
mad.f32 r5.x, r30.z, r27.w, (last)r5.x
mad.f32 r17.y, r30.w, r26.y, (last)r17.y
mad.f32 r15.y, r30.w, r26.z, (last)r15.y
mad.f32 r13.y, r30.w, r26.w, (last)r13.y
mad.f32 r11.y, r30.w, r27.x, (last)r11.y
mad.f32 r9.y, r30.w, r27.y, (last)r9.y
mad.f32 r7.y, r30.w, r27.z, (last)r7.y
mad.f32 r5.y, r30.w, r27.w, (last)r5.y
mad.f32 r17.z, r31.x, r26.y, (last)r17.z
mad.f32 r15.z, r31.x, r26.z, (last)r15.z
mad.f32 r13.z, r31.x, r26.w, (last)r13.z
mad.f32 r11.z, r31.x, r27.x, (last)r11.z
mad.f32 r9.z, r31.x, r27.y, (last)r9.z
mad.f32 r7.z, r31.x, r27.z, (last)r7.z
mad.f32 r5.z, r31.x, r27.w, (last)r5.z
mad.f32 r15.w, r1.w, r26.y, (last)r15.w
mad.f32 r13.w, r1.w, r26.z, (last)r13.w
mad.f32 r11.w, r1.w, r26.w, (last)r11.w
mad.f32 r9.w, r1.w, r27.x, (last)r9.w
mad.f32 r7.w, r1.w, r27.y, (last)r7.w
mad.f32 r5.w, r1.w, r27.z, (last)r5.w
mad.f32 r3.w, r1.w, r27.w, (last)r3.w
mad.f32 r16.x, r2.x, r26.y, (last)r16.x
mad.f32 r14.x, r2.x, r26.z, (last)r14.x
mad.f32 r12.x, r2.x, r26.w, (last)r12.x
mad.f32 r10.x, r2.x, r27.x, (last)r10.x
mad.f32 r8.x, r2.x, r27.y, (last)r8.x
mad.f32 r6.x, r2.x, r27.z, (last)r6.x
mad.f32 r4.x, r2.x, r27.w, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r2.y, r26.y, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r2.y, r26.z, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r2.y, r26.w, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r2.y, r27.x, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r2.y, r27.y, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r2.y, r27.z, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r2.y, r27.w, (r)(last)r4.y
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r28.x, (r)(last)r23.z
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r28.x, (r)(last)r24.x
ldl.u32 r23.z, l[r29.z], 4
(rpt1)mad.f32 r1.w, (r)(last)r1.w, r28.x, (r)(last)r25.y
(rpt1)mad.f32 r2.y, (r)(last)r2.y, r28.x, (r)(last)r25.w
ldl.u32 r25.y, l[r29.z+128], 4
ldl.u32 r26.y, l[r24.w+3328], 4
ldl.u32 r27.y, l[r24.w+3456], 4
ldl.u32 r28.y, l[r29.w], 4
(ss)mad.f32 r16.w, r19.z, r2.w, (last)r16.w
mad.f32 r14.w, r19.z, r3.x, (last)r14.w
mad.f32 r12.w, r19.z, r3.y, (last)r12.w
mad.f32 r10.w, r19.z, r3.z, (last)r10.w
mad.f32 r8.w, r19.z, r18.z, (last)r8.w
mad.f32 r6.w, r19.z, r18.w, (last)r6.w
mad.f32 r4.w, r19.z, r19.x, (last)r4.w
mad.f32 r17.x, r19.w, r2.w, (last)r17.x
mad.f32 r15.x, r19.w, r3.x, (last)r15.x
mad.f32 r13.x, r19.w, r3.y, (last)r13.x
mad.f32 r11.x, r19.w, r3.z, (last)r11.x
mad.f32 r9.x, r19.w, r18.z, (last)r9.x
mad.f32 r7.x, r19.w, r18.w, (last)r7.x
mad.f32 r5.x, r19.w, r19.x, (last)r5.x
mad.f32 r17.y, r20.x, r2.w, (last)r17.y
mad.f32 r15.y, r20.x, r3.x, (last)r15.y
mad.f32 r13.y, r20.x, r3.y, (last)r13.y
mad.f32 r11.y, r20.x, r3.z, (last)r11.y
mad.f32 r9.y, r20.x, r18.z, (last)r9.y
mad.f32 r7.y, r20.x, r18.w, (last)r7.y
mad.f32 r5.y, r20.x, r19.x, (last)r5.y
mad.f32 r17.z, r20.y, r2.w, (last)r17.z
mad.f32 r15.z, r20.y, r3.x, (last)r15.z
mad.f32 r13.z, r20.y, r3.y, (last)r13.z
mad.f32 r11.z, r20.y, r3.z, (last)r11.z
mad.f32 r9.z, r20.y, r18.z, (last)r9.z
mad.f32 r7.z, r20.y, r18.w, (last)r7.z
mad.f32 r5.z, r20.y, r19.x, (last)r5.z
mad.f32 r15.w, r20.z, r2.w, (last)r15.w
mad.f32 r13.w, r20.z, r3.x, (last)r13.w
mad.f32 r11.w, r20.z, r3.y, (last)r11.w
mad.f32 r9.w, r20.z, r3.z, (last)r9.w
mad.f32 r7.w, r20.z, r18.z, (last)r7.w
mad.f32 r5.w, r20.z, r18.w, (last)r5.w
mad.f32 r3.w, r20.z, r19.x, (last)r3.w
mad.f32 r16.x, r20.w, r2.w, (last)r16.x
mad.f32 r14.x, r20.w, r3.x, (last)r14.x
mad.f32 r12.x, r20.w, r3.y, (last)r12.x
mad.f32 r10.x, r20.w, r3.z, (last)r10.x
mad.f32 r8.x, r20.w, r18.z, (last)r8.x
mad.f32 r6.x, r20.w, r18.w, (last)r6.x
mad.f32 r4.x, r20.w, r19.x, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r21.x, r2.w, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r21.x, r3.x, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r21.x, r3.y, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r21.x, r3.z, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r21.x, r18.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r21.x, r18.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r21.x, r19.x, (r)(last)r4.y
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r19.y, (r)(last)r30.y
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r19.y, (r)(last)r30.w
ldl.u32 r30.y, l[r29.w+128], 4
(rpt1)mad.f32 r20.z, (r)(last)r20.z, r19.y, (r)(last)r1.w
(rpt1)mad.f32 r21.x, (r)(last)r21.x, r19.y, (r)(last)r2.y
ldl.u32 r1.w, l[r24.w+3584], 4
ldl.u32 r2.w, l[r24.w+3712], 4
ldl.u32 r18.z, l[r30.x], 4
mad.f32 r16.w, r23.z, r21.z, (last)r16.w
mad.f32 r14.w, r23.z, r21.w, (last)r14.w
mad.f32 r12.w, r23.z, r22.x, (last)r12.w
mad.f32 r10.w, r23.z, r22.y, (last)r10.w
mad.f32 r8.w, r23.z, r22.z, (last)r8.w
mad.f32 r6.w, r23.z, r22.w, (last)r6.w
mad.f32 r4.w, r23.z, r23.x, (last)r4.w
mad.f32 r17.x, r23.w, r21.z, (last)r17.x
mad.f32 r15.x, r23.w, r21.w, (last)r15.x
mad.f32 r13.x, r23.w, r22.x, (last)r13.x
mad.f32 r11.x, r23.w, r22.y, (last)r11.x
mad.f32 r9.x, r23.w, r22.z, (last)r9.x
mad.f32 r7.x, r23.w, r22.w, (last)r7.x
mad.f32 r5.x, r23.w, r23.x, (last)r5.x
mad.f32 r17.y, r24.x, r21.z, (last)r17.y
mad.f32 r15.y, r24.x, r21.w, (last)r15.y
mad.f32 r13.y, r24.x, r22.x, (last)r13.y
mad.f32 r11.y, r24.x, r22.y, (last)r11.y
mad.f32 r9.y, r24.x, r22.z, (last)r9.y
mad.f32 r7.y, r24.x, r22.w, (last)r7.y
mad.f32 r5.y, r24.x, r23.x, (last)r5.y
mad.f32 r17.z, r24.y, r21.z, (last)r17.z
mad.f32 r15.z, r24.y, r21.w, (last)r15.z
mad.f32 r13.z, r24.y, r22.x, (last)r13.z
mad.f32 r11.z, r24.y, r22.y, (last)r11.z
mad.f32 r9.z, r24.y, r22.z, (last)r9.z
mad.f32 r7.z, r24.y, r22.w, (last)r7.z
mad.f32 r5.z, r24.y, r23.x, (last)r5.z
mad.f32 r15.w, r25.y, r21.z, (last)r15.w
mad.f32 r13.w, r25.y, r21.w, (last)r13.w
mad.f32 r11.w, r25.y, r22.x, (last)r11.w
mad.f32 r9.w, r25.y, r22.y, (last)r9.w
mad.f32 r7.w, r25.y, r22.z, (last)r7.w
mad.f32 r5.w, r25.y, r22.w, (last)r5.w
mad.f32 r3.w, r25.y, r23.x, (last)r3.w
mad.f32 r16.x, r25.z, r21.z, (last)r16.x
mad.f32 r14.x, r25.z, r21.w, (last)r14.x
mad.f32 r12.x, r25.z, r22.x, (last)r12.x
mad.f32 r10.x, r25.z, r22.y, (last)r10.x
mad.f32 r8.x, r25.z, r22.z, (last)r8.x
mad.f32 r6.x, r25.z, r22.w, (last)r6.x
mad.f32 r4.x, r25.z, r23.x, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r25.w, r21.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r25.w, r21.w, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r25.w, r22.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r25.w, r22.y, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r25.w, r22.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r25.w, r22.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r25.w, r23.x, (r)(last)r4.y
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r23.y, (r)(last)r19.z
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r23.y, (r)(last)r20.x
ldl.u32 r19.z, l[r30.x+128], 4
(rpt1)mad.f32 r25.y, (r)(last)r25.y, r23.y, (r)(last)r20.z
(rpt1)mad.f32 r25.w, (r)(last)r25.w, r23.y, (r)(last)r21.x
ldl.u32 r20.z, l[r24.w+3840], 4
ldl.u32 r21.z, l[r24.w+3968], 4
ldl.u32 r22.z, l[r18.y], 4
mad.f32 r17.y, r28.w, r26.y, (last)r17.y
mad.f32 r15.y, r28.w, r26.z, (last)r15.y
mad.f32 r13.y, r28.w, r26.w, (last)r13.y
mad.f32 r11.y, r28.w, r27.x, (last)r11.y
mad.f32 r9.y, r28.w, r27.y, (last)r9.y
mad.f32 r7.y, r28.w, r27.z, (last)r7.y
mad.f32 r5.y, r28.w, r27.w, (last)r5.y
mad.f32 r17.z, r29.x, r26.y, (last)r17.z
mad.f32 r15.z, r29.x, r26.z, (last)r15.z
mad.f32 r13.z, r29.x, r26.w, (last)r13.z
mad.f32 r11.z, r29.x, r27.x, (last)r11.z
mad.f32 r9.z, r29.x, r27.y, (last)r9.z
mad.f32 r7.z, r29.x, r27.z, (last)r7.z
mad.f32 r5.z, r29.x, r27.w, (last)r5.z
(rpt1)mad.f32 r28.w, (r)(last)r28.w, r28.x, (r)(last)r24.x
(ss)nop
ldl.u32 r24.x, l[r18.y+128], 4
mad.f32 r16.w, r28.y, r26.y, (last)r16.w
mad.f32 r14.w, r28.y, r26.z, (last)r14.w
mad.f32 r12.w, r28.y, r26.w, (last)r12.w
mad.f32 r10.w, r28.y, r27.x, (last)r10.w
mad.f32 r8.w, r28.y, r27.y, (last)r8.w
mad.f32 r6.w, r28.y, r27.z, (last)r6.w
mad.f32 r4.w, r28.y, r27.w, (last)r4.w
mad.f32 r17.x, r28.z, r26.y, (last)r17.x
mad.f32 r15.x, r28.z, r26.z, (last)r15.x
mad.f32 r13.x, r28.z, r26.w, (last)r13.x
mad.f32 r11.x, r28.z, r27.x, (last)r11.x
mad.f32 r9.x, r28.z, r27.y, (last)r9.x
mad.f32 r7.x, r28.z, r27.z, (last)r7.x
mad.f32 r5.x, r28.z, r27.w, (last)r5.x
mad.f32 r15.w, r30.y, r26.y, (last)r15.w
mad.f32 r13.w, r30.y, r26.z, (last)r13.w
mad.f32 r11.w, r30.y, r26.w, (last)r11.w
mad.f32 r9.w, r30.y, r27.x, (last)r9.w
mad.f32 r7.w, r30.y, r27.y, (last)r7.w
mad.f32 r5.w, r30.y, r27.z, (last)r5.w
mad.f32 r3.w, r30.y, r27.w, (last)r3.w
mad.f32 r16.x, r30.z, r26.y, (last)r16.x
mad.f32 r14.x, r30.z, r26.z, (last)r14.x
mad.f32 r12.x, r30.z, r26.w, (last)r12.x
mad.f32 r10.x, r30.z, r27.x, (last)r10.x
mad.f32 r8.x, r30.z, r27.y, (last)r8.x
mad.f32 r6.x, r30.z, r27.z, (last)r6.x
mad.f32 r4.x, r30.z, r27.w, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r30.w, r26.y, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r30.w, r26.z, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r30.w, r26.w, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r30.w, r27.x, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r30.w, r27.y, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r30.w, r27.z, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r30.w, r27.w, (r)(last)r4.y
(rpt1)mad.f32 r28.y, (r)(last)r28.y, r28.x, (r)(last)r23.z
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r28.x, (r)(last)r25.y
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r28.x, (r)(last)r25.w
mad.f32 r17.y, r19.x, r1.w, (last)r17.y
mad.f32 r15.y, r19.x, r2.x, (last)r15.y
mad.f32 r13.y, r19.x, r2.y, (last)r13.y
mad.f32 r11.y, r19.x, r2.z, (last)r11.y
mad.f32 r9.y, r19.x, r2.w, (last)r9.y
mad.f32 r7.y, r19.x, r3.x, (last)r7.y
mad.f32 r5.y, r19.x, r3.y, (last)r5.y
mad.f32 r17.z, r19.y, r1.w, (last)r17.z
mad.f32 r15.z, r19.y, r2.x, (last)r15.z
mad.f32 r13.z, r19.y, r2.y, (last)r13.z
mad.f32 r11.z, r19.y, r2.z, (last)r11.z
mad.f32 r9.z, r19.y, r2.w, (last)r9.z
mad.f32 r7.z, r19.y, r3.x, (last)r7.z
mad.f32 r5.z, r19.y, r3.y, (last)r5.z
mad.f32 r16.w, r18.z, r1.w, (last)r16.w
mad.f32 r14.w, r18.z, r2.x, (last)r14.w
mad.f32 r12.w, r18.z, r2.y, (last)r12.w
mad.f32 r10.w, r18.z, r2.z, (last)r10.w
mad.f32 r8.w, r18.z, r2.w, (last)r8.w
mad.f32 r6.w, r18.z, r3.x, (last)r6.w
mad.f32 r4.w, r18.z, r3.y, (last)r4.w
mad.f32 r17.x, r18.w, r1.w, (last)r17.x
mad.f32 r15.x, r18.w, r2.x, (last)r15.x
mad.f32 r13.x, r18.w, r2.y, (last)r13.x
mad.f32 r11.x, r18.w, r2.z, (last)r11.x
mad.f32 r9.x, r18.w, r2.w, (last)r9.x
mad.f32 r7.x, r18.w, r3.x, (last)r7.x
mad.f32 r5.x, r18.w, r3.y, (last)r5.x
mad.f32 r15.w, r19.z, r1.w, (last)r15.w
mad.f32 r13.w, r19.z, r2.x, (last)r13.w
mad.f32 r11.w, r19.z, r2.y, (last)r11.w
mad.f32 r9.w, r19.z, r2.z, (last)r9.w
mad.f32 r7.w, r19.z, r2.w, (last)r7.w
mad.f32 r5.w, r19.z, r3.x, (last)r5.w
mad.f32 r3.w, r19.z, r3.y, (last)r3.w
mad.f32 r16.x, r19.w, r1.w, (last)r16.x
mad.f32 r14.x, r19.w, r2.x, (last)r14.x
mad.f32 r12.x, r19.w, r2.y, (last)r12.x
mad.f32 r10.x, r19.w, r2.z, (last)r10.x
mad.f32 r8.x, r19.w, r2.w, (last)r8.x
mad.f32 r6.x, r19.w, r3.x, (last)r6.x
mad.f32 r4.x, r19.w, r3.y, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r20.x, r1.w, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r20.x, r2.x, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r20.x, r2.y, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r20.x, r2.z, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r20.x, r2.w, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r20.x, r3.x, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r20.x, r3.y, (r)(last)r4.y
(rpt1)mad.f32 r19.x, (r)(last)r19.x, r3.z, (r)(last)r28.w
(rpt1)mad.f32 r18.z, (r)(last)r18.z, r3.z, (r)(last)r28.y
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r3.z, (r)(last)r30.y
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r3.z, (r)(last)r30.w
mad.f32 r17.y, r23.x, r20.z, (last)r17.y
mad.f32 r15.y, r23.x, r20.w, (last)r15.y
mad.f32 r13.y, r23.x, r21.x, (last)r13.y
mad.f32 r11.y, r23.x, r21.y, (last)r11.y
mad.f32 r9.y, r23.x, r21.z, (last)r9.y
mad.f32 r7.y, r23.x, r21.w, (last)r7.y
mad.f32 r5.y, r23.x, r22.x, (last)r5.y
mad.f32 r17.z, r23.y, r20.z, (last)r17.z
mad.f32 r15.z, r23.y, r20.w, (last)r15.z
mad.f32 r13.z, r23.y, r21.x, (last)r13.z
mad.f32 r11.z, r23.y, r21.y, (last)r11.z
mad.f32 r9.z, r23.y, r21.z, (last)r9.z
mad.f32 r7.z, r23.y, r21.w, (last)r7.z
mad.f32 r5.z, r23.y, r22.x, (last)r5.z
mad.f32 r16.w, r22.z, r20.z, (last)r16.w
mad.f32 r14.w, r22.z, r20.w, (last)r14.w
mad.f32 r12.w, r22.z, r21.x, (last)r12.w
mad.f32 r10.w, r22.z, r21.y, (last)r10.w
mad.f32 r8.w, r22.z, r21.z, (last)r8.w
mad.f32 r6.w, r22.z, r21.w, (last)r6.w
mad.f32 r4.w, r22.z, r22.x, (last)r4.w
mad.f32 r17.x, r22.w, r20.z, (last)r17.x
mad.f32 r15.x, r22.w, r20.w, (last)r15.x
mad.f32 r13.x, r22.w, r21.x, (last)r13.x
mad.f32 r11.x, r22.w, r21.y, (last)r11.x
mad.f32 r9.x, r22.w, r21.z, (last)r9.x
mad.f32 r7.x, r22.w, r21.w, (last)r7.x
mad.f32 r5.x, r22.w, r22.x, (last)r5.x
(ss)mad.f32 r15.w, r24.x, r20.z, (last)r15.w
mad.f32 r13.w, r24.x, r20.w, (last)r13.w
mad.f32 r11.w, r24.x, r21.x, (last)r11.w
mad.f32 r9.w, r24.x, r21.y, (last)r9.w
mad.f32 r7.w, r24.x, r21.z, (last)r7.w
mad.f32 r5.w, r24.x, r21.w, (last)r5.w
mad.f32 r3.w, r24.x, r22.x, (last)r3.w
mad.f32 r16.x, r24.y, r20.z, (last)r16.x
mad.f32 r14.x, r24.y, r20.w, (last)r14.x
mad.f32 r12.x, r24.y, r21.x, (last)r12.x
mad.f32 r10.x, r24.y, r21.y, (last)r10.x
mad.f32 r8.x, r24.y, r21.z, (last)r8.x
mad.f32 r6.x, r24.y, r21.w, (last)r6.x
mad.f32 r4.x, r24.y, r22.x, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r24.z, r20.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r24.z, r20.w, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r24.z, r21.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r24.z, r21.y, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r24.z, r21.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r24.z, r21.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r24.z, r22.x, (r)(last)r4.y
mad.f32 r3.y, (last)r23.x, r22.y, (last)r19.x
(rpt1)mad.f32 r2.w, (r)(last)r22.z, r22.y, (r)(last)r18.z
(rpt1)mad.f32 r25.y, (r)(last)r24.x, r22.y, (r)(last)r19.z
(rpt1)mad.f32 r25.w, (r)(last)r24.z, r22.y, (r)(last)r20.x
mad.f32 r3.z, (last)r23.y, r22.y, (last)r19.y
fence.r.w
(sy)(ss)cov.f32f16 hr47.z, r17.y
cov.f32f16 hr1.x, r15.y
cov.f32f16 hr4.x, r13.y
cov.f32f16 hr5.x, r11.y
cov.f32f16 hr36.x, r9.y
cov.f32f16 hr47.w, r17.z
cov.f32f16 hr1.y, r15.z
cov.f32f16 hr4.y, r13.z
cov.f32f16 hr5.y, r11.z
cov.f32f16 hr36.y, r9.z
cov.f32f16 hr47.x, r16.w
cov.f32f16 hr0.z, r14.w
cov.f32f16 hr3.z, r12.w
cov.f32f16 hr4.z, r10.w
cov.f32f16 hr35.z, r8.w
cov.f32f16 hr47.y, r17.x
cov.f32f16 hr0.w, r15.x
cov.f32f16 hr3.w, r13.x
cov.f32f16 hr4.w, r11.x
cov.f32f16 hr35.w, r9.x
(rpt1)cov.f32f16 hr41.x, (r)r11.w
(rpt1)cov.f32f16 hr41.z, (r)r12.y
(rpt1)cov.f32f16 hr42.x, (r)r9.w
cov.f32f16 hr42.w, r10.z
cov.f32f16 hr42.z, r10.y
(rpt1)cov.f32f16 hr43.x, (r)r7.w
(rpt1)cov.f32f16 hr43.z, (r)r8.y
(rpt1)cov.f32f16 hr44.x, (r)r5.w
(rpt1)cov.f32f16 hr46.x, (r)r3.w
(rpt1)cov.f32f16 hr38.x, (r)r4.w
cov.f32f16 hr45.x, r2.w
(rpt1)cov.f32f16 hr37.x, (r)r6.w
cov.f32f16 hr45.y, r3.x
cov.f32f16 hr45.z, r3.y
(rpt1)cov.f32f16 hr37.z, (r)r7.y
cov.f32f16 hr36.z, r25.y
mov.u32u32 r24.x, (last)r0.x
(rpt1)cov.f32f16 hr39.x, (r)r15.w
cov.f32f16 hr36.w, r25.z
(rpt1)cov.f32f16 hr39.z, (r)r16.y
(rpt1)cov.f32f16 hr40.x, (r)r13.w
(rpt1)cov.f32f16 hr40.z, (r)r14.y
cov.f32f16 hr45.w, r3.z
cov.f32f16 hr46.z, r4.y
cov.f32f16 hr46.w, r25.w
(rpt1)cov.f32f16 hr44.z, (r)r6.y
(rpt1)cov.f32f16 hr38.z, (r)r5.y
bar.g
(sy)(ss)cov.f32f16 hr0.x, r4.z
cov.f32f16 hr0.y, r26.x
br p0.x, #l1172
mov.u32u32 r1.w, (last)r25.y
mov.u32u32 r2.x, (last)r25.z
mov.u32u32 r2.z, (last)r26.x
mov.u32u32 r2.y, (last)r25.w
mov.u32u32 r0.x, (last)r24.x
jump #l118
l1172:
(jp)(eolm)nop
add.u r25.x, r49.x, (last)r25.x
mov.u16u16 hr9.z, (last)hr46.x
mov.u16u16 hr9.w, (last)hr46.y
mov.u16u16 hr10.x, (last)hr46.z
shl.b r25.x, (last)r25.x, 9
mov.u16u16 hr10.y, (last)hr0.x
mov.u16u16 hr11.z, (last)hr36.z
mov.u16u16 hr11.w, (last)hr36.w
sad.s32 r25.x, r50.x, r25.x, (last)r1.y
mov.u16u16 hr12.x, (last)hr46.w
mov.u16u16 hr12.y, (last)hr0.y
nop
(nop3) shl.b r25.x, (last)r25.x, 2
add.u r0.w, r25.x, c1.x
add.u r1.x, r25.x, c5.z
add.u r1.y, r25.x, c1.y
add.u r1.z, r25.x, c5.w
add.u r2.w, r25.x, c3.y
(rpt2)add.u r3.x, r25.x, (r)c6.x
(rpt3)add.u r3.w, r25.x, (r)c6.w
(rpt1)add.u r5.y, r25.x, (r)c7.w
stib.b.untyped.1d.u16.4.imm.base0 hr47.x, r25.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr39.x, r25.x+32, 4
stib.b.untyped.1d.u16.4.imm.base0 hr0.z, r0.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr40.x, r1.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r1.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr41.x, r1.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r2.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr42.x, r3.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr35.z, r3.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr43.x, r3.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr37.x, r3.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr44.x, r4.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr38.x, r4.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r4.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr45.x, r5.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r5.z, 4
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
; CL prog 23/1: 1386 instr, 23 nops, 1363 non-nops, 79 mov, 64 cov, 2464 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 32 full, 12 constlen
; CL prog 23/1: 26 cat0, 143 cat1, 80 cat2, 1037 cat3, 0 cat4, 8 cat5, 88 cat6, 4 cat7
; CL prog 23/1: 60 sstall, 18 (ss), 41 systall, 6 (sy), 1 loops
; CL prog 23/1: 8 max_waves, 0 double_threadsize
; 46 preamble-instr, 1 early-preamble
