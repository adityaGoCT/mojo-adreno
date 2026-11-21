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
ldl.u16 r29.w, l[r10.y+1024], 4
ldl.u16 r30.w, l[r10.y+1152], 4
ldl.u16 r0.z, l[r12.x+128], 4
(ss)mad.f16 hr17.z, hr30.w, hr27.z, (last)hr17.z
mad.f16 hr15.z, hr30.w, hr27.w, (last)hr15.z
mad.f16 hr13.z, hr30.w, hr28.x, (last)hr13.z
mad.f16 hr11.z, hr30.w, hr28.y, (last)hr11.z
mad.f16 hr9.z, hr30.w, hr28.z, (last)hr9.z
mad.f16 hr7.z, hr30.w, hr28.w, (last)hr7.z
mad.f16 hr5.z, hr30.w, hr29.x, (last)hr5.z
mad.f16 hr17.w, hr31.x, hr27.z, (last)hr17.w
mad.f16 hr15.w, hr31.x, hr27.w, (last)hr15.w
mad.f16 hr13.w, hr31.x, hr28.x, (last)hr13.w
mad.f16 hr11.w, hr31.x, hr28.y, (last)hr11.w
mad.f16 hr9.w, hr31.x, hr28.z, (last)hr9.w
mad.f16 hr7.w, hr31.x, hr28.w, (last)hr7.w
mad.f16 hr5.w, hr31.x, hr29.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr31.y, hr27.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr31.y, hr27.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr31.y, hr28.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr31.y, hr28.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr31.y, hr28.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr31.y, hr28.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr31.y, hr29.x, (r)(last)hr6.x
(rpt1)mad.f16 hr30.w, (r)(last)hr30.w, hr29.y, (r)(last)hr3.z
(rpt1)mad.f16 hr31.y, (r)(last)hr31.y, hr29.y, (r)(last)hr4.x
ldl.u16 r3.z, l[r12.x+192], 4
ldl.u16 r21.x, l[r10.y+1280], 4
ldl.u16 r22.x, l[r10.y+1408], 4
ldl.u16 r23.x, l[r12.x+256], 4
ldl.u16 r25.z, l[r12.x+320], 4
mad.f16 hr18.z, hr29.w, hr27.z, (last)hr18.z
mad.f16 hr16.z, hr29.w, hr27.w, (last)hr16.z
mad.f16 hr14.z, hr29.w, hr28.x, (last)hr14.z
mad.f16 hr12.z, hr29.w, hr28.y, (last)hr12.z
mad.f16 hr10.z, hr29.w, hr28.z, (last)hr10.z
mad.f16 hr8.z, hr29.w, hr28.w, (last)hr8.z
mad.f16 hr6.z, hr29.w, hr29.x, (last)hr6.z
mad.f16 hr18.w, hr30.x, hr27.z, (last)hr18.w
mad.f16 hr16.w, hr30.x, hr27.w, (last)hr16.w
mad.f16 hr14.w, hr30.x, hr28.x, (last)hr14.w
mad.f16 hr12.w, hr30.x, hr28.y, (last)hr12.w
mad.f16 hr10.w, hr30.x, hr28.z, (last)hr10.w
mad.f16 hr8.w, hr30.x, hr28.w, (last)hr8.w
mad.f16 hr6.w, hr30.x, hr29.x, (last)hr6.w
mad.f16 hr19.x, hr30.y, hr27.z, (last)hr19.x
mad.f16 hr17.x, hr30.y, hr27.w, (last)hr17.x
mad.f16 hr15.x, hr30.y, hr28.x, (last)hr15.x
mad.f16 hr13.x, hr30.y, hr28.y, (last)hr13.x
mad.f16 hr11.x, hr30.y, hr28.z, (last)hr11.x
mad.f16 hr9.x, hr30.y, hr28.w, (last)hr9.x
mad.f16 hr7.x, hr30.y, hr29.x, (last)hr7.x
mad.f16 hr19.y, hr30.z, hr27.z, (last)hr19.y
ldl.u16 r26.w, l[r10.y+1536], 4
mad.f16 hr17.y, hr30.z, hr27.w, (last)hr17.y
mad.f16 hr15.y, hr30.z, hr28.x, (last)hr15.y
mad.f16 hr13.y, hr30.z, hr28.y, (last)hr13.y
mad.f16 hr11.y, hr30.z, hr28.z, (last)hr11.y
ldl.u16 r27.w, l[r10.y+1664], 4
mad.f16 hr9.y, hr30.z, hr28.w, (last)hr9.y
mad.f16 hr7.y, hr30.z, hr29.x, (last)hr7.y
(rpt1)mad.f16 hr29.w, (r)(last)hr29.w, hr29.y, (r)(last)hr4.z
(rpt1)mad.f16 hr30.y, (r)(last)hr30.y, hr29.y, (r)(last)hr5.x
ldl.u16 r28.w, l[r12.x+384], 4
(ss)mad.f16 hr17.z, hr22.x, hr0.z, (last)hr17.z
mad.f16 hr15.z, hr22.x, hr0.w, (last)hr15.z
mad.f16 hr13.z, hr22.x, hr1.x, (last)hr13.z
mad.f16 hr11.z, hr22.x, hr1.y, (last)hr11.z
mad.f16 hr9.z, hr22.x, hr3.z, (last)hr9.z
mad.f16 hr7.z, hr22.x, hr3.w, (last)hr7.z
mad.f16 hr5.z, hr22.x, hr4.x, (last)hr5.z
mad.f16 hr17.w, hr22.y, hr0.z, (last)hr17.w
mad.f16 hr15.w, hr22.y, hr0.w, (last)hr15.w
mad.f16 hr13.w, hr22.y, hr1.x, (last)hr13.w
mad.f16 hr11.w, hr22.y, hr1.y, (last)hr11.w
mad.f16 hr9.w, hr22.y, hr3.z, (last)hr9.w
mad.f16 hr7.w, hr22.y, hr3.w, (last)hr7.w
mad.f16 hr5.w, hr22.y, hr4.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr22.z, hr0.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr22.z, hr0.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr22.z, hr1.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr22.z, hr1.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr22.z, hr3.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr22.z, hr3.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr22.z, hr4.x, (r)(last)hr6.x
mad.f16 hr18.z, hr21.x, hr0.z, (last)hr18.z
mad.f16 hr16.z, hr21.x, hr0.w, (last)hr16.z
mad.f16 hr14.z, hr21.x, hr1.x, (last)hr14.z
mad.f16 hr12.z, hr21.x, hr1.y, (last)hr12.z
mad.f16 hr10.z, hr21.x, hr3.z, (last)hr10.z
mad.f16 hr8.z, hr21.x, hr3.w, (last)hr8.z
mad.f16 hr6.z, hr21.x, hr4.x, (last)hr6.z
mad.f16 hr18.w, hr21.y, hr0.z, (last)hr18.w
mad.f16 hr16.w, hr21.y, hr0.w, (last)hr16.w
mad.f16 hr14.w, hr21.y, hr1.x, (last)hr14.w
mad.f16 hr12.w, hr21.y, hr1.y, (last)hr12.w
mad.f16 hr10.w, hr21.y, hr3.z, (last)hr10.w
mad.f16 hr8.w, hr21.y, hr3.w, (last)hr8.w
mad.f16 hr6.w, hr21.y, hr4.x, (last)hr6.w
mad.f16 hr19.x, hr21.z, hr0.z, (last)hr19.x
mad.f16 hr17.x, hr21.z, hr0.w, (last)hr17.x
mad.f16 hr15.x, hr21.z, hr1.x, (last)hr15.x
mad.f16 hr13.x, hr21.z, hr1.y, (last)hr13.x
mad.f16 hr11.x, hr21.z, hr3.z, (last)hr11.x
mad.f16 hr9.x, hr21.z, hr3.w, (last)hr9.x
mad.f16 hr7.x, hr21.z, hr4.x, (last)hr7.x
mad.f16 hr19.y, hr21.w, hr0.z, (last)hr19.y
mad.f16 hr17.y, hr21.w, hr0.w, (last)hr17.y
mad.f16 hr15.y, hr21.w, hr1.x, (last)hr15.y
mad.f16 hr13.y, hr21.w, hr1.y, (last)hr13.y
mad.f16 hr11.y, hr21.w, hr3.z, (last)hr11.y
mad.f16 hr9.y, hr21.w, hr3.w, (last)hr9.y
mad.f16 hr7.y, hr21.w, hr4.x, (last)hr7.y
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr4.y, (r)(last)hr30.w
(rpt1)mad.f16 hr22.z, (r)(last)hr22.z, hr4.y, (r)(last)hr31.y
(rpt1)mad.f16 hr21.x, (r)(last)hr21.x, hr4.y, (r)(last)hr29.w
(rpt1)mad.f16 hr21.z, (r)(last)hr21.z, hr4.y, (r)(last)hr30.y
ldl.u16 r29.w, l[r12.x+448], 4
ldl.u16 r31.x, l[r10.y+1792], 4
ldl.u16 r4.x, l[r10.y+1920], 4
ldl.u16 r19.z, l[r12.x+512], 4
(rpt1)mad.f16 hr17.z, (r)hr27.w, hr23.x, (r)(last)hr17.z
mad.f16 hr15.w, hr28.x, hr23.y, (last)hr15.w
mad.f16 hr13.w, hr28.x, hr23.z, (last)hr13.w
mad.f16 hr11.w, hr28.x, hr23.w, (last)hr11.w
mad.f16 hr9.w, hr28.x, hr25.z, (last)hr9.w
mad.f16 hr7.w, hr28.x, hr25.w, (last)hr7.w
mad.f16 hr5.w, hr28.x, hr26.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr28.y, hr23.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr28.y, hr23.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr28.y, hr23.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr28.y, hr23.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr28.y, hr25.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr28.y, hr25.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr28.y, hr26.x, (r)(last)hr6.x
mad.f16 hr18.z, hr26.w, hr23.x, (last)hr18.z
mad.f16 hr16.z, hr26.w, hr23.y, (last)hr16.z
mad.f16 hr14.z, hr26.w, hr23.z, (last)hr14.z
mad.f16 hr12.z, hr26.w, hr23.w, (last)hr12.z
mad.f16 hr10.z, hr26.w, hr25.z, (last)hr10.z
mad.f16 hr8.z, hr26.w, hr25.w, (last)hr8.z
mad.f16 hr6.z, hr26.w, hr26.x, (last)hr6.z
mad.f16 hr18.w, hr27.x, hr23.x, (last)hr18.w
mad.f16 hr16.w, hr27.x, hr23.y, (last)hr16.w
mad.f16 hr14.w, hr27.x, hr23.z, (last)hr14.w
mad.f16 hr12.w, hr27.x, hr23.w, (last)hr12.w
mad.f16 hr10.w, hr27.x, hr25.z, (last)hr10.w
mad.f16 hr8.w, hr27.x, hr25.w, (last)hr8.w
mad.f16 hr6.w, hr27.x, hr26.x, (last)hr6.w
mad.f16 hr19.x, hr27.y, hr23.x, (last)hr19.x
mad.f16 hr17.x, hr27.y, hr23.y, (last)hr17.x
mad.f16 hr15.x, hr27.y, hr23.z, (last)hr15.x
mad.f16 hr13.x, hr27.y, hr23.w, (last)hr13.x
mad.f16 hr11.x, hr27.y, hr25.z, (last)hr11.x
mad.f16 hr9.x, hr27.y, hr25.w, (last)hr9.x
mad.f16 hr7.x, hr27.y, hr26.x, (last)hr7.x
mad.f16 hr19.y, hr27.z, hr23.x, (last)hr19.y
mad.f16 hr17.y, hr27.z, hr23.y, (last)hr17.y
mad.f16 hr15.y, hr27.z, hr23.z, (last)hr15.y
mad.f16 hr13.y, hr27.z, hr23.w, (last)hr13.y
mad.f16 hr11.y, hr27.z, hr25.z, (last)hr11.y
mad.f16 hr9.y, hr27.z, hr25.w, (last)hr9.y
mad.f16 hr7.y, hr27.z, hr26.x, (last)hr7.y
mad.f16 hr28.x, (last)hr28.x, hr26.y, (last)hr22.y
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr26.y, (r)(last)hr22.z
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr26.y, (r)(last)hr21.x
(rpt1)mad.f16 hr27.y, (r)(last)hr27.y, hr26.y, (r)(last)hr21.z
ldl.u16 r21.x, l[r12.x+576], 4
ldl.u16 r22.y, l[r10.y+2048], 4
mad.f16 hr15.z, hr27.w, hr23.y, (last)hr15.z
mad.f16 hr13.z, hr27.w, hr23.z, (last)hr13.z
mad.f16 hr11.z, hr27.w, hr23.w, (last)hr11.z
mad.f16 hr9.z, hr27.w, hr25.z, (last)hr9.z
mad.f16 hr7.z, hr27.w, hr25.w, (last)hr7.z
mad.f16 hr5.z, hr27.w, hr26.x, (last)hr5.z
mad.f16 hr27.w, (last)hr27.w, hr26.y, (last)hr22.x
ldl.u16 r25.w, l[r10.y+2176], 4
(ss)(rpt1)mad.f16 hr17.z, (r)hr4.x, hr28.w, (r)(last)hr17.z
mad.f16 hr15.w, hr4.y, hr29.x, (last)hr15.w
mad.f16 hr13.w, hr4.y, hr29.y, (last)hr13.w
mad.f16 hr11.w, hr4.y, hr29.z, (last)hr11.w
mad.f16 hr9.w, hr4.y, hr29.w, (last)hr9.w
mad.f16 hr7.w, hr4.y, hr30.x, (last)hr7.w
mad.f16 hr5.w, hr4.y, hr30.y, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr4.z, hr28.w, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr4.z, hr29.x, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr4.z, hr29.y, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr4.z, hr29.z, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr4.z, hr29.w, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr4.z, hr30.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr4.z, hr30.y, (r)(last)hr6.x
mad.f16 hr18.z, hr31.x, hr28.w, (last)hr18.z
mad.f16 hr16.z, hr31.x, hr29.x, (last)hr16.z
mad.f16 hr14.z, hr31.x, hr29.y, (last)hr14.z
mad.f16 hr12.z, hr31.x, hr29.z, (last)hr12.z
mad.f16 hr10.z, hr31.x, hr29.w, (last)hr10.z
mad.f16 hr8.z, hr31.x, hr30.x, (last)hr8.z
mad.f16 hr6.z, hr31.x, hr30.y, (last)hr6.z
mad.f16 hr18.w, hr31.y, hr28.w, (last)hr18.w
mad.f16 hr16.w, hr31.y, hr29.x, (last)hr16.w
mad.f16 hr14.w, hr31.y, hr29.y, (last)hr14.w
mad.f16 hr12.w, hr31.y, hr29.z, (last)hr12.w
mad.f16 hr10.w, hr31.y, hr29.w, (last)hr10.w
mad.f16 hr8.w, hr31.y, hr30.x, (last)hr8.w
mad.f16 hr6.w, hr31.y, hr30.y, (last)hr6.w
mad.f16 hr19.x, hr31.z, hr28.w, (last)hr19.x
mad.f16 hr17.x, hr31.z, hr29.x, (last)hr17.x
mad.f16 hr15.x, hr31.z, hr29.y, (last)hr15.x
mad.f16 hr13.x, hr31.z, hr29.z, (last)hr13.x
mad.f16 hr11.x, hr31.z, hr29.w, (last)hr11.x
mad.f16 hr9.x, hr31.z, hr30.x, (last)hr9.x
mad.f16 hr7.x, hr31.z, hr30.y, (last)hr7.x
mad.f16 hr19.y, hr31.w, hr28.w, (last)hr19.y
mad.f16 hr17.y, hr31.w, hr29.x, (last)hr17.y
mad.f16 hr15.y, hr31.w, hr29.y, (last)hr15.y
mad.f16 hr13.y, hr31.w, hr29.z, (last)hr13.y
mad.f16 hr11.y, hr31.w, hr29.w, (last)hr11.y
mad.f16 hr9.y, hr31.w, hr30.x, (last)hr9.y
mad.f16 hr7.y, hr31.w, hr30.y, (last)hr7.y
mad.f16 hr15.z, hr4.x, hr29.x, (last)hr15.z
mad.f16 hr13.z, hr4.x, hr29.y, (last)hr13.z
mad.f16 hr11.z, hr4.x, hr29.z, (last)hr11.z
mad.f16 hr9.z, hr4.x, hr29.w, (last)hr9.z
mad.f16 hr7.z, hr4.x, hr30.x, (last)hr7.z
mad.f16 hr5.z, hr4.x, hr30.y, (last)hr5.z
mad.f16 hr4.y, (last)hr4.y, hr30.z, (last)hr28.x
(rpt1)mad.f16 hr4.z, (r)(last)hr4.z, hr30.z, (r)(last)hr28.y
(rpt1)mad.f16 hr31.x, (r)(last)hr31.x, hr30.z, (r)(last)hr26.w
(rpt1)mad.f16 hr31.z, (r)(last)hr31.z, hr30.z, (r)(last)hr27.y
ldl.u16 r26.w, l[r12.x+640], 4
mad.f16 hr4.x, (last)hr4.x, hr30.z, (last)hr27.w
ldl.u16 r27.w, l[r12.x+704], 4
ldl.u16 r28.w, l[r10.y+2304], 4
ldl.u16 r30.x, l[r10.y+2432], 4
mad.f16 hr18.z, hr22.y, hr19.z, (last)hr18.z
mad.f16 hr16.z, hr22.y, hr19.w, (last)hr16.z
mad.f16 hr14.z, hr22.y, hr20.x, (last)hr14.z
mad.f16 hr12.z, hr22.y, hr20.y, (last)hr12.z
mad.f16 hr10.z, hr22.y, hr21.x, (last)hr10.z
mad.f16 hr8.z, hr22.y, hr21.y, (last)hr8.z
mad.f16 hr6.z, hr22.y, hr21.z, (last)hr6.z
mad.f16 hr18.w, hr22.z, hr19.z, (last)hr18.w
mad.f16 hr16.w, hr22.z, hr19.w, (last)hr16.w
mad.f16 hr14.w, hr22.z, hr20.x, (last)hr14.w
mad.f16 hr12.w, hr22.z, hr20.y, (last)hr12.w
mad.f16 hr10.w, hr22.z, hr21.x, (last)hr10.w
mad.f16 hr8.w, hr22.z, hr21.y, (last)hr8.w
mad.f16 hr6.w, hr22.z, hr21.z, (last)hr6.w
mad.f16 hr19.x, hr22.w, hr19.z, (last)hr19.x
mad.f16 hr17.x, hr22.w, hr19.w, (last)hr17.x
mad.f16 hr15.x, hr22.w, hr20.x, (last)hr15.x
mad.f16 hr13.x, hr22.w, hr20.y, (last)hr13.x
mad.f16 hr11.x, hr22.w, hr21.x, (last)hr11.x
mad.f16 hr9.x, hr22.w, hr21.y, (last)hr9.x
mad.f16 hr7.x, hr22.w, hr21.z, (last)hr7.x
mad.f16 hr19.y, hr23.x, hr19.z, (last)hr19.y
mad.f16 hr17.y, hr23.x, hr19.w, (last)hr17.y
mad.f16 hr15.y, hr23.x, hr20.x, (last)hr15.y
mad.f16 hr13.y, hr23.x, hr20.y, (last)hr13.y
mad.f16 hr11.y, hr23.x, hr21.x, (last)hr11.y
mad.f16 hr9.y, hr23.x, hr21.y, (last)hr9.y
mad.f16 hr7.y, hr23.x, hr21.z, (last)hr7.y
(rpt1)mad.f16 hr22.y, (r)(last)hr22.y, hr21.w, (r)(last)hr31.x
(rpt1)mad.f16 hr22.w, (r)(last)hr22.w, hr21.w, (r)(last)hr31.z
ldl.u16 r31.x, l[r12.x+768], 4
ldl.u16 r0.z, l[r12.x+832], 4
(rpt1)mad.f16 hr17.z, (r)hr25.w, hr19.z, (r)(last)hr17.z
mad.f16 hr15.w, hr26.x, hr19.w, (last)hr15.w
mad.f16 hr13.w, hr26.x, hr20.x, (last)hr13.w
mad.f16 hr11.w, hr26.x, hr20.y, (last)hr11.w
mad.f16 hr9.w, hr26.x, hr21.x, (last)hr9.w
mad.f16 hr7.w, hr26.x, hr21.y, (last)hr7.w
mad.f16 hr5.w, hr26.x, hr21.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr26.y, hr19.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr26.y, hr19.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr26.y, hr20.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr26.y, hr20.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr26.y, hr21.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr26.y, hr21.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr26.y, hr21.z, (r)(last)hr6.x
mad.f16 hr15.z, hr25.w, hr19.w, (last)hr15.z
mad.f16 hr13.z, hr25.w, hr20.x, (last)hr13.z
mad.f16 hr11.z, hr25.w, hr20.y, (last)hr11.z
mad.f16 hr9.z, hr25.w, hr21.x, (last)hr9.z
mad.f16 hr7.z, hr25.w, hr21.y, (last)hr7.z
mad.f16 hr5.z, hr25.w, hr21.z, (last)hr5.z
(ss)mad.f16 hr18.z, hr28.w, hr26.w, (last)hr18.z
mad.f16 hr16.z, hr28.w, hr27.x, (last)hr16.z
mad.f16 hr14.z, hr28.w, hr27.y, (last)hr14.z
mad.f16 hr12.z, hr28.w, hr27.z, (last)hr12.z
mad.f16 hr10.z, hr28.w, hr27.w, (last)hr10.z
mad.f16 hr8.z, hr28.w, hr28.x, (last)hr8.z
mad.f16 hr6.z, hr28.w, hr28.y, (last)hr6.z
mad.f16 hr18.w, hr29.x, hr26.w, (last)hr18.w
mad.f16 hr16.w, hr29.x, hr27.x, (last)hr16.w
mad.f16 hr14.w, hr29.x, hr27.y, (last)hr14.w
mad.f16 hr12.w, hr29.x, hr27.z, (last)hr12.w
mad.f16 hr10.w, hr29.x, hr27.w, (last)hr10.w
mad.f16 hr8.w, hr29.x, hr28.x, (last)hr8.w
mad.f16 hr6.w, hr29.x, hr28.y, (last)hr6.w
mad.f16 hr19.x, hr29.y, hr26.w, (last)hr19.x
mad.f16 hr17.x, hr29.y, hr27.x, (last)hr17.x
mad.f16 hr15.x, hr29.y, hr27.y, (last)hr15.x
mad.f16 hr13.x, hr29.y, hr27.z, (last)hr13.x
mad.f16 hr11.x, hr29.y, hr27.w, (last)hr11.x
mad.f16 hr9.x, hr29.y, hr28.x, (last)hr9.x
mad.f16 hr7.x, hr29.y, hr28.y, (last)hr7.x
mad.f16 hr19.y, hr29.z, hr26.w, (last)hr19.y
mad.f16 hr17.y, hr29.z, hr27.x, (last)hr17.y
mad.f16 hr15.y, hr29.z, hr27.y, (last)hr15.y
mad.f16 hr13.y, hr29.z, hr27.z, (last)hr13.y
mad.f16 hr11.y, hr29.z, hr27.w, (last)hr11.y
mad.f16 hr9.y, hr29.z, hr28.x, (last)hr9.y
mad.f16 hr7.y, hr29.z, hr28.y, (last)hr7.y
mad.f16 hr26.x, (last)hr26.x, hr21.w, (last)hr4.y
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr21.w, (r)(last)hr4.z
mad.f16 hr25.w, (last)hr25.w, hr21.w, (last)hr4.x
ldl.u16 r4.x, l[r10.y+2560], 4
ldl.u16 r21.y, l[r10.y+2688], 4
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr28.z, (r)(last)hr22.y
(rpt1)mad.f16 hr29.y, (r)(last)hr29.y, hr28.z, (r)(last)hr22.w
ldl.u16 r22.y, l[r12.x+896], 4
(rpt1)mad.f16 hr17.z, (r)hr30.x, hr26.w, (r)(last)hr17.z
mad.f16 hr15.w, hr30.y, hr27.x, (last)hr15.w
mad.f16 hr13.w, hr30.y, hr27.y, (last)hr13.w
mad.f16 hr11.w, hr30.y, hr27.z, (last)hr11.w
mad.f16 hr9.w, hr30.y, hr27.w, (last)hr9.w
mad.f16 hr7.w, hr30.y, hr28.x, (last)hr7.w
mad.f16 hr5.w, hr30.y, hr28.y, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr30.z, hr26.w, (r)(last)hr18.x
(ss)nop
ldl.u16 r23.y, l[r12.x+960], 4
(rpt1)mad.f16 hr16.x, (r)hr30.z, hr27.x, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr30.z, hr27.y, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr30.z, hr27.z, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr30.z, hr27.w, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr30.z, hr28.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr30.z, hr28.y, (r)(last)hr6.x
mad.f16 hr15.z, hr30.x, hr27.x, (last)hr15.z
mad.f16 hr13.z, hr30.x, hr27.y, (last)hr13.z
mad.f16 hr11.z, hr30.x, hr27.z, (last)hr11.z
mad.f16 hr9.z, hr30.x, hr27.w, (last)hr9.z
mad.f16 hr7.z, hr30.x, hr28.x, (last)hr7.z
mad.f16 hr5.z, hr30.x, hr28.y, (last)hr5.z
mad.f16 hr30.y, (last)hr30.y, hr28.z, (last)hr26.x
(rpt1)mad.f16 hr30.z, (r)(last)hr30.z, hr28.z, (r)(last)hr26.y
mad.f16 hr30.x, (last)hr30.x, hr28.z, (last)hr25.w
ldl.u16 r25.w, l[r10.y+2816], 4
ldl.u16 r27.w, l[r10.y+2944], 4
mad.f16 hr18.z, hr4.x, hr31.x, (last)hr18.z
mad.f16 hr16.z, hr4.x, hr31.y, (last)hr16.z
mad.f16 hr14.z, hr4.x, hr31.z, (last)hr14.z
mad.f16 hr12.z, hr4.x, hr31.w, (last)hr12.z
mad.f16 hr10.z, hr4.x, hr0.z, (last)hr10.z
mad.f16 hr8.z, hr4.x, hr0.w, (last)hr8.z
mad.f16 hr6.z, hr4.x, hr1.x, (last)hr6.z
mad.f16 hr18.w, hr4.y, hr31.x, (last)hr18.w
mad.f16 hr16.w, hr4.y, hr31.y, (last)hr16.w
mad.f16 hr14.w, hr4.y, hr31.z, (last)hr14.w
mad.f16 hr12.w, hr4.y, hr31.w, (last)hr12.w
mad.f16 hr10.w, hr4.y, hr0.z, (last)hr10.w
mad.f16 hr8.w, hr4.y, hr0.w, (last)hr8.w
mad.f16 hr6.w, hr4.y, hr1.x, (last)hr6.w
mad.f16 hr19.x, hr4.z, hr31.x, (last)hr19.x
mad.f16 hr17.x, hr4.z, hr31.y, (last)hr17.x
mad.f16 hr15.x, hr4.z, hr31.z, (last)hr15.x
mad.f16 hr13.x, hr4.z, hr31.w, (last)hr13.x
mad.f16 hr11.x, hr4.z, hr0.z, (last)hr11.x
mad.f16 hr9.x, hr4.z, hr0.w, (last)hr9.x
mad.f16 hr7.x, hr4.z, hr1.x, (last)hr7.x
mad.f16 hr19.y, hr4.w, hr31.x, (last)hr19.y
mad.f16 hr17.y, hr4.w, hr31.y, (last)hr17.y
mad.f16 hr15.y, hr4.w, hr31.z, (last)hr15.y
mad.f16 hr13.y, hr4.w, hr31.w, (last)hr13.y
mad.f16 hr11.y, hr4.w, hr0.z, (last)hr11.y
mad.f16 hr9.y, hr4.w, hr0.w, (last)hr9.y
mad.f16 hr7.y, hr4.w, hr1.x, (last)hr7.y
(rpt1)mad.f16 hr17.z, (r)hr21.y, hr31.x, (r)(last)hr17.z
mad.f16 hr15.w, hr21.z, hr31.y, (last)hr15.w
mad.f16 hr13.w, hr21.z, hr31.z, (last)hr13.w
mad.f16 hr11.w, hr21.z, hr31.w, (last)hr11.w
mad.f16 hr9.w, hr21.z, hr0.z, (last)hr9.w
mad.f16 hr7.w, hr21.z, hr0.w, (last)hr7.w
mad.f16 hr5.w, hr21.z, hr1.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr21.w, hr31.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr21.w, hr31.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr21.w, hr31.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr21.w, hr31.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr21.w, hr0.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr21.w, hr0.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr21.w, hr1.x, (r)(last)hr6.x
mad.f16 hr15.z, hr21.y, hr31.y, (last)hr15.z
mad.f16 hr13.z, hr21.y, hr31.z, (last)hr13.z
mad.f16 hr11.z, hr21.y, hr31.w, (last)hr11.z
mad.f16 hr9.z, hr21.y, hr0.z, (last)hr9.z
mad.f16 hr7.z, hr21.y, hr0.w, (last)hr7.z
mad.f16 hr5.z, hr21.y, hr1.x, (last)hr5.z
(rpt1)mad.f16 hr4.x, (r)(last)hr4.x, hr1.y, (r)(last)hr28.w
(rpt1)mad.f16 hr4.z, (r)(last)hr4.z, hr1.y, (r)(last)hr29.y
mad.f16 hr21.z, (last)hr21.z, hr1.y, (last)hr30.y
(rpt1)mad.f16 hr21.w, (r)(last)hr21.w, hr1.y, (r)(last)hr30.z
mad.f16 hr21.y, (last)hr21.y, hr1.y, (last)hr30.x
fence.r.w
(sy)(ss)mad.f16 hr18.z, hr25.w, hr22.y, (last)hr18.z
mad.f16 hr16.z, hr25.w, hr22.z, (last)hr16.z
mad.f16 hr14.z, hr25.w, hr22.w, (last)hr14.z
mad.f16 hr12.z, hr25.w, hr23.x, (last)hr12.z
mad.f16 hr10.z, hr25.w, hr23.y, (last)hr10.z
mad.f16 hr8.z, hr25.w, hr23.z, (last)hr8.z
mad.f16 hr6.z, hr25.w, hr23.w, (last)hr6.z
mad.f16 hr18.w, hr26.x, hr22.y, (last)hr18.w
mad.f16 hr16.w, hr26.x, hr22.z, (last)hr16.w
mad.f16 hr14.w, hr26.x, hr22.w, (last)hr14.w
mad.f16 hr12.w, hr26.x, hr23.x, (last)hr12.w
mad.f16 hr10.w, hr26.x, hr23.y, (last)hr10.w
mad.f16 hr8.w, hr26.x, hr23.z, (last)hr8.w
mad.f16 hr6.w, hr26.x, hr23.w, (last)hr6.w
mad.f16 hr19.x, hr26.y, hr22.y, (last)hr19.x
mad.f16 hr17.x, hr26.y, hr22.z, (last)hr17.x
mad.f16 hr15.x, hr26.y, hr22.w, (last)hr15.x
mad.f16 hr13.x, hr26.y, hr23.x, (last)hr13.x
mad.f16 hr11.x, hr26.y, hr23.y, (last)hr11.x
mad.f16 hr9.x, hr26.y, hr23.z, (last)hr9.x
mad.f16 hr7.x, hr26.y, hr23.w, (last)hr7.x
mad.f16 hr19.y, hr26.z, hr22.y, (last)hr19.y
mad.f16 hr17.y, hr26.z, hr22.z, (last)hr17.y
mad.f16 hr15.y, hr26.z, hr22.w, (last)hr15.y
mad.f16 hr13.y, hr26.z, hr23.x, (last)hr13.y
mad.f16 hr11.y, hr26.z, hr23.y, (last)hr11.y
mad.f16 hr9.y, hr26.z, hr23.z, (last)hr9.y
mad.f16 hr7.y, hr26.z, hr23.w, (last)hr7.y
(rpt1)mad.f16 hr17.z, (r)hr27.w, hr22.y, (r)(last)hr17.z
mad.f16 hr15.w, hr28.x, hr22.z, (last)hr15.w
mad.f16 hr13.w, hr28.x, hr22.w, (last)hr13.w
mad.f16 hr11.w, hr28.x, hr23.x, (last)hr11.w
mad.f16 hr9.w, hr28.x, hr23.y, (last)hr9.w
mad.f16 hr7.w, hr28.x, hr23.z, (last)hr7.w
mad.f16 hr5.w, hr28.x, hr23.w, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr28.y, hr22.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr28.y, hr22.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr28.y, hr22.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr28.y, hr23.x, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr28.y, hr23.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr28.y, hr23.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr28.y, hr23.w, (r)(last)hr6.x
mad.f16 hr15.z, hr27.w, hr22.z, (last)hr15.z
mad.f16 hr13.z, hr27.w, hr22.w, (last)hr13.z
mad.f16 hr11.z, hr27.w, hr23.x, (last)hr11.z
mad.f16 hr9.z, hr27.w, hr23.y, (last)hr9.z
mad.f16 hr7.z, hr27.w, hr23.z, (last)hr7.z
mad.f16 hr5.z, hr27.w, hr23.w, (last)hr5.z
(rpt1)mad.f16 hr26.w, (r)(last)hr25.w, hr24.x, (r)(last)hr4.x
(rpt1)mad.f16 hr27.y, (r)(last)hr26.y, hr24.x, (r)(last)hr4.z
mad.f16 hr3.w, (last)hr28.x, hr24.x, (last)hr21.z
mad.f16 hr3.z, (last)hr27.w, hr24.x, (last)hr21.y
bar.g
(sy)(ss)(rpt1)mad.f16 hr4.x, (r)(last)hr28.y, hr24.x, (r)(last)hr21.w
br p0.x, #l601
mov.u32u32 r53.y, r54.x
mov.u16u16 hr5.y, hr27.z
mov.u16u16 hr5.x, hr27.y
mov.u16u16 hr4.w, hr27.x
mov.u16u16 hr4.z, hr26.w
jump #l99
l601:
(jp)(eolm)nop
(nop3) add.u r12.z, r52.w, (last)r12.z
(nop3) shl.b r12.z, (last)r12.z, 9
(nop3) sad.s32 r12.z, r53.w, r12.z, (last)r1.y
(nop3) shl.b r12.z, (last)r12.z, 2
(rpt3)add.u r14.z, r12.z, (r)c1.x
(rpt3)add.u r0.x, r12.z, (r)c2.x
stib.b.untyped.1d.u16.4.imm.base0 hr18.z, r12.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r12.z+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r14.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r14.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r15.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r15.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r0.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r0.y, 4
(ss)(rpt1)add.u r5.w, r12.z, (r)c4.x
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r0.z, 4
(ss)(rpt1)add.u r5.y, r12.z, (r)c3.z
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r0.w, 4
(ss)(rpt1)add.u r4.w, (last)r12.z, (r)c3.x
(rpt4)nop
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r4.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r5.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r5.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r5.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr26.w, r5.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r6.x, 4
end
nop
nop
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 727 instr, 30 nops, 697 non-nops, 70 mov, 0 cov, 1280 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 16 full, 8 constlen
; CL prog 23/1: 33 cat0, 70 cat1, 50 cat2, 516 cat3, 0 cat4, 3 cat5, 51 cat6, 4 cat7
; CL prog 23/1: 30 sstall, 13 (ss), 39 systall, 5 (sy), 1 loops
; CL prog 23/1: 16 max_waves, 0 double_threadsize
; 27 preamble-instr, 1 early-preamble
