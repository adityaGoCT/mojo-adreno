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
@const(c1.x)	0x00000800, 0x00000840, 0x00001000, 0x00001040
@const(c2.x)	0x00001800, 0x00001840, 0x00020000, 0x00020040
@const(c3.x)	0x00020800, 0x00020840, 0x00021000, 0x00021040
@const(c4.x)	0x00021800, 0x00021840, 0xd0d0d0d0, 0xd0d0d0d0
shps #l27
getone #l27
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 2112
mov.u32u32 r49.y, 4096
mov.u32u32 r49.z, 0x1040
mov.u32u32 r49.w, 0x1800
mov.u32u32 r50.x, 0x1840
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
shr.b r0.w, r0.x, 5
and.b r1.x, r0.x, 31
shr.b r1.z, r0.x, 4
and.b r1.y, (last)r0.x, 15
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
l99:
(ss)add.u r11.x, r53.y, r0.w
add.u r53.y, r53.y, 8
cmps.u.ge up0.x, r53.y, c1.x
shl.b r9.w, r0.w, 8
shl.b r10.x, r1.x, 3
shl.b r10.z, r1.z, 3
shl.b r11.x, (last)r11.x, 11
shl.b r10.y, r1.y, 3
add.u r9.w, (last)r9.w, (last)r10.x
shl.b r10.w, r1.z, 2
(rpt1)add.u r11.y, (last)r11.x, (r)r52.w
(rpt1)nop
(rpt1)shr.b r11.y, (last)(r)r11.y, 2
(rpt1)nop
(rpt1)add.u r11.y, (last)(r)r11.y, r1.x
(rpt1)nop
(rpt1)shl.b r11.y, (last)(r)r11.y, 2
(rpt4)nop
isam.v.base0 (u16)(xyzw)hr23.z, r11.y, s#0, t#0
nop
isam.v.base0 (u16)(xyzw)hr24.z, r11.z, s#0, t#2
(sy)stl.u16 l[r9.w], r23.z, 4
stl.u16 l[r9.w+2048], r24.z, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
ldl.u16 r25.z, l[r10.z], 4
ldl.u16 r26.z, l[r10.z+128], 4
ldl.u16 r27.z, l[r10.y+2048], 4
ldl.u16 r28.z, l[r10.y+2176], 4
ldl.u16 r29.z, l[r10.z+256], 4
ldl.u16 r30.z, l[r10.z+384], 4
ldl.u16 r0.x, l[r10.y+2304], 4
(ss)mad.f16 hr18.z, hr27.z, hr25.z, (last)hr18.z
mad.f16 hr16.z, hr27.z, hr25.w, (last)hr16.z
mad.f16 hr14.z, hr27.z, hr26.x, (last)hr14.z
mad.f16 hr12.z, hr27.z, hr26.y, (last)hr12.z
mad.f16 hr10.z, hr27.z, hr26.z, (last)hr10.z
mad.f16 hr8.z, hr27.z, hr26.w, (last)hr8.z
mad.f16 hr6.z, hr27.z, hr27.x, (last)hr6.z
mad.f16 hr18.w, hr27.w, hr25.z, (last)hr18.w
mad.f16 hr16.w, hr27.w, hr25.w, (last)hr16.w
mad.f16 hr14.w, hr27.w, hr26.x, (last)hr14.w
mad.f16 hr12.w, hr27.w, hr26.y, (last)hr12.w
mad.f16 hr10.w, hr27.w, hr26.z, (last)hr10.w
mad.f16 hr8.w, hr27.w, hr26.w, (last)hr8.w
mad.f16 hr6.w, hr27.w, hr27.x, (last)hr6.w
mad.f16 hr19.x, hr28.x, hr25.z, (last)hr19.x
mad.f16 hr17.x, hr28.x, hr25.w, (last)hr17.x
mad.f16 hr15.x, hr28.x, hr26.x, (last)hr15.x
mad.f16 hr13.x, hr28.x, hr26.y, (last)hr13.x
mad.f16 hr11.x, hr28.x, hr26.z, (last)hr11.x
mad.f16 hr9.x, hr28.x, hr26.w, (last)hr9.x
mad.f16 hr7.x, hr28.x, hr27.x, (last)hr7.x
mad.f16 hr19.y, hr28.y, hr25.z, (last)hr19.y
mad.f16 hr17.y, hr28.y, hr25.w, (last)hr17.y
mad.f16 hr15.y, hr28.y, hr26.x, (last)hr15.y
mad.f16 hr13.y, hr28.y, hr26.y, (last)hr13.y
mad.f16 hr11.y, hr28.y, hr26.z, (last)hr11.y
mad.f16 hr9.y, hr28.y, hr26.w, (last)hr9.y
mad.f16 hr7.y, hr28.y, hr27.x, (last)hr7.y
mad.f16 hr17.z, hr28.z, hr25.z, (last)hr17.z
mad.f16 hr15.z, hr28.z, hr25.w, (last)hr15.z
mad.f16 hr13.z, hr28.z, hr26.x, (last)hr13.z
mad.f16 hr11.z, hr28.z, hr26.y, (last)hr11.z
mad.f16 hr9.z, hr28.z, hr26.z, (last)hr9.z
mad.f16 hr7.z, hr28.z, hr26.w, (last)hr7.z
mad.f16 hr5.z, hr28.z, hr27.x, (last)hr5.z
mad.f16 hr17.w, hr28.w, hr25.z, (last)hr17.w
mad.f16 hr15.w, hr28.w, hr25.w, (last)hr15.w
mad.f16 hr13.w, hr28.w, hr26.x, (last)hr13.w
mad.f16 hr11.w, hr28.w, hr26.y, (last)hr11.w
mad.f16 hr9.w, hr28.w, hr26.z, (last)hr9.w
mad.f16 hr7.w, hr28.w, hr26.w, (last)hr7.w
mad.f16 hr5.w, hr28.w, hr27.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr29.x, hr25.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr29.x, hr25.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr29.x, hr26.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr29.x, hr26.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr29.x, hr26.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr29.x, hr26.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr29.x, hr27.x, (r)(last)hr6.x
(rpt1)mad.f16 hr27.z, (r)(last)hr27.z, hr27.y, (r)(last)hr4.z
(rpt1)mad.f16 hr28.x, (r)(last)hr28.x, hr27.y, (r)(last)hr5.x
(rpt1)mad.f16 hr28.z, (r)(last)hr28.z, hr27.y, (r)(last)hr3.z
(rpt1)mad.f16 hr29.x, (r)(last)hr29.x, hr27.y, (r)(last)hr4.x
ldl.u16 r3.z, l[r10.y+2432], 4
ldl.u16 r4.z, l[r10.z+512], 4
ldl.u16 r19.z, l[r10.z+640], 4
ldl.u16 r22.x, l[r10.y+2560], 4
ldl.u16 r23.x, l[r10.y+2688], 4
ldl.u16 r24.x, l[r10.z+768], 4
ldl.u16 r25.x, l[r10.z+896], 4
ldl.u16 r26.x, l[r10.y+2816], 4
mad.f16 hr18.z, hr0.x, hr29.z, (last)hr18.z
mad.f16 hr16.z, hr0.x, hr29.w, (last)hr16.z
mad.f16 hr14.z, hr0.x, hr30.x, (last)hr14.z
mad.f16 hr12.z, hr0.x, hr30.y, (last)hr12.z
mad.f16 hr10.z, hr0.x, hr30.z, (last)hr10.z
mad.f16 hr8.z, hr0.x, hr30.w, (last)hr8.z
mad.f16 hr6.z, hr0.x, hr31.x, (last)hr6.z
mad.f16 hr18.w, hr0.y, hr29.z, (last)hr18.w
mad.f16 hr16.w, hr0.y, hr29.w, (last)hr16.w
mad.f16 hr14.w, hr0.y, hr30.x, (last)hr14.w
mad.f16 hr12.w, hr0.y, hr30.y, (last)hr12.w
mad.f16 hr10.w, hr0.y, hr30.z, (last)hr10.w
mad.f16 hr8.w, hr0.y, hr30.w, (last)hr8.w
mad.f16 hr6.w, hr0.y, hr31.x, (last)hr6.w
(rpt1)mad.f16 hr0.x, (r)(last)hr0.x, hr31.y, (r)(last)hr27.z
ldl.u16 r27.x, l[r10.y+2944], 4
mad.f16 hr19.x, hr0.z, hr29.z, (last)hr19.x
mad.f16 hr17.x, hr0.z, hr29.w, (last)hr17.x
mad.f16 hr15.x, hr0.z, hr30.x, (last)hr15.x
mad.f16 hr13.x, hr0.z, hr30.y, (last)hr13.x
mad.f16 hr11.x, hr0.z, hr30.z, (last)hr11.x
mad.f16 hr9.x, hr0.z, hr30.w, (last)hr9.x
mad.f16 hr7.x, hr0.z, hr31.x, (last)hr7.x
mad.f16 hr19.y, hr0.w, hr29.z, (last)hr19.y
mad.f16 hr17.y, hr0.w, hr29.w, (last)hr17.y
mad.f16 hr15.y, hr0.w, hr30.x, (last)hr15.y
mad.f16 hr13.y, hr0.w, hr30.y, (last)hr13.y
mad.f16 hr11.y, hr0.w, hr30.z, (last)hr11.y
mad.f16 hr9.y, hr0.w, hr30.w, (last)hr9.y
mad.f16 hr7.y, hr0.w, hr31.x, (last)hr7.y
(ss)mad.f16 hr17.z, hr3.z, hr29.z, (last)hr17.z
mad.f16 hr15.z, hr3.z, hr29.w, (last)hr15.z
mad.f16 hr13.z, hr3.z, hr30.x, (last)hr13.z
mad.f16 hr11.z, hr3.z, hr30.y, (last)hr11.z
mad.f16 hr9.z, hr3.z, hr30.z, (last)hr9.z
mad.f16 hr7.z, hr3.z, hr30.w, (last)hr7.z
mad.f16 hr5.z, hr3.z, hr31.x, (last)hr5.z
mad.f16 hr17.w, hr3.w, hr29.z, (last)hr17.w
mad.f16 hr15.w, hr3.w, hr29.w, (last)hr15.w
mad.f16 hr13.w, hr3.w, hr30.x, (last)hr13.w
mad.f16 hr11.w, hr3.w, hr30.y, (last)hr11.w
mad.f16 hr9.w, hr3.w, hr30.z, (last)hr9.w
mad.f16 hr7.w, hr3.w, hr30.w, (last)hr7.w
mad.f16 hr5.w, hr3.w, hr31.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr4.x, hr29.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr4.x, hr29.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr4.x, hr30.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr4.x, hr30.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr4.x, hr30.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr4.x, hr30.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr4.x, hr31.x, (r)(last)hr6.x
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr31.y, (r)(last)hr28.x
(rpt1)mad.f16 hr3.z, (r)(last)hr3.z, hr31.y, (r)(last)hr28.z
ldl.u16 r28.x, l[r10.z+1024], 4
(rpt1)mad.f16 hr4.x, (r)(last)hr4.x, hr31.y, (r)(last)hr29.x
ldl.u16 r29.x, l[r10.z+1152], 4
ldl.u16 r30.x, l[r10.y+3072], 4
ldl.u16 r31.x, l[r10.y+3200], 4
mad.f16 hr18.z, hr22.x, hr4.z, (last)hr18.z
mad.f16 hr16.z, hr22.x, hr4.w, (last)hr16.z
mad.f16 hr14.z, hr22.x, hr5.x, (last)hr14.z
mad.f16 hr12.z, hr22.x, hr5.y, (last)hr12.z
mad.f16 hr10.z, hr22.x, hr19.z, (last)hr10.z
mad.f16 hr8.z, hr22.x, hr19.w, (last)hr8.z
mad.f16 hr6.z, hr22.x, hr20.x, (last)hr6.z
mad.f16 hr18.w, hr22.y, hr4.z, (last)hr18.w
mad.f16 hr16.w, hr22.y, hr4.w, (last)hr16.w
mad.f16 hr14.w, hr22.y, hr5.x, (last)hr14.w
mad.f16 hr12.w, hr22.y, hr5.y, (last)hr12.w
mad.f16 hr10.w, hr22.y, hr19.z, (last)hr10.w
mad.f16 hr8.w, hr22.y, hr19.w, (last)hr8.w
mad.f16 hr6.w, hr22.y, hr20.x, (last)hr6.w
mad.f16 hr19.x, hr22.z, hr4.z, (last)hr19.x
mad.f16 hr17.x, hr22.z, hr4.w, (last)hr17.x
mad.f16 hr15.x, hr22.z, hr5.x, (last)hr15.x
mad.f16 hr13.x, hr22.z, hr5.y, (last)hr13.x
mad.f16 hr11.x, hr22.z, hr19.z, (last)hr11.x
mad.f16 hr9.x, hr22.z, hr19.w, (last)hr9.x
mad.f16 hr7.x, hr22.z, hr20.x, (last)hr7.x
mad.f16 hr19.y, hr22.w, hr4.z, (last)hr19.y
mad.f16 hr17.y, hr22.w, hr4.w, (last)hr17.y
mad.f16 hr15.y, hr22.w, hr5.x, (last)hr15.y
mad.f16 hr13.y, hr22.w, hr5.y, (last)hr13.y
mad.f16 hr11.y, hr22.w, hr19.z, (last)hr11.y
mad.f16 hr9.y, hr22.w, hr19.w, (last)hr9.y
mad.f16 hr7.y, hr22.w, hr20.x, (last)hr7.y
mad.f16 hr17.z, hr23.x, hr4.z, (last)hr17.z
mad.f16 hr15.z, hr23.x, hr4.w, (last)hr15.z
mad.f16 hr13.z, hr23.x, hr5.x, (last)hr13.z
mad.f16 hr11.z, hr23.x, hr5.y, (last)hr11.z
mad.f16 hr9.z, hr23.x, hr19.z, (last)hr9.z
mad.f16 hr7.z, hr23.x, hr19.w, (last)hr7.z
mad.f16 hr5.z, hr23.x, hr20.x, (last)hr5.z
mad.f16 hr17.w, hr23.y, hr4.z, (last)hr17.w
mad.f16 hr15.w, hr23.y, hr4.w, (last)hr15.w
mad.f16 hr13.w, hr23.y, hr5.x, (last)hr13.w
mad.f16 hr11.w, hr23.y, hr5.y, (last)hr11.w
mad.f16 hr9.w, hr23.y, hr19.z, (last)hr9.w
mad.f16 hr7.w, hr23.y, hr19.w, (last)hr7.w
mad.f16 hr5.w, hr23.y, hr20.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr23.z, hr4.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr23.z, hr4.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr23.z, hr5.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr23.z, hr5.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr23.z, hr19.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr23.z, hr19.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr23.z, hr20.x, (r)(last)hr6.x
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr20.y, (r)(last)hr0.x
(rpt1)mad.f16 hr22.z, (r)(last)hr22.z, hr20.y, (r)(last)hr0.z
ldl.u16 r0.x, l[r10.z+1280], 4
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr20.y, (r)(last)hr3.z
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr20.y, (r)(last)hr4.x
ldl.u16 r3.z, l[r10.z+1408], 4
ldl.u16 r4.z, l[r10.y+3328], 4
ldl.u16 r19.z, l[r10.y+3456], 4
mad.f16 hr18.z, hr26.x, hr24.x, (last)hr18.z
mad.f16 hr16.z, hr26.x, hr24.y, (last)hr16.z
mad.f16 hr14.z, hr26.x, hr24.z, (last)hr14.z
mad.f16 hr12.z, hr26.x, hr24.w, (last)hr12.z
mad.f16 hr10.z, hr26.x, hr25.x, (last)hr10.z
mad.f16 hr8.z, hr26.x, hr25.y, (last)hr8.z
mad.f16 hr6.z, hr26.x, hr25.z, (last)hr6.z
mad.f16 hr18.w, hr26.y, hr24.x, (last)hr18.w
mad.f16 hr16.w, hr26.y, hr24.y, (last)hr16.w
mad.f16 hr14.w, hr26.y, hr24.z, (last)hr14.w
mad.f16 hr12.w, hr26.y, hr24.w, (last)hr12.w
mad.f16 hr10.w, hr26.y, hr25.x, (last)hr10.w
mad.f16 hr8.w, hr26.y, hr25.y, (last)hr8.w
mad.f16 hr6.w, hr26.y, hr25.z, (last)hr6.w
mad.f16 hr19.x, hr26.z, hr24.x, (last)hr19.x
mad.f16 hr17.x, hr26.z, hr24.y, (last)hr17.x
mad.f16 hr15.x, hr26.z, hr24.z, (last)hr15.x
mad.f16 hr13.x, hr26.z, hr24.w, (last)hr13.x
mad.f16 hr11.x, hr26.z, hr25.x, (last)hr11.x
mad.f16 hr9.x, hr26.z, hr25.y, (last)hr9.x
mad.f16 hr7.x, hr26.z, hr25.z, (last)hr7.x
mad.f16 hr19.y, hr26.w, hr24.x, (last)hr19.y
mad.f16 hr17.y, hr26.w, hr24.y, (last)hr17.y
mad.f16 hr15.y, hr26.w, hr24.z, (last)hr15.y
mad.f16 hr13.y, hr26.w, hr24.w, (last)hr13.y
mad.f16 hr11.y, hr26.w, hr25.x, (last)hr11.y
mad.f16 hr9.y, hr26.w, hr25.y, (last)hr9.y
mad.f16 hr7.y, hr26.w, hr25.z, (last)hr7.y
mad.f16 hr17.z, hr27.x, hr24.x, (last)hr17.z
mad.f16 hr15.z, hr27.x, hr24.y, (last)hr15.z
mad.f16 hr13.z, hr27.x, hr24.z, (last)hr13.z
mad.f16 hr11.z, hr27.x, hr24.w, (last)hr11.z
mad.f16 hr9.z, hr27.x, hr25.x, (last)hr9.z
mad.f16 hr7.z, hr27.x, hr25.y, (last)hr7.z
mad.f16 hr5.z, hr27.x, hr25.z, (last)hr5.z
mad.f16 hr17.w, hr27.y, hr24.x, (last)hr17.w
mad.f16 hr15.w, hr27.y, hr24.y, (last)hr15.w
mad.f16 hr13.w, hr27.y, hr24.z, (last)hr13.w
mad.f16 hr11.w, hr27.y, hr24.w, (last)hr11.w
mad.f16 hr9.w, hr27.y, hr25.x, (last)hr9.w
mad.f16 hr7.w, hr27.y, hr25.y, (last)hr7.w
mad.f16 hr5.w, hr27.y, hr25.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr27.z, hr24.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr27.z, hr24.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr27.z, hr24.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr27.z, hr24.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr27.z, hr25.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr27.z, hr25.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr27.z, hr25.z, (r)(last)hr6.x
(rpt1)mad.f16 hr26.x, (r)(last)hr26.x, hr25.w, (r)(last)hr22.x
(rpt1)mad.f16 hr26.z, (r)(last)hr26.z, hr25.w, (r)(last)hr22.z
ldl.u16 r22.x, l[r10.z+1536], 4
(rpt1)mad.f16 hr27.x, (r)(last)hr27.x, hr25.w, (r)(last)hr23.x
(rpt1)mad.f16 hr27.z, (r)(last)hr27.z, hr25.w, (r)(last)hr23.z
ldl.u16 r23.x, l[r10.z+1664], 4
ldl.u16 r24.x, l[r10.y+3584], 4
ldl.u16 r25.x, l[r10.y+3712], 4
(ss)mad.f16 hr18.z, hr30.x, hr28.x, (last)hr18.z
mad.f16 hr16.z, hr30.x, hr28.y, (last)hr16.z
mad.f16 hr14.z, hr30.x, hr28.z, (last)hr14.z
mad.f16 hr12.z, hr30.x, hr28.w, (last)hr12.z
mad.f16 hr10.z, hr30.x, hr29.x, (last)hr10.z
mad.f16 hr8.z, hr30.x, hr29.y, (last)hr8.z
mad.f16 hr6.z, hr30.x, hr29.z, (last)hr6.z
mad.f16 hr18.w, hr30.y, hr28.x, (last)hr18.w
mad.f16 hr16.w, hr30.y, hr28.y, (last)hr16.w
mad.f16 hr14.w, hr30.y, hr28.z, (last)hr14.w
mad.f16 hr12.w, hr30.y, hr28.w, (last)hr12.w
mad.f16 hr10.w, hr30.y, hr29.x, (last)hr10.w
mad.f16 hr8.w, hr30.y, hr29.y, (last)hr8.w
mad.f16 hr6.w, hr30.y, hr29.z, (last)hr6.w
mad.f16 hr19.x, hr30.z, hr28.x, (last)hr19.x
mad.f16 hr17.x, hr30.z, hr28.y, (last)hr17.x
mad.f16 hr15.x, hr30.z, hr28.z, (last)hr15.x
mad.f16 hr13.x, hr30.z, hr28.w, (last)hr13.x
mad.f16 hr11.x, hr30.z, hr29.x, (last)hr11.x
mad.f16 hr9.x, hr30.z, hr29.y, (last)hr9.x
mad.f16 hr7.x, hr30.z, hr29.z, (last)hr7.x
mad.f16 hr19.y, hr30.w, hr28.x, (last)hr19.y
mad.f16 hr17.y, hr30.w, hr28.y, (last)hr17.y
mad.f16 hr15.y, hr30.w, hr28.z, (last)hr15.y
mad.f16 hr13.y, hr30.w, hr28.w, (last)hr13.y
mad.f16 hr11.y, hr30.w, hr29.x, (last)hr11.y
mad.f16 hr9.y, hr30.w, hr29.y, (last)hr9.y
mad.f16 hr7.y, hr30.w, hr29.z, (last)hr7.y
mad.f16 hr17.z, hr31.x, hr28.x, (last)hr17.z
mad.f16 hr15.z, hr31.x, hr28.y, (last)hr15.z
mad.f16 hr13.z, hr31.x, hr28.z, (last)hr13.z
mad.f16 hr11.z, hr31.x, hr28.w, (last)hr11.z
mad.f16 hr9.z, hr31.x, hr29.x, (last)hr9.z
mad.f16 hr7.z, hr31.x, hr29.y, (last)hr7.z
mad.f16 hr5.z, hr31.x, hr29.z, (last)hr5.z
mad.f16 hr17.w, hr31.y, hr28.x, (last)hr17.w
mad.f16 hr15.w, hr31.y, hr28.y, (last)hr15.w
mad.f16 hr13.w, hr31.y, hr28.z, (last)hr13.w
mad.f16 hr11.w, hr31.y, hr28.w, (last)hr11.w
mad.f16 hr9.w, hr31.y, hr29.x, (last)hr9.w
mad.f16 hr7.w, hr31.y, hr29.y, (last)hr7.w
mad.f16 hr5.w, hr31.y, hr29.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr31.z, hr28.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr31.z, hr28.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr31.z, hr28.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr31.z, hr28.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr31.z, hr29.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr31.z, hr29.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr31.z, hr29.z, (r)(last)hr6.x
(rpt1)mad.f16 hr30.x, (r)(last)hr30.x, hr29.w, (r)(last)hr26.x
(rpt1)mad.f16 hr30.z, (r)(last)hr30.z, hr29.w, (r)(last)hr26.z
ldl.u16 r26.x, l[r10.z+1792], 4
(rpt1)mad.f16 hr31.x, (r)(last)hr31.x, hr29.w, (r)(last)hr27.x
(rpt1)mad.f16 hr31.z, (r)(last)hr31.z, hr29.w, (r)(last)hr27.z
ldl.u16 r27.x, l[r10.z+1920], 4
ldl.u16 r28.x, l[r10.y+3840], 4
ldl.u16 r29.x, l[r10.y+3968], 4
mad.f16 hr18.z, hr4.z, hr0.x, (last)hr18.z
mad.f16 hr16.z, hr4.z, hr0.y, (last)hr16.z
mad.f16 hr14.z, hr4.z, hr0.z, (last)hr14.z
mad.f16 hr12.z, hr4.z, hr0.w, (last)hr12.z
mad.f16 hr10.z, hr4.z, hr3.z, (last)hr10.z
mad.f16 hr8.z, hr4.z, hr3.w, (last)hr8.z
mad.f16 hr6.z, hr4.z, hr4.x, (last)hr6.z
mad.f16 hr18.w, hr4.w, hr0.x, (last)hr18.w
mad.f16 hr16.w, hr4.w, hr0.y, (last)hr16.w
mad.f16 hr14.w, hr4.w, hr0.z, (last)hr14.w
mad.f16 hr12.w, hr4.w, hr0.w, (last)hr12.w
mad.f16 hr10.w, hr4.w, hr3.z, (last)hr10.w
mad.f16 hr8.w, hr4.w, hr3.w, (last)hr8.w
mad.f16 hr6.w, hr4.w, hr4.x, (last)hr6.w
mad.f16 hr19.x, hr5.x, hr0.x, (last)hr19.x
mad.f16 hr17.x, hr5.x, hr0.y, (last)hr17.x
mad.f16 hr15.x, hr5.x, hr0.z, (last)hr15.x
mad.f16 hr13.x, hr5.x, hr0.w, (last)hr13.x
mad.f16 hr11.x, hr5.x, hr3.z, (last)hr11.x
mad.f16 hr9.x, hr5.x, hr3.w, (last)hr9.x
mad.f16 hr7.x, hr5.x, hr4.x, (last)hr7.x
mad.f16 hr19.y, hr5.y, hr0.x, (last)hr19.y
mad.f16 hr17.y, hr5.y, hr0.y, (last)hr17.y
mad.f16 hr15.y, hr5.y, hr0.z, (last)hr15.y
mad.f16 hr13.y, hr5.y, hr0.w, (last)hr13.y
mad.f16 hr11.y, hr5.y, hr3.z, (last)hr11.y
mad.f16 hr9.y, hr5.y, hr3.w, (last)hr9.y
mad.f16 hr7.y, hr5.y, hr4.x, (last)hr7.y
mad.f16 hr17.z, hr19.z, hr0.x, (last)hr17.z
mad.f16 hr15.z, hr19.z, hr0.y, (last)hr15.z
mad.f16 hr13.z, hr19.z, hr0.z, (last)hr13.z
mad.f16 hr11.z, hr19.z, hr0.w, (last)hr11.z
mad.f16 hr9.z, hr19.z, hr3.z, (last)hr9.z
mad.f16 hr7.z, hr19.z, hr3.w, (last)hr7.z
mad.f16 hr5.z, hr19.z, hr4.x, (last)hr5.z
mad.f16 hr17.w, hr19.w, hr0.x, (last)hr17.w
mad.f16 hr15.w, hr19.w, hr0.y, (last)hr15.w
mad.f16 hr13.w, hr19.w, hr0.z, (last)hr13.w
mad.f16 hr11.w, hr19.w, hr0.w, (last)hr11.w
mad.f16 hr9.w, hr19.w, hr3.z, (last)hr9.w
mad.f16 hr7.w, hr19.w, hr3.w, (last)hr7.w
mad.f16 hr5.w, hr19.w, hr4.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr20.x, hr0.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr20.x, hr0.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr20.x, hr0.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr20.x, hr0.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr20.x, hr3.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr20.x, hr3.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr20.x, hr4.x, (r)(last)hr6.x
(rpt1)mad.f16 hr4.z, (r)(last)hr4.z, hr4.y, (r)(last)hr30.x
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr4.y, (r)(last)hr30.z
(rpt1)mad.f16 hr19.z, (r)(last)hr19.z, hr4.y, (r)(last)hr31.x
(rpt1)mad.f16 hr20.x, (r)(last)hr20.x, hr4.y, (r)(last)hr31.z
mad.f16 hr18.z, hr24.x, hr22.x, (last)hr18.z
mad.f16 hr16.z, hr24.x, hr22.y, (last)hr16.z
mad.f16 hr14.z, hr24.x, hr22.z, (last)hr14.z
mad.f16 hr12.z, hr24.x, hr22.w, (last)hr12.z
mad.f16 hr10.z, hr24.x, hr23.x, (last)hr10.z
mad.f16 hr8.z, hr24.x, hr23.y, (last)hr8.z
mad.f16 hr6.z, hr24.x, hr23.z, (last)hr6.z
mad.f16 hr18.w, hr24.y, hr22.x, (last)hr18.w
mad.f16 hr16.w, hr24.y, hr22.y, (last)hr16.w
mad.f16 hr14.w, hr24.y, hr22.z, (last)hr14.w
mad.f16 hr12.w, hr24.y, hr22.w, (last)hr12.w
mad.f16 hr10.w, hr24.y, hr23.x, (last)hr10.w
mad.f16 hr8.w, hr24.y, hr23.y, (last)hr8.w
mad.f16 hr6.w, hr24.y, hr23.z, (last)hr6.w
mad.f16 hr19.x, hr24.z, hr22.x, (last)hr19.x
mad.f16 hr17.x, hr24.z, hr22.y, (last)hr17.x
mad.f16 hr15.x, hr24.z, hr22.z, (last)hr15.x
mad.f16 hr13.x, hr24.z, hr22.w, (last)hr13.x
mad.f16 hr11.x, hr24.z, hr23.x, (last)hr11.x
mad.f16 hr9.x, hr24.z, hr23.y, (last)hr9.x
mad.f16 hr7.x, hr24.z, hr23.z, (last)hr7.x
mad.f16 hr19.y, hr24.w, hr22.x, (last)hr19.y
mad.f16 hr17.y, hr24.w, hr22.y, (last)hr17.y
mad.f16 hr15.y, hr24.w, hr22.z, (last)hr15.y
mad.f16 hr13.y, hr24.w, hr22.w, (last)hr13.y
mad.f16 hr11.y, hr24.w, hr23.x, (last)hr11.y
mad.f16 hr9.y, hr24.w, hr23.y, (last)hr9.y
mad.f16 hr7.y, hr24.w, hr23.z, (last)hr7.y
mad.f16 hr17.z, hr25.x, hr22.x, (last)hr17.z
mad.f16 hr15.z, hr25.x, hr22.y, (last)hr15.z
mad.f16 hr13.z, hr25.x, hr22.z, (last)hr13.z
mad.f16 hr11.z, hr25.x, hr22.w, (last)hr11.z
mad.f16 hr9.z, hr25.x, hr23.x, (last)hr9.z
mad.f16 hr7.z, hr25.x, hr23.y, (last)hr7.z
mad.f16 hr5.z, hr25.x, hr23.z, (last)hr5.z
mad.f16 hr17.w, hr25.y, hr22.x, (last)hr17.w
mad.f16 hr15.w, hr25.y, hr22.y, (last)hr15.w
mad.f16 hr13.w, hr25.y, hr22.z, (last)hr13.w
mad.f16 hr11.w, hr25.y, hr22.w, (last)hr11.w
mad.f16 hr9.w, hr25.y, hr23.x, (last)hr9.w
mad.f16 hr7.w, hr25.y, hr23.y, (last)hr7.w
mad.f16 hr5.w, hr25.y, hr23.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr25.z, hr22.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr25.z, hr22.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr25.z, hr22.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr25.z, hr22.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr25.z, hr23.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr25.z, hr23.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr25.z, hr23.z, (r)(last)hr6.x
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr23.w, (r)(last)hr4.z
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr23.w, (r)(last)hr5.x
(rpt1)mad.f16 hr25.x, (r)(last)hr25.x, hr23.w, (r)(last)hr19.z
(rpt1)mad.f16 hr25.z, (r)(last)hr25.z, hr23.w, (r)(last)hr20.x
fence.r.w
(sy)(ss)mad.f16 hr18.z, hr28.x, hr26.x, (last)hr18.z
mad.f16 hr16.z, hr28.x, hr26.y, (last)hr16.z
mad.f16 hr14.z, hr28.x, hr26.z, (last)hr14.z
mad.f16 hr12.z, hr28.x, hr26.w, (last)hr12.z
mad.f16 hr10.z, hr28.x, hr27.x, (last)hr10.z
mad.f16 hr8.z, hr28.x, hr27.y, (last)hr8.z
mad.f16 hr6.z, hr28.x, hr27.z, (last)hr6.z
mad.f16 hr18.w, hr28.y, hr26.x, (last)hr18.w
mad.f16 hr16.w, hr28.y, hr26.y, (last)hr16.w
mad.f16 hr14.w, hr28.y, hr26.z, (last)hr14.w
mad.f16 hr12.w, hr28.y, hr26.w, (last)hr12.w
mad.f16 hr10.w, hr28.y, hr27.x, (last)hr10.w
mad.f16 hr8.w, hr28.y, hr27.y, (last)hr8.w
mad.f16 hr6.w, hr28.y, hr27.z, (last)hr6.w
mad.f16 hr19.x, hr28.z, hr26.x, (last)hr19.x
mad.f16 hr17.x, hr28.z, hr26.y, (last)hr17.x
mad.f16 hr15.x, hr28.z, hr26.z, (last)hr15.x
mad.f16 hr13.x, hr28.z, hr26.w, (last)hr13.x
mad.f16 hr11.x, hr28.z, hr27.x, (last)hr11.x
mad.f16 hr9.x, hr28.z, hr27.y, (last)hr9.x
mad.f16 hr7.x, hr28.z, hr27.z, (last)hr7.x
mad.f16 hr19.y, hr28.w, hr26.x, (last)hr19.y
mad.f16 hr17.y, hr28.w, hr26.y, (last)hr17.y
mad.f16 hr15.y, hr28.w, hr26.z, (last)hr15.y
mad.f16 hr13.y, hr28.w, hr26.w, (last)hr13.y
mad.f16 hr11.y, hr28.w, hr27.x, (last)hr11.y
mad.f16 hr9.y, hr28.w, hr27.y, (last)hr9.y
mad.f16 hr7.y, hr28.w, hr27.z, (last)hr7.y
mad.f16 hr17.z, hr29.x, hr26.x, (last)hr17.z
mad.f16 hr15.z, hr29.x, hr26.y, (last)hr15.z
mad.f16 hr13.z, hr29.x, hr26.z, (last)hr13.z
mad.f16 hr11.z, hr29.x, hr26.w, (last)hr11.z
mad.f16 hr9.z, hr29.x, hr27.x, (last)hr9.z
mad.f16 hr7.z, hr29.x, hr27.y, (last)hr7.z
mad.f16 hr5.z, hr29.x, hr27.z, (last)hr5.z
mad.f16 hr17.w, hr29.y, hr26.x, (last)hr17.w
mad.f16 hr15.w, hr29.y, hr26.y, (last)hr15.w
mad.f16 hr13.w, hr29.y, hr26.z, (last)hr13.w
mad.f16 hr11.w, hr29.y, hr26.w, (last)hr11.w
mad.f16 hr9.w, hr29.y, hr27.x, (last)hr9.w
mad.f16 hr7.w, hr29.y, hr27.y, (last)hr7.w
mad.f16 hr5.w, hr29.y, hr27.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr29.z, hr26.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr29.z, hr26.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr29.z, hr26.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr29.z, hr26.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr29.z, hr27.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr29.z, hr27.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr29.z, hr27.z, (r)(last)hr6.x
(rpt1)mad.f16 hr4.z, (r)(last)hr28.x, hr27.w, (r)(last)hr24.x
(rpt1)mad.f16 hr5.x, (r)(last)hr28.z, hr27.w, (r)(last)hr24.z
(rpt1)mad.f16 hr3.z, (r)(last)hr29.x, hr27.w, (r)(last)hr25.x
(rpt1)mad.f16 hr4.x, (r)(last)hr29.z, hr27.w, (r)(last)hr25.z
bar.g
(sy)(ss)br p0.x, #l585
jump #l99
l585:
(jp)(eolm)nop
shr.b r53.x, r53.x, 2
(nop3) add.u r10.w, r52.w, (last)r10.w
(nop3) shl.b r10.w, (last)r10.w, 9
(ss)(nop3) sad.s32 r10.w, r53.x, r10.w, (last)r1.y
(nop3) shl.b r10.w, (last)r10.w, 2
(rpt3)add.u r15.x, r10.w, (r)c1.x
(rpt2)add.u r0.x, r10.w, (r)c2.x
(rpt1)add.u r0.w, (r)c2.w, r10.w
(rpt1)add.u r1.y, (r)c3.y, r10.w
stib.b.untyped.1d.u16.4.imm.base0 hr18.z, r10.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r10.w+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r15.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r15.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r15.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r15.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r0.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r0.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r0.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r0.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r1.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r1.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r1.z, 4
(ss)(rpt1)add.u r3.y, (r)c3.w, r10.w
(nop3) add.u r10.w, c4.y, (last)r10.w
nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r3.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r3.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r10.w, 4
end
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 719 instr, 38 nops, 681 non-nops, 65 mov, 0 cov, 1254 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 16 full, 8 constlen
; CL prog 23/1: 41 cat0, 65 cat1, 44 cat2, 513 cat3, 0 cat4, 2 cat5, 50 cat6, 4 cat7
; CL prog 23/1: 20 sstall, 10 (ss), 39 systall, 5 (sy), 1 loops
; CL prog 23/1: 16 max_waves, 0 double_threadsize
; 27 preamble-instr, 1 early-preamble
