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
@const(c2.x)	0x00001040, 0x00000840, 0x00010000, 0x00001820
@const(c3.x)	0x00001020, 0x00000820, 0x00010040, 0x00010800
@const(c4.x)	0x00010840, 0x00011000, 0x00011040, 0x00011800
@const(c5.x)	0x00011840, 0xd0d0d0d0, 0xd0d0d0d0, 0xd0d0d0d0
shps #l31
getone #l31
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 0x1800
mov.u32u32 r49.y, 4096
mov.u32u32 r49.z, 0x1840
mov.u32u32 r49.w, 0x1040
mov.u32u32 r50.x, 2112
mov.u32u32 r50.y, 0x10000
mov.u32u32 r50.z, 0x1820
mov.u32u32 r50.w, 0x1020
mov.u32u32 r51.x, 2080
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
l101:
(rpt1)shr.b r54.y, (r)r53.z, 2
shl.b r54.w, r54.x, 9
add.u r54.x, r54.x, 4
cmps.u.ge up0.x, r54.x, c1.x
(ss)(nop2) sad.s32 r17.x, r54.w, r0.w, r54.y
sad.s32 r17.y, r54.w, r0.x, r54.z
(nop2) shl.b r17.x, (last)r17.x, 2
shl.b r17.y, (last)r17.y, 2
add.u r18.z, r17.x, c1.x
add.u r18.w, r17.x, c3.y
add.u r19.x, r17.x, c1.z
isam.v.base0 (u32)(xyzw)r17.z, r17.x, s#0, t#0
isam.v.base0 (u32)(xyzw)r21.z, r17.x+32, s#0, t#0
add.u r19.y, r17.y, c1.x
add.u r19.z, r17.y, c2.y
add.u r20.x, c3.x, r17.x
isam.v.base0 (u32)(xyzw)r22.w, r17.y, s#0, t#2
isam.v.base0 (u32)(xyzw)r23.w, r17.y+64, s#0, t#2
add.u r20.y, c1.y, r17.x
add.u r20.z, c2.w, (last)r17.x
add.u r19.w, r17.y, c1.z
add.u r20.w, c2.x, r17.y
add.u r21.x, c1.y, r17.y
add.u r21.y, c1.w, (last)r17.y
(sy)mad.f32 r16.x, r22.w, r17.z, (last)r16.x
mad.f32 r14.x, r22.w, r17.w, (last)r14.x
mad.f32 r12.x, r22.w, r18.x, (last)r12.x
mad.f32 r10.x, r22.w, r18.y, (last)r10.x
mad.f32 r8.x, r22.w, r21.z, (last)r8.x
mad.f32 r6.x, r22.w, r21.w, (last)r6.x
mad.f32 r4.x, r22.w, r22.x, (last)r4.x
mad.f32 r16.y, r23.x, r17.z, (last)r16.y
mad.f32 r14.y, r23.x, r17.w, (last)r14.y
mad.f32 r12.y, r23.x, r18.x, (last)r12.y
mad.f32 r10.y, r23.x, r18.y, (last)r10.y
mad.f32 r8.y, r23.x, r21.z, (last)r8.y
mad.f32 r6.y, r23.x, r21.w, (last)r6.y
mad.f32 r4.y, r23.x, r22.x, (last)r4.y
mad.f32 r16.z, r23.y, r17.z, (last)r16.z
mad.f32 r14.z, r23.y, r17.w, (last)r14.z
mad.f32 r12.z, r23.y, r18.x, (last)r12.z
mad.f32 r10.z, r23.y, r18.y, (last)r10.z
mad.f32 r8.z, r23.y, r21.z, (last)r8.z
mad.f32 r6.z, r23.y, r21.w, (last)r6.z
mad.f32 r4.z, r23.y, r22.x, (last)r4.z
mad.f32 r16.w, r23.z, r17.z, (last)r16.w
mad.f32 r14.w, r23.z, r17.w, (last)r14.w
mad.f32 r12.w, r23.z, r18.x, (last)r12.w
mad.f32 r10.w, r23.z, r18.y, (last)r10.w
mad.f32 r8.w, r23.z, r21.z, (last)r8.w
mad.f32 r6.w, r23.z, r21.w, (last)r6.w
mad.f32 r4.w, r23.z, r22.x, (last)r4.w
mad.f32 r15.x, r23.w, r17.z, (last)r15.x
mad.f32 r13.x, r23.w, r17.w, (last)r13.x
mad.f32 r11.x, r23.w, r18.x, (last)r11.x
mad.f32 r9.x, r23.w, r18.y, (last)r9.x
mad.f32 r7.x, r23.w, r21.z, (last)r7.x
mad.f32 r5.x, r23.w, r21.w, (last)r5.x
mad.f32 r3.x, r23.w, r22.x, (last)r3.x
mad.f32 r15.y, r24.x, r17.z, (last)r15.y
mad.f32 r13.y, r24.x, r17.w, (last)r13.y
mad.f32 r11.y, r24.x, r18.x, (last)r11.y
mad.f32 r9.y, r24.x, r18.y, (last)r9.y
mad.f32 r7.y, r24.x, r21.z, (last)r7.y
mad.f32 r5.y, r24.x, r21.w, (last)r5.y
mad.f32 r3.y, r24.x, r22.x, (last)r3.y
(rpt1)mad.f32 r15.z, (r)r24.y, r17.z, (r)(last)r15.z
(rpt1)mad.f32 r13.z, (r)r24.y, r17.w, (r)(last)r13.z
(rpt1)mad.f32 r11.z, (r)r24.y, r18.x, (r)(last)r11.z
(rpt1)mad.f32 r9.z, (r)r24.y, r18.y, (r)(last)r9.z
(rpt1)mad.f32 r7.z, (r)r24.y, r21.z, (r)(last)r7.z
(rpt1)mad.f32 r5.z, (r)r24.y, r21.w, (r)(last)r5.z
(rpt1)mad.f32 r3.z, (r)r24.y, r22.x, (r)(last)r3.z
(rpt1)mad.f32 r22.w, (r)(last)r22.w, r22.y, (r)(last)r2.x
(rpt1)mad.f32 r23.y, (r)(last)r23.y, r22.y, (r)(last)r2.z
(rpt1)mad.f32 r23.w, (r)(last)r23.w, r22.y, (r)(last)r1.x
(rpt1)mad.f32 r24.y, (r)(last)r24.y, r22.y, (r)(last)r1.z
isam.v.base0 (u32)(xyzw)r1.x, r18.z, s#0, t#0
isam.v.base0 (u32)(xyzw)r2.x, r18.w, s#0, t#0
isam.v.base0 (u32)(xyzw)r17.x, r19.y, s#0, t#2
isam.v.base0 (u32)(xyzw)r21.w, r19.z, s#0, t#2
(sy)mad.f32 r16.x, r17.x, r1.x, (last)r16.x
mad.f32 r14.x, r17.x, r1.y, (last)r14.x
mad.f32 r12.x, r17.x, r1.z, (last)r12.x
mad.f32 r10.x, r17.x, r1.w, (last)r10.x
mad.f32 r8.x, r17.x, r2.x, (last)r8.x
mad.f32 r6.x, r17.x, r2.y, (last)r6.x
mad.f32 r4.x, r17.x, r2.z, (last)r4.x
mad.f32 r16.y, r17.y, r1.x, (last)r16.y
mad.f32 r14.y, r17.y, r1.y, (last)r14.y
mad.f32 r12.y, r17.y, r1.z, (last)r12.y
mad.f32 r10.y, r17.y, r1.w, (last)r10.y
mad.f32 r8.y, r17.y, r2.x, (last)r8.y
mad.f32 r6.y, r17.y, r2.y, (last)r6.y
mad.f32 r4.y, r17.y, r2.z, (last)r4.y
mad.f32 r16.z, r17.z, r1.x, (last)r16.z
mad.f32 r14.z, r17.z, r1.y, (last)r14.z
mad.f32 r12.z, r17.z, r1.z, (last)r12.z
mad.f32 r10.z, r17.z, r1.w, (last)r10.z
mad.f32 r8.z, r17.z, r2.x, (last)r8.z
mad.f32 r6.z, r17.z, r2.y, (last)r6.z
mad.f32 r4.z, r17.z, r2.z, (last)r4.z
mad.f32 r16.w, r17.w, r1.x, (last)r16.w
mad.f32 r14.w, r17.w, r1.y, (last)r14.w
mad.f32 r12.w, r17.w, r1.z, (last)r12.w
mad.f32 r10.w, r17.w, r1.w, (last)r10.w
mad.f32 r8.w, r17.w, r2.x, (last)r8.w
mad.f32 r6.w, r17.w, r2.y, (last)r6.w
mad.f32 r4.w, r17.w, r2.z, (last)r4.w
mad.f32 r15.x, r21.w, r1.x, (last)r15.x
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
(rpt1)mad.f32 r17.x, (r)(last)r17.x, r2.w, (r)(last)r22.w
(rpt1)mad.f32 r17.z, (r)(last)r17.z, r2.w, (r)(last)r23.y
isam.v.base0 (u32)(xyzw)r22.w, r19.x, s#0, t#0
(rpt1)mad.f32 r21.w, (r)(last)r21.w, r2.w, (r)(last)r23.w
(rpt1)mad.f32 r22.y, (r)(last)r22.y, r2.w, (r)(last)r24.y
isam.v.base0 (u32)(xyzw)r23.w, r20.x, s#0, t#0
isam.v.base0 (u32)(xyzw)r1.x, r19.w, s#0, t#2
isam.v.base0 (u32)(xyzw)r2.x, r20.w, s#0, t#2
(sy)mad.f32 r16.x, r1.x, r22.w, (last)r16.x
mad.f32 r14.x, r1.x, r23.x, (last)r14.x
mad.f32 r12.x, r1.x, r23.y, (last)r12.x
mad.f32 r10.x, r1.x, r23.z, (last)r10.x
mad.f32 r8.x, r1.x, r23.w, (last)r8.x
mad.f32 r6.x, r1.x, r24.x, (last)r6.x
mad.f32 r4.x, r1.x, r24.y, (last)r4.x
mad.f32 r16.y, r1.y, r22.w, (last)r16.y
mad.f32 r14.y, r1.y, r23.x, (last)r14.y
mad.f32 r12.y, r1.y, r23.y, (last)r12.y
mad.f32 r10.y, r1.y, r23.z, (last)r10.y
mad.f32 r8.y, r1.y, r23.w, (last)r8.y
mad.f32 r6.y, r1.y, r24.x, (last)r6.y
mad.f32 r4.y, r1.y, r24.y, (last)r4.y
mad.f32 r16.z, r1.z, r22.w, (last)r16.z
mad.f32 r14.z, r1.z, r23.x, (last)r14.z
mad.f32 r12.z, r1.z, r23.y, (last)r12.z
mad.f32 r10.z, r1.z, r23.z, (last)r10.z
mad.f32 r8.z, r1.z, r23.w, (last)r8.z
mad.f32 r6.z, r1.z, r24.x, (last)r6.z
mad.f32 r4.z, r1.z, r24.y, (last)r4.z
mad.f32 r16.w, r1.w, r22.w, (last)r16.w
mad.f32 r14.w, r1.w, r23.x, (last)r14.w
mad.f32 r12.w, r1.w, r23.y, (last)r12.w
mad.f32 r10.w, r1.w, r23.z, (last)r10.w
mad.f32 r8.w, r1.w, r23.w, (last)r8.w
mad.f32 r6.w, r1.w, r24.x, (last)r6.w
mad.f32 r4.w, r1.w, r24.y, (last)r4.w
(rpt1)mad.f32 r1.x, (r)(last)r1.x, r24.z, (r)(last)r17.x
(rpt1)mad.f32 r1.z, (r)(last)r1.z, r24.z, (r)(last)r17.z
isam.v.base0 (u32)(xyzw)r17.x, r20.y, s#0, t#0
isam.v.base0 (u32)(xyzw)r18.x, r20.z, s#0, t#0
isam.v.base0 (u32)(xyzw)r19.y, r21.x, s#0, t#2
mad.f32 r15.x, r2.x, r22.w, (last)r15.x
mad.f32 r13.x, r2.x, r23.x, (last)r13.x
mad.f32 r11.x, r2.x, r23.y, (last)r11.x
mad.f32 r9.x, r2.x, r23.z, (last)r9.x
mad.f32 r7.x, r2.x, r23.w, (last)r7.x
mad.f32 r5.x, r2.x, r24.x, (last)r5.x
mad.f32 r3.x, r2.x, r24.y, (last)r3.x
mad.f32 r15.y, r2.y, r22.w, (last)r15.y
mad.f32 r13.y, r2.y, r23.x, (last)r13.y
mad.f32 r11.y, r2.y, r23.y, (last)r11.y
mad.f32 r9.y, r2.y, r23.z, (last)r9.y
mad.f32 r7.y, r2.y, r23.w, (last)r7.y
mad.f32 r5.y, r2.y, r24.x, (last)r5.y
mad.f32 r3.y, r2.y, r24.y, (last)r3.y
(rpt1)mad.f32 r15.z, (r)r2.z, r22.w, (r)(last)r15.z
(rpt1)mad.f32 r13.z, (r)r2.z, r23.x, (r)(last)r13.z
(rpt1)mad.f32 r11.z, (r)r2.z, r23.y, (r)(last)r11.z
(rpt1)mad.f32 r9.z, (r)r2.z, r23.z, (r)(last)r9.z
(rpt1)mad.f32 r7.z, (r)r2.z, r23.w, (r)(last)r7.z
(rpt1)mad.f32 r5.z, (r)r2.z, r24.x, (r)(last)r5.z
(rpt1)mad.f32 r3.z, (r)r2.z, r24.y, (r)(last)r3.z
(rpt1)mad.f32 r2.x, (r)(last)r2.x, r24.z, (r)(last)r21.w
(rpt1)mad.f32 r2.z, (r)(last)r2.z, r24.z, (r)(last)r22.y
(sy)mad.f32 r16.x, r19.y, r17.x, (last)r16.x
mad.f32 r14.x, r19.y, r17.y, (last)r14.x
mad.f32 r12.x, r19.y, r17.z, (last)r12.x
mad.f32 r10.x, r19.y, r17.w, (last)r10.x
mad.f32 r8.x, r19.y, r18.x, (last)r8.x
mad.f32 r6.x, r19.y, r18.y, (last)r6.x
mad.f32 r4.x, r19.y, r18.z, (last)r4.x
mad.f32 r20.y, (last)r19.y, r18.w, (last)r1.x
mad.f32 r16.y, r19.z, r17.x, (last)r16.y
mad.f32 r14.y, r19.z, r17.y, (last)r14.y
mad.f32 r12.y, r19.z, r17.z, (last)r12.y
mad.f32 r10.y, r19.z, r17.w, (last)r10.y
mad.f32 r8.y, r19.z, r18.x, (last)r8.y
mad.f32 r6.y, r19.z, r18.y, (last)r6.y
mad.f32 r4.y, r19.z, r18.z, (last)r4.y
mad.f32 r20.z, (last)r19.z, r18.w, (last)r1.y
mad.f32 r16.z, r19.w, r17.x, (last)r16.z
mad.f32 r14.z, r19.w, r17.y, (last)r14.z
mad.f32 r12.z, r19.w, r17.z, (last)r12.z
mad.f32 r10.z, r19.w, r17.w, (last)r10.z
mad.f32 r8.z, r19.w, r18.x, (last)r8.z
mad.f32 r6.z, r19.w, r18.y, (last)r6.z
mad.f32 r4.z, r19.w, r18.z, (last)r4.z
mad.f32 r20.w, (last)r19.w, r18.w, (last)r1.z
isam.v.base0 (u32)(xyzw)r19.x, r21.y, s#0, t#2
mad.f32 r16.w, r20.x, r17.x, (last)r16.w
mad.f32 r14.w, r20.x, r17.y, (last)r14.w
mad.f32 r12.w, r20.x, r17.z, (last)r12.w
mad.f32 r10.w, r20.x, r17.w, (last)r10.w
mad.f32 r8.w, r20.x, r18.x, (last)r8.w
mad.f32 r6.w, r20.x, r18.y, (last)r6.w
mad.f32 r4.w, r20.x, r18.z, (last)r4.w
mad.f32 r21.x, (last)r20.x, r18.w, (last)r1.w
cov.f32f16 hr43.x, r16.x
cov.f32f16 hr44.x, r14.x
cov.f32f16 hr45.x, r12.x
cov.f32f16 hr46.x, r10.x
cov.f32f16 hr47.x, r8.x
cov.f32f16 hr0.z, r6.x
cov.f32f16 hr2.x, r4.x
cov.f32f16 hr43.y, r16.y
cov.f32f16 hr44.y, r14.y
cov.f32f16 hr45.y, r12.y
cov.f32f16 hr46.y, r10.y
cov.f32f16 hr47.y, r8.y
cov.f32f16 hr0.w, r6.y
cov.f32f16 hr2.y, r4.y
cov.f32f16 hr43.z, r16.z
cov.f32f16 hr44.z, r14.z
cov.f32f16 hr45.z, r12.z
cov.f32f16 hr46.z, r10.z
cov.f32f16 hr47.z, r8.z
cov.f32f16 hr1.x, r6.z
cov.f32f16 hr2.z, r4.z
(rpt1)cov.f32f16 hr3.x, (r)r20.y
cov.f32f16 hr43.w, r16.w
cov.f32f16 hr44.w, r14.w
cov.f32f16 hr45.w, r12.w
cov.f32f16 hr46.w, r10.w
cov.f32f16 hr47.w, r8.w
cov.f32f16 hr1.y, r6.w
cov.f32f16 hr2.w, r4.w
cov.f32f16 hr3.w, r21.x
(sy)mad.f32 r15.x, r19.x, r17.x, (last)r15.x
mad.f32 r13.x, r19.x, r17.y, (last)r13.x
mad.f32 r11.x, r19.x, r17.z, (last)r11.x
mad.f32 r9.x, r19.x, r17.w, (last)r9.x
mad.f32 r7.x, r19.x, r18.x, (last)r7.x
mad.f32 r5.x, r19.x, r18.y, (last)r5.x
mad.f32 r3.x, r19.x, r18.z, (last)r3.x
mad.f32 r24.x, (last)r19.x, r18.w, (last)r2.x
mad.f32 r15.y, r19.y, r17.x, (last)r15.y
mad.f32 r13.y, r19.y, r17.y, (last)r13.y
mad.f32 r11.y, r19.y, r17.z, (last)r11.y
mad.f32 r9.y, r19.y, r17.w, (last)r9.y
mad.f32 r7.y, r19.y, r18.x, (last)r7.y
mad.f32 r5.y, r19.y, r18.y, (last)r5.y
mad.f32 r3.y, r19.y, r18.z, (last)r3.y
mad.f32 r24.y, (last)r19.y, r18.w, (last)r2.y
(rpt1)mad.f32 r15.z, (r)r19.z, r17.x, (r)(last)r15.z
(rpt1)mad.f32 r13.z, (r)r19.z, r17.y, (r)(last)r13.z
(rpt1)mad.f32 r11.z, (r)r19.z, r17.z, (r)(last)r11.z
(rpt1)mad.f32 r9.z, (r)r19.z, r17.w, (r)(last)r9.z
(rpt1)mad.f32 r7.z, (r)r19.z, r18.x, (r)(last)r7.z
(rpt1)mad.f32 r5.z, (r)r19.z, r18.y, (r)(last)r5.z
mad.f32 r3.z, r19.z, r18.z, (last)r3.z
mad.f32 r24.z, (last)r19.z, r18.w, (last)r2.z
mad.f32 r3.w, r19.w, r18.z, (last)r3.w
mad.f32 r24.w, (last)r19.w, r18.w, (last)r2.w
cov.f32f16 hr3.z, r20.w
cov.f32f16 hr38.x, r3.x
(rpt1)cov.f32f16 hr4.x, (r)r15.x
cov.f32f16 hr38.y, r3.y
(rpt1)cov.f32f16 hr4.z, (r)r15.z
(rpt1)cov.f32f16 hr34.x, (r)r11.x
(rpt1)cov.f32f16 hr34.z, (r)r11.z
(rpt1)cov.f32f16 hr35.x, (r)r9.x
cov.f32f16 hr35.w, r9.w
cov.f32f16 hr35.z, r9.z
(rpt1)cov.f32f16 hr36.x, (r)r7.x
(rpt1)cov.f32f16 hr36.z, (r)r7.z
cov.f32f16 hr38.z, r3.z
(rpt1)cov.f32f16 hr39.x, (r)r24.x
(rpt1)cov.f32f16 hr5.x, (r)r13.x
cov.f32f16 hr38.w, r3.w
(rpt1)cov.f32f16 hr37.x, (r)r5.x
cov.f32f16 hr39.w, r24.w
cov.f32f16 hr39.z, r24.z
(rpt1)cov.f32f16 hr37.z, (r)r5.z
(rpt1)cov.f32f16 hr5.z, (r)r13.z
br p0.x, #l415
mov.u32u32 r1.x, (last)r24.x
mov.u32u32 r1.y, (last)r24.y
mov.u32u32 r2.w, (last)r21.x
mov.u32u32 r2.z, (last)r20.w
mov.u32u32 r2.y, (last)r20.z
mov.u32u32 r2.x, (last)r20.y
mov.u32u32 r1.w, (last)r24.w
mov.u32u32 r1.z, (last)r24.z
jump #l101
l415:
(jp)(nop3) shl.b r0.w, (last)r0.w, 2
(nop3) add.u r0.w, r53.z, (last)r0.w
(nop3) shl.b r0.w, (last)r0.w, 9
(nop3) sad.s32 r0.w, r54.z, r0.w, (last)r0.x
(nop3) shl.b r0.w, (last)r0.w, 2
add.u r20.x, r0.w, c1.x
add.u r20.y, r0.w, c2.y
add.u r20.z, r0.w, c1.z
add.u r20.w, r0.w, c2.x
add.u r21.x, r0.w, c1.y
stib.b.untyped.1d.u16.4.imm.base0 hr43.x, r0.w, 4
add.u r21.y, r0.w, c1.w
(ss)add.u r21.z, r0.w, c2.z
add.u r21.w, r0.w, c3.z
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r0.w+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr44.x, r20.x, 4
(ss)(rpt1)add.u r22.x, r0.w, (r)c3.w
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r20.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr45.x, r20.z, 4
(ss)(rpt1)add.u r22.z, r0.w, (r)c4.y
stib.b.untyped.1d.u16.4.imm.base0 hr34.x, r20.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr46.x, r21.x, 4
(ss)(rpt1)add.u r23.x, (last)r0.w, (r)c4.w
stib.b.untyped.1d.u16.4.imm.base0 hr35.x, r21.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr47.x, r21.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr36.x, r21.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr0.z, r22.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr37.x, r22.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr2.x, r22.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr38.x, r22.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr3.x, r23.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr39.x, r23.y, 4
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
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 499 instr, 25 nops, 474 non-nops, 73 mov, 64 cov, 928 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 25 full, 8 constlen
; CL prog 23/1: 28 cat0, 137 cat1, 43 cat2, 259 cat3, 0 cat4, 16 cat5, 16 cat6, 0 cat7
; CL prog 23/1: 6 sstall, 5 (ss), 118 systall, 5 (sy), 1 loops
; CL prog 23/1: 10 max_waves, 0 double_threadsize
; 31 preamble-instr, 1 early-preamble
