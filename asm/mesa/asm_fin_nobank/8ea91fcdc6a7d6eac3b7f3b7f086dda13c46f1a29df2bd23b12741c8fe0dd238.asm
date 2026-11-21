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
@const(c2.x)	0x00001800, 0x00001840, 0x00010000, 0x00010040
@const(c3.x)	0x00010800, 0x00010840, 0x00011000, 0x00011040
@const(c4.x)	0x00011800, 0x00011840, 0xd0d0d0d0, 0xd0d0d0d0
shps #l27
getone #l27
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 2112
mov.u32u32 r49.y, 4096
mov.u32u32 r49.z, 0x1040
mov.u32u32 r49.w, 0x1800
mov.u32u32 r50.x, 0x1840
mov.u32u32 r50.y, 0x10000
mov.u32u32 r50.z, 0x10040
mov.u32u32 r50.w, 0x10800
mov.u32u32 r51.x, 0x10840
mov.u32u32 r51.y, 0x11000
mov.u32u32 r51.z, 0x11040
mov.u32u32 r51.w, 0x11800
mov.u32u32 r52.x, 0x11840
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
shl.b r52.w, r52.z, 6
shr.b r0.w, r0.x, 4
shr.b r1.x, r0.x, 5
and.b r1.y, r0.x, 15
and.b r1.z, r0.x, 31
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
(rpt1)shr.b r53.z, (r)r52.w, 2
add.u r54.x, r53.y, 8
cmps.u.ge up0.x, r54.x, c1.x
add.u r11.w, r0.x, 128
shl.b r9.w, r0.w, 7
shl.b r10.y, r1.y, 3
shl.b r10.x, r1.x, 8
shr.b r11.w, (last)r11.w, 5
shl.b r10.z, r1.z, 3
(ss)(rpt1)add.u r10.w, r53.y, (r)r0.w
add.u r12.y, r53.y, r11.w
shl.b r11.w, (last)r11.w, 8
(rpt1)shl.b r10.w, (last)(r)r10.w, 9
shl.b r12.y, (last)r12.y, 9
shl.b r12.x, r0.w, 3
(rpt1)sad.s32 r10.w, (r)r53.z, (r)r10.w, (r)r1.y
sad.s32 r12.y, r53.w, r12.y, r1.z
add.u r9.w, (last)r9.w, r10.y
(rpt1)shl.b r10.w, (last)(r)r10.w, 2
shl.b r12.y, (last)r12.y, 2
add.u r10.x, (last)r10.x, r10.z
add.u r11.w, (last)r11.w, (last)r10.z
(nop1) shl.b r12.z, r0.w, 2
isam.v.base0 (u16)(xyzw)hr22.z, r10.w, s#0, t#0
nop
isam.v.base0 (u16)(xyzw)hr25.z, r11.x, s#0, t#2
nop
isam.v.base0 (u16)(xyzw)hr26.z, r12.y, s#0, t#2
(sy)stl.u16 l[r9.w], r22.z, 4
nop
stl.u16 l[r10.x+1024], r25.z, 4
nop
stl.u16 l[r11.w+1024], r26.z, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
ldl.u16 r27.z, l[r12.x], 4
ldl.u16 r28.z, l[r12.x+64], 4
ldl.u16 r29.z, l[r10.y+1024], 4
ldl.u16 r30.z, l[r10.y+1152], 4
ldl.u16 r0.z, l[r12.x+128], 4
(ss)mad.f16 hr18.z, hr29.z, hr27.z, (last)hr18.z
mad.f16 hr16.z, hr29.z, hr27.w, (last)hr16.z
mad.f16 hr14.z, hr29.z, hr28.x, (last)hr14.z
mad.f16 hr12.z, hr29.z, hr28.y, (last)hr12.z
mad.f16 hr10.z, hr29.z, hr28.z, (last)hr10.z
mad.f16 hr8.z, hr29.z, hr28.w, (last)hr8.z
mad.f16 hr6.z, hr29.z, hr29.x, (last)hr6.z
mad.f16 hr18.w, hr29.w, hr27.z, (last)hr18.w
mad.f16 hr16.w, hr29.w, hr27.w, (last)hr16.w
mad.f16 hr14.w, hr29.w, hr28.x, (last)hr14.w
mad.f16 hr12.w, hr29.w, hr28.y, (last)hr12.w
mad.f16 hr10.w, hr29.w, hr28.z, (last)hr10.w
mad.f16 hr8.w, hr29.w, hr28.w, (last)hr8.w
mad.f16 hr6.w, hr29.w, hr29.x, (last)hr6.w
mad.f16 hr19.x, hr30.x, hr27.z, (last)hr19.x
mad.f16 hr17.x, hr30.x, hr27.w, (last)hr17.x
mad.f16 hr15.x, hr30.x, hr28.x, (last)hr15.x
mad.f16 hr13.x, hr30.x, hr28.y, (last)hr13.x
mad.f16 hr11.x, hr30.x, hr28.z, (last)hr11.x
mad.f16 hr9.x, hr30.x, hr28.w, (last)hr9.x
mad.f16 hr7.x, hr30.x, hr29.x, (last)hr7.x
mad.f16 hr19.y, hr30.y, hr27.z, (last)hr19.y
mad.f16 hr17.y, hr30.y, hr27.w, (last)hr17.y
mad.f16 hr15.y, hr30.y, hr28.x, (last)hr15.y
mad.f16 hr13.y, hr30.y, hr28.y, (last)hr13.y
mad.f16 hr11.y, hr30.y, hr28.z, (last)hr11.y
mad.f16 hr9.y, hr30.y, hr28.w, (last)hr9.y
mad.f16 hr7.y, hr30.y, hr29.x, (last)hr7.y
mad.f16 hr17.z, hr30.z, hr27.z, (last)hr17.z
mad.f16 hr15.z, hr30.z, hr27.w, (last)hr15.z
mad.f16 hr13.z, hr30.z, hr28.x, (last)hr13.z
mad.f16 hr11.z, hr30.z, hr28.y, (last)hr11.z
mad.f16 hr9.z, hr30.z, hr28.z, (last)hr9.z
mad.f16 hr7.z, hr30.z, hr28.w, (last)hr7.z
mad.f16 hr5.z, hr30.z, hr29.x, (last)hr5.z
mad.f16 hr17.w, hr30.w, hr27.z, (last)hr17.w
mad.f16 hr15.w, hr30.w, hr27.w, (last)hr15.w
mad.f16 hr13.w, hr30.w, hr28.x, (last)hr13.w
mad.f16 hr11.w, hr30.w, hr28.y, (last)hr11.w
mad.f16 hr9.w, hr30.w, hr28.z, (last)hr9.w
mad.f16 hr7.w, hr30.w, hr28.w, (last)hr7.w
mad.f16 hr5.w, hr30.w, hr29.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr31.x, hr27.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr31.x, hr27.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr31.x, hr28.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr31.x, hr28.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr31.x, hr28.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr31.x, hr28.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr31.x, hr29.x, (r)(last)hr6.x
(rpt1)mad.f16 hr29.z, (r)(last)hr29.z, hr29.y, (r)(last)hr4.z
(rpt1)mad.f16 hr30.x, (r)(last)hr30.x, hr29.y, (r)(last)hr5.x
(rpt1)mad.f16 hr30.z, (r)(last)hr30.z, hr29.y, (r)(last)hr3.z
(rpt1)mad.f16 hr31.x, (r)(last)hr31.x, hr29.y, (r)(last)hr4.x
ldl.u16 r3.z, l[r12.x+192], 4
ldl.u16 r4.z, l[r10.y+1280], 4
ldl.u16 r19.z, l[r10.y+1408], 4
ldl.u16 r21.x, l[r12.x+256], 4
ldl.u16 r22.x, l[r12.x+320], 4
ldl.u16 r23.x, l[r10.y+1536], 4
ldl.u16 r25.z, l[r10.y+1664], 4
ldl.u16 r26.z, l[r12.x+384], 4
ldl.u16 r27.z, l[r12.x+448], 4
ldl.u16 r28.z, l[r10.y+1792], 4
(ss)mad.f16 hr18.z, hr4.z, hr0.z, (last)hr18.z
mad.f16 hr16.z, hr4.z, hr0.w, (last)hr16.z
mad.f16 hr14.z, hr4.z, hr1.x, (last)hr14.z
mad.f16 hr12.z, hr4.z, hr1.y, (last)hr12.z
mad.f16 hr10.z, hr4.z, hr3.z, (last)hr10.z
mad.f16 hr8.z, hr4.z, hr3.w, (last)hr8.z
mad.f16 hr6.z, hr4.z, hr4.x, (last)hr6.z
mad.f16 hr18.w, hr4.w, hr0.z, (last)hr18.w
mad.f16 hr16.w, hr4.w, hr0.w, (last)hr16.w
mad.f16 hr14.w, hr4.w, hr1.x, (last)hr14.w
mad.f16 hr12.w, hr4.w, hr1.y, (last)hr12.w
mad.f16 hr10.w, hr4.w, hr3.z, (last)hr10.w
mad.f16 hr8.w, hr4.w, hr3.w, (last)hr8.w
mad.f16 hr6.w, hr4.w, hr4.x, (last)hr6.w
mad.f16 hr19.x, hr5.x, hr0.z, (last)hr19.x
mad.f16 hr17.x, hr5.x, hr0.w, (last)hr17.x
mad.f16 hr15.x, hr5.x, hr1.x, (last)hr15.x
mad.f16 hr13.x, hr5.x, hr1.y, (last)hr13.x
mad.f16 hr11.x, hr5.x, hr3.z, (last)hr11.x
mad.f16 hr9.x, hr5.x, hr3.w, (last)hr9.x
mad.f16 hr7.x, hr5.x, hr4.x, (last)hr7.x
mad.f16 hr19.y, hr5.y, hr0.z, (last)hr19.y
mad.f16 hr17.y, hr5.y, hr0.w, (last)hr17.y
mad.f16 hr15.y, hr5.y, hr1.x, (last)hr15.y
mad.f16 hr13.y, hr5.y, hr1.y, (last)hr13.y
mad.f16 hr11.y, hr5.y, hr3.z, (last)hr11.y
mad.f16 hr9.y, hr5.y, hr3.w, (last)hr9.y
mad.f16 hr7.y, hr5.y, hr4.x, (last)hr7.y
mad.f16 hr17.z, hr19.z, hr0.z, (last)hr17.z
mad.f16 hr15.z, hr19.z, hr0.w, (last)hr15.z
mad.f16 hr13.z, hr19.z, hr1.x, (last)hr13.z
mad.f16 hr11.z, hr19.z, hr1.y, (last)hr11.z
mad.f16 hr9.z, hr19.z, hr3.z, (last)hr9.z
mad.f16 hr7.z, hr19.z, hr3.w, (last)hr7.z
mad.f16 hr5.z, hr19.z, hr4.x, (last)hr5.z
mad.f16 hr17.w, hr19.w, hr0.z, (last)hr17.w
mad.f16 hr15.w, hr19.w, hr0.w, (last)hr15.w
mad.f16 hr13.w, hr19.w, hr1.x, (last)hr13.w
mad.f16 hr11.w, hr19.w, hr1.y, (last)hr11.w
mad.f16 hr9.w, hr19.w, hr3.z, (last)hr9.w
mad.f16 hr7.w, hr19.w, hr3.w, (last)hr7.w
mad.f16 hr5.w, hr19.w, hr4.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr20.x, hr0.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr20.x, hr0.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr20.x, hr1.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr20.x, hr1.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr20.x, hr3.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr20.x, hr3.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr20.x, hr4.x, (r)(last)hr6.x
(rpt1)mad.f16 hr4.z, (r)(last)hr4.z, hr4.y, (r)(last)hr29.z
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr4.y, (r)(last)hr30.x
ldl.u16 r29.z, l[r10.y+1920], 4
(rpt1)mad.f16 hr19.z, (r)(last)hr19.z, hr4.y, (r)(last)hr30.z
(rpt1)mad.f16 hr20.x, (r)(last)hr20.x, hr4.y, (r)(last)hr31.x
ldl.u16 r30.z, l[r12.x+512], 4
ldl.u16 r0.z, l[r12.x+576], 4
ldl.u16 r3.z, l[r10.y+2048], 4
mad.f16 hr18.z, hr23.x, hr21.x, (last)hr18.z
mad.f16 hr16.z, hr23.x, hr21.y, (last)hr16.z
mad.f16 hr14.z, hr23.x, hr21.z, (last)hr14.z
mad.f16 hr12.z, hr23.x, hr21.w, (last)hr12.z
mad.f16 hr10.z, hr23.x, hr22.x, (last)hr10.z
mad.f16 hr8.z, hr23.x, hr22.y, (last)hr8.z
mad.f16 hr6.z, hr23.x, hr22.z, (last)hr6.z
mad.f16 hr18.w, hr23.y, hr21.x, (last)hr18.w
mad.f16 hr16.w, hr23.y, hr21.y, (last)hr16.w
mad.f16 hr14.w, hr23.y, hr21.z, (last)hr14.w
mad.f16 hr12.w, hr23.y, hr21.w, (last)hr12.w
mad.f16 hr10.w, hr23.y, hr22.x, (last)hr10.w
mad.f16 hr8.w, hr23.y, hr22.y, (last)hr8.w
mad.f16 hr6.w, hr23.y, hr22.z, (last)hr6.w
mad.f16 hr19.x, hr23.z, hr21.x, (last)hr19.x
mad.f16 hr17.x, hr23.z, hr21.y, (last)hr17.x
mad.f16 hr15.x, hr23.z, hr21.z, (last)hr15.x
mad.f16 hr13.x, hr23.z, hr21.w, (last)hr13.x
mad.f16 hr11.x, hr23.z, hr22.x, (last)hr11.x
mad.f16 hr9.x, hr23.z, hr22.y, (last)hr9.x
mad.f16 hr7.x, hr23.z, hr22.z, (last)hr7.x
mad.f16 hr19.y, hr23.w, hr21.x, (last)hr19.y
mad.f16 hr17.y, hr23.w, hr21.y, (last)hr17.y
mad.f16 hr15.y, hr23.w, hr21.z, (last)hr15.y
mad.f16 hr13.y, hr23.w, hr21.w, (last)hr13.y
mad.f16 hr11.y, hr23.w, hr22.x, (last)hr11.y
mad.f16 hr9.y, hr23.w, hr22.y, (last)hr9.y
mad.f16 hr7.y, hr23.w, hr22.z, (last)hr7.y
mad.f16 hr17.z, hr25.z, hr21.x, (last)hr17.z
mad.f16 hr15.z, hr25.z, hr21.y, (last)hr15.z
mad.f16 hr13.z, hr25.z, hr21.z, (last)hr13.z
mad.f16 hr11.z, hr25.z, hr21.w, (last)hr11.z
mad.f16 hr9.z, hr25.z, hr22.x, (last)hr9.z
mad.f16 hr7.z, hr25.z, hr22.y, (last)hr7.z
mad.f16 hr5.z, hr25.z, hr22.z, (last)hr5.z
mad.f16 hr17.w, hr25.w, hr21.x, (last)hr17.w
mad.f16 hr15.w, hr25.w, hr21.y, (last)hr15.w
mad.f16 hr13.w, hr25.w, hr21.z, (last)hr13.w
mad.f16 hr11.w, hr25.w, hr21.w, (last)hr11.w
mad.f16 hr9.w, hr25.w, hr22.x, (last)hr9.w
mad.f16 hr7.w, hr25.w, hr22.y, (last)hr7.w
mad.f16 hr5.w, hr25.w, hr22.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr26.x, hr21.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr26.x, hr21.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr26.x, hr21.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr26.x, hr21.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr26.x, hr22.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr26.x, hr22.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr26.x, hr22.z, (r)(last)hr6.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr22.w, (r)(last)hr4.z
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr22.w, (r)(last)hr5.x
ldl.u16 r4.z, l[r10.y+2176], 4
(rpt1)mad.f16 hr25.z, (r)(last)hr25.z, hr22.w, (r)(last)hr19.z
(rpt1)mad.f16 hr26.x, (r)(last)hr26.x, hr22.w, (r)(last)hr20.x
ldl.u16 r19.z, l[r12.x+640], 4
ldl.u16 r21.x, l[r12.x+704], 4
ldl.u16 r22.x, l[r10.y+2304], 4
mad.f16 hr18.z, hr28.z, hr26.z, (last)hr18.z
mad.f16 hr16.z, hr28.z, hr26.w, (last)hr16.z
mad.f16 hr14.z, hr28.z, hr27.x, (last)hr14.z
mad.f16 hr12.z, hr28.z, hr27.y, (last)hr12.z
mad.f16 hr10.z, hr28.z, hr27.z, (last)hr10.z
mad.f16 hr8.z, hr28.z, hr27.w, (last)hr8.z
mad.f16 hr6.z, hr28.z, hr28.x, (last)hr6.z
mad.f16 hr18.w, hr28.w, hr26.z, (last)hr18.w
mad.f16 hr16.w, hr28.w, hr26.w, (last)hr16.w
mad.f16 hr14.w, hr28.w, hr27.x, (last)hr14.w
mad.f16 hr12.w, hr28.w, hr27.y, (last)hr12.w
mad.f16 hr10.w, hr28.w, hr27.z, (last)hr10.w
mad.f16 hr8.w, hr28.w, hr27.w, (last)hr8.w
mad.f16 hr6.w, hr28.w, hr28.x, (last)hr6.w
mad.f16 hr19.x, hr29.x, hr26.z, (last)hr19.x
mad.f16 hr17.x, hr29.x, hr26.w, (last)hr17.x
mad.f16 hr15.x, hr29.x, hr27.x, (last)hr15.x
mad.f16 hr13.x, hr29.x, hr27.y, (last)hr13.x
mad.f16 hr11.x, hr29.x, hr27.z, (last)hr11.x
mad.f16 hr9.x, hr29.x, hr27.w, (last)hr9.x
mad.f16 hr7.x, hr29.x, hr28.x, (last)hr7.x
mad.f16 hr19.y, hr29.y, hr26.z, (last)hr19.y
mad.f16 hr17.y, hr29.y, hr26.w, (last)hr17.y
mad.f16 hr15.y, hr29.y, hr27.x, (last)hr15.y
mad.f16 hr13.y, hr29.y, hr27.y, (last)hr13.y
mad.f16 hr11.y, hr29.y, hr27.z, (last)hr11.y
mad.f16 hr9.y, hr29.y, hr27.w, (last)hr9.y
mad.f16 hr7.y, hr29.y, hr28.x, (last)hr7.y
(rpt1)mad.f16 hr28.z, (r)(last)hr28.z, hr28.y, (r)(last)hr23.x
(rpt1)mad.f16 hr29.x, (r)(last)hr29.x, hr28.y, (r)(last)hr23.z
ldl.u16 r23.x, l[r10.y+2432], 4
(ss)mad.f16 hr17.z, hr29.z, hr26.z, (last)hr17.z
mad.f16 hr15.z, hr29.z, hr26.w, (last)hr15.z
mad.f16 hr13.z, hr29.z, hr27.x, (last)hr13.z
mad.f16 hr11.z, hr29.z, hr27.y, (last)hr11.z
mad.f16 hr9.z, hr29.z, hr27.z, (last)hr9.z
mad.f16 hr7.z, hr29.z, hr27.w, (last)hr7.z
mad.f16 hr5.z, hr29.z, hr28.x, (last)hr5.z
mad.f16 hr17.w, hr29.w, hr26.z, (last)hr17.w
mad.f16 hr15.w, hr29.w, hr26.w, (last)hr15.w
mad.f16 hr13.w, hr29.w, hr27.x, (last)hr13.w
mad.f16 hr11.w, hr29.w, hr27.y, (last)hr11.w
mad.f16 hr9.w, hr29.w, hr27.z, (last)hr9.w
mad.f16 hr7.w, hr29.w, hr27.w, (last)hr7.w
mad.f16 hr5.w, hr29.w, hr28.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr30.x, hr26.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr30.x, hr26.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr30.x, hr27.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr30.x, hr27.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr30.x, hr27.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr30.x, hr27.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr30.x, hr28.x, (r)(last)hr6.x
mad.f16 hr18.z, hr3.z, hr30.z, (last)hr18.z
mad.f16 hr16.z, hr3.z, hr30.w, (last)hr16.z
mad.f16 hr14.z, hr3.z, hr31.x, (last)hr14.z
mad.f16 hr12.z, hr3.z, hr31.y, (last)hr12.z
mad.f16 hr10.z, hr3.z, hr0.z, (last)hr10.z
mad.f16 hr8.z, hr3.z, hr0.w, (last)hr8.z
mad.f16 hr6.z, hr3.z, hr1.x, (last)hr6.z
mad.f16 hr18.w, hr3.w, hr30.z, (last)hr18.w
mad.f16 hr16.w, hr3.w, hr30.w, (last)hr16.w
mad.f16 hr14.w, hr3.w, hr31.x, (last)hr14.w
mad.f16 hr12.w, hr3.w, hr31.y, (last)hr12.w
mad.f16 hr10.w, hr3.w, hr0.z, (last)hr10.w
mad.f16 hr8.w, hr3.w, hr0.w, (last)hr8.w
mad.f16 hr6.w, hr3.w, hr1.x, (last)hr6.w
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
(rpt1)mad.f16 hr29.z, (r)(last)hr29.z, hr28.y, (r)(last)hr25.z
(rpt1)mad.f16 hr30.x, (r)(last)hr30.x, hr28.y, (r)(last)hr26.x
ldl.u16 r25.z, l[r12.x+768], 4
ldl.u16 r26.z, l[r12.x+832], 4
ldl.u16 r27.z, l[r10.y+2560], 4
(rpt1)mad.f16 hr3.z, (r)(last)hr3.z, hr1.y, (r)(last)hr28.z
(rpt1)mad.f16 hr4.x, (r)(last)hr4.x, hr1.y, (r)(last)hr29.x
ldl.u16 r28.z, l[r10.y+2688], 4
mad.f16 hr17.z, hr4.z, hr30.z, (last)hr17.z
mad.f16 hr15.z, hr4.z, hr30.w, (last)hr15.z
mad.f16 hr13.z, hr4.z, hr31.x, (last)hr13.z
mad.f16 hr11.z, hr4.z, hr31.y, (last)hr11.z
mad.f16 hr9.z, hr4.z, hr0.z, (last)hr9.z
mad.f16 hr7.z, hr4.z, hr0.w, (last)hr7.z
mad.f16 hr5.z, hr4.z, hr1.x, (last)hr5.z
mad.f16 hr17.w, hr4.w, hr30.z, (last)hr17.w
mad.f16 hr15.w, hr4.w, hr30.w, (last)hr15.w
mad.f16 hr13.w, hr4.w, hr31.x, (last)hr13.w
mad.f16 hr11.w, hr4.w, hr31.y, (last)hr11.w
mad.f16 hr9.w, hr4.w, hr0.z, (last)hr9.w
mad.f16 hr7.w, hr4.w, hr0.w, (last)hr7.w
mad.f16 hr5.w, hr4.w, hr1.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr5.x, hr30.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr5.x, hr30.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr5.x, hr31.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr5.x, hr31.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr5.x, hr0.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr5.x, hr0.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr5.x, hr1.x, (r)(last)hr6.x
mad.f16 hr18.z, hr22.x, hr19.z, (last)hr18.z
mad.f16 hr16.z, hr22.x, hr19.w, (last)hr16.z
mad.f16 hr14.z, hr22.x, hr20.x, (last)hr14.z
mad.f16 hr12.z, hr22.x, hr20.y, (last)hr12.z
mad.f16 hr10.z, hr22.x, hr21.x, (last)hr10.z
mad.f16 hr8.z, hr22.x, hr21.y, (last)hr8.z
mad.f16 hr6.z, hr22.x, hr21.z, (last)hr6.z
mad.f16 hr18.w, hr22.y, hr19.z, (last)hr18.w
mad.f16 hr16.w, hr22.y, hr19.w, (last)hr16.w
mad.f16 hr14.w, hr22.y, hr20.x, (last)hr14.w
mad.f16 hr12.w, hr22.y, hr20.y, (last)hr12.w
mad.f16 hr10.w, hr22.y, hr21.x, (last)hr10.w
mad.f16 hr8.w, hr22.y, hr21.y, (last)hr8.w
mad.f16 hr6.w, hr22.y, hr21.z, (last)hr6.w
mad.f16 hr19.x, hr22.z, hr19.z, (last)hr19.x
mad.f16 hr17.x, hr22.z, hr19.w, (last)hr17.x
mad.f16 hr15.x, hr22.z, hr20.x, (last)hr15.x
mad.f16 hr13.x, hr22.z, hr20.y, (last)hr13.x
mad.f16 hr11.x, hr22.z, hr21.x, (last)hr11.x
mad.f16 hr9.x, hr22.z, hr21.y, (last)hr9.x
mad.f16 hr7.x, hr22.z, hr21.z, (last)hr7.x
mad.f16 hr19.y, hr22.w, hr19.z, (last)hr19.y
mad.f16 hr17.y, hr22.w, hr19.w, (last)hr17.y
mad.f16 hr15.y, hr22.w, hr20.x, (last)hr15.y
mad.f16 hr13.y, hr22.w, hr20.y, (last)hr13.y
mad.f16 hr11.y, hr22.w, hr21.x, (last)hr11.y
mad.f16 hr9.y, hr22.w, hr21.y, (last)hr9.y
mad.f16 hr7.y, hr22.w, hr21.z, (last)hr7.y
(rpt1)mad.f16 hr4.z, (r)(last)hr4.z, hr1.y, (r)(last)hr29.z
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr1.y, (r)(last)hr30.x
ldl.u16 r29.z, l[r12.x+896], 4
ldl.u16 r30.z, l[r12.x+960], 4
ldl.u16 r0.z, l[r10.y+2816], 4
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr21.w, (r)(last)hr3.z
(rpt1)mad.f16 hr22.z, (r)(last)hr22.z, hr21.w, (r)(last)hr4.x
ldl.u16 r3.z, l[r10.y+2944], 4
mad.f16 hr17.z, hr23.x, hr19.z, (last)hr17.z
mad.f16 hr15.z, hr23.x, hr19.w, (last)hr15.z
mad.f16 hr13.z, hr23.x, hr20.x, (last)hr13.z
mad.f16 hr11.z, hr23.x, hr20.y, (last)hr11.z
mad.f16 hr9.z, hr23.x, hr21.x, (last)hr9.z
mad.f16 hr7.z, hr23.x, hr21.y, (last)hr7.z
mad.f16 hr5.z, hr23.x, hr21.z, (last)hr5.z
mad.f16 hr17.w, hr23.y, hr19.z, (last)hr17.w
mad.f16 hr15.w, hr23.y, hr19.w, (last)hr15.w
mad.f16 hr13.w, hr23.y, hr20.x, (last)hr13.w
mad.f16 hr11.w, hr23.y, hr20.y, (last)hr11.w
mad.f16 hr9.w, hr23.y, hr21.x, (last)hr9.w
mad.f16 hr7.w, hr23.y, hr21.y, (last)hr7.w
mad.f16 hr5.w, hr23.y, hr21.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr23.z, hr19.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr23.z, hr19.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr23.z, hr20.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr23.z, hr20.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr23.z, hr21.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr23.z, hr21.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr23.z, hr21.z, (r)(last)hr6.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr21.w, (r)(last)hr4.z
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr21.w, (r)(last)hr5.x
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
(rpt1)mad.f16 hr27.z, (r)(last)hr27.z, hr27.y, (r)(last)hr22.x
(rpt1)mad.f16 hr28.x, (r)(last)hr28.x, hr27.y, (r)(last)hr22.z
(rpt1)mad.f16 hr28.z, (r)(last)hr28.z, hr27.y, (r)(last)hr23.x
(rpt1)mad.f16 hr29.x, (r)(last)hr29.x, hr27.y, (r)(last)hr23.z
fence.r.w
(sy)(ss)mad.f16 hr18.z, hr0.z, hr29.z, (last)hr18.z
mad.f16 hr16.z, hr0.z, hr29.w, (last)hr16.z
mad.f16 hr14.z, hr0.z, hr30.x, (last)hr14.z
mad.f16 hr12.z, hr0.z, hr30.y, (last)hr12.z
mad.f16 hr10.z, hr0.z, hr30.z, (last)hr10.z
mad.f16 hr8.z, hr0.z, hr30.w, (last)hr8.z
mad.f16 hr6.z, hr0.z, hr31.x, (last)hr6.z
mad.f16 hr18.w, hr0.w, hr29.z, (last)hr18.w
mad.f16 hr16.w, hr0.w, hr29.w, (last)hr16.w
mad.f16 hr14.w, hr0.w, hr30.x, (last)hr14.w
mad.f16 hr12.w, hr0.w, hr30.y, (last)hr12.w
mad.f16 hr10.w, hr0.w, hr30.z, (last)hr10.w
mad.f16 hr8.w, hr0.w, hr30.w, (last)hr8.w
mad.f16 hr6.w, hr0.w, hr31.x, (last)hr6.w
mad.f16 hr19.x, hr1.x, hr29.z, (last)hr19.x
mad.f16 hr17.x, hr1.x, hr29.w, (last)hr17.x
mad.f16 hr15.x, hr1.x, hr30.x, (last)hr15.x
mad.f16 hr13.x, hr1.x, hr30.y, (last)hr13.x
mad.f16 hr11.x, hr1.x, hr30.z, (last)hr11.x
mad.f16 hr9.x, hr1.x, hr30.w, (last)hr9.x
mad.f16 hr7.x, hr1.x, hr31.x, (last)hr7.x
mad.f16 hr19.y, hr1.y, hr29.z, (last)hr19.y
mad.f16 hr17.y, hr1.y, hr29.w, (last)hr17.y
mad.f16 hr15.y, hr1.y, hr30.x, (last)hr15.y
mad.f16 hr13.y, hr1.y, hr30.y, (last)hr13.y
mad.f16 hr11.y, hr1.y, hr30.z, (last)hr11.y
mad.f16 hr9.y, hr1.y, hr30.w, (last)hr9.y
mad.f16 hr7.y, hr1.y, hr31.x, (last)hr7.y
mad.f16 hr17.z, hr3.z, hr29.z, (last)hr17.z
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
(rpt1)mad.f16 hr4.z, (r)(last)hr0.z, hr31.y, (r)(last)hr27.z
(rpt1)mad.f16 hr5.x, (r)(last)hr1.x, hr31.y, (r)(last)hr28.x
bar.g
(sy)(ss)(rpt1)mad.f16 hr3.z, (r)(last)hr3.z, hr31.y, (r)(last)hr28.z
(rpt1)mad.f16 hr4.x, (r)(last)hr4.x, hr31.y, (r)(last)hr29.x
br p0.x, #l596
mov.u32u32 r53.y, r54.x
jump #l99
l596:
(jp)(eolm)nop
(nop3) add.u r12.z, r52.w, (last)r12.z
(nop3) shl.b r12.z, (last)r12.z, 9
(nop3) sad.s32 r12.z, r53.w, r12.z, (last)r1.y
(nop3) shl.b r12.z, (last)r12.z, 2
(rpt2)add.u r9.w, r12.z, (r)c2.x
stib.b.untyped.1d.u16.4.imm.base0 hr18.z, r12.z, 4
add.u r10.z, r12.z, c2.w
(rpt3)add.u r10.w, r12.z, (r)c3.x
(rpt1)add.u r11.w, r12.z, (r)c4.x
(ss)(rpt1)add.u r9.y, r12.z, (r)c1.z
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r12.z+64, 4
(ss)(rpt1)add.u r8.w, (last)r12.z, (r)c1.x
(rpt4)nop
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r8.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r9.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r9.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r9.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r9.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r10.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r10.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r10.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r10.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r11.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r11.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r11.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r11.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r12.x, 4
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
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 718 instr, 25 nops, 693 non-nops, 66 mov, 0 cov, 1280 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 16 full, 8 constlen
; CL prog 23/1: 28 cat0, 66 cat1, 50 cat2, 516 cat3, 0 cat4, 3 cat5, 51 cat6, 4 cat7
; CL prog 23/1: 30 sstall, 11 (ss), 39 systall, 5 (sy), 1 loops
; CL prog 23/1: 16 max_waves, 0 double_threadsize
; 27 preamble-instr, 1 early-preamble
