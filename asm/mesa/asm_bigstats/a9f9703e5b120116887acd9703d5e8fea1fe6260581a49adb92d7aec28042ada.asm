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
@const(c10.x)	0x00011800, 0x00011820, 0x00020000, 0x00020020
@const(c11.x)	0x00020800, 0x00020820, 0x00021000, 0x00021020
@const(c12.x)	0x00021800, 0x00021820, 0x00030000, 0x00030020
@const(c13.x)	0x00030800, 0x00030820, 0x00031000, 0x00031020
@const(c14.x)	0x00031800, 0x00031820, 0xd0d0d0d0, 0xd0d0d0d0
shps #l78
getone #l78
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
mov.u32u32 r51.y, 0x20000
mov.u32u32 r51.z, 0x20020
mov.u32u32 r51.w, 0x20800
mov.u32u32 r52.x, 0x20820
mov.u32u32 r52.y, 0x21000
mov.u32u32 r52.z, 0x21020
mov.u32u32 r52.w, 0x21800
mov.u32u32 r53.x, 0x21820
mov.u32u32 r53.y, 0x30000
mov.u32u32 r53.z, 0x30020
mov.u32u32 r53.w, 0x30800
mov.u32u32 r54.x, 0x30820
mov.u32u32 r54.y, 0x31000
mov.u32u32 r54.z, 0x31020
mov.u32u32 r54.w, 0x31800
mov.u32u32 r55.x, 0x31820
stc.u32 c[32], r48.w, 4
(ss)nop
stc.u32 c[36], r49.w, 4
stc.u32 c[40], r50.w, 4
stc.u32 c[44], r51.w, 4
stc.u32 c[48], r52.w, 4
stc.u32 c[52], r53.w, 4
stc.u32 c[56], r54.w, 2
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l78:
(jp)(rpt1)add.u r55.y, (r)r48.x, (r)c0.x
mov.u32u32 r49.x, 0
shl.b r48.w, r55.y, 6
shl.b r48.z, r55.z, 7
shr.b r0.w, r0.x, 5
and.b r1.x, r0.x, 31
shr.b r1.y, r0.x, 3
and.b r1.z, r0.x, -8
and.b r1.w, r0.x, 7
mov.u16u16 hr4.x, 0
mov.u16u16 hr4.y, 0
mov.u16u16 hr35.w, 0
mov.u16u16 hr35.z, 0
mov.u16u16 hr35.y, 0
mov.u16u16 hr35.x, 0
mov.u16u16 hr34.w, 0
mov.u16u16 hr34.z, 0
mov.u16u16 hr34.y, 0
mov.u16u16 hr34.x, 0
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
l215:
(rpt1)shr.b r49.y, (r)r48.z, 2
shl.b r49.w, r49.x, 9
add.u r18.z, r0.x, 64
add.u r18.w, r0.x, 128
add.u r19.x, r0.x, 192
add.u r19.y, r0.x, 256
(rpt1)shr.b r18.z, (last)(r)r18.z, 5
(ss)add.u r19.z, r49.x, r0.w
shr.b r19.x, (last)r19.x, 5
add.u r20.y, r49.x, r18.z
shr.b r19.y, (last)r19.y, 5
shl.b r19.z, (last)r19.z, 9
add.u r20.z, r49.x, r18.w
shl.b r20.y, (last)r20.y, 9
add.u r20.w, r49.x, r19.x
sad.s32 r19.z, r49.y, r19.z, r1.x
add.u r21.x, r49.x, r19.y
sad.s32 r20.y, r49.y, r20.y, r1.x
shl.b r20.z, (last)r20.z, 9
shl.b r19.z, (last)r19.z, 2
shl.b r20.w, (last)r20.w, 9
shl.b r20.y, (last)r20.y, 2
shl.b r21.x, (last)r21.x, 9
shl.b r18.x, r0.w, 8
shl.b r18.y, r1.x, 3
add.u r21.y, r0.x, 320
isam.v.base0 (u16)(xyzw)hr39.z, r19.z, s#0, t#0
add.u r21.z, r0.x, 384
add.u r21.w, r0.x, 448
isam.v.base0 (u16)(xyzw)hr45.z, r20.y, s#0, t#0
shl.b r18.z, (last)r18.z, 8
(rpt2)sad.s32 r20.z, r49.y, (r)r20.z, r1.x
add.u r18.x, (last)r18.x, r18.y
(rpt2)shr.b r21.y, (last)(r)r21.y, 5
add.u r18.z, (last)r18.z, r18.y
shl.b r20.z, (last)r20.z, 2
(rpt1)shl.b r20.w, (last)(r)r20.w, 2
(rpt2)shl.b r18.w, (last)(r)r18.w, 8
add.u r22.x, r49.x, r21.y
isam.v.base0 (u16)(xyzw)hr47.x, r20.z, s#0, t#0
add.u r22.y, r49.x, r21.z
isam.v.base0 (u16)(xyzw)hr0.z, r20.w, s#0, t#0
add.u r22.z, r49.x, r21.w
add.u r49.x, r49.x, 16
cmps.u.ge up0.x, r49.x, c1.x
(rpt2)shl.b r21.y, (last)(r)r21.y, 8
(rpt2)add.u r18.w, (last)(r)r18.w, r18.y
(rpt2)add.u r21.y, (last)(r)r21.y, (last)r18.y
(rpt2)shl.b r22.x, (last)(r)r22.x, 9
shl.b r23.y, r1.y, 2
(rpt2)sad.s32 r22.x, r49.y, (r)r22.x, r1.x
nop
(rpt1)shl.b r22.x, (last)(r)r22.x, 2
shl.b r22.z, (last)r22.z, 2
(sy)stl.u16 l[r18.x], r39.z, 4
stl.u16 l[r18.z], r45.z, 4
(ss)nop
isam.v.base0 (u16)(xyzw)hr36.z, r21.x, s#0, t#0
stl.u16 l[r18.w], r47.x, 4
stl.u16 l[r19.x], r0.z, 4
sad.s32 r18.x, r49.w, r1.w, r49.z
(ss)(rpt1)nop
isam.v.base0 (u16)(xyzw)hr0.z, r22.x, s#0, t#0
nop
(nop3) shl.b r18.x, (last)r18.x, 2
add.u r19.z, r18.x, c1.x
add.u r19.w, r18.x, c8.y
add.u r20.x, r18.x, c4.z
add.u r20.y, r18.x, c8.x
add.u r23.z, r18.x, c4.y
add.u r23.w, r18.x, c7.w
add.u r24.x, r18.x, c4.x
add.u r24.y, r18.x, c7.z
add.u r24.z, r18.x, c3.w
add.u r24.w, r18.x, c7.y
add.u r25.x, r18.x, c3.z
add.u r25.y, r18.x, c7.x
add.u r25.z, r18.x, c3.y
add.u r25.w, r18.x, c6.w
add.u r26.x, r18.x, c3.x
add.u r26.y, r18.x, c6.z
add.u r26.z, r18.x, c2.w
add.u r26.w, r18.x, c6.y
add.u r27.x, r18.x, c2.z
add.u r27.y, r18.x, c6.x
add.u r27.z, r18.x, c2.y
add.u r27.w, r18.x, c5.w
add.u r28.x, r18.x, c2.x
add.u r28.y, r18.x, c5.z
add.u r28.z, r18.x, c1.w
add.u r28.w, r18.x, c5.y
add.u r29.x, r18.x, c1.z
add.u r29.y, r18.x, c5.x
add.u r29.z, r18.x, c1.y
add.u r29.w, r18.x, c4.w
(sy)stl.u16 l[r19.y], r36.z, 4
(ss)nop
isam.v.base0 (u16)(xyzw)hr36.z, r22.y, s#0, t#0
isam.v.base0 (u16)(xyzw)hr37.z, r22.z, s#0, t#0
stl.u16 l[r21.y], r0.z, 4
(sy)stl.u16 l[r21.z], r36.z, 4
stl.u16 l[r21.w], r37.z, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
isam.v.base0 (u16)(xyzw)hr42.x, r18.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr44.x, r18.x+32, s#0, t#2
ldl.u16 r41.x, l[r1.z], 4
ldl.u16 r43.x, l[r1.z+64], 4
ldl.u16 r45.x, l[r1.z+128], 4
ldl.u16 r0.z, l[r1.z+192], 4
ldl.u16 r37.y, l[r1.z+256], 4
(ss)nop
isam.v.base0 (u16)(xyzw)hr36.y, r19.z, s#0, t#2
(ss)nop
ldl.u16 r38.y, l[r1.z+320], 4
(sy)(rpt1)mad.f16 hr17.x, (r)hr42.x, hr45.y, (r)(last)hr17.x
(rpt1)mad.f16 hr17.z, (r)hr42.z, hr45.y, (r)(last)hr17.z
(rpt1)mad.f16 hr16.x, (r)hr44.x, hr45.y, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr44.z, hr45.y, (r)(last)hr16.z
(rpt1)mad.f16 hr15.x, (r)hr42.x, hr45.z, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr42.z, hr45.z, (r)(last)hr15.z
(rpt1)mad.f16 hr14.x, (r)hr44.x, hr45.z, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr44.z, hr45.z, (r)(last)hr14.z
(rpt1)mad.f16 hr13.x, (r)hr42.x, hr45.w, (r)(last)hr13.x
(rpt1)mad.f16 hr13.z, (r)hr42.z, hr45.w, (r)(last)hr13.z
(rpt1)mad.f16 hr12.x, (r)hr44.x, hr45.w, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr44.z, hr45.w, (r)(last)hr12.z
isam.v.base0 (u16)(xyzw)hr45.y, r19.w, s#0, t#2
mad.f16 hr35.x, hr42.x, hr41.x, (last)hr35.x
mad.f16 hr33.x, hr42.x, hr41.y, (last)hr33.x
mad.f16 hr31.x, hr42.x, hr41.z, (last)hr31.x
mad.f16 hr29.x, hr42.x, hr41.w, (last)hr29.x
mad.f16 hr35.y, hr42.y, hr41.x, (last)hr35.y
mad.f16 hr33.y, hr42.y, hr41.y, (last)hr33.y
mad.f16 hr31.y, hr42.y, hr41.z, (last)hr31.y
mad.f16 hr29.y, hr42.y, hr41.w, (last)hr29.y
mad.f16 hr35.z, hr42.z, hr41.x, (last)hr35.z
mad.f16 hr33.z, hr42.z, hr41.y, (last)hr33.z
mad.f16 hr31.z, hr42.z, hr41.z, (last)hr31.z
mad.f16 hr29.z, hr42.z, hr41.w, (last)hr29.z
mad.f16 hr35.w, hr42.w, hr41.x, (last)hr35.w
mad.f16 hr33.w, hr42.w, hr41.y, (last)hr33.w
mad.f16 hr31.w, hr42.w, hr41.z, (last)hr31.w
mad.f16 hr29.w, hr42.w, hr41.w, (last)hr29.w
(rpt1)mad.f16 hr27.x, (r)hr42.x, hr43.x, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr42.z, hr43.x, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr42.x, hr43.y, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr42.z, hr43.y, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr42.x, hr43.z, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr42.z, hr43.z, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr42.x, hr43.w, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr42.z, hr43.w, (r)(last)hr21.z
(rpt1)mad.f16 hr19.x, (r)hr42.x, hr45.x, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr42.z, hr45.x, (r)(last)hr19.z
(rpt1)mad.f16 hr11.x, (r)hr42.x, hr0.z, (r)(last)hr11.x
(rpt1)mad.f16 hr11.z, (r)hr42.z, hr0.z, (r)(last)hr11.z
(rpt1)mad.f16 hr9.x, (r)hr42.x, hr0.w, (r)(last)hr9.x
(rpt1)mad.f16 hr9.z, (r)hr42.z, hr0.w, (r)(last)hr9.z
(rpt1)mad.f16 hr7.x, (r)hr42.x, hr1.x, (r)(last)hr7.x
(rpt1)mad.f16 hr7.z, (r)hr42.z, hr1.x, (r)(last)hr7.z
(rpt1)mad.f16 hr42.x, (r)(last)hr42.x, hr1.y, (r)(last)hr5.x
(rpt1)mad.f16 hr42.z, (r)(last)hr42.z, hr1.y, (r)(last)hr5.z
isam.v.base0 (u16)(xyzw)hr5.x, r20.x, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr39.y, r20.y, s#0, t#2
mad.f16 hr34.x, hr44.x, hr41.x, (last)hr34.x
mad.f16 hr32.x, hr44.x, hr41.y, (last)hr32.x
mad.f16 hr30.x, hr44.x, hr41.z, (last)hr30.x
mad.f16 hr28.x, hr44.x, hr41.w, (last)hr28.x
mad.f16 hr34.y, hr44.y, hr41.x, (last)hr34.y
mad.f16 hr32.y, hr44.y, hr41.y, (last)hr32.y
mad.f16 hr30.y, hr44.y, hr41.z, (last)hr30.y
mad.f16 hr28.y, hr44.y, hr41.w, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr44.z, hr41.x, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr44.z, hr41.y, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr44.z, hr41.z, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr44.z, hr41.w, (r)(last)hr28.z
mad.f16 hr26.x, hr44.x, hr43.x, (last)hr26.x
mad.f16 hr24.x, hr44.x, hr43.y, (last)hr24.x
mad.f16 hr22.x, hr44.x, hr43.z, (last)hr22.x
mad.f16 hr20.x, hr44.x, hr43.w, (last)hr20.x
mad.f16 hr26.y, hr44.y, hr43.x, (last)hr26.y
mad.f16 hr24.y, hr44.y, hr43.y, (last)hr24.y
mad.f16 hr22.y, hr44.y, hr43.z, (last)hr22.y
mad.f16 hr20.y, hr44.y, hr43.w, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr44.z, hr43.x, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr44.z, hr43.y, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr44.z, hr43.z, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr44.z, hr43.w, (r)(last)hr20.z
(rpt1)mad.f16 hr18.x, (r)hr44.x, hr45.x, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr44.z, hr45.x, (r)(last)hr18.z
(rpt1)mad.f16 hr10.x, (r)hr44.x, hr0.z, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr44.z, hr0.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr44.x, hr0.w, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr44.z, hr0.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr44.x, hr1.x, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr44.z, hr1.x, (r)(last)hr6.z
mad.f16 hr35.x, hr36.y, hr37.y, (last)hr35.x
mad.f16 hr33.x, hr36.y, hr37.z, (last)hr33.x
mad.f16 hr31.x, hr36.y, hr37.w, (last)hr31.x
mad.f16 hr29.x, hr36.y, hr38.x, (last)hr29.x
mad.f16 hr35.y, hr36.z, hr37.y, (last)hr35.y
mad.f16 hr33.y, hr36.z, hr37.z, (last)hr33.y
mad.f16 hr31.y, hr36.z, hr37.w, (last)hr31.y
mad.f16 hr29.y, hr36.z, hr38.x, (last)hr29.y
mad.f16 hr35.z, hr36.w, hr37.y, (last)hr35.z
mad.f16 hr33.z, hr36.w, hr37.z, (last)hr33.z
mad.f16 hr31.z, hr36.w, hr37.w, (last)hr31.z
mad.f16 hr29.z, hr36.w, hr38.x, (last)hr29.z
mad.f16 hr35.w, hr37.x, hr37.y, (last)hr35.w
mad.f16 hr33.w, hr37.x, hr37.z, (last)hr33.w
mad.f16 hr31.w, hr37.x, hr37.w, (last)hr31.w
mad.f16 hr29.w, hr37.x, hr38.x, (last)hr29.w
(rpt1)mad.f16 hr27.x, (r)hr36.y, hr38.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr36.w, hr38.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr36.y, hr38.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr36.w, hr38.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr36.y, hr38.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr36.w, hr38.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr36.y, hr39.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr36.w, hr39.x, (r)(last)hr21.z
(sy)mad.f16 hr34.x, hr45.y, hr37.y, (last)hr34.x
mad.f16 hr32.x, hr45.y, hr37.z, (last)hr32.x
mad.f16 hr30.x, hr45.y, hr37.w, (last)hr30.x
mad.f16 hr28.x, hr45.y, hr38.x, (last)hr28.x
mad.f16 hr34.y, hr45.z, hr37.y, (last)hr34.y
mad.f16 hr32.y, hr45.z, hr37.z, (last)hr32.y
mad.f16 hr30.y, hr45.z, hr37.w, (last)hr30.y
mad.f16 hr28.y, hr45.z, hr38.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr45.w, hr37.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr45.w, hr37.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr45.w, hr37.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr45.w, hr38.x, (r)(last)hr28.z
mad.f16 hr26.x, hr45.y, hr38.y, (last)hr26.x
mad.f16 hr24.x, hr45.y, hr38.z, (last)hr24.x
mad.f16 hr22.x, hr45.y, hr38.w, (last)hr22.x
mad.f16 hr20.x, hr45.y, hr39.x, (last)hr20.x
mad.f16 hr26.y, hr45.z, hr38.y, (last)hr26.y
mad.f16 hr24.y, hr45.z, hr38.z, (last)hr24.y
mad.f16 hr22.y, hr45.z, hr38.w, (last)hr22.y
mad.f16 hr20.y, hr45.z, hr39.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr45.w, hr38.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr45.w, hr38.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr45.w, hr38.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr45.w, hr39.x, (r)(last)hr20.z
(rpt1)mad.f16 hr44.x, (r)(last)hr44.x, hr1.y, (r)(last)hr4.x
(rpt1)mad.f16 hr44.z, (r)(last)hr44.z, hr1.y, (r)(last)hr4.z
ldl.u16 r0.z, l[r1.z+384], 4
ldl.u16 r4.x, l[r1.z+448], 4
ldl.u16 r37.y, l[r1.z+512], 4
ldl.u16 r38.y, l[r1.z+576], 4
ldl.u16 r40.y, l[r1.z+640], 4
(ss)mad.f16 hr19.x, hr36.y, hr0.z, (last)hr19.x
mad.f16 hr17.x, hr36.y, hr0.w, (last)hr17.x
mad.f16 hr15.x, hr36.y, hr1.x, (last)hr15.x
mad.f16 hr13.x, hr36.y, hr1.y, (last)hr13.x
mad.f16 hr11.x, hr36.y, hr4.x, (last)hr11.x
mad.f16 hr9.x, hr36.y, hr4.y, (last)hr9.x
mad.f16 hr7.x, hr36.y, hr4.z, (last)hr7.x
mad.f16 hr36.y, (last)hr36.y, hr4.w, (last)hr42.x
ldl.u16 r41.y, l[r1.z+704], 4
(rpt1)mad.f16 hr18.x, (r)hr45.y, hr0.z, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr45.w, hr0.z, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr45.y, hr0.w, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr45.w, hr0.w, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr45.y, hr1.x, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr45.w, hr1.x, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr45.y, hr1.y, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr45.w, hr1.y, (r)(last)hr12.z
(rpt1)mad.f16 hr10.x, (r)hr45.y, hr4.x, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr45.w, hr4.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr45.y, hr4.y, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr45.w, hr4.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr45.y, hr4.z, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr45.w, hr4.z, (r)(last)hr6.z
mad.f16 hr45.y, (last)hr45.y, hr4.w, (last)hr44.x
ldl.u16 r43.y, l[r1.z+768], 4
mad.f16 hr45.z, (last)hr45.z, hr4.w, (last)hr44.y
(rpt1)mad.f16 hr45.w, (r)(last)hr45.w, hr4.w, (r)(last)hr44.z
ldl.u16 r44.y, l[r1.z+832], 4
mad.f16 hr19.y, hr36.z, hr0.z, (last)hr19.y
(rpt1)mad.f16 hr19.z, (r)hr36.w, hr0.z, (r)(last)hr19.z
mad.f16 hr17.y, hr36.z, hr0.w, (last)hr17.y
(rpt1)mad.f16 hr17.z, (r)hr36.w, hr0.w, (r)(last)hr17.z
mad.f16 hr15.y, hr36.z, hr1.x, (last)hr15.y
(rpt1)mad.f16 hr15.z, (r)hr36.w, hr1.x, (r)(last)hr15.z
mad.f16 hr13.y, hr36.z, hr1.y, (last)hr13.y
(rpt1)mad.f16 hr13.z, (r)hr36.w, hr1.y, (r)(last)hr13.z
mad.f16 hr11.y, hr36.z, hr4.x, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr36.w, hr4.x, (r)(last)hr11.z
mad.f16 hr9.y, hr36.z, hr4.y, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr36.w, hr4.y, (r)(last)hr9.z
mad.f16 hr7.y, hr36.z, hr4.z, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr36.w, hr4.z, (r)(last)hr7.z
mad.f16 hr34.x, hr39.y, hr37.y, (last)hr34.x
mad.f16 hr32.x, hr39.y, hr37.z, (last)hr32.x
mad.f16 hr30.x, hr39.y, hr37.w, (last)hr30.x
mad.f16 hr28.x, hr39.y, hr38.x, (last)hr28.x
mad.f16 hr34.y, hr39.z, hr37.y, (last)hr34.y
mad.f16 hr32.y, hr39.z, hr37.z, (last)hr32.y
mad.f16 hr30.y, hr39.z, hr37.w, (last)hr30.y
mad.f16 hr28.y, hr39.z, hr38.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr39.w, hr37.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr39.w, hr37.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr39.w, hr37.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr39.w, hr38.x, (r)(last)hr28.z
mad.f16 hr26.x, hr39.y, hr38.y, (last)hr26.x
mad.f16 hr24.x, hr39.y, hr38.z, (last)hr24.x
mad.f16 hr22.x, hr39.y, hr38.w, (last)hr22.x
mad.f16 hr20.x, hr39.y, hr39.x, (last)hr20.x
mad.f16 hr26.y, hr39.z, hr38.y, (last)hr26.y
mad.f16 hr24.y, hr39.z, hr38.z, (last)hr24.y
mad.f16 hr22.y, hr39.z, hr38.w, (last)hr22.y
mad.f16 hr20.y, hr39.z, hr39.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr39.w, hr38.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr39.w, hr38.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr39.w, hr38.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr39.w, hr39.x, (r)(last)hr20.z
(rpt1)mad.f16 hr18.x, (r)hr39.y, hr40.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr39.w, hr40.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr39.y, hr40.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr39.w, hr40.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr39.y, hr40.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr39.w, hr40.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr39.y, hr41.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr39.w, hr41.x, (r)(last)hr12.z
(ss)(rpt1)mad.f16 hr10.x, (r)hr39.y, hr41.y, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr39.w, hr41.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr39.y, hr41.z, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr39.w, hr41.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr39.y, hr41.w, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr39.w, hr41.w, (r)(last)hr6.z
mad.f16 hr36.z, (last)hr36.z, hr4.w, (last)hr42.y
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr4.w, (r)(last)hr42.z
isam.v.base0 (u16)(xyzw)hr42.y, r23.z, s#0, t#2
(rpt1)mad.f16 hr39.y, (r)(last)hr39.y, hr42.x, (r)(last)hr45.y
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr42.x, (r)(last)hr45.w
isam.v.base0 (u16)(xyzw)hr45.y, r23.w, s#0, t#2
(ss)nop
ldl.u16 r47.x, l[r1.z+896], 4
ldl.u16 r0.z, l[r1.z+960], 4
(rpt1)mad.f16 hr35.x, (r)hr5.x, hr37.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr5.z, hr37.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr5.x, hr37.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr5.z, hr37.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr5.x, hr37.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr5.z, hr37.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr5.x, hr38.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr5.z, hr38.x, (r)(last)hr29.z
ldl.u16 r37.y, l[r1.z+1024], 4
(rpt1)mad.f16 hr27.x, (r)hr5.x, hr38.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr5.z, hr38.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr5.x, hr38.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr5.z, hr38.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr5.x, hr38.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr5.z, hr38.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr5.x, hr39.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr5.z, hr39.x, (r)(last)hr21.z
ldl.u16 r38.y, l[r1.z+1088], 4
mad.f16 hr19.x, hr5.x, hr40.y, (last)hr19.x
mad.f16 hr17.x, hr5.x, hr40.z, (last)hr17.x
mad.f16 hr15.x, hr5.x, hr40.w, (last)hr15.x
mad.f16 hr13.x, hr5.x, hr41.x, (last)hr13.x
mad.f16 hr11.x, hr5.x, hr41.y, (last)hr11.x
mad.f16 hr9.x, hr5.x, hr41.z, (last)hr9.x
mad.f16 hr7.x, hr5.x, hr41.w, (last)hr7.x
mad.f16 hr19.y, hr5.y, hr40.y, (last)hr19.y
(rpt1)mad.f16 hr19.z, (r)hr5.z, hr40.y, (r)(last)hr19.z
mad.f16 hr17.y, hr5.y, hr40.z, (last)hr17.y
(rpt1)mad.f16 hr17.z, (r)hr5.z, hr40.z, (r)(last)hr17.z
mad.f16 hr15.y, hr5.y, hr40.w, (last)hr15.y
(rpt1)mad.f16 hr15.z, (r)hr5.z, hr40.w, (r)(last)hr15.z
mad.f16 hr13.y, hr5.y, hr41.x, (last)hr13.y
(rpt1)mad.f16 hr13.z, (r)hr5.z, hr41.x, (r)(last)hr13.z
ldl.u16 r40.y, l[r1.z+1152], 4
mad.f16 hr11.y, hr5.y, hr41.y, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr5.z, hr41.y, (r)(last)hr11.z
mad.f16 hr9.y, hr5.y, hr41.z, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr5.z, hr41.z, (r)(last)hr9.z
mad.f16 hr7.y, hr5.y, hr41.w, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr5.z, hr41.w, (r)(last)hr7.z
(sy)mad.f16 hr34.x, hr45.y, hr43.y, (last)hr34.x
mad.f16 hr32.x, hr45.y, hr43.z, (last)hr32.x
mad.f16 hr30.x, hr45.y, hr43.w, (last)hr30.x
mad.f16 hr28.x, hr45.y, hr44.x, (last)hr28.x
mad.f16 hr26.x, hr45.y, hr44.y, (last)hr26.x
mad.f16 hr24.x, hr45.y, hr44.z, (last)hr24.x
mad.f16 hr22.x, hr45.y, hr44.w, (last)hr22.x
mad.f16 hr20.x, hr45.y, hr45.x, (last)hr20.x
mad.f16 hr34.y, hr45.z, hr43.y, (last)hr34.y
mad.f16 hr32.y, hr45.z, hr43.z, (last)hr32.y
mad.f16 hr30.y, hr45.z, hr43.w, (last)hr30.y
mad.f16 hr28.y, hr45.z, hr44.x, (last)hr28.y
mad.f16 hr26.y, hr45.z, hr44.y, (last)hr26.y
mad.f16 hr24.y, hr45.z, hr44.z, (last)hr24.y
mad.f16 hr22.y, hr45.z, hr44.w, (last)hr22.y
mad.f16 hr20.y, hr45.z, hr45.x, (last)hr20.y
(rpt1)mad.f16 hr34.z, (r)hr45.w, hr43.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr45.w, hr43.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr45.w, hr43.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr45.w, hr44.x, (r)(last)hr28.z
(rpt1)mad.f16 hr26.z, (r)hr45.w, hr44.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr45.w, hr44.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr45.w, hr44.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr45.w, hr45.x, (r)(last)hr20.z
(ss)(rpt1)mad.f16 hr18.x, (r)hr45.y, hr47.x, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr45.w, hr47.x, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr45.y, hr47.y, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr45.w, hr47.y, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr45.y, hr47.z, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr45.w, hr47.z, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr45.y, hr47.w, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr45.w, hr47.w, (r)(last)hr12.z
(rpt1)mad.f16 hr10.x, (r)hr45.y, hr0.z, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr45.w, hr0.z, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr45.y, hr0.w, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr45.w, hr0.w, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr45.y, hr1.x, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr45.w, hr1.x, (r)(last)hr6.z
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr42.x, (r)(last)hr36.y
(rpt1)mad.f16 hr5.z, (r)(last)hr5.z, hr42.x, (r)(last)hr36.w
isam.v.base0 (u16)(xyzw)hr36.y, r24.x, s#0, t#2
ldl.u16 r41.y, l[r1.z+1216], 4
(rpt1)mad.f16 hr45.y, (r)(last)hr45.y, hr1.y, (r)(last)hr39.y
(rpt1)mad.f16 hr45.w, (r)(last)hr45.w, hr1.y, (r)(last)hr39.w
isam.v.base0 (u16)(xyzw)hr39.y, r24.y, s#0, t#2
(rpt1)mad.f16 hr35.x, (r)hr42.y, hr43.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr42.w, hr43.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr42.y, hr43.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr42.w, hr43.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr42.y, hr43.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr42.w, hr43.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr42.y, hr44.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr42.w, hr44.x, (r)(last)hr29.z
isam.v.base0 (u16)(xyzw)hr43.y, r24.z, s#0, t#2
mad.f16 hr27.x, hr42.y, hr44.y, (last)hr27.x
mad.f16 hr25.x, hr42.y, hr44.z, (last)hr25.x
mad.f16 hr23.x, hr42.y, hr44.w, (last)hr23.x
mad.f16 hr21.x, hr42.y, hr45.x, (last)hr21.x
mad.f16 hr19.x, hr42.y, hr47.x, (last)hr19.x
mad.f16 hr17.x, hr42.y, hr47.y, (last)hr17.x
mad.f16 hr15.x, hr42.y, hr47.z, (last)hr15.x
mad.f16 hr13.x, hr42.y, hr47.w, (last)hr13.x
mad.f16 hr11.x, hr42.y, hr0.z, (last)hr11.x
mad.f16 hr9.x, hr42.y, hr0.w, (last)hr9.x
mad.f16 hr7.x, hr42.y, hr1.x, (last)hr7.x
mad.f16 hr42.y, (last)hr42.y, hr1.y, (last)hr5.x
isam.v.base0 (u16)(xyzw)hr4.y, r24.w, s#0, t#2
mad.f16 hr27.y, hr42.z, hr44.y, (last)hr27.y
(rpt1)mad.f16 hr27.z, (r)hr42.w, hr44.y, (r)(last)hr27.z
mad.f16 hr25.y, hr42.z, hr44.z, (last)hr25.y
(rpt1)mad.f16 hr25.z, (r)hr42.w, hr44.z, (r)(last)hr25.z
mad.f16 hr23.y, hr42.z, hr44.w, (last)hr23.y
(rpt1)mad.f16 hr23.z, (r)hr42.w, hr44.w, (r)(last)hr23.z
mad.f16 hr21.y, hr42.z, hr45.x, (last)hr21.y
(rpt1)mad.f16 hr21.z, (r)hr42.w, hr45.x, (r)(last)hr21.z
ldl.u16 r44.y, l[r1.z+1280], 4
mad.f16 hr19.y, hr42.z, hr47.x, (last)hr19.y
(rpt1)mad.f16 hr19.z, (r)hr42.w, hr47.x, (r)(last)hr19.z
mad.f16 hr17.y, hr42.z, hr47.y, (last)hr17.y
(rpt1)mad.f16 hr17.z, (r)hr42.w, hr47.y, (r)(last)hr17.z
mad.f16 hr15.y, hr42.z, hr47.z, (last)hr15.y
(rpt1)mad.f16 hr15.z, (r)hr42.w, hr47.z, (r)(last)hr15.z
mad.f16 hr13.y, hr42.z, hr47.w, (last)hr13.y
(rpt1)mad.f16 hr13.z, (r)hr42.w, hr47.w, (r)(last)hr13.z
mad.f16 hr11.y, hr42.z, hr0.z, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr42.w, hr0.z, (r)(last)hr11.z
mad.f16 hr9.y, hr42.z, hr0.w, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr42.w, hr0.w, (r)(last)hr9.z
mad.f16 hr7.y, hr42.z, hr1.x, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr42.w, hr1.x, (r)(last)hr7.z
mad.f16 hr42.z, (last)hr42.z, hr1.y, (last)hr5.y
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr1.y, (r)(last)hr5.z
(sy)mad.f16 hr34.x, hr39.y, hr37.y, (last)hr34.x
mad.f16 hr32.x, hr39.y, hr37.z, (last)hr32.x
mad.f16 hr30.x, hr39.y, hr37.w, (last)hr30.x
mad.f16 hr28.x, hr39.y, hr38.x, (last)hr28.x
mad.f16 hr34.y, hr39.z, hr37.y, (last)hr34.y
mad.f16 hr32.y, hr39.z, hr37.z, (last)hr32.y
mad.f16 hr30.y, hr39.z, hr37.w, (last)hr30.y
mad.f16 hr28.y, hr39.z, hr38.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr39.w, hr37.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr39.w, hr37.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr39.w, hr37.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr39.w, hr38.x, (r)(last)hr28.z
(rpt1)mad.f16 hr35.x, (r)hr36.y, hr37.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr36.w, hr37.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr36.y, hr37.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr36.w, hr37.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr36.y, hr37.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr36.w, hr37.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr36.y, hr38.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr36.w, hr38.x, (r)(last)hr29.z
(rpt1)mad.f16 hr18.x, (r)hr39.y, hr40.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr39.w, hr40.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr39.y, hr40.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr39.w, hr40.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr39.y, hr40.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr39.w, hr40.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr39.y, hr41.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr39.w, hr41.x, (r)(last)hr12.z
mad.f16 hr19.x, hr36.y, hr40.y, (last)hr19.x
mad.f16 hr17.x, hr36.y, hr40.z, (last)hr17.x
mad.f16 hr15.x, hr36.y, hr40.w, (last)hr15.x
mad.f16 hr13.x, hr36.y, hr41.x, (last)hr13.x
mad.f16 hr19.y, hr36.z, hr40.y, (last)hr19.y
(rpt1)mad.f16 hr19.z, (r)hr36.w, hr40.y, (r)(last)hr19.z
mad.f16 hr17.y, hr36.z, hr40.z, (last)hr17.y
(rpt1)mad.f16 hr17.z, (r)hr36.w, hr40.z, (r)(last)hr17.z
mad.f16 hr15.y, hr36.z, hr40.w, (last)hr15.y
(rpt1)mad.f16 hr15.z, (r)hr36.w, hr40.w, (r)(last)hr15.z
mad.f16 hr13.y, hr36.z, hr41.x, (last)hr13.y
(rpt1)mad.f16 hr13.z, (r)hr36.w, hr41.x, (r)(last)hr13.z
isam.v.base0 (u16)(xyzw)hr40.y, r25.x, s#0, t#2
(ss)mad.f16 hr34.x, hr4.y, hr44.y, (last)hr34.x
mad.f16 hr32.x, hr4.y, hr44.z, (last)hr32.x
mad.f16 hr30.x, hr4.y, hr44.w, (last)hr30.x
mad.f16 hr28.x, hr4.y, hr45.x, (last)hr28.x
mad.f16 hr34.y, hr4.z, hr44.y, (last)hr34.y
mad.f16 hr32.y, hr4.z, hr44.z, (last)hr32.y
mad.f16 hr30.y, hr4.z, hr44.w, (last)hr30.y
mad.f16 hr28.y, hr4.z, hr45.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr4.w, hr44.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr4.w, hr44.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr4.w, hr44.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr4.w, hr45.x, (r)(last)hr28.z
(rpt1)mad.f16 hr35.x, (r)hr43.y, hr44.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr43.w, hr44.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr43.y, hr44.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr43.w, hr44.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr43.y, hr44.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr43.w, hr44.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr43.y, hr45.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr43.w, hr45.x, (r)(last)hr29.z
isam.v.base0 (u16)(xyzw)hr44.y, r25.y, s#0, t#2
mad.f16 hr26.x, hr39.y, hr38.y, (last)hr26.x
mad.f16 hr24.x, hr39.y, hr38.z, (last)hr24.x
mad.f16 hr22.x, hr39.y, hr38.w, (last)hr22.x
mad.f16 hr20.x, hr39.y, hr39.x, (last)hr20.x
mad.f16 hr26.y, hr39.z, hr38.y, (last)hr26.y
mad.f16 hr24.y, hr39.z, hr38.z, (last)hr24.y
mad.f16 hr22.y, hr39.z, hr38.w, (last)hr22.y
mad.f16 hr20.y, hr39.z, hr39.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr39.w, hr38.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr39.w, hr38.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr39.w, hr38.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr39.w, hr39.x, (r)(last)hr20.z
(rpt1)mad.f16 hr10.x, (r)hr39.y, hr41.y, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr39.w, hr41.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr39.y, hr41.z, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr39.w, hr41.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr39.y, hr41.w, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr39.w, hr41.w, (r)(last)hr6.z
mad.f16 hr27.x, hr36.y, hr38.y, (last)hr27.x
mad.f16 hr25.x, hr36.y, hr38.z, (last)hr25.x
mad.f16 hr23.x, hr36.y, hr38.w, (last)hr23.x
mad.f16 hr21.x, hr36.y, hr39.x, (last)hr21.x
mad.f16 hr27.y, hr36.z, hr38.y, (last)hr27.y
(rpt1)mad.f16 hr27.z, (r)hr36.w, hr38.y, (r)(last)hr27.z
mad.f16 hr25.y, hr36.z, hr38.z, (last)hr25.y
(rpt1)mad.f16 hr25.z, (r)hr36.w, hr38.z, (r)(last)hr25.z
mad.f16 hr23.y, hr36.z, hr38.w, (last)hr23.y
(rpt1)mad.f16 hr23.z, (r)hr36.w, hr38.w, (r)(last)hr23.z
mad.f16 hr21.y, hr36.z, hr39.x, (last)hr21.y
(rpt1)mad.f16 hr21.z, (r)hr36.w, hr39.x, (r)(last)hr21.z
(rpt1)mad.f16 hr39.y, (r)(last)hr39.y, hr42.x, (r)(last)hr45.y
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr42.x, (r)(last)hr45.w
ldl.u16 r45.y, l[r1.z+1344], 4
ldl.u16 r37.y, l[r1.z+1408], 4
ldl.u16 r38.y, l[r1.z+1472], 4
mad.f16 hr11.x, hr36.y, hr41.y, (last)hr11.x
mad.f16 hr9.x, hr36.y, hr41.z, (last)hr9.x
mad.f16 hr7.x, hr36.y, hr41.w, (last)hr7.x
mad.f16 hr11.y, hr36.z, hr41.y, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr36.w, hr41.y, (r)(last)hr11.z
mad.f16 hr9.y, hr36.z, hr41.z, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr36.w, hr41.z, (r)(last)hr9.z
mad.f16 hr7.y, hr36.z, hr41.w, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr36.w, hr41.w, (r)(last)hr7.z
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr42.x, (r)(last)hr42.y
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr42.x, (r)(last)hr42.w
ldl.u16 r41.y, l[r1.z+1536], 4
ldl.u16 r42.y, l[r1.z+1600], 4
(ss)(rpt1)mad.f16 hr27.x, (r)hr43.y, hr45.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr43.w, hr45.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr43.y, hr45.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr43.w, hr45.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr43.y, hr45.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr43.w, hr45.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr43.y, hr46.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr43.w, hr46.x, (r)(last)hr21.z
mad.f16 hr26.x, hr4.y, hr45.y, (last)hr26.x
mad.f16 hr24.x, hr4.y, hr45.z, (last)hr24.x
mad.f16 hr22.x, hr4.y, hr45.w, (last)hr22.x
mad.f16 hr20.x, hr4.y, hr46.x, (last)hr20.x
mad.f16 hr26.y, hr4.z, hr45.y, (last)hr26.y
mad.f16 hr24.y, hr4.z, hr45.z, (last)hr24.y
mad.f16 hr22.y, hr4.z, hr45.w, (last)hr22.y
mad.f16 hr20.y, hr4.z, hr46.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr4.w, hr45.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr4.w, hr45.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr4.w, hr45.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr4.w, hr46.x, (r)(last)hr20.z
ldl.u16 r45.y, l[r1.z+1664], 4
ldl.u16 r47.x, l[r1.z+1728], 4
(rpt1)mad.f16 hr19.x, (r)hr43.y, hr37.y, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr43.w, hr37.y, (r)(last)hr19.z
(rpt1)mad.f16 hr18.x, (r)hr4.y, hr37.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr4.w, hr37.y, (r)(last)hr18.z
(rpt1)mad.f16 hr17.x, (r)hr43.y, hr37.z, (r)(last)hr17.x
(rpt1)mad.f16 hr17.z, (r)hr43.w, hr37.z, (r)(last)hr17.z
(rpt1)mad.f16 hr16.x, (r)hr4.y, hr37.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr4.w, hr37.z, (r)(last)hr16.z
(rpt1)mad.f16 hr15.x, (r)hr43.y, hr37.w, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr43.w, hr37.w, (r)(last)hr15.z
(rpt1)mad.f16 hr14.x, (r)hr4.y, hr37.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr4.w, hr37.w, (r)(last)hr14.z
(rpt1)mad.f16 hr13.x, (r)hr43.y, hr38.x, (r)(last)hr13.x
(rpt1)mad.f16 hr13.z, (r)hr43.w, hr38.x, (r)(last)hr13.z
(rpt1)mad.f16 hr12.x, (r)hr4.y, hr38.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr4.w, hr38.x, (r)(last)hr12.z
ldl.u16 r37.y, l[r1.z+1792], 4
(rpt1)mad.f16 hr10.x, (r)hr4.y, hr38.y, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr4.w, hr38.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr4.y, hr38.z, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr4.w, hr38.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr4.y, hr38.w, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr4.w, hr38.w, (r)(last)hr6.z
mad.f16 hr11.x, hr43.y, hr38.y, (last)hr11.x
mad.f16 hr9.x, hr43.y, hr38.z, (last)hr9.x
mad.f16 hr7.x, hr43.y, hr38.w, (last)hr7.x
mad.f16 hr11.y, hr43.z, hr38.y, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr43.w, hr38.y, (r)(last)hr11.z
mad.f16 hr9.y, hr43.z, hr38.z, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr43.w, hr38.z, (r)(last)hr9.z
mad.f16 hr7.y, hr43.z, hr38.w, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr43.w, hr38.w, (r)(last)hr7.z
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr39.x, (r)(last)hr39.y
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr39.x, (r)(last)hr39.w
(rpt1)mad.f16 hr43.y, (r)(last)hr43.y, hr39.x, (r)(last)hr36.y
(rpt1)mad.f16 hr43.w, (r)(last)hr43.w, hr39.x, (r)(last)hr36.w
isam.v.base0 (u16)(xyzw)hr36.y, r25.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr39.y, r25.w, s#0, t#2
ldl.u16 r38.y, l[r1.z+1856], 4
(sy)(rpt1)mad.f16 hr35.x, (r)hr40.y, hr41.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr40.w, hr41.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr40.y, hr41.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr40.w, hr41.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr40.y, hr41.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr40.w, hr41.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr40.y, hr42.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr40.w, hr42.x, (r)(last)hr29.z
mad.f16 hr34.x, hr44.y, hr41.y, (last)hr34.x
mad.f16 hr32.x, hr44.y, hr41.z, (last)hr32.x
mad.f16 hr30.x, hr44.y, hr41.w, (last)hr30.x
mad.f16 hr28.x, hr44.y, hr42.x, (last)hr28.x
mad.f16 hr34.y, hr44.z, hr41.y, (last)hr34.y
mad.f16 hr32.y, hr44.z, hr41.z, (last)hr32.y
mad.f16 hr30.y, hr44.z, hr41.w, (last)hr30.y
mad.f16 hr28.y, hr44.z, hr42.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr44.w, hr41.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr44.w, hr41.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr44.w, hr41.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr44.w, hr42.x, (r)(last)hr28.z
ldl.u16 r41.y, l[r1.z+1920], 4
(rpt1)mad.f16 hr27.x, (r)hr40.y, hr42.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr40.w, hr42.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr40.y, hr42.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr40.w, hr42.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr40.y, hr42.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr40.w, hr42.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr40.y, hr43.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr40.w, hr43.x, (r)(last)hr21.z
mad.f16 hr26.x, hr44.y, hr42.y, (last)hr26.x
mad.f16 hr24.x, hr44.y, hr42.z, (last)hr24.x
mad.f16 hr22.x, hr44.y, hr42.w, (last)hr22.x
mad.f16 hr20.x, hr44.y, hr43.x, (last)hr20.x
mad.f16 hr26.y, hr44.z, hr42.y, (last)hr26.y
mad.f16 hr24.y, hr44.z, hr42.z, (last)hr24.y
mad.f16 hr22.y, hr44.z, hr42.w, (last)hr22.y
mad.f16 hr20.y, hr44.z, hr43.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr44.w, hr42.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr44.w, hr42.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr44.w, hr42.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr44.w, hr43.x, (r)(last)hr20.z
ldl.u16 r42.y, l[r1.z+1984], 4
(ss)(rpt1)mad.f16 hr19.x, (r)hr40.y, hr45.y, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr40.w, hr45.y, (r)(last)hr19.z
(rpt1)mad.f16 hr18.x, (r)hr44.y, hr45.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr44.w, hr45.y, (r)(last)hr18.z
(rpt1)mad.f16 hr17.x, (r)hr40.y, hr45.z, (r)(last)hr17.x
(rpt1)mad.f16 hr17.z, (r)hr40.w, hr45.z, (r)(last)hr17.z
(rpt1)mad.f16 hr16.x, (r)hr44.y, hr45.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr44.w, hr45.z, (r)(last)hr16.z
(rpt1)mad.f16 hr15.x, (r)hr40.y, hr45.w, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr40.w, hr45.w, (r)(last)hr15.z
(rpt1)mad.f16 hr14.x, (r)hr44.y, hr45.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr44.w, hr45.w, (r)(last)hr14.z
(rpt1)mad.f16 hr13.x, (r)hr40.y, hr46.x, (r)(last)hr13.x
(rpt1)mad.f16 hr13.z, (r)hr40.w, hr46.x, (r)(last)hr13.z
(rpt1)mad.f16 hr12.x, (r)hr44.y, hr46.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr44.w, hr46.x, (r)(last)hr12.z
(rpt1)mad.f16 hr10.x, (r)hr44.y, hr47.x, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr44.w, hr47.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr44.y, hr47.y, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr44.w, hr47.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr44.y, hr47.z, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr44.w, hr47.z, (r)(last)hr6.z
mad.f16 hr11.x, hr40.y, hr47.x, (last)hr11.x
mad.f16 hr9.x, hr40.y, hr47.y, (last)hr9.x
mad.f16 hr7.x, hr40.y, hr47.z, (last)hr7.x
mad.f16 hr11.y, hr40.z, hr47.x, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr40.w, hr47.x, (r)(last)hr11.z
mad.f16 hr9.y, hr40.z, hr47.y, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr40.w, hr47.y, (r)(last)hr9.z
mad.f16 hr7.y, hr40.z, hr47.z, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr40.w, hr47.z, (r)(last)hr7.z
(rpt1)mad.f16 hr44.y, (r)(last)hr44.y, hr47.w, (r)(last)hr4.y
(rpt1)mad.f16 hr44.w, (r)(last)hr44.w, hr47.w, (r)(last)hr4.w
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr47.w, (r)(last)hr43.y
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr47.w, (r)(last)hr43.w
isam.v.base0 (u16)(xyzw)hr43.y, r26.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr4.y, r26.y, s#0, t#2
mad.f16 hr34.x, hr39.y, hr37.y, (last)hr34.x
mad.f16 hr32.x, hr39.y, hr37.z, (last)hr32.x
mad.f16 hr30.x, hr39.y, hr37.w, (last)hr30.x
mad.f16 hr28.x, hr39.y, hr38.x, (last)hr28.x
mad.f16 hr34.y, hr39.z, hr37.y, (last)hr34.y
mad.f16 hr32.y, hr39.z, hr37.z, (last)hr32.y
mad.f16 hr30.y, hr39.z, hr37.w, (last)hr30.y
mad.f16 hr28.y, hr39.z, hr38.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr39.w, hr37.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr39.w, hr37.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr39.w, hr37.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr39.w, hr38.x, (r)(last)hr28.z
mad.f16 hr26.x, hr39.y, hr38.y, (last)hr26.x
mad.f16 hr24.x, hr39.y, hr38.z, (last)hr24.x
mad.f16 hr22.x, hr39.y, hr38.w, (last)hr22.x
mad.f16 hr20.x, hr39.y, hr39.x, (last)hr20.x
mad.f16 hr26.y, hr39.z, hr38.y, (last)hr26.y
mad.f16 hr24.y, hr39.z, hr38.z, (last)hr24.y
mad.f16 hr22.y, hr39.z, hr38.w, (last)hr22.y
mad.f16 hr20.y, hr39.z, hr39.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr39.w, hr38.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr39.w, hr38.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr39.w, hr38.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr39.w, hr39.x, (r)(last)hr20.z
(rpt1)mad.f16 hr18.x, (r)hr39.y, hr41.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr39.w, hr41.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr39.y, hr41.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr39.w, hr41.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr39.y, hr41.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr39.w, hr41.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr39.y, hr42.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr39.w, hr42.x, (r)(last)hr12.z
(rpt1)mad.f16 hr10.x, (r)hr39.y, hr42.y, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr39.w, hr42.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr39.y, hr42.z, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr39.w, hr42.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr39.y, hr42.w, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr39.w, hr42.w, (r)(last)hr6.z
(rpt1)mad.f16 hr39.y, (r)(last)hr39.y, hr43.x, (r)(last)hr44.y
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr43.x, (r)(last)hr44.w
ldl.u16 r44.y, l[r1.z+2048], 4
ldl.u16 r45.y, l[r1.z+2112], 4
(rpt1)mad.f16 hr35.x, (r)hr36.y, hr37.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr36.w, hr37.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr36.y, hr37.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr36.w, hr37.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr36.y, hr37.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr36.w, hr37.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr36.y, hr38.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr36.w, hr38.x, (r)(last)hr29.z
ldl.u16 r37.y, l[r1.z+2176], 4
(rpt1)mad.f16 hr27.x, (r)hr36.y, hr38.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr36.w, hr38.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr36.y, hr38.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr36.w, hr38.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr36.y, hr38.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr36.w, hr38.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr36.y, hr39.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr36.w, hr39.x, (r)(last)hr21.z
ldl.u16 r38.y, l[r1.z+2240], 4
(rpt1)mad.f16 hr19.x, (r)hr36.y, hr41.y, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr36.w, hr41.y, (r)(last)hr19.z
(rpt1)mad.f16 hr17.x, (r)hr36.y, hr41.z, (r)(last)hr17.x
(rpt1)mad.f16 hr17.z, (r)hr36.w, hr41.z, (r)(last)hr17.z
(rpt1)mad.f16 hr15.x, (r)hr36.y, hr41.w, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr36.w, hr41.w, (r)(last)hr15.z
(rpt1)mad.f16 hr13.x, (r)hr36.y, hr42.x, (r)(last)hr13.x
(rpt1)mad.f16 hr13.z, (r)hr36.w, hr42.x, (r)(last)hr13.z
ldl.u16 r41.y, l[r1.z+2304], 4
mad.f16 hr11.x, hr36.y, hr42.y, (last)hr11.x
mad.f16 hr9.x, hr36.y, hr42.z, (last)hr9.x
mad.f16 hr7.x, hr36.y, hr42.w, (last)hr7.x
mad.f16 hr11.y, hr36.z, hr42.y, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr36.w, hr42.y, (r)(last)hr11.z
mad.f16 hr9.y, hr36.z, hr42.z, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr36.w, hr42.z, (r)(last)hr9.z
mad.f16 hr7.y, hr36.z, hr42.w, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr36.w, hr42.w, (r)(last)hr7.z
(sy)(ss)mad.f16 hr34.x, hr4.y, hr44.y, (last)hr34.x
mad.f16 hr32.x, hr4.y, hr44.z, (last)hr32.x
mad.f16 hr30.x, hr4.y, hr44.w, (last)hr30.x
mad.f16 hr28.x, hr4.y, hr45.x, (last)hr28.x
mad.f16 hr34.y, hr4.z, hr44.y, (last)hr34.y
mad.f16 hr32.y, hr4.z, hr44.z, (last)hr32.y
mad.f16 hr30.y, hr4.z, hr44.w, (last)hr30.y
mad.f16 hr28.y, hr4.z, hr45.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr4.w, hr44.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr4.w, hr44.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr4.w, hr44.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr4.w, hr45.x, (r)(last)hr28.z
(rpt1)mad.f16 hr35.x, (r)hr43.y, hr44.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr43.w, hr44.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr43.y, hr44.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr43.w, hr44.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr43.y, hr44.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr43.w, hr44.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr43.y, hr45.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr43.w, hr45.x, (r)(last)hr29.z
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr43.x, (r)(last)hr40.y
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr43.x, (r)(last)hr40.w
isam.v.base0 (u16)(xyzw)hr40.y, r26.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr44.y, r26.w, s#0, t#2
ldl.u16 r42.y, l[r1.z+2368], 4
mad.f16 hr26.x, hr4.y, hr45.y, (last)hr26.x
mad.f16 hr24.x, hr4.y, hr45.z, (last)hr24.x
mad.f16 hr22.x, hr4.y, hr45.w, (last)hr22.x
mad.f16 hr20.x, hr4.y, hr46.x, (last)hr20.x
mad.f16 hr26.y, hr4.z, hr45.y, (last)hr26.y
mad.f16 hr24.y, hr4.z, hr45.z, (last)hr24.y
mad.f16 hr22.y, hr4.z, hr45.w, (last)hr22.y
mad.f16 hr20.y, hr4.z, hr46.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr4.w, hr45.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr4.w, hr45.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr4.w, hr45.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr4.w, hr46.x, (r)(last)hr20.z
(rpt1)mad.f16 hr18.x, (r)hr4.y, hr37.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr4.w, hr37.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr4.y, hr37.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr4.w, hr37.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr4.y, hr37.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr4.w, hr37.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr4.y, hr38.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr4.w, hr38.x, (r)(last)hr12.z
(rpt1)mad.f16 hr27.x, (r)hr43.y, hr45.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr43.w, hr45.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr43.y, hr45.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr43.w, hr45.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr43.y, hr45.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr43.w, hr45.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr43.y, hr46.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr43.w, hr46.x, (r)(last)hr21.z
ldl.u16 r45.y, l[r1.z+2432], 4
ldl.u16 r47.x, l[r1.z+2496], 4
(rpt1)mad.f16 hr10.x, (r)hr4.y, hr38.y, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr4.w, hr38.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr4.y, hr38.z, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr4.w, hr38.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr4.y, hr38.w, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr4.w, hr38.w, (r)(last)hr6.z
(rpt1)mad.f16 hr19.x, (r)hr43.y, hr37.y, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr43.w, hr37.y, (r)(last)hr19.z
(rpt1)mad.f16 hr17.x, (r)hr43.y, hr37.z, (r)(last)hr17.x
(rpt1)mad.f16 hr17.z, (r)hr43.w, hr37.z, (r)(last)hr17.z
(rpt1)mad.f16 hr15.x, (r)hr43.y, hr37.w, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr43.w, hr37.w, (r)(last)hr15.z
(rpt1)mad.f16 hr13.x, (r)hr43.y, hr38.x, (r)(last)hr13.x
(rpt1)mad.f16 hr13.z, (r)hr43.w, hr38.x, (r)(last)hr13.z
ldl.u16 r37.y, l[r1.z+2560], 4
mad.f16 hr11.x, hr43.y, hr38.y, (last)hr11.x
mad.f16 hr9.x, hr43.y, hr38.z, (last)hr9.x
mad.f16 hr7.x, hr43.y, hr38.w, (last)hr7.x
mad.f16 hr11.y, hr43.z, hr38.y, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr43.w, hr38.y, (r)(last)hr11.z
mad.f16 hr9.y, hr43.z, hr38.z, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr43.w, hr38.z, (r)(last)hr9.z
mad.f16 hr7.y, hr43.z, hr38.w, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr43.w, hr38.w, (r)(last)hr7.z
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr39.x, (r)(last)hr39.y
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr39.x, (r)(last)hr39.w
(rpt1)mad.f16 hr43.y, (r)(last)hr43.y, hr39.x, (r)(last)hr36.y
(rpt1)mad.f16 hr43.w, (r)(last)hr43.w, hr39.x, (r)(last)hr36.w
isam.v.base0 (u16)(xyzw)hr36.y, r27.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr39.y, r27.y, s#0, t#2
ldl.u16 r38.y, l[r1.z+2624], 4
(sy)(rpt1)mad.f16 hr35.x, (r)hr40.y, hr41.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr40.w, hr41.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr40.y, hr41.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr40.w, hr41.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr40.y, hr41.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr40.w, hr41.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr40.y, hr42.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr40.w, hr42.x, (r)(last)hr29.z
mad.f16 hr34.x, hr44.y, hr41.y, (last)hr34.x
mad.f16 hr32.x, hr44.y, hr41.z, (last)hr32.x
mad.f16 hr30.x, hr44.y, hr41.w, (last)hr30.x
mad.f16 hr28.x, hr44.y, hr42.x, (last)hr28.x
mad.f16 hr34.y, hr44.z, hr41.y, (last)hr34.y
mad.f16 hr32.y, hr44.z, hr41.z, (last)hr32.y
mad.f16 hr30.y, hr44.z, hr41.w, (last)hr30.y
mad.f16 hr28.y, hr44.z, hr42.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr44.w, hr41.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr44.w, hr41.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr44.w, hr41.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr44.w, hr42.x, (r)(last)hr28.z
ldl.u16 r41.y, l[r1.z+2688], 4
(ss)mad.f16 hr26.x, hr44.y, hr42.y, (last)hr26.x
mad.f16 hr24.x, hr44.y, hr42.z, (last)hr24.x
mad.f16 hr22.x, hr44.y, hr42.w, (last)hr22.x
mad.f16 hr20.x, hr44.y, hr43.x, (last)hr20.x
mad.f16 hr26.y, hr44.z, hr42.y, (last)hr26.y
mad.f16 hr24.y, hr44.z, hr42.z, (last)hr24.y
mad.f16 hr22.y, hr44.z, hr42.w, (last)hr22.y
mad.f16 hr20.y, hr44.z, hr43.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr44.w, hr42.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr44.w, hr42.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr44.w, hr42.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr44.w, hr43.x, (r)(last)hr20.z
(rpt1)mad.f16 hr27.x, (r)hr40.y, hr42.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr40.w, hr42.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr40.y, hr42.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr40.w, hr42.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr40.y, hr42.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr40.w, hr42.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr40.y, hr43.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr40.w, hr43.x, (r)(last)hr21.z
ldl.u16 r42.y, l[r1.z+2752], 4
(rpt1)mad.f16 hr18.x, (r)hr44.y, hr45.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr44.w, hr45.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr44.y, hr45.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr44.w, hr45.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr44.y, hr45.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr44.w, hr45.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr44.y, hr46.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr44.w, hr46.x, (r)(last)hr12.z
(rpt1)mad.f16 hr10.x, (r)hr44.y, hr47.x, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr44.w, hr47.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr44.y, hr47.y, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr44.w, hr47.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr44.y, hr47.z, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr44.w, hr47.z, (r)(last)hr6.z
(rpt1)mad.f16 hr19.x, (r)hr40.y, hr45.y, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr40.w, hr45.y, (r)(last)hr19.z
(rpt1)mad.f16 hr17.x, (r)hr40.y, hr45.z, (r)(last)hr17.x
(rpt1)mad.f16 hr17.z, (r)hr40.w, hr45.z, (r)(last)hr17.z
(rpt1)mad.f16 hr15.x, (r)hr40.y, hr45.w, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr40.w, hr45.w, (r)(last)hr15.z
(rpt1)mad.f16 hr13.x, (r)hr40.y, hr46.x, (r)(last)hr13.x
(rpt1)mad.f16 hr13.z, (r)hr40.w, hr46.x, (r)(last)hr13.z
mad.f16 hr11.x, hr40.y, hr47.x, (last)hr11.x
mad.f16 hr9.x, hr40.y, hr47.y, (last)hr9.x
mad.f16 hr7.x, hr40.y, hr47.z, (last)hr7.x
mad.f16 hr11.y, hr40.z, hr47.x, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr40.w, hr47.x, (r)(last)hr11.z
mad.f16 hr9.y, hr40.z, hr47.y, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr40.w, hr47.y, (r)(last)hr9.z
mad.f16 hr7.y, hr40.z, hr47.z, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr40.w, hr47.z, (r)(last)hr7.z
(rpt1)mad.f16 hr44.y, (r)(last)hr44.y, hr47.w, (r)(last)hr4.y
(rpt1)mad.f16 hr44.w, (r)(last)hr44.w, hr47.w, (r)(last)hr4.w
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr47.w, (r)(last)hr43.y
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr47.w, (r)(last)hr43.w
isam.v.base0 (u16)(xyzw)hr43.y, r27.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr4.y, r27.w, s#0, t#2
mad.f16 hr34.x, hr39.y, hr37.y, (last)hr34.x
mad.f16 hr32.x, hr39.y, hr37.z, (last)hr32.x
mad.f16 hr30.x, hr39.y, hr37.w, (last)hr30.x
mad.f16 hr28.x, hr39.y, hr38.x, (last)hr28.x
mad.f16 hr34.y, hr39.z, hr37.y, (last)hr34.y
mad.f16 hr32.y, hr39.z, hr37.z, (last)hr32.y
mad.f16 hr30.y, hr39.z, hr37.w, (last)hr30.y
mad.f16 hr28.y, hr39.z, hr38.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr39.w, hr37.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr39.w, hr37.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr39.w, hr37.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr39.w, hr38.x, (r)(last)hr28.z
mad.f16 hr26.x, hr39.y, hr38.y, (last)hr26.x
mad.f16 hr24.x, hr39.y, hr38.z, (last)hr24.x
mad.f16 hr22.x, hr39.y, hr38.w, (last)hr22.x
mad.f16 hr20.x, hr39.y, hr39.x, (last)hr20.x
mad.f16 hr26.y, hr39.z, hr38.y, (last)hr26.y
mad.f16 hr24.y, hr39.z, hr38.z, (last)hr24.y
mad.f16 hr22.y, hr39.z, hr38.w, (last)hr22.y
mad.f16 hr20.y, hr39.z, hr39.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr39.w, hr38.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr39.w, hr38.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr39.w, hr38.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr39.w, hr39.x, (r)(last)hr20.z
(rpt1)mad.f16 hr18.x, (r)hr39.y, hr41.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr39.w, hr41.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr39.y, hr41.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr39.w, hr41.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr39.y, hr41.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr39.w, hr41.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr39.y, hr42.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr39.w, hr42.x, (r)(last)hr12.z
(ss)(rpt1)mad.f16 hr10.x, (r)hr39.y, hr42.y, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr39.w, hr42.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr39.y, hr42.z, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr39.w, hr42.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr39.y, hr42.w, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr39.w, hr42.w, (r)(last)hr6.z
(rpt1)mad.f16 hr39.y, (r)(last)hr39.y, hr43.x, (r)(last)hr44.y
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr43.x, (r)(last)hr44.w
ldl.u16 r44.y, l[r1.z+2816], 4
ldl.u16 r45.y, l[r1.z+2880], 4
(rpt1)mad.f16 hr35.x, (r)hr36.y, hr37.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr36.w, hr37.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr36.y, hr37.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr36.w, hr37.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr36.y, hr37.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr36.w, hr37.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr36.y, hr38.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr36.w, hr38.x, (r)(last)hr29.z
ldl.u16 r37.y, l[r1.z+2944], 4
(rpt1)mad.f16 hr27.x, (r)hr36.y, hr38.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr36.w, hr38.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr36.y, hr38.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr36.w, hr38.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr36.y, hr38.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr36.w, hr38.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr36.y, hr39.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr36.w, hr39.x, (r)(last)hr21.z
ldl.u16 r38.y, l[r1.z+3008], 4
(rpt1)mad.f16 hr19.x, (r)hr36.y, hr41.y, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr36.w, hr41.y, (r)(last)hr19.z
(rpt1)mad.f16 hr17.x, (r)hr36.y, hr41.z, (r)(last)hr17.x
(rpt1)mad.f16 hr17.z, (r)hr36.w, hr41.z, (r)(last)hr17.z
(rpt1)mad.f16 hr15.x, (r)hr36.y, hr41.w, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr36.w, hr41.w, (r)(last)hr15.z
(rpt1)mad.f16 hr13.x, (r)hr36.y, hr42.x, (r)(last)hr13.x
(rpt1)mad.f16 hr13.z, (r)hr36.w, hr42.x, (r)(last)hr13.z
ldl.u16 r41.y, l[r1.z+3072], 4
mad.f16 hr11.x, hr36.y, hr42.y, (last)hr11.x
mad.f16 hr9.x, hr36.y, hr42.z, (last)hr9.x
mad.f16 hr7.x, hr36.y, hr42.w, (last)hr7.x
mad.f16 hr11.y, hr36.z, hr42.y, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr36.w, hr42.y, (r)(last)hr11.z
mad.f16 hr9.y, hr36.z, hr42.z, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr36.w, hr42.z, (r)(last)hr9.z
mad.f16 hr7.y, hr36.z, hr42.w, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr36.w, hr42.w, (r)(last)hr7.z
(sy)(ss)mad.f16 hr34.x, hr4.y, hr44.y, (last)hr34.x
mad.f16 hr32.x, hr4.y, hr44.z, (last)hr32.x
mad.f16 hr30.x, hr4.y, hr44.w, (last)hr30.x
mad.f16 hr28.x, hr4.y, hr45.x, (last)hr28.x
mad.f16 hr34.y, hr4.z, hr44.y, (last)hr34.y
mad.f16 hr32.y, hr4.z, hr44.z, (last)hr32.y
mad.f16 hr30.y, hr4.z, hr44.w, (last)hr30.y
mad.f16 hr28.y, hr4.z, hr45.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr4.w, hr44.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr4.w, hr44.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr4.w, hr44.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr4.w, hr45.x, (r)(last)hr28.z
(rpt1)mad.f16 hr35.x, (r)hr43.y, hr44.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr43.w, hr44.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr43.y, hr44.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr43.w, hr44.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr43.y, hr44.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr43.w, hr44.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr43.y, hr45.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr43.w, hr45.x, (r)(last)hr29.z
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr43.x, (r)(last)hr40.y
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr43.x, (r)(last)hr40.w
isam.v.base0 (u16)(xyzw)hr40.y, r28.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr44.y, r28.y, s#0, t#2
ldl.u16 r42.y, l[r1.z+3136], 4
mad.f16 hr26.x, hr4.y, hr45.y, (last)hr26.x
mad.f16 hr24.x, hr4.y, hr45.z, (last)hr24.x
mad.f16 hr22.x, hr4.y, hr45.w, (last)hr22.x
mad.f16 hr20.x, hr4.y, hr46.x, (last)hr20.x
mad.f16 hr26.y, hr4.z, hr45.y, (last)hr26.y
mad.f16 hr24.y, hr4.z, hr45.z, (last)hr24.y
mad.f16 hr22.y, hr4.z, hr45.w, (last)hr22.y
mad.f16 hr20.y, hr4.z, hr46.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr4.w, hr45.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr4.w, hr45.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr4.w, hr45.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr4.w, hr46.x, (r)(last)hr20.z
(rpt1)mad.f16 hr18.x, (r)hr4.y, hr37.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr4.w, hr37.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr4.y, hr37.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr4.w, hr37.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr4.y, hr37.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr4.w, hr37.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr4.y, hr38.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr4.w, hr38.x, (r)(last)hr12.z
(rpt1)mad.f16 hr27.x, (r)hr43.y, hr45.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr43.w, hr45.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr43.y, hr45.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr43.w, hr45.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr43.y, hr45.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr43.w, hr45.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr43.y, hr46.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr43.w, hr46.x, (r)(last)hr21.z
ldl.u16 r45.y, l[r1.z+3200], 4
ldl.u16 r47.x, l[r1.z+3264], 4
(rpt1)mad.f16 hr10.x, (r)hr4.y, hr38.y, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr4.w, hr38.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr4.y, hr38.z, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr4.w, hr38.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr4.y, hr38.w, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr4.w, hr38.w, (r)(last)hr6.z
(rpt1)mad.f16 hr19.x, (r)hr43.y, hr37.y, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr43.w, hr37.y, (r)(last)hr19.z
(rpt1)mad.f16 hr17.x, (r)hr43.y, hr37.z, (r)(last)hr17.x
(rpt1)mad.f16 hr17.z, (r)hr43.w, hr37.z, (r)(last)hr17.z
(rpt1)mad.f16 hr15.x, (r)hr43.y, hr37.w, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr43.w, hr37.w, (r)(last)hr15.z
(rpt1)mad.f16 hr13.x, (r)hr43.y, hr38.x, (r)(last)hr13.x
(rpt1)mad.f16 hr13.z, (r)hr43.w, hr38.x, (r)(last)hr13.z
ldl.u16 r37.y, l[r1.z+3328], 4
mad.f16 hr11.x, hr43.y, hr38.y, (last)hr11.x
mad.f16 hr9.x, hr43.y, hr38.z, (last)hr9.x
mad.f16 hr7.x, hr43.y, hr38.w, (last)hr7.x
mad.f16 hr11.y, hr43.z, hr38.y, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr43.w, hr38.y, (r)(last)hr11.z
mad.f16 hr9.y, hr43.z, hr38.z, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr43.w, hr38.z, (r)(last)hr9.z
mad.f16 hr7.y, hr43.z, hr38.w, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr43.w, hr38.w, (r)(last)hr7.z
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr39.x, (r)(last)hr39.y
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr39.x, (r)(last)hr39.w
(rpt1)mad.f16 hr43.y, (r)(last)hr43.y, hr39.x, (r)(last)hr36.y
(rpt1)mad.f16 hr43.w, (r)(last)hr43.w, hr39.x, (r)(last)hr36.w
isam.v.base0 (u16)(xyzw)hr36.y, r28.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr39.y, r28.w, s#0, t#2
ldl.u16 r38.y, l[r1.z+3392], 4
(sy)(rpt1)mad.f16 hr35.x, (r)hr40.y, hr41.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr40.w, hr41.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr40.y, hr41.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr40.w, hr41.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr40.y, hr41.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr40.w, hr41.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr40.y, hr42.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr40.w, hr42.x, (r)(last)hr29.z
mad.f16 hr34.x, hr44.y, hr41.y, (last)hr34.x
mad.f16 hr32.x, hr44.y, hr41.z, (last)hr32.x
mad.f16 hr30.x, hr44.y, hr41.w, (last)hr30.x
mad.f16 hr28.x, hr44.y, hr42.x, (last)hr28.x
mad.f16 hr34.y, hr44.z, hr41.y, (last)hr34.y
mad.f16 hr32.y, hr44.z, hr41.z, (last)hr32.y
mad.f16 hr30.y, hr44.z, hr41.w, (last)hr30.y
mad.f16 hr28.y, hr44.z, hr42.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr44.w, hr41.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr44.w, hr41.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr44.w, hr41.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr44.w, hr42.x, (r)(last)hr28.z
ldl.u16 r41.y, l[r1.z+3456], 4
(ss)mad.f16 hr26.x, hr44.y, hr42.y, (last)hr26.x
mad.f16 hr24.x, hr44.y, hr42.z, (last)hr24.x
mad.f16 hr22.x, hr44.y, hr42.w, (last)hr22.x
mad.f16 hr20.x, hr44.y, hr43.x, (last)hr20.x
mad.f16 hr26.y, hr44.z, hr42.y, (last)hr26.y
mad.f16 hr24.y, hr44.z, hr42.z, (last)hr24.y
mad.f16 hr22.y, hr44.z, hr42.w, (last)hr22.y
mad.f16 hr20.y, hr44.z, hr43.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr44.w, hr42.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr44.w, hr42.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr44.w, hr42.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr44.w, hr43.x, (r)(last)hr20.z
(rpt1)mad.f16 hr27.x, (r)hr40.y, hr42.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr40.w, hr42.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr40.y, hr42.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr40.w, hr42.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr40.y, hr42.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr40.w, hr42.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr40.y, hr43.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr40.w, hr43.x, (r)(last)hr21.z
ldl.u16 r42.y, l[r1.z+3520], 4
(rpt1)mad.f16 hr18.x, (r)hr44.y, hr45.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr44.w, hr45.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr44.y, hr45.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr44.w, hr45.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr44.y, hr45.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr44.w, hr45.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr44.y, hr46.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr44.w, hr46.x, (r)(last)hr12.z
(rpt1)mad.f16 hr10.x, (r)hr44.y, hr47.x, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr44.w, hr47.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr44.y, hr47.y, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr44.w, hr47.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr44.y, hr47.z, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr44.w, hr47.z, (r)(last)hr6.z
(rpt1)mad.f16 hr19.x, (r)hr40.y, hr45.y, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr40.w, hr45.y, (r)(last)hr19.z
(rpt1)mad.f16 hr17.x, (r)hr40.y, hr45.z, (r)(last)hr17.x
(rpt1)mad.f16 hr17.z, (r)hr40.w, hr45.z, (r)(last)hr17.z
(rpt1)mad.f16 hr15.x, (r)hr40.y, hr45.w, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr40.w, hr45.w, (r)(last)hr15.z
(rpt1)mad.f16 hr13.x, (r)hr40.y, hr46.x, (r)(last)hr13.x
(rpt1)mad.f16 hr13.z, (r)hr40.w, hr46.x, (r)(last)hr13.z
mad.f16 hr11.x, hr40.y, hr47.x, (last)hr11.x
mad.f16 hr9.x, hr40.y, hr47.y, (last)hr9.x
mad.f16 hr7.x, hr40.y, hr47.z, (last)hr7.x
mad.f16 hr11.y, hr40.z, hr47.x, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr40.w, hr47.x, (r)(last)hr11.z
mad.f16 hr9.y, hr40.z, hr47.y, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr40.w, hr47.y, (r)(last)hr9.z
mad.f16 hr7.y, hr40.z, hr47.z, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr40.w, hr47.z, (r)(last)hr7.z
(rpt1)mad.f16 hr44.y, (r)(last)hr44.y, hr47.w, (r)(last)hr4.y
(rpt1)mad.f16 hr44.w, (r)(last)hr44.w, hr47.w, (r)(last)hr4.w
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr47.w, (r)(last)hr43.y
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr47.w, (r)(last)hr43.w
isam.v.base0 (u16)(xyzw)hr43.y, r29.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr4.y, r29.y, s#0, t#2
mad.f16 hr34.x, hr39.y, hr37.y, (last)hr34.x
mad.f16 hr32.x, hr39.y, hr37.z, (last)hr32.x
mad.f16 hr30.x, hr39.y, hr37.w, (last)hr30.x
mad.f16 hr28.x, hr39.y, hr38.x, (last)hr28.x
mad.f16 hr34.y, hr39.z, hr37.y, (last)hr34.y
mad.f16 hr32.y, hr39.z, hr37.z, (last)hr32.y
mad.f16 hr30.y, hr39.z, hr37.w, (last)hr30.y
mad.f16 hr28.y, hr39.z, hr38.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr39.w, hr37.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr39.w, hr37.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr39.w, hr37.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr39.w, hr38.x, (r)(last)hr28.z
mad.f16 hr26.x, hr39.y, hr38.y, (last)hr26.x
mad.f16 hr24.x, hr39.y, hr38.z, (last)hr24.x
mad.f16 hr22.x, hr39.y, hr38.w, (last)hr22.x
mad.f16 hr20.x, hr39.y, hr39.x, (last)hr20.x
mad.f16 hr26.y, hr39.z, hr38.y, (last)hr26.y
mad.f16 hr24.y, hr39.z, hr38.z, (last)hr24.y
mad.f16 hr22.y, hr39.z, hr38.w, (last)hr22.y
mad.f16 hr20.y, hr39.z, hr39.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr39.w, hr38.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr39.w, hr38.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr39.w, hr38.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr39.w, hr39.x, (r)(last)hr20.z
(rpt1)mad.f16 hr18.x, (r)hr39.y, hr41.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr39.w, hr41.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr39.y, hr41.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr39.w, hr41.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr39.y, hr41.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr39.w, hr41.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr39.y, hr42.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr39.w, hr42.x, (r)(last)hr12.z
(ss)(rpt1)mad.f16 hr10.x, (r)hr39.y, hr42.y, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr39.w, hr42.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr39.y, hr42.z, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr39.w, hr42.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr39.y, hr42.w, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr39.w, hr42.w, (r)(last)hr6.z
(rpt1)mad.f16 hr39.y, (r)(last)hr39.y, hr43.x, (r)(last)hr44.y
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr43.x, (r)(last)hr44.w
ldl.u16 r44.y, l[r1.z+3584], 4
ldl.u16 r45.y, l[r1.z+3648], 4
(rpt1)mad.f16 hr35.x, (r)hr36.y, hr37.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr36.w, hr37.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr36.y, hr37.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr36.w, hr37.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr36.y, hr37.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr36.w, hr37.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr36.y, hr38.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr36.w, hr38.x, (r)(last)hr29.z
ldl.u16 r37.y, l[r1.z+3712], 4
(rpt1)mad.f16 hr27.x, (r)hr36.y, hr38.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr36.w, hr38.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr36.y, hr38.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr36.w, hr38.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr36.y, hr38.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr36.w, hr38.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr36.y, hr39.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr36.w, hr39.x, (r)(last)hr21.z
ldl.u16 r38.y, l[r1.z+3776], 4
(rpt1)mad.f16 hr19.x, (r)hr36.y, hr41.y, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr36.w, hr41.y, (r)(last)hr19.z
(rpt1)mad.f16 hr17.x, (r)hr36.y, hr41.z, (r)(last)hr17.x
(rpt1)mad.f16 hr17.z, (r)hr36.w, hr41.z, (r)(last)hr17.z
(rpt1)mad.f16 hr15.x, (r)hr36.y, hr41.w, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr36.w, hr41.w, (r)(last)hr15.z
(rpt1)mad.f16 hr13.x, (r)hr36.y, hr42.x, (r)(last)hr13.x
(rpt1)mad.f16 hr13.z, (r)hr36.w, hr42.x, (r)(last)hr13.z
ldl.u16 r41.y, l[r1.z+3840], 4
mad.f16 hr11.x, hr36.y, hr42.y, (last)hr11.x
mad.f16 hr9.x, hr36.y, hr42.z, (last)hr9.x
mad.f16 hr7.x, hr36.y, hr42.w, (last)hr7.x
mad.f16 hr11.y, hr36.z, hr42.y, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr36.w, hr42.y, (r)(last)hr11.z
mad.f16 hr9.y, hr36.z, hr42.z, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr36.w, hr42.z, (r)(last)hr9.z
mad.f16 hr7.y, hr36.z, hr42.w, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr36.w, hr42.w, (r)(last)hr7.z
(sy)(ss)mad.f16 hr34.x, hr4.y, hr44.y, (last)hr34.x
mad.f16 hr32.x, hr4.y, hr44.z, (last)hr32.x
mad.f16 hr30.x, hr4.y, hr44.w, (last)hr30.x
mad.f16 hr28.x, hr4.y, hr45.x, (last)hr28.x
mad.f16 hr34.y, hr4.z, hr44.y, (last)hr34.y
mad.f16 hr32.y, hr4.z, hr44.z, (last)hr32.y
mad.f16 hr30.y, hr4.z, hr44.w, (last)hr30.y
mad.f16 hr28.y, hr4.z, hr45.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr4.w, hr44.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr4.w, hr44.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr4.w, hr44.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr4.w, hr45.x, (r)(last)hr28.z
(rpt1)mad.f16 hr35.x, (r)hr43.y, hr44.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr43.w, hr44.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr43.y, hr44.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr43.w, hr44.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr43.y, hr44.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr43.w, hr44.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr43.y, hr45.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr43.w, hr45.x, (r)(last)hr29.z
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr43.x, (r)(last)hr40.y
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr43.x, (r)(last)hr40.w
isam.v.base0 (u16)(xyzw)hr40.y, r29.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr44.y, r29.w, s#0, t#2
ldl.u16 r42.y, l[r1.z+3904], 4
mad.f16 hr26.x, hr4.y, hr45.y, (last)hr26.x
mad.f16 hr24.x, hr4.y, hr45.z, (last)hr24.x
mad.f16 hr22.x, hr4.y, hr45.w, (last)hr22.x
mad.f16 hr20.x, hr4.y, hr46.x, (last)hr20.x
mad.f16 hr26.y, hr4.z, hr45.y, (last)hr26.y
mad.f16 hr24.y, hr4.z, hr45.z, (last)hr24.y
mad.f16 hr22.y, hr4.z, hr45.w, (last)hr22.y
mad.f16 hr20.y, hr4.z, hr46.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr4.w, hr45.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr4.w, hr45.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr4.w, hr45.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr4.w, hr46.x, (r)(last)hr20.z
(rpt1)mad.f16 hr27.x, (r)hr43.y, hr45.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr43.w, hr45.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr43.y, hr45.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr43.w, hr45.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr43.y, hr45.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr43.w, hr45.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr43.y, hr46.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr43.w, hr46.x, (r)(last)hr21.z
ldl.u16 r45.y, l[r1.z+3968], 4
ldl.u16 r47.x, l[r1.z+4032], 4
(rpt1)mad.f16 hr18.x, (r)hr4.y, hr37.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr4.w, hr37.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr4.y, hr37.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr4.w, hr37.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr4.y, hr37.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr4.w, hr37.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr4.y, hr38.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr4.w, hr38.x, (r)(last)hr12.z
(rpt1)mad.f16 hr10.x, (r)hr4.y, hr38.y, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr4.w, hr38.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr4.y, hr38.z, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr4.w, hr38.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr4.y, hr38.w, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr4.w, hr38.w, (r)(last)hr6.z
(rpt1)mad.f16 hr19.x, (r)hr43.y, hr37.y, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr43.w, hr37.y, (r)(last)hr19.z
(rpt1)mad.f16 hr17.x, (r)hr43.y, hr37.z, (r)(last)hr17.x
(rpt1)mad.f16 hr17.z, (r)hr43.w, hr37.z, (r)(last)hr17.z
(rpt1)mad.f16 hr15.x, (r)hr43.y, hr37.w, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr43.w, hr37.w, (r)(last)hr15.z
(rpt1)mad.f16 hr13.x, (r)hr43.y, hr38.x, (r)(last)hr13.x
(rpt1)mad.f16 hr13.z, (r)hr43.w, hr38.x, (r)(last)hr13.z
mad.f16 hr11.x, hr43.y, hr38.y, (last)hr11.x
mad.f16 hr9.x, hr43.y, hr38.z, (last)hr9.x
mad.f16 hr7.x, hr43.y, hr38.w, (last)hr7.x
mad.f16 hr11.y, hr43.z, hr38.y, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr43.w, hr38.y, (r)(last)hr11.z
mad.f16 hr9.y, hr43.z, hr38.z, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr43.w, hr38.z, (r)(last)hr9.z
mad.f16 hr7.y, hr43.z, hr38.w, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr43.w, hr38.w, (r)(last)hr7.z
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr39.x, (r)(last)hr39.y
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr39.x, (r)(last)hr39.w
(rpt1)mad.f16 hr43.y, (r)(last)hr43.y, hr39.x, (r)(last)hr36.y
(rpt1)mad.f16 hr43.w, (r)(last)hr43.w, hr39.x, (r)(last)hr36.w
(sy)(rpt1)mad.f16 hr35.x, (r)hr40.y, hr41.y, (r)(last)hr35.x
(rpt1)mad.f16 hr35.z, (r)hr40.w, hr41.y, (r)(last)hr35.z
(rpt1)mad.f16 hr33.x, (r)hr40.y, hr41.z, (r)(last)hr33.x
(rpt1)mad.f16 hr33.z, (r)hr40.w, hr41.z, (r)(last)hr33.z
(rpt1)mad.f16 hr31.x, (r)hr40.y, hr41.w, (r)(last)hr31.x
(rpt1)mad.f16 hr31.z, (r)hr40.w, hr41.w, (r)(last)hr31.z
(rpt1)mad.f16 hr29.x, (r)hr40.y, hr42.x, (r)(last)hr29.x
(rpt1)mad.f16 hr29.z, (r)hr40.w, hr42.x, (r)(last)hr29.z
mad.f16 hr34.x, hr44.y, hr41.y, (last)hr34.x
mad.f16 hr32.x, hr44.y, hr41.z, (last)hr32.x
mad.f16 hr30.x, hr44.y, hr41.w, (last)hr30.x
mad.f16 hr28.x, hr44.y, hr42.x, (last)hr28.x
mad.f16 hr34.y, hr44.z, hr41.y, (last)hr34.y
mad.f16 hr32.y, hr44.z, hr41.z, (last)hr32.y
mad.f16 hr30.y, hr44.z, hr41.w, (last)hr30.y
mad.f16 hr28.y, hr44.z, hr42.x, (last)hr28.y
(rpt1)mad.f16 hr34.z, (r)hr44.w, hr41.y, (r)(last)hr34.z
(rpt1)mad.f16 hr32.z, (r)hr44.w, hr41.z, (r)(last)hr32.z
(rpt1)mad.f16 hr30.z, (r)hr44.w, hr41.w, (r)(last)hr30.z
(rpt1)mad.f16 hr28.z, (r)hr44.w, hr42.x, (r)(last)hr28.z
(ss)mad.f16 hr26.x, hr44.y, hr42.y, (last)hr26.x
mad.f16 hr24.x, hr44.y, hr42.z, (last)hr24.x
mad.f16 hr22.x, hr44.y, hr42.w, (last)hr22.x
mad.f16 hr20.x, hr44.y, hr43.x, (last)hr20.x
mad.f16 hr26.y, hr44.z, hr42.y, (last)hr26.y
mad.f16 hr24.y, hr44.z, hr42.z, (last)hr24.y
mad.f16 hr22.y, hr44.z, hr42.w, (last)hr22.y
mad.f16 hr20.y, hr44.z, hr43.x, (last)hr20.y
(rpt1)mad.f16 hr26.z, (r)hr44.w, hr42.y, (r)(last)hr26.z
(rpt1)mad.f16 hr24.z, (r)hr44.w, hr42.z, (r)(last)hr24.z
(rpt1)mad.f16 hr22.z, (r)hr44.w, hr42.w, (r)(last)hr22.z
(rpt1)mad.f16 hr20.z, (r)hr44.w, hr43.x, (r)(last)hr20.z
(rpt1)mad.f16 hr27.x, (r)hr40.y, hr42.y, (r)(last)hr27.x
(rpt1)mad.f16 hr27.z, (r)hr40.w, hr42.y, (r)(last)hr27.z
(rpt1)mad.f16 hr25.x, (r)hr40.y, hr42.z, (r)(last)hr25.x
(rpt1)mad.f16 hr25.z, (r)hr40.w, hr42.z, (r)(last)hr25.z
(rpt1)mad.f16 hr23.x, (r)hr40.y, hr42.w, (r)(last)hr23.x
(rpt1)mad.f16 hr23.z, (r)hr40.w, hr42.w, (r)(last)hr23.z
(rpt1)mad.f16 hr21.x, (r)hr40.y, hr43.x, (r)(last)hr21.x
(rpt1)mad.f16 hr21.z, (r)hr40.w, hr43.x, (r)(last)hr21.z
fence.r.w
(sy)(ss)(rpt1)mad.f16 hr18.x, (r)hr44.y, hr45.y, (r)(last)hr18.x
(rpt1)mad.f16 hr18.z, (r)hr44.w, hr45.y, (r)(last)hr18.z
(rpt1)mad.f16 hr16.x, (r)hr44.y, hr45.z, (r)(last)hr16.x
(rpt1)mad.f16 hr16.z, (r)hr44.w, hr45.z, (r)(last)hr16.z
(rpt1)mad.f16 hr14.x, (r)hr44.y, hr45.w, (r)(last)hr14.x
(rpt1)mad.f16 hr14.z, (r)hr44.w, hr45.w, (r)(last)hr14.z
(rpt1)mad.f16 hr12.x, (r)hr44.y, hr46.x, (r)(last)hr12.x
(rpt1)mad.f16 hr12.z, (r)hr44.w, hr46.x, (r)(last)hr12.z
(rpt1)mad.f16 hr10.x, (r)hr44.y, hr47.x, (r)(last)hr10.x
(rpt1)mad.f16 hr10.z, (r)hr44.w, hr47.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.x, (r)hr44.y, hr47.y, (r)(last)hr8.x
(rpt1)mad.f16 hr8.z, (r)hr44.w, hr47.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.x, (r)hr44.y, hr47.z, (r)(last)hr6.x
(rpt1)mad.f16 hr6.z, (r)hr44.w, hr47.z, (r)(last)hr6.z
(rpt1)mad.f16 hr19.x, (r)hr40.y, hr45.y, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr40.w, hr45.y, (r)(last)hr19.z
(rpt1)mad.f16 hr17.x, (r)hr40.y, hr45.z, (r)(last)hr17.x
(rpt1)mad.f16 hr17.z, (r)hr40.w, hr45.z, (r)(last)hr17.z
(rpt1)mad.f16 hr15.x, (r)hr40.y, hr45.w, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr40.w, hr45.w, (r)(last)hr15.z
(rpt1)mad.f16 hr13.x, (r)hr40.y, hr46.x, (r)(last)hr13.x
(rpt1)mad.f16 hr13.z, (r)hr40.w, hr46.x, (r)(last)hr13.z
mad.f16 hr11.x, hr40.y, hr47.x, (last)hr11.x
mad.f16 hr9.x, hr40.y, hr47.y, (last)hr9.x
mad.f16 hr7.x, hr40.y, hr47.z, (last)hr7.x
mad.f16 hr11.y, hr40.z, hr47.x, (last)hr11.y
(rpt1)mad.f16 hr11.z, (r)hr40.w, hr47.x, (r)(last)hr11.z
mad.f16 hr9.y, hr40.z, hr47.y, (last)hr9.y
(rpt1)mad.f16 hr9.z, (r)hr40.w, hr47.y, (r)(last)hr9.z
mad.f16 hr7.y, hr40.z, hr47.z, (last)hr7.y
(rpt1)mad.f16 hr7.z, (r)hr40.w, hr47.z, (r)(last)hr7.z
mad.f16 hr4.x, (last)hr44.y, hr47.w, (last)hr4.y
(rpt1)mad.f16 hr0.z, (r)(last)hr40.y, hr47.w, (r)(last)hr43.y
(rpt1)mad.f16 hr1.x, (r)(last)hr40.w, hr47.w, (r)(last)hr43.w
bar.g
(sy)(ss)mad.f16 hr4.y, (last)hr44.z, hr47.w, (last)hr4.z
(rpt1)mad.f16 hr4.z, (r)(last)hr44.w, hr47.w, (r)(last)hr4.w
br p0.x, #l1669
mov.u16u16 hr5.w, hr1.y
mov.u16u16 hr5.z, hr1.x
mov.u16u16 hr5.y, hr0.w
mov.u16u16 hr5.x, hr0.z
jump #l215
l1669:
(jp)(eolm)nop
(nop3) add.u r23.y, r48.z, (last)r23.y
(nop3) shl.b r23.y, (last)r23.y, 9
(nop3) sad.s32 r23.y, r49.z, r23.y, (last)r1.w
(nop3) shl.b r23.y, (last)r23.y, 2
add.u r0.w, r23.y, c1.x
add.u r1.x, r23.y, c8.y
add.u r1.y, r23.y, c4.z
add.u r1.z, r23.y, c8.x
stib.b.untyped.1d.u16.4.imm.base0 hr35.x, r23.y, 4
add.u r18.x, c11.x, r23.y
(rpt1)add.u r18.y, (r)c11.y, r23.y
(rpt1)add.u r18.w, (r)c11.w, r23.y
(rpt1)add.u r19.y, (r)c12.y, r23.y
(rpt1)add.u r19.w, (r)c12.w, r23.y
(rpt1)add.u r20.y, (r)c13.y, r23.y
(rpt1)add.u r20.w, (r)c13.w, r23.y
(ss)add.u r17.z, r23.y, c10.z
add.u r17.w, c10.w, r23.y
stib.b.untyped.1d.u16.4.imm.base0 hr34.x, r23.y+32, 4
(ss)(rpt1)add.u r17.x, r23.y, (r)c10.x
stib.b.untyped.1d.u16.4.imm.base0 hr33.x, r0.w, 4
(ss)(rpt1)add.u r16.z, r23.y, (r)c9.z
stib.b.untyped.1d.u16.4.imm.base0 hr32.x, r1.x, 4
(ss)(rpt1)add.u r16.x, r23.y, (r)c9.x
stib.b.untyped.1d.u16.4.imm.base0 hr31.x, r1.y, 4
(ss)(rpt1)add.u r15.z, r23.y, (r)c8.z
stib.b.untyped.1d.u16.4.imm.base0 hr30.x, r1.z, 4
(ss)add.u r15.x, r23.y, c4.y
add.u r15.y, r23.y, c7.w
(nop3) add.u r23.y, c14.y, (last)r23.y
nop
stib.b.untyped.1d.u16.4.imm.base0 hr29.x, r15.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr28.x, r15.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr27.x, r15.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr26.x, r15.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr25.x, r16.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr24.x, r16.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr23.x, r16.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr22.x, r16.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr21.x, r17.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr20.x, r17.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr19.x, r17.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr18.x, r17.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr17.x, r18.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.x, r18.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.x, r18.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.x, r18.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.x, r19.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.x, r19.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.x, r19.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.x, r19.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.x, r20.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr8.x, r20.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr7.x, r20.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr6.x, r20.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr0.z, r21.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r23.y, 4
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
; CL prog 23/1: 2509 instr, 33 nops, 2476 non-nops, 133 mov, 0 cov, 3488 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 30 full, 16 constlen
; CL prog 23/1: 36 cat0, 133 cat1, 134 cat2, 2058 cat3, 0 cat4, 40 cat5, 104 cat6, 4 cat7
; CL prog 23/1: 60 sstall, 32 (ss), 211 systall, 18 (sy), 1 loops
; CL prog 23/1: 8 max_waves, 0 double_threadsize
; 78 preamble-instr, 1 early-preamble
