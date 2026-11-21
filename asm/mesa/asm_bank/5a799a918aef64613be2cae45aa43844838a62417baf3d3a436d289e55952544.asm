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
@const(c4.x)	0x00002000, 0x00001800, 0x00001000, 0x00000820
@const(c5.x)	0x00001020, 0x00001820, 0x00010000, 0x00007820
@const(c6.x)	0x00007020, 0x00006820, 0x00006020, 0x00005820
@const(c7.x)	0x00005020, 0x00004820, 0x00004020, 0x00003820
@const(c8.x)	0x00003020, 0x00002820, 0x00002020, 0x00010020
@const(c9.x)	0x00010800, 0x00010820, 0x00011000, 0x00011020
@const(c10.x)	0x00011800, 0x00011820, 0xd0d0d0d0, 0xd0d0d0d0
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
mov.u32u32 r52.z, 2080
mov.u32u32 r52.w, 0x1020
mov.u32u32 r53.x, 0x1820
mov.u32u32 r53.y, 0x10000
mov.u32u32 r53.z, 0x7820
mov.u32u32 r53.w, 0x7020
mov.u32u32 r54.x, 0x6820
mov.u32u32 r54.y, 0x6020
mov.u32u32 r54.z, 0x5820
mov.u32u32 r54.w, 0x5020
mov.u32u32 r55.x, 0x4820
mov.u32u32 r55.y, 0x4020
mov.u32u32 r55.z, 0x3820
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
(ss)mov.u32u32 r48.w, 0x3020
mov.u32u32 r49.x, 0x2820
mov.u32u32 r49.y, 0x2020
mov.u32u32 r49.z, 0x10020
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 4
stc.u32 c[20], r52.w, 4
stc.u32 c[24], r53.w, 4
stc.u32 c[28], r54.w, 4
(ss)mov.u32u32 r49.w, 0x10800
mov.u32u32 r50.x, 0x10820
mov.u32u32 r50.y, 0x11000
mov.u32u32 r50.z, 0x11020
mov.u32u32 r50.w, 0x11800
mov.u32u32 r51.x, 0x11820
stc.u32 c[32], r48.w, 4
(ss)nop
stc.u32 c[36], r49.w, 4
stc.u32 c[40], r50.w, 2
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l58:
(jp)(rpt1)add.u r51.y, (r)r48.x, (r)c0.x
mov.u32u32 r52.y, 0
shl.b r52.x, r51.y, 6
shl.b r51.w, r51.z, 6
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
l130:
shr.b r52.z, r52.x, 2
shr.b r52.w, r51.w, 2
(nop2) shl.b r53.x, r52.y, 9
add.u r18.z, r0.x, 64
add.u r18.w, r0.x, 128
add.u r19.x, r0.x, 192
shl.b r17.w, r0.w, 8
(rpt2)shr.b r18.z, (last)(r)r18.z, 4
(ss)add.u r19.y, r52.y, r0.w
(rpt2)add.u r19.z, r52.y, (r)r18.z
add.u r52.y, r52.y, 16
cmps.u.ge up0.x, r52.y, c1.x
shl.b r19.y, (last)r19.y, 9
(rpt2)shl.b r19.z, (last)(r)r19.z, 9
sad.s32 r19.y, r52.z, r19.y, r1.x
(rpt2)sad.s32 r19.z, r52.z, (r)r19.z, r1.x
shl.b r19.y, (last)r19.y, 2
(rpt2)shl.b r19.z, (last)(r)r19.z, 2
shl.b r18.x, r1.x, 4
sad.s32 r21.z, r53.x, r1.z, r52.w
shl.b r18.z, (last)r18.z, 8
isam.v.base0 (u32)(xyzw)r20.y, r19.y, s#0, t#2
shl.b r18.w, (last)r18.w, 8
isam.v.base0 (u32)(xyzw)r26.z, r19.z, s#0, t#2
shl.b r19.x, (last)r19.x, 8
isam.v.base0 (u32)(xyzw)r30.y, r19.w, s#0, t#2
add.u r17.w, (last)r17.w, r18.x
(ss)nop
isam.v.base0 (u32)(xyzw)r19.y, r20.x, s#0, t#2
shl.b r21.z, (last)r21.z, 2
(rpt2)add.u r18.z, (last)(r)r18.z, (last)r18.x
shl.b r18.y, r1.y, 4
add.u r21.w, r21.z, c1.x
add.u r22.x, r21.z, c4.w
add.u r22.y, r21.z, c4.z
add.u r22.z, c5.x, r21.z
add.u r22.w, c4.y, r21.z
add.u r23.x, c5.y, r21.z
add.u r23.y, c4.x, r21.z
add.u r23.z, c8.z, r21.z
add.u r23.w, c3.w, r21.z
add.u r24.x, c8.y, r21.z
add.u r24.y, c3.z, r21.z
add.u r24.z, c8.x, r21.z
add.u r24.w, c3.y, r21.z
add.u r25.x, c7.w, r21.z
add.u r25.y, c3.x, r21.z
add.u r25.z, c7.z, r21.z
add.u r25.w, c2.w, r21.z
add.u r26.x, c7.y, r21.z
add.u r26.y, c2.z, r21.z
add.u r27.z, c7.x, r21.z
add.u r27.w, c2.y, r21.z
add.u r28.x, c6.w, r21.z
add.u r28.y, c2.x, r21.z
add.u r28.z, c6.z, r21.z
add.u r28.w, c1.w, r21.z
add.u r29.x, c6.y, r21.z
add.u r29.y, c1.z, r21.z
add.u r29.z, c6.x, r21.z
add.u r29.w, c1.y, r21.z
add.u r30.x, c5.w, r21.z
shl.b r21.y, r1.z, 2
(sy)stl.u32 l[r17.w], r20.y, 4
stl.u32 l[r18.z], r26.z, 4
stl.u32 l[r18.w], r30.y, 4
stl.u32 l[r19.x], r19.y, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
isam.v.base0 (u32)(xyzw)r20.y, r21.z, s#0, t#0
isam.v.base0 (u32)(xyzw)r30.y, r21.z+32, s#0, t#0
ldl.u32 r26.z, l[r18.y], 4
ldl.u32 r18.z, l[r18.y+128], 4
(sy)(ss)(rpt1)mad.f32 r16.w, (r)r26.z, r20.y, (r)(last)r16.w
(rpt1)mad.f32 r17.y, (r)r27.x, r20.y, (r)(last)r17.y
mad.f32 r15.w, r18.z, r20.y, (last)r15.w
mad.f32 r13.w, r18.z, r20.z, (last)r13.w
mad.f32 r11.w, r18.z, r20.w, (last)r11.w
mad.f32 r9.w, r18.z, r21.x, (last)r9.w
mad.f32 r7.w, r18.z, r30.y, (last)r7.w
mad.f32 r5.w, r18.z, r30.z, (last)r5.w
mad.f32 r3.w, r18.z, r30.w, (last)r3.w
mad.f32 r16.x, r18.w, r20.y, (last)r16.x
mad.f32 r14.x, r18.w, r20.z, (last)r14.x
mad.f32 r12.x, r18.w, r20.w, (last)r12.x
mad.f32 r10.x, r18.w, r21.x, (last)r10.x
mad.f32 r8.x, r18.w, r30.y, (last)r8.x
mad.f32 r6.x, r18.w, r30.z, (last)r6.x
mad.f32 r4.x, r18.w, r30.w, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r19.x, r20.y, (r)(last)r16.y
isam.v.base0 (u32)(xyzw)r19.z, r21.w, s#0, t#0
(rpt1)mad.f32 r14.y, (r)r19.x, r20.z, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r19.x, r20.w, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r19.x, r21.x, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r19.x, r30.y, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r19.x, r30.z, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r19.x, r30.w, (r)(last)r4.y
(rpt1)mad.f32 r18.z, (r)(last)r18.z, r31.x, (r)(last)r1.w
(rpt1)mad.f32 r19.x, (r)(last)r19.x, r31.x, (r)(last)r2.y
isam.v.base0 (u32)(xyzw)r1.w, r22.x, s#0, t#0
mad.f32 r14.w, r26.z, r20.z, (last)r14.w
mad.f32 r12.w, r26.z, r20.w, (last)r12.w
mad.f32 r10.w, r26.z, r21.x, (last)r10.w
mad.f32 r15.x, r26.w, r20.z, (last)r15.x
mad.f32 r13.x, r26.w, r20.w, (last)r13.x
mad.f32 r11.x, r26.w, r21.x, (last)r11.x
mad.f32 r15.y, r27.x, r20.z, (last)r15.y
mad.f32 r13.y, r27.x, r20.w, (last)r13.y
mad.f32 r11.y, r27.x, r21.x, (last)r11.y
mad.f32 r15.z, r27.y, r20.z, (last)r15.z
mad.f32 r13.z, r27.y, r20.w, (last)r13.z
mad.f32 r11.z, r27.y, r21.x, (last)r11.z
(rpt1)mad.f32 r8.w, (r)r26.z, r30.y, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r27.x, r30.y, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r26.z, r30.z, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r27.x, r30.z, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r26.z, r30.w, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r27.x, r30.w, (r)(last)r5.y
(rpt1)mad.f32 r26.z, (r)(last)r26.z, r31.x, (r)(last)r2.w
(rpt1)mad.f32 r27.x, (r)(last)r27.x, r31.x, (r)(last)r3.y
ldl.u32 r30.y, l[r18.y+256], 4
ldl.u32 r2.w, l[r18.y+384], 4
(sy)(ss)mad.f32 r15.w, r2.w, r19.z, (last)r15.w
mad.f32 r13.w, r2.w, r19.w, (last)r13.w
mad.f32 r11.w, r2.w, r20.x, (last)r11.w
mad.f32 r9.w, r2.w, r20.y, (last)r9.w
mad.f32 r7.w, r2.w, r1.w, (last)r7.w
mad.f32 r5.w, r2.w, r2.x, (last)r5.w
mad.f32 r3.w, r2.w, r2.y, (last)r3.w
mad.f32 r16.x, r3.x, r19.z, (last)r16.x
mad.f32 r14.x, r3.x, r19.w, (last)r14.x
mad.f32 r12.x, r3.x, r20.x, (last)r12.x
mad.f32 r10.x, r3.x, r20.y, (last)r10.x
mad.f32 r8.x, r3.x, r1.w, (last)r8.x
mad.f32 r6.x, r3.x, r2.x, (last)r6.x
mad.f32 r4.x, r3.x, r2.y, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r3.y, r19.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r3.y, r19.w, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r3.y, r20.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r3.y, r20.y, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r3.y, r1.w, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r3.y, r2.x, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r3.y, r2.y, (r)(last)r4.y
(rpt1)mad.f32 r2.w, (r)(last)r2.w, r2.z, (r)(last)r18.z
(rpt1)mad.f32 r3.y, (r)(last)r3.y, r2.z, (r)(last)r19.x
isam.v.base0 (u32)(xyzw)r18.z, r22.y, s#0, t#0
(ss)nop
isam.v.base0 (u32)(xyzw)r21.z, r22.z, s#0, t#0
mad.f32 r16.w, r30.y, r19.z, (last)r16.w
mad.f32 r14.w, r30.y, r19.w, (last)r14.w
mad.f32 r12.w, r30.y, r20.x, (last)r12.w
mad.f32 r10.w, r30.y, r20.y, (last)r10.w
mad.f32 r17.x, r30.z, r19.z, (last)r17.x
mad.f32 r15.x, r30.z, r19.w, (last)r15.x
mad.f32 r13.x, r30.z, r20.x, (last)r13.x
mad.f32 r11.x, r30.z, r20.y, (last)r11.x
mad.f32 r17.y, r30.w, r19.z, (last)r17.y
mad.f32 r15.y, r30.w, r19.w, (last)r15.y
mad.f32 r13.y, r30.w, r20.x, (last)r13.y
mad.f32 r11.y, r30.w, r20.y, (last)r11.y
mad.f32 r17.z, r31.x, r19.z, (last)r17.z
mad.f32 r15.z, r31.x, r19.w, (last)r15.z
mad.f32 r13.z, r31.x, r20.x, (last)r13.z
mad.f32 r11.z, r31.x, r20.y, (last)r11.z
ldl.u32 r19.z, l[r18.y+512], 4
(rpt1)mad.f32 r8.w, (r)r30.y, r1.w, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r30.w, r1.w, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r30.y, r2.x, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r30.w, r2.x, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r30.y, r2.y, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r30.w, r2.y, (r)(last)r5.y
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r2.z, (r)(last)r26.z
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r2.z, (r)(last)r27.x
ldl.u32 r26.z, l[r18.y+640], 4
(sy)(ss)mad.f32 r16.w, r19.z, r18.z, (last)r16.w
mad.f32 r14.w, r19.z, r18.w, (last)r14.w
mad.f32 r12.w, r19.z, r19.x, (last)r12.w
mad.f32 r10.w, r19.z, r19.y, (last)r10.w
mad.f32 r17.x, r19.w, r18.z, (last)r17.x
mad.f32 r15.x, r19.w, r18.w, (last)r15.x
mad.f32 r13.x, r19.w, r19.x, (last)r13.x
mad.f32 r11.x, r19.w, r19.y, (last)r11.x
mad.f32 r17.y, r20.x, r18.z, (last)r17.y
mad.f32 r15.y, r20.x, r18.w, (last)r15.y
mad.f32 r13.y, r20.x, r19.x, (last)r13.y
mad.f32 r11.y, r20.x, r19.y, (last)r11.y
mad.f32 r17.z, r20.y, r18.z, (last)r17.z
mad.f32 r15.z, r20.y, r18.w, (last)r15.z
mad.f32 r13.z, r20.y, r19.x, (last)r13.z
mad.f32 r11.z, r20.y, r19.y, (last)r11.z
(rpt1)mad.f32 r8.w, (r)r19.z, r21.z, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r20.x, r21.z, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r19.z, r21.w, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r20.x, r21.w, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r19.z, r22.x, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r20.x, r22.x, (r)(last)r5.y
mad.f32 r15.w, r26.z, r18.z, (last)r15.w
mad.f32 r13.w, r26.z, r18.w, (last)r13.w
mad.f32 r11.w, r26.z, r19.x, (last)r11.w
mad.f32 r9.w, r26.z, r19.y, (last)r9.w
mad.f32 r16.x, r26.w, r18.z, (last)r16.x
mad.f32 r14.x, r26.w, r18.w, (last)r14.x
mad.f32 r12.x, r26.w, r19.x, (last)r12.x
mad.f32 r10.x, r26.w, r19.y, (last)r10.x
(rpt1)mad.f32 r16.y, (r)r27.x, r18.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r27.x, r18.w, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r27.x, r19.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r27.x, r19.y, (r)(last)r10.y
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r22.y, (r)(last)r30.y
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r22.y, (r)(last)r30.w
isam.v.base0 (u32)(xyzw)r30.y, r22.w, s#0, t#0
isam.v.base0 (u32)(xyzw)r18.z, r23.x, s#0, t#0
mad.f32 r7.w, r26.z, r21.z, (last)r7.w
mad.f32 r5.w, r26.z, r21.w, (last)r5.w
mad.f32 r3.w, r26.z, r22.x, (last)r3.w
mad.f32 r26.z, (last)r26.z, r22.y, (last)r2.w
ldl.u32 r2.x, l[r18.y+768], 4
mad.f32 r8.x, r26.w, r21.z, (last)r8.x
mad.f32 r6.x, r26.w, r21.w, (last)r6.x
mad.f32 r4.x, r26.w, r22.x, (last)r4.x
(rpt1)mad.f32 r8.y, (r)r27.x, r21.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r27.x, r21.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r27.x, r22.x, (r)(last)r4.y
mad.f32 r26.w, (last)r26.w, r22.y, (last)r3.x
(rpt1)mad.f32 r27.x, (r)(last)r27.x, r22.y, (r)(last)r3.y
(ss)nop
ldl.u32 r22.x, l[r18.y+896], 4
(sy)mad.f32 r16.w, r2.x, r30.y, (last)r16.w
mad.f32 r14.w, r2.x, r30.z, (last)r14.w
mad.f32 r12.w, r2.x, r30.w, (last)r12.w
mad.f32 r10.w, r2.x, r31.x, (last)r10.w
mad.f32 r17.x, r2.y, r30.y, (last)r17.x
mad.f32 r15.x, r2.y, r30.z, (last)r15.x
mad.f32 r13.x, r2.y, r30.w, (last)r13.x
mad.f32 r11.x, r2.y, r31.x, (last)r11.x
mad.f32 r17.y, r2.z, r30.y, (last)r17.y
mad.f32 r15.y, r2.z, r30.z, (last)r15.y
mad.f32 r13.y, r2.z, r30.w, (last)r13.y
mad.f32 r11.y, r2.z, r31.x, (last)r11.y
mad.f32 r17.z, r2.w, r30.y, (last)r17.z
mad.f32 r15.z, r2.w, r30.z, (last)r15.z
mad.f32 r13.z, r2.w, r30.w, (last)r13.z
mad.f32 r11.z, r2.w, r31.x, (last)r11.z
(rpt1)mad.f32 r8.w, (r)r2.x, r18.z, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r2.z, r18.z, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r2.x, r18.w, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r2.z, r18.w, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r2.x, r19.x, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r2.z, r19.x, (r)(last)r5.y
(ss)mad.f32 r15.w, r22.x, r30.y, (last)r15.w
mad.f32 r13.w, r22.x, r30.z, (last)r13.w
mad.f32 r11.w, r22.x, r30.w, (last)r11.w
mad.f32 r9.w, r22.x, r31.x, (last)r9.w
mad.f32 r7.w, r22.x, r18.z, (last)r7.w
mad.f32 r5.w, r22.x, r18.w, (last)r5.w
mad.f32 r3.w, r22.x, r19.x, (last)r3.w
mad.f32 r16.x, r22.y, r30.y, (last)r16.x
mad.f32 r14.x, r22.y, r30.z, (last)r14.x
mad.f32 r12.x, r22.y, r30.w, (last)r12.x
mad.f32 r10.x, r22.y, r31.x, (last)r10.x
mad.f32 r8.x, r22.y, r18.z, (last)r8.x
mad.f32 r6.x, r22.y, r18.w, (last)r6.x
mad.f32 r4.x, r22.y, r19.x, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r22.z, r30.y, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r22.z, r30.z, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r22.z, r30.w, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r22.z, r31.x, (r)(last)r10.y
ldl.u32 r30.y, l[r18.y+1024], 4
(rpt1)mad.f32 r8.y, (r)r22.z, r18.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r22.z, r18.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r22.z, r19.x, (r)(last)r4.y
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r19.y, (r)(last)r19.z
(rpt1)mad.f32 r2.z, (r)(last)r2.z, r19.y, (r)(last)r20.x
ldl.u32 r19.z, l[r18.y+1152], 4
(rpt1)mad.f32 r22.x, (r)(last)r22.x, r19.y, (r)(last)r26.z
(rpt1)mad.f32 r22.z, (r)(last)r22.z, r19.y, (r)(last)r27.x
isam.v.base0 (u32)(xyzw)r26.z, r23.y, s#0, t#0
isam.v.base0 (u32)(xyzw)r18.z, r23.z, s#0, t#0
(sy)(ss)mad.f32 r15.w, r19.z, r26.z, (last)r15.w
mad.f32 r13.w, r19.z, r26.w, (last)r13.w
mad.f32 r11.w, r19.z, r27.x, (last)r11.w
mad.f32 r9.w, r19.z, r27.y, (last)r9.w
mad.f32 r16.x, r19.w, r26.z, (last)r16.x
mad.f32 r14.x, r19.w, r26.w, (last)r14.x
mad.f32 r12.x, r19.w, r27.x, (last)r12.x
mad.f32 r10.x, r19.w, r27.y, (last)r10.x
mad.f32 r7.w, r19.z, r18.z, (last)r7.w
mad.f32 r5.w, r19.z, r18.w, (last)r5.w
mad.f32 r3.w, r19.z, r19.x, (last)r3.w
mad.f32 r8.x, r19.w, r18.z, (last)r8.x
mad.f32 r6.x, r19.w, r18.w, (last)r6.x
mad.f32 r4.x, r19.w, r19.x, (last)r4.x
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r19.y, (r)(last)r22.x
isam.v.base0 (u32)(xyzw)r21.z, r23.w, s#0, t#0
mad.f32 r16.w, r30.y, r26.z, (last)r16.w
mad.f32 r14.w, r30.y, r26.w, (last)r14.w
mad.f32 r12.w, r30.y, r27.x, (last)r12.w
mad.f32 r10.w, r30.y, r27.y, (last)r10.w
mad.f32 r17.x, r30.z, r26.z, (last)r17.x
mad.f32 r15.x, r30.z, r26.w, (last)r15.x
mad.f32 r13.x, r30.z, r27.x, (last)r13.x
mad.f32 r11.x, r30.z, r27.y, (last)r11.x
mad.f32 r17.y, r30.w, r26.z, (last)r17.y
mad.f32 r15.y, r30.w, r26.w, (last)r15.y
mad.f32 r13.y, r30.w, r27.x, (last)r13.y
mad.f32 r11.y, r30.w, r27.y, (last)r11.y
mad.f32 r17.z, r31.x, r26.z, (last)r17.z
mad.f32 r15.z, r31.x, r26.w, (last)r15.z
mad.f32 r13.z, r31.x, r27.x, (last)r13.z
mad.f32 r11.z, r31.x, r27.y, (last)r11.z
(rpt1)mad.f32 r16.y, (r)r20.x, r26.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r20.x, r26.w, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r20.x, r27.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r20.x, r27.y, (r)(last)r10.y
isam.v.base0 (u32)(xyzw)r26.z, r24.x, s#0, t#0
(rpt1)mad.f32 r8.w, (r)r30.y, r18.z, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r30.w, r18.z, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r30.y, r18.w, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r30.w, r18.w, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r30.y, r19.x, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r30.w, r19.x, (r)(last)r5.y
(rpt1)mad.f32 r8.y, (r)r20.x, r18.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r20.x, r18.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r20.x, r19.x, (r)(last)r4.y
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r19.y, (r)(last)r2.x
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r19.y, (r)(last)r2.z
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r19.y, (r)(last)r22.z
ldl.u32 r22.z, l[r18.y+1280], 4
ldl.u32 r2.x, l[r18.y+1408], 4
isam.v.base0 (u32)(xyzw)r18.z, r24.y, s#0, t#0
(sy)(ss)mad.f32 r16.w, r22.z, r21.z, (last)r16.w
mad.f32 r14.w, r22.z, r21.w, (last)r14.w
mad.f32 r12.w, r22.z, r22.x, (last)r12.w
mad.f32 r10.w, r22.z, r22.y, (last)r10.w
mad.f32 r17.x, r22.w, r21.z, (last)r17.x
mad.f32 r15.x, r22.w, r21.w, (last)r15.x
mad.f32 r13.x, r22.w, r22.x, (last)r13.x
mad.f32 r11.x, r22.w, r22.y, (last)r11.x
mad.f32 r17.y, r23.x, r21.z, (last)r17.y
mad.f32 r15.y, r23.x, r21.w, (last)r15.y
mad.f32 r13.y, r23.x, r22.x, (last)r13.y
mad.f32 r11.y, r23.x, r22.y, (last)r11.y
mad.f32 r17.z, r23.y, r21.z, (last)r17.z
mad.f32 r15.z, r23.y, r21.w, (last)r15.z
mad.f32 r13.z, r23.y, r22.x, (last)r13.z
mad.f32 r11.z, r23.y, r22.y, (last)r11.z
mad.f32 r15.w, r2.x, r21.z, (last)r15.w
mad.f32 r13.w, r2.x, r21.w, (last)r13.w
mad.f32 r11.w, r2.x, r22.x, (last)r11.w
mad.f32 r9.w, r2.x, r22.y, (last)r9.w
mad.f32 r16.x, r2.y, r21.z, (last)r16.x
mad.f32 r14.x, r2.y, r21.w, (last)r14.x
mad.f32 r12.x, r2.y, r22.x, (last)r12.x
mad.f32 r10.x, r2.y, r22.y, (last)r10.x
(rpt1)mad.f32 r16.y, (r)r2.z, r21.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r2.z, r21.w, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r2.z, r22.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r2.z, r22.y, (r)(last)r10.y
isam.v.base0 (u32)(xyzw)r21.z, r24.z, s#0, t#0
(rpt1)mad.f32 r8.y, (r)r2.z, r26.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r2.z, r26.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r2.z, r27.x, (r)(last)r4.y
(rpt1)mad.f32 r2.z, (r)(last)r2.z, r27.y, (r)(last)r20.x
ldl.u32 r20.x, l[r18.y+1536], 4
ldl.u32 r23.z, l[r18.y+1664], 4
mad.f32 r7.w, r2.x, r26.z, (last)r7.w
mad.f32 r5.w, r2.x, r26.w, (last)r5.w
mad.f32 r3.w, r2.x, r27.x, (last)r3.w
mad.f32 r8.x, r2.y, r26.z, (last)r8.x
mad.f32 r6.x, r2.y, r26.w, (last)r6.x
mad.f32 r4.x, r2.y, r27.x, (last)r4.x
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r27.y, (r)(last)r19.z
(rpt1)mad.f32 r8.w, (r)r22.z, r26.z, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r23.x, r26.z, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r22.z, r26.w, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r23.x, r26.w, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r22.z, r27.x, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r23.x, r27.x, (r)(last)r5.y
(ss)mad.f32 r15.w, r23.z, r18.z, (last)r15.w
mad.f32 r13.w, r23.z, r18.w, (last)r13.w
mad.f32 r11.w, r23.z, r19.x, (last)r11.w
mad.f32 r9.w, r23.z, r19.y, (last)r9.w
mad.f32 r16.x, r23.w, r18.z, (last)r16.x
mad.f32 r14.x, r23.w, r18.w, (last)r14.x
mad.f32 r12.x, r23.w, r19.x, (last)r12.x
mad.f32 r10.x, r23.w, r19.y, (last)r10.x
mad.f32 r16.y, r24.x, r18.z, (last)r16.y
mad.f32 r14.y, r24.x, r18.w, (last)r14.y
mad.f32 r12.y, r24.x, r19.x, (last)r12.y
mad.f32 r10.y, r24.x, r19.y, (last)r10.y
(sy)mad.f32 r8.y, r24.x, r21.z, (last)r8.y
mad.f32 r6.y, r24.x, r21.w, (last)r6.y
mad.f32 r4.y, r24.x, r22.x, (last)r4.y
mad.f32 r7.w, r23.z, r21.z, (last)r7.w
mad.f32 r5.w, r23.z, r21.w, (last)r5.w
mad.f32 r3.w, r23.z, r22.x, (last)r3.w
mad.f32 r8.x, r23.w, r21.z, (last)r8.x
mad.f32 r6.x, r23.w, r21.w, (last)r6.x
mad.f32 r4.x, r23.w, r22.x, (last)r4.x
(rpt1)mad.f32 r22.z, (r)(last)r22.z, r27.y, (r)(last)r30.y
(rpt1)mad.f32 r23.x, (r)(last)r23.x, r27.y, (r)(last)r30.w
isam.v.base0 (u32)(xyzw)r26.z, r24.w, s#0, t#0
ldl.u32 r30.y, l[r18.y+1792], 4
mad.f32 r24.x, (last)r24.x, r22.y, (last)r2.z
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r22.y, (r)(last)r2.x
isam.v.base0 (u32)(xyzw)r1.w, r25.x, s#0, t#0
mad.f32 r16.w, r20.x, r18.z, (last)r16.w
mad.f32 r14.w, r20.x, r18.w, (last)r14.w
mad.f32 r12.w, r20.x, r19.x, (last)r12.w
mad.f32 r10.w, r20.x, r19.y, (last)r10.w
mad.f32 r17.x, r20.y, r18.z, (last)r17.x
mad.f32 r15.x, r20.y, r18.w, (last)r15.x
mad.f32 r13.x, r20.y, r19.x, (last)r13.x
mad.f32 r11.x, r20.y, r19.y, (last)r11.x
mad.f32 r17.y, r20.z, r18.z, (last)r17.y
mad.f32 r15.y, r20.z, r18.w, (last)r15.y
mad.f32 r13.y, r20.z, r19.x, (last)r13.y
mad.f32 r11.y, r20.z, r19.y, (last)r11.y
mad.f32 r17.z, r20.w, r18.z, (last)r17.z
mad.f32 r15.z, r20.w, r18.w, (last)r15.z
mad.f32 r13.z, r20.w, r19.x, (last)r13.z
mad.f32 r11.z, r20.w, r19.y, (last)r11.z
(rpt1)mad.f32 r8.w, (r)r20.x, r21.z, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r20.z, r21.z, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r20.x, r21.w, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r20.z, r21.w, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r20.x, r22.x, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r20.z, r22.x, (r)(last)r5.y
(rpt1)mad.f32 r20.x, (r)(last)r20.x, r22.y, (r)(last)r22.z
(rpt1)mad.f32 r20.z, (r)(last)r20.z, r22.y, (r)(last)r23.x
mad.f32 r12.z, r24.y, r19.x, (last)r12.z
mad.f32 r10.z, r24.y, r19.y, (last)r10.z
ldl.u32 r19.x, l[r18.y+1920], 4
mad.f32 r16.z, r24.y, r18.z, (last)r16.z
mad.f32 r14.z, r24.y, r18.w, (last)r14.z
mad.f32 r8.z, r24.y, r21.z, (last)r8.z
mad.f32 r6.z, r24.y, r21.w, (last)r6.z
mad.f32 r4.z, r24.y, r22.x, (last)r4.z
mad.f32 r24.y, (last)r24.y, r22.y, (last)r2.w
ldl.u32 r21.z, l[r18.y+2048], 4
(sy)(ss)mad.f32 r16.w, r30.y, r26.z, (last)r16.w
mad.f32 r14.w, r30.y, r26.w, (last)r14.w
mad.f32 r12.w, r30.y, r27.x, (last)r12.w
mad.f32 r10.w, r30.y, r27.y, (last)r10.w
mad.f32 r17.x, r30.z, r26.z, (last)r17.x
mad.f32 r15.x, r30.z, r26.w, (last)r15.x
mad.f32 r13.x, r30.z, r27.x, (last)r13.x
mad.f32 r11.x, r30.z, r27.y, (last)r11.x
mad.f32 r17.y, r30.w, r26.z, (last)r17.y
mad.f32 r15.y, r30.w, r26.w, (last)r15.y
mad.f32 r13.y, r30.w, r27.x, (last)r13.y
mad.f32 r11.y, r30.w, r27.y, (last)r11.y
mad.f32 r17.z, r31.x, r26.z, (last)r17.z
mad.f32 r15.z, r31.x, r26.w, (last)r15.z
mad.f32 r13.z, r31.x, r27.x, (last)r13.z
mad.f32 r11.z, r31.x, r27.y, (last)r11.z
(rpt1)mad.f32 r8.w, (r)r30.y, r1.w, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r30.w, r1.w, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r30.y, r2.x, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r30.w, r2.x, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r30.y, r2.y, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r30.w, r2.y, (r)(last)r5.y
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r2.z, (r)(last)r20.x
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r2.z, (r)(last)r20.z
isam.v.base0 (u32)(xyzw)r20.x, r25.y, s#0, t#0
isam.v.base0 (u32)(xyzw)r22.z, r25.z, s#0, t#0
(ss)nop
isam.v.base0 (u32)(xyzw)r24.z, r25.w, s#0, t#0
mad.f32 r15.w, r19.x, r26.z, (last)r15.w
mad.f32 r13.w, r19.x, r26.w, (last)r13.w
mad.f32 r11.w, r19.x, r27.x, (last)r11.w
mad.f32 r9.w, r19.x, r27.y, (last)r9.w
mad.f32 r7.w, r19.x, r1.w, (last)r7.w
mad.f32 r5.w, r19.x, r2.x, (last)r5.w
mad.f32 r3.w, r19.x, r2.y, (last)r3.w
mad.f32 r16.x, r19.y, r26.z, (last)r16.x
mad.f32 r14.x, r19.y, r26.w, (last)r14.x
mad.f32 r12.x, r19.y, r27.x, (last)r12.x
mad.f32 r10.x, r19.y, r27.y, (last)r10.x
mad.f32 r8.x, r19.y, r1.w, (last)r8.x
mad.f32 r6.x, r19.y, r2.x, (last)r6.x
mad.f32 r4.x, r19.y, r2.y, (last)r4.x
mad.f32 r16.y, r19.z, r26.z, (last)r16.y
mad.f32 r14.y, r19.z, r26.w, (last)r14.y
(rpt1)mad.f32 r12.y, (r)r19.z, r27.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r19.z, r27.y, (r)(last)r10.y
mad.f32 r8.y, r19.z, r1.w, (last)r8.y
mad.f32 r6.y, r19.z, r2.x, (last)r6.y
mad.f32 r4.y, r19.z, r2.y, (last)r4.y
mad.f32 r16.z, r19.w, r26.z, (last)r16.z
mad.f32 r14.z, r19.w, r26.w, (last)r14.z
mad.f32 r8.z, r19.w, r1.w, (last)r8.z
mad.f32 r6.z, r19.w, r2.x, (last)r6.z
mad.f32 r4.z, r19.w, r2.y, (last)r4.z
(rpt1)mad.f32 r19.x, (r)(last)r19.x, r2.z, (r)(last)r23.z
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r2.z, (r)(last)r24.x
isam.v.base0 (u32)(xyzw)r1.w, r26.x, s#0, t#0
ldl.u32 r23.z, l[r18.y+2176], 4
(sy)mad.f32 r16.w, r21.z, r20.x, (last)r16.w
mad.f32 r14.w, r21.z, r20.y, (last)r14.w
mad.f32 r12.w, r21.z, r20.z, (last)r12.w
mad.f32 r10.w, r21.z, r20.w, (last)r10.w
mad.f32 r17.x, r21.w, r20.x, (last)r17.x
mad.f32 r15.x, r21.w, r20.y, (last)r15.x
mad.f32 r13.x, r21.w, r20.z, (last)r13.x
mad.f32 r11.x, r21.w, r20.w, (last)r11.x
mad.f32 r17.y, r22.x, r20.x, (last)r17.y
mad.f32 r15.y, r22.x, r20.y, (last)r15.y
mad.f32 r13.y, r22.x, r20.z, (last)r13.y
mad.f32 r11.y, r22.x, r20.w, (last)r11.y
mad.f32 r17.z, r22.y, r20.x, (last)r17.z
mad.f32 r15.z, r22.y, r20.y, (last)r15.z
mad.f32 r13.z, r22.y, r20.z, (last)r13.z
mad.f32 r11.z, r22.y, r20.w, (last)r11.z
(rpt1)mad.f32 r8.w, (r)r21.z, r22.z, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r22.x, r22.z, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r21.z, r22.w, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r22.x, r22.w, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r21.z, r23.x, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r22.x, r23.x, (r)(last)r5.y
(ss)mad.f32 r15.w, r23.z, r20.x, (last)r15.w
mad.f32 r13.w, r23.z, r20.y, (last)r13.w
mad.f32 r11.w, r23.z, r20.z, (last)r11.w
mad.f32 r9.w, r23.z, r20.w, (last)r9.w
mad.f32 r7.w, r23.z, r22.z, (last)r7.w
mad.f32 r5.w, r23.z, r22.w, (last)r5.w
mad.f32 r3.w, r23.z, r23.x, (last)r3.w
mad.f32 r16.x, r23.w, r20.x, (last)r16.x
mad.f32 r14.x, r23.w, r20.y, (last)r14.x
mad.f32 r12.x, r23.w, r20.z, (last)r12.x
mad.f32 r10.x, r23.w, r20.w, (last)r10.x
mad.f32 r8.x, r23.w, r22.z, (last)r8.x
mad.f32 r6.x, r23.w, r22.w, (last)r6.x
mad.f32 r4.x, r23.w, r23.x, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r24.x, r20.x, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r24.x, r20.y, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r24.x, r20.z, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r24.x, r20.w, (r)(last)r10.y
isam.v.base0 (u32)(xyzw)r20.x, r26.y, s#0, t#0
(rpt1)mad.f32 r8.y, (r)r24.x, r22.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r24.x, r22.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r24.x, r23.x, (r)(last)r4.y
(rpt1)mad.f32 r21.z, (r)(last)r21.z, r23.y, (r)(last)r30.y
(rpt1)mad.f32 r22.x, (r)(last)r22.x, r23.y, (r)(last)r30.w
ldl.u32 r30.y, l[r18.y+2304], 4
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r23.y, (r)(last)r19.x
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r23.y, (r)(last)r19.z
isam.v.base0 (u32)(xyzw)r22.z, r27.z, s#0, t#0
ldl.u32 r19.x, l[r18.y+2432], 4
(ss)mad.f32 r16.w, r30.y, r24.z, (last)r16.w
mad.f32 r14.w, r30.y, r24.w, (last)r14.w
mad.f32 r12.w, r30.y, r25.x, (last)r12.w
mad.f32 r10.w, r30.y, r25.y, (last)r10.w
mad.f32 r17.x, r30.z, r24.z, (last)r17.x
mad.f32 r15.x, r30.z, r24.w, (last)r15.x
mad.f32 r13.x, r30.z, r25.x, (last)r13.x
mad.f32 r11.x, r30.z, r25.y, (last)r11.x
mad.f32 r17.y, r30.w, r24.z, (last)r17.y
mad.f32 r15.y, r30.w, r24.w, (last)r15.y
mad.f32 r13.y, r30.w, r25.x, (last)r13.y
mad.f32 r11.y, r30.w, r25.y, (last)r11.y
mad.f32 r17.z, r31.x, r24.z, (last)r17.z
mad.f32 r15.z, r31.x, r24.w, (last)r15.z
mad.f32 r13.z, r31.x, r25.x, (last)r13.z
mad.f32 r11.z, r31.x, r25.y, (last)r11.z
mad.f32 r15.w, r19.x, r24.z, (last)r15.w
mad.f32 r13.w, r19.x, r24.w, (last)r13.w
mad.f32 r11.w, r19.x, r25.x, (last)r11.w
mad.f32 r9.w, r19.x, r25.y, (last)r9.w
mad.f32 r16.x, r19.y, r24.z, (last)r16.x
mad.f32 r14.x, r19.y, r24.w, (last)r14.x
mad.f32 r12.x, r19.y, r25.x, (last)r12.x
mad.f32 r10.x, r19.y, r25.y, (last)r10.x
(rpt1)mad.f32 r16.y, (r)r19.z, r24.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r19.z, r24.w, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r19.z, r25.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r19.z, r25.y, (r)(last)r10.y
isam.v.base0 (u32)(xyzw)r24.z, r27.w, s#0, t#0
(ss)nop
isam.v.base0 (u32)(xyzw)r27.x, r28.x, s#0, t#0
(rpt1)mad.f32 r8.w, (r)r30.y, r1.w, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r30.w, r1.w, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r30.y, r2.x, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r30.w, r2.x, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r30.y, r2.y, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r30.w, r2.y, (r)(last)r5.y
mad.f32 r7.w, r19.x, r1.w, (last)r7.w
mad.f32 r5.w, r19.x, r2.x, (last)r5.w
mad.f32 r3.w, r19.x, r2.y, (last)r3.w
mad.f32 r8.x, r19.y, r1.w, (last)r8.x
mad.f32 r6.x, r19.y, r2.x, (last)r6.x
mad.f32 r4.x, r19.y, r2.y, (last)r4.x
(rpt1)mad.f32 r8.y, (r)r19.z, r1.w, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r19.z, r2.x, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r19.z, r2.y, (r)(last)r4.y
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r2.z, (r)(last)r21.z
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r2.z, (r)(last)r22.x
ldl.u32 r21.z, l[r18.y+2560], 4
(rpt1)mad.f32 r19.x, (r)(last)r19.x, r2.z, (r)(last)r23.z
(rpt1)mad.f32 r19.z, (r)(last)r19.z, r2.z, (r)(last)r24.x
ldl.u32 r23.z, l[r18.y+2688], 4
isam.v.base0 (u32)(xyzw)r1.w, r28.y, s#0, t#0
ldl.u32 r26.x, l[r18.y+2816], 4
(sy)(ss)mad.f32 r16.w, r21.z, r20.x, (last)r16.w
mad.f32 r14.w, r21.z, r20.y, (last)r14.w
mad.f32 r12.w, r21.z, r20.z, (last)r12.w
mad.f32 r10.w, r21.z, r20.w, (last)r10.w
mad.f32 r17.x, r21.w, r20.x, (last)r17.x
mad.f32 r15.x, r21.w, r20.y, (last)r15.x
mad.f32 r13.x, r21.w, r20.z, (last)r13.x
mad.f32 r11.x, r21.w, r20.w, (last)r11.x
mad.f32 r17.y, r22.x, r20.x, (last)r17.y
mad.f32 r15.y, r22.x, r20.y, (last)r15.y
mad.f32 r13.y, r22.x, r20.z, (last)r13.y
mad.f32 r11.y, r22.x, r20.w, (last)r11.y
mad.f32 r17.z, r22.y, r20.x, (last)r17.z
mad.f32 r15.z, r22.y, r20.y, (last)r15.z
mad.f32 r13.z, r22.y, r20.z, (last)r13.z
mad.f32 r11.z, r22.y, r20.w, (last)r11.z
(rpt1)mad.f32 r8.w, (r)r21.z, r22.z, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r22.x, r22.z, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r21.z, r22.w, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r22.x, r22.w, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r21.z, r23.x, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r22.x, r23.x, (r)(last)r5.y
mad.f32 r15.w, r23.z, r20.x, (last)r15.w
mad.f32 r13.w, r23.z, r20.y, (last)r13.w
mad.f32 r16.x, r23.w, r20.x, (last)r16.x
mad.f32 r14.x, r23.w, r20.y, (last)r14.x
(rpt1)mad.f32 r16.y, (r)r24.x, r20.x, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r24.x, r20.y, (r)(last)r14.y
(rpt1)mad.f32 r12.y, (r)r24.x, r20.z, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r24.x, r20.w, (r)(last)r10.y
(rpt1)mad.f32 r8.y, (r)r24.x, r22.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r24.x, r22.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r24.x, r23.x, (r)(last)r4.y
(rpt1)mad.f32 r21.z, (r)(last)r21.z, r23.y, (r)(last)r30.y
(rpt1)mad.f32 r22.x, (r)(last)r22.x, r23.y, (r)(last)r30.w
ldl.u32 r30.y, l[r18.y+2944], 4
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r23.y, (r)(last)r19.z
isam.v.base0 (u32)(xyzw)r19.z, r28.z, s#0, t#0
mad.f32 r11.w, r23.z, r20.z, (last)r11.w
mad.f32 r9.w, r23.z, r20.w, (last)r9.w
mad.f32 r12.x, r23.w, r20.z, (last)r12.x
mad.f32 r10.x, r23.w, r20.w, (last)r10.x
mad.f32 r7.w, r23.z, r22.z, (last)r7.w
mad.f32 r5.w, r23.z, r22.w, (last)r5.w
mad.f32 r3.w, r23.z, r23.x, (last)r3.w
mad.f32 r8.x, r23.w, r22.z, (last)r8.x
mad.f32 r6.x, r23.w, r22.w, (last)r6.x
mad.f32 r4.x, r23.w, r23.x, (last)r4.x
mad.f32 r12.w, r26.x, r25.x, (last)r12.w
mad.f32 r10.w, r26.x, r25.y, (last)r10.w
mad.f32 r13.x, r26.y, r25.x, (last)r13.x
mad.f32 r11.x, r26.y, r25.y, (last)r11.x
mad.f32 r13.y, r26.z, r25.x, (last)r13.y
mad.f32 r11.y, r26.z, r25.y, (last)r11.y
mad.f32 r13.z, r26.w, r25.x, (last)r13.z
mad.f32 r11.z, r26.w, r25.y, (last)r11.z
(ss)(rpt1)mad.f32 r12.y, (r)r30.w, r25.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r30.w, r25.y, (r)(last)r10.y
mad.f32 r11.w, r30.y, r25.x, (last)r11.w
mad.f32 r9.w, r30.y, r25.y, (last)r9.w
mad.f32 r12.x, r30.z, r25.x, (last)r12.x
mad.f32 r10.x, r30.z, r25.y, (last)r10.x
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r23.y, (r)(last)r19.x
isam.v.base0 (u32)(xyzw)r22.z, r28.w, s#0, t#0
isam.v.base0 (u32)(xyzw)r25.x, r29.x, s#0, t#0
ldl.u32 r18.z, l[r18.y+3072], 4
mad.f32 r16.w, r26.x, r24.z, (last)r16.w
mad.f32 r14.w, r26.x, r24.w, (last)r14.w
mad.f32 r17.x, r26.y, r24.z, (last)r17.x
mad.f32 r15.x, r26.y, r24.w, (last)r15.x
mad.f32 r17.y, r26.z, r24.z, (last)r17.y
mad.f32 r15.y, r26.z, r24.w, (last)r15.y
mad.f32 r17.z, r26.w, r24.z, (last)r17.z
mad.f32 r15.z, r26.w, r24.w, (last)r15.z
(rpt1)mad.f32 r8.w, (r)r26.x, r27.x, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r26.z, r27.x, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r26.x, r27.y, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r26.z, r27.y, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r26.x, r27.z, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r26.z, r27.z, (r)(last)r5.y
(rpt1)mad.f32 r26.x, (r)(last)r26.x, r27.w, (r)(last)r21.z
(rpt1)mad.f32 r26.z, (r)(last)r26.z, r27.w, (r)(last)r22.x
ldl.u32 r21.z, l[r18.y+3200], 4
mad.f32 r15.w, r30.y, r24.z, (last)r15.w
mad.f32 r13.w, r30.y, r24.w, (last)r13.w
mad.f32 r16.x, r30.z, r24.z, (last)r16.x
mad.f32 r14.x, r30.z, r24.w, (last)r14.x
(rpt1)mad.f32 r16.y, (r)r30.w, r24.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r30.w, r24.w, (r)(last)r14.y
(rpt1)mad.f32 r8.y, (r)r30.w, r27.x, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r30.w, r27.y, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r30.w, r27.z, (r)(last)r4.y
mad.f32 r7.w, r30.y, r27.x, (last)r7.w
mad.f32 r5.w, r30.y, r27.y, (last)r5.w
mad.f32 r3.w, r30.y, r27.z, (last)r3.w
mad.f32 r8.x, r30.z, r27.x, (last)r8.x
mad.f32 r6.x, r30.z, r27.y, (last)r6.x
mad.f32 r4.x, r30.z, r27.z, (last)r4.x
(rpt1)mad.f32 r30.w, (r)(last)r30.w, r27.w, (r)(last)r24.x
ldl.u32 r24.x, l[r18.y+3328], 4
(rpt1)mad.f32 r30.y, (r)(last)r30.y, r27.w, (r)(last)r23.z
isam.v.base0 (u32)(xyzw)r27.x, r29.y, s#0, t#0
(ss)mad.f32 r12.w, r18.z, r2.y, (last)r12.w
mad.f32 r10.w, r18.z, r2.z, (last)r10.w
mad.f32 r13.x, r18.w, r2.y, (last)r13.x
mad.f32 r11.x, r18.w, r2.z, (last)r11.x
mad.f32 r13.y, r19.x, r2.y, (last)r13.y
mad.f32 r11.y, r19.x, r2.z, (last)r11.y
mad.f32 r13.z, r19.y, r2.y, (last)r13.z
mad.f32 r11.z, r19.y, r2.z, (last)r11.z
mad.f32 r16.w, r18.z, r1.w, (last)r16.w
mad.f32 r14.w, r18.z, r2.x, (last)r14.w
mad.f32 r17.x, r18.w, r1.w, (last)r17.x
mad.f32 r15.x, r18.w, r2.x, (last)r15.x
mad.f32 r17.y, r19.x, r1.w, (last)r17.y
mad.f32 r15.y, r19.x, r2.x, (last)r15.y
mad.f32 r17.z, r19.y, r1.w, (last)r17.z
mad.f32 r15.z, r19.y, r2.x, (last)r15.z
mad.f32 r11.w, r21.z, r2.y, (last)r11.w
mad.f32 r9.w, r21.z, r2.z, (last)r9.w
mad.f32 r12.x, r21.w, r2.y, (last)r12.x
mad.f32 r10.x, r21.w, r2.z, (last)r10.x
(rpt1)mad.f32 r12.y, (r)r22.x, r2.y, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r22.x, r2.z, (r)(last)r10.y
mad.f32 r15.w, r21.z, r1.w, (last)r15.w
mad.f32 r13.w, r21.z, r2.x, (last)r13.w
mad.f32 r16.x, r21.w, r1.w, (last)r16.x
mad.f32 r14.x, r21.w, r2.x, (last)r14.x
(rpt1)mad.f32 r16.y, (r)r22.x, r1.w, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r22.x, r2.x, (r)(last)r14.y
(sy)(rpt1)mad.f32 r8.w, (r)r18.z, r19.z, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r19.x, r19.z, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r18.z, r19.w, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r19.x, r19.w, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r18.z, r20.x, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r19.x, r20.x, (r)(last)r5.y
(rpt1)mad.f32 r8.y, (r)r22.x, r19.z, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r22.x, r19.w, (r)(last)r6.y
(rpt1)mad.f32 r4.y, (r)r22.x, r20.x, (r)(last)r4.y
mad.f32 r7.w, r21.z, r19.z, (last)r7.w
mad.f32 r5.w, r21.z, r19.w, (last)r5.w
mad.f32 r3.w, r21.z, r20.x, (last)r3.w
mad.f32 r8.x, r21.w, r19.z, (last)r8.x
mad.f32 r6.x, r21.w, r19.w, (last)r6.x
mad.f32 r4.x, r21.w, r20.x, (last)r4.x
(rpt1)mad.f32 r18.z, (r)(last)r18.z, r20.y, (r)(last)r26.x
(rpt1)mad.f32 r19.x, (r)(last)r19.x, r20.y, (r)(last)r26.z
ldl.u32 r26.x, l[r18.y+3456], 4
ldl.u32 r28.y, l[r18.y+3584], 4
ldl.u32 r2.y, l[r18.y+3712], 4
(rpt1)mad.f32 r22.x, (r)(last)r22.x, r20.y, (r)(last)r30.w
(rpt1)mad.f32 r21.z, (r)(last)r21.z, r20.y, (r)(last)r30.y
isam.v.base0 (u32)(xyzw)r30.y, r29.z, s#0, t#0
ldl.u32 r19.z, l[r18.y+3840], 4
mad.f32 r12.w, r24.x, r23.x, (last)r12.w
mad.f32 r10.w, r24.x, r23.y, (last)r10.w
mad.f32 r13.x, r24.y, r23.x, (last)r13.x
mad.f32 r11.x, r24.y, r23.y, (last)r11.x
mad.f32 r13.y, r24.z, r23.x, (last)r13.y
mad.f32 r11.y, r24.z, r23.y, (last)r11.y
mad.f32 r13.z, r24.w, r23.x, (last)r13.z
mad.f32 r11.z, r24.w, r23.y, (last)r11.z
mad.f32 r16.w, r24.x, r22.z, (last)r16.w
mad.f32 r14.w, r24.x, r22.w, (last)r14.w
mad.f32 r17.x, r24.y, r22.z, (last)r17.x
mad.f32 r15.x, r24.y, r22.w, (last)r15.x
mad.f32 r17.y, r24.z, r22.z, (last)r17.y
mad.f32 r15.y, r24.z, r22.w, (last)r15.y
mad.f32 r17.z, r24.w, r22.z, (last)r17.z
mad.f32 r15.z, r24.w, r22.w, (last)r15.z
(rpt1)mad.f32 r8.w, (r)r24.x, r25.x, (r)(last)r8.w
(rpt1)mad.f32 r9.y, (r)r24.z, r25.x, (r)(last)r9.y
(rpt1)mad.f32 r6.w, (r)r24.x, r25.y, (r)(last)r6.w
(rpt1)mad.f32 r7.y, (r)r24.z, r25.y, (r)(last)r7.y
(rpt1)mad.f32 r4.w, (r)r24.x, r25.z, (r)(last)r4.w
(rpt1)mad.f32 r5.y, (r)r24.z, r25.z, (r)(last)r5.y
(ss)mad.f32 r11.w, r26.x, r23.x, (last)r11.w
mad.f32 r9.w, r26.x, r23.y, (last)r9.w
mad.f32 r12.x, r26.y, r23.x, (last)r12.x
mad.f32 r10.x, r26.y, r23.y, (last)r10.x
(rpt1)mad.f32 r12.y, (r)r26.z, r23.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r26.z, r23.y, (r)(last)r10.y
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r25.w, (r)(last)r18.z
(rpt1)mad.f32 r24.z, (r)(last)r24.z, r25.w, (r)(last)r19.x
isam.v.base0 (u32)(xyzw)r18.z, r29.w, s#0, t#0
isam.v.base0 (u32)(xyzw)r23.x, r30.x, s#0, t#0
mad.f32 r7.w, r26.x, r25.x, (last)r7.w
mad.f32 r5.w, r26.x, r25.y, (last)r5.w
mad.f32 r8.x, r26.y, r25.x, (last)r8.x
mad.f32 r6.x, r26.y, r25.y, (last)r6.x
(rpt1)mad.f32 r8.y, (r)r26.z, r25.x, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r26.z, r25.y, (r)(last)r6.y
mad.f32 r13.y, r28.w, r27.z, (last)r13.y
mad.f32 r11.y, r28.w, r27.w, (last)r11.y
mad.f32 r13.z, r29.x, r27.z, (last)r13.z
mad.f32 r11.z, r29.x, r27.w, (last)r11.z
mad.f32 r17.y, r28.w, r27.x, (last)r17.y
mad.f32 r15.y, r28.w, r27.y, (last)r15.y
mad.f32 r17.z, r29.x, r27.x, (last)r17.z
mad.f32 r15.z, r29.x, r27.y, (last)r15.z
mad.f32 r15.w, r26.x, r22.z, (last)r15.w
mad.f32 r13.w, r26.x, r22.w, (last)r13.w
mad.f32 r3.w, r26.x, r25.z, (last)r3.w
mad.f32 r16.x, r26.y, r22.z, (last)r16.x
mad.f32 r14.x, r26.y, r22.w, (last)r14.x
mad.f32 r4.x, r26.y, r25.z, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r26.z, r22.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r26.z, r22.w, (r)(last)r14.y
(rpt1)mad.f32 r4.y, (r)r26.z, r25.z, (r)(last)r4.y
(rpt1)mad.f32 r26.x, (r)(last)r26.x, r25.w, (r)(last)r21.z
(rpt1)mad.f32 r26.z, (r)(last)r26.z, r25.w, (r)(last)r22.x
mad.f32 r12.w, r28.y, r27.z, (last)r12.w
mad.f32 r10.w, r28.y, r27.w, (last)r10.w
mad.f32 r13.x, r28.z, r27.z, (last)r13.x
mad.f32 r11.x, r28.z, r27.w, (last)r11.x
mad.f32 r16.w, r28.y, r27.x, (last)r16.w
mad.f32 r14.w, r28.y, r27.y, (last)r14.w
mad.f32 r17.x, r28.z, r27.x, (last)r17.x
(sy)(rpt1)mad.f32 r9.y, (r)r28.w, r30.y, (r)(last)r9.y
(rpt1)mad.f32 r7.y, (r)r28.w, r30.z, (r)(last)r7.y
(rpt1)mad.f32 r5.y, (r)r28.w, r30.w, (r)(last)r5.y
(rpt1)mad.f32 r28.w, (r)(last)r28.w, r31.x, (r)(last)r24.z
ldl.u32 r24.z, l[r18.y+3968], 4
mad.f32 r15.x, r28.z, r27.y, (last)r15.x
(rpt1)mad.f32 r8.w, (r)r28.y, r30.y, (r)(last)r8.w
(rpt1)mad.f32 r6.w, (r)r28.y, r30.z, (r)(last)r6.w
(rpt1)mad.f32 r4.w, (r)r28.y, r30.w, (r)(last)r4.w
mad.f32 r11.w, r2.y, r27.z, (last)r11.w
mad.f32 r9.w, r2.y, r27.w, (last)r9.w
mad.f32 r12.x, r2.z, r27.z, (last)r12.x
mad.f32 r10.x, r2.z, r27.w, (last)r10.x
(rpt1)mad.f32 r12.y, (r)r2.w, r27.z, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r2.w, r27.w, (r)(last)r10.y
mad.f32 r7.w, r2.y, r30.y, (last)r7.w
mad.f32 r5.w, r2.y, r30.z, (last)r5.w
mad.f32 r8.x, r2.z, r30.y, (last)r8.x
mad.f32 r6.x, r2.z, r30.z, (last)r6.x
(rpt1)mad.f32 r8.y, (r)r2.w, r30.y, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r2.w, r30.z, (r)(last)r6.y
mad.f32 r15.w, r2.y, r27.x, (last)r15.w
mad.f32 r13.w, r2.y, r27.y, (last)r13.w
mad.f32 r3.w, r2.y, r30.w, (last)r3.w
mad.f32 r16.x, r2.z, r27.x, (last)r16.x
mad.f32 r14.x, r2.z, r27.y, (last)r14.x
mad.f32 r4.x, r2.z, r30.w, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r2.w, r27.x, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r2.w, r27.y, (r)(last)r14.y
(rpt1)mad.f32 r4.y, (r)r2.w, r30.w, (r)(last)r4.y
(rpt1)mad.f32 r28.y, (r)(last)r28.y, r31.x, (r)(last)r24.x
(rpt1)mad.f32 r2.y, (r)(last)r2.y, r31.x, (r)(last)r26.x
(rpt1)mad.f32 r2.w, (r)(last)r2.w, r31.x, (r)(last)r26.z
mad.f32 r13.y, r20.x, r19.x, (last)r13.y
mad.f32 r11.y, r20.x, r19.y, (last)r11.y
mad.f32 r13.z, r20.y, r19.x, (last)r13.z
mad.f32 r11.z, r20.y, r19.y, (last)r11.z
mad.f32 r17.y, r20.x, r18.z, (last)r17.y
mad.f32 r15.y, r20.x, r18.w, (last)r15.y
mad.f32 r17.z, r20.y, r18.z, (last)r17.z
mad.f32 r15.z, r20.y, r18.w, (last)r15.z
mad.f32 r12.w, r19.z, r19.x, (last)r12.w
mad.f32 r10.w, r19.z, r19.y, (last)r10.w
mad.f32 r13.x, r19.w, r19.x, (last)r13.x
mad.f32 r11.x, r19.w, r19.y, (last)r11.x
mad.f32 r16.w, r19.z, r18.z, (last)r16.w
mad.f32 r14.w, r19.z, r18.w, (last)r14.w
mad.f32 r17.x, r19.w, r18.z, (last)r17.x
(rpt1)mad.f32 r9.y, (r)r20.x, r23.x, (r)(last)r9.y
(rpt1)mad.f32 r7.y, (r)r20.x, r23.y, (r)(last)r7.y
(rpt1)mad.f32 r5.y, (r)r20.x, r23.z, (r)(last)r5.y
(rpt1)mad.f32 r3.y, (r)(last)r20.x, r23.w, (r)(last)r28.w
mad.f32 r15.x, r19.w, r18.w, (last)r15.x
(rpt1)mad.f32 r8.w, (r)r19.z, r23.x, (r)(last)r8.w
(rpt1)mad.f32 r6.w, (r)r19.z, r23.y, (r)(last)r6.w
(rpt1)mad.f32 r4.w, (r)r19.z, r23.z, (r)(last)r4.w
(ss)mad.f32 r11.w, r24.z, r19.x, (last)r11.w
mad.f32 r9.w, r24.z, r19.y, (last)r9.w
mad.f32 r12.x, r24.w, r19.x, (last)r12.x
mad.f32 r10.x, r24.w, r19.y, (last)r10.x
(rpt1)mad.f32 r12.y, (r)r25.x, r19.x, (r)(last)r12.y
(rpt1)mad.f32 r10.y, (r)r25.x, r19.y, (r)(last)r10.y
mad.f32 r7.w, r24.z, r23.x, (last)r7.w
mad.f32 r5.w, r24.z, r23.y, (last)r5.w
mad.f32 r8.x, r24.w, r23.x, (last)r8.x
mad.f32 r6.x, r24.w, r23.y, (last)r6.x
(rpt1)mad.f32 r8.y, (r)r25.x, r23.x, (r)(last)r8.y
(rpt1)mad.f32 r6.y, (r)r25.x, r23.y, (r)(last)r6.y
mad.f32 r15.w, r24.z, r18.z, (last)r15.w
mad.f32 r13.w, r24.z, r18.w, (last)r13.w
mad.f32 r3.w, r24.z, r23.z, (last)r3.w
mad.f32 r16.x, r24.w, r18.z, (last)r16.x
mad.f32 r14.x, r24.w, r18.w, (last)r14.x
mad.f32 r4.x, r24.w, r23.z, (last)r4.x
(rpt1)mad.f32 r16.y, (r)r25.x, r18.z, (r)(last)r16.y
(rpt1)mad.f32 r14.y, (r)r25.x, r18.w, (r)(last)r14.y
(rpt1)mad.f32 r4.y, (r)r25.x, r23.z, (r)(last)r4.y
(rpt1)mad.f32 r24.x, (r)(last)r19.z, r23.w, (r)(last)r28.y
(rpt1)mad.f32 r25.z, (r)(last)r24.z, r23.w, (r)(last)r2.y
(rpt1)mad.f32 r2.y, (r)(last)r25.x, r23.w, (r)(last)r2.w
fence.r.w
(sy)(ss)cov.f32f16 hr44.z, r13.y
cov.f32f16 hr45.z, r11.y
cov.f32f16 hr44.w, r13.z
cov.f32f16 hr45.w, r11.z
cov.f32f16 hr41.z, r17.y
cov.f32f16 hr43.z, r15.y
cov.f32f16 hr41.w, r17.z
cov.f32f16 hr43.w, r15.z
cov.f32f16 hr44.x, r12.w
cov.f32f16 hr45.x, r10.w
cov.f32f16 hr44.y, r13.x
cov.f32f16 hr45.y, r11.x
cov.f32f16 hr41.x, r16.w
cov.f32f16 hr43.x, r14.w
cov.f32f16 hr41.y, r17.x
(rpt1)cov.f32f16 hr1.x, (r)r9.y
(rpt1)cov.f32f16 hr4.x, (r)r7.y
(rpt1)cov.f32f16 hr36.x, (r)r5.y
cov.f32f16 hr43.y, r15.x
(rpt1)cov.f32f16 hr0.z, (r)r8.w
(rpt1)cov.f32f16 hr3.z, (r)r6.w
(rpt1)cov.f32f16 hr35.z, (r)r4.w
cov.f32f16 hr40.x, r9.w
cov.f32f16 hr40.y, r12.x
cov.f32f16 hr40.z, r10.x
(rpt1)cov.f32f16 hr42.x, (r)r12.y
(rpt1)cov.f32f16 hr46.x, (r)r7.w
(rpt1)cov.f32f16 hr38.z, (r)r6.y
(rpt1)cov.f32f16 hr46.z, (r)r10.y
(rpt1)cov.f32f16 hr36.z, (r)r13.w
cov.f32f16 hr40.w, r4.x
(rpt1)cov.f32f16 hr37.x, (r)r14.y
cov.f32f16 hr37.z, r11.w
cov.f32f16 hr37.w, r3.w
(rpt1)cov.f32f16 hr47.x, (r)r5.w
(rpt1)cov.f32f16 hr39.x, (r)r24.x
(rpt1)cov.f32f16 hr39.z, (r)r3.y
cov.f32f16 hr38.x, r25.z
mov.u32u32 r24.z, (last)r0.x
cov.f32f16 hr38.y, r25.w
mov.u32u32 r24.w, (last)r0.w
(rpt1)cov.f32f16 hr5.z, (r)r15.w
(rpt1)cov.f32f16 hr47.z, (r)r8.y
(rpt1)cov.f32f16 hr6.x, (r)r16.y
bar.g
(sy)(ss)cov.f32f16 hr0.x, r4.y
cov.f32f16 hr0.y, r2.y
cov.f32f16 hr1.z, r4.z
cov.f32f16 hr1.w, r2.z
br p0.x, #l1090
mov.u32u32 r1.w, (last)r25.z
mov.u32u32 r2.x, (last)r25.w
mov.u32u32 r3.x, (last)r24.y
mov.u32u32 r2.w, (last)r24.x
mov.u32u32 r0.x, (last)r24.z
mov.u32u32 r0.w, (last)r24.w
jump #l130
l1090:
(jp)(eolm)nop
add.u r21.y, r51.w, (last)r21.y
mov.u16u16 hr8.z, (last)hr40.x
mov.u16u16 hr8.w, (last)hr40.z
mov.u16u16 hr9.x, (last)hr46.z
shl.b r21.y, (last)r21.y, 9
mov.u16u16 hr9.y, (last)hr46.w
mov.u16u16 hr9.z, (last)hr46.x
mov.u16u16 hr9.w, (last)hr46.y
sad.s32 r21.y, r52.z, r21.y, (last)r1.y
mov.u16u16 hr10.x, (last)hr47.z
mov.u16u16 hr10.y, (last)hr47.w
mov.u16u16 hr12.z, (last)hr47.x
shl.b r21.y, (last)r21.y, 2
mov.u16u16 hr12.w, (last)hr47.y
mov.u16u16 hr13.x, (last)hr38.z
mov.u16u16 hr13.y, (last)hr38.w
add.u r2.y, r21.y, c1.x
add.u r2.z, r21.y, c4.w
add.u r3.y, r21.y, c4.y
stib.b.untyped.1d.u16.4.imm.base0 hr41.x, r21.y, 4
(rpt1)add.u r3.z, r21.y, (r)c5.y
(ss)mov.u16u16 hr41.z, (last)hr37.z
mov.u16u16 hr41.w, (last)hr40.y
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r21.y+32, 4
(ss)add.u r2.w, r21.y, c4.z
add.u r3.x, r21.y, c5.x
add.u r4.x, r21.y, c8.w
(rpt3)add.u r5.y, r21.y, (r)c9.x
stib.b.untyped.1d.u16.4.imm.base0 hr43.x, r2.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr36.z, r2.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr44.x, r2.w, 4
add.u r6.w, r21.y, c10.x
stib.b.untyped.1d.u16.4.imm.base0 hr41.z, r3.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr45.x, r3.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r3.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr0.z, r3.w, 4
(ss)mov.u16u16 hr0.w, (last)hr37.w
mov.u16u16 hr1.x, (last)hr40.w
mov.u16u16 hr1.y, (last)hr0.x
add.u r7.x, (last)r21.y, c10.y
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r4.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r5.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r5.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr35.z, r5.w, 4
(rpt4)nop
stib.b.untyped.1d.u16.4.imm.base0 hr0.w, r6.x, 4
(ss)mov.u16u16 hr1.x, (last)hr38.x
mov.u16u16 hr1.y, (last)hr38.y
mov.u16u16 hr1.z, (last)hr0.y
stib.b.untyped.1d.u16.4.imm.base0 hr39.x, r6.w, 4
(rpt5)nop
stib.b.untyped.1d.u16.4.imm.base0 hr1.x, r7.x, 4
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
; CL prog 23/1: 1392 instr, 20 nops, 1372 non-nops, 93 mov, 64 cov, 2304 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 32 full, 12 constlen
; CL prog 23/1: 23 cat0, 157 cat1, 90 cat2, 1030 cat3, 0 cat4, 36 cat5, 52 cat6, 4 cat7
; CL prog 23/1: 80 sstall, 29 (ss), 235 systall, 17 (sy), 1 loops
; CL prog 23/1: 8 max_waves, 0 double_threadsize
; 58 preamble-instr, 1 early-preamble
