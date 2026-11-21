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
mov.u16u16 hr2.x, 0
mov.u16u16 hr2.y, 0
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
mov.u16u16 hr3.w, 0
mov.u16u16 hr3.z, 0
mov.u16u16 hr3.y, 0
mov.u16u16 hr3.x, 0
mov.u16u16 hr2.w, 0
mov.u16u16 hr2.z, 0
and.b r0.x, (last)r0.x, 15
l101:
(rpt1)shr.b r54.y, (r)r53.z, 2
shl.b r54.w, r54.x, 9
add.u r54.x, r54.x, 4
cmps.u.ge up0.x, r54.x, c1.x
(ss)(nop2) sad.s32 r9.x, r54.w, r0.w, r54.y
sad.s32 r9.y, r54.w, r0.x, r54.z
(nop2) shl.b r9.x, (last)r9.x, 2
shl.b r9.y, (last)r9.y, 2
add.u r10.x, r9.x, c1.x
add.u r10.y, r9.x, c3.y
add.u r10.z, r9.x, c1.z
isam.v.base0 (u16)(xyzw)hr19.x, r9.x, s#0, t#0
isam.v.base0 (u16)(xyzw)hr26.x, r9.x+32, s#0, t#0
add.u r11.x, r9.y, c1.x
add.u r11.y, r9.y, c2.y
add.u r10.w, r9.x, c3.x
isam.v.base0 (u16)(xyzw)hr27.y, r9.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr28.y, r9.y+64, s#0, t#2
add.u r11.z, r9.y, c1.z
isam.v.base0 (u16)(xyzw)hr29.y, r10.x, s#0, t#0
add.u r11.w, r9.y, c2.x
isam.v.base0 (u16)(xyzw)hr30.y, r10.y, s#0, t#0
add.u r12.x, r9.x, c1.y
add.u r12.y, (last)r9.x, c2.w
isam.v.base0 (u16)(xyzw)hr0.z, r11.x, s#0, t#2
add.u r12.z, r9.y, c1.y
add.u r12.w, (last)r9.y, c1.w
(sy)mad.f16 hr17.x, hr27.y, hr19.x, (last)hr17.x
mad.f16 hr15.x, hr27.y, hr19.y, (last)hr15.x
mad.f16 hr13.x, hr27.y, hr19.z, (last)hr13.x
mad.f16 hr11.x, hr27.y, hr19.w, (last)hr11.x
mad.f16 hr9.x, hr27.y, hr26.x, (last)hr9.x
mad.f16 hr7.x, hr27.y, hr26.y, (last)hr7.x
mad.f16 hr5.x, hr27.y, hr26.z, (last)hr5.x
mad.f16 hr17.y, hr27.z, hr19.x, (last)hr17.y
mad.f16 hr15.y, hr27.z, hr19.y, (last)hr15.y
mad.f16 hr13.y, hr27.z, hr19.z, (last)hr13.y
mad.f16 hr11.y, hr27.z, hr19.w, (last)hr11.y
mad.f16 hr9.y, hr27.z, hr26.x, (last)hr9.y
mad.f16 hr7.y, hr27.z, hr26.y, (last)hr7.y
mad.f16 hr5.y, hr27.z, hr26.z, (last)hr5.y
(rpt1)mad.f16 hr16.z, (r)hr28.w, hr19.x, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr28.w, hr19.y, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr28.w, hr19.z, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr28.w, hr19.w, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr28.w, hr26.x, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr28.w, hr26.y, (r)(last)hr6.z
(rpt1)mad.f16 hr4.z, (r)hr28.w, hr26.z, (r)(last)hr4.z
(rpt1)mad.f16 hr27.y, (r)(last)hr27.y, hr26.w, (r)(last)hr3.x
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr26.w, (r)(last)hr2.z
isam.v.base0 (u16)(xyzw)hr2.z, r11.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr18.x, r10.z, s#0, t#0
mad.f16 hr17.z, hr27.w, hr19.x, (last)hr17.z
mad.f16 hr15.z, hr27.w, hr19.y, (last)hr15.z
mad.f16 hr13.z, hr27.w, hr19.z, (last)hr13.z
mad.f16 hr11.z, hr27.w, hr19.w, (last)hr11.z
mad.f16 hr17.w, hr28.x, hr19.x, (last)hr17.w
mad.f16 hr15.w, hr28.x, hr19.y, (last)hr15.w
mad.f16 hr13.w, hr28.x, hr19.z, (last)hr13.w
mad.f16 hr11.w, hr28.x, hr19.w, (last)hr11.w
mad.f16 hr16.x, hr28.y, hr19.x, (last)hr16.x
mad.f16 hr14.x, hr28.y, hr19.y, (last)hr14.x
mad.f16 hr12.x, hr28.y, hr19.z, (last)hr12.x
mad.f16 hr10.x, hr28.y, hr19.w, (last)hr10.x
mad.f16 hr16.y, hr28.z, hr19.x, (last)hr16.y
mad.f16 hr14.y, hr28.z, hr19.y, (last)hr14.y
mad.f16 hr12.y, hr28.z, hr19.z, (last)hr12.y
mad.f16 hr10.y, hr28.z, hr19.w, (last)hr10.y
isam.v.base0 (u16)(xyzw)hr19.x, r10.w, s#0, t#0
(ss)nop
isam.v.base0 (u16)(xyzw)hr20.y, r11.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr21.y, r11.w, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr22.y, r12.x, s#0, t#0
(ss)nop
isam.v.base0 (u16)(xyzw)hr23.y, r12.y, s#0, t#0
(ss)nop
isam.v.base0 (u16)(xyzw)hr24.z, r12.z, s#0, t#2
mad.f16 hr9.z, hr27.w, hr26.x, (last)hr9.z
mad.f16 hr7.z, hr27.w, hr26.y, (last)hr7.z
mad.f16 hr9.w, hr28.x, hr26.x, (last)hr9.w
mad.f16 hr7.w, hr28.x, hr26.y, (last)hr7.w
mad.f16 hr8.x, hr28.y, hr26.x, (last)hr8.x
mad.f16 hr6.x, hr28.y, hr26.y, (last)hr6.x
mad.f16 hr8.y, hr28.z, hr26.x, (last)hr8.y
mad.f16 hr6.y, hr28.z, hr26.y, (last)hr6.y
isam.v.base0 (u16)(xyzw)hr25.z, r12.w, s#0, t#2
(rpt1)mad.f16 hr5.z, (r)hr27.w, hr26.z, (r)(last)hr5.z
(rpt1)mad.f16 hr4.x, (r)hr28.y, hr26.z, (r)(last)hr4.x
(rpt1)mad.f16 hr27.w, (r)(last)hr27.w, hr26.w, (r)(last)hr3.z
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr26.w, (r)(last)hr2.x
mad.f16 hr17.x, hr0.z, hr29.y, (last)hr17.x
mad.f16 hr15.x, hr0.z, hr29.z, (last)hr15.x
mad.f16 hr13.x, hr0.z, hr29.w, (last)hr13.x
mad.f16 hr11.x, hr0.z, hr30.x, (last)hr11.x
mad.f16 hr9.x, hr0.z, hr30.y, (last)hr9.x
mad.f16 hr7.x, hr0.z, hr30.z, (last)hr7.x
mad.f16 hr5.x, hr0.z, hr30.w, (last)hr5.x
mad.f16 hr17.y, hr0.w, hr29.y, (last)hr17.y
mad.f16 hr15.y, hr0.w, hr29.z, (last)hr15.y
mad.f16 hr13.y, hr0.w, hr29.w, (last)hr13.y
mad.f16 hr11.y, hr0.w, hr30.x, (last)hr11.y
mad.f16 hr9.y, hr0.w, hr30.y, (last)hr9.y
mad.f16 hr7.y, hr0.w, hr30.z, (last)hr7.y
mad.f16 hr5.y, hr0.w, hr30.w, (last)hr5.y
mad.f16 hr17.z, hr1.x, hr29.y, (last)hr17.z
mad.f16 hr15.z, hr1.x, hr29.z, (last)hr15.z
mad.f16 hr13.z, hr1.x, hr29.w, (last)hr13.z
mad.f16 hr11.z, hr1.x, hr30.x, (last)hr11.z
mad.f16 hr17.w, hr1.y, hr29.y, (last)hr17.w
mad.f16 hr15.w, hr1.y, hr29.z, (last)hr15.w
mad.f16 hr13.w, hr1.y, hr29.w, (last)hr13.w
mad.f16 hr11.w, hr1.y, hr30.x, (last)hr11.w
mad.f16 hr9.z, hr1.x, hr30.y, (last)hr9.z
mad.f16 hr7.z, hr1.x, hr30.z, (last)hr7.z
mad.f16 hr9.w, hr1.y, hr30.y, (last)hr9.w
mad.f16 hr7.w, hr1.y, hr30.z, (last)hr7.w
(rpt1)mad.f16 hr5.z, (r)hr1.x, hr30.w, (r)(last)hr5.z
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr31.x, (r)(last)hr27.y
mad.f16 hr1.x, (last)hr1.x, hr31.x, (last)hr27.w
(sy)(rpt1)mad.f16 hr16.z, (r)hr3.x, hr29.y, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr3.x, hr29.z, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr3.x, hr29.w, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr3.x, hr30.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr3.x, hr30.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr3.x, hr30.z, (r)(last)hr6.z
(rpt1)mad.f16 hr4.z, (r)hr3.x, hr30.w, (r)(last)hr4.z
mad.f16 hr16.x, hr2.z, hr29.y, (last)hr16.x
mad.f16 hr14.x, hr2.z, hr29.z, (last)hr14.x
mad.f16 hr12.x, hr2.z, hr29.w, (last)hr12.x
mad.f16 hr10.x, hr2.z, hr30.x, (last)hr10.x
mad.f16 hr16.y, hr2.w, hr29.y, (last)hr16.y
mad.f16 hr14.y, hr2.w, hr29.z, (last)hr14.y
mad.f16 hr12.y, hr2.w, hr29.w, (last)hr12.y
mad.f16 hr10.y, hr2.w, hr30.x, (last)hr10.y
mad.f16 hr8.x, hr2.z, hr30.y, (last)hr8.x
mad.f16 hr6.x, hr2.z, hr30.z, (last)hr6.x
mad.f16 hr8.y, hr2.w, hr30.y, (last)hr8.y
mad.f16 hr6.y, hr2.w, hr30.z, (last)hr6.y
(rpt1)mad.f16 hr4.x, (r)hr2.z, hr30.w, (r)(last)hr4.x
mad.f16 hr1.y, (last)hr1.y, hr31.x, (last)hr28.x
(rpt1)mad.f16 hr3.x, (r)(last)hr3.x, hr31.x, (r)(last)hr28.w
(rpt1)mad.f16 hr2.z, (r)(last)hr2.z, hr31.x, (r)(last)hr28.y
mad.f16 hr17.x, hr20.y, hr18.x, (last)hr17.x
mad.f16 hr15.x, hr20.y, hr18.y, (last)hr15.x
mad.f16 hr13.x, hr20.y, hr18.z, (last)hr13.x
mad.f16 hr11.x, hr20.y, hr18.w, (last)hr11.x
mad.f16 hr9.x, hr20.y, hr19.x, (last)hr9.x
mad.f16 hr7.x, hr20.y, hr19.y, (last)hr7.x
mad.f16 hr5.x, hr20.y, hr19.z, (last)hr5.x
mad.f16 hr17.y, hr20.z, hr18.x, (last)hr17.y
mad.f16 hr15.y, hr20.z, hr18.y, (last)hr15.y
mad.f16 hr13.y, hr20.z, hr18.z, (last)hr13.y
mad.f16 hr11.y, hr20.z, hr18.w, (last)hr11.y
mad.f16 hr9.y, hr20.z, hr19.x, (last)hr9.y
mad.f16 hr7.y, hr20.z, hr19.y, (last)hr7.y
mad.f16 hr5.y, hr20.z, hr19.z, (last)hr5.y
mad.f16 hr17.z, hr20.w, hr18.x, (last)hr17.z
mad.f16 hr15.z, hr20.w, hr18.y, (last)hr15.z
mad.f16 hr13.z, hr20.w, hr18.z, (last)hr13.z
mad.f16 hr11.z, hr20.w, hr18.w, (last)hr11.z
mad.f16 hr17.w, hr21.x, hr18.x, (last)hr17.w
mad.f16 hr15.w, hr21.x, hr18.y, (last)hr15.w
mad.f16 hr13.w, hr21.x, hr18.z, (last)hr13.w
mad.f16 hr11.w, hr21.x, hr18.w, (last)hr11.w
mad.f16 hr9.z, hr20.w, hr19.x, (last)hr9.z
mad.f16 hr7.z, hr20.w, hr19.y, (last)hr7.z
mad.f16 hr9.w, hr21.x, hr19.x, (last)hr9.w
mad.f16 hr7.w, hr21.x, hr19.y, (last)hr7.w
(rpt1)mad.f16 hr5.z, (r)hr20.w, hr19.z, (r)(last)hr5.z
(rpt1)mad.f16 hr16.z, (r)hr21.w, hr18.x, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr21.w, hr18.y, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr21.w, hr18.z, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr21.w, hr18.w, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr21.w, hr19.x, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr21.w, hr19.y, (r)(last)hr6.z
(rpt1)mad.f16 hr4.z, (r)hr21.w, hr19.z, (r)(last)hr4.z
mad.f16 hr16.x, hr21.y, hr18.x, (last)hr16.x
mad.f16 hr14.x, hr21.y, hr18.y, (last)hr14.x
mad.f16 hr12.x, hr21.y, hr18.z, (last)hr12.x
mad.f16 hr10.x, hr21.y, hr18.w, (last)hr10.x
mad.f16 hr16.y, hr21.z, hr18.x, (last)hr16.y
mad.f16 hr14.y, hr21.z, hr18.y, (last)hr14.y
mad.f16 hr12.y, hr21.z, hr18.z, (last)hr12.y
mad.f16 hr10.y, hr21.z, hr18.w, (last)hr10.y
mad.f16 hr8.x, hr21.y, hr19.x, (last)hr8.x
mad.f16 hr6.x, hr21.y, hr19.y, (last)hr6.x
mad.f16 hr8.y, hr21.z, hr19.x, (last)hr8.y
mad.f16 hr6.y, hr21.z, hr19.y, (last)hr6.y
(rpt1)mad.f16 hr4.x, (r)hr21.y, hr19.z, (r)(last)hr4.x
(rpt1)mad.f16 hr20.y, (r)(last)hr20.y, hr19.w, (r)(last)hr0.z
(rpt1)mad.f16 hr20.w, (r)(last)hr20.w, hr19.w, (r)(last)hr1.x
(rpt1)mad.f16 hr21.w, (r)(last)hr21.w, hr19.w, (r)(last)hr3.x
(rpt1)mad.f16 hr21.y, (r)(last)hr21.y, hr19.w, (r)(last)hr2.z
mad.f16 hr17.x, hr24.z, hr22.y, (last)hr17.x
mad.f16 hr15.x, hr24.z, hr22.z, (last)hr15.x
mad.f16 hr13.x, hr24.z, hr22.w, (last)hr13.x
mad.f16 hr11.x, hr24.z, hr23.x, (last)hr11.x
mad.f16 hr9.x, hr24.z, hr23.y, (last)hr9.x
mad.f16 hr7.x, hr24.z, hr23.z, (last)hr7.x
mad.f16 hr5.x, hr24.z, hr23.w, (last)hr5.x
mad.f16 hr17.y, hr24.w, hr22.y, (last)hr17.y
mad.f16 hr15.y, hr24.w, hr22.z, (last)hr15.y
mad.f16 hr13.y, hr24.w, hr22.w, (last)hr13.y
mad.f16 hr11.y, hr24.w, hr23.x, (last)hr11.y
mad.f16 hr9.y, hr24.w, hr23.y, (last)hr9.y
mad.f16 hr7.y, hr24.w, hr23.z, (last)hr7.y
mad.f16 hr5.y, hr24.w, hr23.w, (last)hr5.y
mad.f16 hr17.z, hr25.x, hr22.y, (last)hr17.z
mad.f16 hr15.z, hr25.x, hr22.z, (last)hr15.z
mad.f16 hr13.z, hr25.x, hr22.w, (last)hr13.z
mad.f16 hr11.z, hr25.x, hr23.x, (last)hr11.z
mad.f16 hr17.w, hr25.y, hr22.y, (last)hr17.w
mad.f16 hr15.w, hr25.y, hr22.z, (last)hr15.w
mad.f16 hr13.w, hr25.y, hr22.w, (last)hr13.w
mad.f16 hr11.w, hr25.y, hr23.x, (last)hr11.w
mad.f16 hr9.z, hr25.x, hr23.y, (last)hr9.z
mad.f16 hr7.z, hr25.x, hr23.z, (last)hr7.z
mad.f16 hr9.w, hr25.y, hr23.y, (last)hr9.w
mad.f16 hr7.w, hr25.y, hr23.z, (last)hr7.w
(rpt1)mad.f16 hr5.z, (r)hr25.x, hr23.w, (r)(last)hr5.z
(rpt1)mad.f16 hr16.z, (r)hr26.x, hr22.y, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr26.x, hr22.z, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr26.x, hr22.w, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr26.x, hr23.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr26.x, hr23.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr26.x, hr23.z, (r)(last)hr6.z
(rpt1)mad.f16 hr4.z, (r)hr26.x, hr23.w, (r)(last)hr4.z
mad.f16 hr16.x, hr25.z, hr22.y, (last)hr16.x
mad.f16 hr14.x, hr25.z, hr22.z, (last)hr14.x
mad.f16 hr12.x, hr25.z, hr22.w, (last)hr12.x
mad.f16 hr10.x, hr25.z, hr23.x, (last)hr10.x
mad.f16 hr16.y, hr25.w, hr22.y, (last)hr16.y
mad.f16 hr14.y, hr25.w, hr22.z, (last)hr14.y
mad.f16 hr12.y, hr25.w, hr22.w, (last)hr12.y
mad.f16 hr10.y, hr25.w, hr23.x, (last)hr10.y
mad.f16 hr8.x, hr25.z, hr23.y, (last)hr8.x
mad.f16 hr6.x, hr25.z, hr23.z, (last)hr6.x
mad.f16 hr8.y, hr25.w, hr23.y, (last)hr8.y
mad.f16 hr6.y, hr25.w, hr23.z, (last)hr6.y
(rpt1)mad.f16 hr4.x, (r)hr25.z, hr23.w, (r)(last)hr4.x
(rpt1)mad.f16 hr3.z, (r)(last)hr25.x, hr24.x, (r)(last)hr20.w
(rpt1)mad.f16 hr3.x, (r)(last)hr24.z, hr24.x, (r)(last)hr20.y
mad.f16 hr2.x, (last)hr25.z, hr24.x, (last)hr21.y
mad.f16 hr2.z, (last)hr26.x, hr24.x, (last)hr21.w
mad.f16 hr2.y, (last)hr25.w, hr24.x, (last)hr21.z
mad.f16 hr2.w, (last)hr26.y, hr24.x, (last)hr22.x
br p0.x, #l350
jump #l101
l350:
(jp)(nop3) shl.b r0.w, (last)r0.w, 2
(nop3) add.u r0.w, r53.z, (last)r0.w
(nop3) shl.b r0.w, (last)r0.w, 9
(nop3) sad.s32 r0.w, r54.z, r0.w, (last)r0.x
(nop3) shl.b r0.w, (last)r0.w, 2
add.u r13.y, r0.w, c1.x
add.u r13.z, r0.w, c2.y
add.u r13.w, r0.w, c1.z
add.u r14.x, r0.w, c2.x
add.u r14.y, r0.w, c1.y
add.u r14.z, r0.w, c1.w
add.u r14.w, r0.w, c2.z
add.u r15.x, r0.w, c3.z
stib.b.untyped.1d.u16.4.imm.base0 hr17.x, r0.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.x, r0.w+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.x, r13.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.x, r13.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr13.x, r13.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr12.x, r14.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr11.x, r14.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr10.x, r14.z, 4
(ss)(rpt1)add.u r5.x, r0.w, (r)c4.w
stib.b.untyped.1d.u16.4.imm.base0 hr9.x, r14.w, 4
(ss)(rpt1)add.u r4.z, r0.w, (r)c4.y
stib.b.untyped.1d.u16.4.imm.base0 hr8.x, r15.x, 4
(ss)(rpt1)add.u r4.x, (last)r0.w, (r)c3.w
(rpt4)nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.x, r4.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.x, r4.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r4.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r4.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr3.x, r5.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr2.x, r5.y, 4
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
; CL prog 23/1: 435 instr, 33 nops, 402 non-nops, 65 mov, 0 cov, 800 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 16 full, 8 constlen
; CL prog 23/1: 36 cat0, 65 cat1, 43 cat2, 259 cat3, 0 cat4, 16 cat5, 16 cat6, 0 cat7
; CL prog 23/1: 6 sstall, 8 (ss), 37 systall, 2 (sy), 1 loops
; CL prog 23/1: 16 max_waves, 0 double_threadsize
; 31 preamble-instr, 1 early-preamble
