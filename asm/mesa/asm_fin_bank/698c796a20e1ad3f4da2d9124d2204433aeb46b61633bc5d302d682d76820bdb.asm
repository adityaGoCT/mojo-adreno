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
@const(c4.x)	0x00002000, 0x00001800, 0x00001000, 0x00007820
@const(c5.x)	0x00007020, 0x00006820, 0x00006020, 0x00005820
@const(c6.x)	0x00005020, 0x00004820, 0x00004020, 0x00003820
@const(c7.x)	0x00003020, 0x00002820, 0x00002020, 0x00001820
@const(c8.x)	0x00001020, 0x00000820, 0x00010000, 0x00010020
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
mov.u32u32 r52.z, 0x7820
mov.u32u32 r52.w, 0x7020
mov.u32u32 r53.x, 0x6820
mov.u32u32 r53.y, 0x6020
mov.u32u32 r53.z, 0x5820
mov.u32u32 r53.w, 0x5020
mov.u32u32 r54.x, 0x4820
mov.u32u32 r54.y, 0x4020
mov.u32u32 r54.z, 0x3820
mov.u32u32 r54.w, 0x3020
mov.u32u32 r55.x, 0x2820
mov.u32u32 r55.y, 0x2020
mov.u32u32 r55.z, 0x1820
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
(ss)mov.u32u32 r48.w, 0x1020
mov.u32u32 r49.x, 2080
mov.u32u32 r49.y, 0x10000
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
shr.b r1.y, r0.x, 3
and.b r1.z, r0.x, -8
and.b r1.w, r0.x, 7
mov.u16u16 hr4.x, 0
mov.u16u16 hr4.y, 0
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
l131:
(rpt1)shr.b r52.z, (r)r51.w, 2
shl.b r53.x, r52.y, 9
add.u r10.z, r0.x, 64
add.u r10.w, r0.x, 128
add.u r11.x, r0.x, 192
shl.b r10.x, r0.w, 7
(rpt2)shr.b r10.z, (last)(r)r10.z, 4
(ss)add.u r11.y, r52.y, r0.w
(rpt2)add.u r11.z, r52.y, (r)r10.z
add.u r52.y, r52.y, 16
cmps.u.ge up0.x, r52.y, c1.x
shl.b r11.y, (last)r11.y, 9
(rpt2)shl.b r11.z, (last)(r)r11.z, 9
sad.s32 r11.y, r52.z, r11.y, r1.x
(rpt2)sad.s32 r11.z, r52.z, (r)r11.z, r1.x
shl.b r11.y, (last)r11.y, 2
(rpt1)shl.b r11.z, (last)(r)r11.z, 2
shl.b r12.x, (last)r12.x, 2
shl.b r10.y, r1.x, 3
sad.s32 r14.x, r53.x, r1.w, r52.w
shl.b r10.z, (last)r10.z, 7
isam.v.base0 (u16)(xyzw)hr24.z, r11.y, s#0, t#0
shl.b r10.w, (last)r10.w, 7
isam.v.base0 (u16)(xyzw)hr26.x, r11.z, s#0, t#0
shl.b r11.x, (last)r11.x, 7
isam.v.base0 (u16)(xyzw)hr27.x, r11.w, s#0, t#0
add.u r10.x, (last)r10.x, r10.y
isam.v.base0 (u16)(xyzw)hr28.z, r12.x, s#0, t#0
shl.b r14.x, (last)r14.x, 2
(rpt2)add.u r10.z, (last)(r)r10.z, (last)r10.y
add.u r14.w, r14.x, c1.x
add.u r15.x, r14.x, c8.y
add.u r15.y, r14.x, c4.z
add.u r15.z, r14.x, c8.x
add.u r15.w, r14.x, c4.y
add.u r16.x, r14.x, c7.w
add.u r16.y, r14.x, c4.x
add.u r16.z, r14.x, c7.z
add.u r16.w, r14.x, c3.w
add.u r17.x, r14.x, c7.y
add.u r17.y, r14.x, c3.z
add.u r17.z, r14.x, c7.x
add.u r17.w, r14.x, c3.y
add.u r18.x, r14.x, c6.w
add.u r18.y, r14.x, c3.x
add.u r18.z, r14.x, c6.z
add.u r18.w, r14.x, c2.w
add.u r19.x, r14.x, c6.y
add.u r19.y, r14.x, c2.z
add.u r19.z, r14.x, c6.x
add.u r19.w, r14.x, c2.y
add.u r20.x, r14.x, c5.w
add.u r20.y, r14.x, c2.x
add.u r20.z, r14.x, c5.z
(ss)add.u r11.y, r14.x, c1.y
add.u r11.z, r14.x, c4.w
add.u r10.y, r14.x, c5.y
shl.b r12.w, r1.y, 2
(sy)stl.u16 l[r10.x], r24.z, 4
(ss)add.u r10.x, r14.x, c1.w
stl.u16 l[r10.z], r26.x, 4
(ss)add.u r10.z, r14.x, c1.z
stl.u16 l[r10.w], r27.x, 4
(ss)add.u r10.w, r14.x, c5.x
stl.u16 l[r11.x], r28.z, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
isam.v.base0 (u16)(xyzw)hr26.y, r14.x, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr27.y, r14.x+32, s#0, t#2
ldl.u16 r23.z, l[r1.z], 4
ldl.u16 r28.z, l[r1.z+64], 4
ldl.u16 r0.z, l[r1.z+128], 4
(sy)(ss)mad.f16 hr17.x, hr26.y, hr23.w, (last)hr17.x
mad.f16 hr15.x, hr26.y, hr24.x, (last)hr15.x
mad.f16 hr13.x, hr26.y, hr24.y, (last)hr13.x
mad.f16 hr17.y, hr26.z, hr23.w, (last)hr17.y
mad.f16 hr15.y, hr26.z, hr24.x, (last)hr15.y
mad.f16 hr13.y, hr26.z, hr24.y, (last)hr13.y
mad.f16 hr17.z, hr26.w, hr23.w, (last)hr17.z
mad.f16 hr15.z, hr26.w, hr24.x, (last)hr15.z
mad.f16 hr13.z, hr26.w, hr24.y, (last)hr13.z
mad.f16 hr17.w, hr27.x, hr23.w, (last)hr17.w
mad.f16 hr15.w, hr27.x, hr24.x, (last)hr15.w
mad.f16 hr13.w, hr27.x, hr24.y, (last)hr13.w
mad.f16 hr16.x, hr27.y, hr23.w, (last)hr16.x
mad.f16 hr14.x, hr27.y, hr24.x, (last)hr14.x
mad.f16 hr12.x, hr27.y, hr24.y, (last)hr12.x
mad.f16 hr16.y, hr27.z, hr23.w, (last)hr16.y
mad.f16 hr14.y, hr27.z, hr24.x, (last)hr14.y
mad.f16 hr12.y, hr27.z, hr24.y, (last)hr12.y
(rpt1)mad.f16 hr16.z, (r)hr27.w, hr23.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr27.w, hr24.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr27.w, hr24.y, (r)(last)hr12.z
isam.v.base0 (u16)(xyzw)hr23.w, r14.w, s#0, t#2
(rpt1)mad.f16 hr18.x, (r)hr27.y, hr23.z, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr27.w, hr23.z, (r)(last)hr18.z
mad.f16 hr10.x, hr27.y, hr28.z, (last)hr10.x
mad.f16 hr8.x, hr27.y, hr28.w, (last)hr8.x
mad.f16 hr6.x, hr27.y, hr29.x, (last)hr6.x
mad.f16 hr10.y, hr27.z, hr28.z, (last)hr10.y
mad.f16 hr8.y, hr27.z, hr28.w, (last)hr8.y
mad.f16 hr6.y, hr27.z, hr29.x, (last)hr6.y
(rpt1)mad.f16 hr10.z, (r)hr27.w, hr28.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr27.w, hr28.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr27.w, hr29.x, (r)(last)hr6.z
(rpt1)mad.f16 hr27.y, (r)(last)hr27.y, hr29.y, (r)(last)hr4.x
(rpt1)mad.f16 hr27.w, (r)(last)hr27.w, hr29.y, (r)(last)hr4.z
ldl.u16 r4.x, l[r1.z+192], 4
(rpt1)mad.f16 hr19.x, (r)hr26.y, hr23.z, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr26.w, hr23.z, (r)(last)hr19.z
(rpt1)mad.f16 hr11.x, (r)hr26.y, hr28.z, (r)(last)hr11.x
(rpt1)mad.f16 hr11.z, (r)hr26.w, hr28.z, (r)(last)hr11.z
(rpt1)mad.f16 hr9.x, (r)hr26.y, hr28.w, (r)(last)hr9.x
(rpt1)mad.f16 hr9.z, (r)hr26.w, hr28.w, (r)(last)hr9.z
(rpt1)mad.f16 hr7.x, (r)hr26.y, hr29.x, (r)(last)hr7.x
(rpt1)mad.f16 hr7.z, (r)hr26.w, hr29.x, (r)(last)hr7.z
ldl.u16 r28.y, l[r1.z+256], 4
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr29.y, (r)(last)hr5.x
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr29.y, (r)(last)hr5.z
(sy)mad.f16 hr17.x, hr23.w, hr0.w, (last)hr17.x
mad.f16 hr15.x, hr23.w, hr1.x, (last)hr15.x
mad.f16 hr13.x, hr23.w, hr1.y, (last)hr13.x
mad.f16 hr17.y, hr24.x, hr0.w, (last)hr17.y
mad.f16 hr15.y, hr24.x, hr1.x, (last)hr15.y
mad.f16 hr13.y, hr24.x, hr1.y, (last)hr13.y
mad.f16 hr17.z, hr24.y, hr0.w, (last)hr17.z
mad.f16 hr15.z, hr24.y, hr1.x, (last)hr15.z
mad.f16 hr13.z, hr24.y, hr1.y, (last)hr13.z
mad.f16 hr17.w, hr24.z, hr0.w, (last)hr17.w
mad.f16 hr15.w, hr24.z, hr1.x, (last)hr15.w
mad.f16 hr13.w, hr24.z, hr1.y, (last)hr13.w
(rpt1)mad.f16 hr19.x, (r)hr23.w, hr0.z, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr24.y, hr0.z, (r)(last)hr19.z
(ss)(rpt1)mad.f16 hr11.x, (r)hr23.w, hr4.x, (r)(last)hr11.x
(rpt1)mad.f16 hr11.z, (r)hr24.y, hr4.x, (r)(last)hr11.z
(rpt1)mad.f16 hr9.x, (r)hr23.w, hr4.y, (r)(last)hr9.x
(rpt1)mad.f16 hr9.z, (r)hr24.y, hr4.y, (r)(last)hr9.z
(rpt1)mad.f16 hr7.x, (r)hr23.w, hr4.z, (r)(last)hr7.x
(rpt1)mad.f16 hr7.z, (r)hr24.y, hr4.z, (r)(last)hr7.z
(rpt1)mad.f16 hr23.w, (r)(last)hr23.w, hr4.w, (r)(last)hr26.y
(rpt1)mad.f16 hr24.y, (r)(last)hr24.y, hr4.w, (r)(last)hr26.w
isam.v.base0 (u16)(xyzw)hr26.y, r15.x, s#0, t#2
(ss)nop
ldl.u16 r29.y, l[r1.z+320], 4
(sy)mad.f16 hr18.x, hr26.y, hr0.z, (last)hr18.x
mad.f16 hr16.x, hr26.y, hr0.w, (last)hr16.x
mad.f16 hr14.x, hr26.y, hr1.x, (last)hr14.x
mad.f16 hr12.x, hr26.y, hr1.y, (last)hr12.x
mad.f16 hr10.x, hr26.y, hr4.x, (last)hr10.x
mad.f16 hr8.x, hr26.y, hr4.y, (last)hr8.x
mad.f16 hr6.x, hr26.y, hr4.z, (last)hr6.x
mad.f16 hr18.y, hr26.z, hr0.z, (last)hr18.y
mad.f16 hr16.y, hr26.z, hr0.w, (last)hr16.y
mad.f16 hr14.y, hr26.z, hr1.x, (last)hr14.y
mad.f16 hr12.y, hr26.z, hr1.y, (last)hr12.y
mad.f16 hr10.y, hr26.z, hr4.x, (last)hr10.y
mad.f16 hr8.y, hr26.z, hr4.y, (last)hr8.y
mad.f16 hr6.y, hr26.z, hr4.z, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr26.w, hr0.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr26.w, hr0.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr26.w, hr1.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr26.w, hr1.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr26.w, hr4.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr26.w, hr4.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr26.w, hr4.z, (r)(last)hr6.z
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr4.w, (r)(last)hr27.y
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr4.w, (r)(last)hr27.w
isam.v.base0 (u16)(xyzw)hr4.y, r15.y, s#0, t#2
ldl.u16 r27.y, l[r1.z+384], 4
(sy)mad.f16 hr19.x, hr4.y, hr28.y, (last)hr19.x
mad.f16 hr17.x, hr4.y, hr28.z, (last)hr17.x
mad.f16 hr15.x, hr4.y, hr28.w, (last)hr15.x
mad.f16 hr13.x, hr4.y, hr29.x, (last)hr13.x
mad.f16 hr19.y, hr4.z, hr28.y, (last)hr19.y
mad.f16 hr17.y, hr4.z, hr28.z, (last)hr17.y
mad.f16 hr15.y, hr4.z, hr28.w, (last)hr15.y
mad.f16 hr13.y, hr4.z, hr29.x, (last)hr13.y
mad.f16 hr19.z, hr4.w, hr28.y, (last)hr19.z
mad.f16 hr17.z, hr4.w, hr28.z, (last)hr17.z
(ss)mad.f16 hr11.x, hr4.y, hr29.y, (last)hr11.x
mad.f16 hr9.x, hr4.y, hr29.z, (last)hr9.x
mad.f16 hr7.x, hr4.y, hr29.w, (last)hr7.x
mad.f16 hr11.y, hr4.z, hr29.y, (last)hr11.y
mad.f16 hr9.y, hr4.z, hr29.z, (last)hr9.y
mad.f16 hr7.y, hr4.z, hr29.w, (last)hr7.y
mad.f16 hr15.z, hr4.w, hr28.w, (last)hr15.z
mad.f16 hr13.z, hr4.w, hr29.x, (last)hr13.z
mad.f16 hr11.z, hr4.w, hr29.y, (last)hr11.z
mad.f16 hr9.z, hr4.w, hr29.z, (last)hr9.z
mad.f16 hr7.z, hr4.w, hr29.w, (last)hr7.z
mad.f16 hr19.w, hr5.x, hr28.y, (last)hr19.w
mad.f16 hr17.w, hr5.x, hr28.z, (last)hr17.w
mad.f16 hr15.w, hr5.x, hr28.w, (last)hr15.w
mad.f16 hr13.w, hr5.x, hr29.x, (last)hr13.w
mad.f16 hr11.w, hr5.x, hr29.y, (last)hr11.w
mad.f16 hr9.w, hr5.x, hr29.z, (last)hr9.w
mad.f16 hr7.w, hr5.x, hr29.w, (last)hr7.w
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr30.x, (r)(last)hr23.w
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr30.x, (r)(last)hr24.y
isam.v.base0 (u16)(xyzw)hr23.w, r15.z, s#0, t#2
(sy)mad.f16 hr18.x, hr23.w, hr28.y, (last)hr18.x
mad.f16 hr16.x, hr23.w, hr28.z, (last)hr16.x
mad.f16 hr14.x, hr23.w, hr28.w, (last)hr14.x
mad.f16 hr12.x, hr23.w, hr29.x, (last)hr12.x
mad.f16 hr10.x, hr23.w, hr29.y, (last)hr10.x
mad.f16 hr8.x, hr23.w, hr29.z, (last)hr8.x
mad.f16 hr6.x, hr23.w, hr29.w, (last)hr6.x
mad.f16 hr18.y, hr24.x, hr28.y, (last)hr18.y
mad.f16 hr16.y, hr24.x, hr28.z, (last)hr16.y
mad.f16 hr14.y, hr24.x, hr28.w, (last)hr14.y
mad.f16 hr12.y, hr24.x, hr29.x, (last)hr12.y
mad.f16 hr10.y, hr24.x, hr29.y, (last)hr10.y
mad.f16 hr8.y, hr24.x, hr29.z, (last)hr8.y
mad.f16 hr6.y, hr24.x, hr29.w, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr24.y, hr28.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr24.y, hr28.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr24.y, hr28.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr24.y, hr29.x, (r)(last)hr12.z
ldl.u16 r28.y, l[r1.z+448], 4
(rpt1)mad.f16 hr10.z, (r)hr24.y, hr29.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr24.y, hr29.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr24.y, hr29.w, (r)(last)hr6.z
(rpt1)mad.f16 hr23.w, (r)(last)hr23.w, hr30.x, (r)(last)hr26.y
(rpt1)mad.f16 hr24.y, (r)(last)hr24.y, hr30.x, (r)(last)hr26.w
isam.v.base0 (u16)(xyzw)hr29.y, r15.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr30.y, r16.x, s#0, t#2
(ss)nop
ldl.u16 r31.y, l[r1.z+512], 4
ldl.u16 r0.z, l[r1.z+576], 4
ldl.u16 r26.x, l[r1.z+640], 4
(sy)mad.f16 hr19.x, hr29.y, hr27.y, (last)hr19.x
mad.f16 hr17.x, hr29.y, hr27.z, (last)hr17.x
mad.f16 hr15.x, hr29.y, hr27.w, (last)hr15.x
mad.f16 hr13.x, hr29.y, hr28.x, (last)hr13.x
mad.f16 hr11.x, hr29.y, hr28.y, (last)hr11.x
mad.f16 hr9.x, hr29.y, hr28.z, (last)hr9.x
mad.f16 hr7.x, hr29.y, hr28.w, (last)hr7.x
mad.f16 hr19.y, hr29.z, hr27.y, (last)hr19.y
mad.f16 hr17.y, hr29.z, hr27.z, (last)hr17.y
mad.f16 hr15.y, hr29.z, hr27.w, (last)hr15.y
mad.f16 hr13.y, hr29.z, hr28.x, (last)hr13.y
mad.f16 hr11.y, hr29.z, hr28.y, (last)hr11.y
mad.f16 hr9.y, hr29.z, hr28.z, (last)hr9.y
mad.f16 hr7.y, hr29.z, hr28.w, (last)hr7.y
mad.f16 hr19.z, hr29.w, hr27.y, (last)hr19.z
mad.f16 hr17.z, hr29.w, hr27.z, (last)hr17.z
mad.f16 hr15.z, hr29.w, hr27.w, (last)hr15.z
mad.f16 hr13.z, hr29.w, hr28.x, (last)hr13.z
mad.f16 hr11.z, hr29.w, hr28.y, (last)hr11.z
mad.f16 hr9.z, hr29.w, hr28.z, (last)hr9.z
mad.f16 hr7.z, hr29.w, hr28.w, (last)hr7.z
mad.f16 hr19.w, hr30.x, hr27.y, (last)hr19.w
mad.f16 hr17.w, hr30.x, hr27.z, (last)hr17.w
mad.f16 hr15.w, hr30.x, hr27.w, (last)hr15.w
mad.f16 hr13.w, hr30.x, hr28.x, (last)hr13.w
mad.f16 hr11.w, hr30.x, hr28.y, (last)hr11.w
mad.f16 hr9.w, hr30.x, hr28.z, (last)hr9.w
mad.f16 hr7.w, hr30.x, hr28.w, (last)hr7.w
(rpt1)mad.f16 hr29.y, (r)(last)hr29.y, hr29.x, (r)(last)hr4.y
(rpt1)mad.f16 hr29.w, (r)(last)hr29.w, hr29.x, (r)(last)hr4.w
isam.v.base0 (u16)(xyzw)hr4.y, r16.y, s#0, t#2
mad.f16 hr18.x, hr30.y, hr27.y, (last)hr18.x
mad.f16 hr16.x, hr30.y, hr27.z, (last)hr16.x
mad.f16 hr14.x, hr30.y, hr27.w, (last)hr14.x
mad.f16 hr12.x, hr30.y, hr28.x, (last)hr12.x
mad.f16 hr10.x, hr30.y, hr28.y, (last)hr10.x
mad.f16 hr8.x, hr30.y, hr28.z, (last)hr8.x
mad.f16 hr6.x, hr30.y, hr28.w, (last)hr6.x
mad.f16 hr18.y, hr30.z, hr27.y, (last)hr18.y
mad.f16 hr16.y, hr30.z, hr27.z, (last)hr16.y
mad.f16 hr14.y, hr30.z, hr27.w, (last)hr14.y
mad.f16 hr12.y, hr30.z, hr28.x, (last)hr12.y
mad.f16 hr10.y, hr30.z, hr28.y, (last)hr10.y
mad.f16 hr8.y, hr30.z, hr28.z, (last)hr8.y
mad.f16 hr6.y, hr30.z, hr28.w, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr30.w, hr27.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr30.w, hr27.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr30.w, hr27.w, (r)(last)hr14.z
ldl.u16 r27.x, l[r1.z+704], 4
(rpt1)mad.f16 hr12.z, (r)hr30.w, hr28.x, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr30.w, hr28.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr30.w, hr28.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr30.w, hr28.w, (r)(last)hr6.z
(rpt1)mad.f16 hr30.y, (r)(last)hr30.y, hr29.x, (r)(last)hr23.w
(rpt1)mad.f16 hr30.w, (r)(last)hr30.w, hr29.x, (r)(last)hr24.y
isam.v.base0 (u16)(xyzw)hr23.w, r16.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr28.y, r16.w, s#0, t#2
(sy)(ss)mad.f16 hr19.x, hr4.y, hr31.y, (last)hr19.x
mad.f16 hr17.x, hr4.y, hr31.z, (last)hr17.x
mad.f16 hr15.x, hr4.y, hr31.w, (last)hr15.x
mad.f16 hr13.x, hr4.y, hr32.x, (last)hr13.x
mad.f16 hr11.x, hr4.y, hr0.z, (last)hr11.x
mad.f16 hr9.x, hr4.y, hr0.w, (last)hr9.x
mad.f16 hr7.x, hr4.y, hr1.x, (last)hr7.x
mad.f16 hr19.y, hr4.z, hr31.y, (last)hr19.y
mad.f16 hr17.y, hr4.z, hr31.z, (last)hr17.y
mad.f16 hr15.y, hr4.z, hr31.w, (last)hr15.y
mad.f16 hr13.y, hr4.z, hr32.x, (last)hr13.y
mad.f16 hr11.y, hr4.z, hr0.z, (last)hr11.y
mad.f16 hr9.y, hr4.z, hr0.w, (last)hr9.y
mad.f16 hr7.y, hr4.z, hr1.x, (last)hr7.y
mad.f16 hr19.z, hr4.w, hr31.y, (last)hr19.z
mad.f16 hr17.z, hr4.w, hr31.z, (last)hr17.z
mad.f16 hr15.z, hr4.w, hr31.w, (last)hr15.z
mad.f16 hr13.z, hr4.w, hr32.x, (last)hr13.z
mad.f16 hr11.z, hr4.w, hr0.z, (last)hr11.z
mad.f16 hr9.z, hr4.w, hr0.w, (last)hr9.z
mad.f16 hr7.z, hr4.w, hr1.x, (last)hr7.z
mad.f16 hr19.w, hr5.x, hr31.y, (last)hr19.w
mad.f16 hr17.w, hr5.x, hr31.z, (last)hr17.w
mad.f16 hr15.w, hr5.x, hr31.w, (last)hr15.w
mad.f16 hr13.w, hr5.x, hr32.x, (last)hr13.w
mad.f16 hr11.w, hr5.x, hr0.z, (last)hr11.w
mad.f16 hr9.w, hr5.x, hr0.w, (last)hr9.w
mad.f16 hr7.w, hr5.x, hr1.x, (last)hr7.w
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr1.y, (r)(last)hr29.y
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr1.y, (r)(last)hr29.w
isam.v.base0 (u16)(xyzw)hr29.y, r17.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr32.y, r17.y, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr33.y, r17.z, s#0, t#2
mad.f16 hr18.x, hr23.w, hr31.y, (last)hr18.x
mad.f16 hr16.x, hr23.w, hr31.z, (last)hr16.x
mad.f16 hr14.x, hr23.w, hr31.w, (last)hr14.x
mad.f16 hr12.x, hr23.w, hr32.x, (last)hr12.x
mad.f16 hr10.x, hr23.w, hr0.z, (last)hr10.x
mad.f16 hr8.x, hr23.w, hr0.w, (last)hr8.x
mad.f16 hr6.x, hr23.w, hr1.x, (last)hr6.x
mad.f16 hr18.y, hr24.x, hr31.y, (last)hr18.y
mad.f16 hr16.y, hr24.x, hr31.z, (last)hr16.y
mad.f16 hr14.y, hr24.x, hr31.w, (last)hr14.y
mad.f16 hr12.y, hr24.x, hr32.x, (last)hr12.y
mad.f16 hr10.y, hr24.x, hr0.z, (last)hr10.y
mad.f16 hr8.y, hr24.x, hr0.w, (last)hr8.y
mad.f16 hr6.y, hr24.x, hr1.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr24.y, hr31.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr24.y, hr31.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr24.y, hr31.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr24.y, hr32.x, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr24.y, hr0.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr24.y, hr0.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr24.y, hr1.x, (r)(last)hr6.z
(rpt1)mad.f16 hr23.w, (r)(last)hr23.w, hr1.y, (r)(last)hr30.y
(rpt1)mad.f16 hr24.y, (r)(last)hr24.y, hr1.y, (r)(last)hr30.w
ldl.u16 r30.y, l[r1.z+768], 4
ldl.u16 r31.y, l[r1.z+832], 4
mad.f16 hr19.x, hr28.y, hr26.x, (last)hr19.x
mad.f16 hr17.x, hr28.y, hr26.y, (last)hr17.x
mad.f16 hr15.x, hr28.y, hr26.z, (last)hr15.x
mad.f16 hr13.x, hr28.y, hr26.w, (last)hr13.x
mad.f16 hr11.x, hr28.y, hr27.x, (last)hr11.x
mad.f16 hr9.x, hr28.y, hr27.y, (last)hr9.x
mad.f16 hr7.x, hr28.y, hr27.z, (last)hr7.x
mad.f16 hr19.y, hr28.z, hr26.x, (last)hr19.y
mad.f16 hr17.y, hr28.z, hr26.y, (last)hr17.y
mad.f16 hr15.y, hr28.z, hr26.z, (last)hr15.y
(ss)nop
ldl.u16 r34.y, l[r1.z+896], 4
ldl.u16 r0.z, l[r1.z+960], 4
mad.f16 hr13.y, hr28.z, hr26.w, (last)hr13.y
mad.f16 hr11.y, hr28.z, hr27.x, (last)hr11.y
mad.f16 hr9.y, hr28.z, hr27.y, (last)hr9.y
mad.f16 hr7.y, hr28.z, hr27.z, (last)hr7.y
mad.f16 hr19.z, hr28.w, hr26.x, (last)hr19.z
mad.f16 hr17.z, hr28.w, hr26.y, (last)hr17.z
mad.f16 hr15.z, hr28.w, hr26.z, (last)hr15.z
mad.f16 hr13.z, hr28.w, hr26.w, (last)hr13.z
mad.f16 hr11.z, hr28.w, hr27.x, (last)hr11.z
mad.f16 hr9.z, hr28.w, hr27.y, (last)hr9.z
mad.f16 hr7.z, hr28.w, hr27.z, (last)hr7.z
mad.f16 hr19.w, hr29.x, hr26.x, (last)hr19.w
mad.f16 hr17.w, hr29.x, hr26.y, (last)hr17.w
mad.f16 hr15.w, hr29.x, hr26.z, (last)hr15.w
mad.f16 hr13.w, hr29.x, hr26.w, (last)hr13.w
mad.f16 hr11.w, hr29.x, hr27.x, (last)hr11.w
mad.f16 hr9.w, hr29.x, hr27.y, (last)hr9.w
mad.f16 hr7.w, hr29.x, hr27.z, (last)hr7.w
(sy)mad.f16 hr18.x, hr29.y, hr26.x, (last)hr18.x
mad.f16 hr16.x, hr29.y, hr26.y, (last)hr16.x
mad.f16 hr14.x, hr29.y, hr26.z, (last)hr14.x
mad.f16 hr12.x, hr29.y, hr26.w, (last)hr12.x
mad.f16 hr10.x, hr29.y, hr27.x, (last)hr10.x
mad.f16 hr8.x, hr29.y, hr27.y, (last)hr8.x
mad.f16 hr6.x, hr29.y, hr27.z, (last)hr6.x
mad.f16 hr18.y, hr29.z, hr26.x, (last)hr18.y
mad.f16 hr16.y, hr29.z, hr26.y, (last)hr16.y
mad.f16 hr14.y, hr29.z, hr26.z, (last)hr14.y
mad.f16 hr12.y, hr29.z, hr26.w, (last)hr12.y
mad.f16 hr10.y, hr29.z, hr27.x, (last)hr10.y
mad.f16 hr8.y, hr29.z, hr27.y, (last)hr8.y
mad.f16 hr6.y, hr29.z, hr27.z, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr29.w, hr26.x, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr29.w, hr26.y, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr29.w, hr26.z, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr29.w, hr26.w, (r)(last)hr12.z
ldl.u16 r26.x, l[r1.z+1024], 4
(rpt1)mad.f16 hr10.z, (r)hr29.w, hr27.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr29.w, hr27.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr29.w, hr27.z, (r)(last)hr6.z
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr27.w, (r)(last)hr4.y
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr27.w, (r)(last)hr4.w
isam.v.base0 (u16)(xyzw)hr4.y, r17.w, s#0, t#2
(rpt1)mad.f16 hr29.y, (r)(last)hr29.y, hr27.w, (r)(last)hr23.w
(rpt1)mad.f16 hr29.w, (r)(last)hr29.w, hr27.w, (r)(last)hr24.y
isam.v.base0 (u16)(xyzw)hr23.w, r18.x, s#0, t#2
ldl.u16 r27.x, l[r1.z+1088], 4
mad.f16 hr19.x, hr32.y, hr30.y, (last)hr19.x
mad.f16 hr17.x, hr32.y, hr30.z, (last)hr17.x
mad.f16 hr15.x, hr32.y, hr30.w, (last)hr15.x
mad.f16 hr13.x, hr32.y, hr31.x, (last)hr13.x
mad.f16 hr11.x, hr32.y, hr31.y, (last)hr11.x
mad.f16 hr9.x, hr32.y, hr31.z, (last)hr9.x
mad.f16 hr7.x, hr32.y, hr31.w, (last)hr7.x
mad.f16 hr19.y, hr32.z, hr30.y, (last)hr19.y
mad.f16 hr17.y, hr32.z, hr30.z, (last)hr17.y
mad.f16 hr15.y, hr32.z, hr30.w, (last)hr15.y
mad.f16 hr13.y, hr32.z, hr31.x, (last)hr13.y
mad.f16 hr11.y, hr32.z, hr31.y, (last)hr11.y
mad.f16 hr9.y, hr32.z, hr31.z, (last)hr9.y
mad.f16 hr7.y, hr32.z, hr31.w, (last)hr7.y
mad.f16 hr19.z, hr32.w, hr30.y, (last)hr19.z
mad.f16 hr17.z, hr32.w, hr30.z, (last)hr17.z
mad.f16 hr15.z, hr32.w, hr30.w, (last)hr15.z
mad.f16 hr13.z, hr32.w, hr31.x, (last)hr13.z
mad.f16 hr11.z, hr32.w, hr31.y, (last)hr11.z
mad.f16 hr9.z, hr32.w, hr31.z, (last)hr9.z
mad.f16 hr7.z, hr32.w, hr31.w, (last)hr7.z
mad.f16 hr19.w, hr33.x, hr30.y, (last)hr19.w
mad.f16 hr17.w, hr33.x, hr30.z, (last)hr17.w
mad.f16 hr15.w, hr33.x, hr30.w, (last)hr15.w
mad.f16 hr13.w, hr33.x, hr31.x, (last)hr13.w
mad.f16 hr11.w, hr33.x, hr31.y, (last)hr11.w
mad.f16 hr9.w, hr33.x, hr31.z, (last)hr9.w
mad.f16 hr7.w, hr33.x, hr31.w, (last)hr7.w
mad.f16 hr18.x, hr33.y, hr30.y, (last)hr18.x
mad.f16 hr16.x, hr33.y, hr30.z, (last)hr16.x
mad.f16 hr14.x, hr33.y, hr30.w, (last)hr14.x
mad.f16 hr12.x, hr33.y, hr31.x, (last)hr12.x
mad.f16 hr10.x, hr33.y, hr31.y, (last)hr10.x
mad.f16 hr8.x, hr33.y, hr31.z, (last)hr8.x
mad.f16 hr6.x, hr33.y, hr31.w, (last)hr6.x
mad.f16 hr18.y, hr33.z, hr30.y, (last)hr18.y
mad.f16 hr16.y, hr33.z, hr30.z, (last)hr16.y
mad.f16 hr14.y, hr33.z, hr30.w, (last)hr14.y
mad.f16 hr12.y, hr33.z, hr31.x, (last)hr12.y
mad.f16 hr10.y, hr33.z, hr31.y, (last)hr10.y
mad.f16 hr8.y, hr33.z, hr31.z, (last)hr8.y
mad.f16 hr6.y, hr33.z, hr31.w, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr33.w, hr30.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr33.w, hr30.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr33.w, hr30.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr33.w, hr31.x, (r)(last)hr12.z
ldl.u16 r30.y, l[r1.z+1152], 4
(rpt1)mad.f16 hr10.z, (r)hr33.w, hr31.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr33.w, hr31.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr33.w, hr31.w, (r)(last)hr6.z
(rpt1)mad.f16 hr32.y, (r)(last)hr32.y, hr32.x, (r)(last)hr28.y
(rpt1)mad.f16 hr32.w, (r)(last)hr32.w, hr32.x, (r)(last)hr28.w
isam.v.base0 (u16)(xyzw)hr28.y, r18.y, s#0, t#2
(rpt1)mad.f16 hr33.y, (r)(last)hr33.y, hr32.x, (r)(last)hr29.y
(rpt1)mad.f16 hr33.w, (r)(last)hr33.w, hr32.x, (r)(last)hr29.w
isam.v.base0 (u16)(xyzw)hr29.y, r18.z, s#0, t#2
ldl.u16 r31.y, l[r1.z+1216], 4
(sy)(ss)mad.f16 hr19.x, hr4.y, hr34.y, (last)hr19.x
mad.f16 hr17.x, hr4.y, hr34.z, (last)hr17.x
mad.f16 hr15.x, hr4.y, hr34.w, (last)hr15.x
mad.f16 hr13.x, hr4.y, hr35.x, (last)hr13.x
mad.f16 hr11.x, hr4.y, hr0.z, (last)hr11.x
mad.f16 hr9.x, hr4.y, hr0.w, (last)hr9.x
mad.f16 hr7.x, hr4.y, hr1.x, (last)hr7.x
mad.f16 hr19.y, hr4.z, hr34.y, (last)hr19.y
mad.f16 hr17.y, hr4.z, hr34.z, (last)hr17.y
mad.f16 hr15.y, hr4.z, hr34.w, (last)hr15.y
mad.f16 hr13.y, hr4.z, hr35.x, (last)hr13.y
mad.f16 hr11.y, hr4.z, hr0.z, (last)hr11.y
mad.f16 hr9.y, hr4.z, hr0.w, (last)hr9.y
mad.f16 hr7.y, hr4.z, hr1.x, (last)hr7.y
mad.f16 hr19.z, hr4.w, hr34.y, (last)hr19.z
mad.f16 hr17.z, hr4.w, hr34.z, (last)hr17.z
mad.f16 hr15.z, hr4.w, hr34.w, (last)hr15.z
mad.f16 hr13.z, hr4.w, hr35.x, (last)hr13.z
mad.f16 hr11.z, hr4.w, hr0.z, (last)hr11.z
mad.f16 hr9.z, hr4.w, hr0.w, (last)hr9.z
mad.f16 hr7.z, hr4.w, hr1.x, (last)hr7.z
mad.f16 hr19.w, hr5.x, hr34.y, (last)hr19.w
mad.f16 hr17.w, hr5.x, hr34.z, (last)hr17.w
mad.f16 hr15.w, hr5.x, hr34.w, (last)hr15.w
mad.f16 hr13.w, hr5.x, hr35.x, (last)hr13.w
mad.f16 hr11.w, hr5.x, hr0.z, (last)hr11.w
mad.f16 hr9.w, hr5.x, hr0.w, (last)hr9.w
mad.f16 hr7.w, hr5.x, hr1.x, (last)hr7.w
mad.f16 hr18.x, hr23.w, hr34.y, (last)hr18.x
mad.f16 hr16.x, hr23.w, hr34.z, (last)hr16.x
mad.f16 hr14.x, hr23.w, hr34.w, (last)hr14.x
mad.f16 hr12.x, hr23.w, hr35.x, (last)hr12.x
mad.f16 hr10.x, hr23.w, hr0.z, (last)hr10.x
mad.f16 hr8.x, hr23.w, hr0.w, (last)hr8.x
mad.f16 hr6.x, hr23.w, hr1.x, (last)hr6.x
mad.f16 hr18.y, hr24.x, hr34.y, (last)hr18.y
mad.f16 hr16.y, hr24.x, hr34.z, (last)hr16.y
mad.f16 hr14.y, hr24.x, hr34.w, (last)hr14.y
mad.f16 hr12.y, hr24.x, hr35.x, (last)hr12.y
mad.f16 hr10.y, hr24.x, hr0.z, (last)hr10.y
mad.f16 hr8.y, hr24.x, hr0.w, (last)hr8.y
mad.f16 hr6.y, hr24.x, hr1.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr24.y, hr34.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr24.y, hr34.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr24.y, hr34.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr24.y, hr35.x, (r)(last)hr12.z
ldl.u16 r34.y, l[r1.z+1280], 4
ldl.u16 r35.y, l[r1.z+1344], 4
(rpt1)mad.f16 hr10.z, (r)hr24.y, hr0.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr24.y, hr0.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr24.y, hr1.x, (r)(last)hr6.z
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr1.y, (r)(last)hr32.y
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr1.y, (r)(last)hr32.w
isam.v.base0 (u16)(xyzw)hr32.y, r18.w, s#0, t#2
(rpt1)mad.f16 hr23.w, (r)(last)hr23.w, hr1.y, (r)(last)hr33.y
(rpt1)mad.f16 hr24.y, (r)(last)hr24.y, hr1.y, (r)(last)hr33.w
isam.v.base0 (u16)(xyzw)hr33.y, r19.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr36.y, r19.y, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr37.y, r19.z, s#0, t#2
(ss)nop
ldl.u16 r38.y, l[r1.z+1408], 4
ldl.u16 r0.z, l[r1.z+1472], 4
mad.f16 hr19.x, hr28.y, hr26.x, (last)hr19.x
mad.f16 hr17.x, hr28.y, hr26.y, (last)hr17.x
mad.f16 hr15.x, hr28.y, hr26.z, (last)hr15.x
mad.f16 hr13.x, hr28.y, hr26.w, (last)hr13.x
mad.f16 hr11.x, hr28.y, hr27.x, (last)hr11.x
mad.f16 hr9.x, hr28.y, hr27.y, (last)hr9.x
mad.f16 hr7.x, hr28.y, hr27.z, (last)hr7.x
mad.f16 hr19.y, hr28.z, hr26.x, (last)hr19.y
mad.f16 hr17.y, hr28.z, hr26.y, (last)hr17.y
mad.f16 hr15.y, hr28.z, hr26.z, (last)hr15.y
mad.f16 hr13.y, hr28.z, hr26.w, (last)hr13.y
mad.f16 hr11.y, hr28.z, hr27.x, (last)hr11.y
mad.f16 hr9.y, hr28.z, hr27.y, (last)hr9.y
mad.f16 hr7.y, hr28.z, hr27.z, (last)hr7.y
mad.f16 hr19.z, hr28.w, hr26.x, (last)hr19.z
mad.f16 hr17.z, hr28.w, hr26.y, (last)hr17.z
mad.f16 hr15.z, hr28.w, hr26.z, (last)hr15.z
mad.f16 hr13.z, hr28.w, hr26.w, (last)hr13.z
mad.f16 hr11.z, hr28.w, hr27.x, (last)hr11.z
mad.f16 hr9.z, hr28.w, hr27.y, (last)hr9.z
mad.f16 hr7.z, hr28.w, hr27.z, (last)hr7.z
mad.f16 hr19.w, hr29.x, hr26.x, (last)hr19.w
mad.f16 hr17.w, hr29.x, hr26.y, (last)hr17.w
mad.f16 hr15.w, hr29.x, hr26.z, (last)hr15.w
mad.f16 hr13.w, hr29.x, hr26.w, (last)hr13.w
mad.f16 hr11.w, hr29.x, hr27.x, (last)hr11.w
mad.f16 hr9.w, hr29.x, hr27.y, (last)hr9.w
mad.f16 hr7.w, hr29.x, hr27.z, (last)hr7.w
mad.f16 hr18.x, hr29.y, hr26.x, (last)hr18.x
mad.f16 hr16.x, hr29.y, hr26.y, (last)hr16.x
mad.f16 hr14.x, hr29.y, hr26.z, (last)hr14.x
mad.f16 hr12.x, hr29.y, hr26.w, (last)hr12.x
mad.f16 hr10.x, hr29.y, hr27.x, (last)hr10.x
mad.f16 hr8.x, hr29.y, hr27.y, (last)hr8.x
mad.f16 hr6.x, hr29.y, hr27.z, (last)hr6.x
mad.f16 hr18.y, hr29.z, hr26.x, (last)hr18.y
mad.f16 hr16.y, hr29.z, hr26.y, (last)hr16.y
mad.f16 hr14.y, hr29.z, hr26.z, (last)hr14.y
mad.f16 hr12.y, hr29.z, hr26.w, (last)hr12.y
mad.f16 hr10.y, hr29.z, hr27.x, (last)hr10.y
mad.f16 hr8.y, hr29.z, hr27.y, (last)hr8.y
mad.f16 hr6.y, hr29.z, hr27.z, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr29.w, hr26.x, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr29.w, hr26.y, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr29.w, hr26.z, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr29.w, hr26.w, (r)(last)hr12.z
ldl.u16 r26.x, l[r1.z+1536], 4
(rpt1)mad.f16 hr10.z, (r)hr29.w, hr27.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr29.w, hr27.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr29.w, hr27.z, (r)(last)hr6.z
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr27.w, (r)(last)hr4.y
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr27.w, (r)(last)hr4.w
isam.v.base0 (u16)(xyzw)hr4.y, r19.w, s#0, t#2
(rpt1)mad.f16 hr29.y, (r)(last)hr29.y, hr27.w, (r)(last)hr23.w
(rpt1)mad.f16 hr29.w, (r)(last)hr29.w, hr27.w, (r)(last)hr24.y
isam.v.base0 (u16)(xyzw)hr23.w, r20.x, s#0, t#2
ldl.u16 r27.x, l[r1.z+1600], 4
(sy)mad.f16 hr19.x, hr32.y, hr30.y, (last)hr19.x
mad.f16 hr17.x, hr32.y, hr30.z, (last)hr17.x
mad.f16 hr15.x, hr32.y, hr30.w, (last)hr15.x
mad.f16 hr13.x, hr32.y, hr31.x, (last)hr13.x
mad.f16 hr11.x, hr32.y, hr31.y, (last)hr11.x
mad.f16 hr9.x, hr32.y, hr31.z, (last)hr9.x
mad.f16 hr7.x, hr32.y, hr31.w, (last)hr7.x
mad.f16 hr19.y, hr32.z, hr30.y, (last)hr19.y
mad.f16 hr17.y, hr32.z, hr30.z, (last)hr17.y
mad.f16 hr15.y, hr32.z, hr30.w, (last)hr15.y
mad.f16 hr13.y, hr32.z, hr31.x, (last)hr13.y
mad.f16 hr11.y, hr32.z, hr31.y, (last)hr11.y
mad.f16 hr9.y, hr32.z, hr31.z, (last)hr9.y
mad.f16 hr7.y, hr32.z, hr31.w, (last)hr7.y
mad.f16 hr19.z, hr32.w, hr30.y, (last)hr19.z
mad.f16 hr17.z, hr32.w, hr30.z, (last)hr17.z
mad.f16 hr15.z, hr32.w, hr30.w, (last)hr15.z
mad.f16 hr13.z, hr32.w, hr31.x, (last)hr13.z
mad.f16 hr11.z, hr32.w, hr31.y, (last)hr11.z
mad.f16 hr9.z, hr32.w, hr31.z, (last)hr9.z
mad.f16 hr7.z, hr32.w, hr31.w, (last)hr7.z
mad.f16 hr19.w, hr33.x, hr30.y, (last)hr19.w
mad.f16 hr17.w, hr33.x, hr30.z, (last)hr17.w
mad.f16 hr15.w, hr33.x, hr30.w, (last)hr15.w
mad.f16 hr13.w, hr33.x, hr31.x, (last)hr13.w
mad.f16 hr11.w, hr33.x, hr31.y, (last)hr11.w
mad.f16 hr9.w, hr33.x, hr31.z, (last)hr9.w
mad.f16 hr7.w, hr33.x, hr31.w, (last)hr7.w
mad.f16 hr18.x, hr33.y, hr30.y, (last)hr18.x
mad.f16 hr16.x, hr33.y, hr30.z, (last)hr16.x
mad.f16 hr14.x, hr33.y, hr30.w, (last)hr14.x
mad.f16 hr12.x, hr33.y, hr31.x, (last)hr12.x
mad.f16 hr10.x, hr33.y, hr31.y, (last)hr10.x
mad.f16 hr8.x, hr33.y, hr31.z, (last)hr8.x
mad.f16 hr6.x, hr33.y, hr31.w, (last)hr6.x
mad.f16 hr18.y, hr33.z, hr30.y, (last)hr18.y
mad.f16 hr16.y, hr33.z, hr30.z, (last)hr16.y
mad.f16 hr14.y, hr33.z, hr30.w, (last)hr14.y
mad.f16 hr12.y, hr33.z, hr31.x, (last)hr12.y
mad.f16 hr10.y, hr33.z, hr31.y, (last)hr10.y
mad.f16 hr8.y, hr33.z, hr31.z, (last)hr8.y
mad.f16 hr6.y, hr33.z, hr31.w, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr33.w, hr30.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr33.w, hr30.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr33.w, hr30.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr33.w, hr31.x, (r)(last)hr12.z
ldl.u16 r30.y, l[r1.z+1664], 4
(rpt1)mad.f16 hr10.z, (r)hr33.w, hr31.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr33.w, hr31.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr33.w, hr31.w, (r)(last)hr6.z
(rpt1)mad.f16 hr32.y, (r)(last)hr32.y, hr32.x, (r)(last)hr28.y
(rpt1)mad.f16 hr32.w, (r)(last)hr32.w, hr32.x, (r)(last)hr28.w
isam.v.base0 (u16)(xyzw)hr28.y, r20.y, s#0, t#2
(rpt1)mad.f16 hr33.y, (r)(last)hr33.y, hr32.x, (r)(last)hr29.y
(rpt1)mad.f16 hr33.w, (r)(last)hr33.w, hr32.x, (r)(last)hr29.w
isam.v.base0 (u16)(xyzw)hr29.y, r20.z, s#0, t#2
ldl.u16 r31.y, l[r1.z+1728], 4
mad.f16 hr19.x, hr36.y, hr34.y, (last)hr19.x
mad.f16 hr17.x, hr36.y, hr34.z, (last)hr17.x
mad.f16 hr15.x, hr36.y, hr34.w, (last)hr15.x
mad.f16 hr13.x, hr36.y, hr35.x, (last)hr13.x
mad.f16 hr11.x, hr36.y, hr35.y, (last)hr11.x
mad.f16 hr9.x, hr36.y, hr35.z, (last)hr9.x
mad.f16 hr7.x, hr36.y, hr35.w, (last)hr7.x
mad.f16 hr19.y, hr36.z, hr34.y, (last)hr19.y
mad.f16 hr17.y, hr36.z, hr34.z, (last)hr17.y
mad.f16 hr15.y, hr36.z, hr34.w, (last)hr15.y
mad.f16 hr13.y, hr36.z, hr35.x, (last)hr13.y
mad.f16 hr11.y, hr36.z, hr35.y, (last)hr11.y
mad.f16 hr9.y, hr36.z, hr35.z, (last)hr9.y
mad.f16 hr7.y, hr36.z, hr35.w, (last)hr7.y
mad.f16 hr19.z, hr36.w, hr34.y, (last)hr19.z
mad.f16 hr17.z, hr36.w, hr34.z, (last)hr17.z
mad.f16 hr15.z, hr36.w, hr34.w, (last)hr15.z
mad.f16 hr13.z, hr36.w, hr35.x, (last)hr13.z
mad.f16 hr11.z, hr36.w, hr35.y, (last)hr11.z
mad.f16 hr9.z, hr36.w, hr35.z, (last)hr9.z
mad.f16 hr7.z, hr36.w, hr35.w, (last)hr7.z
mad.f16 hr19.w, hr37.x, hr34.y, (last)hr19.w
mad.f16 hr17.w, hr37.x, hr34.z, (last)hr17.w
mad.f16 hr15.w, hr37.x, hr34.w, (last)hr15.w
mad.f16 hr13.w, hr37.x, hr35.x, (last)hr13.w
mad.f16 hr11.w, hr37.x, hr35.y, (last)hr11.w
mad.f16 hr9.w, hr37.x, hr35.z, (last)hr9.w
mad.f16 hr7.w, hr37.x, hr35.w, (last)hr7.w
mad.f16 hr18.x, hr37.y, hr34.y, (last)hr18.x
mad.f16 hr16.x, hr37.y, hr34.z, (last)hr16.x
mad.f16 hr14.x, hr37.y, hr34.w, (last)hr14.x
mad.f16 hr12.x, hr37.y, hr35.x, (last)hr12.x
mad.f16 hr10.x, hr37.y, hr35.y, (last)hr10.x
mad.f16 hr8.x, hr37.y, hr35.z, (last)hr8.x
mad.f16 hr6.x, hr37.y, hr35.w, (last)hr6.x
mad.f16 hr18.y, hr37.z, hr34.y, (last)hr18.y
mad.f16 hr16.y, hr37.z, hr34.z, (last)hr16.y
mad.f16 hr14.y, hr37.z, hr34.w, (last)hr14.y
mad.f16 hr12.y, hr37.z, hr35.x, (last)hr12.y
mad.f16 hr10.y, hr37.z, hr35.y, (last)hr10.y
mad.f16 hr8.y, hr37.z, hr35.z, (last)hr8.y
mad.f16 hr6.y, hr37.z, hr35.w, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr37.w, hr34.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr37.w, hr34.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr37.w, hr34.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr37.w, hr35.x, (r)(last)hr12.z
ldl.u16 r34.y, l[r1.z+1792], 4
(rpt1)mad.f16 hr10.z, (r)hr37.w, hr35.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr37.w, hr35.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr37.w, hr35.w, (r)(last)hr6.z
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr36.x, (r)(last)hr32.y
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr36.x, (r)(last)hr32.w
isam.v.base0 (u16)(xyzw)hr32.y, r10.x, s#0, t#2
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr36.x, (r)(last)hr33.y
(rpt1)mad.f16 hr37.w, (r)(last)hr37.w, hr36.x, (r)(last)hr33.w
isam.v.base0 (u16)(xyzw)hr33.y, r10.y, s#0, t#2
ldl.u16 r35.y, l[r1.z+1856], 4
(ss)mad.f16 hr19.x, hr4.y, hr38.y, (last)hr19.x
mad.f16 hr17.x, hr4.y, hr38.z, (last)hr17.x
mad.f16 hr15.x, hr4.y, hr38.w, (last)hr15.x
mad.f16 hr13.x, hr4.y, hr39.x, (last)hr13.x
mad.f16 hr11.x, hr4.y, hr0.z, (last)hr11.x
mad.f16 hr9.x, hr4.y, hr0.w, (last)hr9.x
mad.f16 hr7.x, hr4.y, hr1.x, (last)hr7.x
mad.f16 hr19.y, hr4.z, hr38.y, (last)hr19.y
mad.f16 hr17.y, hr4.z, hr38.z, (last)hr17.y
mad.f16 hr15.y, hr4.z, hr38.w, (last)hr15.y
mad.f16 hr13.y, hr4.z, hr39.x, (last)hr13.y
mad.f16 hr11.y, hr4.z, hr0.z, (last)hr11.y
mad.f16 hr9.y, hr4.z, hr0.w, (last)hr9.y
mad.f16 hr7.y, hr4.z, hr1.x, (last)hr7.y
mad.f16 hr19.z, hr4.w, hr38.y, (last)hr19.z
mad.f16 hr17.z, hr4.w, hr38.z, (last)hr17.z
mad.f16 hr15.z, hr4.w, hr38.w, (last)hr15.z
mad.f16 hr13.z, hr4.w, hr39.x, (last)hr13.z
mad.f16 hr11.z, hr4.w, hr0.z, (last)hr11.z
mad.f16 hr9.z, hr4.w, hr0.w, (last)hr9.z
mad.f16 hr7.z, hr4.w, hr1.x, (last)hr7.z
mad.f16 hr19.w, hr5.x, hr38.y, (last)hr19.w
mad.f16 hr17.w, hr5.x, hr38.z, (last)hr17.w
mad.f16 hr15.w, hr5.x, hr38.w, (last)hr15.w
mad.f16 hr13.w, hr5.x, hr39.x, (last)hr13.w
mad.f16 hr11.w, hr5.x, hr0.z, (last)hr11.w
mad.f16 hr9.w, hr5.x, hr0.w, (last)hr9.w
mad.f16 hr7.w, hr5.x, hr1.x, (last)hr7.w
mad.f16 hr18.x, hr23.w, hr38.y, (last)hr18.x
mad.f16 hr16.x, hr23.w, hr38.z, (last)hr16.x
mad.f16 hr14.x, hr23.w, hr38.w, (last)hr14.x
mad.f16 hr12.x, hr23.w, hr39.x, (last)hr12.x
mad.f16 hr10.x, hr23.w, hr0.z, (last)hr10.x
mad.f16 hr8.x, hr23.w, hr0.w, (last)hr8.x
mad.f16 hr6.x, hr23.w, hr1.x, (last)hr6.x
mad.f16 hr18.y, hr24.x, hr38.y, (last)hr18.y
mad.f16 hr16.y, hr24.x, hr38.z, (last)hr16.y
mad.f16 hr14.y, hr24.x, hr38.w, (last)hr14.y
mad.f16 hr12.y, hr24.x, hr39.x, (last)hr12.y
mad.f16 hr10.y, hr24.x, hr0.z, (last)hr10.y
mad.f16 hr8.y, hr24.x, hr0.w, (last)hr8.y
mad.f16 hr6.y, hr24.x, hr1.x, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr24.y, hr38.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr24.y, hr38.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr24.y, hr38.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr24.y, hr39.x, (r)(last)hr12.z
ldl.u16 r38.y, l[r1.z+1920], 4
ldl.u16 r39.y, l[r1.z+1984], 4
(rpt1)mad.f16 hr10.z, (r)hr24.y, hr0.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr24.y, hr0.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr24.y, hr1.x, (r)(last)hr6.z
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr1.y, (r)(last)hr36.y
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr1.y, (r)(last)hr36.w
isam.v.base0 (u16)(xyzw)hr36.y, r10.z, s#0, t#2
(rpt1)mad.f16 hr23.w, (r)(last)hr23.w, hr1.y, (r)(last)hr37.y
(rpt1)mad.f16 hr24.y, (r)(last)hr24.y, hr1.y, (r)(last)hr37.w
isam.v.base0 (u16)(xyzw)hr37.y, r10.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr40.y, r11.y, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr20.y, r11.z, s#0, t#2
fence.r.w
(sy)(ss)mad.f16 hr19.x, hr28.y, hr26.x, (last)hr19.x
mad.f16 hr17.x, hr28.y, hr26.y, (last)hr17.x
mad.f16 hr15.x, hr28.y, hr26.z, (last)hr15.x
mad.f16 hr13.x, hr28.y, hr26.w, (last)hr13.x
mad.f16 hr11.x, hr28.y, hr27.x, (last)hr11.x
mad.f16 hr9.x, hr28.y, hr27.y, (last)hr9.x
mad.f16 hr7.x, hr28.y, hr27.z, (last)hr7.x
mad.f16 hr19.y, hr28.z, hr26.x, (last)hr19.y
mad.f16 hr17.y, hr28.z, hr26.y, (last)hr17.y
mad.f16 hr15.y, hr28.z, hr26.z, (last)hr15.y
mad.f16 hr13.y, hr28.z, hr26.w, (last)hr13.y
mad.f16 hr11.y, hr28.z, hr27.x, (last)hr11.y
mad.f16 hr9.y, hr28.z, hr27.y, (last)hr9.y
mad.f16 hr7.y, hr28.z, hr27.z, (last)hr7.y
mad.f16 hr19.z, hr28.w, hr26.x, (last)hr19.z
mad.f16 hr17.z, hr28.w, hr26.y, (last)hr17.z
mad.f16 hr15.z, hr28.w, hr26.z, (last)hr15.z
mad.f16 hr13.z, hr28.w, hr26.w, (last)hr13.z
mad.f16 hr11.z, hr28.w, hr27.x, (last)hr11.z
mad.f16 hr9.z, hr28.w, hr27.y, (last)hr9.z
mad.f16 hr7.z, hr28.w, hr27.z, (last)hr7.z
mad.f16 hr19.w, hr29.x, hr26.x, (last)hr19.w
mad.f16 hr17.w, hr29.x, hr26.y, (last)hr17.w
mad.f16 hr15.w, hr29.x, hr26.z, (last)hr15.w
mad.f16 hr13.w, hr29.x, hr26.w, (last)hr13.w
mad.f16 hr11.w, hr29.x, hr27.x, (last)hr11.w
mad.f16 hr9.w, hr29.x, hr27.y, (last)hr9.w
mad.f16 hr7.w, hr29.x, hr27.z, (last)hr7.w
mad.f16 hr18.x, hr29.y, hr26.x, (last)hr18.x
mad.f16 hr16.x, hr29.y, hr26.y, (last)hr16.x
mad.f16 hr14.x, hr29.y, hr26.z, (last)hr14.x
mad.f16 hr12.x, hr29.y, hr26.w, (last)hr12.x
mad.f16 hr10.x, hr29.y, hr27.x, (last)hr10.x
mad.f16 hr8.x, hr29.y, hr27.y, (last)hr8.x
mad.f16 hr6.x, hr29.y, hr27.z, (last)hr6.x
mad.f16 hr18.y, hr29.z, hr26.x, (last)hr18.y
mad.f16 hr16.y, hr29.z, hr26.y, (last)hr16.y
mad.f16 hr14.y, hr29.z, hr26.z, (last)hr14.y
mad.f16 hr12.y, hr29.z, hr26.w, (last)hr12.y
mad.f16 hr10.y, hr29.z, hr27.x, (last)hr10.y
mad.f16 hr8.y, hr29.z, hr27.y, (last)hr8.y
mad.f16 hr6.y, hr29.z, hr27.z, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr29.w, hr26.x, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr29.w, hr26.y, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr29.w, hr26.z, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr29.w, hr26.w, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr29.w, hr27.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr29.w, hr27.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr29.w, hr27.z, (r)(last)hr6.z
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr27.w, (r)(last)hr4.y
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr27.w, (r)(last)hr4.w
(rpt1)mad.f16 hr29.y, (r)(last)hr29.y, hr27.w, (r)(last)hr23.w
(rpt1)mad.f16 hr29.w, (r)(last)hr29.w, hr27.w, (r)(last)hr24.y
mad.f16 hr19.x, hr32.y, hr30.y, (last)hr19.x
mad.f16 hr17.x, hr32.y, hr30.z, (last)hr17.x
mad.f16 hr15.x, hr32.y, hr30.w, (last)hr15.x
mad.f16 hr13.x, hr32.y, hr31.x, (last)hr13.x
mad.f16 hr11.x, hr32.y, hr31.y, (last)hr11.x
mad.f16 hr9.x, hr32.y, hr31.z, (last)hr9.x
mad.f16 hr7.x, hr32.y, hr31.w, (last)hr7.x
mad.f16 hr19.y, hr32.z, hr30.y, (last)hr19.y
mad.f16 hr17.y, hr32.z, hr30.z, (last)hr17.y
mad.f16 hr15.y, hr32.z, hr30.w, (last)hr15.y
mad.f16 hr13.y, hr32.z, hr31.x, (last)hr13.y
mad.f16 hr11.y, hr32.z, hr31.y, (last)hr11.y
mad.f16 hr9.y, hr32.z, hr31.z, (last)hr9.y
mad.f16 hr7.y, hr32.z, hr31.w, (last)hr7.y
mad.f16 hr19.z, hr32.w, hr30.y, (last)hr19.z
mad.f16 hr17.z, hr32.w, hr30.z, (last)hr17.z
mad.f16 hr15.z, hr32.w, hr30.w, (last)hr15.z
mad.f16 hr13.z, hr32.w, hr31.x, (last)hr13.z
mad.f16 hr11.z, hr32.w, hr31.y, (last)hr11.z
mad.f16 hr9.z, hr32.w, hr31.z, (last)hr9.z
mad.f16 hr7.z, hr32.w, hr31.w, (last)hr7.z
mad.f16 hr19.w, hr33.x, hr30.y, (last)hr19.w
mad.f16 hr17.w, hr33.x, hr30.z, (last)hr17.w
mad.f16 hr15.w, hr33.x, hr30.w, (last)hr15.w
mad.f16 hr13.w, hr33.x, hr31.x, (last)hr13.w
mad.f16 hr11.w, hr33.x, hr31.y, (last)hr11.w
mad.f16 hr9.w, hr33.x, hr31.z, (last)hr9.w
mad.f16 hr7.w, hr33.x, hr31.w, (last)hr7.w
mad.f16 hr18.x, hr33.y, hr30.y, (last)hr18.x
mad.f16 hr16.x, hr33.y, hr30.z, (last)hr16.x
mad.f16 hr14.x, hr33.y, hr30.w, (last)hr14.x
mad.f16 hr12.x, hr33.y, hr31.x, (last)hr12.x
mad.f16 hr10.x, hr33.y, hr31.y, (last)hr10.x
mad.f16 hr8.x, hr33.y, hr31.z, (last)hr8.x
mad.f16 hr6.x, hr33.y, hr31.w, (last)hr6.x
mad.f16 hr18.y, hr33.z, hr30.y, (last)hr18.y
mad.f16 hr16.y, hr33.z, hr30.z, (last)hr16.y
mad.f16 hr14.y, hr33.z, hr30.w, (last)hr14.y
mad.f16 hr12.y, hr33.z, hr31.x, (last)hr12.y
mad.f16 hr10.y, hr33.z, hr31.y, (last)hr10.y
mad.f16 hr8.y, hr33.z, hr31.z, (last)hr8.y
mad.f16 hr6.y, hr33.z, hr31.w, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr33.w, hr30.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr33.w, hr30.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr33.w, hr30.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr33.w, hr31.x, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr33.w, hr31.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr33.w, hr31.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr33.w, hr31.w, (r)(last)hr6.z
(rpt1)mad.f16 hr32.y, (r)(last)hr32.y, hr32.x, (r)(last)hr28.y
(rpt1)mad.f16 hr32.w, (r)(last)hr32.w, hr32.x, (r)(last)hr28.w
(rpt1)mad.f16 hr33.y, (r)(last)hr33.y, hr32.x, (r)(last)hr29.y
(rpt1)mad.f16 hr33.w, (r)(last)hr33.w, hr32.x, (r)(last)hr29.w
mad.f16 hr19.x, hr36.y, hr34.y, (last)hr19.x
mad.f16 hr17.x, hr36.y, hr34.z, (last)hr17.x
mad.f16 hr15.x, hr36.y, hr34.w, (last)hr15.x
mad.f16 hr13.x, hr36.y, hr35.x, (last)hr13.x
mad.f16 hr11.x, hr36.y, hr35.y, (last)hr11.x
mad.f16 hr9.x, hr36.y, hr35.z, (last)hr9.x
mad.f16 hr7.x, hr36.y, hr35.w, (last)hr7.x
mad.f16 hr19.y, hr36.z, hr34.y, (last)hr19.y
mad.f16 hr17.y, hr36.z, hr34.z, (last)hr17.y
mad.f16 hr15.y, hr36.z, hr34.w, (last)hr15.y
mad.f16 hr13.y, hr36.z, hr35.x, (last)hr13.y
mad.f16 hr11.y, hr36.z, hr35.y, (last)hr11.y
mad.f16 hr9.y, hr36.z, hr35.z, (last)hr9.y
mad.f16 hr7.y, hr36.z, hr35.w, (last)hr7.y
mad.f16 hr19.z, hr36.w, hr34.y, (last)hr19.z
mad.f16 hr17.z, hr36.w, hr34.z, (last)hr17.z
mad.f16 hr15.z, hr36.w, hr34.w, (last)hr15.z
mad.f16 hr13.z, hr36.w, hr35.x, (last)hr13.z
mad.f16 hr11.z, hr36.w, hr35.y, (last)hr11.z
mad.f16 hr9.z, hr36.w, hr35.z, (last)hr9.z
mad.f16 hr7.z, hr36.w, hr35.w, (last)hr7.z
mad.f16 hr19.w, hr37.x, hr34.y, (last)hr19.w
mad.f16 hr17.w, hr37.x, hr34.z, (last)hr17.w
mad.f16 hr15.w, hr37.x, hr34.w, (last)hr15.w
mad.f16 hr13.w, hr37.x, hr35.x, (last)hr13.w
mad.f16 hr11.w, hr37.x, hr35.y, (last)hr11.w
mad.f16 hr9.w, hr37.x, hr35.z, (last)hr9.w
mad.f16 hr7.w, hr37.x, hr35.w, (last)hr7.w
mad.f16 hr18.x, hr37.y, hr34.y, (last)hr18.x
mad.f16 hr16.x, hr37.y, hr34.z, (last)hr16.x
mad.f16 hr14.x, hr37.y, hr34.w, (last)hr14.x
mad.f16 hr12.x, hr37.y, hr35.x, (last)hr12.x
mad.f16 hr10.x, hr37.y, hr35.y, (last)hr10.x
mad.f16 hr8.x, hr37.y, hr35.z, (last)hr8.x
mad.f16 hr6.x, hr37.y, hr35.w, (last)hr6.x
mad.f16 hr18.y, hr37.z, hr34.y, (last)hr18.y
mad.f16 hr16.y, hr37.z, hr34.z, (last)hr16.y
mad.f16 hr14.y, hr37.z, hr34.w, (last)hr14.y
mad.f16 hr12.y, hr37.z, hr35.x, (last)hr12.y
mad.f16 hr10.y, hr37.z, hr35.y, (last)hr10.y
mad.f16 hr8.y, hr37.z, hr35.z, (last)hr8.y
mad.f16 hr6.y, hr37.z, hr35.w, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr37.w, hr34.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr37.w, hr34.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr37.w, hr34.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr37.w, hr35.x, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr37.w, hr35.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr37.w, hr35.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr37.w, hr35.w, (r)(last)hr6.z
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr36.x, (r)(last)hr32.y
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr36.x, (r)(last)hr32.w
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr36.x, (r)(last)hr33.y
(rpt1)mad.f16 hr37.w, (r)(last)hr37.w, hr36.x, (r)(last)hr33.w
bar.g
(sy)(ss)mad.f16 hr19.x, hr40.y, hr38.y, (last)hr19.x
mad.f16 hr17.x, hr40.y, hr38.z, (last)hr17.x
mad.f16 hr15.x, hr40.y, hr38.w, (last)hr15.x
mad.f16 hr13.x, hr40.y, hr39.x, (last)hr13.x
mad.f16 hr11.x, hr40.y, hr39.y, (last)hr11.x
mad.f16 hr9.x, hr40.y, hr39.z, (last)hr9.x
mad.f16 hr7.x, hr40.y, hr39.w, (last)hr7.x
mad.f16 hr19.y, hr40.z, hr38.y, (last)hr19.y
mad.f16 hr17.y, hr40.z, hr38.z, (last)hr17.y
mad.f16 hr15.y, hr40.z, hr38.w, (last)hr15.y
mad.f16 hr13.y, hr40.z, hr39.x, (last)hr13.y
mad.f16 hr11.y, hr40.z, hr39.y, (last)hr11.y
mad.f16 hr9.y, hr40.z, hr39.z, (last)hr9.y
mad.f16 hr7.y, hr40.z, hr39.w, (last)hr7.y
mad.f16 hr19.z, hr40.w, hr38.y, (last)hr19.z
mad.f16 hr17.z, hr40.w, hr38.z, (last)hr17.z
mad.f16 hr15.z, hr40.w, hr38.w, (last)hr15.z
mad.f16 hr13.z, hr40.w, hr39.x, (last)hr13.z
mad.f16 hr11.z, hr40.w, hr39.y, (last)hr11.z
mad.f16 hr9.z, hr40.w, hr39.z, (last)hr9.z
mad.f16 hr7.z, hr40.w, hr39.w, (last)hr7.z
mad.f16 hr19.w, hr41.x, hr38.y, (last)hr19.w
mad.f16 hr17.w, hr41.x, hr38.z, (last)hr17.w
mad.f16 hr15.w, hr41.x, hr38.w, (last)hr15.w
mad.f16 hr13.w, hr41.x, hr39.x, (last)hr13.w
mad.f16 hr11.w, hr41.x, hr39.y, (last)hr11.w
mad.f16 hr9.w, hr41.x, hr39.z, (last)hr9.w
mad.f16 hr7.w, hr41.x, hr39.w, (last)hr7.w
mad.f16 hr18.x, hr20.y, hr38.y, (last)hr18.x
mad.f16 hr16.x, hr20.y, hr38.z, (last)hr16.x
mad.f16 hr14.x, hr20.y, hr38.w, (last)hr14.x
mad.f16 hr12.x, hr20.y, hr39.x, (last)hr12.x
mad.f16 hr10.x, hr20.y, hr39.y, (last)hr10.x
mad.f16 hr8.x, hr20.y, hr39.z, (last)hr8.x
mad.f16 hr6.x, hr20.y, hr39.w, (last)hr6.x
mad.f16 hr18.y, hr20.z, hr38.y, (last)hr18.y
mad.f16 hr16.y, hr20.z, hr38.z, (last)hr16.y
mad.f16 hr14.y, hr20.z, hr38.w, (last)hr14.y
mad.f16 hr12.y, hr20.z, hr39.x, (last)hr12.y
mad.f16 hr10.y, hr20.z, hr39.y, (last)hr10.y
mad.f16 hr8.y, hr20.z, hr39.z, (last)hr8.y
mad.f16 hr6.y, hr20.z, hr39.w, (last)hr6.y
(rpt1)mad.f16 hr18.z, (r)hr20.w, hr38.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.z, (r)hr20.w, hr38.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.z, (r)hr20.w, hr38.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.z, (r)hr20.w, hr39.x, (r)(last)hr12.z
(rpt1)mad.f16 hr10.z, (r)hr20.w, hr39.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr20.w, hr39.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr20.w, hr39.w, (r)(last)hr6.z
(rpt1)mad.f16 hr5.x, (r)(last)hr40.y, hr40.x, (r)(last)hr36.y
(rpt1)mad.f16 hr5.z, (r)(last)hr40.w, hr40.x, (r)(last)hr36.w
(rpt1)mad.f16 hr4.x, (r)(last)hr20.y, hr40.x, (r)(last)hr37.y
(rpt1)mad.f16 hr4.z, (r)(last)hr20.w, hr40.x, (r)(last)hr37.w
br p0.x, #l1106
jump #l131
l1106:
(jp)(eolm)nop
(nop3) add.u r12.w, r51.w, (last)r12.w
(nop3) shl.b r12.w, (last)r12.w, 9
(nop3) sad.s32 r12.w, r52.w, r12.w, (last)r1.w
(nop3) shl.b r12.w, (last)r12.w, 2
add.u r10.w, r12.w, c1.x
add.u r11.x, r12.w, c8.y
add.u r11.y, r12.w, c4.z
add.u r11.z, r12.w, c8.x
add.u r11.w, r12.w, c4.y
add.u r12.x, r12.w, c7.w
(rpt1)add.u r12.y, r12.w, (r)c8.z
(rpt3)add.u r13.x, r12.w, (r)c9.x
(rpt1)add.u r14.x, r12.w, (r)c10.x
stib.b.untyped.1d.u16.4.imm.base0 hr19.x, r12.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr18.x, r12.w+32, 4
stib.b.untyped.1d.u16.4.imm.base0 hr17.x, r10.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.x, r11.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.x, r11.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.x, r11.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.x, r11.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.x, r12.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.x, r12.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.x, r12.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr9.x, r13.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr8.x, r13.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.x, r13.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.x, r13.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r14.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r14.y, 4
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
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1308 instr, 28 nops, 1280 non-nops, 65 mov, 0 cov, 2304 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 21 full, 12 constlen
; CL prog 23/1: 31 cat0, 65 cat1, 90 cat2, 1030 cat3, 0 cat4, 36 cat5, 52 cat6, 4 cat7
; CL prog 23/1: 30 sstall, 23 (ss), 345 systall, 15 (sy), 1 loops
; CL prog 23/1: 12 max_waves, 0 double_threadsize
; 58 preamble-instr, 1 early-preamble
