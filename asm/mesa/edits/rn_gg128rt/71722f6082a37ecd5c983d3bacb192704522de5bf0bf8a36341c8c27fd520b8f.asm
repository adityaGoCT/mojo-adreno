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
l97:
(rpt1)shr.b r53.z, (r)r52.w, 2
shl.b r54.x, r53.y, 9
add.u r53.y, r53.y, 4
cmps.u.ge up0.x, r53.y, c1.x
(ss)(nop2) sad.s32 r9.x, r54.x, r0.w, r53.z
sad.s32 r9.y, r54.x, r0.x, r53.w
(nop2) shl.b r9.x, (last)r9.x, 2
shl.b r9.y, (last)r9.y, 2
add.u r10.x, r9.x, c1.x
add.u r10.y, r9.x, c2.y
add.u r10.z, r9.x, c1.z
isam.v.base0 (u16)(xyzw)hr19.x, r9.x, s#0, t#0
isam.v.base0 (u16)(xyzw)hr26.x, r9.x+64, s#0, t#0
add.u r11.x, r9.y, c1.x
add.u r11.y, r9.y, c2.y
add.u r10.w, r9.x, c2.x
isam.v.base0 (u16)(xyzw)hr27.x, r9.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr28.x, r9.y+64, s#0, t#2
add.u r11.z, r9.y, c1.z
isam.v.base0 (u16)(xyzw)hr29.x, r10.x, s#0, t#0
add.u r11.w, r9.y, c2.x
isam.v.base0 (u16)(xyzw)hr30.x, r10.y, s#0, t#0
add.u r12.x, r9.x, c1.y
add.u r12.y, (last)r9.x, c1.w
isam.v.base0 (u16)(xyzw)hr31.x, r11.x, s#0, t#2
add.u r12.z, r9.y, c1.y
isam.v.base0 (u16)(xyzw)hr0.z, r11.y, s#0, t#2
add.u r12.w, (last)r9.y, c1.w
(sy)mad.f16 hr17.x, hr27.x, hr19.x, (last)hr17.x
mad.f16 hr15.x, hr27.x, hr19.y, (last)hr15.x
mad.f16 hr13.x, hr27.x, hr19.z, (last)hr13.x
mad.f16 hr11.x, hr27.x, hr19.w, (last)hr11.x
mad.f16 hr9.x, hr27.x, hr26.x, (last)hr9.x
mad.f16 hr7.x, hr27.x, hr26.y, (last)hr7.x
mad.f16 hr5.x, hr27.x, hr26.z, (last)hr5.x
mad.f16 hr17.y, hr27.y, hr19.x, (last)hr17.y
mad.f16 hr15.y, hr27.y, hr19.y, (last)hr15.y
mad.f16 hr13.y, hr27.y, hr19.z, (last)hr13.y
mad.f16 hr11.y, hr27.y, hr19.w, (last)hr11.y
mad.f16 hr9.y, hr27.y, hr26.x, (last)hr9.y
mad.f16 hr7.y, hr27.y, hr26.y, (last)hr7.y
mad.f16 hr5.y, hr27.y, hr26.z, (last)hr5.y
mad.f16 hr17.z, hr27.z, hr19.x, (last)hr17.z
mad.f16 hr15.z, hr27.z, hr19.y, (last)hr15.z
mad.f16 hr13.z, hr27.z, hr19.z, (last)hr13.z
mad.f16 hr11.z, hr27.z, hr19.w, (last)hr11.z
mad.f16 hr9.z, hr27.z, hr26.x, (last)hr9.z
mad.f16 hr7.z, hr27.z, hr26.y, (last)hr7.z
mad.f16 hr5.z, hr27.z, hr26.z, (last)hr5.z
mad.f16 hr17.w, hr27.w, hr19.x, (last)hr17.w
mad.f16 hr15.w, hr27.w, hr19.y, (last)hr15.w
mad.f16 hr13.w, hr27.w, hr19.z, (last)hr13.w
mad.f16 hr11.w, hr27.w, hr19.w, (last)hr11.w
mad.f16 hr9.w, hr27.w, hr26.x, (last)hr9.w
mad.f16 hr7.w, hr27.w, hr26.y, (last)hr7.w
mad.f16 hr5.w, hr27.w, hr26.z, (last)hr5.w
mad.f16 hr16.x, hr28.x, hr19.x, (last)hr16.x
mad.f16 hr14.x, hr28.x, hr19.y, (last)hr14.x
mad.f16 hr12.x, hr28.x, hr19.z, (last)hr12.x
mad.f16 hr10.x, hr28.x, hr19.w, (last)hr10.x
mad.f16 hr8.x, hr28.x, hr26.x, (last)hr8.x
mad.f16 hr6.x, hr28.x, hr26.y, (last)hr6.x
mad.f16 hr4.x, hr28.x, hr26.z, (last)hr4.x
mad.f16 hr16.y, hr28.y, hr19.x, (last)hr16.y
mad.f16 hr14.y, hr28.y, hr19.y, (last)hr14.y
mad.f16 hr12.y, hr28.y, hr19.z, (last)hr12.y
mad.f16 hr10.y, hr28.y, hr19.w, (last)hr10.y
mad.f16 hr8.y, hr28.y, hr26.x, (last)hr8.y
mad.f16 hr6.y, hr28.y, hr26.y, (last)hr6.y
mad.f16 hr4.y, hr28.y, hr26.z, (last)hr4.y
(rpt1)mad.f16 hr16.z, (r)hr28.z, hr19.x, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr28.z, hr19.y, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr28.z, hr19.z, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr28.z, hr19.w, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr28.z, hr26.x, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr28.z, hr26.y, (r)(last)hr6.z
(rpt1)mad.f16 hr4.z, (r)hr28.z, hr26.z, (r)(last)hr4.z
(rpt1)mad.f16 hr27.x, (r)(last)hr27.x, hr26.w, (r)(last)hr3.x
(rpt1)mad.f16 hr27.z, (r)(last)hr27.z, hr26.w, (r)(last)hr3.z
(rpt1)mad.f16 hr28.x, (r)(last)hr28.x, hr26.w, (r)(last)hr2.x
(rpt1)mad.f16 hr28.z, (r)(last)hr28.z, hr26.w, (r)(last)hr2.z
isam.v.base0 (u16)(xyzw)hr2.x, r10.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr3.x, r10.w, s#0, t#0
isam.v.base0 (u16)(xyzw)hr18.x, r11.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr19.x, r11.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr20.x, r12.x, s#0, t#0
(ss)nop
isam.v.base0 (u16)(xyzw)hr21.x, r12.y, s#0, t#0
isam.v.base0 (u16)(xyzw)hr22.x, r12.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr23.x, r12.w, s#0, t#2
mad.f16 hr17.x, hr31.x, hr29.x, (last)hr17.x
mad.f16 hr15.x, hr31.x, hr29.y, (last)hr15.x
mad.f16 hr13.x, hr31.x, hr29.z, (last)hr13.x
mad.f16 hr11.x, hr31.x, hr29.w, (last)hr11.x
mad.f16 hr9.x, hr31.x, hr30.x, (last)hr9.x
mad.f16 hr7.x, hr31.x, hr30.y, (last)hr7.x
mad.f16 hr5.x, hr31.x, hr30.z, (last)hr5.x
mad.f16 hr17.y, hr31.y, hr29.x, (last)hr17.y
mad.f16 hr15.y, hr31.y, hr29.y, (last)hr15.y
mad.f16 hr13.y, hr31.y, hr29.z, (last)hr13.y
mad.f16 hr11.y, hr31.y, hr29.w, (last)hr11.y
mad.f16 hr9.y, hr31.y, hr30.x, (last)hr9.y
mad.f16 hr7.y, hr31.y, hr30.y, (last)hr7.y
mad.f16 hr5.y, hr31.y, hr30.z, (last)hr5.y
mad.f16 hr17.z, hr31.z, hr29.x, (last)hr17.z
mad.f16 hr15.z, hr31.z, hr29.y, (last)hr15.z
mad.f16 hr13.z, hr31.z, hr29.z, (last)hr13.z
mad.f16 hr11.z, hr31.z, hr29.w, (last)hr11.z
mad.f16 hr9.z, hr31.z, hr30.x, (last)hr9.z
mad.f16 hr7.z, hr31.z, hr30.y, (last)hr7.z
mad.f16 hr5.z, hr31.z, hr30.z, (last)hr5.z
mad.f16 hr17.w, hr31.w, hr29.x, (last)hr17.w
mad.f16 hr15.w, hr31.w, hr29.y, (last)hr15.w
mad.f16 hr13.w, hr31.w, hr29.z, (last)hr13.w
mad.f16 hr11.w, hr31.w, hr29.w, (last)hr11.w
mad.f16 hr9.w, hr31.w, hr30.x, (last)hr9.w
mad.f16 hr7.w, hr31.w, hr30.y, (last)hr7.w
mad.f16 hr5.w, hr31.w, hr30.z, (last)hr5.w
mad.f16 hr16.x, hr0.z, hr29.x, (last)hr16.x
mad.f16 hr14.x, hr0.z, hr29.y, (last)hr14.x
mad.f16 hr12.x, hr0.z, hr29.z, (last)hr12.x
mad.f16 hr10.x, hr0.z, hr29.w, (last)hr10.x
mad.f16 hr8.x, hr0.z, hr30.x, (last)hr8.x
mad.f16 hr6.x, hr0.z, hr30.y, (last)hr6.x
mad.f16 hr4.x, hr0.z, hr30.z, (last)hr4.x
mad.f16 hr16.y, hr0.w, hr29.x, (last)hr16.y
mad.f16 hr14.y, hr0.w, hr29.y, (last)hr14.y
mad.f16 hr12.y, hr0.w, hr29.z, (last)hr12.y
mad.f16 hr10.y, hr0.w, hr29.w, (last)hr10.y
mad.f16 hr8.y, hr0.w, hr30.x, (last)hr8.y
mad.f16 hr6.y, hr0.w, hr30.y, (last)hr6.y
mad.f16 hr4.y, hr0.w, hr30.z, (last)hr4.y
(rpt1)mad.f16 hr16.z, (r)hr1.x, hr29.x, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr1.x, hr29.y, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr1.x, hr29.z, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr1.x, hr29.w, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr1.x, hr30.x, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr1.x, hr30.y, (r)(last)hr6.z
(rpt1)mad.f16 hr4.z, (r)hr1.x, hr30.z, (r)(last)hr4.z
(rpt1)mad.f16 hr31.x, (r)(last)hr31.x, hr30.w, (r)(last)hr27.x
(rpt1)mad.f16 hr31.z, (r)(last)hr31.z, hr30.w, (r)(last)hr27.z
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr30.w, (r)(last)hr28.x
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr30.w, (r)(last)hr28.z
(sy)mad.f16 hr17.x, hr18.x, hr2.x, (last)hr17.x
mad.f16 hr15.x, hr18.x, hr2.y, (last)hr15.x
mad.f16 hr13.x, hr18.x, hr2.z, (last)hr13.x
mad.f16 hr11.x, hr18.x, hr2.w, (last)hr11.x
mad.f16 hr9.x, hr18.x, hr3.x, (last)hr9.x
mad.f16 hr7.x, hr18.x, hr3.y, (last)hr7.x
mad.f16 hr5.x, hr18.x, hr3.z, (last)hr5.x
mad.f16 hr17.y, hr18.y, hr2.x, (last)hr17.y
mad.f16 hr15.y, hr18.y, hr2.y, (last)hr15.y
mad.f16 hr13.y, hr18.y, hr2.z, (last)hr13.y
mad.f16 hr11.y, hr18.y, hr2.w, (last)hr11.y
mad.f16 hr9.y, hr18.y, hr3.x, (last)hr9.y
mad.f16 hr7.y, hr18.y, hr3.y, (last)hr7.y
mad.f16 hr5.y, hr18.y, hr3.z, (last)hr5.y
mad.f16 hr17.z, hr18.z, hr2.x, (last)hr17.z
mad.f16 hr15.z, hr18.z, hr2.y, (last)hr15.z
mad.f16 hr13.z, hr18.z, hr2.z, (last)hr13.z
mad.f16 hr11.z, hr18.z, hr2.w, (last)hr11.z
mad.f16 hr9.z, hr18.z, hr3.x, (last)hr9.z
mad.f16 hr7.z, hr18.z, hr3.y, (last)hr7.z
mad.f16 hr5.z, hr18.z, hr3.z, (last)hr5.z
mad.f16 hr17.w, hr18.w, hr2.x, (last)hr17.w
mad.f16 hr15.w, hr18.w, hr2.y, (last)hr15.w
mad.f16 hr13.w, hr18.w, hr2.z, (last)hr13.w
mad.f16 hr11.w, hr18.w, hr2.w, (last)hr11.w
mad.f16 hr9.w, hr18.w, hr3.x, (last)hr9.w
mad.f16 hr7.w, hr18.w, hr3.y, (last)hr7.w
mad.f16 hr5.w, hr18.w, hr3.z, (last)hr5.w
mad.f16 hr16.x, hr19.x, hr2.x, (last)hr16.x
mad.f16 hr14.x, hr19.x, hr2.y, (last)hr14.x
mad.f16 hr12.x, hr19.x, hr2.z, (last)hr12.x
mad.f16 hr10.x, hr19.x, hr2.w, (last)hr10.x
mad.f16 hr8.x, hr19.x, hr3.x, (last)hr8.x
mad.f16 hr6.x, hr19.x, hr3.y, (last)hr6.x
mad.f16 hr4.x, hr19.x, hr3.z, (last)hr4.x
mad.f16 hr16.y, hr19.y, hr2.x, (last)hr16.y
mad.f16 hr14.y, hr19.y, hr2.y, (last)hr14.y
mad.f16 hr12.y, hr19.y, hr2.z, (last)hr12.y
mad.f16 hr10.y, hr19.y, hr2.w, (last)hr10.y
mad.f16 hr8.y, hr19.y, hr3.x, (last)hr8.y
mad.f16 hr6.y, hr19.y, hr3.y, (last)hr6.y
mad.f16 hr4.y, hr19.y, hr3.z, (last)hr4.y
(rpt1)mad.f16 hr16.z, (r)hr19.z, hr2.x, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr19.z, hr2.y, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr19.z, hr2.z, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr19.z, hr2.w, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr19.z, hr3.x, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr19.z, hr3.y, (r)(last)hr6.z
(rpt1)mad.f16 hr4.z, (r)hr19.z, hr3.z, (r)(last)hr4.z
(rpt1)mad.f16 hr18.x, (r)(last)hr18.x, hr3.w, (r)(last)hr31.x
(rpt1)mad.f16 hr18.z, (r)(last)hr18.z, hr3.w, (r)(last)hr31.z
(rpt1)mad.f16 hr19.x, (r)(last)hr19.x, hr3.w, (r)(last)hr0.z
(rpt1)mad.f16 hr19.z, (r)(last)hr19.z, hr3.w, (r)(last)hr1.x
mad.f16 hr17.x, hr22.x, hr20.x, (last)hr17.x
mad.f16 hr15.x, hr22.x, hr20.y, (last)hr15.x
mad.f16 hr13.x, hr22.x, hr20.z, (last)hr13.x
mad.f16 hr11.x, hr22.x, hr20.w, (last)hr11.x
mad.f16 hr9.x, hr22.x, hr21.x, (last)hr9.x
mad.f16 hr7.x, hr22.x, hr21.y, (last)hr7.x
mad.f16 hr5.x, hr22.x, hr21.z, (last)hr5.x
mad.f16 hr17.y, hr22.y, hr20.x, (last)hr17.y
mad.f16 hr15.y, hr22.y, hr20.y, (last)hr15.y
mad.f16 hr13.y, hr22.y, hr20.z, (last)hr13.y
mad.f16 hr11.y, hr22.y, hr20.w, (last)hr11.y
mad.f16 hr9.y, hr22.y, hr21.x, (last)hr9.y
mad.f16 hr7.y, hr22.y, hr21.y, (last)hr7.y
mad.f16 hr5.y, hr22.y, hr21.z, (last)hr5.y
mad.f16 hr17.z, hr22.z, hr20.x, (last)hr17.z
mad.f16 hr15.z, hr22.z, hr20.y, (last)hr15.z
mad.f16 hr13.z, hr22.z, hr20.z, (last)hr13.z
mad.f16 hr11.z, hr22.z, hr20.w, (last)hr11.z
mad.f16 hr9.z, hr22.z, hr21.x, (last)hr9.z
mad.f16 hr7.z, hr22.z, hr21.y, (last)hr7.z
mad.f16 hr5.z, hr22.z, hr21.z, (last)hr5.z
mad.f16 hr17.w, hr22.w, hr20.x, (last)hr17.w
mad.f16 hr15.w, hr22.w, hr20.y, (last)hr15.w
mad.f16 hr13.w, hr22.w, hr20.z, (last)hr13.w
mad.f16 hr11.w, hr22.w, hr20.w, (last)hr11.w
mad.f16 hr9.w, hr22.w, hr21.x, (last)hr9.w
mad.f16 hr7.w, hr22.w, hr21.y, (last)hr7.w
mad.f16 hr5.w, hr22.w, hr21.z, (last)hr5.w
mad.f16 hr16.x, hr23.x, hr20.x, (last)hr16.x
mad.f16 hr14.x, hr23.x, hr20.y, (last)hr14.x
mad.f16 hr12.x, hr23.x, hr20.z, (last)hr12.x
mad.f16 hr10.x, hr23.x, hr20.w, (last)hr10.x
mad.f16 hr8.x, hr23.x, hr21.x, (last)hr8.x
mad.f16 hr6.x, hr23.x, hr21.y, (last)hr6.x
mad.f16 hr4.x, hr23.x, hr21.z, (last)hr4.x
mad.f16 hr16.y, hr23.y, hr20.x, (last)hr16.y
mad.f16 hr14.y, hr23.y, hr20.y, (last)hr14.y
mad.f16 hr12.y, hr23.y, hr20.z, (last)hr12.y
mad.f16 hr10.y, hr23.y, hr20.w, (last)hr10.y
mad.f16 hr8.y, hr23.y, hr21.x, (last)hr8.y
mad.f16 hr6.y, hr23.y, hr21.y, (last)hr6.y
mad.f16 hr4.y, hr23.y, hr21.z, (last)hr4.y
(rpt1)mad.f16 hr16.z, (r)hr23.z, hr20.x, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr23.z, hr20.y, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr23.z, hr20.z, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr23.z, hr20.w, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr23.z, hr21.x, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr23.z, hr21.y, (r)(last)hr6.z
(rpt1)mad.f16 hr4.z, (r)hr23.z, hr21.z, (r)(last)hr4.z
(rpt1)mad.f16 hr3.x, (r)(last)hr22.x, hr21.w, (r)(last)hr18.x
mad.f16 hr3.z, (last)hr22.z, hr21.w, (last)hr18.z
(rpt1)mad.f16 hr2.x, (r)(last)hr23.x, hr21.w, (r)(last)hr19.x
(rpt1)mad.f16 hr2.z, (r)(last)hr23.z, hr21.w, (r)(last)hr19.z
mad.f16 hr3.w, (last)hr22.w, hr21.w, (last)hr18.w
br p0.x, #l349
jump #l97
l349:
(jp)(nop3) shl.b r0.w, (last)r0.w, 2
(nop3) add.u r0.w, r52.w, (last)r0.w
(nop3) shl.b r0.w, (last)r0.w, 9
(nop3) sad.s32 r0.w, r53.w, r0.w, (last)r0.x
(nop3) shl.b r0.w, (last)r0.w, 2
add.u r12.x, r0.w, c1.x
add.u r12.y, r0.w, c2.y
add.u r12.z, r0.w, c1.z
stib.b.untyped.1d.u16.4.imm.base0 hr17.x, r0.w, 4
add.u r12.w, r0.w, c2.x
add.u r13.x, r0.w, c1.y
add.u r13.y, r0.w, c1.w
add.u r13.z, r0.w, c2.z
(rpt1)add.u r13.w, (r)c2.w, r0.w
(rpt1)add.u r14.y, (r)c3.y, r0.w
(rpt1)add.u r14.w, (r)c3.w, r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr16.x, r0.w+64, 4
(ss)add.u r0.w, c4.y, (last)r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr15.x, r12.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.x, r12.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.x, r12.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.x, r12.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.x, r13.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.x, r13.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.x, r13.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr8.x, r13.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.x, r14.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.x, r14.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r14.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r14.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr3.x, r15.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr2.x, r0.w, 4
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
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 428 instr, 26 nops, 402 non-nops, 65 mov, 0 cov, 800 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 16 full, 8 constlen
; CL prog 23/1: 29 cat0, 65 cat1, 43 cat2, 259 cat3, 0 cat4, 16 cat5, 16 cat6, 0 cat7
; CL prog 23/1: 6 sstall, 3 (ss), 38 systall, 2 (sy), 1 loops
; CL prog 23/1: 16 max_waves, 0 double_threadsize
; 27 preamble-instr, 1 early-preamble
