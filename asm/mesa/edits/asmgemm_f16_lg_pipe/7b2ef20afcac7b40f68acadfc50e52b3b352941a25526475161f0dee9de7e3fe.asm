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
mov.u32u32 r52.z, 0x7840
mov.u32u32 r52.w, 0x7040
mov.u32u32 r53.x, 0x6840
mov.u32u32 r53.y, 0x6040
mov.u32u32 r53.z, 0x5840
mov.u32u32 r53.w, 0x5040
mov.u32u32 r54.x, 0x4840
mov.u32u32 r54.y, 0x4040
mov.u32u32 r54.z, 0x3840
mov.u32u32 r54.w, 0x3040
mov.u32u32 r55.x, 0x2840
mov.u32u32 r55.y, 0x2040
mov.u32u32 r55.z, 0x1840
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
(ss)mov.u32u32 r48.w, 0x1040
mov.u32u32 r49.x, 2112
mov.u32u32 r49.y, 0x10000
mov.u32u32 r49.z, 0x10040
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 4
stc.u32 c[20], r52.w, 4
stc.u32 c[24], r53.w, 4
stc.u32 c[28], r54.w, 4
(ss)mov.u32u32 r49.w, 0x10800
mov.u32u32 r50.x, 0x10840
mov.u32u32 r50.y, 0x11000
mov.u32u32 r50.z, 0x11040
mov.u32u32 r50.w, 0x11800
mov.u32u32 r51.x, 0x11840
stc.u32 c[32], r48.w, 4
(ss)nop
stc.u32 c[36], r49.w, 4
stc.u32 c[40], r50.w, 2
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l58:
(jp)(rpt1)add.u r51.y, (r)r48.x, (r)c0.x
mov.u32u32 r52.y, 0
shl.b r52.x, r51.y, 7
shl.b r51.w, r51.z, 6
shr.b r0.w, r0.x, 4
and.b r1.x, r0.x, 15
mov.u16u16 hr2.z, 0
mov.u16u16 hr2.w, 0
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
mov.u32u32 r23.x, 0x8000
mov.u32u32 r25.y, 0x3fffff
(rpt1)shr.b r52.z, (r)r51.w, 2
shl.b r24.w, r0.x, 3
shl.b r25.x, r0.w, 3
shl.b r24.y, r0.w, 9
(ss)add.u r23.y, r52.w, r1.x
(rpt2)nop
add.u r24.y, r24.y, r52.z
shl.b r23.y, r23.y, 2
(rpt2)nop
add.u r24.y, r24.y, r1.x
(rpt2)nop
shl.b r24.y, r24.y, 2
(rpt2)nop
add.u r24.z, r24.y, c3.x
(rpt2)nop
add.u r23.z, r23.y, c1.x
add.u r23.w, r23.y, c4.z
add.u r24.x, r23.y, c4.y
(rpt5)nop
isam.v.base0 (u16)(xyzw)hr18.w, r23.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr19.w, r23.y+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr20.w, r23.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr21.w, r23.z+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr22.w, r23.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr23.w, r23.w+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr24.w, r24.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr25.w, r24.x+64, s#0, t#2
(ss)(nop3) add.u r23.y, r23.y, c4.x
and.b r23.y, r23.y, r25.y
l128:
add.u r52.y, r52.y, 16
cmps.u.ge up0.x, r52.y, c1.x
isam.v.base0 (u16)(xyzw)hr42.w, r24.y, s#0, t#0
isam.v.base0 (u16)(xyzw)hr43.w, r24.z, s#0, t#0
(ss)add.u r24.y, r24.y, r23.x
add.u r24.z, r24.z, r23.x
(sy)stl.u16 l[r24.w], r42.w, 4
stl.u16 l[r24.w+1024], r43.w, 4
fence.r.w
(sy)(ss)bar.g
(sy)nop
ldl.u16 r34.w, l[r25.x], 4
ldl.u16 r35.w, l[r25.x+64], 4
ldl.u16 r36.w, l[r25.x+128], 4
ldl.u16 r37.w, l[r25.x+192], 4
ldl.u16 r38.w, l[r25.x+256], 4
ldl.u16 r39.w, l[r25.x+320], 4
ldl.u16 r40.w, l[r25.x+384], 4
ldl.u16 r41.w, l[r25.x+448], 4
add.u r23.z, r23.y, c1.x
add.u r23.w, r23.y, c4.z
add.u r24.x, r23.y, c4.y
(rpt5)nop
isam.v.base0 (u16)(xyzw)hr26.w, r23.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr27.w, r23.y+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr28.w, r23.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr29.w, r23.z+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr30.w, r23.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr31.w, r23.w+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr32.w, r24.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr33.w, r24.x+64, s#0, t#2
(ss)(nop3) add.u r23.y, r23.y, c4.x
and.b r23.y, r23.y, r25.y
(ss)(rpt3)mad.f16 hr17.z, (r)hr18.w, hr34.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr19.w, hr34.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr18.w, hr35.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr19.w, hr35.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr18.w, hr35.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr19.w, hr35.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr18.w, hr35.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr19.w, hr35.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr18.w, hr35.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr19.w, hr35.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr18.w, hr36.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr19.w, hr36.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr18.w, hr36.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr19.w, hr36.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr18.w, hr36.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr19.w, hr36.z, (r)hr2.z
(rpt3)mad.f16 hr17.z, (r)hr20.w, hr36.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr21.w, hr36.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr20.w, hr37.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr21.w, hr37.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr20.w, hr37.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr21.w, hr37.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr20.w, hr37.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr21.w, hr37.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr20.w, hr37.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr21.w, hr37.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr20.w, hr38.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr21.w, hr38.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr20.w, hr38.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr21.w, hr38.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr20.w, hr38.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr21.w, hr38.z, (r)hr2.z
(rpt3)mad.f16 hr17.z, (r)hr22.w, hr38.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr23.w, hr38.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr22.w, hr39.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr23.w, hr39.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr22.w, hr39.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr23.w, hr39.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr22.w, hr39.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr23.w, hr39.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr22.w, hr39.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr23.w, hr39.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr22.w, hr40.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr23.w, hr40.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr22.w, hr40.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr23.w, hr40.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr22.w, hr40.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr23.w, hr40.z, (r)hr2.z
(rpt3)mad.f16 hr17.z, (r)hr24.w, hr40.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr25.w, hr40.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr24.w, hr41.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr25.w, hr41.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr24.w, hr41.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr25.w, hr41.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr24.w, hr41.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr25.w, hr41.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr24.w, hr41.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr25.w, hr41.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr24.w, hr42.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr25.w, hr42.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr24.w, hr42.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr25.w, hr42.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr24.w, hr42.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr25.w, hr42.z, (r)hr2.z
(sy)nop
ldl.u16 r34.w, l[r25.x+512], 4
ldl.u16 r35.w, l[r25.x+576], 4
ldl.u16 r36.w, l[r25.x+640], 4
ldl.u16 r37.w, l[r25.x+704], 4
ldl.u16 r38.w, l[r25.x+768], 4
ldl.u16 r39.w, l[r25.x+832], 4
ldl.u16 r40.w, l[r25.x+896], 4
ldl.u16 r41.w, l[r25.x+960], 4
add.u r23.z, r23.y, c1.x
add.u r23.w, r23.y, c4.z
add.u r24.x, r23.y, c4.y
(rpt5)nop
isam.v.base0 (u16)(xyzw)hr18.w, r23.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr19.w, r23.y+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr20.w, r23.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr21.w, r23.z+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr22.w, r23.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr23.w, r23.w+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr24.w, r24.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr25.w, r24.x+64, s#0, t#2
(ss)(nop3) add.u r23.y, r23.y, c4.x
and.b r23.y, r23.y, r25.y
(ss)(rpt3)mad.f16 hr17.z, (r)hr26.w, hr34.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr27.w, hr34.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr26.w, hr35.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr27.w, hr35.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr26.w, hr35.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr27.w, hr35.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr26.w, hr35.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr27.w, hr35.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr26.w, hr35.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr27.w, hr35.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr26.w, hr36.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr27.w, hr36.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr26.w, hr36.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr27.w, hr36.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr26.w, hr36.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr27.w, hr36.z, (r)hr2.z
(rpt3)mad.f16 hr17.z, (r)hr28.w, hr36.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr29.w, hr36.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr28.w, hr37.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr29.w, hr37.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr28.w, hr37.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr29.w, hr37.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr28.w, hr37.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr29.w, hr37.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr28.w, hr37.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr29.w, hr37.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr28.w, hr38.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr29.w, hr38.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr28.w, hr38.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr29.w, hr38.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr28.w, hr38.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr29.w, hr38.z, (r)hr2.z
(rpt3)mad.f16 hr17.z, (r)hr30.w, hr38.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr31.w, hr38.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr30.w, hr39.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr31.w, hr39.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr30.w, hr39.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr31.w, hr39.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr30.w, hr39.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr31.w, hr39.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr30.w, hr39.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr31.w, hr39.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr30.w, hr40.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr31.w, hr40.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr30.w, hr40.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr31.w, hr40.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr30.w, hr40.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr31.w, hr40.z, (r)hr2.z
(rpt3)mad.f16 hr17.z, (r)hr32.w, hr40.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr33.w, hr40.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr32.w, hr41.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr33.w, hr41.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr32.w, hr41.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr33.w, hr41.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr32.w, hr41.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr33.w, hr41.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr32.w, hr41.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr33.w, hr41.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr32.w, hr42.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr33.w, hr42.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr32.w, hr42.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr33.w, hr42.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr32.w, hr42.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr33.w, hr42.z, (r)hr2.z
(sy)nop
ldl.u16 r34.w, l[r25.x+1024], 4
ldl.u16 r35.w, l[r25.x+1088], 4
ldl.u16 r36.w, l[r25.x+1152], 4
ldl.u16 r37.w, l[r25.x+1216], 4
ldl.u16 r38.w, l[r25.x+1280], 4
ldl.u16 r39.w, l[r25.x+1344], 4
ldl.u16 r40.w, l[r25.x+1408], 4
ldl.u16 r41.w, l[r25.x+1472], 4
add.u r23.z, r23.y, c1.x
add.u r23.w, r23.y, c4.z
add.u r24.x, r23.y, c4.y
(rpt5)nop
isam.v.base0 (u16)(xyzw)hr26.w, r23.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr27.w, r23.y+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr28.w, r23.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr29.w, r23.z+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr30.w, r23.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr31.w, r23.w+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr32.w, r24.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr33.w, r24.x+64, s#0, t#2
(ss)(nop3) add.u r23.y, r23.y, c4.x
and.b r23.y, r23.y, r25.y
(ss)(rpt3)mad.f16 hr17.z, (r)hr18.w, hr34.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr19.w, hr34.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr18.w, hr35.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr19.w, hr35.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr18.w, hr35.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr19.w, hr35.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr18.w, hr35.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr19.w, hr35.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr18.w, hr35.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr19.w, hr35.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr18.w, hr36.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr19.w, hr36.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr18.w, hr36.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr19.w, hr36.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr18.w, hr36.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr19.w, hr36.z, (r)hr2.z
(rpt3)mad.f16 hr17.z, (r)hr20.w, hr36.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr21.w, hr36.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr20.w, hr37.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr21.w, hr37.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr20.w, hr37.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr21.w, hr37.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr20.w, hr37.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr21.w, hr37.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr20.w, hr37.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr21.w, hr37.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr20.w, hr38.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr21.w, hr38.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr20.w, hr38.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr21.w, hr38.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr20.w, hr38.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr21.w, hr38.z, (r)hr2.z
(rpt3)mad.f16 hr17.z, (r)hr22.w, hr38.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr23.w, hr38.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr22.w, hr39.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr23.w, hr39.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr22.w, hr39.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr23.w, hr39.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr22.w, hr39.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr23.w, hr39.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr22.w, hr39.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr23.w, hr39.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr22.w, hr40.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr23.w, hr40.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr22.w, hr40.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr23.w, hr40.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr22.w, hr40.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr23.w, hr40.z, (r)hr2.z
(rpt3)mad.f16 hr17.z, (r)hr24.w, hr40.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr25.w, hr40.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr24.w, hr41.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr25.w, hr41.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr24.w, hr41.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr25.w, hr41.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr24.w, hr41.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr25.w, hr41.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr24.w, hr41.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr25.w, hr41.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr24.w, hr42.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr25.w, hr42.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr24.w, hr42.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr25.w, hr42.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr24.w, hr42.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr25.w, hr42.z, (r)hr2.z
(sy)nop
ldl.u16 r34.w, l[r25.x+1536], 4
ldl.u16 r35.w, l[r25.x+1600], 4
ldl.u16 r36.w, l[r25.x+1664], 4
ldl.u16 r37.w, l[r25.x+1728], 4
ldl.u16 r38.w, l[r25.x+1792], 4
ldl.u16 r39.w, l[r25.x+1856], 4
ldl.u16 r40.w, l[r25.x+1920], 4
ldl.u16 r41.w, l[r25.x+1984], 4
add.u r23.z, r23.y, c1.x
add.u r23.w, r23.y, c4.z
add.u r24.x, r23.y, c4.y
(rpt5)nop
isam.v.base0 (u16)(xyzw)hr18.w, r23.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr19.w, r23.y+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr20.w, r23.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr21.w, r23.z+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr22.w, r23.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr23.w, r23.w+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr24.w, r24.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr25.w, r24.x+64, s#0, t#2
(ss)(nop3) add.u r23.y, r23.y, c4.x
and.b r23.y, r23.y, r25.y
(ss)(rpt3)mad.f16 hr17.z, (r)hr26.w, hr34.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr27.w, hr34.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr26.w, hr35.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr27.w, hr35.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr26.w, hr35.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr27.w, hr35.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr26.w, hr35.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr27.w, hr35.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr26.w, hr35.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr27.w, hr35.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr26.w, hr36.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr27.w, hr36.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr26.w, hr36.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr27.w, hr36.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr26.w, hr36.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr27.w, hr36.z, (r)hr2.z
(rpt3)mad.f16 hr17.z, (r)hr28.w, hr36.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr29.w, hr36.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr28.w, hr37.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr29.w, hr37.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr28.w, hr37.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr29.w, hr37.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr28.w, hr37.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr29.w, hr37.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr28.w, hr37.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr29.w, hr37.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr28.w, hr38.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr29.w, hr38.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr28.w, hr38.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr29.w, hr38.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr28.w, hr38.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr29.w, hr38.z, (r)hr2.z
(rpt3)mad.f16 hr17.z, (r)hr30.w, hr38.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr31.w, hr38.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr30.w, hr39.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr31.w, hr39.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr30.w, hr39.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr31.w, hr39.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr30.w, hr39.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr31.w, hr39.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr30.w, hr39.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr31.w, hr39.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr30.w, hr40.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr31.w, hr40.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr30.w, hr40.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr31.w, hr40.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr30.w, hr40.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr31.w, hr40.z, (r)hr2.z
(rpt3)mad.f16 hr17.z, (r)hr32.w, hr40.w, (r)hr17.z
(rpt3)mad.f16 hr16.z, (r)hr33.w, hr40.w, (r)hr16.z
(rpt3)mad.f16 hr15.z, (r)hr32.w, hr41.x, (r)hr15.z
(rpt3)mad.f16 hr14.z, (r)hr33.w, hr41.x, (r)hr14.z
(rpt3)mad.f16 hr13.z, (r)hr32.w, hr41.y, (r)hr13.z
(rpt3)mad.f16 hr12.z, (r)hr33.w, hr41.y, (r)hr12.z
(rpt3)mad.f16 hr11.z, (r)hr32.w, hr41.z, (r)hr11.z
(rpt3)mad.f16 hr10.z, (r)hr33.w, hr41.z, (r)hr10.z
(rpt3)mad.f16 hr9.z, (r)hr32.w, hr41.w, (r)hr9.z
(rpt3)mad.f16 hr8.z, (r)hr33.w, hr41.w, (r)hr8.z
(rpt3)mad.f16 hr7.z, (r)hr32.w, hr42.x, (r)hr7.z
(rpt3)mad.f16 hr6.z, (r)hr33.w, hr42.x, (r)hr6.z
(rpt3)mad.f16 hr5.z, (r)hr32.w, hr42.y, (r)hr5.z
(rpt3)mad.f16 hr4.z, (r)hr33.w, hr42.y, (r)hr4.z
(rpt3)mad.f16 hr3.z, (r)hr32.w, hr42.z, (r)hr3.z
(rpt3)mad.f16 hr2.z, (r)hr33.w, hr42.z, (r)hr2.z
(ss)bar.g
(ss)br p0.x, #l1097
jump #l128
l1097:
(jp)(eolm)nop
(sy)nop
shl.b r11.y, r0.w, 2
(rpt2)nop
(nop3) add.u r11.y, r51.w, (last)r11.y
(nop3) shl.b r11.y, (last)r11.y, 9
(nop3) sad.s32 r11.y, r52.w, r11.y, (last)r1.x
(nop3) shl.b r11.y, (last)r11.y, 2
add.u r20.x, r11.y, c1.x
add.u r20.y, r11.y, c8.y
add.u r20.z, r11.y, c4.z
add.u r20.w, r11.y, c8.x
add.u r0.x, r11.y, c4.y
add.u r0.y, r11.y, c7.w
(rpt1)add.u r0.z, r11.y, (r)c8.z
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r11.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r11.y+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r20.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r20.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r20.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r20.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r0.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r0.y, 4
(ss)(rpt1)add.u r5.y, r11.y, (r)c10.x
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r0.z, 4
(ss)(rpt1)add.u r4.w, r11.y, (r)c9.z
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r0.w, 4
(ss)(rpt1)add.u r4.y, (last)r11.y, (r)c9.x
(rpt4)nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r4.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r4.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r4.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r5.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r5.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr2.z, r5.z, 4
end
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1287 instr, 29 nops, 1258 non-nops, 65 mov, 0 cov, 2278 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 21 full, 12 constlen
; CL prog 23/1: 32 cat0, 65 cat1, 74 cat2, 1028 cat3, 0 cat4, 34 cat5, 50 cat6, 4 cat7
; CL prog 23/1: 30 sstall, 16 (ss), 155 systall, 9 (sy), 1 loops
; CL prog 23/1: 12 max_waves, 0 double_threadsize
; 58 preamble-instr, 1 early-preamble
