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
@const(c1.x)	0x00000800, 0x00001800, 0x00001000, 0x00001840
@const(c2.x)	0x00001040, 0x00000840, 0x00020000, 0x00020040
@const(c3.x)	0x00020800, 0x00020840, 0x00021000, 0x00021040
@const(c4.x)	0x00021800, 0x00021840, 0xd0d0d0d0, 0xd0d0d0d0
shps #l27
getone #l27
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 0x1800
mov.u32u32 r49.y, 4096
mov.u32u32 r49.z, 0x1840
mov.u32u32 r49.w, 0x1040
mov.u32u32 r50.x, 2112
mov.u32u32 r50.y, 0x20000
mov.u32u32 r50.z, 0x20040
mov.u32u32 r50.w, 0x20800
mov.u32u32 r51.x, 0x20840
mov.u32u32 r51.y, 0x21000
mov.u32u32 r51.z, 0x21040
mov.u32u32 r51.w, 0x21800
mov.u32u32 r52.x, 0x21840
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 2
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l27:
(jp)(rpt1)add.u r52.y, (r)r48.x, (r)c0.x
mov.u32u32 r53.y, 0
shl.b r53.x, r52.y, 7
shl.b r52.w, r52.z, 7
shr.b r0.w, r0.x, 4
mov.u32u32 r1.x, 0
mov.u32u32 r1.y, 0
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
mov.u32u32 r1.w, 0
mov.u32u32 r1.z, 0
and.b r0.x, (last)r0.x, 15
l97:
(rpt1)shr.b r53.z, (r)r52.w, 2
shl.b r54.x, r53.y, 9
add.u r53.y, r53.y, 4
cmps.u.ge up0.x, r53.y, c1.x
(ss)(nop2) sad.s32 r17.x, r54.x, r0.w, r53.z
sad.s32 r17.y, r54.x, r0.x, r53.w
(nop2) shl.b r17.x, (last)r17.x, 2
shl.b r17.y, (last)r17.y, 2
add.u r18.z, r17.x, c1.x
add.u r18.w, r17.x, c2.y
add.u r19.x, r17.x, c1.z
isam.v.base0 (u32)(xyzw)r17.z, r17.x, s#0, t#0
isam.v.base0 (u32)(xyzw)r21.z, r17.x+64, s#0, t#0
add.u r19.y, r17.y, c1.x
add.u r19.z, r17.y, c2.y
add.u r19.w, r17.y, c1.z
isam.v.base0 (u32)(xyzw)r22.z, r17.y, s#0, t#2
isam.v.base0 (u32)(xyzw)r23.z, r17.y+64, s#0, t#2
add.u r20.w, c2.x, r17.y
add.u r21.x, c1.y, r17.y
add.u r21.y, c1.w, (last)r17.y
add.u r20.x, c2.x, r17.x
add.u r20.y, c1.y, r17.x
add.u r20.z, c1.w, (last)r17.x
(sy)mad.f32 r16.x, r22.z, r17.z, (last)r16.x
mad.f32 r14.x, r22.z, r17.w, (last)r14.x
mad.f32 r12.x, r22.z, r18.x, (last)r12.x
mad.f32 r10.x, r22.z, r18.y, (last)r10.x
mad.f32 r8.x, r22.z, r21.z, (last)r8.x
mad.f32 r6.x, r22.z, r21.w, (last)r6.x
mad.f32 r4.x, r22.z, r22.x, (last)r4.x
mad.f32 r16.y, r22.w, r17.z, (last)r16.y
mad.f32 r14.y, r22.w, r17.w, (last)r14.y
mad.f32 r12.y, r22.w, r18.x, (last)r12.y
mad.f32 r10.y, r22.w, r18.y, (last)r10.y
mad.f32 r8.y, r22.w, r21.z, (last)r8.y
mad.f32 r6.y, r22.w, r21.w, (last)r6.y
mad.f32 r4.y, r22.w, r22.x, (last)r4.y
mad.f32 r16.z, r23.x, r17.z, (last)r16.z
mad.f32 r14.z, r23.x, r17.w, (last)r14.z
mad.f32 r12.z, r23.x, r18.x, (last)r12.z
mad.f32 r10.z, r23.x, r18.y, (last)r10.z
mad.f32 r8.z, r23.x, r21.z, (last)r8.z
mad.f32 r6.z, r23.x, r21.w, (last)r6.z
mad.f32 r4.z, r23.x, r22.x, (last)r4.z
mad.f32 r16.w, r23.y, r17.z, (last)r16.w
mad.f32 r14.w, r23.y, r17.w, (last)r14.w
mad.f32 r12.w, r23.y, r18.x, (last)r12.w
mad.f32 r10.w, r23.y, r18.y, (last)r10.w
mad.f32 r8.w, r23.y, r21.z, (last)r8.w
mad.f32 r6.w, r23.y, r21.w, (last)r6.w
mad.f32 r4.w, r23.y, r22.x, (last)r4.w
mad.f32 r15.x, r23.z, r17.z, (last)r15.x
mad.f32 r13.x, r23.z, r17.w, (last)r13.x
mad.f32 r11.x, r23.z, r18.x, (last)r11.x
mad.f32 r9.x, r23.z, r18.y, (last)r9.x
mad.f32 r7.x, r23.z, r21.z, (last)r7.x
mad.f32 r5.x, r23.z, r21.w, (last)r5.x
mad.f32 r3.x, r23.z, r22.x, (last)r3.x
mad.f32 r15.y, r23.w, r17.z, (last)r15.y
mad.f32 r13.y, r23.w, r17.w, (last)r13.y
mad.f32 r11.y, r23.w, r18.x, (last)r11.y
mad.f32 r9.y, r23.w, r18.y, (last)r9.y
mad.f32 r7.y, r23.w, r21.z, (last)r7.y
mad.f32 r5.y, r23.w, r21.w, (last)r5.y
mad.f32 r3.y, r23.w, r22.x, (last)r3.y
(rpt1)mad.f32 r15.z, (r)r24.x, r17.z, (r)(last)r15.z
(rpt1)mad.f32 r13.z, (r)r24.x, r17.w, (r)(last)r13.z
(rpt1)mad.f32 r11.z, (r)r24.x, r18.x, (r)(last)r11.z
(rpt1)mad.f32 r9.z, (r)r24.x, r18.y, (r)(last)r9.z
(rpt1)mad.f32 r7.z, (r)r24.x, r21.z, (r)(last)r7.z
(rpt1)mad.f32 r5.z, (r)r24.x, r21.w, (r)(last)r5.z
(rpt1)mad.f32 r3.z, (r)r24.x, r22.x, (r)(last)r3.z
(rpt1)mad.f32 r22.z, (r)(last)r22.z, r22.y, (r)(last)r2.x
(rpt1)mad.f32 r23.x, (r)(last)r23.x, r22.y, (r)(last)r2.z
(rpt1)mad.f32 r23.z, (r)(last)r23.z, r22.y, (r)(last)r1.x
(rpt1)mad.f32 r24.x, (r)(last)r24.x, r22.y, (r)(last)r1.z
isam.v.base0 (u32)(xyzw)r1.x, r18.z, s#0, t#0
isam.v.base0 (u32)(xyzw)r2.x, r18.w, s#0, t#0
isam.v.base0 (u32)(xyzw)r17.y, r19.y, s#0, t#2
(sy)mad.f32 r16.x, r17.y, r1.x, (last)r16.x
mad.f32 r14.x, r17.y, r1.y, (last)r14.x
mad.f32 r12.x, r17.y, r1.z, (last)r12.x
mad.f32 r10.x, r17.y, r1.w, (last)r10.x
mad.f32 r8.x, r17.y, r2.x, (last)r8.x
mad.f32 r6.x, r17.y, r2.y, (last)r6.x
mad.f32 r4.x, r17.y, r2.z, (last)r4.x
mad.f32 r17.y, (last)r17.y, r2.w, (last)r22.z
isam.v.base0 (u32)(xyzw)r21.w, r19.z, s#0, t#2
mad.f32 r16.y, r17.z, r1.x, (last)r16.y
mad.f32 r14.y, r17.z, r1.y, (last)r14.y
mad.f32 r12.y, r17.z, r1.z, (last)r12.y
mad.f32 r10.y, r17.z, r1.w, (last)r10.y
mad.f32 r8.y, r17.z, r2.x, (last)r8.y
mad.f32 r6.y, r17.z, r2.y, (last)r6.y
mad.f32 r4.y, r17.z, r2.z, (last)r4.y
mad.f32 r16.z, r17.w, r1.x, (last)r16.z
mad.f32 r14.z, r17.w, r1.y, (last)r14.z
mad.f32 r12.z, r17.w, r1.z, (last)r12.z
mad.f32 r10.z, r17.w, r1.w, (last)r10.z
mad.f32 r8.z, r17.w, r2.x, (last)r8.z
mad.f32 r6.z, r17.w, r2.y, (last)r6.z
mad.f32 r4.z, r17.w, r2.z, (last)r4.z
mad.f32 r16.w, r18.x, r1.x, (last)r16.w
mad.f32 r14.w, r18.x, r1.y, (last)r14.w
mad.f32 r12.w, r18.x, r1.z, (last)r12.w
mad.f32 r10.w, r18.x, r1.w, (last)r10.w
mad.f32 r8.w, r18.x, r2.x, (last)r8.w
mad.f32 r6.w, r18.x, r2.y, (last)r6.w
mad.f32 r4.w, r18.x, r2.z, (last)r4.w
mad.f32 r17.z, (last)r17.z, r2.w, (last)r22.w
(rpt1)mad.f32 r17.w, (r)(last)r17.w, r2.w, (r)(last)r23.x
(sy)mad.f32 r15.x, r21.w, r1.x, (last)r15.x
mad.f32 r13.x, r21.w, r1.y, (last)r13.x
mad.f32 r11.x, r21.w, r1.z, (last)r11.x
mad.f32 r9.x, r21.w, r1.w, (last)r9.x
mad.f32 r7.x, r21.w, r2.x, (last)r7.x
mad.f32 r5.x, r21.w, r2.y, (last)r5.x
mad.f32 r3.x, r21.w, r2.z, (last)r3.x
mad.f32 r15.y, r22.x, r1.x, (last)r15.y
mad.f32 r13.y, r22.x, r1.y, (last)r13.y
mad.f32 r11.y, r22.x, r1.z, (last)r11.y
mad.f32 r9.y, r22.x, r1.w, (last)r9.y
mad.f32 r7.y, r22.x, r2.x, (last)r7.y
mad.f32 r5.y, r22.x, r2.y, (last)r5.y
mad.f32 r3.y, r22.x, r2.z, (last)r3.y
(rpt1)mad.f32 r15.z, (r)r22.y, r1.x, (r)(last)r15.z
(rpt1)mad.f32 r13.z, (r)r22.y, r1.y, (r)(last)r13.z
(rpt1)mad.f32 r11.z, (r)r22.y, r1.z, (r)(last)r11.z
(rpt1)mad.f32 r9.z, (r)r22.y, r1.w, (r)(last)r9.z
(rpt1)mad.f32 r7.z, (r)r22.y, r2.x, (r)(last)r7.z
(rpt1)mad.f32 r5.z, (r)r22.y, r2.y, (r)(last)r5.z
(rpt1)mad.f32 r3.z, (r)r22.y, r2.z, (r)(last)r3.z
mad.f32 r21.w, (last)r21.w, r2.w, (last)r23.z
isam.v.base0 (u32)(xyzw)r22.w, r19.x, s#0, t#0
mad.f32 r22.x, (last)r22.x, r2.w, (last)r23.w
(rpt1)mad.f32 r22.y, (r)(last)r22.y, r2.w, (r)(last)r24.x
isam.v.base0 (u32)(xyzw)r23.w, r20.x, s#0, t#0
isam.v.base0 (u32)(xyzw)r1.z, r19.w, s#0, t#2
(sy)mad.f32 r16.x, r1.z, r22.w, (last)r16.x
mad.f32 r14.x, r1.z, r23.x, (last)r14.x
mad.f32 r12.x, r1.z, r23.y, (last)r12.x
mad.f32 r10.x, r1.z, r23.z, (last)r10.x
mad.f32 r8.x, r1.z, r23.w, (last)r8.x
mad.f32 r6.x, r1.z, r24.x, (last)r6.x
mad.f32 r4.x, r1.z, r24.y, (last)r4.x
mad.f32 r16.y, r1.w, r22.w, (last)r16.y
mad.f32 r14.y, r1.w, r23.x, (last)r14.y
mad.f32 r12.y, r1.w, r23.y, (last)r12.y
mad.f32 r10.y, r1.w, r23.z, (last)r10.y
mad.f32 r8.y, r1.w, r23.w, (last)r8.y
mad.f32 r6.y, r1.w, r24.x, (last)r6.y
mad.f32 r4.y, r1.w, r24.y, (last)r4.y
mad.f32 r16.z, r2.x, r22.w, (last)r16.z
mad.f32 r14.z, r2.x, r23.x, (last)r14.z
mad.f32 r12.z, r2.x, r23.y, (last)r12.z
mad.f32 r10.z, r2.x, r23.z, (last)r10.z
mad.f32 r8.z, r2.x, r23.w, (last)r8.z
mad.f32 r6.z, r2.x, r24.x, (last)r6.z
mad.f32 r4.z, r2.x, r24.y, (last)r4.z
mad.f32 r16.w, r2.y, r22.w, (last)r16.w
mad.f32 r14.w, r2.y, r23.x, (last)r14.w
mad.f32 r12.w, r2.y, r23.y, (last)r12.w
mad.f32 r10.w, r2.y, r23.z, (last)r10.w
mad.f32 r8.w, r2.y, r23.w, (last)r8.w
mad.f32 r6.w, r2.y, r24.x, (last)r6.w
mad.f32 r4.w, r2.y, r24.y, (last)r4.w
(rpt1)mad.f32 r1.z, (r)(last)r1.z, r24.z, (r)(last)r17.y
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r24.z, (r)(last)r17.w
isam.v.base0 (u32)(xyzw)r17.y, r20.w, s#0, t#2
isam.v.base0 (u32)(xyzw)r18.y, r20.y, s#0, t#0
isam.v.base0 (u32)(xyzw)r19.y, r20.z, s#0, t#0
(ss)nop
isam.v.base0 (u32)(xyzw)r20.y, r21.x, s#0, t#2
(sy)mad.f32 r15.x, r17.y, r22.w, (last)r15.x
mad.f32 r13.x, r17.y, r23.x, (last)r13.x
mad.f32 r11.x, r17.y, r23.y, (last)r11.x
mad.f32 r9.x, r17.y, r23.z, (last)r9.x
mad.f32 r7.x, r17.y, r23.w, (last)r7.x
mad.f32 r5.x, r17.y, r24.x, (last)r5.x
mad.f32 r3.x, r17.y, r24.y, (last)r3.x
mad.f32 r16.y, r20.z, r18.y, (last)r16.y
mad.f32 r14.y, r20.z, r18.z, (last)r14.y
mad.f32 r12.y, r20.z, r18.w, (last)r12.y
mad.f32 r10.y, r20.z, r19.x, (last)r10.y
mad.f32 r8.y, r20.z, r19.y, (last)r8.y
mad.f32 r6.y, r20.z, r19.z, (last)r6.y
mad.f32 r4.y, r20.z, r19.w, (last)r4.y
mad.f32 r16.z, r20.w, r18.y, (last)r16.z
mad.f32 r14.z, r20.w, r18.z, (last)r14.z
mad.f32 r12.z, r20.w, r18.w, (last)r12.z
mad.f32 r10.z, r20.w, r19.x, (last)r10.z
mad.f32 r8.z, r20.w, r19.y, (last)r8.z
mad.f32 r6.z, r20.w, r19.z, (last)r6.z
mad.f32 r4.z, r20.w, r19.w, (last)r4.z
mad.f32 r2.z, (last)r20.w, r20.x, (last)r2.x
mad.f32 r16.w, r21.x, r18.y, (last)r16.w
mad.f32 r14.w, r21.x, r18.z, (last)r14.w
mad.f32 r12.w, r21.x, r18.w, (last)r12.w
mad.f32 r10.w, r21.x, r19.x, (last)r10.w
mad.f32 r8.w, r21.x, r19.y, (last)r8.w
mad.f32 r6.w, r21.x, r19.z, (last)r6.w
mad.f32 r4.w, r21.x, r19.w, (last)r4.w
mad.f32 r2.w, (last)r21.x, r20.x, (last)r2.y
mad.f32 r17.y, (last)r17.y, r24.z, (last)r21.w
mad.f32 r21.w, (last)r20.z, r20.x, (last)r1.w
isam.v.base0 (u32)(xyzw)r20.z, r21.y, s#0, t#2
mad.f32 r15.y, r17.z, r22.w, (last)r15.y
mad.f32 r13.y, r17.z, r23.x, (last)r13.y
mad.f32 r11.y, r17.z, r23.y, (last)r11.y
mad.f32 r9.y, r17.z, r23.z, (last)r9.y
mad.f32 r7.y, r17.z, r23.w, (last)r7.y
mad.f32 r5.y, r17.z, r24.x, (last)r5.y
mad.f32 r3.y, r17.z, r24.y, (last)r3.y
(rpt1)mad.f32 r15.z, (r)r17.w, r22.w, (r)(last)r15.z
(rpt1)mad.f32 r13.z, (r)r17.w, r23.x, (r)(last)r13.z
(rpt1)mad.f32 r11.z, (r)r17.w, r23.y, (r)(last)r11.z
(rpt1)mad.f32 r9.z, (r)r17.w, r23.z, (r)(last)r9.z
(rpt1)mad.f32 r7.z, (r)r17.w, r23.w, (r)(last)r7.z
(rpt1)mad.f32 r5.z, (r)r17.w, r24.x, (r)(last)r5.z
(rpt1)mad.f32 r3.z, (r)r17.w, r24.y, (r)(last)r3.z
mad.f32 r17.z, (last)r17.z, r24.z, (last)r22.x
(rpt1)mad.f32 r17.w, (r)(last)r17.w, r24.z, (r)(last)r22.y
mad.f32 r16.x, r20.y, r18.y, (last)r16.x
mad.f32 r14.x, r20.y, r18.z, (last)r14.x
mad.f32 r12.x, r20.y, r18.w, (last)r12.x
mad.f32 r10.x, r20.y, r19.x, (last)r10.x
mad.f32 r8.x, r20.y, r19.y, (last)r8.x
mad.f32 r6.x, r20.y, r19.z, (last)r6.x
mad.f32 r4.x, r20.y, r19.w, (last)r4.x
mad.f32 r21.z, (last)r20.y, r20.x, (last)r1.z
cov.f32f16 hr0.w, r8.y
cov.f32f16 hr2.y, r6.y
cov.f32f16 hr1.x, r8.z
cov.f32f16 hr2.z, r6.z
cov.f32f16 hr1.y, r8.w
cov.f32f16 hr2.w, r6.w
cov.f32f16 hr4.w, r2.w
(sy)mad.f32 r15.x, r20.z, r18.y, (last)r15.x
mad.f32 r13.x, r20.z, r18.z, (last)r13.x
mad.f32 r11.x, r20.z, r18.w, (last)r11.x
mad.f32 r9.x, r20.z, r19.x, (last)r9.x
mad.f32 r7.x, r20.z, r19.y, (last)r7.x
mad.f32 r5.x, r20.z, r19.z, (last)r5.x
mad.f32 r3.x, r20.z, r19.w, (last)r3.x
mad.f32 r15.y, r20.w, r18.y, (last)r15.y
mad.f32 r13.y, r20.w, r18.z, (last)r13.y
mad.f32 r11.y, r20.w, r18.w, (last)r11.y
mad.f32 r9.y, r20.w, r19.x, (last)r9.y
mad.f32 r7.y, r20.w, r19.y, (last)r7.y
mad.f32 r5.y, r20.w, r19.z, (last)r5.y
mad.f32 r3.y, r20.w, r19.w, (last)r3.y
(rpt1)mad.f32 r15.z, (r)r21.x, r18.y, (r)(last)r15.z
(rpt1)mad.f32 r13.z, (r)r21.x, r18.z, (r)(last)r13.z
(rpt1)mad.f32 r11.z, (r)r21.x, r18.w, (r)(last)r11.z
(rpt1)mad.f32 r9.z, (r)r21.x, r19.x, (r)(last)r9.z
(rpt1)mad.f32 r7.z, (r)r21.x, r19.y, (r)(last)r7.z
(rpt1)mad.f32 r5.z, (r)r21.x, r19.z, (r)(last)r5.z
mad.f32 r24.x, (last)r20.z, r20.x, (last)r17.y
(rpt1)mad.f32 r3.z, (r)r21.x, r19.w, (r)(last)r3.z
mad.f32 r24.y, (last)r20.w, r20.x, (last)r17.z
mad.f32 r24.w, (last)r21.y, r20.x, (last)r18.x
mad.f32 r24.z, (last)r21.x, r20.x, (last)r17.w
cov.f32f16 hr4.z, r2.z
cov.f32f16 hr4.y, r21.w
(rpt1)cov.f32f16 hr3.z, (r)r4.z
(rpt1)cov.f32f16 hr45.z, (r)r14.z
cov.f32f16 hr46.y, r12.y
(rpt1)cov.f32f16 hr46.z, (r)r12.z
cov.f32f16 hr47.y, r10.y
(rpt1)cov.f32f16 hr47.z, (r)r10.z
cov.f32f16 hr44.y, r16.y
(rpt1)cov.f32f16 hr44.z, (r)r16.z
cov.f32f16 hr45.y, r14.y
cov.f32f16 hr44.x, r16.x
cov.f32f16 hr45.x, r14.x
cov.f32f16 hr46.x, r12.x
cov.f32f16 hr47.x, r10.x
cov.f32f16 hr0.z, r8.x
cov.f32f16 hr2.x, r6.x
cov.f32f16 hr4.x, r21.z
(rpt1)cov.f32f16 hr3.x, (r)r4.x
(rpt1)cov.f32f16 hr34.x, (r)r15.x
(rpt1)cov.f32f16 hr37.x, (r)r9.x
(rpt1)cov.f32f16 hr36.z, (r)r11.z
(rpt1)cov.f32f16 hr37.z, (r)r9.z
(rpt1)cov.f32f16 hr38.x, (r)r7.x
cov.f32f16 hr38.w, r7.w
cov.f32f16 hr38.z, r7.z
(rpt1)cov.f32f16 hr39.x, (r)r5.x
cov.f32f16 hr41.x, r24.x
(rpt1)cov.f32f16 hr34.z, (r)r15.z
(rpt1)cov.f32f16 hr40.z, (r)r3.z
(rpt1)cov.f32f16 hr39.z, (r)r5.z
cov.f32f16 hr41.y, r24.y
(rpt1)cov.f32f16 hr35.x, (r)r13.x
cov.f32f16 hr41.w, r24.w
(rpt1)cov.f32f16 hr36.x, (r)r11.x
cov.f32f16 hr41.z, r24.z
(rpt1)cov.f32f16 hr40.x, (r)r3.x
(rpt1)cov.f32f16 hr35.z, (r)r13.z
br p0.x, #l406
mov.u32u32 r1.x, (last)r24.x
mov.u32u32 r1.y, (last)r24.y
mov.u32u32 r2.y, (last)r21.w
mov.u32u32 r2.x, (last)r21.z
mov.u32u32 r1.w, (last)r24.w
mov.u32u32 r1.z, (last)r24.z
jump #l97
l406:
(jp)(nop3) shl.b r0.w, (last)r0.w, 2
(nop3) add.u r0.w, r52.w, (last)r0.w
(nop3) shl.b r0.w, (last)r0.w, 9
(nop3) sad.s32 r0.w, r53.w, r0.w, (last)r0.x
(nop3) shl.b r0.w, (last)r0.w, 2
add.u r21.x, r0.w, c1.x
add.u r21.y, r0.w, c2.y
add.u r21.z, r0.w, c1.z
stib.b.untyped.1d.u16.4.imm.base0 hr44.x, r0.w, 4
add.u r21.w, r0.w, c2.x
(ss)add.u r22.x, r0.w, c1.y
add.u r24.x, c4.x, r0.w
add.u r22.y, r0.w, c1.w
stib.b.untyped.1d.u16.4.imm.base0 hr34.x, r0.w+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr45.x, r21.x, 4
(ss)add.u r22.z, r0.w, c2.z
add.u r22.w, c2.w, r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr35.x, r21.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr46.x, r21.z, 4
(ss)add.u r23.x, c3.x, r0.w
add.u r23.y, c3.y, r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr36.x, r21.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr47.x, r22.x, 4
(ss)add.u r23.z, c3.z, r0.w
add.u r23.w, c3.w, r0.w
add.u r0.w, c4.y, (last)r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr37.x, r22.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr0.z, r22.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr38.x, r22.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr2.x, r23.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr39.x, r23.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr3.x, r23.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr40.x, r23.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r24.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr41.x, r0.w, 4
end
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 498 instr, 26 nops, 472 non-nops, 71 mov, 64 cov, 904 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 25 full, 8 constlen
; CL prog 23/1: 29 cat0, 135 cat1, 43 cat2, 259 cat3, 0 cat4, 16 cat5, 16 cat6, 0 cat7
; CL prog 23/1: 6 sstall, 6 (ss), 165 systall, 6 (sy), 1 loops
; CL prog 23/1: 10 max_waves, 0 double_threadsize
; 27 preamble-instr, 1 early-preamble
