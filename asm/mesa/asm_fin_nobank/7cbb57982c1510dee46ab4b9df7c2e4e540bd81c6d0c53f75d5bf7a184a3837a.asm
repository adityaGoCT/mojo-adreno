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
@const(c1.x)	0x00000800, 0x00001000, 0x00001f00, 0x00001e00
@const(c2.x)	0x00001d00, 0x00001c00, 0x00001b00, 0x00001a00
@const(c3.x)	0x00001900, 0x00001800, 0x00001700, 0x00001600
@const(c4.x)	0x00001500, 0x00001400, 0x00001300, 0x00001200
@const(c5.x)	0x00001100, 0x00001080, 0x00000840, 0x00001040
@const(c6.x)	0x00001840, 0x00020000, 0x00020040, 0x00020800
@const(c7.x)	0x00020840, 0x00021000, 0x00021040, 0x00021800
@const(c8.x)	0x00021840, 0xd0d0d0d0, 0xd0d0d0d0, 0xd0d0d0d0
shps #l46
getone #l46
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 4096
mov.u32u32 r49.y, 0x1f00
mov.u32u32 r49.z, 0x1e00
mov.u32u32 r49.w, 0x1d00
mov.u32u32 r50.x, 0x1c00
mov.u32u32 r50.y, 0x1b00
mov.u32u32 r50.z, 0x1a00
mov.u32u32 r50.w, 0x1900
mov.u32u32 r51.x, 0x1800
mov.u32u32 r51.y, 0x1700
mov.u32u32 r51.z, 0x1600
mov.u32u32 r51.w, 0x1500
mov.u32u32 r52.x, 0x1400
mov.u32u32 r52.y, 0x1300
mov.u32u32 r52.z, 0x1200
mov.u32u32 r52.w, 0x1100
mov.u32u32 r53.x, 0x1080
mov.u32u32 r53.y, 2112
mov.u32u32 r53.z, 0x1040
mov.u32u32 r53.w, 0x1840
mov.u32u32 r54.x, 0x20000
mov.u32u32 r54.y, 0x20040
mov.u32u32 r54.z, 0x20800
mov.u32u32 r54.w, 0x20840
mov.u32u32 r55.x, 0x21000
mov.u32u32 r55.y, 0x21040
mov.u32u32 r55.z, 0x21800
mov.u32u32 r55.w, 0x21840
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 4
stc.u32 c[20], r52.w, 4
stc.u32 c[24], r53.w, 4
stc.u32 c[28], r54.w, 4
stc.u32 c[32], r55.w, 1
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l46:
(jp)(rpt1)add.u r48.z, (r)r48.x, (r)c0.x
mov.u32u32 r49.z, 0
shl.b r49.y, r48.z, 7
shl.b r49.x, r48.w, 7
shr.b r0.w, r0.x, 5
and.b r1.x, r0.x, 31
shr.b r1.z, r0.x, 4
and.b r1.y, r0.x, 15
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
l118:
(rpt1)shr.b r49.w, (r)r49.x, 2
add.u r10.z, r0.x, 256
shl.b r9.w, r0.w, 8
shl.b r10.x, r1.x, 3
shl.b r13.y, r1.z, 3
shr.b r10.z, (last)r10.z, 5
shl.b r10.y, r1.y, 3
(ss)add.u r11.x, r49.z, r0.w
add.u r10.w, r9.w, r10.x
add.u r11.y, r49.z, r10.z
add.u r49.z, r49.z, 16
cmps.u.ge up0.x, r49.z, c1.x
shl.b r10.z, (last)r10.z, 8
shl.b r11.x, (last)r11.x, 9
sad.s32 r9.w, c1.y, r9.w, r10.x
shl.b r11.y, (last)r11.y, 9
add.u r12.z, r10.z, r10.x
(rpt1)sad.s32 r11.z, (r)r49.w, r11.x, r1.x
(rpt1)sad.s32 r12.x, (r)r49.w, r11.y, r1.x
(rpt1)shl.b r11.z, (last)(r)r11.z, 2
(rpt1)shl.b r12.x, (last)(r)r12.x, 2
sad.s32 r10.z, c1.y, r10.z, (last)r10.x
add.u r13.w, c1.y, r10.y
add.u r14.x, c5.y, r10.y
isam.v.base0 (u16)(xyzw)hr25.z, r11.z, s#0, t#0
add.u r14.y, c5.x, r10.y
add.u r14.z, c4.w, r10.y
isam.v.base0 (u16)(xyzw)hr0.z, r12.x, s#0, t#0
add.u r14.w, c4.z, r10.y
add.u r15.x, c4.y, r10.y
add.u r15.y, c4.x, r10.y
add.u r15.z, c3.w, r10.y
add.u r15.w, c3.z, r10.y
add.u r16.x, c3.y, r10.y
add.u r16.y, c3.x, r10.y
add.u r16.z, c2.w, r10.y
add.u r16.w, c2.z, r10.y
add.u r17.x, c2.y, r10.y
add.u r17.y, c2.x, r10.y
add.u r17.z, c1.w, r10.y
add.u r10.y, c1.z, (last)r10.y
shl.b r13.z, r1.z, 2
(sy)stl.u16 l[r10.w], r25.z, 4
(ss)nop
isam.v.base0 (u16)(xyzw)hr21.z, r11.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr22.z, r12.y, s#0, t#2
stl.u16 l[r12.z], r0.z, 4
(sy)stl.u16 l[r9.w], r21.z, 4
stl.u16 l[r10.z], r22.z, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
ldl.u16 r23.z, l[r13.y], 4
ldl.u16 r24.z, l[r13.y+128], 4
ldl.u16 r25.z, l[r13.w], 4
(ss)nop
ldl.u16 r27.z, l[r14.x], 4
ldl.u16 r0.z, l[r13.y+256], 4
mad.f16 hr18.z, hr25.z, hr23.z, (last)hr18.z
mad.f16 hr16.z, hr25.z, hr23.w, (last)hr16.z
mad.f16 hr14.z, hr25.z, hr24.x, (last)hr14.z
mad.f16 hr12.z, hr25.z, hr24.y, (last)hr12.z
mad.f16 hr10.z, hr25.z, hr24.z, (last)hr10.z
mad.f16 hr8.z, hr25.z, hr24.w, (last)hr8.z
mad.f16 hr6.z, hr25.z, hr25.x, (last)hr6.z
mad.f16 hr18.w, hr25.w, hr23.z, (last)hr18.w
mad.f16 hr16.w, hr25.w, hr23.w, (last)hr16.w
mad.f16 hr14.w, hr25.w, hr24.x, (last)hr14.w
mad.f16 hr12.w, hr25.w, hr24.y, (last)hr12.w
mad.f16 hr10.w, hr25.w, hr24.z, (last)hr10.w
mad.f16 hr8.w, hr25.w, hr24.w, (last)hr8.w
mad.f16 hr6.w, hr25.w, hr25.x, (last)hr6.w
mad.f16 hr19.x, hr26.x, hr23.z, (last)hr19.x
mad.f16 hr17.x, hr26.x, hr23.w, (last)hr17.x
mad.f16 hr15.x, hr26.x, hr24.x, (last)hr15.x
mad.f16 hr13.x, hr26.x, hr24.y, (last)hr13.x
mad.f16 hr11.x, hr26.x, hr24.z, (last)hr11.x
mad.f16 hr9.x, hr26.x, hr24.w, (last)hr9.x
mad.f16 hr7.x, hr26.x, hr25.x, (last)hr7.x
mad.f16 hr19.y, hr26.y, hr23.z, (last)hr19.y
mad.f16 hr17.y, hr26.y, hr23.w, (last)hr17.y
mad.f16 hr15.y, hr26.y, hr24.x, (last)hr15.y
mad.f16 hr13.y, hr26.y, hr24.y, (last)hr13.y
mad.f16 hr11.y, hr26.y, hr24.z, (last)hr11.y
mad.f16 hr9.y, hr26.y, hr24.w, (last)hr9.y
mad.f16 hr7.y, hr26.y, hr25.x, (last)hr7.y
(ss)mad.f16 hr17.z, hr27.z, hr23.z, (last)hr17.z
mad.f16 hr15.z, hr27.z, hr23.w, (last)hr15.z
mad.f16 hr13.z, hr27.z, hr24.x, (last)hr13.z
mad.f16 hr11.z, hr27.z, hr24.y, (last)hr11.z
mad.f16 hr9.z, hr27.z, hr24.z, (last)hr9.z
mad.f16 hr7.z, hr27.z, hr24.w, (last)hr7.z
mad.f16 hr5.z, hr27.z, hr25.x, (last)hr5.z
mad.f16 hr17.w, hr27.w, hr23.z, (last)hr17.w
mad.f16 hr15.w, hr27.w, hr23.w, (last)hr15.w
mad.f16 hr13.w, hr27.w, hr24.x, (last)hr13.w
mad.f16 hr11.w, hr27.w, hr24.y, (last)hr11.w
mad.f16 hr9.w, hr27.w, hr24.z, (last)hr9.w
mad.f16 hr7.w, hr27.w, hr24.w, (last)hr7.w
mad.f16 hr5.w, hr27.w, hr25.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr28.x, hr23.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr28.x, hr23.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr28.x, hr24.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr28.x, hr24.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr28.x, hr24.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr28.x, hr24.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr28.x, hr25.x, (r)(last)hr6.x
(rpt1)mad.f16 hr25.z, (r)(last)hr25.z, hr25.y, (r)(last)hr4.z
(rpt1)mad.f16 hr26.x, (r)(last)hr26.x, hr25.y, (r)(last)hr5.x
(rpt1)mad.f16 hr27.z, (r)(last)hr27.z, hr25.y, (r)(last)hr3.z
(rpt1)mad.f16 hr28.x, (r)(last)hr28.x, hr25.y, (r)(last)hr4.x
ldl.u16 r3.z, l[r13.y+384], 4
ldl.u16 r4.z, l[r14.y], 4
ldl.u16 r19.z, l[r14.y+128], 4
ldl.u16 r21.x, l[r13.y+512], 4
ldl.u16 r22.x, l[r13.y+640], 4
ldl.u16 r23.x, l[r14.z], 4
ldl.u16 r24.x, l[r14.z+128], 4
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
(rpt1)mad.f16 hr4.z, (r)(last)hr4.z, hr4.y, (r)(last)hr25.z
ldl.u16 r25.x, l[r13.y+768], 4
(rpt1)mad.f16 hr19.z, (r)(last)hr19.z, hr4.y, (r)(last)hr27.z
(rpt1)mad.f16 hr20.x, (r)(last)hr20.x, hr4.y, (r)(last)hr28.x
ldl.u16 r27.z, l[r13.y+896], 4
ldl.u16 r28.z, l[r14.w], 4
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
ldl.u16 r0.z, l[r14.w+128], 4
mad.f16 hr11.y, hr5.y, hr3.z, (last)hr11.y
mad.f16 hr9.y, hr5.y, hr3.w, (last)hr9.y
mad.f16 hr7.y, hr5.y, hr4.x, (last)hr7.y
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr4.y, (r)(last)hr26.x
ldl.u16 r3.z, l[r13.y+1024], 4
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
mad.f16 hr17.z, hr24.x, hr21.x, (last)hr17.z
mad.f16 hr15.z, hr24.x, hr21.y, (last)hr15.z
mad.f16 hr13.z, hr24.x, hr21.z, (last)hr13.z
mad.f16 hr11.z, hr24.x, hr21.w, (last)hr11.z
mad.f16 hr9.z, hr24.x, hr22.x, (last)hr9.z
mad.f16 hr7.z, hr24.x, hr22.y, (last)hr7.z
mad.f16 hr5.z, hr24.x, hr22.z, (last)hr5.z
mad.f16 hr17.w, hr24.y, hr21.x, (last)hr17.w
mad.f16 hr15.w, hr24.y, hr21.y, (last)hr15.w
mad.f16 hr13.w, hr24.y, hr21.z, (last)hr13.w
mad.f16 hr11.w, hr24.y, hr21.w, (last)hr11.w
mad.f16 hr9.w, hr24.y, hr22.x, (last)hr9.w
mad.f16 hr7.w, hr24.y, hr22.y, (last)hr7.w
mad.f16 hr5.w, hr24.y, hr22.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr24.z, hr21.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr24.z, hr21.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr24.z, hr21.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr24.z, hr21.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr24.z, hr22.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr24.z, hr22.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr24.z, hr22.z, (r)(last)hr6.x
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
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr22.w, (r)(last)hr4.z
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr22.w, (r)(last)hr19.z
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr22.w, (r)(last)hr20.x
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr22.w, (r)(last)hr5.x
ldl.u16 r4.z, l[r13.y+1152], 4
ldl.u16 r19.z, l[r15.x], 4
ldl.u16 r21.x, l[r15.x+128], 4
ldl.u16 r22.x, l[r13.y+1280], 4
(ss)mad.f16 hr18.z, hr28.z, hr25.x, (last)hr18.z
mad.f16 hr16.z, hr28.z, hr25.y, (last)hr16.z
mad.f16 hr14.z, hr28.z, hr25.z, (last)hr14.z
mad.f16 hr12.z, hr28.z, hr25.w, (last)hr12.z
mad.f16 hr10.z, hr28.z, hr27.z, (last)hr10.z
mad.f16 hr8.z, hr28.z, hr27.w, (last)hr8.z
mad.f16 hr6.z, hr28.z, hr28.x, (last)hr6.z
mad.f16 hr18.w, hr28.w, hr25.x, (last)hr18.w
mad.f16 hr16.w, hr28.w, hr25.y, (last)hr16.w
mad.f16 hr14.w, hr28.w, hr25.z, (last)hr14.w
mad.f16 hr12.w, hr28.w, hr25.w, (last)hr12.w
mad.f16 hr10.w, hr28.w, hr27.z, (last)hr10.w
mad.f16 hr8.w, hr28.w, hr27.w, (last)hr8.w
mad.f16 hr6.w, hr28.w, hr28.x, (last)hr6.w
mad.f16 hr19.x, hr29.x, hr25.x, (last)hr19.x
mad.f16 hr17.x, hr29.x, hr25.y, (last)hr17.x
mad.f16 hr15.x, hr29.x, hr25.z, (last)hr15.x
mad.f16 hr13.x, hr29.x, hr25.w, (last)hr13.x
mad.f16 hr11.x, hr29.x, hr27.z, (last)hr11.x
mad.f16 hr9.x, hr29.x, hr27.w, (last)hr9.x
mad.f16 hr7.x, hr29.x, hr28.x, (last)hr7.x
mad.f16 hr19.y, hr29.y, hr25.x, (last)hr19.y
mad.f16 hr17.y, hr29.y, hr25.y, (last)hr17.y
mad.f16 hr15.y, hr29.y, hr25.z, (last)hr15.y
mad.f16 hr13.y, hr29.y, hr25.w, (last)hr13.y
mad.f16 hr11.y, hr29.y, hr27.z, (last)hr11.y
mad.f16 hr9.y, hr29.y, hr27.w, (last)hr9.y
mad.f16 hr7.y, hr29.y, hr28.x, (last)hr7.y
(rpt1)mad.f16 hr28.z, (r)(last)hr28.z, hr28.y, (r)(last)hr23.x
(rpt1)mad.f16 hr29.x, (r)(last)hr29.x, hr28.y, (r)(last)hr23.z
ldl.u16 r23.x, l[r13.y+1408], 4
mad.f16 hr17.z, hr0.z, hr25.x, (last)hr17.z
mad.f16 hr15.z, hr0.z, hr25.y, (last)hr15.z
mad.f16 hr13.z, hr0.z, hr25.z, (last)hr13.z
mad.f16 hr11.z, hr0.z, hr25.w, (last)hr11.z
mad.f16 hr9.z, hr0.z, hr27.z, (last)hr9.z
mad.f16 hr7.z, hr0.z, hr27.w, (last)hr7.z
mad.f16 hr5.z, hr0.z, hr28.x, (last)hr5.z
mad.f16 hr17.w, hr0.w, hr25.x, (last)hr17.w
mad.f16 hr15.w, hr0.w, hr25.y, (last)hr15.w
mad.f16 hr13.w, hr0.w, hr25.z, (last)hr13.w
mad.f16 hr11.w, hr0.w, hr25.w, (last)hr11.w
mad.f16 hr9.w, hr0.w, hr27.z, (last)hr9.w
mad.f16 hr7.w, hr0.w, hr27.w, (last)hr7.w
mad.f16 hr5.w, hr0.w, hr28.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr1.x, hr25.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr1.x, hr25.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr1.x, hr25.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr1.x, hr25.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr1.x, hr27.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr1.x, hr27.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr1.x, hr28.x, (r)(last)hr6.x
mad.f16 hr18.z, hr19.z, hr3.z, (last)hr18.z
mad.f16 hr16.z, hr19.z, hr3.w, (last)hr16.z
mad.f16 hr14.z, hr19.z, hr4.x, (last)hr14.z
mad.f16 hr12.z, hr19.z, hr4.y, (last)hr12.z
mad.f16 hr10.z, hr19.z, hr4.z, (last)hr10.z
mad.f16 hr8.z, hr19.z, hr4.w, (last)hr8.z
mad.f16 hr6.z, hr19.z, hr5.x, (last)hr6.z
mad.f16 hr18.w, hr19.w, hr3.z, (last)hr18.w
mad.f16 hr16.w, hr19.w, hr3.w, (last)hr16.w
mad.f16 hr14.w, hr19.w, hr4.x, (last)hr14.w
mad.f16 hr12.w, hr19.w, hr4.y, (last)hr12.w
mad.f16 hr10.w, hr19.w, hr4.z, (last)hr10.w
mad.f16 hr8.w, hr19.w, hr4.w, (last)hr8.w
mad.f16 hr6.w, hr19.w, hr5.x, (last)hr6.w
mad.f16 hr19.x, hr20.x, hr3.z, (last)hr19.x
mad.f16 hr17.x, hr20.x, hr3.w, (last)hr17.x
mad.f16 hr15.x, hr20.x, hr4.x, (last)hr15.x
mad.f16 hr13.x, hr20.x, hr4.y, (last)hr13.x
mad.f16 hr11.x, hr20.x, hr4.z, (last)hr11.x
mad.f16 hr9.x, hr20.x, hr4.w, (last)hr9.x
mad.f16 hr7.x, hr20.x, hr5.x, (last)hr7.x
mad.f16 hr19.y, hr20.y, hr3.z, (last)hr19.y
mad.f16 hr17.y, hr20.y, hr3.w, (last)hr17.y
mad.f16 hr15.y, hr20.y, hr4.x, (last)hr15.y
mad.f16 hr13.y, hr20.y, hr4.y, (last)hr13.y
mad.f16 hr11.y, hr20.y, hr4.z, (last)hr11.y
mad.f16 hr9.y, hr20.y, hr4.w, (last)hr9.y
mad.f16 hr7.y, hr20.y, hr5.x, (last)hr7.y
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr28.y, (r)(last)hr24.x
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr28.y, (r)(last)hr24.z
ldl.u16 r24.x, l[r15.y], 4
ldl.u16 r25.x, l[r15.y+128], 4
ldl.u16 r27.z, l[r13.y+1536], 4
(rpt1)mad.f16 hr19.z, (r)(last)hr19.z, hr5.y, (r)(last)hr28.z
(rpt1)mad.f16 hr20.x, (r)(last)hr20.x, hr5.y, (r)(last)hr29.x
ldl.u16 r28.z, l[r13.y+1664], 4
ldl.u16 r29.z, l[r15.z], 4
mad.f16 hr17.z, hr21.x, hr3.z, (last)hr17.z
mad.f16 hr15.z, hr21.x, hr3.w, (last)hr15.z
mad.f16 hr13.z, hr21.x, hr4.x, (last)hr13.z
mad.f16 hr11.z, hr21.x, hr4.y, (last)hr11.z
mad.f16 hr9.z, hr21.x, hr4.z, (last)hr9.z
mad.f16 hr7.z, hr21.x, hr4.w, (last)hr7.z
mad.f16 hr5.z, hr21.x, hr5.x, (last)hr5.z
mad.f16 hr17.w, hr21.y, hr3.z, (last)hr17.w
mad.f16 hr15.w, hr21.y, hr3.w, (last)hr15.w
mad.f16 hr13.w, hr21.y, hr4.x, (last)hr13.w
(ss)nop
ldl.u16 r30.z, l[r15.z+128], 4
mad.f16 hr11.w, hr21.y, hr4.y, (last)hr11.w
mad.f16 hr9.w, hr21.y, hr4.z, (last)hr9.w
mad.f16 hr7.w, hr21.y, hr4.w, (last)hr7.w
mad.f16 hr5.w, hr21.y, hr5.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr21.z, hr3.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr21.z, hr3.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr21.z, hr4.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr21.z, hr4.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr21.z, hr4.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr21.z, hr4.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr21.z, hr5.x, (r)(last)hr6.x
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
(rpt1)mad.f16 hr21.x, (r)(last)hr21.x, hr5.y, (r)(last)hr0.z
(rpt1)mad.f16 hr21.z, (r)(last)hr21.z, hr5.y, (r)(last)hr1.x
ldl.u16 r0.z, l[r13.y+1792], 4
ldl.u16 r3.z, l[r13.y+1920], 4
ldl.u16 r4.z, l[r15.w], 4
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr23.w, (r)(last)hr19.z
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr23.w, (r)(last)hr20.x
ldl.u16 r19.z, l[r15.w+128], 4
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
(rpt1)mad.f16 hr25.x, (r)(last)hr25.x, hr23.w, (r)(last)hr21.x
(rpt1)mad.f16 hr25.z, (r)(last)hr25.z, hr23.w, (r)(last)hr21.z
ldl.u16 r21.x, l[r13.y+2048], 4
ldl.u16 r22.x, l[r13.y+2176], 4
ldl.u16 r23.x, l[r16.x], 4
mad.f16 hr18.z, hr29.z, hr27.z, (last)hr18.z
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
(ss)mad.f16 hr17.z, hr30.z, hr27.z, (last)hr17.z
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
(rpt1)mad.f16 hr29.z, (r)(last)hr29.z, hr29.y, (r)(last)hr24.x
(rpt1)mad.f16 hr30.x, (r)(last)hr30.x, hr29.y, (r)(last)hr24.z
ldl.u16 r24.x, l[r16.x+128], 4
(rpt1)mad.f16 hr30.z, (r)(last)hr30.z, hr29.y, (r)(last)hr25.x
(rpt1)mad.f16 hr31.x, (r)(last)hr31.x, hr29.y, (r)(last)hr25.z
ldl.u16 r25.x, l[r13.y+2304], 4
ldl.u16 r27.z, l[r13.y+2432], 4
ldl.u16 r28.z, l[r16.y], 4
mad.f16 hr18.z, hr4.z, hr0.z, (last)hr18.z
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
ldl.u16 r29.z, l[r16.y+128], 4
(rpt1)mad.f16 hr19.z, (r)(last)hr19.z, hr4.y, (r)(last)hr30.z
(rpt1)mad.f16 hr20.x, (r)(last)hr20.x, hr4.y, (r)(last)hr31.x
ldl.u16 r30.z, l[r13.y+2560], 4
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
(ss)nop
ldl.u16 r31.z, l[r13.y+2688], 4
ldl.u16 r0.z, l[r16.z], 4
ldl.u16 r3.z, l[r16.z+128], 4
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
mad.f16 hr17.z, hr24.x, hr21.x, (last)hr17.z
mad.f16 hr15.z, hr24.x, hr21.y, (last)hr15.z
mad.f16 hr13.z, hr24.x, hr21.z, (last)hr13.z
mad.f16 hr11.z, hr24.x, hr21.w, (last)hr11.z
mad.f16 hr9.z, hr24.x, hr22.x, (last)hr9.z
mad.f16 hr7.z, hr24.x, hr22.y, (last)hr7.z
mad.f16 hr5.z, hr24.x, hr22.z, (last)hr5.z
mad.f16 hr17.w, hr24.y, hr21.x, (last)hr17.w
mad.f16 hr15.w, hr24.y, hr21.y, (last)hr15.w
mad.f16 hr13.w, hr24.y, hr21.z, (last)hr13.w
mad.f16 hr11.w, hr24.y, hr21.w, (last)hr11.w
mad.f16 hr9.w, hr24.y, hr22.x, (last)hr9.w
mad.f16 hr7.w, hr24.y, hr22.y, (last)hr7.w
mad.f16 hr5.w, hr24.y, hr22.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr24.z, hr21.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr24.z, hr21.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr24.z, hr21.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr24.z, hr21.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr24.z, hr22.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr24.z, hr22.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr24.z, hr22.z, (r)(last)hr6.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr22.w, (r)(last)hr4.z
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr22.w, (r)(last)hr5.x
ldl.u16 r4.z, l[r13.y+2816], 4
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr22.w, (r)(last)hr19.z
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr22.w, (r)(last)hr20.x
ldl.u16 r19.z, l[r13.y+2944], 4
ldl.u16 r21.x, l[r16.w], 4
ldl.u16 r22.x, l[r16.w+128], 4
mad.f16 hr18.z, hr28.z, hr25.x, (last)hr18.z
mad.f16 hr16.z, hr28.z, hr25.y, (last)hr16.z
mad.f16 hr14.z, hr28.z, hr25.z, (last)hr14.z
mad.f16 hr12.z, hr28.z, hr25.w, (last)hr12.z
mad.f16 hr10.z, hr28.z, hr27.z, (last)hr10.z
mad.f16 hr8.z, hr28.z, hr27.w, (last)hr8.z
mad.f16 hr6.z, hr28.z, hr28.x, (last)hr6.z
mad.f16 hr18.w, hr28.w, hr25.x, (last)hr18.w
mad.f16 hr16.w, hr28.w, hr25.y, (last)hr16.w
mad.f16 hr14.w, hr28.w, hr25.z, (last)hr14.w
mad.f16 hr12.w, hr28.w, hr25.w, (last)hr12.w
mad.f16 hr10.w, hr28.w, hr27.z, (last)hr10.w
mad.f16 hr8.w, hr28.w, hr27.w, (last)hr8.w
mad.f16 hr6.w, hr28.w, hr28.x, (last)hr6.w
mad.f16 hr19.x, hr29.x, hr25.x, (last)hr19.x
mad.f16 hr17.x, hr29.x, hr25.y, (last)hr17.x
mad.f16 hr15.x, hr29.x, hr25.z, (last)hr15.x
mad.f16 hr13.x, hr29.x, hr25.w, (last)hr13.x
mad.f16 hr11.x, hr29.x, hr27.z, (last)hr11.x
mad.f16 hr9.x, hr29.x, hr27.w, (last)hr9.x
mad.f16 hr7.x, hr29.x, hr28.x, (last)hr7.x
mad.f16 hr19.y, hr29.y, hr25.x, (last)hr19.y
mad.f16 hr17.y, hr29.y, hr25.y, (last)hr17.y
mad.f16 hr15.y, hr29.y, hr25.z, (last)hr15.y
mad.f16 hr13.y, hr29.y, hr25.w, (last)hr13.y
mad.f16 hr11.y, hr29.y, hr27.z, (last)hr11.y
mad.f16 hr9.y, hr29.y, hr27.w, (last)hr9.y
mad.f16 hr7.y, hr29.y, hr28.x, (last)hr7.y
mad.f16 hr17.z, hr29.z, hr25.x, (last)hr17.z
mad.f16 hr15.z, hr29.z, hr25.y, (last)hr15.z
mad.f16 hr13.z, hr29.z, hr25.z, (last)hr13.z
mad.f16 hr11.z, hr29.z, hr25.w, (last)hr11.z
mad.f16 hr9.z, hr29.z, hr27.z, (last)hr9.z
mad.f16 hr7.z, hr29.z, hr27.w, (last)hr7.z
mad.f16 hr5.z, hr29.z, hr28.x, (last)hr5.z
mad.f16 hr17.w, hr29.w, hr25.x, (last)hr17.w
mad.f16 hr15.w, hr29.w, hr25.y, (last)hr15.w
mad.f16 hr13.w, hr29.w, hr25.z, (last)hr13.w
mad.f16 hr11.w, hr29.w, hr25.w, (last)hr11.w
mad.f16 hr9.w, hr29.w, hr27.z, (last)hr9.w
mad.f16 hr7.w, hr29.w, hr27.w, (last)hr7.w
mad.f16 hr5.w, hr29.w, hr28.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr30.x, hr25.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr30.x, hr25.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr30.x, hr25.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr30.x, hr25.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr30.x, hr27.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr30.x, hr27.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr30.x, hr28.x, (r)(last)hr6.x
(rpt1)mad.f16 hr28.z, (r)(last)hr28.z, hr28.y, (r)(last)hr23.x
(rpt1)mad.f16 hr29.x, (r)(last)hr29.x, hr28.y, (r)(last)hr23.z
ldl.u16 r23.x, l[r13.y+3072], 4
(rpt1)mad.f16 hr29.z, (r)(last)hr29.z, hr28.y, (r)(last)hr24.x
(rpt1)mad.f16 hr30.x, (r)(last)hr30.x, hr28.y, (r)(last)hr24.z
ldl.u16 r24.x, l[r13.y+3200], 4
ldl.u16 r25.x, l[r17.x], 4
ldl.u16 r27.z, l[r17.x+128], 4
(ss)mad.f16 hr18.z, hr0.z, hr30.z, (last)hr18.z
mad.f16 hr16.z, hr0.z, hr30.w, (last)hr16.z
mad.f16 hr14.z, hr0.z, hr31.x, (last)hr14.z
mad.f16 hr12.z, hr0.z, hr31.y, (last)hr12.z
mad.f16 hr10.z, hr0.z, hr31.z, (last)hr10.z
mad.f16 hr8.z, hr0.z, hr31.w, (last)hr8.z
mad.f16 hr6.z, hr0.z, hr32.x, (last)hr6.z
mad.f16 hr18.w, hr0.w, hr30.z, (last)hr18.w
mad.f16 hr16.w, hr0.w, hr30.w, (last)hr16.w
mad.f16 hr14.w, hr0.w, hr31.x, (last)hr14.w
mad.f16 hr12.w, hr0.w, hr31.y, (last)hr12.w
mad.f16 hr10.w, hr0.w, hr31.z, (last)hr10.w
mad.f16 hr8.w, hr0.w, hr31.w, (last)hr8.w
mad.f16 hr6.w, hr0.w, hr32.x, (last)hr6.w
mad.f16 hr19.x, hr1.x, hr30.z, (last)hr19.x
mad.f16 hr17.x, hr1.x, hr30.w, (last)hr17.x
mad.f16 hr15.x, hr1.x, hr31.x, (last)hr15.x
mad.f16 hr13.x, hr1.x, hr31.y, (last)hr13.x
mad.f16 hr11.x, hr1.x, hr31.z, (last)hr11.x
mad.f16 hr9.x, hr1.x, hr31.w, (last)hr9.x
mad.f16 hr7.x, hr1.x, hr32.x, (last)hr7.x
mad.f16 hr19.y, hr1.y, hr30.z, (last)hr19.y
mad.f16 hr17.y, hr1.y, hr30.w, (last)hr17.y
mad.f16 hr15.y, hr1.y, hr31.x, (last)hr15.y
mad.f16 hr13.y, hr1.y, hr31.y, (last)hr13.y
mad.f16 hr11.y, hr1.y, hr31.z, (last)hr11.y
mad.f16 hr9.y, hr1.y, hr31.w, (last)hr9.y
mad.f16 hr7.y, hr1.y, hr32.x, (last)hr7.y
mad.f16 hr17.z, hr3.z, hr30.z, (last)hr17.z
mad.f16 hr15.z, hr3.z, hr30.w, (last)hr15.z
mad.f16 hr13.z, hr3.z, hr31.x, (last)hr13.z
mad.f16 hr11.z, hr3.z, hr31.y, (last)hr11.z
mad.f16 hr9.z, hr3.z, hr31.z, (last)hr9.z
mad.f16 hr7.z, hr3.z, hr31.w, (last)hr7.z
mad.f16 hr5.z, hr3.z, hr32.x, (last)hr5.z
mad.f16 hr17.w, hr3.w, hr30.z, (last)hr17.w
mad.f16 hr15.w, hr3.w, hr30.w, (last)hr15.w
mad.f16 hr13.w, hr3.w, hr31.x, (last)hr13.w
mad.f16 hr11.w, hr3.w, hr31.y, (last)hr11.w
mad.f16 hr9.w, hr3.w, hr31.z, (last)hr9.w
mad.f16 hr7.w, hr3.w, hr31.w, (last)hr7.w
mad.f16 hr5.w, hr3.w, hr32.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr4.x, hr30.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr4.x, hr30.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr4.x, hr31.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr4.x, hr31.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr4.x, hr31.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr4.x, hr31.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr4.x, hr32.x, (r)(last)hr6.x
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr32.y, (r)(last)hr28.z
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr32.y, (r)(last)hr29.x
ldl.u16 r28.z, l[r13.y+3328], 4
(rpt1)mad.f16 hr3.z, (r)(last)hr3.z, hr32.y, (r)(last)hr29.z
(rpt1)mad.f16 hr4.x, (r)(last)hr4.x, hr32.y, (r)(last)hr30.x
ldl.u16 r29.z, l[r13.y+3456], 4
ldl.u16 r30.z, l[r17.y], 4
ldl.u16 r31.z, l[r17.y+128], 4
ldl.u16 r32.z, l[r13.y+3584], 4
ldl.u16 r33.z, l[r13.y+3712], 4
mad.f16 hr18.z, hr21.x, hr4.z, (last)hr18.z
mad.f16 hr16.z, hr21.x, hr4.w, (last)hr16.z
mad.f16 hr14.z, hr21.x, hr5.x, (last)hr14.z
mad.f16 hr12.z, hr21.x, hr5.y, (last)hr12.z
mad.f16 hr10.z, hr21.x, hr19.z, (last)hr10.z
mad.f16 hr8.z, hr21.x, hr19.w, (last)hr8.z
mad.f16 hr6.z, hr21.x, hr20.x, (last)hr6.z
mad.f16 hr18.w, hr21.y, hr4.z, (last)hr18.w
mad.f16 hr16.w, hr21.y, hr4.w, (last)hr16.w
mad.f16 hr14.w, hr21.y, hr5.x, (last)hr14.w
mad.f16 hr12.w, hr21.y, hr5.y, (last)hr12.w
mad.f16 hr10.w, hr21.y, hr19.z, (last)hr10.w
mad.f16 hr8.w, hr21.y, hr19.w, (last)hr8.w
mad.f16 hr6.w, hr21.y, hr20.x, (last)hr6.w
mad.f16 hr19.x, hr21.z, hr4.z, (last)hr19.x
mad.f16 hr17.x, hr21.z, hr4.w, (last)hr17.x
mad.f16 hr15.x, hr21.z, hr5.x, (last)hr15.x
mad.f16 hr13.x, hr21.z, hr5.y, (last)hr13.x
mad.f16 hr11.x, hr21.z, hr19.z, (last)hr11.x
mad.f16 hr9.x, hr21.z, hr19.w, (last)hr9.x
mad.f16 hr7.x, hr21.z, hr20.x, (last)hr7.x
mad.f16 hr19.y, hr21.w, hr4.z, (last)hr19.y
mad.f16 hr17.y, hr21.w, hr4.w, (last)hr17.y
mad.f16 hr15.y, hr21.w, hr5.x, (last)hr15.y
mad.f16 hr13.y, hr21.w, hr5.y, (last)hr13.y
mad.f16 hr11.y, hr21.w, hr19.z, (last)hr11.y
mad.f16 hr9.y, hr21.w, hr19.w, (last)hr9.y
mad.f16 hr7.y, hr21.w, hr20.x, (last)hr7.y
mad.f16 hr17.z, hr22.x, hr4.z, (last)hr17.z
mad.f16 hr15.z, hr22.x, hr4.w, (last)hr15.z
mad.f16 hr13.z, hr22.x, hr5.x, (last)hr13.z
mad.f16 hr11.z, hr22.x, hr5.y, (last)hr11.z
mad.f16 hr9.z, hr22.x, hr19.z, (last)hr9.z
mad.f16 hr7.z, hr22.x, hr19.w, (last)hr7.z
mad.f16 hr5.z, hr22.x, hr20.x, (last)hr5.z
mad.f16 hr17.w, hr22.y, hr4.z, (last)hr17.w
mad.f16 hr15.w, hr22.y, hr4.w, (last)hr15.w
mad.f16 hr13.w, hr22.y, hr5.x, (last)hr13.w
mad.f16 hr11.w, hr22.y, hr5.y, (last)hr11.w
mad.f16 hr9.w, hr22.y, hr19.z, (last)hr9.w
mad.f16 hr7.w, hr22.y, hr19.w, (last)hr7.w
mad.f16 hr5.w, hr22.y, hr20.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr22.z, hr4.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr22.z, hr4.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr22.z, hr5.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr22.z, hr5.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr22.z, hr19.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr22.z, hr19.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr22.z, hr20.x, (r)(last)hr6.x
(rpt1)mad.f16 hr21.x, (r)(last)hr21.x, hr20.y, (r)(last)hr0.z
(rpt1)mad.f16 hr21.z, (r)(last)hr21.z, hr20.y, (r)(last)hr1.x
ldl.u16 r0.z, l[r17.z], 4
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr20.y, (r)(last)hr3.z
(rpt1)mad.f16 hr22.z, (r)(last)hr22.z, hr20.y, (r)(last)hr4.x
ldl.u16 r3.z, l[r17.z+128], 4
ldl.u16 r4.z, l[r13.y+3840], 4
ldl.u16 r19.z, l[r13.y+3968], 4
mad.f16 hr18.z, hr25.x, hr23.x, (last)hr18.z
mad.f16 hr16.z, hr25.x, hr23.y, (last)hr16.z
mad.f16 hr14.z, hr25.x, hr23.z, (last)hr14.z
mad.f16 hr12.z, hr25.x, hr23.w, (last)hr12.z
mad.f16 hr10.z, hr25.x, hr24.x, (last)hr10.z
mad.f16 hr8.z, hr25.x, hr24.y, (last)hr8.z
mad.f16 hr6.z, hr25.x, hr24.z, (last)hr6.z
mad.f16 hr18.w, hr25.y, hr23.x, (last)hr18.w
mad.f16 hr16.w, hr25.y, hr23.y, (last)hr16.w
mad.f16 hr14.w, hr25.y, hr23.z, (last)hr14.w
mad.f16 hr12.w, hr25.y, hr23.w, (last)hr12.w
mad.f16 hr10.w, hr25.y, hr24.x, (last)hr10.w
mad.f16 hr8.w, hr25.y, hr24.y, (last)hr8.w
mad.f16 hr6.w, hr25.y, hr24.z, (last)hr6.w
mad.f16 hr19.x, hr25.z, hr23.x, (last)hr19.x
mad.f16 hr17.x, hr25.z, hr23.y, (last)hr17.x
mad.f16 hr15.x, hr25.z, hr23.z, (last)hr15.x
mad.f16 hr13.x, hr25.z, hr23.w, (last)hr13.x
mad.f16 hr11.x, hr25.z, hr24.x, (last)hr11.x
mad.f16 hr9.x, hr25.z, hr24.y, (last)hr9.x
mad.f16 hr7.x, hr25.z, hr24.z, (last)hr7.x
mad.f16 hr19.y, hr25.w, hr23.x, (last)hr19.y
mad.f16 hr17.y, hr25.w, hr23.y, (last)hr17.y
mad.f16 hr15.y, hr25.w, hr23.z, (last)hr15.y
mad.f16 hr13.y, hr25.w, hr23.w, (last)hr13.y
mad.f16 hr11.y, hr25.w, hr24.x, (last)hr11.y
mad.f16 hr9.y, hr25.w, hr24.y, (last)hr9.y
mad.f16 hr7.y, hr25.w, hr24.z, (last)hr7.y
mad.f16 hr17.z, hr27.z, hr23.x, (last)hr17.z
mad.f16 hr15.z, hr27.z, hr23.y, (last)hr15.z
mad.f16 hr13.z, hr27.z, hr23.z, (last)hr13.z
mad.f16 hr11.z, hr27.z, hr23.w, (last)hr11.z
mad.f16 hr17.w, hr27.w, hr23.x, (last)hr17.w
mad.f16 hr15.w, hr27.w, hr23.y, (last)hr15.w
mad.f16 hr13.w, hr27.w, hr23.z, (last)hr13.w
mad.f16 hr11.w, hr27.w, hr23.w, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr28.x, hr23.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr28.x, hr23.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr28.x, hr23.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr28.x, hr23.w, (r)(last)hr12.x
(rpt1)mad.f16 hr25.x, (r)(last)hr25.x, hr24.w, (r)(last)hr21.x
(rpt1)mad.f16 hr25.z, (r)(last)hr25.z, hr24.w, (r)(last)hr21.z
ldl.u16 r21.x, l[r10.y], 4
ldl.u16 r23.x, l[r10.y+128], 4
mad.f16 hr9.z, hr27.z, hr24.x, (last)hr9.z
mad.f16 hr7.z, hr27.z, hr24.y, (last)hr7.z
mad.f16 hr5.z, hr27.z, hr24.z, (last)hr5.z
mad.f16 hr9.w, hr27.w, hr24.x, (last)hr9.w
mad.f16 hr7.w, hr27.w, hr24.y, (last)hr7.w
mad.f16 hr5.w, hr27.w, hr24.z, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr28.x, hr24.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr28.x, hr24.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr28.x, hr24.z, (r)(last)hr6.x
(rpt1)mad.f16 hr27.z, (r)(last)hr27.z, hr24.w, (r)(last)hr22.x
(rpt1)mad.f16 hr28.x, (r)(last)hr28.x, hr24.w, (r)(last)hr22.z
(ss)mad.f16 hr18.z, hr30.z, hr28.z, (last)hr18.z
mad.f16 hr16.z, hr30.z, hr28.w, (last)hr16.z
mad.f16 hr14.z, hr30.z, hr29.x, (last)hr14.z
mad.f16 hr12.z, hr30.z, hr29.y, (last)hr12.z
mad.f16 hr10.z, hr30.z, hr29.z, (last)hr10.z
mad.f16 hr8.z, hr30.z, hr29.w, (last)hr8.z
mad.f16 hr6.z, hr30.z, hr30.x, (last)hr6.z
mad.f16 hr18.w, hr30.w, hr28.z, (last)hr18.w
mad.f16 hr16.w, hr30.w, hr28.w, (last)hr16.w
mad.f16 hr14.w, hr30.w, hr29.x, (last)hr14.w
mad.f16 hr12.w, hr30.w, hr29.y, (last)hr12.w
mad.f16 hr10.w, hr30.w, hr29.z, (last)hr10.w
mad.f16 hr8.w, hr30.w, hr29.w, (last)hr8.w
mad.f16 hr6.w, hr30.w, hr30.x, (last)hr6.w
mad.f16 hr19.x, hr31.x, hr28.z, (last)hr19.x
mad.f16 hr17.x, hr31.x, hr28.w, (last)hr17.x
mad.f16 hr15.x, hr31.x, hr29.x, (last)hr15.x
mad.f16 hr13.x, hr31.x, hr29.y, (last)hr13.x
mad.f16 hr11.x, hr31.x, hr29.z, (last)hr11.x
mad.f16 hr9.x, hr31.x, hr29.w, (last)hr9.x
mad.f16 hr7.x, hr31.x, hr30.x, (last)hr7.x
mad.f16 hr19.y, hr31.y, hr28.z, (last)hr19.y
mad.f16 hr17.y, hr31.y, hr28.w, (last)hr17.y
mad.f16 hr15.y, hr31.y, hr29.x, (last)hr15.y
mad.f16 hr13.y, hr31.y, hr29.y, (last)hr13.y
mad.f16 hr11.y, hr31.y, hr29.z, (last)hr11.y
mad.f16 hr9.y, hr31.y, hr29.w, (last)hr9.y
mad.f16 hr7.y, hr31.y, hr30.x, (last)hr7.y
mad.f16 hr17.z, hr31.z, hr28.z, (last)hr17.z
mad.f16 hr15.z, hr31.z, hr28.w, (last)hr15.z
mad.f16 hr13.z, hr31.z, hr29.x, (last)hr13.z
mad.f16 hr11.z, hr31.z, hr29.y, (last)hr11.z
mad.f16 hr17.w, hr31.w, hr28.z, (last)hr17.w
mad.f16 hr15.w, hr31.w, hr28.w, (last)hr15.w
mad.f16 hr13.w, hr31.w, hr29.x, (last)hr13.w
mad.f16 hr11.w, hr31.w, hr29.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr32.x, hr28.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr32.x, hr28.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr32.x, hr29.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr32.x, hr29.y, (r)(last)hr12.x
mad.f16 hr9.z, hr31.z, hr29.z, (last)hr9.z
mad.f16 hr7.z, hr31.z, hr29.w, (last)hr7.z
mad.f16 hr5.z, hr31.z, hr30.x, (last)hr5.z
mad.f16 hr9.w, hr31.w, hr29.z, (last)hr9.w
mad.f16 hr7.w, hr31.w, hr29.w, (last)hr7.w
mad.f16 hr5.w, hr31.w, hr30.x, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr32.x, hr29.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr32.x, hr29.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr32.x, hr30.x, (r)(last)hr6.x
(rpt1)mad.f16 hr30.z, (r)(last)hr30.z, hr30.y, (r)(last)hr25.x
(rpt1)mad.f16 hr31.x, (r)(last)hr31.x, hr30.y, (r)(last)hr25.z
(rpt1)mad.f16 hr31.z, (r)(last)hr31.z, hr30.y, (r)(last)hr27.z
(rpt1)mad.f16 hr32.x, (r)(last)hr32.x, hr30.y, (r)(last)hr28.x
mad.f16 hr18.z, hr0.z, hr32.z, (last)hr18.z
mad.f16 hr16.z, hr0.z, hr32.w, (last)hr16.z
mad.f16 hr14.z, hr0.z, hr33.x, (last)hr14.z
mad.f16 hr12.z, hr0.z, hr33.y, (last)hr12.z
mad.f16 hr10.z, hr0.z, hr33.z, (last)hr10.z
mad.f16 hr8.z, hr0.z, hr33.w, (last)hr8.z
mad.f16 hr6.z, hr0.z, hr34.x, (last)hr6.z
mad.f16 hr18.w, hr0.w, hr32.z, (last)hr18.w
mad.f16 hr16.w, hr0.w, hr32.w, (last)hr16.w
mad.f16 hr14.w, hr0.w, hr33.x, (last)hr14.w
mad.f16 hr12.w, hr0.w, hr33.y, (last)hr12.w
mad.f16 hr10.w, hr0.w, hr33.z, (last)hr10.w
mad.f16 hr8.w, hr0.w, hr33.w, (last)hr8.w
mad.f16 hr6.w, hr0.w, hr34.x, (last)hr6.w
mad.f16 hr19.x, hr1.x, hr32.z, (last)hr19.x
mad.f16 hr17.x, hr1.x, hr32.w, (last)hr17.x
mad.f16 hr15.x, hr1.x, hr33.x, (last)hr15.x
mad.f16 hr13.x, hr1.x, hr33.y, (last)hr13.x
mad.f16 hr11.x, hr1.x, hr33.z, (last)hr11.x
mad.f16 hr9.x, hr1.x, hr33.w, (last)hr9.x
mad.f16 hr7.x, hr1.x, hr34.x, (last)hr7.x
mad.f16 hr19.y, hr1.y, hr32.z, (last)hr19.y
mad.f16 hr17.y, hr1.y, hr32.w, (last)hr17.y
mad.f16 hr15.y, hr1.y, hr33.x, (last)hr15.y
mad.f16 hr13.y, hr1.y, hr33.y, (last)hr13.y
mad.f16 hr11.y, hr1.y, hr33.z, (last)hr11.y
mad.f16 hr9.y, hr1.y, hr33.w, (last)hr9.y
mad.f16 hr7.y, hr1.y, hr34.x, (last)hr7.y
mad.f16 hr17.z, hr3.z, hr32.z, (last)hr17.z
mad.f16 hr15.z, hr3.z, hr32.w, (last)hr15.z
mad.f16 hr13.z, hr3.z, hr33.x, (last)hr13.z
mad.f16 hr11.z, hr3.z, hr33.y, (last)hr11.z
mad.f16 hr17.w, hr3.w, hr32.z, (last)hr17.w
mad.f16 hr15.w, hr3.w, hr32.w, (last)hr15.w
mad.f16 hr13.w, hr3.w, hr33.x, (last)hr13.w
mad.f16 hr11.w, hr3.w, hr33.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr4.x, hr32.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr4.x, hr32.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr4.x, hr33.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr4.x, hr33.y, (r)(last)hr12.x
mad.f16 hr9.z, hr3.z, hr33.z, (last)hr9.z
mad.f16 hr7.z, hr3.z, hr33.w, (last)hr7.z
mad.f16 hr5.z, hr3.z, hr34.x, (last)hr5.z
mad.f16 hr9.w, hr3.w, hr33.z, (last)hr9.w
mad.f16 hr7.w, hr3.w, hr33.w, (last)hr7.w
mad.f16 hr5.w, hr3.w, hr34.x, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr4.x, hr33.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr4.x, hr33.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr4.x, hr34.x, (r)(last)hr6.x
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr34.y, (r)(last)hr30.z
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr34.y, (r)(last)hr31.x
(rpt1)mad.f16 hr3.z, (r)(last)hr3.z, hr34.y, (r)(last)hr31.z
(rpt1)mad.f16 hr4.x, (r)(last)hr4.x, hr34.y, (r)(last)hr32.x
fence.r.w
(sy)(ss)mad.f16 hr18.z, hr21.x, hr4.z, (last)hr18.z
mad.f16 hr16.z, hr21.x, hr4.w, (last)hr16.z
mad.f16 hr14.z, hr21.x, hr5.x, (last)hr14.z
mad.f16 hr12.z, hr21.x, hr5.y, (last)hr12.z
mad.f16 hr10.z, hr21.x, hr19.z, (last)hr10.z
mad.f16 hr8.z, hr21.x, hr19.w, (last)hr8.z
mad.f16 hr6.z, hr21.x, hr20.x, (last)hr6.z
mad.f16 hr18.w, hr21.y, hr4.z, (last)hr18.w
mad.f16 hr16.w, hr21.y, hr4.w, (last)hr16.w
mad.f16 hr14.w, hr21.y, hr5.x, (last)hr14.w
mad.f16 hr12.w, hr21.y, hr5.y, (last)hr12.w
mad.f16 hr10.w, hr21.y, hr19.z, (last)hr10.w
mad.f16 hr8.w, hr21.y, hr19.w, (last)hr8.w
mad.f16 hr6.w, hr21.y, hr20.x, (last)hr6.w
mad.f16 hr19.x, hr21.z, hr4.z, (last)hr19.x
mad.f16 hr17.x, hr21.z, hr4.w, (last)hr17.x
mad.f16 hr15.x, hr21.z, hr5.x, (last)hr15.x
mad.f16 hr13.x, hr21.z, hr5.y, (last)hr13.x
mad.f16 hr11.x, hr21.z, hr19.z, (last)hr11.x
mad.f16 hr9.x, hr21.z, hr19.w, (last)hr9.x
mad.f16 hr7.x, hr21.z, hr20.x, (last)hr7.x
mad.f16 hr19.y, hr21.w, hr4.z, (last)hr19.y
mad.f16 hr17.y, hr21.w, hr4.w, (last)hr17.y
mad.f16 hr15.y, hr21.w, hr5.x, (last)hr15.y
mad.f16 hr13.y, hr21.w, hr5.y, (last)hr13.y
mad.f16 hr11.y, hr21.w, hr19.z, (last)hr11.y
mad.f16 hr9.y, hr21.w, hr19.w, (last)hr9.y
mad.f16 hr7.y, hr21.w, hr20.x, (last)hr7.y
mad.f16 hr17.z, hr23.x, hr4.z, (last)hr17.z
mad.f16 hr15.z, hr23.x, hr4.w, (last)hr15.z
mad.f16 hr13.z, hr23.x, hr5.x, (last)hr13.z
mad.f16 hr11.z, hr23.x, hr5.y, (last)hr11.z
mad.f16 hr17.w, hr23.y, hr4.z, (last)hr17.w
mad.f16 hr15.w, hr23.y, hr4.w, (last)hr15.w
mad.f16 hr13.w, hr23.y, hr5.x, (last)hr13.w
mad.f16 hr11.w, hr23.y, hr5.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr23.z, hr4.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr23.z, hr4.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr23.z, hr5.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr23.z, hr5.y, (r)(last)hr12.x
mad.f16 hr9.z, hr23.x, hr19.z, (last)hr9.z
mad.f16 hr7.z, hr23.x, hr19.w, (last)hr7.z
mad.f16 hr5.z, hr23.x, hr20.x, (last)hr5.z
mad.f16 hr9.w, hr23.y, hr19.z, (last)hr9.w
mad.f16 hr7.w, hr23.y, hr19.w, (last)hr7.w
mad.f16 hr5.w, hr23.y, hr20.x, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr23.z, hr19.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr23.z, hr19.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr23.z, hr20.x, (r)(last)hr6.x
(rpt1)mad.f16 hr22.x, (r)(last)hr21.x, hr20.y, (r)(last)hr0.z
(rpt1)mad.f16 hr22.z, (r)(last)hr21.z, hr20.y, (r)(last)hr1.x
(rpt1)mad.f16 hr3.z, (r)(last)hr23.x, hr20.y, (r)(last)hr3.z
(rpt1)mad.f16 hr4.x, (r)(last)hr23.z, hr20.y, (r)(last)hr4.x
bar.g
(sy)(ss)br p0.x, #l1093
mov.u16u16 hr5.y, hr22.w
mov.u16u16 hr5.x, hr22.z
mov.u16u16 hr4.w, hr22.y
mov.u16u16 hr4.z, hr22.x
jump #l118
l1093:
(jp)(eolm)nop
(nop3) add.u r13.z, r49.x, (last)r13.z
(nop3) shl.b r13.z, (last)r13.z, 9
(nop3) sad.s32 r13.z, r50.x, r13.z, (last)r1.y
(nop3) shl.b r13.z, (last)r13.z, 2
add.u r12.x, r13.z, c1.x
add.u r12.y, r13.z, c5.z
add.u r12.z, r13.z, c1.y
stib.b.untyped.1d.u16.4.imm.base0 hr18.z, r13.z, 4
add.u r12.w, r13.z, c5.w
add.u r13.w, r13.z, c3.y
(rpt1)add.u r14.x, r13.z, (r)c6.x
(rpt1)add.u r14.z, (r)c6.z, r13.z
(rpt1)add.u r15.x, (r)c7.x, r13.z
(rpt1)add.u r15.z, (r)c7.z, r13.z
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r13.z+64, 4
(ss)add.u r13.z, c8.x, (last)r13.z
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r12.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r12.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r12.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r12.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r13.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r14.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r14.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r14.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r14.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r15.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r15.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r15.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr22.x, r15.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r13.z, 4
end
nop
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1283 instr, 24 nops, 1259 non-nops, 69 mov, 0 cov, 2272 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 18 full, 12 constlen
; CL prog 23/1: 27 cat0, 69 cat1, 64 cat2, 1031 cat3, 0 cat4, 4 cat5, 84 cat6, 4 cat7
; CL prog 23/1: 40 sstall, 16 (ss), 63 systall, 6 (sy), 1 loops
; CL prog 23/1: 14 max_waves, 0 double_threadsize
; 46 preamble-instr, 1 early-preamble
