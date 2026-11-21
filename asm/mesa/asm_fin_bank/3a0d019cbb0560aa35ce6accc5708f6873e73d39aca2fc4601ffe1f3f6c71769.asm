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
@const(c1.x)	0x00000800, 0x00000820, 0x00001000, 0x00001020
@const(c2.x)	0x00001800, 0x00001820, 0x00010000, 0x00010020
@const(c3.x)	0x00010800, 0x00010820, 0x00011000, 0x00011020
@const(c4.x)	0x00011800, 0x00011820, 0xd0d0d0d0, 0xd0d0d0d0
shps #l27
getone #l27
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 2080
mov.u32u32 r49.y, 4096
mov.u32u32 r49.z, 0x1020
mov.u32u32 r49.w, 0x1800
mov.u32u32 r50.x, 0x1820
mov.u32u32 r50.y, 0x10000
mov.u32u32 r50.z, 0x10020
mov.u32u32 r50.w, 0x10800
mov.u32u32 r51.x, 0x10820
mov.u32u32 r51.y, 0x11000
mov.u32u32 r51.z, 0x11020
mov.u32u32 r51.w, 0x11800
mov.u32u32 r52.x, 0x11820
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
shl.b r53.x, r52.y, 6
shl.b r52.w, r52.z, 6
shr.b r0.w, r0.x, 4
and.b r1.x, r0.x, 15
shr.b r1.z, r0.x, 3
and.b r1.y, r0.x, 7
and.b r1.w, r0.x, -8
mov.u16u16 hr4.x, 0
mov.u16u16 hr4.y, 0
mov.u16u16 hr19.w, 0
mov.u16u16 hr19.z, 0
mov.u16u16 hr19.y, 0
mov.u16u16 hr19.x, 0
mov.u16u16 hr18.w, 0
mov.u16u16 hr18.z, 0
mov.u16u16 hr18.y, 0
mov.u16u16 hr18.x, 0
mov.u16u16 hr17.w, 0
mov.u16u16 hr17.z, 0
mov.u16u16 hr17.y, 0
mov.u16u16 hr17.x, 0
mov.u16u16 hr16.w, 0
mov.u16u16 hr16.z, 0
mov.u16u16 hr16.y, 0
mov.u16u16 hr16.x, 0
mov.u16u16 hr15.w, 0
mov.u16u16 hr15.z, 0
mov.u16u16 hr15.y, 0
mov.u16u16 hr15.x, 0
mov.u16u16 hr14.w, 0
mov.u16u16 hr14.z, 0
mov.u16u16 hr14.y, 0
mov.u16u16 hr14.x, 0
mov.u16u16 hr13.w, 0
mov.u16u16 hr13.z, 0
mov.u16u16 hr13.y, 0
mov.u16u16 hr13.x, 0
mov.u16u16 hr12.w, 0
mov.u16u16 hr12.z, 0
mov.u16u16 hr12.y, 0
mov.u16u16 hr12.x, 0
mov.u16u16 hr11.w, 0
mov.u16u16 hr11.z, 0
mov.u16u16 hr11.y, 0
mov.u16u16 hr11.x, 0
mov.u16u16 hr10.w, 0
mov.u16u16 hr10.z, 0
mov.u16u16 hr10.y, 0
mov.u16u16 hr10.x, 0
mov.u16u16 hr9.w, 0
mov.u16u16 hr9.z, 0
mov.u16u16 hr9.y, 0
mov.u16u16 hr9.x, 0
mov.u16u16 hr8.w, 0
mov.u16u16 hr8.z, 0
mov.u16u16 hr8.y, 0
mov.u16u16 hr8.x, 0
mov.u16u16 hr7.w, 0
mov.u16u16 hr7.z, 0
mov.u16u16 hr7.y, 0
mov.u16u16 hr7.x, 0
mov.u16u16 hr6.w, 0
mov.u16u16 hr6.z, 0
mov.u16u16 hr6.y, 0
mov.u16u16 hr6.x, 0
mov.u16u16 hr5.w, 0
mov.u16u16 hr5.z, 0
mov.u16u16 hr5.y, 0
mov.u16u16 hr5.x, 0
mov.u16u16 hr4.w, 0
mov.u16u16 hr4.z, 0
l100:
(rpt1)shr.b r53.z, (r)r52.w, 2
add.u r10.w, r0.x, 64
add.u r11.x, r0.x, 128
add.u r11.y, r0.x, 192
shl.b r10.x, r0.w, 7
(rpt1)shr.b r10.w, (last)(r)r10.w, 4
(ss)add.u r11.z, r53.y, r0.w
shr.b r11.y, (last)r11.y, 4
(rpt1)add.u r12.y, r53.y, (r)r10.w
shl.b r11.z, (last)r11.z, 9
add.u r12.w, r53.y, r11.y
add.u r53.y, r53.y, 16
cmps.u.ge up0.x, r53.y, c1.x
(rpt1)shl.b r12.y, (last)(r)r12.y, 9
sad.s32 r11.w, r53.z, r11.z, r1.x
shl.b r12.w, (last)r12.w, 9
shl.b r10.y, r1.x, 3
sad.s32 r12.x, r53.w, r11.z, r1.x
shl.b r11.w, (last)r11.w, 2
sad.s32 r13.z, r53.z, r12.y, r1.x
sad.s32 r14.y, r53.w, r12.y, r1.x
(rpt1)sad.s32 r13.w, r53.z, (r)r12.z, r1.x
(rpt1)sad.s32 r12.z, r53.w, (r)r12.z, r1.x
isam.v.base0 (u16)(xyzw)hr26.x, r11.w, s#0, t#0
add.u r10.x, (last)r10.x, r10.y
shl.b r12.x, (last)r12.x, 2
shl.b r13.z, (last)r13.z, 2
shl.b r14.w, (last)r14.y, 2
shl.b r13.w, (last)r13.w, 2
shl.b r14.z, (last)r14.x, 2
(rpt1)shl.b r12.z, (last)(r)r12.z, 2
shl.b r10.w, (last)r10.w, 7
isam.v.base0 (u16)(xyzw)hr30.z, r13.z, s#0, t#0
(rpt1)shl.b r11.x, (last)(r)r11.x, 7
isam.v.base0 (u16)(xyzw)hr0.z, r13.w, s#0, t#0
shl.b r10.z, r1.y, 3
(ss)nop
isam.v.base0 (u16)(xyzw)hr23.x, r14.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr24.x, r12.x, s#0, t#2
(rpt2)add.u r10.w, (last)(r)r10.w, (last)r10.y
shl.b r15.x, r1.z, 2
(sy)stl.u16 l[r10.x], r26.x, 4
(ss)nop
isam.v.base0 (u16)(xyzw)hr26.x, r14.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr27.x, r12.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr28.x, r12.w, s#0, t#2
(rpt1)nop
stl.u16 l[r10.w], r30.z, 4
nop
stl.u16 l[r11.x], r0.z, 4
nop
stl.u16 l[r11.y], r23.x, 4
stl.u16 l[r10.x+2048], r24.x, 4
(sy)stl.u16 l[r10.w+2048], r26.x, 4
stl.u16 l[r11.x+2048], r27.x, 4
stl.u16 l[r11.y+2048], r28.x, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
ldl.u16 r29.x, l[r1.w], 4
ldl.u16 r30.z, l[r1.w+64], 4
ldl.u16 r0.z, l[r10.z+2048], 4
(ss)mad.f16 hr19.x, hr0.z, hr29.x, (last)hr19.x
mad.f16 hr17.x, hr0.z, hr29.y, (last)hr17.x
mad.f16 hr15.x, hr0.z, hr29.z, (last)hr15.x
mad.f16 hr13.x, hr0.z, hr29.w, (last)hr13.x
mad.f16 hr11.x, hr0.z, hr30.z, (last)hr11.x
mad.f16 hr9.x, hr0.z, hr30.w, (last)hr9.x
mad.f16 hr7.x, hr0.z, hr31.x, (last)hr7.x
mad.f16 hr19.y, hr0.w, hr29.x, (last)hr19.y
mad.f16 hr17.y, hr0.w, hr29.y, (last)hr17.y
mad.f16 hr15.y, hr0.w, hr29.z, (last)hr15.y
mad.f16 hr13.y, hr0.w, hr29.w, (last)hr13.y
mad.f16 hr11.y, hr0.w, hr30.z, (last)hr11.y
mad.f16 hr9.y, hr0.w, hr30.w, (last)hr9.y
mad.f16 hr7.y, hr0.w, hr31.x, (last)hr7.y
mad.f16 hr19.z, hr1.x, hr29.x, (last)hr19.z
mad.f16 hr17.z, hr1.x, hr29.y, (last)hr17.z
mad.f16 hr15.z, hr1.x, hr29.z, (last)hr15.z
mad.f16 hr13.z, hr1.x, hr29.w, (last)hr13.z
mad.f16 hr11.z, hr1.x, hr30.z, (last)hr11.z
mad.f16 hr9.z, hr1.x, hr30.w, (last)hr9.z
mad.f16 hr7.z, hr1.x, hr31.x, (last)hr7.z
mad.f16 hr19.w, hr1.y, hr29.x, (last)hr19.w
mad.f16 hr17.w, hr1.y, hr29.y, (last)hr17.w
mad.f16 hr15.w, hr1.y, hr29.z, (last)hr15.w
mad.f16 hr13.w, hr1.y, hr29.w, (last)hr13.w
mad.f16 hr11.w, hr1.y, hr30.z, (last)hr11.w
mad.f16 hr9.w, hr1.y, hr30.w, (last)hr9.w
mad.f16 hr7.w, hr1.y, hr31.x, (last)hr7.w
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr31.y, (r)(last)hr5.x
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr31.y, (r)(last)hr5.z
ldl.u16 r5.x, l[r10.z+2112], 4
ldl.u16 r20.x, l[r1.w+128], 4
ldl.u16 r21.z, l[r1.w+192], 4
ldl.u16 r22.z, l[r10.z+2176], 4
ldl.u16 r23.z, l[r10.z+2240], 4
ldl.u16 r24.z, l[r1.w+256], 4
ldl.u16 r25.z, l[r1.w+320], 4
ldl.u16 r26.z, l[r10.z+2304], 4
ldl.u16 r27.z, l[r10.z+2368], 4
(ss)mad.f16 hr18.x, hr5.x, hr29.x, (last)hr18.x
mad.f16 hr16.x, hr5.x, hr29.y, (last)hr16.x
mad.f16 hr14.x, hr5.x, hr29.z, (last)hr14.x
mad.f16 hr12.x, hr5.x, hr29.w, (last)hr12.x
mad.f16 hr10.x, hr5.x, hr30.z, (last)hr10.x
mad.f16 hr8.x, hr5.x, hr30.w, (last)hr8.x
mad.f16 hr6.x, hr5.x, hr31.x, (last)hr6.x
mad.f16 hr18.y, hr5.y, hr29.x, (last)hr18.y
mad.f16 hr16.y, hr5.y, hr29.y, (last)hr16.y
mad.f16 hr14.y, hr5.y, hr29.z, (last)hr14.y
mad.f16 hr12.y, hr5.y, hr29.w, (last)hr12.y
mad.f16 hr10.y, hr5.y, hr30.z, (last)hr10.y
mad.f16 hr8.y, hr5.y, hr30.w, (last)hr8.y
mad.f16 hr6.y, hr5.y, hr31.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr5.z, hr29.x, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr5.z, hr29.y, (r)(last)hr16.z
ldl.u16 r28.z, l[r1.w+384], 4
(rpt1)mad.f16 hr14.z, (r)hr5.z, hr29.z, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr5.z, hr29.w, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr5.z, hr30.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr5.z, hr30.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr5.z, hr31.x, (r)(last)hr6.z
mad.f16 hr19.x, hr22.z, hr20.x, (last)hr19.x
mad.f16 hr17.x, hr22.z, hr20.y, (last)hr17.x
mad.f16 hr15.x, hr22.z, hr20.z, (last)hr15.x
mad.f16 hr13.x, hr22.z, hr20.w, (last)hr13.x
mad.f16 hr11.x, hr22.z, hr21.z, (last)hr11.x
mad.f16 hr9.x, hr22.z, hr21.w, (last)hr9.x
mad.f16 hr7.x, hr22.z, hr22.x, (last)hr7.x
mad.f16 hr19.y, hr22.w, hr20.x, (last)hr19.y
mad.f16 hr17.y, hr22.w, hr20.y, (last)hr17.y
mad.f16 hr15.y, hr22.w, hr20.z, (last)hr15.y
mad.f16 hr13.y, hr22.w, hr20.w, (last)hr13.y
mad.f16 hr11.y, hr22.w, hr21.z, (last)hr11.y
mad.f16 hr9.y, hr22.w, hr21.w, (last)hr9.y
mad.f16 hr7.y, hr22.w, hr22.x, (last)hr7.y
mad.f16 hr19.z, hr23.x, hr20.x, (last)hr19.z
mad.f16 hr17.z, hr23.x, hr20.y, (last)hr17.z
mad.f16 hr15.z, hr23.x, hr20.z, (last)hr15.z
mad.f16 hr13.z, hr23.x, hr20.w, (last)hr13.z
mad.f16 hr11.z, hr23.x, hr21.z, (last)hr11.z
mad.f16 hr9.z, hr23.x, hr21.w, (last)hr9.z
mad.f16 hr7.z, hr23.x, hr22.x, (last)hr7.z
mad.f16 hr19.w, hr23.y, hr20.x, (last)hr19.w
mad.f16 hr17.w, hr23.y, hr20.y, (last)hr17.w
mad.f16 hr15.w, hr23.y, hr20.z, (last)hr15.w
mad.f16 hr13.w, hr23.y, hr20.w, (last)hr13.w
mad.f16 hr11.w, hr23.y, hr21.z, (last)hr11.w
mad.f16 hr9.w, hr23.y, hr21.w, (last)hr9.w
mad.f16 hr7.w, hr23.y, hr22.x, (last)hr7.w
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr31.y, (r)(last)hr4.x
(rpt1)mad.f16 hr5.z, (r)(last)hr5.z, hr31.y, (r)(last)hr4.z
ldl.u16 r30.z, l[r1.w+448], 4
(rpt1)mad.f16 hr22.z, (r)(last)hr22.z, hr22.y, (r)(last)hr0.z
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr22.y, (r)(last)hr1.x
ldl.u16 r0.z, l[r10.z+2432], 4
ldl.u16 r4.x, l[r10.z+2496], 4
mad.f16 hr18.x, hr23.z, hr20.x, (last)hr18.x
mad.f16 hr16.x, hr23.z, hr20.y, (last)hr16.x
mad.f16 hr14.x, hr23.z, hr20.z, (last)hr14.x
mad.f16 hr12.x, hr23.z, hr20.w, (last)hr12.x
mad.f16 hr10.x, hr23.z, hr21.z, (last)hr10.x
mad.f16 hr8.x, hr23.z, hr21.w, (last)hr8.x
mad.f16 hr6.x, hr23.z, hr22.x, (last)hr6.x
mad.f16 hr18.y, hr23.w, hr20.x, (last)hr18.y
mad.f16 hr16.y, hr23.w, hr20.y, (last)hr16.y
mad.f16 hr14.y, hr23.w, hr20.z, (last)hr14.y
mad.f16 hr12.y, hr23.w, hr20.w, (last)hr12.y
mad.f16 hr10.y, hr23.w, hr21.z, (last)hr10.y
mad.f16 hr8.y, hr23.w, hr21.w, (last)hr8.y
mad.f16 hr6.y, hr23.w, hr22.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr24.x, hr20.x, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr24.x, hr20.y, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr24.x, hr20.z, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr24.x, hr20.w, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr24.x, hr21.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr24.x, hr21.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr24.x, hr22.x, (r)(last)hr6.z
mad.f16 hr19.x, hr26.z, hr24.z, (last)hr19.x
mad.f16 hr17.x, hr26.z, hr24.w, (last)hr17.x
mad.f16 hr15.x, hr26.z, hr25.x, (last)hr15.x
mad.f16 hr13.x, hr26.z, hr25.y, (last)hr13.x
mad.f16 hr11.x, hr26.z, hr25.z, (last)hr11.x
mad.f16 hr9.x, hr26.z, hr25.w, (last)hr9.x
mad.f16 hr7.x, hr26.z, hr26.x, (last)hr7.x
mad.f16 hr19.y, hr26.w, hr24.z, (last)hr19.y
mad.f16 hr17.y, hr26.w, hr24.w, (last)hr17.y
mad.f16 hr15.y, hr26.w, hr25.x, (last)hr15.y
mad.f16 hr13.y, hr26.w, hr25.y, (last)hr13.y
mad.f16 hr11.y, hr26.w, hr25.z, (last)hr11.y
mad.f16 hr9.y, hr26.w, hr25.w, (last)hr9.y
mad.f16 hr7.y, hr26.w, hr26.x, (last)hr7.y
mad.f16 hr19.z, hr27.x, hr24.z, (last)hr19.z
mad.f16 hr17.z, hr27.x, hr24.w, (last)hr17.z
mad.f16 hr15.z, hr27.x, hr25.x, (last)hr15.z
mad.f16 hr13.z, hr27.x, hr25.y, (last)hr13.z
mad.f16 hr11.z, hr27.x, hr25.z, (last)hr11.z
mad.f16 hr9.z, hr27.x, hr25.w, (last)hr9.z
mad.f16 hr7.z, hr27.x, hr26.x, (last)hr7.z
mad.f16 hr19.w, hr27.y, hr24.z, (last)hr19.w
mad.f16 hr17.w, hr27.y, hr24.w, (last)hr17.w
mad.f16 hr15.w, hr27.y, hr25.x, (last)hr15.w
mad.f16 hr13.w, hr27.y, hr25.y, (last)hr13.w
mad.f16 hr11.w, hr27.y, hr25.z, (last)hr11.w
mad.f16 hr9.w, hr27.y, hr25.w, (last)hr9.w
mad.f16 hr7.w, hr27.y, hr26.x, (last)hr7.w
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr22.y, (r)(last)hr5.x
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr22.y, (r)(last)hr5.z
ldl.u16 r5.x, l[r1.w+512], 4
ldl.u16 r20.x, l[r1.w+576], 4
ldl.u16 r21.z, l[r10.z+2560], 4
(rpt1)mad.f16 hr26.z, (r)(last)hr26.z, hr26.y, (r)(last)hr22.z
(rpt1)mad.f16 hr27.x, (r)(last)hr27.x, hr26.y, (r)(last)hr23.x
ldl.u16 r22.z, l[r10.z+2624], 4
mad.f16 hr18.x, hr27.z, hr24.z, (last)hr18.x
mad.f16 hr16.x, hr27.z, hr24.w, (last)hr16.x
mad.f16 hr14.x, hr27.z, hr25.x, (last)hr14.x
mad.f16 hr12.x, hr27.z, hr25.y, (last)hr12.x
mad.f16 hr10.x, hr27.z, hr25.z, (last)hr10.x
mad.f16 hr8.x, hr27.z, hr25.w, (last)hr8.x
mad.f16 hr6.x, hr27.z, hr26.x, (last)hr6.x
mad.f16 hr18.y, hr27.w, hr24.z, (last)hr18.y
mad.f16 hr16.y, hr27.w, hr24.w, (last)hr16.y
mad.f16 hr14.y, hr27.w, hr25.x, (last)hr14.y
mad.f16 hr12.y, hr27.w, hr25.y, (last)hr12.y
mad.f16 hr10.y, hr27.w, hr25.z, (last)hr10.y
mad.f16 hr8.y, hr27.w, hr25.w, (last)hr8.y
mad.f16 hr6.y, hr27.w, hr26.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr28.x, hr24.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr28.x, hr24.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr28.x, hr25.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr28.x, hr25.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr28.x, hr25.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr28.x, hr25.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr28.x, hr26.x, (r)(last)hr6.z
(ss)mad.f16 hr19.x, hr0.z, hr28.z, (last)hr19.x
mad.f16 hr17.x, hr0.z, hr28.w, (last)hr17.x
mad.f16 hr15.x, hr0.z, hr29.x, (last)hr15.x
mad.f16 hr13.x, hr0.z, hr29.y, (last)hr13.x
mad.f16 hr11.x, hr0.z, hr30.z, (last)hr11.x
mad.f16 hr9.x, hr0.z, hr30.w, (last)hr9.x
mad.f16 hr7.x, hr0.z, hr31.x, (last)hr7.x
mad.f16 hr19.y, hr0.w, hr28.z, (last)hr19.y
mad.f16 hr17.y, hr0.w, hr28.w, (last)hr17.y
mad.f16 hr15.y, hr0.w, hr29.x, (last)hr15.y
mad.f16 hr13.y, hr0.w, hr29.y, (last)hr13.y
mad.f16 hr11.y, hr0.w, hr30.z, (last)hr11.y
mad.f16 hr9.y, hr0.w, hr30.w, (last)hr9.y
mad.f16 hr7.y, hr0.w, hr31.x, (last)hr7.y
mad.f16 hr19.z, hr1.x, hr28.z, (last)hr19.z
mad.f16 hr17.z, hr1.x, hr28.w, (last)hr17.z
mad.f16 hr15.z, hr1.x, hr29.x, (last)hr15.z
mad.f16 hr13.z, hr1.x, hr29.y, (last)hr13.z
mad.f16 hr11.z, hr1.x, hr30.z, (last)hr11.z
mad.f16 hr9.z, hr1.x, hr30.w, (last)hr9.z
mad.f16 hr7.z, hr1.x, hr31.x, (last)hr7.z
mad.f16 hr19.w, hr1.y, hr28.z, (last)hr19.w
mad.f16 hr17.w, hr1.y, hr28.w, (last)hr17.w
mad.f16 hr15.w, hr1.y, hr29.x, (last)hr15.w
mad.f16 hr13.w, hr1.y, hr29.y, (last)hr13.w
mad.f16 hr11.w, hr1.y, hr30.z, (last)hr11.w
mad.f16 hr9.w, hr1.y, hr30.w, (last)hr9.w
mad.f16 hr7.w, hr1.y, hr31.x, (last)hr7.w
(rpt1)mad.f16 hr27.z, (r)(last)hr27.z, hr26.y, (r)(last)hr23.z
(rpt1)mad.f16 hr28.x, (r)(last)hr28.x, hr26.y, (r)(last)hr24.x
ldl.u16 r23.z, l[r1.w+640], 4
ldl.u16 r24.z, l[r1.w+704], 4
ldl.u16 r25.z, l[r10.z+2688], 4
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr31.y, (r)(last)hr26.z
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr31.y, (r)(last)hr27.x
ldl.u16 r26.z, l[r10.z+2752], 4
mad.f16 hr18.x, hr4.x, hr28.z, (last)hr18.x
mad.f16 hr16.x, hr4.x, hr28.w, (last)hr16.x
mad.f16 hr14.x, hr4.x, hr29.x, (last)hr14.x
mad.f16 hr12.x, hr4.x, hr29.y, (last)hr12.x
mad.f16 hr10.x, hr4.x, hr30.z, (last)hr10.x
mad.f16 hr8.x, hr4.x, hr30.w, (last)hr8.x
mad.f16 hr6.x, hr4.x, hr31.x, (last)hr6.x
mad.f16 hr18.y, hr4.y, hr28.z, (last)hr18.y
mad.f16 hr16.y, hr4.y, hr28.w, (last)hr16.y
mad.f16 hr14.y, hr4.y, hr29.x, (last)hr14.y
mad.f16 hr12.y, hr4.y, hr29.y, (last)hr12.y
mad.f16 hr10.y, hr4.y, hr30.z, (last)hr10.y
mad.f16 hr8.y, hr4.y, hr30.w, (last)hr8.y
mad.f16 hr6.y, hr4.y, hr31.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr4.z, hr28.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr4.z, hr28.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr4.z, hr29.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr4.z, hr29.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr4.z, hr30.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr4.z, hr30.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr4.z, hr31.x, (r)(last)hr6.z
(rpt1)mad.f16 hr4.x, (r)(last)hr4.x, hr31.y, (r)(last)hr27.z
(rpt1)mad.f16 hr4.z, (r)(last)hr4.z, hr31.y, (r)(last)hr28.x
ldl.u16 r27.z, l[r1.w+768], 4
ldl.u16 r28.z, l[r1.w+832], 4
ldl.u16 r30.z, l[r10.z+2816], 4
mad.f16 hr19.x, hr21.z, hr5.x, (last)hr19.x
mad.f16 hr17.x, hr21.z, hr5.y, (last)hr17.x
mad.f16 hr15.x, hr21.z, hr5.z, (last)hr15.x
mad.f16 hr13.x, hr21.z, hr5.w, (last)hr13.x
mad.f16 hr11.x, hr21.z, hr20.x, (last)hr11.x
mad.f16 hr9.x, hr21.z, hr20.y, (last)hr9.x
mad.f16 hr7.x, hr21.z, hr20.z, (last)hr7.x
mad.f16 hr19.y, hr21.w, hr5.x, (last)hr19.y
mad.f16 hr17.y, hr21.w, hr5.y, (last)hr17.y
mad.f16 hr15.y, hr21.w, hr5.z, (last)hr15.y
mad.f16 hr13.y, hr21.w, hr5.w, (last)hr13.y
mad.f16 hr11.y, hr21.w, hr20.x, (last)hr11.y
mad.f16 hr9.y, hr21.w, hr20.y, (last)hr9.y
mad.f16 hr7.y, hr21.w, hr20.z, (last)hr7.y
mad.f16 hr19.z, hr22.x, hr5.x, (last)hr19.z
mad.f16 hr17.z, hr22.x, hr5.y, (last)hr17.z
mad.f16 hr15.z, hr22.x, hr5.z, (last)hr15.z
mad.f16 hr13.z, hr22.x, hr5.w, (last)hr13.z
mad.f16 hr11.z, hr22.x, hr20.x, (last)hr11.z
mad.f16 hr9.z, hr22.x, hr20.y, (last)hr9.z
mad.f16 hr7.z, hr22.x, hr20.z, (last)hr7.z
mad.f16 hr19.w, hr22.y, hr5.x, (last)hr19.w
mad.f16 hr17.w, hr22.y, hr5.y, (last)hr17.w
mad.f16 hr15.w, hr22.y, hr5.z, (last)hr15.w
mad.f16 hr13.w, hr22.y, hr5.w, (last)hr13.w
mad.f16 hr11.w, hr22.y, hr20.x, (last)hr11.w
mad.f16 hr9.w, hr22.y, hr20.y, (last)hr9.w
mad.f16 hr7.w, hr22.y, hr20.z, (last)hr7.w
mad.f16 hr18.x, hr22.z, hr5.x, (last)hr18.x
mad.f16 hr16.x, hr22.z, hr5.y, (last)hr16.x
mad.f16 hr14.x, hr22.z, hr5.z, (last)hr14.x
mad.f16 hr12.x, hr22.z, hr5.w, (last)hr12.x
mad.f16 hr10.x, hr22.z, hr20.x, (last)hr10.x
mad.f16 hr8.x, hr22.z, hr20.y, (last)hr8.x
mad.f16 hr6.x, hr22.z, hr20.z, (last)hr6.x
mad.f16 hr18.y, hr22.w, hr5.x, (last)hr18.y
mad.f16 hr16.y, hr22.w, hr5.y, (last)hr16.y
mad.f16 hr14.y, hr22.w, hr5.z, (last)hr14.y
mad.f16 hr12.y, hr22.w, hr5.w, (last)hr12.y
mad.f16 hr10.y, hr22.w, hr20.x, (last)hr10.y
mad.f16 hr8.y, hr22.w, hr20.y, (last)hr8.y
mad.f16 hr6.y, hr22.w, hr20.z, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr23.x, hr5.x, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr23.x, hr5.y, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr23.x, hr5.z, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr23.x, hr5.w, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr23.x, hr20.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr23.x, hr20.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr23.x, hr20.z, (r)(last)hr6.z
(rpt1)mad.f16 hr21.z, (r)(last)hr21.z, hr20.w, (r)(last)hr0.z
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr20.w, (r)(last)hr1.x
ldl.u16 r0.z, l[r10.z+2880], 4
(rpt1)mad.f16 hr22.z, (r)(last)hr22.z, hr20.w, (r)(last)hr4.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr20.w, (r)(last)hr4.z
ldl.u16 r4.x, l[r1.w+896], 4
ldl.u16 r5.x, l[r1.w+960], 4
ldl.u16 r20.x, l[r10.z+2944], 4
(ss)mad.f16 hr19.x, hr25.z, hr23.z, (last)hr19.x
mad.f16 hr17.x, hr25.z, hr23.w, (last)hr17.x
mad.f16 hr15.x, hr25.z, hr24.x, (last)hr15.x
mad.f16 hr13.x, hr25.z, hr24.y, (last)hr13.x
mad.f16 hr11.x, hr25.z, hr24.z, (last)hr11.x
mad.f16 hr9.x, hr25.z, hr24.w, (last)hr9.x
mad.f16 hr7.x, hr25.z, hr25.x, (last)hr7.x
mad.f16 hr19.y, hr25.w, hr23.z, (last)hr19.y
mad.f16 hr17.y, hr25.w, hr23.w, (last)hr17.y
mad.f16 hr15.y, hr25.w, hr24.x, (last)hr15.y
mad.f16 hr13.y, hr25.w, hr24.y, (last)hr13.y
mad.f16 hr11.y, hr25.w, hr24.z, (last)hr11.y
mad.f16 hr9.y, hr25.w, hr24.w, (last)hr9.y
mad.f16 hr7.y, hr25.w, hr25.x, (last)hr7.y
mad.f16 hr19.z, hr26.x, hr23.z, (last)hr19.z
mad.f16 hr17.z, hr26.x, hr23.w, (last)hr17.z
mad.f16 hr15.z, hr26.x, hr24.x, (last)hr15.z
mad.f16 hr13.z, hr26.x, hr24.y, (last)hr13.z
mad.f16 hr11.z, hr26.x, hr24.z, (last)hr11.z
mad.f16 hr9.z, hr26.x, hr24.w, (last)hr9.z
mad.f16 hr7.z, hr26.x, hr25.x, (last)hr7.z
mad.f16 hr19.w, hr26.y, hr23.z, (last)hr19.w
mad.f16 hr17.w, hr26.y, hr23.w, (last)hr17.w
mad.f16 hr15.w, hr26.y, hr24.x, (last)hr15.w
mad.f16 hr13.w, hr26.y, hr24.y, (last)hr13.w
mad.f16 hr11.w, hr26.y, hr24.z, (last)hr11.w
mad.f16 hr9.w, hr26.y, hr24.w, (last)hr9.w
mad.f16 hr7.w, hr26.y, hr25.x, (last)hr7.w
mad.f16 hr18.x, hr26.z, hr23.z, (last)hr18.x
mad.f16 hr16.x, hr26.z, hr23.w, (last)hr16.x
mad.f16 hr14.x, hr26.z, hr24.x, (last)hr14.x
mad.f16 hr12.x, hr26.z, hr24.y, (last)hr12.x
mad.f16 hr10.x, hr26.z, hr24.z, (last)hr10.x
mad.f16 hr8.x, hr26.z, hr24.w, (last)hr8.x
mad.f16 hr6.x, hr26.z, hr25.x, (last)hr6.x
mad.f16 hr18.y, hr26.w, hr23.z, (last)hr18.y
mad.f16 hr16.y, hr26.w, hr23.w, (last)hr16.y
mad.f16 hr14.y, hr26.w, hr24.x, (last)hr14.y
mad.f16 hr12.y, hr26.w, hr24.y, (last)hr12.y
mad.f16 hr10.y, hr26.w, hr24.z, (last)hr10.y
mad.f16 hr8.y, hr26.w, hr24.w, (last)hr8.y
mad.f16 hr6.y, hr26.w, hr25.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr27.x, hr23.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr27.x, hr23.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr27.x, hr24.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr27.x, hr24.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr27.x, hr24.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr27.x, hr24.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr27.x, hr25.x, (r)(last)hr6.z
(rpt1)mad.f16 hr25.z, (r)(last)hr25.z, hr25.y, (r)(last)hr21.z
(rpt1)mad.f16 hr26.x, (r)(last)hr26.x, hr25.y, (r)(last)hr22.x
ldl.u16 r21.z, l[r10.z+3008], 4
(rpt1)mad.f16 hr26.z, (r)(last)hr26.z, hr25.y, (r)(last)hr22.z
(rpt1)mad.f16 hr27.x, (r)(last)hr27.x, hr25.y, (r)(last)hr23.x
ldl.u16 r22.z, l[r1.w+1024], 4
ldl.u16 r23.z, l[r1.w+1088], 4
ldl.u16 r24.z, l[r10.z+3072], 4
mad.f16 hr19.x, hr30.z, hr27.z, (last)hr19.x
mad.f16 hr17.x, hr30.z, hr27.w, (last)hr17.x
mad.f16 hr15.x, hr30.z, hr28.x, (last)hr15.x
mad.f16 hr13.x, hr30.z, hr28.y, (last)hr13.x
mad.f16 hr11.x, hr30.z, hr28.z, (last)hr11.x
mad.f16 hr9.x, hr30.z, hr28.w, (last)hr9.x
mad.f16 hr7.x, hr30.z, hr29.x, (last)hr7.x
mad.f16 hr19.y, hr30.w, hr27.z, (last)hr19.y
mad.f16 hr17.y, hr30.w, hr27.w, (last)hr17.y
mad.f16 hr15.y, hr30.w, hr28.x, (last)hr15.y
mad.f16 hr13.y, hr30.w, hr28.y, (last)hr13.y
mad.f16 hr11.y, hr30.w, hr28.z, (last)hr11.y
mad.f16 hr9.y, hr30.w, hr28.w, (last)hr9.y
mad.f16 hr7.y, hr30.w, hr29.x, (last)hr7.y
mad.f16 hr19.z, hr31.x, hr27.z, (last)hr19.z
mad.f16 hr17.z, hr31.x, hr27.w, (last)hr17.z
mad.f16 hr15.z, hr31.x, hr28.x, (last)hr15.z
mad.f16 hr13.z, hr31.x, hr28.y, (last)hr13.z
mad.f16 hr11.z, hr31.x, hr28.z, (last)hr11.z
mad.f16 hr9.z, hr31.x, hr28.w, (last)hr9.z
mad.f16 hr7.z, hr31.x, hr29.x, (last)hr7.z
mad.f16 hr19.w, hr31.y, hr27.z, (last)hr19.w
mad.f16 hr17.w, hr31.y, hr27.w, (last)hr17.w
mad.f16 hr15.w, hr31.y, hr28.x, (last)hr15.w
mad.f16 hr13.w, hr31.y, hr28.y, (last)hr13.w
mad.f16 hr11.w, hr31.y, hr28.z, (last)hr11.w
mad.f16 hr9.w, hr31.y, hr28.w, (last)hr9.w
mad.f16 hr7.w, hr31.y, hr29.x, (last)hr7.w
(rpt1)mad.f16 hr30.z, (r)(last)hr30.z, hr29.y, (r)(last)hr25.z
(rpt1)mad.f16 hr31.x, (r)(last)hr31.x, hr29.y, (r)(last)hr26.x
ldl.u16 r25.z, l[r10.z+3136], 4
mad.f16 hr18.x, hr0.z, hr27.z, (last)hr18.x
mad.f16 hr16.x, hr0.z, hr27.w, (last)hr16.x
mad.f16 hr14.x, hr0.z, hr28.x, (last)hr14.x
mad.f16 hr12.x, hr0.z, hr28.y, (last)hr12.x
mad.f16 hr10.x, hr0.z, hr28.z, (last)hr10.x
mad.f16 hr8.x, hr0.z, hr28.w, (last)hr8.x
mad.f16 hr6.x, hr0.z, hr29.x, (last)hr6.x
mad.f16 hr18.y, hr0.w, hr27.z, (last)hr18.y
mad.f16 hr16.y, hr0.w, hr27.w, (last)hr16.y
mad.f16 hr14.y, hr0.w, hr28.x, (last)hr14.y
mad.f16 hr12.y, hr0.w, hr28.y, (last)hr12.y
mad.f16 hr10.y, hr0.w, hr28.z, (last)hr10.y
mad.f16 hr8.y, hr0.w, hr28.w, (last)hr8.y
mad.f16 hr6.y, hr0.w, hr29.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr1.x, hr27.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr1.x, hr27.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr1.x, hr28.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr1.x, hr28.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr1.x, hr28.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr1.x, hr28.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr1.x, hr29.x, (r)(last)hr6.z
mad.f16 hr19.x, hr20.x, hr4.x, (last)hr19.x
mad.f16 hr17.x, hr20.x, hr4.y, (last)hr17.x
mad.f16 hr15.x, hr20.x, hr4.z, (last)hr15.x
mad.f16 hr13.x, hr20.x, hr4.w, (last)hr13.x
mad.f16 hr11.x, hr20.x, hr5.x, (last)hr11.x
mad.f16 hr9.x, hr20.x, hr5.y, (last)hr9.x
mad.f16 hr7.x, hr20.x, hr5.z, (last)hr7.x
mad.f16 hr19.y, hr20.y, hr4.x, (last)hr19.y
mad.f16 hr17.y, hr20.y, hr4.y, (last)hr17.y
mad.f16 hr15.y, hr20.y, hr4.z, (last)hr15.y
mad.f16 hr13.y, hr20.y, hr4.w, (last)hr13.y
mad.f16 hr11.y, hr20.y, hr5.x, (last)hr11.y
mad.f16 hr9.y, hr20.y, hr5.y, (last)hr9.y
mad.f16 hr7.y, hr20.y, hr5.z, (last)hr7.y
mad.f16 hr19.z, hr20.z, hr4.x, (last)hr19.z
mad.f16 hr17.z, hr20.z, hr4.y, (last)hr17.z
mad.f16 hr15.z, hr20.z, hr4.z, (last)hr15.z
mad.f16 hr13.z, hr20.z, hr4.w, (last)hr13.z
mad.f16 hr11.z, hr20.z, hr5.x, (last)hr11.z
mad.f16 hr9.z, hr20.z, hr5.y, (last)hr9.z
mad.f16 hr7.z, hr20.z, hr5.z, (last)hr7.z
mad.f16 hr19.w, hr20.w, hr4.x, (last)hr19.w
mad.f16 hr17.w, hr20.w, hr4.y, (last)hr17.w
mad.f16 hr15.w, hr20.w, hr4.z, (last)hr15.w
mad.f16 hr13.w, hr20.w, hr4.w, (last)hr13.w
mad.f16 hr11.w, hr20.w, hr5.x, (last)hr11.w
mad.f16 hr9.w, hr20.w, hr5.y, (last)hr9.w
mad.f16 hr7.w, hr20.w, hr5.z, (last)hr7.w
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr29.y, (r)(last)hr26.z
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr29.y, (r)(last)hr27.x
ldl.u16 r26.z, l[r1.w+1152], 4
ldl.u16 r27.z, l[r1.w+1216], 4
ldl.u16 r28.z, l[r10.z+3200], 4
(rpt1)mad.f16 hr20.x, (r)(last)hr20.x, hr5.w, (r)(last)hr30.z
(rpt1)mad.f16 hr20.z, (r)(last)hr20.z, hr5.w, (r)(last)hr31.x
ldl.u16 r30.z, l[r10.z+3264], 4
(ss)mad.f16 hr18.x, hr21.z, hr4.x, (last)hr18.x
mad.f16 hr16.x, hr21.z, hr4.y, (last)hr16.x
mad.f16 hr14.x, hr21.z, hr4.z, (last)hr14.x
mad.f16 hr12.x, hr21.z, hr4.w, (last)hr12.x
mad.f16 hr10.x, hr21.z, hr5.x, (last)hr10.x
mad.f16 hr8.x, hr21.z, hr5.y, (last)hr8.x
mad.f16 hr6.x, hr21.z, hr5.z, (last)hr6.x
mad.f16 hr18.y, hr21.w, hr4.x, (last)hr18.y
mad.f16 hr16.y, hr21.w, hr4.y, (last)hr16.y
mad.f16 hr14.y, hr21.w, hr4.z, (last)hr14.y
mad.f16 hr12.y, hr21.w, hr4.w, (last)hr12.y
mad.f16 hr10.y, hr21.w, hr5.x, (last)hr10.y
mad.f16 hr8.y, hr21.w, hr5.y, (last)hr8.y
mad.f16 hr6.y, hr21.w, hr5.z, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr22.x, hr4.x, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr22.x, hr4.y, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr22.x, hr4.z, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr22.x, hr4.w, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr22.x, hr5.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr22.x, hr5.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr22.x, hr5.z, (r)(last)hr6.z
mad.f16 hr19.x, hr24.z, hr22.z, (last)hr19.x
mad.f16 hr17.x, hr24.z, hr22.w, (last)hr17.x
mad.f16 hr15.x, hr24.z, hr23.x, (last)hr15.x
mad.f16 hr13.x, hr24.z, hr23.y, (last)hr13.x
mad.f16 hr11.x, hr24.z, hr23.z, (last)hr11.x
mad.f16 hr9.x, hr24.z, hr23.w, (last)hr9.x
mad.f16 hr7.x, hr24.z, hr24.x, (last)hr7.x
mad.f16 hr19.y, hr24.w, hr22.z, (last)hr19.y
mad.f16 hr17.y, hr24.w, hr22.w, (last)hr17.y
mad.f16 hr15.y, hr24.w, hr23.x, (last)hr15.y
mad.f16 hr13.y, hr24.w, hr23.y, (last)hr13.y
mad.f16 hr11.y, hr24.w, hr23.z, (last)hr11.y
mad.f16 hr9.y, hr24.w, hr23.w, (last)hr9.y
mad.f16 hr7.y, hr24.w, hr24.x, (last)hr7.y
mad.f16 hr19.z, hr25.x, hr22.z, (last)hr19.z
mad.f16 hr17.z, hr25.x, hr22.w, (last)hr17.z
mad.f16 hr15.z, hr25.x, hr23.x, (last)hr15.z
mad.f16 hr13.z, hr25.x, hr23.y, (last)hr13.z
mad.f16 hr11.z, hr25.x, hr23.z, (last)hr11.z
mad.f16 hr9.z, hr25.x, hr23.w, (last)hr9.z
mad.f16 hr7.z, hr25.x, hr24.x, (last)hr7.z
mad.f16 hr19.w, hr25.y, hr22.z, (last)hr19.w
mad.f16 hr17.w, hr25.y, hr22.w, (last)hr17.w
mad.f16 hr15.w, hr25.y, hr23.x, (last)hr15.w
mad.f16 hr13.w, hr25.y, hr23.y, (last)hr13.w
mad.f16 hr11.w, hr25.y, hr23.z, (last)hr11.w
mad.f16 hr9.w, hr25.y, hr23.w, (last)hr9.w
mad.f16 hr7.w, hr25.y, hr24.x, (last)hr7.w
(rpt1)mad.f16 hr21.z, (r)(last)hr21.z, hr5.w, (r)(last)hr0.z
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr5.w, (r)(last)hr1.x
ldl.u16 r0.z, l[r1.w+1280], 4
ldl.u16 r4.x, l[r1.w+1344], 4
ldl.u16 r5.x, l[r10.z+3328], 4
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr24.y, (r)(last)hr20.x
(rpt1)mad.f16 hr25.x, (r)(last)hr25.x, hr24.y, (r)(last)hr20.z
ldl.u16 r20.x, l[r10.z+3392], 4
mad.f16 hr18.x, hr25.z, hr22.z, (last)hr18.x
mad.f16 hr16.x, hr25.z, hr22.w, (last)hr16.x
mad.f16 hr14.x, hr25.z, hr23.x, (last)hr14.x
mad.f16 hr12.x, hr25.z, hr23.y, (last)hr12.x
mad.f16 hr10.x, hr25.z, hr23.z, (last)hr10.x
mad.f16 hr8.x, hr25.z, hr23.w, (last)hr8.x
mad.f16 hr6.x, hr25.z, hr24.x, (last)hr6.x
mad.f16 hr18.y, hr25.w, hr22.z, (last)hr18.y
mad.f16 hr16.y, hr25.w, hr22.w, (last)hr16.y
mad.f16 hr14.y, hr25.w, hr23.x, (last)hr14.y
mad.f16 hr12.y, hr25.w, hr23.y, (last)hr12.y
mad.f16 hr10.y, hr25.w, hr23.z, (last)hr10.y
mad.f16 hr8.y, hr25.w, hr23.w, (last)hr8.y
mad.f16 hr6.y, hr25.w, hr24.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr26.x, hr22.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr26.x, hr22.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr26.x, hr23.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr26.x, hr23.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr26.x, hr23.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr26.x, hr23.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr26.x, hr24.x, (r)(last)hr6.z
(rpt1)mad.f16 hr25.z, (r)(last)hr25.z, hr24.y, (r)(last)hr21.z
(rpt1)mad.f16 hr26.x, (r)(last)hr26.x, hr24.y, (r)(last)hr22.x
ldl.u16 r21.z, l[r1.w+1408], 4
ldl.u16 r22.z, l[r1.w+1472], 4
ldl.u16 r23.z, l[r10.z+3456], 4
mad.f16 hr19.x, hr28.z, hr26.z, (last)hr19.x
mad.f16 hr17.x, hr28.z, hr26.w, (last)hr17.x
mad.f16 hr15.x, hr28.z, hr27.x, (last)hr15.x
mad.f16 hr13.x, hr28.z, hr27.y, (last)hr13.x
mad.f16 hr11.x, hr28.z, hr27.z, (last)hr11.x
mad.f16 hr9.x, hr28.z, hr27.w, (last)hr9.x
mad.f16 hr7.x, hr28.z, hr28.x, (last)hr7.x
mad.f16 hr19.y, hr28.w, hr26.z, (last)hr19.y
mad.f16 hr17.y, hr28.w, hr26.w, (last)hr17.y
mad.f16 hr15.y, hr28.w, hr27.x, (last)hr15.y
mad.f16 hr13.y, hr28.w, hr27.y, (last)hr13.y
mad.f16 hr11.y, hr28.w, hr27.z, (last)hr11.y
mad.f16 hr9.y, hr28.w, hr27.w, (last)hr9.y
mad.f16 hr7.y, hr28.w, hr28.x, (last)hr7.y
mad.f16 hr19.z, hr29.x, hr26.z, (last)hr19.z
mad.f16 hr17.z, hr29.x, hr26.w, (last)hr17.z
mad.f16 hr15.z, hr29.x, hr27.x, (last)hr15.z
mad.f16 hr13.z, hr29.x, hr27.y, (last)hr13.z
mad.f16 hr11.z, hr29.x, hr27.z, (last)hr11.z
mad.f16 hr9.z, hr29.x, hr27.w, (last)hr9.z
mad.f16 hr7.z, hr29.x, hr28.x, (last)hr7.z
mad.f16 hr19.w, hr29.y, hr26.z, (last)hr19.w
mad.f16 hr17.w, hr29.y, hr26.w, (last)hr17.w
mad.f16 hr15.w, hr29.y, hr27.x, (last)hr15.w
mad.f16 hr13.w, hr29.y, hr27.y, (last)hr13.w
mad.f16 hr11.w, hr29.y, hr27.z, (last)hr11.w
mad.f16 hr9.w, hr29.y, hr27.w, (last)hr9.w
mad.f16 hr7.w, hr29.y, hr28.x, (last)hr7.w
mad.f16 hr18.x, hr30.z, hr26.z, (last)hr18.x
mad.f16 hr16.x, hr30.z, hr26.w, (last)hr16.x
mad.f16 hr14.x, hr30.z, hr27.x, (last)hr14.x
mad.f16 hr12.x, hr30.z, hr27.y, (last)hr12.x
mad.f16 hr10.x, hr30.z, hr27.z, (last)hr10.x
mad.f16 hr8.x, hr30.z, hr27.w, (last)hr8.x
mad.f16 hr6.x, hr30.z, hr28.x, (last)hr6.x
mad.f16 hr18.y, hr30.w, hr26.z, (last)hr18.y
mad.f16 hr16.y, hr30.w, hr26.w, (last)hr16.y
mad.f16 hr14.y, hr30.w, hr27.x, (last)hr14.y
mad.f16 hr12.y, hr30.w, hr27.y, (last)hr12.y
mad.f16 hr10.y, hr30.w, hr27.z, (last)hr10.y
mad.f16 hr8.y, hr30.w, hr27.w, (last)hr8.y
mad.f16 hr6.y, hr30.w, hr28.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr31.x, hr26.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr31.x, hr26.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr31.x, hr27.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr31.x, hr27.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr31.x, hr27.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr31.x, hr27.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr31.x, hr28.x, (r)(last)hr6.z
(rpt1)mad.f16 hr28.z, (r)(last)hr28.z, hr28.y, (r)(last)hr24.z
(rpt1)mad.f16 hr29.x, (r)(last)hr29.x, hr28.y, (r)(last)hr25.x
ldl.u16 r24.z, l[r10.z+3520], 4
(rpt1)mad.f16 hr30.z, (r)(last)hr30.z, hr28.y, (r)(last)hr25.z
(rpt1)mad.f16 hr31.x, (r)(last)hr31.x, hr28.y, (r)(last)hr26.x
ldl.u16 r25.z, l[r1.w+1536], 4
ldl.u16 r26.z, l[r1.w+1600], 4
ldl.u16 r27.z, l[r10.z+3584], 4
(ss)mad.f16 hr19.x, hr5.x, hr0.z, (last)hr19.x
mad.f16 hr17.x, hr5.x, hr0.w, (last)hr17.x
mad.f16 hr15.x, hr5.x, hr1.x, (last)hr15.x
mad.f16 hr13.x, hr5.x, hr1.y, (last)hr13.x
mad.f16 hr11.x, hr5.x, hr4.x, (last)hr11.x
mad.f16 hr9.x, hr5.x, hr4.y, (last)hr9.x
mad.f16 hr7.x, hr5.x, hr4.z, (last)hr7.x
mad.f16 hr19.y, hr5.y, hr0.z, (last)hr19.y
mad.f16 hr17.y, hr5.y, hr0.w, (last)hr17.y
mad.f16 hr15.y, hr5.y, hr1.x, (last)hr15.y
mad.f16 hr13.y, hr5.y, hr1.y, (last)hr13.y
mad.f16 hr11.y, hr5.y, hr4.x, (last)hr11.y
mad.f16 hr9.y, hr5.y, hr4.y, (last)hr9.y
mad.f16 hr7.y, hr5.y, hr4.z, (last)hr7.y
mad.f16 hr19.z, hr5.z, hr0.z, (last)hr19.z
mad.f16 hr17.z, hr5.z, hr0.w, (last)hr17.z
mad.f16 hr15.z, hr5.z, hr1.x, (last)hr15.z
mad.f16 hr13.z, hr5.z, hr1.y, (last)hr13.z
mad.f16 hr11.z, hr5.z, hr4.x, (last)hr11.z
mad.f16 hr9.z, hr5.z, hr4.y, (last)hr9.z
mad.f16 hr7.z, hr5.z, hr4.z, (last)hr7.z
mad.f16 hr19.w, hr5.w, hr0.z, (last)hr19.w
mad.f16 hr17.w, hr5.w, hr0.w, (last)hr17.w
mad.f16 hr15.w, hr5.w, hr1.x, (last)hr15.w
mad.f16 hr13.w, hr5.w, hr1.y, (last)hr13.w
mad.f16 hr11.w, hr5.w, hr4.x, (last)hr11.w
mad.f16 hr9.w, hr5.w, hr4.y, (last)hr9.w
mad.f16 hr7.w, hr5.w, hr4.z, (last)hr7.w
mad.f16 hr18.x, hr20.x, hr0.z, (last)hr18.x
mad.f16 hr16.x, hr20.x, hr0.w, (last)hr16.x
mad.f16 hr14.x, hr20.x, hr1.x, (last)hr14.x
mad.f16 hr12.x, hr20.x, hr1.y, (last)hr12.x
mad.f16 hr10.x, hr20.x, hr4.x, (last)hr10.x
mad.f16 hr8.x, hr20.x, hr4.y, (last)hr8.x
mad.f16 hr6.x, hr20.x, hr4.z, (last)hr6.x
mad.f16 hr18.y, hr20.y, hr0.z, (last)hr18.y
mad.f16 hr16.y, hr20.y, hr0.w, (last)hr16.y
mad.f16 hr14.y, hr20.y, hr1.x, (last)hr14.y
mad.f16 hr12.y, hr20.y, hr1.y, (last)hr12.y
mad.f16 hr10.y, hr20.y, hr4.x, (last)hr10.y
mad.f16 hr8.y, hr20.y, hr4.y, (last)hr8.y
mad.f16 hr6.y, hr20.y, hr4.z, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr20.z, hr0.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr20.z, hr0.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr20.z, hr1.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr20.z, hr1.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr20.z, hr4.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr20.z, hr4.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr20.z, hr4.z, (r)(last)hr6.z
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr4.w, (r)(last)hr28.z
(rpt1)mad.f16 hr5.z, (r)(last)hr5.z, hr4.w, (r)(last)hr29.x
ldl.u16 r28.z, l[r10.z+3648], 4
(rpt1)mad.f16 hr20.x, (r)(last)hr20.x, hr4.w, (r)(last)hr30.z
(rpt1)mad.f16 hr20.z, (r)(last)hr20.z, hr4.w, (r)(last)hr31.x
ldl.u16 r30.z, l[r1.w+1664], 4
ldl.u16 r0.z, l[r1.w+1728], 4
ldl.u16 r4.x, l[r10.z+3712], 4
mad.f16 hr19.x, hr23.z, hr21.z, (last)hr19.x
mad.f16 hr17.x, hr23.z, hr21.w, (last)hr17.x
mad.f16 hr15.x, hr23.z, hr22.x, (last)hr15.x
mad.f16 hr13.x, hr23.z, hr22.y, (last)hr13.x
mad.f16 hr11.x, hr23.z, hr22.z, (last)hr11.x
mad.f16 hr9.x, hr23.z, hr22.w, (last)hr9.x
mad.f16 hr7.x, hr23.z, hr23.x, (last)hr7.x
mad.f16 hr19.y, hr23.w, hr21.z, (last)hr19.y
mad.f16 hr17.y, hr23.w, hr21.w, (last)hr17.y
mad.f16 hr15.y, hr23.w, hr22.x, (last)hr15.y
mad.f16 hr13.y, hr23.w, hr22.y, (last)hr13.y
mad.f16 hr11.y, hr23.w, hr22.z, (last)hr11.y
mad.f16 hr9.y, hr23.w, hr22.w, (last)hr9.y
mad.f16 hr7.y, hr23.w, hr23.x, (last)hr7.y
mad.f16 hr19.z, hr24.x, hr21.z, (last)hr19.z
mad.f16 hr17.z, hr24.x, hr21.w, (last)hr17.z
mad.f16 hr15.z, hr24.x, hr22.x, (last)hr15.z
mad.f16 hr13.z, hr24.x, hr22.y, (last)hr13.z
mad.f16 hr11.z, hr24.x, hr22.z, (last)hr11.z
mad.f16 hr9.z, hr24.x, hr22.w, (last)hr9.z
mad.f16 hr7.z, hr24.x, hr23.x, (last)hr7.z
mad.f16 hr19.w, hr24.y, hr21.z, (last)hr19.w
mad.f16 hr17.w, hr24.y, hr21.w, (last)hr17.w
mad.f16 hr15.w, hr24.y, hr22.x, (last)hr15.w
mad.f16 hr13.w, hr24.y, hr22.y, (last)hr13.w
mad.f16 hr11.w, hr24.y, hr22.z, (last)hr11.w
mad.f16 hr9.w, hr24.y, hr22.w, (last)hr9.w
mad.f16 hr7.w, hr24.y, hr23.x, (last)hr7.w
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr23.y, (r)(last)hr5.x
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr23.y, (r)(last)hr5.z
ldl.u16 r5.x, l[r10.z+3776], 4
mad.f16 hr18.x, hr24.z, hr21.z, (last)hr18.x
mad.f16 hr16.x, hr24.z, hr21.w, (last)hr16.x
mad.f16 hr14.x, hr24.z, hr22.x, (last)hr14.x
mad.f16 hr12.x, hr24.z, hr22.y, (last)hr12.x
mad.f16 hr10.x, hr24.z, hr22.z, (last)hr10.x
mad.f16 hr8.x, hr24.z, hr22.w, (last)hr8.x
mad.f16 hr6.x, hr24.z, hr23.x, (last)hr6.x
mad.f16 hr18.y, hr24.w, hr21.z, (last)hr18.y
mad.f16 hr16.y, hr24.w, hr21.w, (last)hr16.y
mad.f16 hr14.y, hr24.w, hr22.x, (last)hr14.y
mad.f16 hr12.y, hr24.w, hr22.y, (last)hr12.y
mad.f16 hr10.y, hr24.w, hr22.z, (last)hr10.y
mad.f16 hr8.y, hr24.w, hr22.w, (last)hr8.y
mad.f16 hr6.y, hr24.w, hr23.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr25.x, hr21.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr25.x, hr21.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr25.x, hr22.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr25.x, hr22.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr25.x, hr22.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr25.x, hr22.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr25.x, hr23.x, (r)(last)hr6.z
mad.f16 hr19.x, hr27.z, hr25.z, (last)hr19.x
mad.f16 hr17.x, hr27.z, hr25.w, (last)hr17.x
mad.f16 hr15.x, hr27.z, hr26.x, (last)hr15.x
mad.f16 hr13.x, hr27.z, hr26.y, (last)hr13.x
mad.f16 hr11.x, hr27.z, hr26.z, (last)hr11.x
mad.f16 hr9.x, hr27.z, hr26.w, (last)hr9.x
mad.f16 hr7.x, hr27.z, hr27.x, (last)hr7.x
mad.f16 hr19.y, hr27.w, hr25.z, (last)hr19.y
mad.f16 hr17.y, hr27.w, hr25.w, (last)hr17.y
mad.f16 hr15.y, hr27.w, hr26.x, (last)hr15.y
mad.f16 hr13.y, hr27.w, hr26.y, (last)hr13.y
mad.f16 hr11.y, hr27.w, hr26.z, (last)hr11.y
mad.f16 hr9.y, hr27.w, hr26.w, (last)hr9.y
mad.f16 hr7.y, hr27.w, hr27.x, (last)hr7.y
mad.f16 hr19.z, hr28.x, hr25.z, (last)hr19.z
mad.f16 hr17.z, hr28.x, hr25.w, (last)hr17.z
mad.f16 hr15.z, hr28.x, hr26.x, (last)hr15.z
mad.f16 hr13.z, hr28.x, hr26.y, (last)hr13.z
mad.f16 hr11.z, hr28.x, hr26.z, (last)hr11.z
mad.f16 hr9.z, hr28.x, hr26.w, (last)hr9.z
mad.f16 hr7.z, hr28.x, hr27.x, (last)hr7.z
mad.f16 hr19.w, hr28.y, hr25.z, (last)hr19.w
mad.f16 hr17.w, hr28.y, hr25.w, (last)hr17.w
mad.f16 hr15.w, hr28.y, hr26.x, (last)hr15.w
mad.f16 hr13.w, hr28.y, hr26.y, (last)hr13.w
mad.f16 hr11.w, hr28.y, hr26.z, (last)hr11.w
mad.f16 hr9.w, hr28.y, hr26.w, (last)hr9.w
mad.f16 hr7.w, hr28.y, hr27.x, (last)hr7.w
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr23.y, (r)(last)hr20.x
(rpt1)mad.f16 hr25.x, (r)(last)hr25.x, hr23.y, (r)(last)hr20.z
ldl.u16 r20.x, l[r1.w+1792], 4
ldl.u16 r21.z, l[r1.w+1856], 4
ldl.u16 r22.z, l[r10.z+3840], 4
(rpt1)mad.f16 hr27.z, (r)(last)hr27.z, hr27.y, (r)(last)hr23.z
(rpt1)mad.f16 hr28.x, (r)(last)hr28.x, hr27.y, (r)(last)hr24.x
ldl.u16 r23.z, l[r10.z+3904], 4
(ss)mad.f16 hr18.x, hr28.z, hr25.z, (last)hr18.x
mad.f16 hr16.x, hr28.z, hr25.w, (last)hr16.x
mad.f16 hr14.x, hr28.z, hr26.x, (last)hr14.x
mad.f16 hr12.x, hr28.z, hr26.y, (last)hr12.x
mad.f16 hr10.x, hr28.z, hr26.z, (last)hr10.x
mad.f16 hr8.x, hr28.z, hr26.w, (last)hr8.x
mad.f16 hr6.x, hr28.z, hr27.x, (last)hr6.x
mad.f16 hr18.y, hr28.w, hr25.z, (last)hr18.y
mad.f16 hr16.y, hr28.w, hr25.w, (last)hr16.y
mad.f16 hr14.y, hr28.w, hr26.x, (last)hr14.y
mad.f16 hr12.y, hr28.w, hr26.y, (last)hr12.y
mad.f16 hr10.y, hr28.w, hr26.z, (last)hr10.y
mad.f16 hr8.y, hr28.w, hr26.w, (last)hr8.y
mad.f16 hr6.y, hr28.w, hr27.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr29.x, hr25.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr29.x, hr25.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr29.x, hr26.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr29.x, hr26.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr29.x, hr26.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr29.x, hr26.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr29.x, hr27.x, (r)(last)hr6.z
mad.f16 hr19.x, hr4.x, hr30.z, (last)hr19.x
mad.f16 hr17.x, hr4.x, hr30.w, (last)hr17.x
mad.f16 hr15.x, hr4.x, hr31.x, (last)hr15.x
mad.f16 hr13.x, hr4.x, hr31.y, (last)hr13.x
mad.f16 hr11.x, hr4.x, hr0.z, (last)hr11.x
mad.f16 hr9.x, hr4.x, hr0.w, (last)hr9.x
mad.f16 hr7.x, hr4.x, hr1.x, (last)hr7.x
mad.f16 hr19.y, hr4.y, hr30.z, (last)hr19.y
mad.f16 hr17.y, hr4.y, hr30.w, (last)hr17.y
mad.f16 hr15.y, hr4.y, hr31.x, (last)hr15.y
mad.f16 hr13.y, hr4.y, hr31.y, (last)hr13.y
mad.f16 hr11.y, hr4.y, hr0.z, (last)hr11.y
mad.f16 hr9.y, hr4.y, hr0.w, (last)hr9.y
mad.f16 hr7.y, hr4.y, hr1.x, (last)hr7.y
mad.f16 hr19.z, hr4.z, hr30.z, (last)hr19.z
mad.f16 hr17.z, hr4.z, hr30.w, (last)hr17.z
mad.f16 hr15.z, hr4.z, hr31.x, (last)hr15.z
mad.f16 hr13.z, hr4.z, hr31.y, (last)hr13.z
mad.f16 hr11.z, hr4.z, hr0.z, (last)hr11.z
mad.f16 hr9.z, hr4.z, hr0.w, (last)hr9.z
mad.f16 hr7.z, hr4.z, hr1.x, (last)hr7.z
mad.f16 hr19.w, hr4.w, hr30.z, (last)hr19.w
mad.f16 hr17.w, hr4.w, hr30.w, (last)hr17.w
mad.f16 hr15.w, hr4.w, hr31.x, (last)hr15.w
mad.f16 hr13.w, hr4.w, hr31.y, (last)hr13.w
mad.f16 hr11.w, hr4.w, hr0.z, (last)hr11.w
mad.f16 hr9.w, hr4.w, hr0.w, (last)hr9.w
mad.f16 hr7.w, hr4.w, hr1.x, (last)hr7.w
(rpt1)mad.f16 hr28.z, (r)(last)hr28.z, hr27.y, (r)(last)hr24.z
(rpt1)mad.f16 hr29.x, (r)(last)hr29.x, hr27.y, (r)(last)hr25.x
ldl.u16 r24.z, l[r1.w+1920], 4
ldl.u16 r25.z, l[r1.w+1984], 4
ldl.u16 r26.z, l[r10.z+3968], 4
(rpt1)mad.f16 hr4.x, (r)(last)hr4.x, hr1.y, (r)(last)hr27.z
(rpt1)mad.f16 hr4.z, (r)(last)hr4.z, hr1.y, (r)(last)hr28.x
ldl.u16 r27.z, l[r10.z+4032], 4
mad.f16 hr18.x, hr5.x, hr30.z, (last)hr18.x
mad.f16 hr16.x, hr5.x, hr30.w, (last)hr16.x
mad.f16 hr14.x, hr5.x, hr31.x, (last)hr14.x
mad.f16 hr12.x, hr5.x, hr31.y, (last)hr12.x
mad.f16 hr10.x, hr5.x, hr0.z, (last)hr10.x
mad.f16 hr8.x, hr5.x, hr0.w, (last)hr8.x
mad.f16 hr6.x, hr5.x, hr1.x, (last)hr6.x
mad.f16 hr18.y, hr5.y, hr30.z, (last)hr18.y
mad.f16 hr16.y, hr5.y, hr30.w, (last)hr16.y
mad.f16 hr14.y, hr5.y, hr31.x, (last)hr14.y
mad.f16 hr12.y, hr5.y, hr31.y, (last)hr12.y
mad.f16 hr10.y, hr5.y, hr0.z, (last)hr10.y
mad.f16 hr8.y, hr5.y, hr0.w, (last)hr8.y
mad.f16 hr6.y, hr5.y, hr1.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr5.z, hr30.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr5.z, hr30.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr5.z, hr31.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr5.z, hr31.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr5.z, hr0.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr5.z, hr0.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr5.z, hr1.x, (r)(last)hr6.z
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr1.y, (r)(last)hr28.z
(rpt1)mad.f16 hr5.z, (r)(last)hr5.z, hr1.y, (r)(last)hr29.x
mad.f16 hr19.x, hr22.z, hr20.x, (last)hr19.x
mad.f16 hr17.x, hr22.z, hr20.y, (last)hr17.x
mad.f16 hr15.x, hr22.z, hr20.z, (last)hr15.x
mad.f16 hr13.x, hr22.z, hr20.w, (last)hr13.x
mad.f16 hr11.x, hr22.z, hr21.z, (last)hr11.x
mad.f16 hr9.x, hr22.z, hr21.w, (last)hr9.x
mad.f16 hr7.x, hr22.z, hr22.x, (last)hr7.x
mad.f16 hr19.y, hr22.w, hr20.x, (last)hr19.y
mad.f16 hr17.y, hr22.w, hr20.y, (last)hr17.y
mad.f16 hr15.y, hr22.w, hr20.z, (last)hr15.y
mad.f16 hr13.y, hr22.w, hr20.w, (last)hr13.y
mad.f16 hr11.y, hr22.w, hr21.z, (last)hr11.y
mad.f16 hr9.y, hr22.w, hr21.w, (last)hr9.y
mad.f16 hr7.y, hr22.w, hr22.x, (last)hr7.y
mad.f16 hr19.z, hr23.x, hr20.x, (last)hr19.z
mad.f16 hr17.z, hr23.x, hr20.y, (last)hr17.z
mad.f16 hr15.z, hr23.x, hr20.z, (last)hr15.z
mad.f16 hr13.z, hr23.x, hr20.w, (last)hr13.z
mad.f16 hr11.z, hr23.x, hr21.z, (last)hr11.z
mad.f16 hr9.z, hr23.x, hr21.w, (last)hr9.z
mad.f16 hr7.z, hr23.x, hr22.x, (last)hr7.z
mad.f16 hr19.w, hr23.y, hr20.x, (last)hr19.w
mad.f16 hr17.w, hr23.y, hr20.y, (last)hr17.w
mad.f16 hr15.w, hr23.y, hr20.z, (last)hr15.w
mad.f16 hr13.w, hr23.y, hr20.w, (last)hr13.w
mad.f16 hr11.w, hr23.y, hr21.z, (last)hr11.w
mad.f16 hr9.w, hr23.y, hr21.w, (last)hr9.w
mad.f16 hr7.w, hr23.y, hr22.x, (last)hr7.w
mad.f16 hr18.x, hr23.z, hr20.x, (last)hr18.x
mad.f16 hr16.x, hr23.z, hr20.y, (last)hr16.x
mad.f16 hr14.x, hr23.z, hr20.z, (last)hr14.x
mad.f16 hr12.x, hr23.z, hr20.w, (last)hr12.x
mad.f16 hr10.x, hr23.z, hr21.z, (last)hr10.x
mad.f16 hr8.x, hr23.z, hr21.w, (last)hr8.x
mad.f16 hr6.x, hr23.z, hr22.x, (last)hr6.x
mad.f16 hr18.y, hr23.w, hr20.x, (last)hr18.y
mad.f16 hr16.y, hr23.w, hr20.y, (last)hr16.y
mad.f16 hr14.y, hr23.w, hr20.z, (last)hr14.y
mad.f16 hr12.y, hr23.w, hr20.w, (last)hr12.y
mad.f16 hr10.y, hr23.w, hr21.z, (last)hr10.y
mad.f16 hr8.y, hr23.w, hr21.w, (last)hr8.y
mad.f16 hr6.y, hr23.w, hr22.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr24.x, hr20.x, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr24.x, hr20.y, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr24.x, hr20.z, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr24.x, hr20.w, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr24.x, hr21.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr24.x, hr21.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr24.x, hr22.x, (r)(last)hr6.z
(rpt1)mad.f16 hr22.z, (r)(last)hr22.z, hr22.y, (r)(last)hr4.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr22.y, (r)(last)hr4.z
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr22.y, (r)(last)hr5.x
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr22.y, (r)(last)hr5.z
fence.r.w
(sy)(ss)mad.f16 hr19.x, hr26.z, hr24.z, (last)hr19.x
mad.f16 hr17.x, hr26.z, hr24.w, (last)hr17.x
mad.f16 hr15.x, hr26.z, hr25.x, (last)hr15.x
mad.f16 hr13.x, hr26.z, hr25.y, (last)hr13.x
mad.f16 hr11.x, hr26.z, hr25.z, (last)hr11.x
mad.f16 hr9.x, hr26.z, hr25.w, (last)hr9.x
mad.f16 hr7.x, hr26.z, hr26.x, (last)hr7.x
mad.f16 hr19.y, hr26.w, hr24.z, (last)hr19.y
mad.f16 hr17.y, hr26.w, hr24.w, (last)hr17.y
mad.f16 hr15.y, hr26.w, hr25.x, (last)hr15.y
mad.f16 hr13.y, hr26.w, hr25.y, (last)hr13.y
mad.f16 hr11.y, hr26.w, hr25.z, (last)hr11.y
mad.f16 hr9.y, hr26.w, hr25.w, (last)hr9.y
mad.f16 hr7.y, hr26.w, hr26.x, (last)hr7.y
mad.f16 hr19.z, hr27.x, hr24.z, (last)hr19.z
mad.f16 hr17.z, hr27.x, hr24.w, (last)hr17.z
mad.f16 hr15.z, hr27.x, hr25.x, (last)hr15.z
mad.f16 hr13.z, hr27.x, hr25.y, (last)hr13.z
mad.f16 hr11.z, hr27.x, hr25.z, (last)hr11.z
mad.f16 hr9.z, hr27.x, hr25.w, (last)hr9.z
mad.f16 hr7.z, hr27.x, hr26.x, (last)hr7.z
mad.f16 hr19.w, hr27.y, hr24.z, (last)hr19.w
mad.f16 hr17.w, hr27.y, hr24.w, (last)hr17.w
mad.f16 hr15.w, hr27.y, hr25.x, (last)hr15.w
mad.f16 hr13.w, hr27.y, hr25.y, (last)hr13.w
mad.f16 hr11.w, hr27.y, hr25.z, (last)hr11.w
mad.f16 hr9.w, hr27.y, hr25.w, (last)hr9.w
mad.f16 hr7.w, hr27.y, hr26.x, (last)hr7.w
mad.f16 hr18.x, hr27.z, hr24.z, (last)hr18.x
mad.f16 hr16.x, hr27.z, hr24.w, (last)hr16.x
mad.f16 hr14.x, hr27.z, hr25.x, (last)hr14.x
mad.f16 hr12.x, hr27.z, hr25.y, (last)hr12.x
mad.f16 hr10.x, hr27.z, hr25.z, (last)hr10.x
mad.f16 hr8.x, hr27.z, hr25.w, (last)hr8.x
mad.f16 hr6.x, hr27.z, hr26.x, (last)hr6.x
mad.f16 hr18.y, hr27.w, hr24.z, (last)hr18.y
mad.f16 hr16.y, hr27.w, hr24.w, (last)hr16.y
mad.f16 hr14.y, hr27.w, hr25.x, (last)hr14.y
mad.f16 hr12.y, hr27.w, hr25.y, (last)hr12.y
mad.f16 hr10.y, hr27.w, hr25.z, (last)hr10.y
mad.f16 hr8.y, hr27.w, hr25.w, (last)hr8.y
mad.f16 hr6.y, hr27.w, hr26.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr28.x, hr24.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr28.x, hr24.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr28.x, hr25.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr28.x, hr25.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr28.x, hr25.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr28.x, hr25.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr28.x, hr26.x, (r)(last)hr6.z
mad.f16 hr4.x, (last)hr27.z, hr26.y, (last)hr23.z
mad.f16 hr5.x, (last)hr26.z, hr26.y, (last)hr22.z
mad.f16 hr4.y, (last)hr27.w, hr26.y, (last)hr23.w
mad.f16 hr5.y, (last)hr26.w, hr26.y, (last)hr22.w
mad.f16 hr4.z, (last)hr28.x, hr26.y, (last)hr24.x
mad.f16 hr5.z, (last)hr27.x, hr26.y, (last)hr23.x
mad.f16 hr4.w, (last)hr28.y, hr26.y, (last)hr24.y
mad.f16 hr5.w, (last)hr27.y, hr26.y, (last)hr23.y
bar.g
(sy)(ss)br p0.x, #l1079
jump #l100
l1079:
(jp)(eolm)nop
(nop3) add.u r15.x, r52.w, (last)r15.x
(nop3) shl.b r15.x, (last)r15.x, 9
(nop3) sad.s32 r15.x, r53.w, r15.x, (last)r1.y
(nop3) shl.b r15.x, (last)r15.x, 2
(rpt3)add.u r0.x, r15.x, (r)c1.x
(rpt3)add.u r1.x, r15.x, (r)c2.x
stib.b.untyped.1d.u16.4.imm.base0 hr19.x, r15.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr18.x, r15.x+32, 4
stib.b.untyped.1d.u16.4.imm.base0 hr17.x, r0.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.x, r0.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr15.x, r0.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr14.x, r0.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr13.x, r1.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr12.x, r1.y, 4
(ss)(rpt1)add.u r6.x, r15.x, (r)c4.x
stib.b.untyped.1d.u16.4.imm.base0 hr11.x, r1.z, 4
(ss)(rpt1)add.u r5.z, r15.x, (r)c3.z
stib.b.untyped.1d.u16.4.imm.base0 hr10.x, r1.w, 4
(ss)(rpt1)add.u r5.x, (last)r15.x, (r)c3.x
(rpt4)nop
stib.b.untyped.1d.u16.4.imm.base0 hr9.x, r5.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr8.x, r5.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr7.x, r5.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr6.x, r5.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r6.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r6.y, 4
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
; CL prog 23/1: 1294 instr, 30 nops, 1264 non-nops, 65 mov, 0 cov, 2240 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 16 full, 8 constlen
; CL prog 23/1: 33 cat0, 65 cat1, 63 cat2, 1033 cat3, 0 cat4, 8 cat5, 88 cat6, 4 cat7
; CL prog 23/1: 60 sstall, 17 (ss), 66 systall, 6 (sy), 1 loops
; CL prog 23/1: 16 max_waves, 0 double_threadsize
; 27 preamble-instr, 1 early-preamble
