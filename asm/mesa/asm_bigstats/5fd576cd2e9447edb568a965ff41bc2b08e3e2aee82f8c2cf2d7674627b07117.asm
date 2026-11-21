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
@const(c5.x)	0x00011840, 0x00020000, 0x00020040, 0x00020800
@const(c6.x)	0x00020840, 0x00021000, 0x00021040, 0x00021800
@const(c7.x)	0x00021840, 0x00030000, 0x00001860, 0x00001060
@const(c8.x)	0x00000860, 0x00030040, 0x00030800, 0x00030840
@const(c9.x)	0x00031000, 0x00031040, 0x00031800, 0x00031840
shps #l55
getone #l55
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
mov.u32u32 r53.x, 0x20000
mov.u32u32 r53.y, 0x20040
mov.u32u32 r53.z, 0x20800
mov.u32u32 r53.w, 0x20840
mov.u32u32 r54.x, 0x21000
mov.u32u32 r54.y, 0x21040
mov.u32u32 r54.z, 0x21800
mov.u32u32 r54.w, 0x21840
mov.u32u32 r55.x, 0x30000
mov.u32u32 r55.y, 0x1860
mov.u32u32 r55.z, 0x1060
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
(ss)mov.u32u32 r48.w, 2144
mov.u32u32 r49.x, 0x30040
mov.u32u32 r49.y, 0x30800
mov.u32u32 r49.z, 0x30840
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 4
stc.u32 c[20], r52.w, 4
stc.u32 c[24], r53.w, 4
stc.u32 c[28], r54.w, 4
(ss)mov.u32u32 r49.w, 0x31000
mov.u32u32 r50.x, 0x31040
mov.u32u32 r50.y, 0x31800
mov.u32u32 r50.z, 0x31840
stc.u32 c[32], r48.w, 4
(ss)nop
stc.u32 c[36], r49.w, 4
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l55:
(jp)(rpt1)add.u r50.w, (r)r48.x, (r)c0.x
mov.u32u32 r51.w, 0
shl.b r51.z, r50.w, 7
shl.b r51.y, r51.x, 7
shr.b r0.w, r0.x, 4
mov.u16u16 hr2.x, 0
mov.u16u16 hr2.y, 0
mov.u16u16 hr33.w, 0
mov.u16u16 hr33.z, 0
mov.u16u16 hr33.y, 0
mov.u16u16 hr33.x, 0
mov.u16u16 hr32.w, 0
mov.u16u16 hr32.z, 0
mov.u16u16 hr32.y, 0
mov.u16u16 hr32.x, 0
mov.u16u16 hr31.w, 0
mov.u16u16 hr31.z, 0
mov.u16u16 hr31.y, 0
mov.u16u16 hr31.x, 0
mov.u16u16 hr30.w, 0
mov.u16u16 hr30.z, 0
mov.u16u16 hr30.y, 0
mov.u16u16 hr30.x, 0
mov.u16u16 hr29.w, 0
mov.u16u16 hr29.z, 0
mov.u16u16 hr29.y, 0
mov.u16u16 hr29.x, 0
mov.u16u16 hr28.w, 0
mov.u16u16 hr28.z, 0
mov.u16u16 hr28.y, 0
mov.u16u16 hr28.x, 0
mov.u16u16 hr27.w, 0
mov.u16u16 hr27.z, 0
mov.u16u16 hr27.y, 0
mov.u16u16 hr27.x, 0
mov.u16u16 hr26.w, 0
mov.u16u16 hr26.z, 0
mov.u16u16 hr26.y, 0
mov.u16u16 hr26.x, 0
mov.u16u16 hr25.w, 0
mov.u16u16 hr25.z, 0
mov.u16u16 hr25.y, 0
mov.u16u16 hr25.x, 0
mov.u16u16 hr24.w, 0
mov.u16u16 hr24.z, 0
mov.u16u16 hr24.y, 0
mov.u16u16 hr24.x, 0
mov.u16u16 hr23.w, 0
mov.u16u16 hr23.z, 0
mov.u16u16 hr23.y, 0
mov.u16u16 hr23.x, 0
mov.u16u16 hr22.w, 0
mov.u16u16 hr22.z, 0
mov.u16u16 hr22.y, 0
mov.u16u16 hr22.x, 0
mov.u16u16 hr21.w, 0
mov.u16u16 hr21.z, 0
mov.u16u16 hr21.y, 0
mov.u16u16 hr21.x, 0
mov.u16u16 hr20.w, 0
mov.u16u16 hr20.z, 0
mov.u16u16 hr20.y, 0
mov.u16u16 hr20.x, 0
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
mov.u16u16 hr4.y, 0
mov.u16u16 hr4.x, 0
mov.u16u16 hr3.w, 0
mov.u16u16 hr3.z, 0
mov.u16u16 hr3.y, 0
mov.u16u16 hr3.x, 0
mov.u16u16 hr2.w, 0
mov.u16u16 hr2.z, 0
and.b r0.x, (last)r0.x, 15
l189:
(rpt1)shr.b r52.x, (r)r51.y, 2
shl.b r52.z, r51.w, 9
add.u r51.w, r51.w, 4
cmps.u.ge up0.x, r51.w, c1.x
(ss)(nop2) sad.s32 r17.x, r52.z, r0.w, r52.x
sad.s32 r17.y, r52.z, r0.x, r52.y
(nop2) shl.b r17.x, (last)r17.x, 2
shl.b r17.y, (last)r17.y, 2
add.u r18.x, r17.x, c1.x
add.u r18.y, r17.x, c3.y
add.u r18.z, r17.x, c2.y
isam.v.base0 (u16)(xyzw)hr35.x, r17.x, s#0, t#0
isam.v.base0 (u16)(xyzw)hr45.x, r17.x+32, s#0, t#0
isam.v.base0 (u16)(xyzw)hr46.x, r17.x+64, s#0, t#0
isam.v.base0 (u16)(xyzw)hr47.x, r17.x+96, s#0, t#0
add.u r18.w, r17.x, c8.x
add.u r19.x, r17.y, c1.x
add.u r19.y, r17.y, c2.y
isam.v.base0 (u16)(xyzw)hr0.z, r17.y, s#0, t#2
add.u r20.x, r17.x, c1.z
add.u r20.y, r17.x, c3.x
add.u r20.z, r17.x, c2.x
add.u r20.w, r17.x, c7.w
add.u r21.x, r17.x, c1.y
add.u r21.y, r17.x, c2.w
add.u r21.z, r17.x, c1.w
add.u r21.w, (last)r17.x, c7.z
add.u r19.z, r17.y, c1.z
add.u r19.w, r17.y, c2.x
add.u r22.x, r17.y, c1.y
add.u r22.y, r17.y, c1.w
(sy)mad.f16 hr33.x, hr0.z, hr35.x, (last)hr33.x
mad.f16 hr31.x, hr0.z, hr35.y, (last)hr31.x
mad.f16 hr29.x, hr0.z, hr35.z, (last)hr29.x
mad.f16 hr27.x, hr0.z, hr35.w, (last)hr27.x
mad.f16 hr25.x, hr0.z, hr45.x, (last)hr25.x
mad.f16 hr23.x, hr0.z, hr45.y, (last)hr23.x
mad.f16 hr21.x, hr0.z, hr45.z, (last)hr21.x
mad.f16 hr19.x, hr0.z, hr45.w, (last)hr19.x
mad.f16 hr17.x, hr0.z, hr46.x, (last)hr17.x
mad.f16 hr15.x, hr0.z, hr46.y, (last)hr15.x
mad.f16 hr13.x, hr0.z, hr46.z, (last)hr13.x
mad.f16 hr11.x, hr0.z, hr46.w, (last)hr11.x
mad.f16 hr9.x, hr0.z, hr47.x, (last)hr9.x
mad.f16 hr7.x, hr0.z, hr47.y, (last)hr7.x
mad.f16 hr5.x, hr0.z, hr47.z, (last)hr5.x
mad.f16 hr33.y, hr0.w, hr35.x, (last)hr33.y
mad.f16 hr31.y, hr0.w, hr35.y, (last)hr31.y
mad.f16 hr29.y, hr0.w, hr35.z, (last)hr29.y
mad.f16 hr27.y, hr0.w, hr35.w, (last)hr27.y
mad.f16 hr25.y, hr0.w, hr45.x, (last)hr25.y
mad.f16 hr23.y, hr0.w, hr45.y, (last)hr23.y
mad.f16 hr21.y, hr0.w, hr45.z, (last)hr21.y
mad.f16 hr19.y, hr0.w, hr45.w, (last)hr19.y
mad.f16 hr17.y, hr0.w, hr46.x, (last)hr17.y
mad.f16 hr15.y, hr0.w, hr46.y, (last)hr15.y
mad.f16 hr13.y, hr0.w, hr46.z, (last)hr13.y
mad.f16 hr11.y, hr0.w, hr46.w, (last)hr11.y
mad.f16 hr9.y, hr0.w, hr47.x, (last)hr9.y
mad.f16 hr7.y, hr0.w, hr47.y, (last)hr7.y
mad.f16 hr5.y, hr0.w, hr47.z, (last)hr5.y
mad.f16 hr33.z, hr1.x, hr35.x, (last)hr33.z
mad.f16 hr31.z, hr1.x, hr35.y, (last)hr31.z
mad.f16 hr29.z, hr1.x, hr35.z, (last)hr29.z
mad.f16 hr27.z, hr1.x, hr35.w, (last)hr27.z
mad.f16 hr25.z, hr1.x, hr45.x, (last)hr25.z
mad.f16 hr23.z, hr1.x, hr45.y, (last)hr23.z
mad.f16 hr21.z, hr1.x, hr45.z, (last)hr21.z
mad.f16 hr19.z, hr1.x, hr45.w, (last)hr19.z
mad.f16 hr17.z, hr1.x, hr46.x, (last)hr17.z
mad.f16 hr15.z, hr1.x, hr46.y, (last)hr15.z
mad.f16 hr13.z, hr1.x, hr46.z, (last)hr13.z
mad.f16 hr11.z, hr1.x, hr46.w, (last)hr11.z
mad.f16 hr9.z, hr1.x, hr47.x, (last)hr9.z
mad.f16 hr7.z, hr1.x, hr47.y, (last)hr7.z
mad.f16 hr5.z, hr1.x, hr47.z, (last)hr5.z
mad.f16 hr33.w, hr1.y, hr35.x, (last)hr33.w
mad.f16 hr31.w, hr1.y, hr35.y, (last)hr31.w
mad.f16 hr29.w, hr1.y, hr35.z, (last)hr29.w
mad.f16 hr27.w, hr1.y, hr35.w, (last)hr27.w
mad.f16 hr25.w, hr1.y, hr45.x, (last)hr25.w
mad.f16 hr23.w, hr1.y, hr45.y, (last)hr23.w
mad.f16 hr21.w, hr1.y, hr45.z, (last)hr21.w
mad.f16 hr19.w, hr1.y, hr45.w, (last)hr19.w
mad.f16 hr17.w, hr1.y, hr46.x, (last)hr17.w
mad.f16 hr15.w, hr1.y, hr46.y, (last)hr15.w
mad.f16 hr13.w, hr1.y, hr46.z, (last)hr13.w
mad.f16 hr11.w, hr1.y, hr46.w, (last)hr11.w
mad.f16 hr9.w, hr1.y, hr47.x, (last)hr9.w
mad.f16 hr7.w, hr1.y, hr47.y, (last)hr7.w
mad.f16 hr5.w, hr1.y, hr47.z, (last)hr5.w
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr47.w, (r)(last)hr3.x
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr47.w, (r)(last)hr3.z
isam.v.base0 (u16)(xyzw)hr3.x, r17.y+64, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr34.x, r18.x, s#0, t#0
(sy)mad.f16 hr32.x, hr3.x, hr35.x, (last)hr32.x
mad.f16 hr30.x, hr3.x, hr35.y, (last)hr30.x
mad.f16 hr28.x, hr3.x, hr35.z, (last)hr28.x
mad.f16 hr26.x, hr3.x, hr35.w, (last)hr26.x
mad.f16 hr24.x, hr3.x, hr45.x, (last)hr24.x
mad.f16 hr22.x, hr3.x, hr45.y, (last)hr22.x
mad.f16 hr20.x, hr3.x, hr45.z, (last)hr20.x
mad.f16 hr18.x, hr3.x, hr45.w, (last)hr18.x
mad.f16 hr14.x, hr3.x, hr46.y, (last)hr14.x
mad.f16 hr12.x, hr3.x, hr46.z, (last)hr12.x
mad.f16 hr10.x, hr3.x, hr46.w, (last)hr10.x
mad.f16 hr8.x, hr3.x, hr47.x, (last)hr8.x
mad.f16 hr32.y, hr3.y, hr35.x, (last)hr32.y
mad.f16 hr30.y, hr3.y, hr35.y, (last)hr30.y
mad.f16 hr28.y, hr3.y, hr35.z, (last)hr28.y
mad.f16 hr26.y, hr3.y, hr35.w, (last)hr26.y
mad.f16 hr24.y, hr3.y, hr45.x, (last)hr24.y
mad.f16 hr22.y, hr3.y, hr45.y, (last)hr22.y
mad.f16 hr20.y, hr3.y, hr45.z, (last)hr20.y
mad.f16 hr18.y, hr3.y, hr45.w, (last)hr18.y
mad.f16 hr14.y, hr3.y, hr46.y, (last)hr14.y
mad.f16 hr12.y, hr3.y, hr46.z, (last)hr12.y
mad.f16 hr10.y, hr3.y, hr46.w, (last)hr10.y
mad.f16 hr8.y, hr3.y, hr47.x, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr3.z, hr35.x, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr3.z, hr35.y, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr3.z, hr35.z, (r)(last)hr28.z
(rpt1)mad.f16 hr26.z, (r)hr3.z, hr35.w, (r)(last)hr26.z
isam.v.base0 (u16)(xyzw)hr35.x, r18.y, s#0, t#0
(ss)nop
isam.v.base0 (u16)(xyzw)hr36.x, r18.z, s#0, t#0
(ss)nop
isam.v.base0 (u16)(xyzw)hr37.x, r18.w, s#0, t#0
(rpt1)mad.f16 hr24.z, (r)hr3.z, hr45.x, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr3.z, hr45.y, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr3.z, hr45.z, (r)(last)hr20.z
(rpt1)mad.f16 hr18.z, (r)hr3.z, hr45.w, (r)(last)hr18.z
isam.v.base0 (u16)(xyzw)hr45.x, r19.x, s#0, t#2
(rpt1)mad.f16 hr14.z, (r)hr3.z, hr46.y, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr3.z, hr46.z, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr3.z, hr46.w, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr3.z, hr47.x, (r)(last)hr8.z
isam.v.base0 (u16)(xyzw)hr46.y, r19.y, s#0, t#2
mad.f16 hr16.x, hr3.x, hr46.x, (last)hr16.x
mad.f16 hr6.x, hr3.x, hr47.y, (last)hr6.x
mad.f16 hr4.x, hr3.x, hr47.z, (last)hr4.x
mad.f16 hr16.y, hr3.y, hr46.x, (last)hr16.y
mad.f16 hr6.y, hr3.y, hr47.y, (last)hr6.y
mad.f16 hr4.y, hr3.y, hr47.z, (last)hr4.y
(rpt1)mad.f16 hr16.z, (r)hr3.z, hr46.x, (r)(last)hr16.z
(rpt1)mad.f16 hr6.z, (r)hr3.z, hr47.y, (r)(last)hr6.z
(rpt1)mad.f16 hr4.z, (r)hr3.z, hr47.z, (r)(last)hr4.z
(rpt1)mad.f16 hr3.x, (r)(last)hr3.x, hr47.w, (r)(last)hr2.x
(rpt1)mad.f16 hr3.z, (r)(last)hr3.z, hr47.w, (r)(last)hr2.z
(sy)mad.f16 hr33.x, hr45.x, hr34.x, (last)hr33.x
mad.f16 hr31.x, hr45.x, hr34.y, (last)hr31.x
mad.f16 hr29.x, hr45.x, hr34.z, (last)hr29.x
mad.f16 hr27.x, hr45.x, hr34.w, (last)hr27.x
mad.f16 hr25.x, hr45.x, hr35.x, (last)hr25.x
mad.f16 hr23.x, hr45.x, hr35.y, (last)hr23.x
mad.f16 hr21.x, hr45.x, hr35.z, (last)hr21.x
mad.f16 hr19.x, hr45.x, hr35.w, (last)hr19.x
mad.f16 hr17.x, hr45.x, hr36.x, (last)hr17.x
mad.f16 hr15.x, hr45.x, hr36.y, (last)hr15.x
mad.f16 hr13.x, hr45.x, hr36.z, (last)hr13.x
mad.f16 hr11.x, hr45.x, hr36.w, (last)hr11.x
mad.f16 hr9.x, hr45.x, hr37.x, (last)hr9.x
mad.f16 hr7.x, hr45.x, hr37.y, (last)hr7.x
mad.f16 hr5.x, hr45.x, hr37.z, (last)hr5.x
mad.f16 hr33.y, hr45.y, hr34.x, (last)hr33.y
mad.f16 hr31.y, hr45.y, hr34.y, (last)hr31.y
mad.f16 hr29.y, hr45.y, hr34.z, (last)hr29.y
mad.f16 hr27.y, hr45.y, hr34.w, (last)hr27.y
mad.f16 hr25.y, hr45.y, hr35.x, (last)hr25.y
mad.f16 hr23.y, hr45.y, hr35.y, (last)hr23.y
mad.f16 hr21.y, hr45.y, hr35.z, (last)hr21.y
mad.f16 hr19.y, hr45.y, hr35.w, (last)hr19.y
mad.f16 hr17.y, hr45.y, hr36.x, (last)hr17.y
mad.f16 hr15.y, hr45.y, hr36.y, (last)hr15.y
mad.f16 hr13.y, hr45.y, hr36.z, (last)hr13.y
mad.f16 hr11.y, hr45.y, hr36.w, (last)hr11.y
mad.f16 hr9.y, hr45.y, hr37.x, (last)hr9.y
mad.f16 hr7.y, hr45.y, hr37.y, (last)hr7.y
mad.f16 hr5.y, hr45.y, hr37.z, (last)hr5.y
mad.f16 hr33.z, hr45.z, hr34.x, (last)hr33.z
mad.f16 hr31.z, hr45.z, hr34.y, (last)hr31.z
mad.f16 hr29.z, hr45.z, hr34.z, (last)hr29.z
mad.f16 hr27.z, hr45.z, hr34.w, (last)hr27.z
mad.f16 hr25.z, hr45.z, hr35.x, (last)hr25.z
mad.f16 hr23.z, hr45.z, hr35.y, (last)hr23.z
mad.f16 hr21.z, hr45.z, hr35.z, (last)hr21.z
mad.f16 hr19.z, hr45.z, hr35.w, (last)hr19.z
mad.f16 hr17.z, hr45.z, hr36.x, (last)hr17.z
mad.f16 hr15.z, hr45.z, hr36.y, (last)hr15.z
mad.f16 hr13.z, hr45.z, hr36.z, (last)hr13.z
mad.f16 hr11.z, hr45.z, hr36.w, (last)hr11.z
mad.f16 hr9.z, hr45.z, hr37.x, (last)hr9.z
mad.f16 hr7.z, hr45.z, hr37.y, (last)hr7.z
mad.f16 hr5.z, hr45.z, hr37.z, (last)hr5.z
mad.f16 hr33.w, hr45.w, hr34.x, (last)hr33.w
mad.f16 hr31.w, hr45.w, hr34.y, (last)hr31.w
mad.f16 hr29.w, hr45.w, hr34.z, (last)hr29.w
mad.f16 hr27.w, hr45.w, hr34.w, (last)hr27.w
mad.f16 hr25.w, hr45.w, hr35.x, (last)hr25.w
mad.f16 hr23.w, hr45.w, hr35.y, (last)hr23.w
mad.f16 hr21.w, hr45.w, hr35.z, (last)hr21.w
mad.f16 hr19.w, hr45.w, hr35.w, (last)hr19.w
mad.f16 hr17.w, hr45.w, hr36.x, (last)hr17.w
mad.f16 hr15.w, hr45.w, hr36.y, (last)hr15.w
mad.f16 hr13.w, hr45.w, hr36.z, (last)hr13.w
mad.f16 hr11.w, hr45.w, hr36.w, (last)hr11.w
mad.f16 hr9.w, hr45.w, hr37.x, (last)hr9.w
mad.f16 hr7.w, hr45.w, hr37.y, (last)hr7.w
mad.f16 hr5.w, hr45.w, hr37.z, (last)hr5.w
mad.f16 hr32.x, hr46.y, hr34.x, (last)hr32.x
mad.f16 hr30.x, hr46.y, hr34.y, (last)hr30.x
mad.f16 hr28.x, hr46.y, hr34.z, (last)hr28.x
mad.f16 hr26.x, hr46.y, hr34.w, (last)hr26.x
mad.f16 hr24.x, hr46.y, hr35.x, (last)hr24.x
mad.f16 hr22.x, hr46.y, hr35.y, (last)hr22.x
mad.f16 hr20.x, hr46.y, hr35.z, (last)hr20.x
mad.f16 hr18.x, hr46.y, hr35.w, (last)hr18.x
mad.f16 hr14.x, hr46.y, hr36.y, (last)hr14.x
mad.f16 hr12.x, hr46.y, hr36.z, (last)hr12.x
mad.f16 hr10.x, hr46.y, hr36.w, (last)hr10.x
mad.f16 hr8.x, hr46.y, hr37.x, (last)hr8.x
mad.f16 hr32.y, hr46.z, hr34.x, (last)hr32.y
mad.f16 hr30.y, hr46.z, hr34.y, (last)hr30.y
mad.f16 hr28.y, hr46.z, hr34.z, (last)hr28.y
mad.f16 hr26.y, hr46.z, hr34.w, (last)hr26.y
mad.f16 hr24.y, hr46.z, hr35.x, (last)hr24.y
mad.f16 hr22.y, hr46.z, hr35.y, (last)hr22.y
mad.f16 hr20.y, hr46.z, hr35.z, (last)hr20.y
mad.f16 hr18.y, hr46.z, hr35.w, (last)hr18.y
mad.f16 hr14.y, hr46.z, hr36.y, (last)hr14.y
mad.f16 hr12.y, hr46.z, hr36.z, (last)hr12.y
mad.f16 hr10.y, hr46.z, hr36.w, (last)hr10.y
mad.f16 hr8.y, hr46.z, hr37.x, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr46.w, hr34.x, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr46.w, hr34.y, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr46.w, hr34.z, (r)(last)hr28.z
(rpt1)mad.f16 hr26.z, (r)hr46.w, hr34.w, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr46.w, hr35.x, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr46.w, hr35.y, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr46.w, hr35.z, (r)(last)hr20.z
(rpt1)mad.f16 hr18.z, (r)hr46.w, hr35.w, (r)(last)hr18.z
(rpt1)mad.f16 hr14.z, (r)hr46.w, hr36.y, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr46.w, hr36.z, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr46.w, hr36.w, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr46.w, hr37.x, (r)(last)hr8.z
mad.f16 hr16.x, hr46.y, hr36.x, (last)hr16.x
mad.f16 hr6.x, hr46.y, hr37.y, (last)hr6.x
mad.f16 hr4.x, hr46.y, hr37.z, (last)hr4.x
mad.f16 hr16.y, hr46.z, hr36.x, (last)hr16.y
mad.f16 hr6.y, hr46.z, hr37.y, (last)hr6.y
mad.f16 hr4.y, hr46.z, hr37.z, (last)hr4.y
(rpt1)mad.f16 hr16.z, (r)hr46.w, hr36.x, (r)(last)hr16.z
(rpt1)mad.f16 hr6.z, (r)hr46.w, hr37.y, (r)(last)hr6.z
(rpt1)mad.f16 hr4.z, (r)hr46.w, hr37.z, (r)(last)hr4.z
(rpt1)mad.f16 hr45.x, (r)(last)hr45.x, hr37.w, (r)(last)hr0.z
(rpt1)mad.f16 hr45.z, (r)(last)hr45.z, hr37.w, (r)(last)hr1.x
isam.v.base0 (u16)(xyzw)hr0.z, r20.x, s#0, t#0
isam.v.base0 (u16)(xyzw)hr2.x, r20.y, s#0, t#0
(rpt1)mad.f16 hr46.y, (r)(last)hr46.y, hr37.w, (r)(last)hr3.x
(rpt1)mad.f16 hr46.w, (r)(last)hr46.w, hr37.w, (r)(last)hr3.z
isam.v.base0 (u16)(xyzw)hr3.x, r20.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr34.x, r20.w, s#0, t#0
isam.v.base0 (u16)(xyzw)hr35.x, r19.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr36.y, r19.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr37.y, r21.x, s#0, t#0
(ss)nop
isam.v.base0 (u16)(xyzw)hr38.y, r21.y, s#0, t#0
isam.v.base0 (u16)(xyzw)hr39.y, r21.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr40.y, r21.w, s#0, t#0
isam.v.base0 (u16)(xyzw)hr41.y, r22.x, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr42.y, r22.y, s#0, t#2
(sy)mad.f16 hr33.x, hr35.x, hr0.z, (last)hr33.x
mad.f16 hr31.x, hr35.x, hr0.w, (last)hr31.x
mad.f16 hr29.x, hr35.x, hr1.x, (last)hr29.x
mad.f16 hr27.x, hr35.x, hr1.y, (last)hr27.x
mad.f16 hr25.x, hr35.x, hr2.x, (last)hr25.x
mad.f16 hr23.x, hr35.x, hr2.y, (last)hr23.x
mad.f16 hr21.x, hr35.x, hr2.z, (last)hr21.x
mad.f16 hr19.x, hr35.x, hr2.w, (last)hr19.x
mad.f16 hr17.x, hr35.x, hr3.x, (last)hr17.x
mad.f16 hr15.x, hr35.x, hr3.y, (last)hr15.x
mad.f16 hr13.x, hr35.x, hr3.z, (last)hr13.x
mad.f16 hr11.x, hr35.x, hr3.w, (last)hr11.x
mad.f16 hr9.x, hr35.x, hr34.x, (last)hr9.x
mad.f16 hr7.x, hr35.x, hr34.y, (last)hr7.x
mad.f16 hr5.x, hr35.x, hr34.z, (last)hr5.x
mad.f16 hr33.y, hr35.y, hr0.z, (last)hr33.y
mad.f16 hr31.y, hr35.y, hr0.w, (last)hr31.y
mad.f16 hr29.y, hr35.y, hr1.x, (last)hr29.y
mad.f16 hr27.y, hr35.y, hr1.y, (last)hr27.y
mad.f16 hr25.y, hr35.y, hr2.x, (last)hr25.y
mad.f16 hr23.y, hr35.y, hr2.y, (last)hr23.y
mad.f16 hr21.y, hr35.y, hr2.z, (last)hr21.y
mad.f16 hr19.y, hr35.y, hr2.w, (last)hr19.y
mad.f16 hr17.y, hr35.y, hr3.x, (last)hr17.y
mad.f16 hr15.y, hr35.y, hr3.y, (last)hr15.y
mad.f16 hr13.y, hr35.y, hr3.z, (last)hr13.y
mad.f16 hr11.y, hr35.y, hr3.w, (last)hr11.y
mad.f16 hr9.y, hr35.y, hr34.x, (last)hr9.y
mad.f16 hr7.y, hr35.y, hr34.y, (last)hr7.y
mad.f16 hr5.y, hr35.y, hr34.z, (last)hr5.y
mad.f16 hr33.z, hr35.z, hr0.z, (last)hr33.z
mad.f16 hr31.z, hr35.z, hr0.w, (last)hr31.z
mad.f16 hr29.z, hr35.z, hr1.x, (last)hr29.z
mad.f16 hr27.z, hr35.z, hr1.y, (last)hr27.z
mad.f16 hr25.z, hr35.z, hr2.x, (last)hr25.z
mad.f16 hr23.z, hr35.z, hr2.y, (last)hr23.z
mad.f16 hr21.z, hr35.z, hr2.z, (last)hr21.z
mad.f16 hr19.z, hr35.z, hr2.w, (last)hr19.z
mad.f16 hr17.z, hr35.z, hr3.x, (last)hr17.z
mad.f16 hr15.z, hr35.z, hr3.y, (last)hr15.z
mad.f16 hr13.z, hr35.z, hr3.z, (last)hr13.z
mad.f16 hr11.z, hr35.z, hr3.w, (last)hr11.z
mad.f16 hr9.z, hr35.z, hr34.x, (last)hr9.z
mad.f16 hr7.z, hr35.z, hr34.y, (last)hr7.z
mad.f16 hr5.z, hr35.z, hr34.z, (last)hr5.z
mad.f16 hr33.w, hr35.w, hr0.z, (last)hr33.w
mad.f16 hr31.w, hr35.w, hr0.w, (last)hr31.w
mad.f16 hr29.w, hr35.w, hr1.x, (last)hr29.w
mad.f16 hr27.w, hr35.w, hr1.y, (last)hr27.w
mad.f16 hr25.w, hr35.w, hr2.x, (last)hr25.w
mad.f16 hr23.w, hr35.w, hr2.y, (last)hr23.w
mad.f16 hr21.w, hr35.w, hr2.z, (last)hr21.w
mad.f16 hr19.w, hr35.w, hr2.w, (last)hr19.w
mad.f16 hr17.w, hr35.w, hr3.x, (last)hr17.w
mad.f16 hr15.w, hr35.w, hr3.y, (last)hr15.w
mad.f16 hr13.w, hr35.w, hr3.z, (last)hr13.w
mad.f16 hr11.w, hr35.w, hr3.w, (last)hr11.w
mad.f16 hr9.w, hr35.w, hr34.x, (last)hr9.w
mad.f16 hr7.w, hr35.w, hr34.y, (last)hr7.w
mad.f16 hr5.w, hr35.w, hr34.z, (last)hr5.w
mad.f16 hr32.x, hr36.y, hr0.z, (last)hr32.x
mad.f16 hr30.x, hr36.y, hr0.w, (last)hr30.x
mad.f16 hr28.x, hr36.y, hr1.x, (last)hr28.x
mad.f16 hr26.x, hr36.y, hr1.y, (last)hr26.x
mad.f16 hr24.x, hr36.y, hr2.x, (last)hr24.x
mad.f16 hr22.x, hr36.y, hr2.y, (last)hr22.x
mad.f16 hr20.x, hr36.y, hr2.z, (last)hr20.x
mad.f16 hr18.x, hr36.y, hr2.w, (last)hr18.x
mad.f16 hr16.x, hr36.y, hr3.x, (last)hr16.x
mad.f16 hr14.x, hr36.y, hr3.y, (last)hr14.x
mad.f16 hr12.x, hr36.y, hr3.z, (last)hr12.x
mad.f16 hr10.x, hr36.y, hr3.w, (last)hr10.x
mad.f16 hr8.x, hr36.y, hr34.x, (last)hr8.x
mad.f16 hr6.x, hr36.y, hr34.y, (last)hr6.x
mad.f16 hr4.x, hr36.y, hr34.z, (last)hr4.x
mad.f16 hr32.y, hr36.z, hr0.z, (last)hr32.y
mad.f16 hr30.y, hr36.z, hr0.w, (last)hr30.y
mad.f16 hr28.y, hr36.z, hr1.x, (last)hr28.y
mad.f16 hr26.y, hr36.z, hr1.y, (last)hr26.y
mad.f16 hr24.y, hr36.z, hr2.x, (last)hr24.y
mad.f16 hr22.y, hr36.z, hr2.y, (last)hr22.y
mad.f16 hr20.y, hr36.z, hr2.z, (last)hr20.y
mad.f16 hr18.y, hr36.z, hr2.w, (last)hr18.y
mad.f16 hr16.y, hr36.z, hr3.x, (last)hr16.y
mad.f16 hr14.y, hr36.z, hr3.y, (last)hr14.y
mad.f16 hr12.y, hr36.z, hr3.z, (last)hr12.y
mad.f16 hr10.y, hr36.z, hr3.w, (last)hr10.y
mad.f16 hr8.y, hr36.z, hr34.x, (last)hr8.y
mad.f16 hr6.y, hr36.z, hr34.y, (last)hr6.y
mad.f16 hr4.y, hr36.z, hr34.z, (last)hr4.y
(rpt1)mad.f16 hr32.z, (r)hr36.w, hr0.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr36.w, hr0.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr36.w, hr1.x, (r)(last)hr28.z
(rpt1)mad.f16 hr26.z, (r)hr36.w, hr1.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr36.w, hr2.x, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr36.w, hr2.y, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr36.w, hr2.z, (r)(last)hr20.z
(rpt1)mad.f16 hr18.z, (r)hr36.w, hr2.w, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr36.w, hr3.x, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr36.w, hr3.y, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr36.w, hr3.z, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr36.w, hr3.w, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr36.w, hr34.x, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr36.w, hr34.y, (r)(last)hr6.z
(rpt1)mad.f16 hr4.z, (r)hr36.w, hr34.z, (r)(last)hr4.z
(rpt1)mad.f16 hr35.x, (r)(last)hr35.x, hr34.w, (r)(last)hr45.x
(rpt1)mad.f16 hr35.z, (r)(last)hr35.z, hr34.w, (r)(last)hr45.z
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr34.w, (r)(last)hr46.y
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr34.w, (r)(last)hr46.w
mad.f16 hr33.x, hr41.y, hr37.y, (last)hr33.x
mad.f16 hr31.x, hr41.y, hr37.z, (last)hr31.x
mad.f16 hr29.x, hr41.y, hr37.w, (last)hr29.x
mad.f16 hr27.x, hr41.y, hr38.x, (last)hr27.x
mad.f16 hr25.x, hr41.y, hr38.y, (last)hr25.x
mad.f16 hr23.x, hr41.y, hr38.z, (last)hr23.x
mad.f16 hr21.x, hr41.y, hr38.w, (last)hr21.x
mad.f16 hr19.x, hr41.y, hr39.x, (last)hr19.x
mad.f16 hr17.x, hr41.y, hr39.y, (last)hr17.x
mad.f16 hr15.x, hr41.y, hr39.z, (last)hr15.x
mad.f16 hr13.x, hr41.y, hr39.w, (last)hr13.x
mad.f16 hr11.x, hr41.y, hr40.x, (last)hr11.x
mad.f16 hr9.x, hr41.y, hr40.y, (last)hr9.x
mad.f16 hr7.x, hr41.y, hr40.z, (last)hr7.x
mad.f16 hr5.x, hr41.y, hr40.w, (last)hr5.x
mad.f16 hr33.y, hr41.z, hr37.y, (last)hr33.y
mad.f16 hr31.y, hr41.z, hr37.z, (last)hr31.y
mad.f16 hr29.y, hr41.z, hr37.w, (last)hr29.y
mad.f16 hr27.y, hr41.z, hr38.x, (last)hr27.y
mad.f16 hr25.y, hr41.z, hr38.y, (last)hr25.y
mad.f16 hr23.y, hr41.z, hr38.z, (last)hr23.y
mad.f16 hr21.y, hr41.z, hr38.w, (last)hr21.y
mad.f16 hr19.y, hr41.z, hr39.x, (last)hr19.y
mad.f16 hr17.y, hr41.z, hr39.y, (last)hr17.y
mad.f16 hr15.y, hr41.z, hr39.z, (last)hr15.y
mad.f16 hr13.y, hr41.z, hr39.w, (last)hr13.y
mad.f16 hr11.y, hr41.z, hr40.x, (last)hr11.y
mad.f16 hr9.y, hr41.z, hr40.y, (last)hr9.y
mad.f16 hr7.y, hr41.z, hr40.z, (last)hr7.y
mad.f16 hr5.y, hr41.z, hr40.w, (last)hr5.y
mad.f16 hr33.z, hr41.w, hr37.y, (last)hr33.z
mad.f16 hr31.z, hr41.w, hr37.z, (last)hr31.z
mad.f16 hr29.z, hr41.w, hr37.w, (last)hr29.z
mad.f16 hr27.z, hr41.w, hr38.x, (last)hr27.z
mad.f16 hr25.z, hr41.w, hr38.y, (last)hr25.z
mad.f16 hr23.z, hr41.w, hr38.z, (last)hr23.z
mad.f16 hr21.z, hr41.w, hr38.w, (last)hr21.z
mad.f16 hr19.z, hr41.w, hr39.x, (last)hr19.z
mad.f16 hr17.z, hr41.w, hr39.y, (last)hr17.z
mad.f16 hr15.z, hr41.w, hr39.z, (last)hr15.z
mad.f16 hr13.z, hr41.w, hr39.w, (last)hr13.z
mad.f16 hr11.z, hr41.w, hr40.x, (last)hr11.z
mad.f16 hr9.z, hr41.w, hr40.y, (last)hr9.z
mad.f16 hr7.z, hr41.w, hr40.z, (last)hr7.z
mad.f16 hr5.z, hr41.w, hr40.w, (last)hr5.z
mad.f16 hr33.w, hr42.x, hr37.y, (last)hr33.w
mad.f16 hr31.w, hr42.x, hr37.z, (last)hr31.w
mad.f16 hr29.w, hr42.x, hr37.w, (last)hr29.w
mad.f16 hr27.w, hr42.x, hr38.x, (last)hr27.w
mad.f16 hr25.w, hr42.x, hr38.y, (last)hr25.w
mad.f16 hr23.w, hr42.x, hr38.z, (last)hr23.w
mad.f16 hr21.w, hr42.x, hr38.w, (last)hr21.w
mad.f16 hr19.w, hr42.x, hr39.x, (last)hr19.w
mad.f16 hr17.w, hr42.x, hr39.y, (last)hr17.w
mad.f16 hr15.w, hr42.x, hr39.z, (last)hr15.w
mad.f16 hr13.w, hr42.x, hr39.w, (last)hr13.w
mad.f16 hr11.w, hr42.x, hr40.x, (last)hr11.w
mad.f16 hr9.w, hr42.x, hr40.y, (last)hr9.w
mad.f16 hr7.w, hr42.x, hr40.z, (last)hr7.w
mad.f16 hr5.w, hr42.x, hr40.w, (last)hr5.w
mad.f16 hr32.x, hr42.y, hr37.y, (last)hr32.x
mad.f16 hr30.x, hr42.y, hr37.z, (last)hr30.x
mad.f16 hr28.x, hr42.y, hr37.w, (last)hr28.x
mad.f16 hr26.x, hr42.y, hr38.x, (last)hr26.x
mad.f16 hr24.x, hr42.y, hr38.y, (last)hr24.x
mad.f16 hr22.x, hr42.y, hr38.z, (last)hr22.x
mad.f16 hr20.x, hr42.y, hr38.w, (last)hr20.x
mad.f16 hr18.x, hr42.y, hr39.x, (last)hr18.x
mad.f16 hr16.x, hr42.y, hr39.y, (last)hr16.x
mad.f16 hr14.x, hr42.y, hr39.z, (last)hr14.x
mad.f16 hr12.x, hr42.y, hr39.w, (last)hr12.x
mad.f16 hr10.x, hr42.y, hr40.x, (last)hr10.x
mad.f16 hr8.x, hr42.y, hr40.y, (last)hr8.x
mad.f16 hr6.x, hr42.y, hr40.z, (last)hr6.x
mad.f16 hr4.x, hr42.y, hr40.w, (last)hr4.x
mad.f16 hr32.y, hr42.z, hr37.y, (last)hr32.y
mad.f16 hr30.y, hr42.z, hr37.z, (last)hr30.y
mad.f16 hr28.y, hr42.z, hr37.w, (last)hr28.y
mad.f16 hr26.y, hr42.z, hr38.x, (last)hr26.y
mad.f16 hr24.y, hr42.z, hr38.y, (last)hr24.y
mad.f16 hr22.y, hr42.z, hr38.z, (last)hr22.y
mad.f16 hr20.y, hr42.z, hr38.w, (last)hr20.y
mad.f16 hr18.y, hr42.z, hr39.x, (last)hr18.y
mad.f16 hr16.y, hr42.z, hr39.y, (last)hr16.y
mad.f16 hr14.y, hr42.z, hr39.z, (last)hr14.y
mad.f16 hr12.y, hr42.z, hr39.w, (last)hr12.y
mad.f16 hr10.y, hr42.z, hr40.x, (last)hr10.y
mad.f16 hr8.y, hr42.z, hr40.y, (last)hr8.y
mad.f16 hr6.y, hr42.z, hr40.z, (last)hr6.y
mad.f16 hr4.y, hr42.z, hr40.w, (last)hr4.y
(rpt1)mad.f16 hr32.z, (r)hr42.w, hr37.y, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr42.w, hr37.z, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr42.w, hr37.w, (r)(last)hr28.z
(rpt1)mad.f16 hr26.z, (r)hr42.w, hr38.x, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr42.w, hr38.y, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr42.w, hr38.z, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr42.w, hr38.w, (r)(last)hr20.z
(rpt1)mad.f16 hr18.z, (r)hr42.w, hr39.x, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr42.w, hr39.y, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr42.w, hr39.z, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr42.w, hr39.w, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr42.w, hr40.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr42.w, hr40.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr42.w, hr40.z, (r)(last)hr6.z
(rpt1)mad.f16 hr4.z, (r)hr42.w, hr40.w, (r)(last)hr4.z
(rpt1)mad.f16 hr3.x, (r)(last)hr41.y, hr41.x, (r)(last)hr35.x
(rpt1)mad.f16 hr3.z, (r)(last)hr41.w, hr41.x, (r)(last)hr35.z
(rpt1)mad.f16 hr2.x, (r)(last)hr42.y, hr41.x, (r)(last)hr36.y
(rpt1)mad.f16 hr2.z, (r)(last)hr42.w, hr41.x, (r)(last)hr36.w
br p0.x, #l682
jump #l189
l682:
(jp)(nop3) shl.b r0.w, (last)r0.w, 2
(nop3) add.u r0.w, r51.y, (last)r0.w
(nop3) shl.b r0.w, (last)r0.w, 9
(nop3) sad.s32 r0.w, r52.y, r0.w, (last)r0.x
(nop3) shl.b r0.w, (last)r0.w, 2
add.u r21.w, r0.w, c1.x
add.u r22.x, r0.w, c2.y
add.u r22.y, r0.w, c1.z
add.u r22.z, r0.w, c2.x
add.u r22.w, r0.w, c1.y
add.u r23.x, r0.w, c1.w
add.u r23.y, r0.w, c2.z
add.u r23.z, r0.w, c3.z
(rpt3)add.u r23.w, r0.w, (r)c3.w
(rpt2)add.u r0.x, r0.w, (r)c4.w
stib.b.untyped.1d.u16.4.imm.base0 hr33.x, r0.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr32.x, r0.w+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr31.x, r21.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr30.x, r22.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr29.x, r22.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr28.x, r22.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr27.x, r22.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr26.x, r23.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr25.x, r23.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr24.x, r23.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr23.x, r23.w, 4
(ss)(rpt1)add.u r11.z, (r)c9.y, r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr22.x, r24.x, 4
(ss)(rpt1)add.u r11.x, (r)c8.w, r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr21.x, r24.y, 4
(ss)(rpt1)add.u r10.z, (r)c8.y, r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr20.x, r24.z, 4
(ss)(rpt1)add.u r10.x, (r)c7.x, r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr19.x, r0.x, 4
(ss)(rpt1)add.u r9.z, (r)c6.z, r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr18.x, r0.y, 4
(ss)(rpt1)add.u r9.x, (r)c6.x, r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr17.x, r0.z, 4
(ss)(rpt1)add.u r8.z, (r)c5.z, r0.w
(nop3) add.u r0.w, c9.w, (last)r0.w
nop
stib.b.untyped.1d.u16.4.imm.base0 hr16.x, r8.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr15.x, r8.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.x, r9.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.x, r9.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.x, r9.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.x, r9.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.x, r10.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.x, r10.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr8.x, r10.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr7.x, r10.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr6.x, r11.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r11.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r11.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr3.x, r11.w, 4
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
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 798 instr, 30 nops, 768 non-nops, 129 mov, 0 cov, 1504 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 25 full, 12 constlen
; CL prog 23/1: 33 cat0, 129 cat1, 65 cat2, 515 cat3, 0 cat4, 24 cat5, 32 cat6, 0 cat7
; CL prog 23/1: 6 sstall, 13 (ss), 128 systall, 4 (sy), 1 loops
; CL prog 23/1: 10 max_waves, 0 double_threadsize
; 55 preamble-instr, 1 early-preamble
