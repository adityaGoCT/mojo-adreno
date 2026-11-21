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
isam.v.base0 (u16)(xyzw)hr24.x, r13.x+32, s#0, t#0
ldl.u16 r23.x, l[r10.y], 4
ldl.u16 r36.z, l[r10.y+64], 4
(sy)(ss)mad.f16 hr17.z, hr36.z, hr22.x, (last)hr17.z
mad.f16 hr15.z, hr36.z, hr22.y, (last)hr15.z
mad.f16 hr13.z, hr36.z, hr22.z, (last)hr13.z
mad.f16 hr11.z, hr36.z, hr22.w, (last)hr11.z
mad.f16 hr9.z, hr36.z, hr24.x, (last)hr9.z
mad.f16 hr7.z, hr36.z, hr24.y, (last)hr7.z
mad.f16 hr5.z, hr36.z, hr24.z, (last)hr5.z
mad.f16 hr17.w, hr36.w, hr22.x, (last)hr17.w
mad.f16 hr15.w, hr36.w, hr22.y, (last)hr15.w
mad.f16 hr13.w, hr36.w, hr22.z, (last)hr13.w
mad.f16 hr11.w, hr36.w, hr22.w, (last)hr11.w
mad.f16 hr9.w, hr36.w, hr24.x, (last)hr9.w
mad.f16 hr7.w, hr36.w, hr24.y, (last)hr7.w
mad.f16 hr5.w, hr36.w, hr24.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr37.x, hr22.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr37.x, hr22.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr37.x, hr22.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr37.x, hr22.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr37.x, hr24.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr37.x, hr24.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr37.x, hr24.z, (r)(last)hr6.x
(rpt1)mad.f16 hr36.z, (r)(last)hr36.z, hr24.w, (r)(last)hr3.z
(rpt1)mad.f16 hr37.x, (r)(last)hr37.x, hr24.w, (r)(last)hr4.x
isam.v.base0 (u16)(xyzw)hr3.z, r13.y, s#0, t#0
isam.v.base0 (u16)(xyzw)hr19.z, r13.z, s#0, t#0
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
isam.v.base0 (u16)(xyzw)hr22.x, r13.w, s#0, t#0
(rpt1)mad.f16 hr10.z, (r)hr23.x, hr24.x, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr23.z, hr24.x, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr23.x, hr24.y, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr23.z, hr24.y, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr23.x, hr24.z, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr23.z, hr24.z, (r)(last)hr7.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr24.w, (r)(last)hr4.z
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr24.w, (r)(last)hr5.x
ldl.u16 r4.z, l[r10.y+128], 4
isam.v.base0 (u16)(xyzw)hr24.y, r14.x, s#0, t#0
ldl.u16 r21.x, l[r10.y+192], 4
(sy)(ss)mad.f16 hr18.w, hr4.w, hr3.z, (last)hr18.w
isam.v.base0 (u16)(xyzw)hr27.y, r14.y, s#0, t#0
mad.f16 hr16.w, hr4.w, hr3.w, (last)hr16.w
mad.f16 hr14.w, hr4.w, hr4.x, (last)hr14.w
mad.f16 hr12.w, hr4.w, hr4.y, (last)hr12.w
mad.f16 hr19.x, hr5.x, hr3.z, (last)hr19.x
mad.f16 hr17.x, hr5.x, hr3.w, (last)hr17.x
mad.f16 hr15.x, hr5.x, hr4.x, (last)hr15.x
mad.f16 hr13.x, hr5.x, hr4.y, (last)hr13.x
mad.f16 hr19.y, hr5.y, hr3.z, (last)hr19.y
mad.f16 hr17.y, hr5.y, hr3.w, (last)hr17.y
mad.f16 hr15.y, hr5.y, hr4.x, (last)hr15.y
mad.f16 hr13.y, hr5.y, hr4.y, (last)hr13.y
mad.f16 hr10.w, hr4.w, hr19.z, (last)hr10.w
(rpt1)mad.f16 hr11.x, (r)hr5.x, hr19.z, (r)(last)hr11.x
mad.f16 hr8.w, hr4.w, hr19.w, (last)hr8.w
(rpt1)mad.f16 hr9.x, (r)hr5.x, hr19.w, (r)(last)hr9.x
mad.f16 hr6.w, hr4.w, hr20.x, (last)hr6.w
(rpt1)mad.f16 hr7.x, (r)hr5.x, hr20.x, (r)(last)hr7.x
mad.f16 hr4.w, (last)hr4.w, hr20.y, (last)hr23.y
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr20.y, (r)(last)hr23.z
ldl.u16 r23.y, l[r10.y+256], 4
ldl.u16 r26.y, l[r10.y+320], 4
mad.f16 hr18.z, hr4.z, hr3.z, (last)hr18.z
mad.f16 hr16.z, hr4.z, hr3.w, (last)hr16.z
mad.f16 hr14.z, hr4.z, hr4.x, (last)hr14.z
mad.f16 hr12.z, hr4.z, hr4.y, (last)hr12.z
mad.f16 hr17.z, hr21.x, hr3.z, (last)hr17.z
mad.f16 hr15.z, hr21.x, hr3.w, (last)hr15.z
mad.f16 hr13.z, hr21.x, hr4.x, (last)hr13.z
mad.f16 hr11.z, hr21.x, hr4.y, (last)hr11.z
mad.f16 hr17.w, hr21.y, hr3.z, (last)hr17.w
mad.f16 hr15.w, hr21.y, hr3.w, (last)hr15.w
mad.f16 hr13.w, hr21.y, hr4.x, (last)hr13.w
mad.f16 hr11.w, hr21.y, hr4.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr21.z, hr3.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr21.z, hr3.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr21.z, hr4.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr21.z, hr4.y, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr3.z, r14.z, s#0, t#0
mad.f16 hr10.z, hr4.z, hr19.z, (last)hr10.z
mad.f16 hr8.z, hr4.z, hr19.w, (last)hr8.z
mad.f16 hr6.z, hr4.z, hr20.x, (last)hr6.z
mad.f16 hr9.z, hr21.x, hr19.z, (last)hr9.z
mad.f16 hr7.z, hr21.x, hr19.w, (last)hr7.z
mad.f16 hr5.z, hr21.x, hr20.x, (last)hr5.z
mad.f16 hr9.w, hr21.y, hr19.z, (last)hr9.w
mad.f16 hr7.w, hr21.y, hr19.w, (last)hr7.w
mad.f16 hr5.w, hr21.y, hr20.x, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr21.z, hr19.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr21.z, hr19.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr21.z, hr20.x, (r)(last)hr6.x
(ss)mad.f16 hr16.w, hr23.z, hr22.y, (last)hr16.w
mad.f16 hr14.w, hr23.z, hr22.z, (last)hr14.w
mad.f16 hr12.w, hr23.z, hr22.w, (last)hr12.w
mad.f16 hr17.x, hr23.w, hr22.y, (last)hr17.x
mad.f16 hr15.x, hr23.w, hr22.z, (last)hr15.x
mad.f16 hr13.x, hr23.w, hr22.w, (last)hr13.x
mad.f16 hr17.y, hr24.x, hr22.y, (last)hr17.y
mad.f16 hr15.y, hr24.x, hr22.z, (last)hr15.y
mad.f16 hr13.y, hr24.x, hr22.w, (last)hr13.y
mad.f16 hr16.z, hr23.y, hr22.y, (last)hr16.z
mad.f16 hr14.z, hr23.y, hr22.z, (last)hr14.z
mad.f16 hr12.z, hr23.y, hr22.w, (last)hr12.z
mad.f16 hr15.z, hr26.y, hr22.y, (last)hr15.z
mad.f16 hr13.z, hr26.y, hr22.z, (last)hr13.z
mad.f16 hr11.z, hr26.y, hr22.w, (last)hr11.z
mad.f16 hr15.w, hr26.z, hr22.y, (last)hr15.w
mad.f16 hr13.w, hr26.z, hr22.z, (last)hr13.w
mad.f16 hr11.w, hr26.z, hr22.w, (last)hr11.w
(rpt1)mad.f16 hr16.x, (r)hr26.w, hr22.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr26.w, hr22.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr26.w, hr22.w, (r)(last)hr12.x
mad.f16 hr4.z, (last)hr4.z, hr20.y, (last)hr23.x
(rpt1)mad.f16 hr21.x, (r)(last)hr21.x, hr20.y, (r)(last)hr36.z
(rpt1)mad.f16 hr21.z, (r)(last)hr21.z, hr20.y, (r)(last)hr37.x
isam.v.base0 (u16)(xyzw)hr19.z, r14.w, s#0, t#0
isam.v.base0 (u16)(xyzw)hr22.y, r15.x, s#0, t#0
ldl.u16 r36.z, l[r10.y+384], 4
mad.f16 hr18.w, hr23.z, hr22.x, (last)hr18.w
(rpt1)mad.f16 hr19.x, (r)hr23.w, hr22.x, (r)(last)hr19.x
mad.f16 hr10.w, hr23.z, hr24.y, (last)hr10.w
(rpt1)mad.f16 hr11.x, (r)hr23.w, hr24.y, (r)(last)hr11.x
mad.f16 hr8.w, hr23.z, hr24.z, (last)hr8.w
(rpt1)mad.f16 hr9.x, (r)hr23.w, hr24.z, (r)(last)hr9.x
mad.f16 hr6.w, hr23.z, hr24.w, (last)hr6.w
(rpt1)mad.f16 hr7.x, (r)hr23.w, hr24.w, (r)(last)hr7.x
mad.f16 hr18.z, hr23.y, hr22.x, (last)hr18.z
mad.f16 hr10.z, hr23.y, hr24.y, (last)hr10.z
mad.f16 hr8.z, hr23.y, hr24.z, (last)hr8.z
mad.f16 hr6.z, hr23.y, hr24.w, (last)hr6.z
mad.f16 hr23.z, (last)hr23.z, hr25.x, (last)hr4.w
(rpt1)mad.f16 hr23.w, (r)(last)hr23.w, hr25.x, (r)(last)hr5.x
mad.f16 hr23.y, (last)hr23.y, hr25.x, (last)hr4.z
ldl.u16 r4.z, l[r10.y+448], 4
(rpt1)mad.f16 hr17.z, (r)hr26.y, hr22.x, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr26.w, hr22.x, (r)(last)hr18.x
mad.f16 hr9.z, hr26.y, hr24.y, (last)hr9.z
mad.f16 hr7.z, hr26.y, hr24.z, (last)hr7.z
mad.f16 hr5.z, hr26.y, hr24.w, (last)hr5.z
mad.f16 hr9.w, hr26.z, hr24.y, (last)hr9.w
mad.f16 hr7.w, hr26.z, hr24.z, (last)hr7.w
mad.f16 hr5.w, hr26.z, hr24.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr26.w, hr24.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr26.w, hr24.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr26.w, hr24.w, (r)(last)hr6.x
mad.f16 hr26.y, (last)hr26.y, hr25.x, (last)hr21.x
(sy)(ss)mad.f16 hr16.z, hr36.z, hr27.z, (last)hr16.z
mad.f16 hr14.z, hr36.z, hr27.w, (last)hr14.z
mad.f16 hr12.z, hr36.z, hr28.x, (last)hr12.z
mad.f16 hr16.w, hr36.w, hr27.z, (last)hr16.w
mad.f16 hr14.w, hr36.w, hr27.w, (last)hr14.w
mad.f16 hr12.w, hr36.w, hr28.x, (last)hr12.w
mad.f16 hr17.x, hr37.x, hr27.z, (last)hr17.x
mad.f16 hr15.x, hr37.x, hr27.w, (last)hr15.x
mad.f16 hr13.x, hr37.x, hr28.x, (last)hr13.x
mad.f16 hr17.y, hr37.y, hr27.z, (last)hr17.y
mad.f16 hr15.y, hr37.y, hr27.w, (last)hr15.y
mad.f16 hr13.y, hr37.y, hr28.x, (last)hr13.y
mad.f16 hr18.w, hr36.w, hr27.y, (last)hr18.w
(rpt1)mad.f16 hr19.x, (r)hr37.x, hr27.y, (r)(last)hr19.x
mad.f16 hr10.w, hr36.w, hr3.z, (last)hr10.w
(rpt1)mad.f16 hr11.x, (r)hr37.x, hr3.z, (r)(last)hr11.x
mad.f16 hr8.w, hr36.w, hr3.w, (last)hr8.w
(rpt1)mad.f16 hr9.x, (r)hr37.x, hr3.w, (r)(last)hr9.x
mad.f16 hr6.w, hr36.w, hr4.x, (last)hr6.w
(rpt1)mad.f16 hr7.x, (r)hr37.x, hr4.x, (r)(last)hr7.x
mad.f16 hr18.z, hr36.z, hr27.y, (last)hr18.z
mad.f16 hr10.z, hr36.z, hr3.z, (last)hr10.z
mad.f16 hr8.z, hr36.z, hr3.w, (last)hr8.z
mad.f16 hr6.z, hr36.z, hr4.x, (last)hr6.z
mad.f16 hr15.z, hr4.z, hr27.z, (last)hr15.z
mad.f16 hr13.z, hr4.z, hr27.w, (last)hr13.z
mad.f16 hr11.z, hr4.z, hr28.x, (last)hr11.z
mad.f16 hr15.w, hr4.w, hr27.z, (last)hr15.w
mad.f16 hr13.w, hr4.w, hr27.w, (last)hr13.w
mad.f16 hr11.w, hr4.w, hr28.x, (last)hr11.w
(rpt1)mad.f16 hr16.x, (r)hr5.x, hr27.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr5.x, hr27.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr5.x, hr28.x, (r)(last)hr12.x
(rpt1)mad.f16 hr17.z, (r)hr4.z, hr27.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr5.x, hr27.y, (r)(last)hr18.x
mad.f16 hr26.z, (last)hr26.z, hr25.x, (last)hr21.y
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr25.x, (r)(last)hr21.z
isam.v.base0 (u16)(xyzw)hr24.y, r15.y, s#0, t#0
ldl.u16 r21.y, l[r10.y+512], 4
isam.v.base0 (u16)(xyzw)hr27.y, r15.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr29.y, r15.w, s#0, t#0
mad.f16 hr36.w, (last)hr36.w, hr4.y, (last)hr23.z
(rpt1)mad.f16 hr37.x, (r)(last)hr37.x, hr4.y, (r)(last)hr23.w
mad.f16 hr36.z, (last)hr36.z, hr4.y, (last)hr23.y
ldl.u16 r23.y, l[r10.y+576], 4
mad.f16 hr9.z, hr4.z, hr3.z, (last)hr9.z
mad.f16 hr7.z, hr4.z, hr3.w, (last)hr7.z
mad.f16 hr5.z, hr4.z, hr4.x, (last)hr5.z
mad.f16 hr9.w, hr4.w, hr3.z, (last)hr9.w
mad.f16 hr7.w, hr4.w, hr3.w, (last)hr7.w
mad.f16 hr5.w, hr4.w, hr4.x, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr5.x, hr3.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr5.x, hr3.w, (r)(last)hr8.x
(ss)nop
isam.v.base0 (u16)(xyzw)hr31.y, r16.x, s#0, t#0
(rpt1)mad.f16 hr6.x, (r)hr5.x, hr4.x, (r)(last)hr6.x
(rpt1)mad.f16 hr4.z, (r)(last)hr4.z, hr4.y, (r)(last)hr26.y
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr4.y, (r)(last)hr26.w
ldl.u16 r26.y, l[r10.y+640], 4
ldl.u16 r28.y, l[r10.y+704], 4
ldl.u16 r30.y, l[r10.y+768], 4
mad.f16 hr18.z, hr21.y, hr19.z, (last)hr18.z
mad.f16 hr16.z, hr21.y, hr19.w, (last)hr16.z
mad.f16 hr14.z, hr21.y, hr20.x, (last)hr14.z
mad.f16 hr12.z, hr21.y, hr20.y, (last)hr12.z
mad.f16 hr18.w, hr21.z, hr19.z, (last)hr18.w
mad.f16 hr16.w, hr21.z, hr19.w, (last)hr16.w
mad.f16 hr14.w, hr21.z, hr20.x, (last)hr14.w
mad.f16 hr12.w, hr21.z, hr20.y, (last)hr12.w
mad.f16 hr19.x, hr21.w, hr19.z, (last)hr19.x
mad.f16 hr17.x, hr21.w, hr19.w, (last)hr17.x
mad.f16 hr15.x, hr21.w, hr20.x, (last)hr15.x
mad.f16 hr13.x, hr21.w, hr20.y, (last)hr13.x
mad.f16 hr19.y, hr22.x, hr19.z, (last)hr19.y
mad.f16 hr17.y, hr22.x, hr19.w, (last)hr17.y
mad.f16 hr15.y, hr22.x, hr20.x, (last)hr15.y
mad.f16 hr13.y, hr22.x, hr20.y, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr21.y, hr22.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr21.w, hr22.y, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr21.y, hr22.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr21.w, hr22.z, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr21.y, hr22.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr21.w, hr22.w, (r)(last)hr7.x
mad.f16 hr17.z, hr23.y, hr19.z, (last)hr17.z
mad.f16 hr15.z, hr23.y, hr19.w, (last)hr15.z
mad.f16 hr13.z, hr23.y, hr20.x, (last)hr13.z
mad.f16 hr11.z, hr23.y, hr20.y, (last)hr11.z
mad.f16 hr17.w, hr23.z, hr19.z, (last)hr17.w
mad.f16 hr15.w, hr23.z, hr19.w, (last)hr15.w
mad.f16 hr13.w, hr23.z, hr20.x, (last)hr13.w
mad.f16 hr11.w, hr23.z, hr20.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr23.w, hr19.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr23.w, hr19.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr23.w, hr20.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr23.w, hr20.y, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr19.z, r16.y, s#0, t#0
mad.f16 hr9.z, hr23.y, hr22.y, (last)hr9.z
mad.f16 hr7.z, hr23.y, hr22.z, (last)hr7.z
mad.f16 hr5.z, hr23.y, hr22.w, (last)hr5.z
mad.f16 hr9.w, hr23.z, hr22.y, (last)hr9.w
mad.f16 hr7.w, hr23.z, hr22.z, (last)hr7.w
mad.f16 hr5.w, hr23.z, hr22.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr23.w, hr22.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr23.w, hr22.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr23.w, hr22.w, (r)(last)hr6.x
(rpt1)mad.f16 hr21.y, (r)(last)hr21.y, hr23.x, (r)(last)hr36.z
(rpt1)mad.f16 hr21.w, (r)(last)hr21.w, hr23.x, (r)(last)hr37.x
mad.f16 hr23.y, (last)hr23.y, hr23.x, (last)hr4.z
ldl.u16 r3.w, l[r10.y+832], 4
mad.f16 hr23.z, (last)hr23.z, hr23.x, (last)hr4.w
(rpt1)mad.f16 hr23.w, (r)(last)hr23.w, hr23.x, (r)(last)hr5.x
isam.v.base0 (u16)(xyzw)hr22.y, r16.z, s#0, t#0
(sy)(ss)mad.f16 hr18.z, hr26.y, hr24.y, (last)hr18.z
mad.f16 hr16.z, hr26.y, hr24.z, (last)hr16.z
mad.f16 hr14.z, hr26.y, hr24.w, (last)hr14.z
mad.f16 hr12.z, hr26.y, hr25.x, (last)hr12.z
mad.f16 hr18.w, hr26.z, hr24.y, (last)hr18.w
mad.f16 hr16.w, hr26.z, hr24.z, (last)hr16.w
mad.f16 hr14.w, hr26.z, hr24.w, (last)hr14.w
mad.f16 hr12.w, hr26.z, hr25.x, (last)hr12.w
mad.f16 hr19.x, hr26.w, hr24.y, (last)hr19.x
mad.f16 hr17.x, hr26.w, hr24.z, (last)hr17.x
mad.f16 hr15.x, hr26.w, hr24.w, (last)hr15.x
mad.f16 hr13.x, hr26.w, hr25.x, (last)hr13.x
mad.f16 hr19.y, hr27.x, hr24.y, (last)hr19.y
mad.f16 hr17.y, hr27.x, hr24.z, (last)hr17.y
mad.f16 hr15.y, hr27.x, hr24.w, (last)hr15.y
mad.f16 hr13.y, hr27.x, hr25.x, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr26.y, hr27.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr26.w, hr27.y, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr26.y, hr27.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr26.w, hr27.z, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr26.y, hr27.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr26.w, hr27.w, (r)(last)hr7.x
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr28.x, (r)(last)hr21.y
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr28.x, (r)(last)hr21.w
ldl.u16 r21.y, l[r10.y+896], 4
mad.f16 hr17.z, hr28.y, hr24.y, (last)hr17.z
mad.f16 hr15.z, hr28.y, hr24.z, (last)hr15.z
mad.f16 hr13.z, hr28.y, hr24.w, (last)hr13.z
mad.f16 hr11.z, hr28.y, hr25.x, (last)hr11.z
mad.f16 hr17.w, hr28.z, hr24.y, (last)hr17.w
mad.f16 hr15.w, hr28.z, hr24.z, (last)hr15.w
mad.f16 hr13.w, hr28.z, hr24.w, (last)hr13.w
mad.f16 hr11.w, hr28.z, hr25.x, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr28.w, hr24.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr28.w, hr24.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr28.w, hr24.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr28.w, hr25.x, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr24.y, r16.w, s#0, t#0
mad.f16 hr9.z, hr28.y, hr27.y, (last)hr9.z
mad.f16 hr7.z, hr28.y, hr27.z, (last)hr7.z
mad.f16 hr5.z, hr28.y, hr27.w, (last)hr5.z
mad.f16 hr9.w, hr28.z, hr27.y, (last)hr9.w
mad.f16 hr7.w, hr28.z, hr27.z, (last)hr7.w
mad.f16 hr5.w, hr28.z, hr27.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr28.w, hr27.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr28.w, hr27.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr28.w, hr27.w, (r)(last)hr6.x
mad.f16 hr18.z, hr30.y, hr29.y, (last)hr18.z
mad.f16 hr16.z, hr30.y, hr29.z, (last)hr16.z
mad.f16 hr14.z, hr30.y, hr29.w, (last)hr14.z
mad.f16 hr12.z, hr30.y, hr30.x, (last)hr12.z
mad.f16 hr18.w, hr30.z, hr29.y, (last)hr18.w
mad.f16 hr16.w, hr30.z, hr29.z, (last)hr16.w
mad.f16 hr14.w, hr30.z, hr29.w, (last)hr14.w
mad.f16 hr12.w, hr30.z, hr30.x, (last)hr12.w
mad.f16 hr19.x, hr30.w, hr29.y, (last)hr19.x
mad.f16 hr17.x, hr30.w, hr29.z, (last)hr17.x
mad.f16 hr15.x, hr30.w, hr29.w, (last)hr15.x
mad.f16 hr13.x, hr30.w, hr30.x, (last)hr13.x
mad.f16 hr19.y, hr31.x, hr29.y, (last)hr19.y
mad.f16 hr17.y, hr31.x, hr29.z, (last)hr17.y
mad.f16 hr15.y, hr31.x, hr29.w, (last)hr15.y
mad.f16 hr13.y, hr31.x, hr30.x, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr30.y, hr31.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr30.w, hr31.y, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr30.y, hr31.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr30.w, hr31.z, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr30.y, hr31.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr30.w, hr31.w, (r)(last)hr7.x
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr28.x, (r)(last)hr23.y
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr28.x, (r)(last)hr23.w
isam.v.base0 (u16)(xyzw)hr27.y, r17.x, s#0, t#0
ldl.u16 r23.y, l[r10.y+960], 4
(rpt1)mad.f16 hr30.y, (r)(last)hr30.y, hr32.x, (r)(last)hr26.y
(rpt1)mad.f16 hr30.w, (r)(last)hr30.w, hr32.x, (r)(last)hr26.w
ldl.u16 r26.y, l[r10.y+1024], 4
mad.f16 hr17.z, hr3.w, hr29.y, (last)hr17.z
mad.f16 hr15.z, hr3.w, hr29.z, (last)hr15.z
mad.f16 hr13.z, hr3.w, hr29.w, (last)hr13.z
mad.f16 hr11.z, hr3.w, hr30.x, (last)hr11.z
mad.f16 hr17.w, hr4.x, hr29.y, (last)hr17.w
mad.f16 hr15.w, hr4.x, hr29.z, (last)hr15.w
mad.f16 hr13.w, hr4.x, hr29.w, (last)hr13.w
mad.f16 hr11.w, hr4.x, hr30.x, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr4.y, hr29.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr4.y, hr29.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr4.y, hr29.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr4.y, hr30.x, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr29.y, r17.y, s#0, t#0
mad.f16 hr9.z, hr3.w, hr31.y, (last)hr9.z
mad.f16 hr7.z, hr3.w, hr31.z, (last)hr7.z
mad.f16 hr5.z, hr3.w, hr31.w, (last)hr5.z
mad.f16 hr9.w, hr4.x, hr31.y, (last)hr9.w
mad.f16 hr7.w, hr4.x, hr31.z, (last)hr7.w
mad.f16 hr5.w, hr4.x, hr31.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr4.y, hr31.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr4.y, hr31.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr4.y, hr31.w, (r)(last)hr6.x
(ss)mad.f16 hr18.z, hr21.y, hr19.z, (last)hr18.z
mad.f16 hr16.z, hr21.y, hr19.w, (last)hr16.z
mad.f16 hr14.z, hr21.y, hr20.x, (last)hr14.z
mad.f16 hr12.z, hr21.y, hr20.y, (last)hr12.z
mad.f16 hr18.w, hr21.z, hr19.z, (last)hr18.w
mad.f16 hr16.w, hr21.z, hr19.w, (last)hr16.w
mad.f16 hr14.w, hr21.z, hr20.x, (last)hr14.w
mad.f16 hr12.w, hr21.z, hr20.y, (last)hr12.w
mad.f16 hr19.x, hr21.w, hr19.z, (last)hr19.x
mad.f16 hr17.x, hr21.w, hr19.w, (last)hr17.x
mad.f16 hr15.x, hr21.w, hr20.x, (last)hr15.x
mad.f16 hr13.x, hr21.w, hr20.y, (last)hr13.x
mad.f16 hr19.y, hr22.x, hr19.z, (last)hr19.y
mad.f16 hr17.y, hr22.x, hr19.w, (last)hr17.y
mad.f16 hr15.y, hr22.x, hr20.x, (last)hr15.y
mad.f16 hr13.y, hr22.x, hr20.y, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr21.y, hr22.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr21.w, hr22.y, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr21.y, hr22.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr21.w, hr22.z, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr21.y, hr22.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr21.w, hr22.w, (r)(last)hr7.x
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr32.x, (r)(last)hr28.y
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr32.x, (r)(last)hr28.w
isam.v.base0 (u16)(xyzw)hr31.y, r17.z, s#0, t#0
ldl.u16 r28.y, l[r10.y+1088], 4
isam.v.base0 (u16)(xyzw)hr33.y, r17.w, s#0, t#0
(rpt1)mad.f16 hr21.y, (r)(last)hr21.y, hr23.x, (r)(last)hr30.y
(rpt1)mad.f16 hr21.w, (r)(last)hr21.w, hr23.x, (r)(last)hr30.w
ldl.u16 r30.y, l[r10.y+1152], 4
ldl.u16 r32.y, l[r10.y+1216], 4
mad.f16 hr17.z, hr23.y, hr19.z, (last)hr17.z
mad.f16 hr15.z, hr23.y, hr19.w, (last)hr15.z
mad.f16 hr13.z, hr23.y, hr20.x, (last)hr13.z
mad.f16 hr11.z, hr23.y, hr20.y, (last)hr11.z
mad.f16 hr17.w, hr23.z, hr19.z, (last)hr17.w
mad.f16 hr15.w, hr23.z, hr19.w, (last)hr15.w
mad.f16 hr13.w, hr23.z, hr20.x, (last)hr13.w
mad.f16 hr11.w, hr23.z, hr20.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr23.w, hr19.z, (r)(last)hr18.x
(ss)nop
isam.v.base0 (u16)(xyzw)hr35.y, r18.x, s#0, t#0
ldl.u16 r34.y, l[r10.y+1280], 4
(rpt1)mad.f16 hr16.x, (r)hr23.w, hr19.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr23.w, hr20.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr23.w, hr20.y, (r)(last)hr12.x
mad.f16 hr9.z, hr23.y, hr22.y, (last)hr9.z
mad.f16 hr7.z, hr23.y, hr22.z, (last)hr7.z
mad.f16 hr5.z, hr23.y, hr22.w, (last)hr5.z
mad.f16 hr9.w, hr23.z, hr22.y, (last)hr9.w
(ss)nop
ldl.u16 r36.y, l[r10.y+1344], 4
mad.f16 hr7.w, hr23.z, hr22.z, (last)hr7.w
mad.f16 hr5.w, hr23.z, hr22.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr23.w, hr22.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr23.w, hr22.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr23.w, hr22.w, (r)(last)hr6.x
(rpt1)mad.f16 hr23.y, (r)(last)hr23.y, hr23.x, (r)(last)hr3.w
mad.f16 hr23.w, (last)hr23.w, hr23.x, (last)hr4.y
isam.v.base0 (u16)(xyzw)hr3.z, r18.w, s#0, t#0
mad.f16 hr24.x, (last)hr24.x, hr23.x, (last)hr4.z
isam.v.base0 (u16)(xyzw)hr22.y, r19.x, s#0, t#0
(sy)mad.f16 hr18.z, hr26.y, hr24.y, (last)hr18.z
mad.f16 hr16.z, hr26.y, hr24.z, (last)hr16.z
mad.f16 hr14.z, hr26.y, hr24.w, (last)hr14.z
mad.f16 hr12.z, hr26.y, hr25.x, (last)hr12.z
mad.f16 hr18.w, hr26.z, hr24.y, (last)hr18.w
mad.f16 hr16.w, hr26.z, hr24.z, (last)hr16.w
mad.f16 hr14.w, hr26.z, hr24.w, (last)hr14.w
mad.f16 hr12.w, hr26.z, hr25.x, (last)hr12.w
mad.f16 hr19.x, hr26.w, hr24.y, (last)hr19.x
mad.f16 hr17.x, hr26.w, hr24.z, (last)hr17.x
mad.f16 hr15.x, hr26.w, hr24.w, (last)hr15.x
mad.f16 hr13.x, hr26.w, hr25.x, (last)hr13.x
mad.f16 hr19.y, hr27.x, hr24.y, (last)hr19.y
mad.f16 hr17.y, hr27.x, hr24.z, (last)hr17.y
mad.f16 hr15.y, hr27.x, hr24.w, (last)hr15.y
mad.f16 hr13.y, hr27.x, hr25.x, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr26.y, hr27.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr26.w, hr27.y, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr26.y, hr27.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr26.w, hr27.z, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr26.y, hr27.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr26.w, hr27.w, (r)(last)hr7.x
mad.f16 hr17.z, hr28.y, hr24.y, (last)hr17.z
mad.f16 hr15.z, hr28.y, hr24.z, (last)hr15.z
mad.f16 hr13.z, hr28.y, hr24.w, (last)hr13.z
mad.f16 hr11.z, hr28.y, hr25.x, (last)hr11.z
mad.f16 hr17.w, hr28.z, hr24.y, (last)hr17.w
mad.f16 hr15.w, hr28.z, hr24.z, (last)hr15.w
mad.f16 hr13.w, hr28.z, hr24.w, (last)hr13.w
mad.f16 hr11.w, hr28.z, hr25.x, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr28.w, hr24.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr28.w, hr24.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr28.w, hr24.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr28.w, hr25.x, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr24.y, r19.y, s#0, t#0
mad.f16 hr9.z, hr28.y, hr27.y, (last)hr9.z
mad.f16 hr7.z, hr28.y, hr27.z, (last)hr7.z
mad.f16 hr5.z, hr28.y, hr27.w, (last)hr5.z
mad.f16 hr9.w, hr28.z, hr27.y, (last)hr9.w
mad.f16 hr7.w, hr28.z, hr27.z, (last)hr7.w
mad.f16 hr5.w, hr28.z, hr27.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr28.w, hr27.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr28.w, hr27.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr28.w, hr27.w, (r)(last)hr6.x
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr28.x, (r)(last)hr21.y
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr28.x, (r)(last)hr21.w
ldl.u16 r21.y, l[r10.y+1408], 4
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr28.x, (r)(last)hr23.y
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr28.x, (r)(last)hr23.w
isam.v.base0 (u16)(xyzw)hr27.y, r19.z, s#0, t#0
ldl.u16 r23.y, l[r10.y+1472], 4
mad.f16 hr18.z, hr30.y, hr29.y, (last)hr18.z
mad.f16 hr16.z, hr30.y, hr29.z, (last)hr16.z
mad.f16 hr14.z, hr30.y, hr29.w, (last)hr14.z
mad.f16 hr12.z, hr30.y, hr30.x, (last)hr12.z
mad.f16 hr18.w, hr30.z, hr29.y, (last)hr18.w
mad.f16 hr16.w, hr30.z, hr29.z, (last)hr16.w
mad.f16 hr14.w, hr30.z, hr29.w, (last)hr14.w
mad.f16 hr12.w, hr30.z, hr30.x, (last)hr12.w
mad.f16 hr19.x, hr30.w, hr29.y, (last)hr19.x
mad.f16 hr17.x, hr30.w, hr29.z, (last)hr17.x
mad.f16 hr15.x, hr30.w, hr29.w, (last)hr15.x
mad.f16 hr13.x, hr30.w, hr30.x, (last)hr13.x
mad.f16 hr19.y, hr31.x, hr29.y, (last)hr19.y
mad.f16 hr17.y, hr31.x, hr29.z, (last)hr17.y
mad.f16 hr15.y, hr31.x, hr29.w, (last)hr15.y
mad.f16 hr13.y, hr31.x, hr30.x, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr30.y, hr31.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr30.w, hr31.y, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr30.y, hr31.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr30.w, hr31.z, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr30.y, hr31.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr30.w, hr31.w, (r)(last)hr7.x
mad.f16 hr17.z, hr32.y, hr29.y, (last)hr17.z
mad.f16 hr15.z, hr32.y, hr29.z, (last)hr15.z
mad.f16 hr13.z, hr32.y, hr29.w, (last)hr13.z
mad.f16 hr11.z, hr32.y, hr30.x, (last)hr11.z
mad.f16 hr17.w, hr32.z, hr29.y, (last)hr17.w
mad.f16 hr15.w, hr32.z, hr29.z, (last)hr15.w
mad.f16 hr13.w, hr32.z, hr29.w, (last)hr13.w
mad.f16 hr11.w, hr32.z, hr30.x, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr32.w, hr29.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr32.w, hr29.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr32.w, hr29.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr32.w, hr30.x, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr29.y, r19.w, s#0, t#0
mad.f16 hr9.z, hr32.y, hr31.y, (last)hr9.z
mad.f16 hr7.z, hr32.y, hr31.z, (last)hr7.z
mad.f16 hr5.z, hr32.y, hr31.w, (last)hr5.z
mad.f16 hr9.w, hr32.z, hr31.y, (last)hr9.w
mad.f16 hr7.w, hr32.z, hr31.z, (last)hr7.w
mad.f16 hr5.w, hr32.z, hr31.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr32.w, hr31.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr32.w, hr31.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr32.w, hr31.w, (r)(last)hr6.x
(rpt1)mad.f16 hr30.y, (r)(last)hr30.y, hr32.x, (r)(last)hr26.y
(rpt1)mad.f16 hr30.w, (r)(last)hr30.w, hr32.x, (r)(last)hr26.w
ldl.u16 r26.y, l[r10.y+1536], 4
(rpt1)mad.f16 hr32.y, (r)(last)hr32.y, hr32.x, (r)(last)hr28.y
(rpt1)mad.f16 hr32.w, (r)(last)hr32.w, hr32.x, (r)(last)hr28.w
isam.v.base0 (u16)(xyzw)hr31.y, r20.x, s#0, t#0
ldl.u16 r28.y, l[r10.y+1600], 4
mad.f16 hr18.z, hr34.y, hr33.y, (last)hr18.z
mad.f16 hr16.z, hr34.y, hr33.z, (last)hr16.z
mad.f16 hr14.z, hr34.y, hr33.w, (last)hr14.z
mad.f16 hr12.z, hr34.y, hr34.x, (last)hr12.z
mad.f16 hr18.w, hr34.z, hr33.y, (last)hr18.w
mad.f16 hr16.w, hr34.z, hr33.z, (last)hr16.w
mad.f16 hr14.w, hr34.z, hr33.w, (last)hr14.w
mad.f16 hr12.w, hr34.z, hr34.x, (last)hr12.w
mad.f16 hr19.x, hr34.w, hr33.y, (last)hr19.x
mad.f16 hr17.x, hr34.w, hr33.z, (last)hr17.x
mad.f16 hr15.x, hr34.w, hr33.w, (last)hr15.x
mad.f16 hr13.x, hr34.w, hr34.x, (last)hr13.x
mad.f16 hr19.y, hr35.x, hr33.y, (last)hr19.y
mad.f16 hr17.y, hr35.x, hr33.z, (last)hr17.y
mad.f16 hr15.y, hr35.x, hr33.w, (last)hr15.y
mad.f16 hr13.y, hr35.x, hr34.x, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr34.y, hr35.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr34.w, hr35.y, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr34.y, hr35.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr34.w, hr35.z, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr34.y, hr35.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr34.w, hr35.w, (r)(last)hr7.x
(ss)mad.f16 hr17.z, hr36.y, hr33.y, (last)hr17.z
mad.f16 hr15.z, hr36.y, hr33.z, (last)hr15.z
mad.f16 hr13.z, hr36.y, hr33.w, (last)hr13.z
mad.f16 hr11.z, hr36.y, hr34.x, (last)hr11.z
mad.f16 hr17.w, hr36.z, hr33.y, (last)hr17.w
mad.f16 hr15.w, hr36.z, hr33.z, (last)hr15.w
mad.f16 hr13.w, hr36.z, hr33.w, (last)hr13.w
mad.f16 hr11.w, hr36.z, hr34.x, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr36.w, hr33.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr36.w, hr33.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr36.w, hr33.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr36.w, hr34.x, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr33.y, r20.y, s#0, t#0
mad.f16 hr9.z, hr36.y, hr35.y, (last)hr9.z
mad.f16 hr7.z, hr36.y, hr35.z, (last)hr7.z
mad.f16 hr5.z, hr36.y, hr35.w, (last)hr5.z
mad.f16 hr9.w, hr36.z, hr35.y, (last)hr9.w
mad.f16 hr7.w, hr36.z, hr35.z, (last)hr7.w
mad.f16 hr5.w, hr36.z, hr35.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr36.w, hr35.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr36.w, hr35.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr36.w, hr35.w, (r)(last)hr6.x
(rpt1)mad.f16 hr34.y, (r)(last)hr34.y, hr36.x, (r)(last)hr30.y
(rpt1)mad.f16 hr34.w, (r)(last)hr34.w, hr36.x, (r)(last)hr30.w
ldl.u16 r30.y, l[r10.y+1664], 4
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr36.x, (r)(last)hr32.y
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr36.x, (r)(last)hr32.w
isam.v.base0 (u16)(xyzw)hr35.y, r20.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr37.y, r0.y, s#0, t#0
isam.v.base0 (u16)(xyzw)hr39.y, r0.z, s#0, t#0
ldl.u16 r32.y, l[r10.y+1728], 4
mad.f16 hr18.z, hr21.y, hr3.z, (last)hr18.z
mad.f16 hr16.z, hr21.y, hr3.w, (last)hr16.z
mad.f16 hr14.z, hr21.y, hr4.x, (last)hr14.z
mad.f16 hr12.z, hr21.y, hr4.y, (last)hr12.z
mad.f16 hr18.w, hr21.z, hr3.z, (last)hr18.w
mad.f16 hr16.w, hr21.z, hr3.w, (last)hr16.w
mad.f16 hr14.w, hr21.z, hr4.x, (last)hr14.w
mad.f16 hr12.w, hr21.z, hr4.y, (last)hr12.w
mad.f16 hr19.x, hr21.w, hr3.z, (last)hr19.x
mad.f16 hr17.x, hr21.w, hr3.w, (last)hr17.x
mad.f16 hr15.x, hr21.w, hr4.x, (last)hr15.x
mad.f16 hr13.x, hr21.w, hr4.y, (last)hr13.x
mad.f16 hr19.y, hr22.x, hr3.z, (last)hr19.y
mad.f16 hr17.y, hr22.x, hr3.w, (last)hr17.y
mad.f16 hr15.y, hr22.x, hr4.x, (last)hr15.y
mad.f16 hr13.y, hr22.x, hr4.y, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr21.y, hr22.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr21.w, hr22.y, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr21.y, hr22.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr21.w, hr22.z, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr21.y, hr22.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr21.w, hr22.w, (r)(last)hr7.x
mad.f16 hr17.z, hr23.y, hr3.z, (last)hr17.z
mad.f16 hr15.z, hr23.y, hr3.w, (last)hr15.z
mad.f16 hr13.z, hr23.y, hr4.x, (last)hr13.z
mad.f16 hr11.z, hr23.y, hr4.y, (last)hr11.z
mad.f16 hr17.w, hr23.z, hr3.z, (last)hr17.w
mad.f16 hr15.w, hr23.z, hr3.w, (last)hr15.w
mad.f16 hr13.w, hr23.z, hr4.x, (last)hr13.w
mad.f16 hr11.w, hr23.z, hr4.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr23.w, hr3.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr23.w, hr3.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr23.w, hr4.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr23.w, hr4.y, (r)(last)hr12.x
mad.f16 hr9.z, hr23.y, hr22.y, (last)hr9.z
mad.f16 hr7.z, hr23.y, hr22.z, (last)hr7.z
mad.f16 hr5.z, hr23.y, hr22.w, (last)hr5.z
mad.f16 hr9.w, hr23.z, hr22.y, (last)hr9.w
mad.f16 hr7.w, hr23.z, hr22.z, (last)hr7.w
mad.f16 hr5.w, hr23.z, hr22.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr23.w, hr22.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr23.w, hr22.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr23.w, hr22.w, (r)(last)hr6.x
(rpt1)mad.f16 hr21.y, (r)(last)hr21.y, hr23.x, (r)(last)hr34.y
(rpt1)mad.f16 hr21.w, (r)(last)hr21.w, hr23.x, (r)(last)hr34.w
ldl.u16 r34.y, l[r10.y+1792], 4
(rpt1)mad.f16 hr23.y, (r)(last)hr23.y, hr23.x, (r)(last)hr36.y
(rpt1)mad.f16 hr23.w, (r)(last)hr23.w, hr23.x, (r)(last)hr36.w
ldl.u16 r36.y, l[r10.y+1856], 4
ldl.u16 r38.y, l[r10.y+1920], 4
(sy)mad.f16 hr18.z, hr26.y, hr24.y, (last)hr18.z
ldl.u16 r40.y, l[r10.y+1984], 4
mad.f16 hr16.z, hr26.y, hr24.z, (last)hr16.z
mad.f16 hr14.z, hr26.y, hr24.w, (last)hr14.z
mad.f16 hr12.z, hr26.y, hr25.x, (last)hr12.z
mad.f16 hr18.w, hr26.z, hr24.y, (last)hr18.w
mad.f16 hr16.w, hr26.z, hr24.z, (last)hr16.w
mad.f16 hr14.w, hr26.z, hr24.w, (last)hr14.w
mad.f16 hr12.w, hr26.z, hr25.x, (last)hr12.w
mad.f16 hr19.x, hr26.w, hr24.y, (last)hr19.x
mad.f16 hr17.x, hr26.w, hr24.z, (last)hr17.x
mad.f16 hr15.x, hr26.w, hr24.w, (last)hr15.x
mad.f16 hr13.x, hr26.w, hr25.x, (last)hr13.x
mad.f16 hr19.y, hr27.x, hr24.y, (last)hr19.y
mad.f16 hr17.y, hr27.x, hr24.z, (last)hr17.y
mad.f16 hr15.y, hr27.x, hr24.w, (last)hr15.y
mad.f16 hr13.y, hr27.x, hr25.x, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr26.y, hr27.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr26.w, hr27.y, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr26.y, hr27.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr26.w, hr27.z, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr26.y, hr27.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr26.w, hr27.w, (r)(last)hr7.x
mad.f16 hr17.z, hr28.y, hr24.y, (last)hr17.z
mad.f16 hr15.z, hr28.y, hr24.z, (last)hr15.z
mad.f16 hr13.z, hr28.y, hr24.w, (last)hr13.z
mad.f16 hr11.z, hr28.y, hr25.x, (last)hr11.z
mad.f16 hr17.w, hr28.z, hr24.y, (last)hr17.w
mad.f16 hr15.w, hr28.z, hr24.z, (last)hr15.w
mad.f16 hr13.w, hr28.z, hr24.w, (last)hr13.w
mad.f16 hr11.w, hr28.z, hr25.x, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr28.w, hr24.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr28.w, hr24.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr28.w, hr24.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr28.w, hr25.x, (r)(last)hr12.x
mad.f16 hr9.z, hr28.y, hr27.y, (last)hr9.z
mad.f16 hr7.z, hr28.y, hr27.z, (last)hr7.z
mad.f16 hr5.z, hr28.y, hr27.w, (last)hr5.z
mad.f16 hr9.w, hr28.z, hr27.y, (last)hr9.w
mad.f16 hr7.w, hr28.z, hr27.z, (last)hr7.w
mad.f16 hr5.w, hr28.z, hr27.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr28.w, hr27.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr28.w, hr27.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr28.w, hr27.w, (r)(last)hr6.x
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr28.x, (r)(last)hr21.y
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr28.x, (r)(last)hr21.w
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr28.x, (r)(last)hr23.y
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr28.x, (r)(last)hr23.w
(ss)mad.f16 hr18.z, hr30.y, hr29.y, (last)hr18.z
mad.f16 hr16.z, hr30.y, hr29.z, (last)hr16.z
mad.f16 hr14.z, hr30.y, hr29.w, (last)hr14.z
mad.f16 hr12.z, hr30.y, hr30.x, (last)hr12.z
mad.f16 hr18.w, hr30.z, hr29.y, (last)hr18.w
mad.f16 hr16.w, hr30.z, hr29.z, (last)hr16.w
mad.f16 hr14.w, hr30.z, hr29.w, (last)hr14.w
mad.f16 hr12.w, hr30.z, hr30.x, (last)hr12.w
mad.f16 hr19.x, hr30.w, hr29.y, (last)hr19.x
mad.f16 hr17.x, hr30.w, hr29.z, (last)hr17.x
mad.f16 hr15.x, hr30.w, hr29.w, (last)hr15.x
mad.f16 hr13.x, hr30.w, hr30.x, (last)hr13.x
mad.f16 hr19.y, hr31.x, hr29.y, (last)hr19.y
mad.f16 hr17.y, hr31.x, hr29.z, (last)hr17.y
mad.f16 hr15.y, hr31.x, hr29.w, (last)hr15.y
mad.f16 hr13.y, hr31.x, hr30.x, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr30.y, hr31.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr30.w, hr31.y, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr30.y, hr31.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr30.w, hr31.z, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr30.y, hr31.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr30.w, hr31.w, (r)(last)hr7.x
mad.f16 hr17.z, hr32.y, hr29.y, (last)hr17.z
mad.f16 hr15.z, hr32.y, hr29.z, (last)hr15.z
mad.f16 hr13.z, hr32.y, hr29.w, (last)hr13.z
mad.f16 hr11.z, hr32.y, hr30.x, (last)hr11.z
mad.f16 hr17.w, hr32.z, hr29.y, (last)hr17.w
mad.f16 hr15.w, hr32.z, hr29.z, (last)hr15.w
mad.f16 hr13.w, hr32.z, hr29.w, (last)hr13.w
mad.f16 hr11.w, hr32.z, hr30.x, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr32.w, hr29.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr32.w, hr29.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr32.w, hr29.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr32.w, hr30.x, (r)(last)hr12.x
mad.f16 hr9.z, hr32.y, hr31.y, (last)hr9.z
mad.f16 hr7.z, hr32.y, hr31.z, (last)hr7.z
mad.f16 hr5.z, hr32.y, hr31.w, (last)hr5.z
mad.f16 hr9.w, hr32.z, hr31.y, (last)hr9.w
mad.f16 hr7.w, hr32.z, hr31.z, (last)hr7.w
mad.f16 hr5.w, hr32.z, hr31.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr32.w, hr31.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr32.w, hr31.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr32.w, hr31.w, (r)(last)hr6.x
(rpt1)mad.f16 hr30.y, (r)(last)hr30.y, hr32.x, (r)(last)hr26.y
(rpt1)mad.f16 hr30.w, (r)(last)hr30.w, hr32.x, (r)(last)hr26.w
(rpt1)mad.f16 hr32.y, (r)(last)hr32.y, hr32.x, (r)(last)hr28.y
(rpt1)mad.f16 hr32.w, (r)(last)hr32.w, hr32.x, (r)(last)hr28.w
mad.f16 hr18.z, hr34.y, hr33.y, (last)hr18.z
mad.f16 hr16.z, hr34.y, hr33.z, (last)hr16.z
mad.f16 hr14.z, hr34.y, hr33.w, (last)hr14.z
mad.f16 hr12.z, hr34.y, hr34.x, (last)hr12.z
mad.f16 hr18.w, hr34.z, hr33.y, (last)hr18.w
mad.f16 hr16.w, hr34.z, hr33.z, (last)hr16.w
mad.f16 hr14.w, hr34.z, hr33.w, (last)hr14.w
mad.f16 hr12.w, hr34.z, hr34.x, (last)hr12.w
mad.f16 hr19.x, hr34.w, hr33.y, (last)hr19.x
mad.f16 hr17.x, hr34.w, hr33.z, (last)hr17.x
mad.f16 hr15.x, hr34.w, hr33.w, (last)hr15.x
mad.f16 hr13.x, hr34.w, hr34.x, (last)hr13.x
mad.f16 hr19.y, hr35.x, hr33.y, (last)hr19.y
mad.f16 hr17.y, hr35.x, hr33.z, (last)hr17.y
mad.f16 hr15.y, hr35.x, hr33.w, (last)hr15.y
mad.f16 hr13.y, hr35.x, hr34.x, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr34.y, hr35.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr34.w, hr35.y, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr34.y, hr35.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr34.w, hr35.z, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr34.y, hr35.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr34.w, hr35.w, (r)(last)hr7.x
mad.f16 hr17.z, hr36.y, hr33.y, (last)hr17.z
mad.f16 hr15.z, hr36.y, hr33.z, (last)hr15.z
mad.f16 hr13.z, hr36.y, hr33.w, (last)hr13.z
mad.f16 hr11.z, hr36.y, hr34.x, (last)hr11.z
mad.f16 hr17.w, hr36.z, hr33.y, (last)hr17.w
mad.f16 hr15.w, hr36.z, hr33.z, (last)hr15.w
mad.f16 hr13.w, hr36.z, hr33.w, (last)hr13.w
mad.f16 hr11.w, hr36.z, hr34.x, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr36.w, hr33.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr36.w, hr33.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr36.w, hr33.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr36.w, hr34.x, (r)(last)hr12.x
mad.f16 hr9.z, hr36.y, hr35.y, (last)hr9.z
mad.f16 hr7.z, hr36.y, hr35.z, (last)hr7.z
mad.f16 hr5.z, hr36.y, hr35.w, (last)hr5.z
mad.f16 hr9.w, hr36.z, hr35.y, (last)hr9.w
mad.f16 hr7.w, hr36.z, hr35.z, (last)hr7.w
mad.f16 hr5.w, hr36.z, hr35.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr36.w, hr35.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr36.w, hr35.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr36.w, hr35.w, (r)(last)hr6.x
(rpt1)mad.f16 hr34.y, (r)(last)hr34.y, hr36.x, (r)(last)hr30.y
(rpt1)mad.f16 hr34.w, (r)(last)hr34.w, hr36.x, (r)(last)hr30.w
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr36.x, (r)(last)hr32.y
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr36.x, (r)(last)hr32.w
fence.r.w
(sy)(ss)mad.f16 hr18.z, hr38.y, hr37.y, (last)hr18.z
mad.f16 hr16.z, hr38.y, hr37.z, (last)hr16.z
mad.f16 hr14.z, hr38.y, hr37.w, (last)hr14.z
mad.f16 hr12.z, hr38.y, hr38.x, (last)hr12.z
mad.f16 hr18.w, hr38.z, hr37.y, (last)hr18.w
mad.f16 hr16.w, hr38.z, hr37.z, (last)hr16.w
mad.f16 hr14.w, hr38.z, hr37.w, (last)hr14.w
mad.f16 hr12.w, hr38.z, hr38.x, (last)hr12.w
mad.f16 hr19.x, hr38.w, hr37.y, (last)hr19.x
mad.f16 hr17.x, hr38.w, hr37.z, (last)hr17.x
mad.f16 hr15.x, hr38.w, hr37.w, (last)hr15.x
mad.f16 hr13.x, hr38.w, hr38.x, (last)hr13.x
mad.f16 hr19.y, hr39.x, hr37.y, (last)hr19.y
mad.f16 hr17.y, hr39.x, hr37.z, (last)hr17.y
mad.f16 hr15.y, hr39.x, hr37.w, (last)hr15.y
mad.f16 hr13.y, hr39.x, hr38.x, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr38.y, hr39.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr38.w, hr39.y, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr38.y, hr39.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr38.w, hr39.z, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr38.y, hr39.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr38.w, hr39.w, (r)(last)hr7.x
mad.f16 hr17.z, hr40.y, hr37.y, (last)hr17.z
mad.f16 hr15.z, hr40.y, hr37.z, (last)hr15.z
mad.f16 hr13.z, hr40.y, hr37.w, (last)hr13.z
mad.f16 hr11.z, hr40.y, hr38.x, (last)hr11.z
mad.f16 hr17.w, hr40.z, hr37.y, (last)hr17.w
mad.f16 hr15.w, hr40.z, hr37.z, (last)hr15.w
mad.f16 hr13.w, hr40.z, hr37.w, (last)hr13.w
mad.f16 hr11.w, hr40.z, hr38.x, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr40.w, hr37.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr40.w, hr37.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr40.w, hr37.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr40.w, hr38.x, (r)(last)hr12.x
mad.f16 hr9.z, hr40.y, hr39.y, (last)hr9.z
mad.f16 hr7.z, hr40.y, hr39.z, (last)hr7.z
mad.f16 hr5.z, hr40.y, hr39.w, (last)hr5.z
mad.f16 hr9.w, hr40.z, hr39.y, (last)hr9.w
mad.f16 hr7.w, hr40.z, hr39.z, (last)hr7.w
mad.f16 hr5.w, hr40.z, hr39.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr40.w, hr39.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr40.w, hr39.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr40.w, hr39.w, (r)(last)hr6.x
(rpt1)mad.f16 hr4.z, (r)(last)hr38.y, hr40.x, (r)(last)hr34.y
(rpt1)mad.f16 hr5.x, (r)(last)hr38.w, hr40.x, (r)(last)hr34.w
(rpt1)mad.f16 hr3.z, (r)(last)hr40.y, hr40.x, (r)(last)hr36.y
(rpt1)mad.f16 hr4.x, (r)(last)hr40.w, hr40.x, (r)(last)hr36.w
bar.g
(sy)(ss)br p0.x, #l1041
jump #l130
l1041:
(jp)(eolm)nop
(nop3) add.u r12.w, r51.w, (last)r12.w
(nop3) shl.b r12.w, (last)r12.w, 9
(nop3) sad.s32 r12.w, r52.z, r12.w, (last)r1.y
(nop3) shl.b r12.w, (last)r12.w, 2
add.u r0.x, r12.w, c1.x
add.u r0.y, r12.w, c4.w
add.u r0.z, r12.w, c4.z
add.u r0.w, r12.w, c5.x
stib.b.untyped.1d.u16.4.imm.base0 hr18.z, r12.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r12.w+32, 4
(ss)(rpt1)add.u r8.w, r12.w, (r)c10.x
nop
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r0.x, 4
(ss)(rpt1)add.u r8.y, r12.w, (r)c9.z
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r0.y, 4
(ss)(rpt1)add.u r7.w, r12.w, (r)c9.x
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r0.z, 4
(ss)add.u r7.y, r12.w, c5.z
add.u r7.z, r12.w, c8.w
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r0.w, 4
(ss)add.u r6.w, r12.w, c4.y
(nop3) add.u r7.x, (last)r12.w, c5.y
(rpt1)nop
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r6.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r7.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r7.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r7.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r7.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r8.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r8.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r8.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r8.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r9.x, 4
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
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1308 instr, 28 nops, 1280 non-nops, 65 mov, 0 cov, 2176 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 21 full, 12 constlen
; CL prog 23/1: 31 cat0, 65 cat1, 90 cat2, 1030 cat3, 0 cat4, 36 cat5, 52 cat6, 4 cat7
; CL prog 23/1: 26 sstall, 23 (ss), 230 systall, 13 (sy), 1 loops
; CL prog 23/1: 12 max_waves, 0 double_threadsize
; 58 preamble-instr, 1 early-preamble
