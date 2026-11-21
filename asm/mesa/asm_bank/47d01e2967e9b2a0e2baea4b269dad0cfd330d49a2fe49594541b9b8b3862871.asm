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
mov.u16u16 hr3.z, 0
mov.u16u16 hr3.w, 0
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
mov.u16u16 hr4.y, 0
mov.u16u16 hr4.x, 0
l130:
shr.b r52.z, r52.x, 2
shr.b r52.w, r51.w, 2
shl.b r53.x, r52.y, 9
add.u r10.z, r0.x, 64
add.u r10.w, r0.x, 128
shl.b r9.w, r0.w, 7
shl.b r10.x, r1.x, 3
(rpt1)shr.b r10.z, (last)(r)r10.z, 4
(ss)add.u r11.y, r52.y, r0.w
add.u r11.x, r0.x, 192
(rpt1)add.u r11.z, r52.y, (r)r10.z
shl.b r11.y, (last)r11.y, 9
add.u r9.w, (last)r9.w, r10.x
(rpt1)shl.b r11.z, (last)(r)r11.z, 9
sad.s32 r11.y, r52.z, r11.y, r1.x
shr.b r11.x, (last)r11.x, 4
(rpt1)sad.s32 r11.z, r52.z, (r)r11.z, r1.x
shl.b r11.y, (last)r11.y, 2
shl.b r10.z, (last)r10.z, 7
(rpt1)shl.b r11.z, (last)(r)r11.z, 2
shl.b r10.w, (last)r10.w, 7
add.u r12.x, r52.y, r11.x
add.u r52.y, r52.y, 16
cmps.u.ge up0.x, r52.y, c1.x
shl.b r11.x, (last)r11.x, 7
isam.v.base0 (u16)(xyzw)hr24.z, r11.y, s#0, t#2
(rpt1)add.u r10.z, (last)(r)r10.z, r10.x
isam.v.base0 (u16)(xyzw)hr36.z, r11.z, s#0, t#2
shl.b r12.x, (last)r12.x, 9
add.u r11.x, (last)r11.x, (last)r10.x
sad.s32 r13.x, r53.x, r1.z, r52.w
shl.b r10.y, r1.y, 3
sad.s32 r12.x, r52.z, r12.x, r1.x
shl.b r12.w, r1.z, 2
(nop1) shl.b r13.x, (last)r13.x, 2
(nop1) shl.b r12.x, (last)r12.x, 2
add.u r13.y, r13.x, c1.x
add.u r13.z, r13.x, c4.w
add.u r13.w, r13.x, c4.z
add.u r14.x, r13.x, c5.x
add.u r14.y, r13.x, c4.y
add.u r14.z, r13.x, c5.y
add.u r14.w, r13.x, c4.x
add.u r15.x, r13.x, c8.z
add.u r15.y, r13.x, c3.w
add.u r15.z, r13.x, c8.y
add.u r15.w, r13.x, c3.z
add.u r16.x, r13.x, c8.x
add.u r16.y, r13.x, c3.y
add.u r16.z, r13.x, c7.w
add.u r16.w, r13.x, c3.x
add.u r17.x, r13.x, c7.z
add.u r17.y, r13.x, c2.w
add.u r17.z, r13.x, c7.y
add.u r17.w, r13.x, c2.z
add.u r18.x, r13.x, c7.x
add.u r18.w, r13.x, c2.y
add.u r19.x, r13.x, c6.w
add.u r19.y, r13.x, c2.x
add.u r19.z, r13.x, c6.z
add.u r19.w, r13.x, c1.w
add.u r20.x, r13.x, c6.y
add.u r20.y, r13.x, c1.z
add.u r20.z, r13.x, c6.x
add.u r0.y, r13.x, c1.y
add.u r0.z, r13.x, c5.w
(sy)stl.u16 l[r9.w], r24.z, 4
(ss)nop
isam.v.base0 (u16)(xyzw)hr19.z, r11.w, s#0, t#2
stl.u16 l[r10.z], r36.z, 4
(sy)stl.u16 l[r10.w], r19.z, 4
(ss)nop
isam.v.base0 (u16)(xyzw)hr21.x, r12.x, s#0, t#2
(sy)stl.u16 l[r11.x], r21.x, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
isam.v.base0 (u16)(xyzw)hr22.x, r13.x, s#0, t#0
ldl.u16 r23.x, l[r10.y], 4
isam.v.base0 (u16)(xyzw)hr24.x, r13.x+32, s#0, t#0
ldl.u16 r21.x, l[r10.y+64], 4
(sy)(ss)mad.f16 hr18.z, hr23.x, hr22.x, (last)hr18.z
mad.f16 hr16.z, hr23.x, hr22.y, (last)hr16.z
mad.f16 hr14.z, hr23.x, hr22.z, (last)hr14.z
mad.f16 hr12.z, hr23.x, hr22.w, (last)hr12.z
mad.f16 hr18.w, hr23.y, hr22.x, (last)hr18.w
mad.f16 hr16.w, hr23.y, hr22.y, (last)hr16.w
mad.f16 hr14.w, hr23.y, hr22.z, (last)hr14.w
mad.f16 hr12.w, hr23.y, hr22.w, (last)hr12.w
mad.f16 hr19.x, hr23.z, hr22.x, (last)hr19.x
mad.f16 hr17.x, hr23.z, hr22.y, (last)hr17.x
mad.f16 hr15.x, hr23.z, hr22.z, (last)hr15.x
mad.f16 hr13.x, hr23.z, hr22.w, (last)hr13.x
mad.f16 hr19.y, hr23.w, hr22.x, (last)hr19.y
mad.f16 hr17.y, hr23.w, hr22.y, (last)hr17.y
mad.f16 hr15.y, hr23.w, hr22.z, (last)hr15.y
mad.f16 hr13.y, hr23.w, hr22.w, (last)hr13.y
mad.f16 hr17.z, hr21.x, hr22.x, (last)hr17.z
mad.f16 hr15.z, hr21.x, hr22.y, (last)hr15.z
mad.f16 hr13.z, hr21.x, hr22.z, (last)hr13.z
mad.f16 hr11.z, hr21.x, hr22.w, (last)hr11.z
mad.f16 hr17.w, hr21.y, hr22.x, (last)hr17.w
mad.f16 hr15.w, hr21.y, hr22.y, (last)hr15.w
mad.f16 hr13.w, hr21.y, hr22.z, (last)hr13.w
mad.f16 hr11.w, hr21.y, hr22.w, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr21.z, hr22.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr21.z, hr22.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr21.z, hr22.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr21.z, hr22.w, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr22.x, r13.y, s#0, t#0
(ss)nop
isam.v.base0 (u16)(xyzw)hr26.x, r13.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr19.z, r13.w, s#0, t#0
(rpt1)mad.f16 hr10.z, (r)hr23.x, hr24.x, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr23.z, hr24.x, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr23.x, hr24.y, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr23.z, hr24.y, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr23.x, hr24.z, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr23.z, hr24.z, (r)(last)hr7.x
mad.f16 hr9.z, hr21.x, hr24.x, (last)hr9.z
mad.f16 hr7.z, hr21.x, hr24.y, (last)hr7.z
mad.f16 hr5.z, hr21.x, hr24.z, (last)hr5.z
mad.f16 hr9.w, hr21.y, hr24.x, (last)hr9.w
mad.f16 hr7.w, hr21.y, hr24.y, (last)hr7.w
mad.f16 hr5.w, hr21.y, hr24.z, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr21.z, hr24.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr21.z, hr24.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr21.z, hr24.z, (r)(last)hr6.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr24.w, (r)(last)hr4.z
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr24.w, (r)(last)hr5.x
(rpt1)mad.f16 hr21.x, (r)(last)hr21.x, hr24.w, (r)(last)hr3.z
(rpt1)mad.f16 hr21.z, (r)(last)hr21.z, hr24.w, (r)(last)hr4.x
ldl.u16 r24.y, l[r10.y+128], 4
ldl.u16 r3.w, l[r10.y+192], 4
(sy)(ss)mad.f16 hr18.z, hr24.y, hr22.x, (last)hr18.z
mad.f16 hr16.z, hr24.y, hr22.y, (last)hr16.z
mad.f16 hr14.z, hr24.y, hr22.z, (last)hr14.z
mad.f16 hr12.z, hr24.y, hr22.w, (last)hr12.z
mad.f16 hr18.w, hr24.z, hr22.x, (last)hr18.w
mad.f16 hr16.w, hr24.z, hr22.y, (last)hr16.w
mad.f16 hr14.w, hr24.z, hr22.z, (last)hr14.w
mad.f16 hr12.w, hr24.z, hr22.w, (last)hr12.w
mad.f16 hr19.x, hr24.w, hr22.x, (last)hr19.x
mad.f16 hr17.x, hr24.w, hr22.y, (last)hr17.x
mad.f16 hr15.x, hr24.w, hr22.z, (last)hr15.x
mad.f16 hr13.x, hr24.w, hr22.w, (last)hr13.x
mad.f16 hr19.y, hr25.x, hr22.x, (last)hr19.y
mad.f16 hr17.y, hr25.x, hr22.y, (last)hr17.y
mad.f16 hr15.y, hr25.x, hr22.z, (last)hr15.y
mad.f16 hr13.y, hr25.x, hr22.w, (last)hr13.y
mad.f16 hr17.z, hr3.w, hr22.x, (last)hr17.z
mad.f16 hr15.z, hr3.w, hr22.y, (last)hr15.z
mad.f16 hr13.z, hr3.w, hr22.z, (last)hr13.z
mad.f16 hr11.z, hr3.w, hr22.w, (last)hr11.z
mad.f16 hr17.w, hr4.x, hr22.x, (last)hr17.w
mad.f16 hr15.w, hr4.x, hr22.y, (last)hr15.w
mad.f16 hr13.w, hr4.x, hr22.z, (last)hr13.w
mad.f16 hr11.w, hr4.x, hr22.w, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr4.y, hr22.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr4.y, hr22.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr4.y, hr22.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr4.y, hr22.w, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr22.x, r14.x, s#0, t#0
mad.f16 hr9.z, hr3.w, hr26.x, (last)hr9.z
mad.f16 hr7.z, hr3.w, hr26.y, (last)hr7.z
mad.f16 hr5.z, hr3.w, hr26.z, (last)hr5.z
mad.f16 hr9.w, hr4.x, hr26.x, (last)hr9.w
mad.f16 hr7.w, hr4.x, hr26.y, (last)hr7.w
mad.f16 hr5.w, hr4.x, hr26.z, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr4.y, hr26.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr4.y, hr26.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr4.y, hr26.z, (r)(last)hr6.x
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr26.w, (r)(last)hr21.x
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr26.w, (r)(last)hr21.z
ldl.u16 r21.x, l[r10.y+256], 4
(rpt1)mad.f16 hr10.z, (r)hr24.y, hr26.x, (r)(last)hr10.z
mad.f16 hr11.x, hr24.w, hr26.x, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr24.y, hr26.y, (r)(last)hr8.z
mad.f16 hr9.x, hr24.w, hr26.y, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr24.y, hr26.z, (r)(last)hr6.z
mad.f16 hr7.x, hr24.w, hr26.z, (last)hr7.x
(rpt1)mad.f16 hr24.y, (r)(last)hr24.y, hr26.w, (r)(last)hr23.x
mad.f16 hr24.w, (last)hr24.w, hr26.w, (last)hr23.z
(ss)mad.f16 hr18.z, hr21.x, hr19.z, (last)hr18.z
mad.f16 hr16.z, hr21.x, hr19.w, (last)hr16.z
mad.f16 hr14.z, hr21.x, hr20.x, (last)hr14.z
mad.f16 hr12.z, hr21.x, hr20.y, (last)hr12.z
mad.f16 hr18.w, hr21.y, hr19.z, (last)hr18.w
mad.f16 hr16.w, hr21.y, hr19.w, (last)hr16.w
mad.f16 hr14.w, hr21.y, hr20.x, (last)hr14.w
mad.f16 hr12.w, hr21.y, hr20.y, (last)hr12.w
mad.f16 hr19.x, hr21.z, hr19.z, (last)hr19.x
mad.f16 hr17.x, hr21.z, hr19.w, (last)hr17.x
mad.f16 hr15.x, hr21.z, hr20.x, (last)hr15.x
mad.f16 hr13.x, hr21.z, hr20.y, (last)hr13.x
(sy)(rpt1)mad.f16 hr10.z, (r)hr21.x, hr22.x, (r)(last)hr10.z
mad.f16 hr11.x, hr21.z, hr22.x, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr21.x, hr22.y, (r)(last)hr8.z
mad.f16 hr9.x, hr21.z, hr22.y, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr21.x, hr22.z, (r)(last)hr6.z
mad.f16 hr7.x, hr21.z, hr22.z, (last)hr7.x
(rpt1)mad.f16 hr21.x, (r)(last)hr21.x, hr22.w, (r)(last)hr24.y
mad.f16 hr21.z, (last)hr21.z, hr22.w, (last)hr24.w
isam.v.base0 (u16)(xyzw)hr24.x, r14.y, s#0, t#0
isam.v.base0 (u16)(xyzw)hr27.y, r14.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr36.z, r14.w, s#0, t#0
mad.f16 hr11.y, hr25.x, hr26.x, (last)hr11.y
mad.f16 hr9.y, hr25.x, hr26.y, (last)hr9.y
mad.f16 hr7.y, hr25.x, hr26.z, (last)hr7.y
mad.f16 hr25.x, (last)hr25.x, hr26.w, (last)hr23.w
ldl.u16 r23.x, l[r10.y+320], 4
ldl.u16 r26.y, l[r10.y+384], 4
mad.f16 hr19.y, hr21.w, hr19.z, (last)hr19.y
mad.f16 hr17.y, hr21.w, hr19.w, (last)hr17.y
mad.f16 hr15.y, hr21.w, hr20.x, (last)hr15.y
mad.f16 hr13.y, hr21.w, hr20.y, (last)hr13.y
mad.f16 hr11.y, hr21.w, hr22.x, (last)hr11.y
mad.f16 hr9.y, hr21.w, hr22.y, (last)hr9.y
mad.f16 hr7.y, hr21.w, hr22.z, (last)hr7.y
mad.f16 hr21.w, (last)hr21.w, hr22.w, (last)hr25.x
(ss)mad.f16 hr17.z, hr23.x, hr19.z, (last)hr17.z
ldl.u16 r28.y, l[r10.y+448], 4
mad.f16 hr15.z, hr23.x, hr19.w, (last)hr15.z
mad.f16 hr13.z, hr23.x, hr20.x, (last)hr13.z
mad.f16 hr11.z, hr23.x, hr20.y, (last)hr11.z
mad.f16 hr17.w, hr23.y, hr19.z, (last)hr17.w
mad.f16 hr15.w, hr23.y, hr19.w, (last)hr15.w
mad.f16 hr13.w, hr23.y, hr20.x, (last)hr13.w
mad.f16 hr11.w, hr23.y, hr20.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr23.z, hr19.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr23.z, hr19.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr23.z, hr20.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr23.z, hr20.y, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr19.z, r15.x, s#0, t#0
mad.f16 hr9.z, hr23.x, hr22.x, (last)hr9.z
mad.f16 hr7.z, hr23.x, hr22.y, (last)hr7.z
mad.f16 hr5.z, hr23.x, hr22.z, (last)hr5.z
mad.f16 hr9.w, hr23.y, hr22.x, (last)hr9.w
mad.f16 hr7.w, hr23.y, hr22.y, (last)hr7.w
mad.f16 hr5.w, hr23.y, hr22.z, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr23.z, hr22.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr23.z, hr22.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr23.z, hr22.z, (r)(last)hr6.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr22.w, (r)(last)hr3.w
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr22.w, (r)(last)hr4.y
isam.v.base0 (u16)(xyzw)hr22.x, r15.y, s#0, t#0
ldl.u16 r3.w, l[r10.y+512], 4
(sy)mad.f16 hr18.z, hr26.y, hr24.x, (last)hr18.z
mad.f16 hr16.z, hr26.y, hr24.y, (last)hr16.z
mad.f16 hr14.z, hr26.y, hr24.z, (last)hr14.z
mad.f16 hr12.z, hr26.y, hr24.w, (last)hr12.z
mad.f16 hr18.w, hr26.z, hr24.x, (last)hr18.w
mad.f16 hr16.w, hr26.z, hr24.y, (last)hr16.w
mad.f16 hr14.w, hr26.z, hr24.z, (last)hr14.w
mad.f16 hr12.w, hr26.z, hr24.w, (last)hr12.w
mad.f16 hr19.x, hr26.w, hr24.x, (last)hr19.x
mad.f16 hr17.x, hr26.w, hr24.y, (last)hr17.x
mad.f16 hr15.x, hr26.w, hr24.z, (last)hr15.x
mad.f16 hr13.x, hr26.w, hr24.w, (last)hr13.x
mad.f16 hr19.y, hr27.x, hr24.x, (last)hr19.y
mad.f16 hr17.y, hr27.x, hr24.y, (last)hr17.y
mad.f16 hr15.y, hr27.x, hr24.z, (last)hr15.y
mad.f16 hr13.y, hr27.x, hr24.w, (last)hr13.y
(ss)mad.f16 hr17.z, hr28.y, hr24.x, (last)hr17.z
mad.f16 hr15.z, hr28.y, hr24.y, (last)hr15.z
mad.f16 hr13.z, hr28.y, hr24.z, (last)hr13.z
mad.f16 hr11.z, hr28.y, hr24.w, (last)hr11.z
mad.f16 hr17.w, hr28.z, hr24.x, (last)hr17.w
mad.f16 hr15.w, hr28.z, hr24.y, (last)hr15.w
mad.f16 hr13.w, hr28.z, hr24.z, (last)hr13.w
mad.f16 hr11.w, hr28.z, hr24.w, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr28.w, hr24.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr28.w, hr24.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr28.w, hr24.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr28.w, hr24.w, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr24.x, r15.z, s#0, t#0
(rpt1)mad.f16 hr10.z, (r)hr26.y, hr27.y, (r)(last)hr10.z
mad.f16 hr11.x, hr26.w, hr27.y, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr26.y, hr27.z, (r)(last)hr8.z
mad.f16 hr9.x, hr26.w, hr27.z, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr26.y, hr27.w, (r)(last)hr6.z
mad.f16 hr7.x, hr26.w, hr27.w, (last)hr7.x
mad.f16 hr11.y, hr27.x, hr27.y, (last)hr11.y
mad.f16 hr9.y, hr27.x, hr27.z, (last)hr9.y
mad.f16 hr7.y, hr27.x, hr27.w, (last)hr7.y
mad.f16 hr9.z, hr28.y, hr27.y, (last)hr9.z
mad.f16 hr7.z, hr28.y, hr27.z, (last)hr7.z
mad.f16 hr5.z, hr28.y, hr27.w, (last)hr5.z
mad.f16 hr9.w, hr28.z, hr27.y, (last)hr9.w
mad.f16 hr7.w, hr28.z, hr27.z, (last)hr7.w
mad.f16 hr5.w, hr28.z, hr27.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr28.w, hr27.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr28.w, hr27.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr28.w, hr27.w, (r)(last)hr6.x
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr28.x, (r)(last)hr21.x
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr28.x, (r)(last)hr21.z
ldl.u16 r21.x, l[r10.y+576], 4
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr28.x, (r)(last)hr23.x
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr28.x, (r)(last)hr23.z
isam.v.base0 (u16)(xyzw)hr27.y, r15.w, s#0, t#0
isam.v.base0 (u16)(xyzw)hr29.y, r16.x, s#0, t#0
ldl.u16 r23.x, l[r10.y+640], 4
mad.f16 hr18.z, hr3.w, hr36.z, (last)hr18.z
mad.f16 hr16.z, hr3.w, hr36.w, (last)hr16.z
mad.f16 hr14.z, hr3.w, hr37.x, (last)hr14.z
mad.f16 hr12.z, hr3.w, hr37.y, (last)hr12.z
mad.f16 hr18.w, hr4.x, hr36.z, (last)hr18.w
mad.f16 hr16.w, hr4.x, hr36.w, (last)hr16.w
mad.f16 hr14.w, hr4.x, hr37.x, (last)hr14.w
mad.f16 hr12.w, hr4.x, hr37.y, (last)hr12.w
mad.f16 hr19.x, hr4.y, hr36.z, (last)hr19.x
mad.f16 hr17.x, hr4.y, hr36.w, (last)hr17.x
(ss)nop
isam.v.base0 (u16)(xyzw)hr31.w, r16.y, s#0, t#0
mad.f16 hr15.x, hr4.y, hr37.x, (last)hr15.x
mad.f16 hr13.x, hr4.y, hr37.y, (last)hr13.x
mad.f16 hr19.y, hr4.z, hr36.z, (last)hr19.y
mad.f16 hr17.y, hr4.z, hr36.w, (last)hr17.y
mad.f16 hr15.y, hr4.z, hr37.x, (last)hr15.y
mad.f16 hr13.y, hr4.z, hr37.y, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr3.w, hr19.z, (r)(last)hr10.z
mad.f16 hr11.x, hr4.y, hr19.z, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr3.w, hr19.w, (r)(last)hr8.z
mad.f16 hr9.x, hr4.y, hr19.w, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr3.w, hr20.x, (r)(last)hr6.z
mad.f16 hr7.x, hr4.y, hr20.x, (last)hr7.x
mad.f16 hr11.y, hr4.z, hr19.z, (last)hr11.y
mad.f16 hr9.y, hr4.z, hr19.w, (last)hr9.y
mad.f16 hr7.y, hr4.z, hr20.x, (last)hr7.y
mad.f16 hr17.z, hr21.x, hr36.z, (last)hr17.z
mad.f16 hr15.z, hr21.x, hr36.w, (last)hr15.z
mad.f16 hr13.z, hr21.x, hr37.x, (last)hr13.z
mad.f16 hr11.z, hr21.x, hr37.y, (last)hr11.z
mad.f16 hr9.z, hr21.x, hr19.z, (last)hr9.z
mad.f16 hr7.z, hr21.x, hr19.w, (last)hr7.z
mad.f16 hr5.z, hr21.x, hr20.x, (last)hr5.z
mad.f16 hr17.w, hr21.y, hr36.z, (last)hr17.w
mad.f16 hr15.w, hr21.y, hr36.w, (last)hr15.w
mad.f16 hr13.w, hr21.y, hr37.x, (last)hr13.w
mad.f16 hr11.w, hr21.y, hr37.y, (last)hr11.w
mad.f16 hr9.w, hr21.y, hr19.z, (last)hr9.w
mad.f16 hr7.w, hr21.y, hr19.w, (last)hr7.w
mad.f16 hr5.w, hr21.y, hr20.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr21.z, hr36.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr21.z, hr36.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr21.z, hr37.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr21.z, hr37.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr21.z, hr19.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr21.z, hr19.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr21.z, hr20.x, (r)(last)hr6.x
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr20.y, (r)(last)hr26.y
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr20.y, (r)(last)hr26.w
ldl.u16 r26.y, l[r10.y+704], 4
(rpt1)mad.f16 hr21.x, (r)(last)hr21.x, hr20.y, (r)(last)hr28.y
(rpt1)mad.f16 hr21.z, (r)(last)hr21.z, hr20.y, (r)(last)hr28.w
ldl.u16 r28.y, l[r10.y+768], 4
isam.v.base0 (u16)(xyzw)hr19.z, r16.z, s#0, t#0
ldl.u16 r30.w, l[r10.y+832], 4
mad.f16 hr18.z, hr23.x, hr22.x, (last)hr18.z
mad.f16 hr16.z, hr23.x, hr22.y, (last)hr16.z
mad.f16 hr14.z, hr23.x, hr22.z, (last)hr14.z
mad.f16 hr12.z, hr23.x, hr22.w, (last)hr12.z
mad.f16 hr18.w, hr23.y, hr22.x, (last)hr18.w
mad.f16 hr16.w, hr23.y, hr22.y, (last)hr16.w
mad.f16 hr14.w, hr23.y, hr22.z, (last)hr14.w
mad.f16 hr12.w, hr23.y, hr22.w, (last)hr12.w
mad.f16 hr19.x, hr23.z, hr22.x, (last)hr19.x
mad.f16 hr17.x, hr23.z, hr22.y, (last)hr17.x
mad.f16 hr15.x, hr23.z, hr22.z, (last)hr15.x
mad.f16 hr13.x, hr23.z, hr22.w, (last)hr13.x
mad.f16 hr19.y, hr23.w, hr22.x, (last)hr19.y
mad.f16 hr17.y, hr23.w, hr22.y, (last)hr17.y
mad.f16 hr15.y, hr23.w, hr22.z, (last)hr15.y
mad.f16 hr13.y, hr23.w, hr22.w, (last)hr13.y
(ss)mad.f16 hr17.z, hr26.y, hr22.x, (last)hr17.z
mad.f16 hr15.z, hr26.y, hr22.y, (last)hr15.z
mad.f16 hr13.z, hr26.y, hr22.z, (last)hr13.z
mad.f16 hr11.z, hr26.y, hr22.w, (last)hr11.z
mad.f16 hr17.w, hr26.z, hr22.x, (last)hr17.w
mad.f16 hr15.w, hr26.z, hr22.y, (last)hr15.w
mad.f16 hr13.w, hr26.z, hr22.z, (last)hr13.w
mad.f16 hr11.w, hr26.z, hr22.w, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr26.w, hr22.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr26.w, hr22.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr26.w, hr22.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr26.w, hr22.w, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr22.x, r16.w, s#0, t#0
(sy)(rpt1)mad.f16 hr10.z, (r)hr23.x, hr24.x, (r)(last)hr10.z
mad.f16 hr11.x, hr23.z, hr24.x, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr23.x, hr24.y, (r)(last)hr8.z
mad.f16 hr9.x, hr23.z, hr24.y, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr23.x, hr24.z, (r)(last)hr6.z
mad.f16 hr7.x, hr23.z, hr24.z, (last)hr7.x
mad.f16 hr11.y, hr23.w, hr24.x, (last)hr11.y
mad.f16 hr9.y, hr23.w, hr24.y, (last)hr9.y
mad.f16 hr7.y, hr23.w, hr24.z, (last)hr7.y
mad.f16 hr9.z, hr26.y, hr24.x, (last)hr9.z
mad.f16 hr7.z, hr26.y, hr24.y, (last)hr7.z
mad.f16 hr5.z, hr26.y, hr24.z, (last)hr5.z
mad.f16 hr9.w, hr26.z, hr24.x, (last)hr9.w
mad.f16 hr7.w, hr26.z, hr24.y, (last)hr7.w
mad.f16 hr5.w, hr26.z, hr24.z, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr26.w, hr24.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr26.w, hr24.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr26.w, hr24.z, (r)(last)hr6.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr24.w, (r)(last)hr3.w
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr24.w, (r)(last)hr4.y
ldl.u16 r3.w, l[r10.y+896], 4
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr24.w, (r)(last)hr21.x
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr24.w, (r)(last)hr21.z
isam.v.base0 (u16)(xyzw)hr24.x, r17.x, s#0, t#0
ldl.u16 r21.x, l[r10.y+960], 4
mad.f16 hr18.z, hr28.y, hr27.y, (last)hr18.z
mad.f16 hr16.z, hr28.y, hr27.z, (last)hr16.z
mad.f16 hr14.z, hr28.y, hr27.w, (last)hr14.z
mad.f16 hr12.z, hr28.y, hr28.x, (last)hr12.z
mad.f16 hr18.w, hr28.z, hr27.y, (last)hr18.w
mad.f16 hr16.w, hr28.z, hr27.z, (last)hr16.w
mad.f16 hr14.w, hr28.z, hr27.w, (last)hr14.w
mad.f16 hr12.w, hr28.z, hr28.x, (last)hr12.w
mad.f16 hr19.x, hr28.w, hr27.y, (last)hr19.x
mad.f16 hr17.x, hr28.w, hr27.z, (last)hr17.x
mad.f16 hr15.x, hr28.w, hr27.w, (last)hr15.x
mad.f16 hr13.x, hr28.w, hr28.x, (last)hr13.x
mad.f16 hr19.y, hr29.x, hr27.y, (last)hr19.y
mad.f16 hr17.y, hr29.x, hr27.z, (last)hr17.y
mad.f16 hr15.y, hr29.x, hr27.w, (last)hr15.y
mad.f16 hr13.y, hr29.x, hr28.x, (last)hr13.y
mad.f16 hr17.z, hr30.w, hr27.y, (last)hr17.z
mad.f16 hr15.z, hr30.w, hr27.z, (last)hr15.z
mad.f16 hr13.z, hr30.w, hr27.w, (last)hr13.z
mad.f16 hr11.z, hr30.w, hr28.x, (last)hr11.z
mad.f16 hr17.w, hr31.x, hr27.y, (last)hr17.w
mad.f16 hr15.w, hr31.x, hr27.z, (last)hr15.w
mad.f16 hr13.w, hr31.x, hr27.w, (last)hr13.w
mad.f16 hr11.w, hr31.x, hr28.x, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr31.y, hr27.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr31.y, hr27.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr31.y, hr27.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr31.y, hr28.x, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr27.y, r17.y, s#0, t#0
(rpt1)mad.f16 hr10.z, (r)hr28.y, hr29.y, (r)(last)hr10.z
mad.f16 hr11.x, hr28.w, hr29.y, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr28.y, hr29.z, (r)(last)hr8.z
mad.f16 hr9.x, hr28.w, hr29.z, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr28.y, hr29.w, (r)(last)hr6.z
mad.f16 hr7.x, hr28.w, hr29.w, (last)hr7.x
mad.f16 hr11.y, hr29.x, hr29.y, (last)hr11.y
mad.f16 hr9.y, hr29.x, hr29.z, (last)hr9.y
mad.f16 hr7.y, hr29.x, hr29.w, (last)hr7.y
mad.f16 hr9.z, hr30.w, hr29.y, (last)hr9.z
mad.f16 hr7.z, hr30.w, hr29.z, (last)hr7.z
mad.f16 hr5.z, hr30.w, hr29.w, (last)hr5.z
mad.f16 hr9.w, hr31.x, hr29.y, (last)hr9.w
mad.f16 hr7.w, hr31.x, hr29.z, (last)hr7.w
mad.f16 hr5.w, hr31.x, hr29.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr31.y, hr29.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr31.y, hr29.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr31.y, hr29.w, (r)(last)hr6.x
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr30.x, (r)(last)hr23.x
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr30.x, (r)(last)hr23.z
ldl.u16 r23.x, l[r10.y+1024], 4
(rpt1)mad.f16 hr30.w, (r)(last)hr30.w, hr30.x, (r)(last)hr26.y
(rpt1)mad.f16 hr31.y, (r)(last)hr31.y, hr30.x, (r)(last)hr26.w
isam.v.base0 (u16)(xyzw)hr29.y, r17.z, s#0, t#0
ldl.u16 r26.y, l[r10.y+1088], 4
(ss)mad.f16 hr18.z, hr3.w, hr31.w, (last)hr18.z
mad.f16 hr16.z, hr3.w, hr32.x, (last)hr16.z
mad.f16 hr14.z, hr3.w, hr32.y, (last)hr14.z
mad.f16 hr12.z, hr3.w, hr32.z, (last)hr12.z
mad.f16 hr18.w, hr4.x, hr31.w, (last)hr18.w
mad.f16 hr16.w, hr4.x, hr32.x, (last)hr16.w
mad.f16 hr14.w, hr4.x, hr32.y, (last)hr14.w
mad.f16 hr12.w, hr4.x, hr32.z, (last)hr12.w
mad.f16 hr19.x, hr4.y, hr31.w, (last)hr19.x
mad.f16 hr17.x, hr4.y, hr32.x, (last)hr17.x
mad.f16 hr15.x, hr4.y, hr32.y, (last)hr15.x
mad.f16 hr13.x, hr4.y, hr32.z, (last)hr13.x
mad.f16 hr19.y, hr4.z, hr31.w, (last)hr19.y
mad.f16 hr17.y, hr4.z, hr32.x, (last)hr17.y
mad.f16 hr15.y, hr4.z, hr32.y, (last)hr15.y
mad.f16 hr13.y, hr4.z, hr32.z, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr3.w, hr19.z, (r)(last)hr10.z
mad.f16 hr11.x, hr4.y, hr19.z, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr3.w, hr19.w, (r)(last)hr8.z
mad.f16 hr9.x, hr4.y, hr19.w, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr3.w, hr20.x, (r)(last)hr6.z
mad.f16 hr7.x, hr4.y, hr20.x, (last)hr7.x
mad.f16 hr11.y, hr4.z, hr19.z, (last)hr11.y
mad.f16 hr9.y, hr4.z, hr19.w, (last)hr9.y
mad.f16 hr7.y, hr4.z, hr20.x, (last)hr7.y
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr20.y, (r)(last)hr28.y
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr20.y, (r)(last)hr28.w
ldl.u16 r28.y, l[r10.y+1152], 4
mad.f16 hr17.z, hr21.x, hr31.w, (last)hr17.z
mad.f16 hr15.z, hr21.x, hr32.x, (last)hr15.z
mad.f16 hr13.z, hr21.x, hr32.y, (last)hr13.z
mad.f16 hr11.z, hr21.x, hr32.z, (last)hr11.z
mad.f16 hr17.w, hr21.y, hr31.w, (last)hr17.w
mad.f16 hr15.w, hr21.y, hr32.x, (last)hr15.w
mad.f16 hr13.w, hr21.y, hr32.y, (last)hr13.w
mad.f16 hr11.w, hr21.y, hr32.z, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr21.z, hr31.w, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr21.z, hr32.x, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr21.z, hr32.y, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr21.z, hr32.z, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr31.w, r17.w, s#0, t#0
isam.v.base0 (u16)(xyzw)hr33.w, r18.x, s#0, t#0
(ss)nop
isam.v.base0 (u16)(xyzw)hr36.x, r18.w, s#0, t#0
mad.f16 hr9.z, hr21.x, hr19.z, (last)hr9.z
mad.f16 hr7.z, hr21.x, hr19.w, (last)hr7.z
mad.f16 hr5.z, hr21.x, hr20.x, (last)hr5.z
mad.f16 hr9.w, hr21.y, hr19.z, (last)hr9.w
mad.f16 hr7.w, hr21.y, hr19.w, (last)hr7.w
mad.f16 hr5.w, hr21.y, hr20.x, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr21.z, hr19.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr21.z, hr19.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr21.z, hr20.x, (r)(last)hr6.x
(rpt1)mad.f16 hr21.x, (r)(last)hr21.x, hr20.y, (r)(last)hr30.w
(rpt1)mad.f16 hr21.z, (r)(last)hr21.z, hr20.y, (r)(last)hr31.y
ldl.u16 r30.w, l[r10.y+1216], 4
ldl.u16 r32.w, l[r10.y+1280], 4
ldl.u16 r35.x, l[r10.y+1344], 4
mad.f16 hr18.z, hr23.x, hr22.x, (last)hr18.z
mad.f16 hr16.z, hr23.x, hr22.y, (last)hr16.z
mad.f16 hr14.z, hr23.x, hr22.z, (last)hr14.z
mad.f16 hr12.z, hr23.x, hr22.w, (last)hr12.z
mad.f16 hr18.w, hr23.y, hr22.x, (last)hr18.w
mad.f16 hr16.w, hr23.y, hr22.y, (last)hr16.w
mad.f16 hr14.w, hr23.y, hr22.z, (last)hr14.w
mad.f16 hr12.w, hr23.y, hr22.w, (last)hr12.w
mad.f16 hr19.x, hr23.z, hr22.x, (last)hr19.x
mad.f16 hr17.x, hr23.z, hr22.y, (last)hr17.x
(ss)nop
ldl.u16 r37.x, l[r10.y+1408], 4
mad.f16 hr15.x, hr23.z, hr22.z, (last)hr15.x
mad.f16 hr13.x, hr23.z, hr22.w, (last)hr13.x
mad.f16 hr19.y, hr23.w, hr22.x, (last)hr19.y
mad.f16 hr17.y, hr23.w, hr22.y, (last)hr17.y
mad.f16 hr15.y, hr23.w, hr22.z, (last)hr15.y
mad.f16 hr13.y, hr23.w, hr22.w, (last)hr13.y
mad.f16 hr17.z, hr26.y, hr22.x, (last)hr17.z
mad.f16 hr15.z, hr26.y, hr22.y, (last)hr15.z
mad.f16 hr13.z, hr26.y, hr22.z, (last)hr13.z
(sy)(rpt1)mad.f16 hr10.z, (r)hr23.x, hr24.x, (r)(last)hr10.z
mad.f16 hr11.x, hr23.z, hr24.x, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr23.x, hr24.y, (r)(last)hr8.z
mad.f16 hr9.x, hr23.z, hr24.y, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr23.x, hr24.z, (r)(last)hr6.z
mad.f16 hr7.x, hr23.z, hr24.z, (last)hr7.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr24.w, (r)(last)hr3.w
mad.f16 hr23.z, (last)hr23.z, hr24.w, (last)hr4.y
isam.v.base0 (u16)(xyzw)hr3.z, r19.x, s#0, t#0
mad.f16 hr11.y, hr23.w, hr24.x, (last)hr11.y
mad.f16 hr9.y, hr23.w, hr24.y, (last)hr9.y
mad.f16 hr7.y, hr23.w, hr24.z, (last)hr7.y
mad.f16 hr11.z, hr26.y, hr22.w, (last)hr11.z
mad.f16 hr17.w, hr26.z, hr22.x, (last)hr17.w
mad.f16 hr15.w, hr26.z, hr22.y, (last)hr15.w
mad.f16 hr13.w, hr26.z, hr22.z, (last)hr13.w
mad.f16 hr11.w, hr26.z, hr22.w, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr26.w, hr22.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr26.w, hr22.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr26.w, hr22.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr26.w, hr22.w, (r)(last)hr12.x
mad.f16 hr9.z, hr26.y, hr24.x, (last)hr9.z
mad.f16 hr7.z, hr26.y, hr24.y, (last)hr7.z
mad.f16 hr5.z, hr26.y, hr24.z, (last)hr5.z
mad.f16 hr9.w, hr26.z, hr24.x, (last)hr9.w
mad.f16 hr7.w, hr26.z, hr24.y, (last)hr7.w
mad.f16 hr5.w, hr26.z, hr24.z, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr26.w, hr24.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr26.w, hr24.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr26.w, hr24.z, (r)(last)hr6.x
mad.f16 hr18.z, hr28.y, hr27.y, (last)hr18.z
mad.f16 hr16.z, hr28.y, hr27.z, (last)hr16.z
mad.f16 hr14.z, hr28.y, hr27.w, (last)hr14.z
mad.f16 hr12.z, hr28.y, hr28.x, (last)hr12.z
mad.f16 hr10.z, hr28.y, hr29.y, (last)hr10.z
mad.f16 hr8.z, hr28.y, hr29.z, (last)hr8.z
mad.f16 hr6.z, hr28.y, hr29.w, (last)hr6.z
mad.f16 hr23.w, (last)hr23.w, hr24.w, (last)hr4.z
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr24.w, (r)(last)hr21.x
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr24.w, (r)(last)hr21.z
ldl.u16 r21.y, l[r10.y+1472], 4
mad.f16 hr28.y, (last)hr28.y, hr30.x, (last)hr23.x
isam.v.base0 (u16)(xyzw)hr22.y, r19.y, s#0, t#0
isam.v.base0 (u16)(xyzw)hr24.y, r19.z, s#0, t#0
mad.f16 hr18.w, hr28.z, hr27.y, (last)hr18.w
mad.f16 hr16.w, hr28.z, hr27.z, (last)hr16.w
mad.f16 hr14.w, hr28.z, hr27.w, (last)hr14.w
mad.f16 hr12.w, hr28.z, hr28.x, (last)hr12.w
mad.f16 hr19.x, hr28.w, hr27.y, (last)hr19.x
mad.f16 hr17.x, hr28.w, hr27.z, (last)hr17.x
mad.f16 hr15.x, hr28.w, hr27.w, (last)hr15.x
mad.f16 hr13.x, hr28.w, hr28.x, (last)hr13.x
mad.f16 hr19.y, hr29.x, hr27.y, (last)hr19.y
mad.f16 hr17.y, hr29.x, hr27.z, (last)hr17.y
mad.f16 hr15.y, hr29.x, hr27.w, (last)hr15.y
mad.f16 hr13.y, hr29.x, hr28.x, (last)hr13.y
mad.f16 hr10.w, hr28.z, hr29.y, (last)hr10.w
mad.f16 hr11.x, hr28.w, hr29.y, (last)hr11.x
mad.f16 hr8.w, hr28.z, hr29.z, (last)hr8.w
mad.f16 hr9.x, hr28.w, hr29.z, (last)hr9.x
mad.f16 hr6.w, hr28.z, hr29.w, (last)hr6.w
mad.f16 hr7.x, hr28.w, hr29.w, (last)hr7.x
mad.f16 hr11.y, hr29.x, hr29.y, (last)hr11.y
mad.f16 hr9.y, hr29.x, hr29.z, (last)hr9.y
mad.f16 hr7.y, hr29.x, hr29.w, (last)hr7.y
mad.f16 hr28.z, (last)hr28.z, hr30.x, (last)hr23.y
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr30.x, (r)(last)hr23.z
ldl.u16 r23.y, l[r10.y+1536], 4
mad.f16 hr17.z, hr30.w, hr27.y, (last)hr17.z
mad.f16 hr15.z, hr30.w, hr27.z, (last)hr15.z
mad.f16 hr13.z, hr30.w, hr27.w, (last)hr13.z
mad.f16 hr17.w, hr31.x, hr27.y, (last)hr17.w
mad.f16 hr15.w, hr31.x, hr27.z, (last)hr15.w
mad.f16 hr13.w, hr31.x, hr27.w, (last)hr13.w
(rpt1)mad.f16 hr18.x, (r)hr31.y, hr27.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr31.y, hr27.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr31.y, hr27.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr31.y, hr28.x, (r)(last)hr12.x
mad.f16 hr9.z, hr30.w, hr29.y, (last)hr9.z
mad.f16 hr7.z, hr30.w, hr29.z, (last)hr7.z
mad.f16 hr5.z, hr30.w, hr29.w, (last)hr5.z
mad.f16 hr9.w, hr31.x, hr29.y, (last)hr9.w
mad.f16 hr7.w, hr31.x, hr29.z, (last)hr7.w
mad.f16 hr5.w, hr31.x, hr29.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr31.y, hr29.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr31.y, hr29.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr31.y, hr29.w, (r)(last)hr6.x
mad.f16 hr19.x, hr33.y, hr31.w, (last)hr19.x
mad.f16 hr17.x, hr33.y, hr32.x, (last)hr17.x
mad.f16 hr15.x, hr33.y, hr32.y, (last)hr15.x
mad.f16 hr13.x, hr33.y, hr32.z, (last)hr13.x
mad.f16 hr19.y, hr33.z, hr31.w, (last)hr19.y
mad.f16 hr17.y, hr33.z, hr32.x, (last)hr17.y
mad.f16 hr15.y, hr33.z, hr32.y, (last)hr15.y
mad.f16 hr13.y, hr33.z, hr32.z, (last)hr13.y
mad.f16 hr11.x, hr33.y, hr33.w, (last)hr11.x
mad.f16 hr9.x, hr33.y, hr34.x, (last)hr9.x
mad.f16 hr7.x, hr33.y, hr34.y, (last)hr7.x
mad.f16 hr11.y, hr33.z, hr33.w, (last)hr11.y
mad.f16 hr9.y, hr33.z, hr34.x, (last)hr9.y
mad.f16 hr7.y, hr33.z, hr34.y, (last)hr7.y
(rpt1)mad.f16 hr31.y, (r)(last)hr31.y, hr30.x, (r)(last)hr26.w
isam.v.base0 (u16)(xyzw)hr27.x, r19.w, s#0, t#0
(rpt1)mad.f16 hr33.y, (r)(last)hr33.y, hr34.z, (r)(last)hr28.w
isam.v.base0 (u16)(xyzw)hr29.x, r20.x, s#0, t#0
(rpt1)mad.f16 hr11.z, (r)hr30.w, hr28.x, (r)(last)hr11.z
mad.f16 hr18.z, hr32.w, hr31.w, (last)hr18.z
mad.f16 hr16.z, hr32.w, hr32.x, (last)hr16.z
mad.f16 hr14.z, hr32.w, hr32.y, (last)hr14.z
mad.f16 hr12.z, hr32.w, hr32.z, (last)hr12.z
mad.f16 hr10.z, hr32.w, hr33.w, (last)hr10.z
mad.f16 hr8.z, hr32.w, hr34.x, (last)hr8.z
mad.f16 hr6.z, hr32.w, hr34.y, (last)hr6.z
mad.f16 hr18.w, hr33.x, hr31.w, (last)hr18.w
mad.f16 hr16.w, hr33.x, hr32.x, (last)hr16.w
mad.f16 hr14.w, hr33.x, hr32.y, (last)hr14.w
mad.f16 hr12.w, hr33.x, hr32.z, (last)hr12.w
mad.f16 hr10.w, hr33.x, hr33.w, (last)hr10.w
mad.f16 hr8.w, hr33.x, hr34.x, (last)hr8.w
mad.f16 hr6.w, hr33.x, hr34.y, (last)hr6.w
mad.f16 hr17.z, hr35.x, hr31.w, (last)hr17.z
mad.f16 hr15.z, hr35.x, hr32.x, (last)hr15.z
mad.f16 hr13.z, hr35.x, hr32.y, (last)hr13.z
mad.f16 hr17.w, hr35.y, hr31.w, (last)hr17.w
mad.f16 hr15.w, hr35.y, hr32.x, (last)hr15.w
mad.f16 hr13.w, hr35.y, hr32.y, (last)hr13.w
(rpt1)mad.f16 hr18.x, (r)hr35.z, hr31.w, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr35.z, hr32.x, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr35.z, hr32.y, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr35.z, hr32.z, (r)(last)hr12.x
mad.f16 hr9.z, hr35.x, hr33.w, (last)hr9.z
mad.f16 hr7.z, hr35.x, hr34.x, (last)hr7.z
mad.f16 hr9.w, hr35.y, hr33.w, (last)hr9.w
mad.f16 hr7.w, hr35.y, hr34.x, (last)hr7.w
(rpt1)mad.f16 hr10.x, (r)hr35.z, hr33.w, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr35.z, hr34.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr35.z, hr34.y, (r)(last)hr6.x
(ss)mad.f16 hr19.x, hr37.z, hr36.x, (last)hr19.x
mad.f16 hr17.x, hr37.z, hr36.y, (last)hr17.x
mad.f16 hr15.x, hr37.z, hr36.z, (last)hr15.x
mad.f16 hr13.x, hr37.z, hr36.w, (last)hr13.x
mad.f16 hr19.y, hr37.w, hr36.x, (last)hr19.y
mad.f16 hr17.y, hr37.w, hr36.y, (last)hr17.y
mad.f16 hr15.y, hr37.w, hr36.z, (last)hr15.y
mad.f16 hr13.y, hr37.w, hr36.w, (last)hr13.y
(sy)mad.f16 hr11.x, hr37.z, hr3.z, (last)hr11.x
mad.f16 hr9.x, hr37.z, hr3.w, (last)hr9.x
mad.f16 hr7.x, hr37.z, hr4.x, (last)hr7.x
mad.f16 hr11.y, hr37.w, hr3.z, (last)hr11.y
mad.f16 hr9.y, hr37.w, hr3.w, (last)hr9.y
mad.f16 hr7.y, hr37.w, hr4.x, (last)hr7.y
(rpt1)mad.f16 hr30.w, (r)(last)hr30.w, hr30.x, (r)(last)hr26.y
ldl.u16 r26.x, l[r10.y+1600], 4
(rpt1)mad.f16 hr32.w, (r)(last)hr32.w, hr34.z, (r)(last)hr28.y
ldl.u16 r28.x, l[r10.y+1664], 4
(rpt1)mad.f16 hr35.z, (r)(last)hr35.z, hr34.z, (r)(last)hr31.y
isam.v.base0 (u16)(xyzw)hr31.y, r20.y, s#0, t#0
(rpt1)mad.f16 hr37.z, (r)(last)hr37.z, hr4.y, (r)(last)hr33.y
isam.v.base0 (u16)(xyzw)hr33.y, r20.z, s#0, t#0
mad.f16 hr18.z, hr37.x, hr36.x, (last)hr18.z
mad.f16 hr16.z, hr37.x, hr36.y, (last)hr16.z
mad.f16 hr14.z, hr37.x, hr36.z, (last)hr14.z
mad.f16 hr18.w, hr37.y, hr36.x, (last)hr18.w
mad.f16 hr16.w, hr37.y, hr36.y, (last)hr16.w
mad.f16 hr14.w, hr37.y, hr36.z, (last)hr14.w
mad.f16 hr17.z, hr21.y, hr36.x, (last)hr17.z
mad.f16 hr15.z, hr21.y, hr36.y, (last)hr15.z
mad.f16 hr13.z, hr21.y, hr36.z, (last)hr13.z
mad.f16 hr17.w, hr21.z, hr36.x, (last)hr17.w
mad.f16 hr15.w, hr21.z, hr36.y, (last)hr15.w
mad.f16 hr13.w, hr21.z, hr36.z, (last)hr13.w
(rpt1)mad.f16 hr18.x, (r)hr21.w, hr36.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr21.w, hr36.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr21.w, hr36.z, (r)(last)hr14.x
mad.f16 hr12.y, hr22.x, hr36.w, (last)hr12.y
mad.f16 hr10.y, hr22.x, hr3.z, (last)hr10.y
mad.f16 hr8.y, hr22.x, hr3.w, (last)hr8.y
mad.f16 hr6.y, hr22.x, hr4.x, (last)hr6.y
mad.f16 hr19.y, hr24.x, hr22.y, (last)hr19.y
mad.f16 hr17.y, hr24.x, hr22.z, (last)hr17.y
mad.f16 hr15.y, hr24.x, hr22.w, (last)hr15.y
mad.f16 hr13.y, hr24.x, hr23.x, (last)hr13.y
mad.f16 hr11.y, hr24.x, hr24.y, (last)hr11.y
mad.f16 hr9.y, hr24.x, hr24.z, (last)hr9.y
mad.f16 hr7.y, hr24.x, hr24.w, (last)hr7.y
mad.f16 hr22.x, (last)hr22.x, hr4.y, (last)hr35.w
isam.v.base0 (u16)(xyzw)hr35.w, r0.y, s#0, t#0
mad.f16 hr24.x, (last)hr24.x, hr25.x, (last)hr37.w
isam.v.base0 (u16)(xyzw)hr37.w, r0.z, s#0, t#0
(rpt1)mad.f16 hr5.z, (r)hr35.x, hr34.y, (r)(last)hr5.z
(rpt1)mad.f16 hr11.z, (r)hr35.x, hr32.z, (r)(last)hr11.z
mad.f16 hr12.z, hr37.x, hr36.w, (last)hr12.z
mad.f16 hr10.z, hr37.x, hr3.z, (last)hr10.z
mad.f16 hr8.z, hr37.x, hr3.w, (last)hr8.z
mad.f16 hr6.z, hr37.x, hr4.x, (last)hr6.z
mad.f16 hr12.w, hr37.y, hr36.w, (last)hr12.w
mad.f16 hr10.w, hr37.y, hr3.z, (last)hr10.w
mad.f16 hr8.w, hr37.y, hr3.w, (last)hr8.w
mad.f16 hr6.w, hr37.y, hr4.x, (last)hr6.w
(rpt1)mad.f16 hr35.x, (r)(last)hr35.x, hr34.z, (r)(last)hr30.w
ldl.u16 r30.y, l[r10.y+1728], 4
(rpt1)mad.f16 hr37.x, (r)(last)hr37.x, hr4.y, (r)(last)hr32.w
ldl.u16 r32.y, l[r10.y+1792], 4
mad.f16 hr12.x, hr21.w, hr36.w, (last)hr12.x
mad.f16 hr9.z, hr21.y, hr3.z, (last)hr9.z
mad.f16 hr7.z, hr21.y, hr3.w, (last)hr7.z
mad.f16 hr9.w, hr21.z, hr3.z, (last)hr9.w
mad.f16 hr7.w, hr21.z, hr3.w, (last)hr7.w
mad.f16 hr10.x, hr21.w, hr3.z, (last)hr10.x
mad.f16 hr8.x, hr21.w, hr3.w, (last)hr8.x
mad.f16 hr6.x, hr21.w, hr4.x, (last)hr6.x
mad.f16 hr19.x, hr23.w, hr22.y, (last)hr19.x
mad.f16 hr17.x, hr23.w, hr22.z, (last)hr17.x
mad.f16 hr15.x, hr23.w, hr22.w, (last)hr15.x
mad.f16 hr13.x, hr23.w, hr23.x, (last)hr13.x
mad.f16 hr11.x, hr23.w, hr24.y, (last)hr11.x
mad.f16 hr9.x, hr23.w, hr24.z, (last)hr9.x
mad.f16 hr7.x, hr23.w, hr24.w, (last)hr7.x
mad.f16 hr18.z, hr23.y, hr22.y, (last)hr18.z
mad.f16 hr16.z, hr23.y, hr22.z, (last)hr16.z
mad.f16 hr14.z, hr23.y, hr22.w, (last)hr14.z
mad.f16 hr18.w, hr23.z, hr22.y, (last)hr18.w
mad.f16 hr16.w, hr23.z, hr22.z, (last)hr16.w
mad.f16 hr14.w, hr23.z, hr22.w, (last)hr14.w
(rpt1)mad.f16 hr5.z, (r)hr21.y, hr4.x, (r)(last)hr5.z
(rpt1)mad.f16 hr11.z, (r)hr21.y, hr36.w, (r)(last)hr11.z
mad.f16 hr12.z, hr23.y, hr23.x, (last)hr12.z
mad.f16 hr10.z, hr23.y, hr24.y, (last)hr10.z
mad.f16 hr8.z, hr23.y, hr24.z, (last)hr8.z
mad.f16 hr6.z, hr23.y, hr24.w, (last)hr6.z
mad.f16 hr12.w, hr23.z, hr23.x, (last)hr12.w
mad.f16 hr10.w, hr23.z, hr24.y, (last)hr10.w
mad.f16 hr8.w, hr23.z, hr24.z, (last)hr8.w
mad.f16 hr6.w, hr23.z, hr24.w, (last)hr6.w
mad.f16 hr21.w, (last)hr21.w, hr4.y, (last)hr35.z
mad.f16 hr23.w, (last)hr23.w, hr25.x, (last)hr37.z
(rpt1)mad.f16 hr21.y, (r)(last)hr21.y, hr4.y, (r)(last)hr35.x
ldl.u16 r34.w, l[r10.y+1856], 4
(rpt1)mad.f16 hr23.y, (r)(last)hr23.y, hr25.x, (r)(last)hr37.x
ldl.u16 r36.w, l[r10.y+1920], 4
ldl.u16 r39.x, l[r10.y+1984], 4
fence.r.w
(sy)(ss)mad.f16 hr17.z, hr26.x, hr22.y, (last)hr17.z
mad.f16 hr15.z, hr26.x, hr22.z, (last)hr15.z
mad.f16 hr13.z, hr26.x, hr22.w, (last)hr13.z
mad.f16 hr17.w, hr26.y, hr22.y, (last)hr17.w
mad.f16 hr15.w, hr26.y, hr22.z, (last)hr15.w
mad.f16 hr13.w, hr26.y, hr22.w, (last)hr13.w
(rpt1)mad.f16 hr18.x, (r)hr26.z, hr22.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr26.z, hr22.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr26.z, hr22.w, (r)(last)hr14.x
mad.f16 hr12.y, hr26.w, hr23.x, (last)hr12.y
mad.f16 hr10.y, hr26.w, hr24.y, (last)hr10.y
mad.f16 hr8.y, hr26.w, hr24.z, (last)hr8.y
mad.f16 hr6.y, hr26.w, hr24.w, (last)hr6.y
mad.f16 hr12.x, hr26.z, hr23.x, (last)hr12.x
mad.f16 hr9.z, hr26.x, hr24.y, (last)hr9.z
mad.f16 hr7.z, hr26.x, hr24.z, (last)hr7.z
mad.f16 hr9.w, hr26.y, hr24.y, (last)hr9.w
mad.f16 hr7.w, hr26.y, hr24.z, (last)hr7.w
mad.f16 hr10.x, hr26.z, hr24.y, (last)hr10.x
mad.f16 hr8.x, hr26.z, hr24.z, (last)hr8.x
mad.f16 hr6.x, hr26.z, hr24.w, (last)hr6.x
(rpt1)mad.f16 hr5.z, (r)hr26.x, hr24.w, (r)(last)hr5.z
(rpt1)mad.f16 hr11.z, (r)hr26.x, hr23.x, (r)(last)hr11.z
mad.f16 hr26.w, (last)hr26.w, hr25.x, (last)hr22.x
mad.f16 hr26.z, (last)hr26.z, hr25.x, (last)hr21.w
(rpt1)mad.f16 hr26.x, (r)(last)hr26.x, hr25.x, (r)(last)hr21.y
mad.f16 hr19.y, hr28.w, hr27.x, (last)hr19.y
mad.f16 hr17.y, hr28.w, hr27.y, (last)hr17.y
mad.f16 hr15.y, hr28.w, hr27.z, (last)hr15.y
mad.f16 hr13.y, hr28.w, hr27.w, (last)hr13.y
mad.f16 hr11.y, hr28.w, hr29.x, (last)hr11.y
mad.f16 hr9.y, hr28.w, hr29.y, (last)hr9.y
mad.f16 hr7.y, hr28.w, hr29.z, (last)hr7.y
mad.f16 hr19.x, hr28.z, hr27.x, (last)hr19.x
mad.f16 hr17.x, hr28.z, hr27.y, (last)hr17.x
mad.f16 hr15.x, hr28.z, hr27.z, (last)hr15.x
mad.f16 hr13.x, hr28.z, hr27.w, (last)hr13.x
mad.f16 hr11.x, hr28.z, hr29.x, (last)hr11.x
mad.f16 hr9.x, hr28.z, hr29.y, (last)hr9.x
mad.f16 hr7.x, hr28.z, hr29.z, (last)hr7.x
mad.f16 hr18.z, hr28.x, hr27.x, (last)hr18.z
mad.f16 hr16.z, hr28.x, hr27.y, (last)hr16.z
mad.f16 hr14.z, hr28.x, hr27.z, (last)hr14.z
mad.f16 hr18.w, hr28.y, hr27.x, (last)hr18.w
mad.f16 hr16.w, hr28.y, hr27.y, (last)hr16.w
mad.f16 hr14.w, hr28.y, hr27.z, (last)hr14.w
mad.f16 hr12.z, hr28.x, hr27.w, (last)hr12.z
mad.f16 hr10.z, hr28.x, hr29.x, (last)hr10.z
mad.f16 hr8.z, hr28.x, hr29.y, (last)hr8.z
mad.f16 hr6.z, hr28.x, hr29.z, (last)hr6.z
mad.f16 hr12.w, hr28.y, hr27.w, (last)hr12.w
mad.f16 hr10.w, hr28.y, hr29.x, (last)hr10.w
mad.f16 hr8.w, hr28.y, hr29.y, (last)hr8.w
mad.f16 hr6.w, hr28.y, hr29.z, (last)hr6.w
mad.f16 hr17.z, hr30.y, hr27.x, (last)hr17.z
mad.f16 hr15.z, hr30.y, hr27.y, (last)hr15.z
mad.f16 hr13.z, hr30.y, hr27.z, (last)hr13.z
mad.f16 hr17.w, hr30.z, hr27.x, (last)hr17.w
mad.f16 hr15.w, hr30.z, hr27.y, (last)hr15.w
mad.f16 hr13.w, hr30.z, hr27.z, (last)hr13.w
(rpt1)mad.f16 hr18.x, (r)hr30.w, hr27.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr30.w, hr27.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr30.w, hr27.z, (r)(last)hr14.x
mad.f16 hr12.y, hr31.x, hr27.w, (last)hr12.y
mad.f16 hr10.y, hr31.x, hr29.x, (last)hr10.y
mad.f16 hr8.y, hr31.x, hr29.y, (last)hr8.y
mad.f16 hr6.y, hr31.x, hr29.z, (last)hr6.y
mad.f16 hr12.x, hr30.w, hr27.w, (last)hr12.x
mad.f16 hr9.z, hr30.y, hr29.x, (last)hr9.z
mad.f16 hr7.z, hr30.y, hr29.y, (last)hr7.z
mad.f16 hr9.w, hr30.z, hr29.x, (last)hr9.w
mad.f16 hr7.w, hr30.z, hr29.y, (last)hr7.w
mad.f16 hr10.x, hr30.w, hr29.x, (last)hr10.x
mad.f16 hr8.x, hr30.w, hr29.y, (last)hr8.x
mad.f16 hr6.x, hr30.w, hr29.z, (last)hr6.x
(rpt1)mad.f16 hr5.z, (r)hr30.y, hr29.z, (r)(last)hr5.z
(rpt1)mad.f16 hr11.z, (r)hr30.y, hr27.w, (r)(last)hr11.z
mad.f16 hr28.w, (last)hr28.w, hr29.w, (last)hr24.x
mad.f16 hr28.z, (last)hr28.z, hr29.w, (last)hr23.w
(rpt1)mad.f16 hr28.x, (r)(last)hr28.x, hr29.w, (r)(last)hr23.y
mad.f16 hr31.x, (last)hr31.x, hr29.w, (last)hr26.w
mad.f16 hr30.w, (last)hr30.w, hr29.w, (last)hr26.z
(rpt1)mad.f16 hr30.y, (r)(last)hr30.y, hr29.w, (r)(last)hr26.x
mad.f16 hr19.y, hr33.x, hr31.y, (last)hr19.y
mad.f16 hr17.y, hr33.x, hr31.z, (last)hr17.y
mad.f16 hr15.y, hr33.x, hr31.w, (last)hr15.y
mad.f16 hr13.y, hr33.x, hr32.x, (last)hr13.y
mad.f16 hr11.y, hr33.x, hr33.y, (last)hr11.y
mad.f16 hr9.y, hr33.x, hr33.z, (last)hr9.y
mad.f16 hr7.y, hr33.x, hr33.w, (last)hr7.y
mad.f16 hr19.x, hr32.w, hr31.y, (last)hr19.x
mad.f16 hr17.x, hr32.w, hr31.z, (last)hr17.x
mad.f16 hr15.x, hr32.w, hr31.w, (last)hr15.x
mad.f16 hr13.x, hr32.w, hr32.x, (last)hr13.x
mad.f16 hr11.x, hr32.w, hr33.y, (last)hr11.x
mad.f16 hr9.x, hr32.w, hr33.z, (last)hr9.x
mad.f16 hr7.x, hr32.w, hr33.w, (last)hr7.x
mad.f16 hr18.z, hr32.y, hr31.y, (last)hr18.z
mad.f16 hr16.z, hr32.y, hr31.z, (last)hr16.z
mad.f16 hr14.z, hr32.y, hr31.w, (last)hr14.z
mad.f16 hr18.w, hr32.z, hr31.y, (last)hr18.w
mad.f16 hr16.w, hr32.z, hr31.z, (last)hr16.w
mad.f16 hr14.w, hr32.z, hr31.w, (last)hr14.w
mad.f16 hr12.z, hr32.y, hr32.x, (last)hr12.z
mad.f16 hr10.z, hr32.y, hr33.y, (last)hr10.z
mad.f16 hr8.z, hr32.y, hr33.z, (last)hr8.z
mad.f16 hr6.z, hr32.y, hr33.w, (last)hr6.z
mad.f16 hr12.w, hr32.z, hr32.x, (last)hr12.w
mad.f16 hr10.w, hr32.z, hr33.y, (last)hr10.w
mad.f16 hr8.w, hr32.z, hr33.z, (last)hr8.w
mad.f16 hr6.w, hr32.z, hr33.w, (last)hr6.w
mad.f16 hr17.z, hr34.w, hr31.y, (last)hr17.z
mad.f16 hr15.z, hr34.w, hr31.z, (last)hr15.z
mad.f16 hr13.z, hr34.w, hr31.w, (last)hr13.z
mad.f16 hr17.w, hr35.x, hr31.y, (last)hr17.w
mad.f16 hr15.w, hr35.x, hr31.z, (last)hr15.w
mad.f16 hr13.w, hr35.x, hr31.w, (last)hr13.w
(rpt1)mad.f16 hr18.x, (r)hr35.y, hr31.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr35.y, hr31.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr35.y, hr31.w, (r)(last)hr14.x
mad.f16 hr12.y, hr35.z, hr32.x, (last)hr12.y
mad.f16 hr10.y, hr35.z, hr33.y, (last)hr10.y
mad.f16 hr8.y, hr35.z, hr33.z, (last)hr8.y
mad.f16 hr6.y, hr35.z, hr33.w, (last)hr6.y
mad.f16 hr12.x, hr35.y, hr32.x, (last)hr12.x
mad.f16 hr9.z, hr34.w, hr33.y, (last)hr9.z
mad.f16 hr7.z, hr34.w, hr33.z, (last)hr7.z
mad.f16 hr9.w, hr35.x, hr33.y, (last)hr9.w
mad.f16 hr7.w, hr35.x, hr33.z, (last)hr7.w
mad.f16 hr10.x, hr35.y, hr33.y, (last)hr10.x
mad.f16 hr8.x, hr35.y, hr33.z, (last)hr8.x
mad.f16 hr6.x, hr35.y, hr33.w, (last)hr6.x
(rpt1)mad.f16 hr5.z, (r)hr34.w, hr33.w, (r)(last)hr5.z
(rpt1)mad.f16 hr11.z, (r)hr34.w, hr32.x, (r)(last)hr11.z
mad.f16 hr33.x, (last)hr33.x, hr34.x, (last)hr28.w
mad.f16 hr32.w, (last)hr32.w, hr34.x, (last)hr28.z
(rpt1)mad.f16 hr32.y, (r)(last)hr32.y, hr34.x, (r)(last)hr28.x
mad.f16 hr35.z, (last)hr35.z, hr34.x, (last)hr31.x
mad.f16 hr35.y, (last)hr35.y, hr34.x, (last)hr30.w
(rpt1)mad.f16 hr34.w, (r)(last)hr34.w, hr34.x, (r)(last)hr30.y
bar.g
(sy)(ss)mad.f16 hr19.y, hr37.z, hr35.w, (last)hr19.y
mad.f16 hr17.y, hr37.z, hr36.x, (last)hr17.y
mad.f16 hr15.y, hr37.z, hr36.y, (last)hr15.y
mad.f16 hr13.y, hr37.z, hr36.z, (last)hr13.y
mad.f16 hr11.y, hr37.z, hr37.w, (last)hr11.y
mad.f16 hr9.y, hr37.z, hr38.x, (last)hr9.y
mad.f16 hr7.y, hr37.z, hr38.y, (last)hr7.y
mad.f16 hr19.x, hr37.y, hr35.w, (last)hr19.x
mad.f16 hr17.x, hr37.y, hr36.x, (last)hr17.x
mad.f16 hr15.x, hr37.y, hr36.y, (last)hr15.x
mad.f16 hr13.x, hr37.y, hr36.z, (last)hr13.x
mad.f16 hr11.x, hr37.y, hr37.w, (last)hr11.x
mad.f16 hr9.x, hr37.y, hr38.x, (last)hr9.x
mad.f16 hr7.x, hr37.y, hr38.y, (last)hr7.x
mad.f16 hr18.z, hr36.w, hr35.w, (last)hr18.z
mad.f16 hr16.z, hr36.w, hr36.x, (last)hr16.z
mad.f16 hr14.z, hr36.w, hr36.y, (last)hr14.z
mad.f16 hr18.w, hr37.x, hr35.w, (last)hr18.w
mad.f16 hr16.w, hr37.x, hr36.x, (last)hr16.w
mad.f16 hr14.w, hr37.x, hr36.y, (last)hr14.w
mad.f16 hr12.z, hr36.w, hr36.z, (last)hr12.z
mad.f16 hr10.z, hr36.w, hr37.w, (last)hr10.z
mad.f16 hr8.z, hr36.w, hr38.x, (last)hr8.z
mad.f16 hr6.z, hr36.w, hr38.y, (last)hr6.z
mad.f16 hr12.w, hr37.x, hr36.z, (last)hr12.w
mad.f16 hr10.w, hr37.x, hr37.w, (last)hr10.w
mad.f16 hr8.w, hr37.x, hr38.x, (last)hr8.w
mad.f16 hr6.w, hr37.x, hr38.y, (last)hr6.w
mad.f16 hr17.z, hr39.x, hr35.w, (last)hr17.z
mad.f16 hr15.z, hr39.x, hr36.x, (last)hr15.z
mad.f16 hr13.z, hr39.x, hr36.y, (last)hr13.z
mad.f16 hr17.w, hr39.y, hr35.w, (last)hr17.w
mad.f16 hr15.w, hr39.y, hr36.x, (last)hr15.w
mad.f16 hr13.w, hr39.y, hr36.y, (last)hr13.w
(rpt1)mad.f16 hr18.x, (r)hr39.z, hr35.w, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr39.z, hr36.x, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr39.z, hr36.y, (r)(last)hr14.x
mad.f16 hr12.y, hr39.w, hr36.z, (last)hr12.y
mad.f16 hr10.y, hr39.w, hr37.w, (last)hr10.y
mad.f16 hr8.y, hr39.w, hr38.x, (last)hr8.y
mad.f16 hr6.y, hr39.w, hr38.y, (last)hr6.y
mad.f16 hr12.x, hr39.z, hr36.z, (last)hr12.x
mad.f16 hr9.z, hr39.x, hr37.w, (last)hr9.z
mad.f16 hr7.z, hr39.x, hr38.x, (last)hr7.z
mad.f16 hr9.w, hr39.y, hr37.w, (last)hr9.w
mad.f16 hr7.w, hr39.y, hr38.x, (last)hr7.w
mad.f16 hr10.x, hr39.z, hr37.w, (last)hr10.x
mad.f16 hr8.x, hr39.z, hr38.x, (last)hr8.x
mad.f16 hr6.x, hr39.z, hr38.y, (last)hr6.x
(rpt1)mad.f16 hr5.z, (r)hr39.x, hr38.y, (r)(last)hr5.z
(rpt1)mad.f16 hr11.z, (r)hr39.x, hr36.z, (r)(last)hr11.z
mad.f16 hr5.y, (last)hr37.z, hr38.z, (last)hr33.x
mad.f16 hr5.x, (last)hr37.y, hr38.z, (last)hr32.w
(rpt1)mad.f16 hr4.z, (r)(last)hr36.w, hr38.z, (r)(last)hr32.y
mad.f16 hr4.y, (last)hr39.w, hr38.z, (last)hr35.z
mad.f16 hr4.x, (last)hr39.z, hr38.z, (last)hr35.y
(rpt1)mad.f16 hr3.z, (r)(last)hr39.x, hr38.z, (r)(last)hr34.w
br p0.x, #l1117
jump #l130
l1117:
(jp)(eolm)nop
(nop3) add.u r12.w, r51.w, (last)r12.w
(nop3) shl.b r12.w, (last)r12.w, 9
(nop3) sad.s32 r12.w, r52.z, r12.w, (last)r1.y
(nop3) shl.b r12.w, (last)r12.w, 2
add.u r20.x, r12.w, c1.x
add.u r20.y, r12.w, c4.w
add.u r20.z, r12.w, c4.z
add.u r20.w, r12.w, c5.x
add.u r0.x, r12.w, c4.y
(rpt1)add.u r0.y, r12.w, (r)c5.y
add.u r0.w, r12.w, c8.w
stib.b.untyped.1d.u16.4.imm.base0 hr18.z, r12.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r12.w+32, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r20.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r20.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r20.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r20.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r0.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r0.y, 4
(ss)(rpt1)add.u r5.w, r12.w, (r)c10.x
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r0.z, 4
(ss)(rpt1)add.u r5.y, r12.w, (r)c9.z
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r0.w, 4
(ss)(rpt1)add.u r4.w, (last)r12.w, (r)c9.x
(rpt4)nop
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r4.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r5.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r5.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r5.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r5.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r6.x, 4
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
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1312 instr, 32 nops, 1280 non-nops, 65 mov, 0 cov, 2336 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 21 full, 12 constlen
; CL prog 23/1: 35 cat0, 65 cat1, 90 cat2, 1030 cat3, 0 cat4, 36 cat5, 52 cat6, 4 cat7
; CL prog 23/1: 41 sstall, 22 (ss), 197 systall, 14 (sy), 1 loops
; CL prog 23/1: 12 max_waves, 0 double_threadsize
; 58 preamble-instr, 1 early-preamble
