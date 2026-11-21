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
@const(c1.x)	0x00000800, 0x00000200, 0x00000280, 0x00000300
@const(c2.x)	0x00000380, 0x00001e00, 0x00007800, 0x00001c00
@const(c3.x)	0x00007000, 0x00001a00, 0x00006800, 0x00001800
@const(c4.x)	0x00006000, 0x00001600, 0x00005800, 0x00001400
@const(c5.x)	0x00005000, 0x00001200, 0x00004800, 0x00001000
@const(c6.x)	0x00004000, 0x00003800, 0x00003000, 0x00002800
@const(c7.x)	0x00002000, 0x00000840, 0x00000880, 0x000008c0
@const(c8.x)	0x00001040, 0x00001080, 0x000010c0, 0x00001840
@const(c9.x)	0x00001880, 0x000018c0, 0x00010000, 0x00007820
@const(c10.x)	0x00007020, 0x00006820, 0x00006020, 0x00005820
@const(c11.x)	0x00005020, 0x00004820, 0x00004020, 0x00003820
@const(c12.x)	0x00003020, 0x00002820, 0x00002020, 0x00001820
@const(c13.x)	0x00001020, 0x00000820, 0x00010040, 0x00010080
@const(c14.x)	0x000100c0, 0x00010800, 0x00010840, 0x00010880
@const(c15.x)	0x000108c0, 0x00011000, 0x00011040, 0x00011080
@const(c16.x)	0x000110c0, 0x00011800, 0x00011840, 0x00011880
@const(c17.x)	0x000118c0, 0xd0d0d0d0, 0xd0d0d0d0, 0xd0d0d0d0
shps #l93
getone #l93
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 512
mov.u32u32 r49.y, 640
mov.u32u32 r49.z, 768
mov.u32u32 r49.w, 896
mov.u32u32 r50.x, 0x1e00
mov.u32u32 r50.y, 0x7800
mov.u32u32 r50.z, 0x1c00
mov.u32u32 r50.w, 0x7000
mov.u32u32 r51.x, 0x1a00
mov.u32u32 r51.y, 0x6800
mov.u32u32 r51.z, 0x1800
mov.u32u32 r51.w, 0x6000
mov.u32u32 r52.x, 0x1600
mov.u32u32 r52.y, 0x5800
mov.u32u32 r52.z, 0x1400
mov.u32u32 r52.w, 0x5000
mov.u32u32 r53.x, 0x1200
mov.u32u32 r53.y, 0x4800
mov.u32u32 r53.z, 4096
mov.u32u32 r53.w, 0x4000
mov.u32u32 r54.x, 0x3800
mov.u32u32 r54.y, 0x3000
mov.u32u32 r54.z, 0x2800
mov.u32u32 r54.w, 0x2000
mov.u32u32 r55.x, 2112
mov.u32u32 r55.y, 2176
mov.u32u32 r55.z, 2240
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
(ss)mov.u32u32 r48.w, 0x1040
mov.u32u32 r49.x, 0x1080
mov.u32u32 r49.y, 0x10c0
mov.u32u32 r49.z, 0x1840
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 4
stc.u32 c[20], r52.w, 4
stc.u32 c[24], r53.w, 4
stc.u32 c[28], r54.w, 4
(ss)mov.u32u32 r49.w, 0x1880
mov.u32u32 r50.x, 0x18c0
mov.u32u32 r50.y, 0x10000
mov.u32u32 r50.z, 0x7820
mov.u32u32 r50.w, 0x7020
mov.u32u32 r51.x, 0x6820
mov.u32u32 r51.y, 0x6020
mov.u32u32 r51.z, 0x5820
mov.u32u32 r51.w, 0x5020
mov.u32u32 r52.x, 0x4820
mov.u32u32 r52.y, 0x4020
mov.u32u32 r52.z, 0x3820
mov.u32u32 r52.w, 0x3020
mov.u32u32 r53.x, 0x2820
mov.u32u32 r53.y, 0x2020
mov.u32u32 r53.z, 0x1820
mov.u32u32 r53.w, 0x1020
mov.u32u32 r54.x, 2080
mov.u32u32 r54.y, 0x10040
mov.u32u32 r54.z, 0x10080
mov.u32u32 r54.w, 0x100c0
mov.u32u32 r55.x, 0x10800
mov.u32u32 r55.y, 0x10840
mov.u32u32 r55.z, 0x10880
stc.u32 c[32], r48.w, 4
(ss)nop
stc.u32 c[36], r49.w, 4
mov.u32u32 r48.w, 0x108c0
mov.u32u32 r49.x, 0x11000
mov.u32u32 r49.y, 0x11040
mov.u32u32 r49.z, 0x11080
stc.u32 c[40], r50.w, 4
stc.u32 c[44], r51.w, 4
stc.u32 c[48], r52.w, 4
stc.u32 c[52], r53.w, 4
stc.u32 c[56], r54.w, 4
(ss)mov.u32u32 r49.w, 0x110c0
mov.u32u32 r50.x, 0x11800
mov.u32u32 r50.y, 0x11840
mov.u32u32 r50.z, 0x11880
mov.u32u32 r50.w, 0x118c0
stc.u32 c[60], r48.w, 4
(ss)nop
stc.u32 c[64], r49.w, 4
stc.u32 c[68], r50.w, 1
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l93:
(jp)(rpt1)add.u r51.x, (r)r48.x, (r)c0.x
mov.u32u32 r52.x, 0
shl.b r51.z, r51.x, 8
shl.b r51.w, r51.y, 6
shr.b r0.w, r0.x, 6
and.b r1.x, r0.x, 63
shr.b r1.z, r0.x, 4
and.b r1.y, r0.x, 15
mov.u16u16 hr3.z, 0
mov.u16u16 hr3.w, 0
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
mov.u16u16 hr4.y, 0
mov.u16u16 hr4.x, 0
l229:
(rpt1)shr.b r52.y, (r)r51.z, 2
shl.b r52.w, r52.x, 9
add.u r18.z, r0.x, 128
add.u r18.w, r0.x, 256
add.u r19.x, r0.x, 384
shl.b r17.w, r0.w, 9
(rpt1)shr.b r18.z, (last)(r)r18.z, 6
(ss)add.u r19.z, r52.x, r0.w
shr.b r19.x, (last)r19.x, 6
(rpt1)add.u r20.y, r52.x, (r)r18.z
shl.b r19.z, (last)r19.z, 9
add.u r20.w, r52.x, r19.x
(rpt1)shl.b r20.y, (last)(r)r20.y, 9
sad.s32 r19.z, r52.y, r19.z, r1.x
shl.b r20.w, (last)r20.w, 9
(rpt1)sad.s32 r20.y, r52.y, (r)r20.y, r1.x
shl.b r19.z, (last)r19.z, 2
shl.b r18.x, r1.x, 3
(rpt1)shl.b r20.y, (last)(r)r20.y, 2
(rpt1)shl.b r18.z, (last)(r)r18.z, 9
sad.s32 r20.w, r52.y, r20.w, r1.x
isam.v.base0 (u16)(xyzw)hr39.z, r19.z, s#0, t#2
add.u r17.w, (last)r17.w, r18.x
add.u r18.z, (last)r18.z, r18.x
isam.v.base0 (u16)(xyzw)hr45.z, r20.y, s#0, t#2
add.u r18.w, (last)r18.w, r18.x
isam.v.base0 (u16)(xyzw)hr0.z, r20.z, s#0, t#2
shl.b r20.w, (last)r20.w, 2
add.u r19.y, r0.x, c1.y
(rpt2)add.u r21.y, r0.x, (r)c1.z
shr.b r19.y, (last)r19.y, 6
(rpt2)shr.b r21.y, (last)(r)r21.y, 6
add.u r21.x, r52.x, r19.y
(rpt2)add.u r22.x, r52.x, (r)r21.y
add.u r52.x, r52.x, 16
cmps.u.ge up0.x, r52.x, c1.x
shl.b r21.x, (last)r21.x, 9
(rpt2)shl.b r22.x, (last)(r)r22.x, 9
shl.b r19.x, (last)r19.x, 9
sad.s32 r21.x, r52.y, r21.x, r1.x
(rpt2)sad.s32 r22.x, r52.y, (r)r22.x, r1.x
add.u r19.x, (last)r19.x, r18.x
shl.b r21.x, (last)r21.x, 2
(rpt1)shl.b r22.x, (last)(r)r22.x, 2
shl.b r22.z, (last)r22.z, 2
shl.b r19.y, (last)r19.y, 9
(rpt2)shl.b r21.y, (last)(r)r21.y, 9
sad.s32 r24.z, r52.w, r1.z, r52.z
shl.b r18.y, r1.y, 3
add.u r19.y, (last)r19.y, r18.x
(rpt2)add.u r21.y, (last)(r)r21.y, (last)r18.x
(sy)stl.u16 l[r17.w], r39.z, 4
stl.u16 l[r18.z], r45.z, 4
stl.u16 l[r18.w], r0.z, 4
(ss)nop
isam.v.base0 (u16)(xyzw)hr37.x, r20.w, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr41.x, r21.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr45.z, r22.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr0.z, r22.y, s#0, t#2
shl.b r24.z, (last)r24.z, 2
add.u r23.z, c5.w, r18.y
add.u r23.w, c5.y, r18.y
add.u r24.x, c4.w, r18.y
add.u r25.w, r24.z, c1.x
add.u r26.x, r24.z, c13.y
add.u r26.y, r24.z, c5.w
add.u r26.z, r24.z, c13.x
add.u r26.w, r24.z, c3.w
add.u r27.x, r24.z, c12.w
add.u r27.y, r24.z, c7.x
add.u r27.z, r24.z, c12.z
add.u r27.w, r24.z, c6.w
add.u r28.x, r24.z, c12.y
add.u r28.y, r24.z, c6.z
add.u r28.z, r24.z, c12.x
add.u r28.w, r24.z, c6.y
add.u r29.x, r24.z, c11.w
add.u r29.y, r24.z, c6.x
add.u r29.z, r24.z, c11.z
add.u r29.w, r24.z, c5.z
add.u r30.x, r24.z, c11.y
add.u r24.y, c4.y, r18.y
add.u r24.w, c3.w, r18.y
add.u r25.x, c3.y, r18.y
add.u r25.y, c2.w, r18.y
add.u r25.z, c2.y, r18.y
add.u r30.y, r24.z, c5.x
add.u r30.z, r24.z, c11.x
add.u r19.z, r24.z, c4.z
add.u r19.w, r24.z, c10.w
add.u r20.x, r24.z, c4.x
add.u r20.y, r24.z, c10.z
add.u r30.w, r24.z, c3.z
add.u r31.x, r24.z, c10.y
add.u r31.y, r24.z, c3.x
add.u r31.z, r24.z, c10.x
add.u r17.w, r24.z, c2.z
add.u r18.x, r24.z, c9.w
(sy)stl.u16 l[r19.x], r37.x, 4
(ss)nop
isam.v.base0 (u16)(xyzw)hr37.x, r22.z, s#0, t#2
stl.u16 l[r19.y], r41.x, 4
stl.u16 l[r21.y], r45.z, 4
stl.u16 l[r21.z], r0.z, 4
shl.b r23.y, r1.z, 2
(sy)stl.u16 l[r21.w], r37.x, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
ldl.u16 r41.y, l[r18.y], 4
isam.v.base0 (u16)(xyzw)hr38.x, r24.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr42.y, r24.z+32, s#0, t#0
ldl.u16 r43.y, l[r18.y+128], 4
ldl.u16 r44.y, l[r18.y+256], 4
ldl.u16 r0.z, l[r18.y+384], 4
isam.v.base0 (u16)(xyzw)hr45.y, r25.w, s#0, t#0
(sy)(ss)mad.f16 hr31.z, hr0.z, hr38.x, (last)hr31.z
mad.f16 hr27.z, hr0.z, hr38.y, (last)hr27.z
mad.f16 hr23.z, hr0.z, hr38.z, (last)hr23.z
mad.f16 hr19.z, hr0.z, hr38.w, (last)hr19.z
mad.f16 hr15.z, hr0.z, hr42.y, (last)hr15.z
mad.f16 hr11.z, hr0.z, hr42.z, (last)hr11.z
mad.f16 hr7.z, hr0.z, hr42.w, (last)hr7.z
mad.f16 hr31.w, hr0.w, hr38.x, (last)hr31.w
mad.f16 hr27.w, hr0.w, hr38.y, (last)hr27.w
mad.f16 hr23.w, hr0.w, hr38.z, (last)hr23.w
mad.f16 hr19.w, hr0.w, hr38.w, (last)hr19.w
mad.f16 hr15.w, hr0.w, hr42.y, (last)hr15.w
mad.f16 hr11.w, hr0.w, hr42.z, (last)hr11.w
mad.f16 hr7.w, hr0.w, hr42.w, (last)hr7.w
(rpt1)mad.f16 hr32.x, (r)hr1.x, hr38.x, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr1.x, hr38.y, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr1.x, hr38.z, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr1.x, hr38.w, (r)(last)hr20.x
(rpt1)mad.f16 hr16.x, (r)hr1.x, hr42.y, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr1.x, hr42.z, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr1.x, hr42.w, (r)(last)hr8.x
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr43.x, (r)(last)hr3.z
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr43.x, (r)(last)hr4.x
isam.v.base0 (u16)(xyzw)hr3.z, r26.x, s#0, t#0
isam.v.base0 (u16)(xyzw)hr37.x, r26.y, s#0, t#0
mad.f16 hr34.z, hr41.y, hr38.x, (last)hr34.z
mad.f16 hr30.z, hr41.y, hr38.y, (last)hr30.z
mad.f16 hr26.z, hr41.y, hr38.z, (last)hr26.z
mad.f16 hr22.z, hr41.y, hr38.w, (last)hr22.z
mad.f16 hr34.w, hr41.z, hr38.x, (last)hr34.w
mad.f16 hr30.w, hr41.z, hr38.y, (last)hr30.w
mad.f16 hr26.w, hr41.z, hr38.z, (last)hr26.w
mad.f16 hr22.w, hr41.z, hr38.w, (last)hr22.w
mad.f16 hr35.x, hr41.w, hr38.x, (last)hr35.x
mad.f16 hr31.x, hr41.w, hr38.y, (last)hr31.x
mad.f16 hr27.x, hr41.w, hr38.z, (last)hr27.x
mad.f16 hr23.x, hr41.w, hr38.w, (last)hr23.x
mad.f16 hr35.y, hr42.x, hr38.x, (last)hr35.y
mad.f16 hr31.y, hr42.x, hr38.y, (last)hr31.y
mad.f16 hr27.y, hr42.x, hr38.z, (last)hr27.y
mad.f16 hr23.y, hr42.x, hr38.w, (last)hr23.y
(rpt1)mad.f16 hr18.z, (r)hr41.y, hr42.y, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr41.w, hr42.y, (r)(last)hr19.x
(rpt1)mad.f16 hr14.z, (r)hr41.y, hr42.z, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr41.w, hr42.z, (r)(last)hr15.x
(rpt1)mad.f16 hr10.z, (r)hr41.y, hr42.w, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr41.w, hr42.w, (r)(last)hr11.x
mad.f16 hr33.z, hr43.y, hr38.x, (last)hr33.z
mad.f16 hr29.z, hr43.y, hr38.y, (last)hr29.z
mad.f16 hr25.z, hr43.y, hr38.z, (last)hr25.z
mad.f16 hr21.z, hr43.y, hr38.w, (last)hr21.z
mad.f16 hr17.z, hr43.y, hr42.y, (last)hr17.z
mad.f16 hr13.z, hr43.y, hr42.z, (last)hr13.z
mad.f16 hr9.z, hr43.y, hr42.w, (last)hr9.z
mad.f16 hr33.w, hr43.z, hr38.x, (last)hr33.w
mad.f16 hr29.w, hr43.z, hr38.y, (last)hr29.w
mad.f16 hr25.w, hr43.z, hr38.z, (last)hr25.w
mad.f16 hr21.w, hr43.z, hr38.w, (last)hr21.w
mad.f16 hr17.w, hr43.z, hr42.y, (last)hr17.w
mad.f16 hr13.w, hr43.z, hr42.z, (last)hr13.w
mad.f16 hr9.w, hr43.z, hr42.w, (last)hr9.w
mad.f16 hr34.x, hr43.w, hr38.x, (last)hr34.x
mad.f16 hr30.x, hr43.w, hr38.y, (last)hr30.x
mad.f16 hr26.x, hr43.w, hr38.z, (last)hr26.x
mad.f16 hr22.x, hr43.w, hr38.w, (last)hr22.x
mad.f16 hr18.x, hr43.w, hr42.y, (last)hr18.x
mad.f16 hr14.x, hr43.w, hr42.z, (last)hr14.x
mad.f16 hr10.x, hr43.w, hr42.w, (last)hr10.x
mad.f16 hr34.y, hr44.x, hr38.x, (last)hr34.y
mad.f16 hr30.y, hr44.x, hr38.y, (last)hr30.y
mad.f16 hr26.y, hr44.x, hr38.z, (last)hr26.y
mad.f16 hr22.y, hr44.x, hr38.w, (last)hr22.y
mad.f16 hr18.y, hr44.x, hr42.y, (last)hr18.y
mad.f16 hr14.y, hr44.x, hr42.z, (last)hr14.y
mad.f16 hr10.y, hr44.x, hr42.w, (last)hr10.y
mad.f16 hr32.z, hr44.y, hr38.x, (last)hr32.z
mad.f16 hr28.z, hr44.y, hr38.y, (last)hr28.z
mad.f16 hr24.z, hr44.y, hr38.z, (last)hr24.z
mad.f16 hr20.z, hr44.y, hr38.w, (last)hr20.z
mad.f16 hr16.z, hr44.y, hr42.y, (last)hr16.z
mad.f16 hr12.z, hr44.y, hr42.z, (last)hr12.z
mad.f16 hr8.z, hr44.y, hr42.w, (last)hr8.z
mad.f16 hr32.w, hr44.z, hr38.x, (last)hr32.w
mad.f16 hr28.w, hr44.z, hr38.y, (last)hr28.w
mad.f16 hr24.w, hr44.z, hr38.z, (last)hr24.w
mad.f16 hr20.w, hr44.z, hr38.w, (last)hr20.w
mad.f16 hr16.w, hr44.z, hr42.y, (last)hr16.w
mad.f16 hr12.w, hr44.z, hr42.z, (last)hr12.w
mad.f16 hr8.w, hr44.z, hr42.w, (last)hr8.w
mad.f16 hr33.x, hr44.w, hr38.x, (last)hr33.x
mad.f16 hr29.x, hr44.w, hr38.y, (last)hr29.x
mad.f16 hr25.x, hr44.w, hr38.z, (last)hr25.x
mad.f16 hr21.x, hr44.w, hr38.w, (last)hr21.x
mad.f16 hr17.x, hr44.w, hr42.y, (last)hr17.x
mad.f16 hr13.x, hr44.w, hr42.z, (last)hr13.x
mad.f16 hr9.x, hr44.w, hr42.w, (last)hr9.x
mad.f16 hr33.y, hr45.x, hr38.x, (last)hr33.y
mad.f16 hr29.y, hr45.x, hr38.y, (last)hr29.y
mad.f16 hr25.y, hr45.x, hr38.z, (last)hr25.y
mad.f16 hr21.y, hr45.x, hr38.w, (last)hr21.y
mad.f16 hr17.y, hr45.x, hr42.y, (last)hr17.y
mad.f16 hr13.y, hr45.x, hr42.z, (last)hr13.y
mad.f16 hr9.y, hr45.x, hr42.w, (last)hr9.y
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr43.x, (r)(last)hr6.z
(rpt1)mad.f16 hr41.w, (r)(last)hr41.w, hr43.x, (r)(last)hr7.x
(rpt1)mad.f16 hr43.y, (r)(last)hr43.y, hr43.x, (r)(last)hr5.z
(rpt1)mad.f16 hr43.w, (r)(last)hr43.w, hr43.x, (r)(last)hr6.x
(rpt1)mad.f16 hr44.y, (r)(last)hr44.y, hr43.x, (r)(last)hr4.z
(rpt1)mad.f16 hr44.w, (r)(last)hr44.w, hr43.x, (r)(last)hr5.x
ldl.u16 r4.w, l[r18.y+512], 4
ldl.u16 r5.w, l[r18.y+640], 4
ldl.u16 r42.y, l[r18.y+768], 4
(ss)mad.f16 hr32.z, hr42.y, hr45.y, (last)hr32.z
mad.f16 hr28.z, hr42.y, hr45.z, (last)hr28.z
mad.f16 hr24.z, hr42.y, hr45.w, (last)hr24.z
mad.f16 hr20.z, hr42.y, hr46.x, (last)hr20.z
(sy)mad.f16 hr16.z, hr42.y, hr3.z, (last)hr16.z
mad.f16 hr12.z, hr42.y, hr3.w, (last)hr12.z
mad.f16 hr8.z, hr42.y, hr4.x, (last)hr8.z
mad.f16 hr32.w, hr42.z, hr45.y, (last)hr32.w
mad.f16 hr28.w, hr42.z, hr45.z, (last)hr28.w
mad.f16 hr24.w, hr42.z, hr45.w, (last)hr24.w
mad.f16 hr20.w, hr42.z, hr46.x, (last)hr20.w
mad.f16 hr16.w, hr42.z, hr3.z, (last)hr16.w
mad.f16 hr12.w, hr42.z, hr3.w, (last)hr12.w
mad.f16 hr8.w, hr42.z, hr4.x, (last)hr8.w
mad.f16 hr33.x, hr42.w, hr45.y, (last)hr33.x
mad.f16 hr29.x, hr42.w, hr45.z, (last)hr29.x
mad.f16 hr25.x, hr42.w, hr45.w, (last)hr25.x
mad.f16 hr21.x, hr42.w, hr46.x, (last)hr21.x
mad.f16 hr17.x, hr42.w, hr3.z, (last)hr17.x
mad.f16 hr13.x, hr42.w, hr3.w, (last)hr13.x
mad.f16 hr9.x, hr42.w, hr4.x, (last)hr9.x
mad.f16 hr33.y, hr43.x, hr45.y, (last)hr33.y
mad.f16 hr29.y, hr43.x, hr45.z, (last)hr29.y
mad.f16 hr25.y, hr43.x, hr45.w, (last)hr25.y
mad.f16 hr21.y, hr43.x, hr46.x, (last)hr21.y
mad.f16 hr17.y, hr43.x, hr3.z, (last)hr17.y
mad.f16 hr13.y, hr43.x, hr3.w, (last)hr13.y
mad.f16 hr9.y, hr43.x, hr4.x, (last)hr9.y
(rpt1)mad.f16 hr42.y, (r)(last)hr42.y, hr4.y, (r)(last)hr44.y
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr4.y, (r)(last)hr44.w
isam.v.base0 (u16)(xyzw)hr44.y, r26.z, s#0, t#0
mad.f16 hr33.z, hr5.w, hr45.y, (last)hr33.z
mad.f16 hr29.z, hr5.w, hr45.z, (last)hr29.z
mad.f16 hr25.z, hr5.w, hr45.w, (last)hr25.z
mad.f16 hr21.z, hr5.w, hr46.x, (last)hr21.z
mad.f16 hr17.z, hr5.w, hr3.z, (last)hr17.z
mad.f16 hr13.z, hr5.w, hr3.w, (last)hr13.z
mad.f16 hr9.z, hr5.w, hr4.x, (last)hr9.z
mad.f16 hr33.w, hr6.x, hr45.y, (last)hr33.w
mad.f16 hr29.w, hr6.x, hr45.z, (last)hr29.w
mad.f16 hr25.w, hr6.x, hr45.w, (last)hr25.w
mad.f16 hr21.w, hr6.x, hr46.x, (last)hr21.w
mad.f16 hr17.w, hr6.x, hr3.z, (last)hr17.w
mad.f16 hr13.w, hr6.x, hr3.w, (last)hr13.w
mad.f16 hr9.w, hr6.x, hr4.x, (last)hr9.w
mad.f16 hr34.x, hr6.y, hr45.y, (last)hr34.x
mad.f16 hr30.x, hr6.y, hr45.z, (last)hr30.x
mad.f16 hr26.x, hr6.y, hr45.w, (last)hr26.x
mad.f16 hr22.x, hr6.y, hr46.x, (last)hr22.x
mad.f16 hr18.x, hr6.y, hr3.z, (last)hr18.x
mad.f16 hr14.x, hr6.y, hr3.w, (last)hr14.x
mad.f16 hr10.x, hr6.y, hr4.x, (last)hr10.x
mad.f16 hr34.y, hr6.z, hr45.y, (last)hr34.y
mad.f16 hr30.y, hr6.z, hr45.z, (last)hr30.y
mad.f16 hr26.y, hr6.z, hr45.w, (last)hr26.y
mad.f16 hr22.y, hr6.z, hr46.x, (last)hr22.y
mad.f16 hr18.y, hr6.z, hr3.z, (last)hr18.y
mad.f16 hr14.y, hr6.z, hr3.w, (last)hr14.y
mad.f16 hr10.y, hr6.z, hr4.x, (last)hr10.y
(rpt1)mad.f16 hr5.w, (r)(last)hr5.w, hr4.y, (r)(last)hr43.y
(rpt1)mad.f16 hr6.y, (r)(last)hr6.y, hr4.y, (r)(last)hr43.w
ldl.u16 r43.y, l[r18.y+896], 4
mad.f16 hr34.z, hr4.w, hr45.y, (last)hr34.z
mad.f16 hr30.z, hr4.w, hr45.z, (last)hr30.z
mad.f16 hr26.z, hr4.w, hr45.w, (last)hr26.z
mad.f16 hr22.z, hr4.w, hr46.x, (last)hr22.z
mad.f16 hr18.z, hr4.w, hr3.z, (last)hr18.z
mad.f16 hr14.z, hr4.w, hr3.w, (last)hr14.z
mad.f16 hr10.z, hr4.w, hr4.x, (last)hr10.z
mad.f16 hr34.w, hr5.x, hr45.y, (last)hr34.w
mad.f16 hr30.w, hr5.x, hr45.z, (last)hr30.w
mad.f16 hr26.w, hr5.x, hr45.w, (last)hr26.w
mad.f16 hr22.w, hr5.x, hr46.x, (last)hr22.w
mad.f16 hr18.w, hr5.x, hr3.z, (last)hr18.w
mad.f16 hr14.w, hr5.x, hr3.w, (last)hr14.w
mad.f16 hr10.w, hr5.x, hr4.x, (last)hr10.w
mad.f16 hr35.x, hr5.y, hr45.y, (last)hr35.x
mad.f16 hr31.x, hr5.y, hr45.z, (last)hr31.x
mad.f16 hr27.x, hr5.y, hr45.w, (last)hr27.x
mad.f16 hr23.x, hr5.y, hr46.x, (last)hr23.x
mad.f16 hr19.x, hr5.y, hr3.z, (last)hr19.x
mad.f16 hr15.x, hr5.y, hr3.w, (last)hr15.x
mad.f16 hr11.x, hr5.y, hr4.x, (last)hr11.x
mad.f16 hr35.y, hr5.z, hr45.y, (last)hr35.y
mad.f16 hr31.y, hr5.z, hr45.z, (last)hr31.y
mad.f16 hr27.y, hr5.z, hr45.w, (last)hr27.y
mad.f16 hr23.y, hr5.z, hr46.x, (last)hr23.y
mad.f16 hr19.y, hr5.z, hr3.z, (last)hr19.y
mad.f16 hr15.y, hr5.z, hr3.w, (last)hr15.y
mad.f16 hr11.y, hr5.z, hr4.x, (last)hr11.y
(ss)mad.f16 hr31.z, hr43.y, hr45.y, (last)hr31.z
mad.f16 hr27.z, hr43.y, hr45.z, (last)hr27.z
mad.f16 hr23.z, hr43.y, hr45.w, (last)hr23.z
mad.f16 hr19.z, hr43.y, hr46.x, (last)hr19.z
mad.f16 hr15.z, hr43.y, hr3.z, (last)hr15.z
mad.f16 hr11.z, hr43.y, hr3.w, (last)hr11.z
mad.f16 hr7.z, hr43.y, hr4.x, (last)hr7.z
mad.f16 hr31.w, hr43.z, hr45.y, (last)hr31.w
mad.f16 hr27.w, hr43.z, hr45.z, (last)hr27.w
mad.f16 hr23.w, hr43.z, hr45.w, (last)hr23.w
mad.f16 hr19.w, hr43.z, hr46.x, (last)hr19.w
mad.f16 hr15.w, hr43.z, hr3.z, (last)hr15.w
mad.f16 hr11.w, hr43.z, hr3.w, (last)hr11.w
mad.f16 hr7.w, hr43.z, hr4.x, (last)hr7.w
(rpt1)mad.f16 hr32.x, (r)hr43.w, hr45.y, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr43.w, hr45.z, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr43.w, hr45.w, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr43.w, hr46.x, (r)(last)hr20.x
ldl.u16 r45.y, l[r18.y+1024], 4
(rpt1)mad.f16 hr16.x, (r)hr43.w, hr3.z, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr43.w, hr3.w, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr43.w, hr4.x, (r)(last)hr8.x
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr4.y, (r)(last)hr41.y
(rpt1)mad.f16 hr5.y, (r)(last)hr5.y, hr4.y, (r)(last)hr41.w
(rpt1)mad.f16 hr43.y, (r)(last)hr43.y, hr4.y, (r)(last)hr0.z
(rpt1)mad.f16 hr43.w, (r)(last)hr43.w, hr4.y, (r)(last)hr1.x
ldl.u16 r3.w, l[r18.y+1152], 4
(ss)mad.f16 hr33.z, hr3.w, hr37.x, (last)hr33.z
mad.f16 hr29.z, hr3.w, hr37.y, (last)hr29.z
mad.f16 hr25.z, hr3.w, hr37.z, (last)hr25.z
mad.f16 hr21.z, hr3.w, hr37.w, (last)hr21.z
(sy)mad.f16 hr17.z, hr3.w, hr44.y, (last)hr17.z
mad.f16 hr13.z, hr3.w, hr44.z, (last)hr13.z
mad.f16 hr9.z, hr3.w, hr44.w, (last)hr9.z
mad.f16 hr33.w, hr4.x, hr37.x, (last)hr33.w
mad.f16 hr29.w, hr4.x, hr37.y, (last)hr29.w
mad.f16 hr25.w, hr4.x, hr37.z, (last)hr25.w
mad.f16 hr21.w, hr4.x, hr37.w, (last)hr21.w
mad.f16 hr17.w, hr4.x, hr44.y, (last)hr17.w
mad.f16 hr13.w, hr4.x, hr44.z, (last)hr13.w
mad.f16 hr9.w, hr4.x, hr44.w, (last)hr9.w
mad.f16 hr34.x, hr4.y, hr37.x, (last)hr34.x
mad.f16 hr30.x, hr4.y, hr37.y, (last)hr30.x
mad.f16 hr26.x, hr4.y, hr37.z, (last)hr26.x
mad.f16 hr22.x, hr4.y, hr37.w, (last)hr22.x
mad.f16 hr18.x, hr4.y, hr44.y, (last)hr18.x
mad.f16 hr14.x, hr4.y, hr44.z, (last)hr14.x
mad.f16 hr10.x, hr4.y, hr44.w, (last)hr10.x
mad.f16 hr34.y, hr4.z, hr37.x, (last)hr34.y
mad.f16 hr30.y, hr4.z, hr37.y, (last)hr30.y
mad.f16 hr26.y, hr4.z, hr37.z, (last)hr26.y
mad.f16 hr22.y, hr4.z, hr37.w, (last)hr22.y
mad.f16 hr18.y, hr4.z, hr44.y, (last)hr18.y
mad.f16 hr14.y, hr4.z, hr44.z, (last)hr14.y
mad.f16 hr10.y, hr4.z, hr44.w, (last)hr10.y
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr45.x, (r)(last)hr5.w
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr45.x, (r)(last)hr6.y
ldl.u16 r5.w, l[r18.y+1280], 4
ldl.u16 r41.y, l[r18.y+1408], 4
mad.f16 hr34.z, hr45.y, hr37.x, (last)hr34.z
mad.f16 hr30.z, hr45.y, hr37.y, (last)hr30.z
mad.f16 hr26.z, hr45.y, hr37.z, (last)hr26.z
mad.f16 hr22.z, hr45.y, hr37.w, (last)hr22.z
mad.f16 hr18.z, hr45.y, hr44.y, (last)hr18.z
mad.f16 hr14.z, hr45.y, hr44.z, (last)hr14.z
mad.f16 hr10.z, hr45.y, hr44.w, (last)hr10.z
mad.f16 hr34.w, hr45.z, hr37.x, (last)hr34.w
mad.f16 hr30.w, hr45.z, hr37.y, (last)hr30.w
mad.f16 hr26.w, hr45.z, hr37.z, (last)hr26.w
mad.f16 hr22.w, hr45.z, hr37.w, (last)hr22.w
mad.f16 hr18.w, hr45.z, hr44.y, (last)hr18.w
mad.f16 hr14.w, hr45.z, hr44.z, (last)hr14.w
mad.f16 hr10.w, hr45.z, hr44.w, (last)hr10.w
mad.f16 hr35.x, hr45.w, hr37.x, (last)hr35.x
mad.f16 hr31.x, hr45.w, hr37.y, (last)hr31.x
mad.f16 hr27.x, hr45.w, hr37.z, (last)hr27.x
mad.f16 hr23.x, hr45.w, hr37.w, (last)hr23.x
mad.f16 hr19.x, hr45.w, hr44.y, (last)hr19.x
mad.f16 hr15.x, hr45.w, hr44.z, (last)hr15.x
mad.f16 hr11.x, hr45.w, hr44.w, (last)hr11.x
mad.f16 hr35.y, hr46.x, hr37.x, (last)hr35.y
mad.f16 hr31.y, hr46.x, hr37.y, (last)hr31.y
mad.f16 hr27.y, hr46.x, hr37.z, (last)hr27.y
mad.f16 hr23.y, hr46.x, hr37.w, (last)hr23.y
mad.f16 hr19.y, hr46.x, hr44.y, (last)hr19.y
mad.f16 hr15.y, hr46.x, hr44.z, (last)hr15.y
mad.f16 hr11.y, hr46.x, hr44.w, (last)hr11.y
(ss)mad.f16 hr32.z, hr5.w, hr37.x, (last)hr32.z
mad.f16 hr28.z, hr5.w, hr37.y, (last)hr28.z
mad.f16 hr24.z, hr5.w, hr37.z, (last)hr24.z
mad.f16 hr20.z, hr5.w, hr37.w, (last)hr20.z
mad.f16 hr16.z, hr5.w, hr44.y, (last)hr16.z
mad.f16 hr12.z, hr5.w, hr44.z, (last)hr12.z
mad.f16 hr8.z, hr5.w, hr44.w, (last)hr8.z
mad.f16 hr32.w, hr6.x, hr37.x, (last)hr32.w
mad.f16 hr28.w, hr6.x, hr37.y, (last)hr28.w
mad.f16 hr24.w, hr6.x, hr37.z, (last)hr24.w
mad.f16 hr20.w, hr6.x, hr37.w, (last)hr20.w
mad.f16 hr16.w, hr6.x, hr44.y, (last)hr16.w
mad.f16 hr12.w, hr6.x, hr44.z, (last)hr12.w
mad.f16 hr8.w, hr6.x, hr44.w, (last)hr8.w
mad.f16 hr33.x, hr6.y, hr37.x, (last)hr33.x
mad.f16 hr29.x, hr6.y, hr37.y, (last)hr29.x
mad.f16 hr25.x, hr6.y, hr37.z, (last)hr25.x
mad.f16 hr21.x, hr6.y, hr37.w, (last)hr21.x
mad.f16 hr17.x, hr6.y, hr44.y, (last)hr17.x
mad.f16 hr13.x, hr6.y, hr44.z, (last)hr13.x
mad.f16 hr9.x, hr6.y, hr44.w, (last)hr9.x
mad.f16 hr33.y, hr6.z, hr37.x, (last)hr33.y
mad.f16 hr29.y, hr6.z, hr37.y, (last)hr29.y
mad.f16 hr25.y, hr6.z, hr37.z, (last)hr25.y
mad.f16 hr21.y, hr6.z, hr37.w, (last)hr21.y
mad.f16 hr17.y, hr6.z, hr44.y, (last)hr17.y
mad.f16 hr13.y, hr6.z, hr44.z, (last)hr13.y
mad.f16 hr9.y, hr6.z, hr44.w, (last)hr9.y
(rpt1)mad.f16 hr45.y, (r)(last)hr45.y, hr45.x, (r)(last)hr4.w
(rpt1)mad.f16 hr45.w, (r)(last)hr45.w, hr45.x, (r)(last)hr5.y
isam.v.base0 (u16)(xyzw)hr4.w, r26.w, s#0, t#0
(rpt1)mad.f16 hr5.w, (r)(last)hr5.w, hr45.x, (r)(last)hr42.y
(rpt1)mad.f16 hr6.y, (r)(last)hr6.y, hr45.x, (r)(last)hr42.w
isam.v.base0 (u16)(xyzw)hr42.y, r27.x, s#0, t#0
mad.f16 hr31.z, hr41.y, hr37.x, (last)hr31.z
mad.f16 hr27.z, hr41.y, hr37.y, (last)hr27.z
mad.f16 hr23.z, hr41.y, hr37.z, (last)hr23.z
mad.f16 hr19.z, hr41.y, hr37.w, (last)hr19.z
mad.f16 hr15.z, hr41.y, hr44.y, (last)hr15.z
mad.f16 hr11.z, hr41.y, hr44.z, (last)hr11.z
mad.f16 hr7.z, hr41.y, hr44.w, (last)hr7.z
mad.f16 hr31.w, hr41.z, hr37.x, (last)hr31.w
mad.f16 hr27.w, hr41.z, hr37.y, (last)hr27.w
mad.f16 hr23.w, hr41.z, hr37.z, (last)hr23.w
mad.f16 hr19.w, hr41.z, hr37.w, (last)hr19.w
mad.f16 hr15.w, hr41.z, hr44.y, (last)hr15.w
mad.f16 hr11.w, hr41.z, hr44.z, (last)hr11.w
mad.f16 hr7.w, hr41.z, hr44.w, (last)hr7.w
(rpt1)mad.f16 hr32.x, (r)hr41.w, hr37.x, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr41.w, hr37.y, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr41.w, hr37.z, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr41.w, hr37.w, (r)(last)hr20.x
(rpt1)mad.f16 hr16.x, (r)hr41.w, hr44.y, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr41.w, hr44.z, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr41.w, hr44.w, (r)(last)hr8.x
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr45.x, (r)(last)hr43.y
(rpt1)mad.f16 hr41.w, (r)(last)hr41.w, hr45.x, (r)(last)hr43.w
ldl.u16 r43.y, l[r18.y+1536], 4
ldl.u16 r44.y, l[r18.y+1664], 4
ldl.u16 r37.y, l[r18.y+1792], 4
ldl.u16 r0.z, l[r18.y+1920], 4
(sy)(ss)mad.f16 hr34.z, hr43.y, hr4.w, (last)hr34.z
mad.f16 hr30.z, hr43.y, hr5.x, (last)hr30.z
mad.f16 hr26.z, hr43.y, hr5.y, (last)hr26.z
mad.f16 hr22.z, hr43.y, hr5.z, (last)hr22.z
mad.f16 hr18.z, hr43.y, hr42.y, (last)hr18.z
mad.f16 hr14.z, hr43.y, hr42.z, (last)hr14.z
mad.f16 hr10.z, hr43.y, hr42.w, (last)hr10.z
mad.f16 hr34.w, hr43.z, hr4.w, (last)hr34.w
mad.f16 hr30.w, hr43.z, hr5.x, (last)hr30.w
mad.f16 hr26.w, hr43.z, hr5.y, (last)hr26.w
mad.f16 hr22.w, hr43.z, hr5.z, (last)hr22.w
mad.f16 hr18.w, hr43.z, hr42.y, (last)hr18.w
mad.f16 hr14.w, hr43.z, hr42.z, (last)hr14.w
mad.f16 hr10.w, hr43.z, hr42.w, (last)hr10.w
mad.f16 hr35.x, hr43.w, hr4.w, (last)hr35.x
mad.f16 hr31.x, hr43.w, hr5.x, (last)hr31.x
mad.f16 hr27.x, hr43.w, hr5.y, (last)hr27.x
mad.f16 hr23.x, hr43.w, hr5.z, (last)hr23.x
mad.f16 hr19.x, hr43.w, hr42.y, (last)hr19.x
mad.f16 hr15.x, hr43.w, hr42.z, (last)hr15.x
mad.f16 hr11.x, hr43.w, hr42.w, (last)hr11.x
mad.f16 hr35.y, hr44.x, hr4.w, (last)hr35.y
mad.f16 hr31.y, hr44.x, hr5.x, (last)hr31.y
mad.f16 hr27.y, hr44.x, hr5.y, (last)hr27.y
mad.f16 hr23.y, hr44.x, hr5.z, (last)hr23.y
mad.f16 hr19.y, hr44.x, hr42.y, (last)hr19.y
mad.f16 hr15.y, hr44.x, hr42.z, (last)hr15.y
mad.f16 hr11.y, hr44.x, hr42.w, (last)hr11.y
mad.f16 hr33.z, hr44.y, hr4.w, (last)hr33.z
mad.f16 hr29.z, hr44.y, hr5.x, (last)hr29.z
mad.f16 hr25.z, hr44.y, hr5.y, (last)hr25.z
mad.f16 hr21.z, hr44.y, hr5.z, (last)hr21.z
mad.f16 hr17.z, hr44.y, hr42.y, (last)hr17.z
mad.f16 hr13.z, hr44.y, hr42.z, (last)hr13.z
mad.f16 hr9.z, hr44.y, hr42.w, (last)hr9.z
mad.f16 hr33.w, hr44.z, hr4.w, (last)hr33.w
mad.f16 hr29.w, hr44.z, hr5.x, (last)hr29.w
mad.f16 hr25.w, hr44.z, hr5.y, (last)hr25.w
mad.f16 hr21.w, hr44.z, hr5.z, (last)hr21.w
mad.f16 hr17.w, hr44.z, hr42.y, (last)hr17.w
mad.f16 hr13.w, hr44.z, hr42.z, (last)hr13.w
mad.f16 hr9.w, hr44.z, hr42.w, (last)hr9.w
mad.f16 hr34.x, hr44.w, hr4.w, (last)hr34.x
mad.f16 hr30.x, hr44.w, hr5.x, (last)hr30.x
mad.f16 hr26.x, hr44.w, hr5.y, (last)hr26.x
mad.f16 hr22.x, hr44.w, hr5.z, (last)hr22.x
mad.f16 hr18.x, hr44.w, hr42.y, (last)hr18.x
mad.f16 hr14.x, hr44.w, hr42.z, (last)hr14.x
mad.f16 hr10.x, hr44.w, hr42.w, (last)hr10.x
(rpt1)mad.f16 hr43.y, (r)(last)hr43.y, hr43.x, (r)(last)hr45.y
(rpt1)mad.f16 hr43.w, (r)(last)hr43.w, hr43.x, (r)(last)hr45.w
isam.v.base0 (u16)(xyzw)hr45.y, r27.y, s#0, t#0
(rpt1)mad.f16 hr44.y, (r)(last)hr44.y, hr43.x, (r)(last)hr3.w
mad.f16 hr44.w, (last)hr44.w, hr43.x, (last)hr4.y
isam.v.base0 (u16)(xyzw)hr3.z, r27.z, s#0, t#0
mad.f16 hr34.y, hr45.x, hr4.w, (last)hr34.y
mad.f16 hr30.y, hr45.x, hr5.x, (last)hr30.y
mad.f16 hr26.y, hr45.x, hr5.y, (last)hr26.y
mad.f16 hr22.y, hr45.x, hr5.z, (last)hr22.y
mad.f16 hr32.z, hr37.y, hr4.w, (last)hr32.z
mad.f16 hr28.z, hr37.y, hr5.x, (last)hr28.z
mad.f16 hr24.z, hr37.y, hr5.y, (last)hr24.z
mad.f16 hr20.z, hr37.y, hr5.z, (last)hr20.z
mad.f16 hr16.z, hr37.y, hr42.y, (last)hr16.z
mad.f16 hr12.z, hr37.y, hr42.z, (last)hr12.z
mad.f16 hr8.z, hr37.y, hr42.w, (last)hr8.z
mad.f16 hr32.w, hr37.z, hr4.w, (last)hr32.w
mad.f16 hr28.w, hr37.z, hr5.x, (last)hr28.w
mad.f16 hr24.w, hr37.z, hr5.y, (last)hr24.w
mad.f16 hr20.w, hr37.z, hr5.z, (last)hr20.w
mad.f16 hr16.w, hr37.z, hr42.y, (last)hr16.w
mad.f16 hr12.w, hr37.z, hr42.z, (last)hr12.w
mad.f16 hr8.w, hr37.z, hr42.w, (last)hr8.w
mad.f16 hr33.x, hr37.w, hr4.w, (last)hr33.x
mad.f16 hr29.x, hr37.w, hr5.x, (last)hr29.x
mad.f16 hr25.x, hr37.w, hr5.y, (last)hr25.x
mad.f16 hr21.x, hr37.w, hr5.z, (last)hr21.x
mad.f16 hr17.x, hr37.w, hr42.y, (last)hr17.x
mad.f16 hr13.x, hr37.w, hr42.z, (last)hr13.x
mad.f16 hr9.x, hr37.w, hr42.w, (last)hr9.x
mad.f16 hr33.y, hr38.x, hr4.w, (last)hr33.y
mad.f16 hr29.y, hr38.x, hr5.x, (last)hr29.y
mad.f16 hr25.y, hr38.x, hr5.y, (last)hr25.y
mad.f16 hr21.y, hr38.x, hr5.z, (last)hr21.y
mad.f16 hr17.y, hr38.x, hr42.y, (last)hr17.y
mad.f16 hr13.y, hr38.x, hr42.z, (last)hr13.y
mad.f16 hr9.y, hr38.x, hr42.w, (last)hr9.y
mad.f16 hr31.z, hr0.z, hr4.w, (last)hr31.z
mad.f16 hr27.z, hr0.z, hr5.x, (last)hr27.z
mad.f16 hr23.z, hr0.z, hr5.y, (last)hr23.z
mad.f16 hr19.z, hr0.z, hr5.z, (last)hr19.z
mad.f16 hr31.w, hr0.w, hr4.w, (last)hr31.w
mad.f16 hr27.w, hr0.w, hr5.x, (last)hr27.w
mad.f16 hr23.w, hr0.w, hr5.y, (last)hr23.w
mad.f16 hr19.w, hr0.w, hr5.z, (last)hr19.w
(rpt1)mad.f16 hr32.x, (r)hr1.x, hr4.w, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr1.x, hr5.x, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr1.x, hr5.y, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr1.x, hr5.z, (r)(last)hr20.x
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr43.x, (r)(last)hr5.w
(rpt1)mad.f16 hr37.w, (r)(last)hr37.w, hr43.x, (r)(last)hr6.y
ldl.u16 r5.w, l[r18.y+2048], 4
ldl.u16 r4.w, l[r18.y+2176], 4
mad.f16 hr18.y, hr45.x, hr42.y, (last)hr18.y
mad.f16 hr14.y, hr45.x, hr42.z, (last)hr14.y
mad.f16 hr10.y, hr45.x, hr42.w, (last)hr10.y
mad.f16 hr45.x, (last)hr45.x, hr43.x, (last)hr4.z
mad.f16 hr15.z, hr0.z, hr42.y, (last)hr15.z
mad.f16 hr11.z, hr0.z, hr42.z, (last)hr11.z
mad.f16 hr7.z, hr0.z, hr42.w, (last)hr7.z
mad.f16 hr15.w, hr0.w, hr42.y, (last)hr15.w
mad.f16 hr11.w, hr0.w, hr42.z, (last)hr11.w
mad.f16 hr7.w, hr0.w, hr42.w, (last)hr7.w
mad.f16 hr16.x, hr1.x, hr42.y, (last)hr16.x
mad.f16 hr12.x, hr1.x, hr42.z, (last)hr12.x
mad.f16 hr8.x, hr1.x, hr42.w, (last)hr8.x
(sy)(ss)mad.f16 hr33.z, hr4.w, hr45.y, (last)hr33.z
mad.f16 hr29.z, hr4.w, hr45.z, (last)hr29.z
mad.f16 hr25.z, hr4.w, hr45.w, (last)hr25.z
mad.f16 hr21.z, hr4.w, hr46.x, (last)hr21.z
mad.f16 hr17.z, hr4.w, hr3.z, (last)hr17.z
mad.f16 hr13.z, hr4.w, hr3.w, (last)hr13.z
mad.f16 hr9.z, hr4.w, hr4.x, (last)hr9.z
mad.f16 hr33.w, hr5.x, hr45.y, (last)hr33.w
mad.f16 hr29.w, hr5.x, hr45.z, (last)hr29.w
mad.f16 hr25.w, hr5.x, hr45.w, (last)hr25.w
mad.f16 hr21.w, hr5.x, hr46.x, (last)hr21.w
mad.f16 hr17.w, hr5.x, hr3.z, (last)hr17.w
mad.f16 hr13.w, hr5.x, hr3.w, (last)hr13.w
mad.f16 hr9.w, hr5.x, hr4.x, (last)hr9.w
mad.f16 hr34.x, hr5.y, hr45.y, (last)hr34.x
mad.f16 hr30.x, hr5.y, hr45.z, (last)hr30.x
mad.f16 hr26.x, hr5.y, hr45.w, (last)hr26.x
mad.f16 hr22.x, hr5.y, hr46.x, (last)hr22.x
mad.f16 hr18.x, hr5.y, hr3.z, (last)hr18.x
mad.f16 hr14.x, hr5.y, hr3.w, (last)hr14.x
mad.f16 hr10.x, hr5.y, hr4.x, (last)hr10.x
mad.f16 hr34.y, hr5.z, hr45.y, (last)hr34.y
mad.f16 hr30.y, hr5.z, hr45.z, (last)hr30.y
mad.f16 hr26.y, hr5.z, hr45.w, (last)hr26.y
mad.f16 hr22.y, hr5.z, hr46.x, (last)hr22.y
mad.f16 hr18.y, hr5.z, hr3.z, (last)hr18.y
mad.f16 hr14.y, hr5.z, hr3.w, (last)hr14.y
mad.f16 hr10.y, hr5.z, hr4.x, (last)hr10.y
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr43.x, (r)(last)hr41.y
mad.f16 hr1.x, (last)hr1.x, hr43.x, (last)hr41.w
isam.v.base0 (u16)(xyzw)hr41.x, r27.w, s#0, t#0
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr4.y, (r)(last)hr44.y
(rpt1)mad.f16 hr5.y, (r)(last)hr5.y, hr4.y, (r)(last)hr44.w
isam.v.base0 (u16)(xyzw)hr44.y, r28.x, s#0, t#0
mad.f16 hr16.y, hr1.y, hr42.y, (last)hr16.y
mad.f16 hr12.y, hr1.y, hr42.z, (last)hr12.y
mad.f16 hr8.y, hr1.y, hr42.w, (last)hr8.y
mad.f16 hr34.z, hr5.w, hr45.y, (last)hr34.z
mad.f16 hr30.z, hr5.w, hr45.z, (last)hr30.z
mad.f16 hr26.z, hr5.w, hr45.w, (last)hr26.z
mad.f16 hr22.z, hr5.w, hr46.x, (last)hr22.z
mad.f16 hr18.z, hr5.w, hr3.z, (last)hr18.z
mad.f16 hr14.z, hr5.w, hr3.w, (last)hr14.z
mad.f16 hr10.z, hr5.w, hr4.x, (last)hr10.z
mad.f16 hr34.w, hr6.x, hr45.y, (last)hr34.w
mad.f16 hr30.w, hr6.x, hr45.z, (last)hr30.w
mad.f16 hr26.w, hr6.x, hr45.w, (last)hr26.w
mad.f16 hr22.w, hr6.x, hr46.x, (last)hr22.w
mad.f16 hr18.w, hr6.x, hr3.z, (last)hr18.w
mad.f16 hr14.w, hr6.x, hr3.w, (last)hr14.w
mad.f16 hr10.w, hr6.x, hr4.x, (last)hr10.w
mad.f16 hr35.x, hr6.y, hr45.y, (last)hr35.x
mad.f16 hr31.x, hr6.y, hr45.z, (last)hr31.x
mad.f16 hr27.x, hr6.y, hr45.w, (last)hr27.x
mad.f16 hr23.x, hr6.y, hr46.x, (last)hr23.x
mad.f16 hr19.x, hr6.y, hr3.z, (last)hr19.x
mad.f16 hr15.x, hr6.y, hr3.w, (last)hr15.x
mad.f16 hr11.x, hr6.y, hr4.x, (last)hr11.x
mad.f16 hr35.y, hr6.z, hr45.y, (last)hr35.y
mad.f16 hr31.y, hr6.z, hr45.z, (last)hr31.y
mad.f16 hr27.y, hr6.z, hr45.w, (last)hr27.y
mad.f16 hr23.y, hr6.z, hr46.x, (last)hr23.y
mad.f16 hr19.y, hr6.z, hr3.z, (last)hr19.y
mad.f16 hr15.y, hr6.z, hr3.w, (last)hr15.y
mad.f16 hr11.y, hr6.z, hr4.x, (last)hr11.y
mad.f16 hr1.y, (last)hr1.y, hr43.x, (last)hr42.x
ldl.u16 r42.y, l[r18.y+2304], 4
(rpt1)mad.f16 hr5.w, (r)(last)hr5.w, hr4.y, (r)(last)hr43.y
(rpt1)mad.f16 hr6.y, (r)(last)hr6.y, hr4.y, (r)(last)hr43.w
ldl.u16 r43.y, l[r18.y+2432], 4
(ss)mad.f16 hr32.z, hr42.y, hr45.y, (last)hr32.z
mad.f16 hr28.z, hr42.y, hr45.z, (last)hr28.z
mad.f16 hr24.z, hr42.y, hr45.w, (last)hr24.z
mad.f16 hr20.z, hr42.y, hr46.x, (last)hr20.z
mad.f16 hr16.z, hr42.y, hr3.z, (last)hr16.z
mad.f16 hr12.z, hr42.y, hr3.w, (last)hr12.z
mad.f16 hr8.z, hr42.y, hr4.x, (last)hr8.z
mad.f16 hr32.w, hr42.z, hr45.y, (last)hr32.w
mad.f16 hr28.w, hr42.z, hr45.z, (last)hr28.w
mad.f16 hr24.w, hr42.z, hr45.w, (last)hr24.w
mad.f16 hr20.w, hr42.z, hr46.x, (last)hr20.w
mad.f16 hr16.w, hr42.z, hr3.z, (last)hr16.w
mad.f16 hr12.w, hr42.z, hr3.w, (last)hr12.w
mad.f16 hr8.w, hr42.z, hr4.x, (last)hr8.w
mad.f16 hr33.x, hr42.w, hr45.y, (last)hr33.x
mad.f16 hr29.x, hr42.w, hr45.z, (last)hr29.x
mad.f16 hr25.x, hr42.w, hr45.w, (last)hr25.x
mad.f16 hr21.x, hr42.w, hr46.x, (last)hr21.x
mad.f16 hr17.x, hr42.w, hr3.z, (last)hr17.x
mad.f16 hr13.x, hr42.w, hr3.w, (last)hr13.x
mad.f16 hr9.x, hr42.w, hr4.x, (last)hr9.x
mad.f16 hr33.y, hr43.x, hr45.y, (last)hr33.y
mad.f16 hr29.y, hr43.x, hr45.z, (last)hr29.y
mad.f16 hr25.y, hr43.x, hr45.w, (last)hr25.y
mad.f16 hr21.y, hr43.x, hr46.x, (last)hr21.y
mad.f16 hr17.y, hr43.x, hr3.z, (last)hr17.y
mad.f16 hr13.y, hr43.x, hr3.w, (last)hr13.y
mad.f16 hr9.y, hr43.x, hr4.x, (last)hr9.y
mad.f16 hr31.z, hr43.y, hr45.y, (last)hr31.z
mad.f16 hr27.z, hr43.y, hr45.z, (last)hr27.z
mad.f16 hr23.z, hr43.y, hr45.w, (last)hr23.z
mad.f16 hr19.z, hr43.y, hr46.x, (last)hr19.z
mad.f16 hr15.z, hr43.y, hr3.z, (last)hr15.z
mad.f16 hr11.z, hr43.y, hr3.w, (last)hr11.z
mad.f16 hr7.z, hr43.y, hr4.x, (last)hr7.z
mad.f16 hr31.w, hr43.z, hr45.y, (last)hr31.w
mad.f16 hr27.w, hr43.z, hr45.z, (last)hr27.w
mad.f16 hr23.w, hr43.z, hr45.w, (last)hr23.w
mad.f16 hr19.w, hr43.z, hr46.x, (last)hr19.w
mad.f16 hr15.w, hr43.z, hr3.z, (last)hr15.w
mad.f16 hr11.w, hr43.z, hr3.w, (last)hr11.w
mad.f16 hr7.w, hr43.z, hr4.x, (last)hr7.w
(rpt1)mad.f16 hr32.x, (r)hr43.w, hr45.y, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr43.w, hr45.z, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr43.w, hr45.w, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr43.w, hr46.x, (r)(last)hr20.x
ldl.u16 r45.y, l[r18.y+2560], 4
(rpt1)mad.f16 hr16.x, (r)hr43.w, hr3.z, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr43.w, hr3.w, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr43.w, hr4.x, (r)(last)hr8.x
(rpt1)mad.f16 hr42.y, (r)(last)hr42.y, hr4.y, (r)(last)hr37.y
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr4.y, (r)(last)hr37.w
(rpt1)mad.f16 hr43.y, (r)(last)hr43.y, hr4.y, (r)(last)hr0.z
(rpt1)mad.f16 hr43.w, (r)(last)hr43.w, hr4.y, (r)(last)hr1.x
ldl.u16 r3.w, l[r18.y+2688], 4
ldl.u16 r37.y, l[r18.y+2816], 4
(sy)(ss)mad.f16 hr34.z, hr45.y, hr41.x, (last)hr34.z
mad.f16 hr30.z, hr45.y, hr41.y, (last)hr30.z
mad.f16 hr26.z, hr45.y, hr41.z, (last)hr26.z
mad.f16 hr22.z, hr45.y, hr41.w, (last)hr22.z
mad.f16 hr18.z, hr45.y, hr44.y, (last)hr18.z
mad.f16 hr14.z, hr45.y, hr44.z, (last)hr14.z
mad.f16 hr10.z, hr45.y, hr44.w, (last)hr10.z
mad.f16 hr34.w, hr45.z, hr41.x, (last)hr34.w
mad.f16 hr30.w, hr45.z, hr41.y, (last)hr30.w
mad.f16 hr26.w, hr45.z, hr41.z, (last)hr26.w
mad.f16 hr22.w, hr45.z, hr41.w, (last)hr22.w
mad.f16 hr18.w, hr45.z, hr44.y, (last)hr18.w
mad.f16 hr14.w, hr45.z, hr44.z, (last)hr14.w
mad.f16 hr10.w, hr45.z, hr44.w, (last)hr10.w
mad.f16 hr35.x, hr45.w, hr41.x, (last)hr35.x
mad.f16 hr31.x, hr45.w, hr41.y, (last)hr31.x
mad.f16 hr27.x, hr45.w, hr41.z, (last)hr27.x
mad.f16 hr23.x, hr45.w, hr41.w, (last)hr23.x
mad.f16 hr19.x, hr45.w, hr44.y, (last)hr19.x
mad.f16 hr15.x, hr45.w, hr44.z, (last)hr15.x
mad.f16 hr11.x, hr45.w, hr44.w, (last)hr11.x
mad.f16 hr35.y, hr46.x, hr41.x, (last)hr35.y
mad.f16 hr31.y, hr46.x, hr41.y, (last)hr31.y
mad.f16 hr27.y, hr46.x, hr41.z, (last)hr27.y
mad.f16 hr23.y, hr46.x, hr41.w, (last)hr23.y
mad.f16 hr19.y, hr46.x, hr44.y, (last)hr19.y
mad.f16 hr15.y, hr46.x, hr44.z, (last)hr15.y
mad.f16 hr11.y, hr46.x, hr44.w, (last)hr11.y
mad.f16 hr32.z, hr37.y, hr41.x, (last)hr32.z
mad.f16 hr28.z, hr37.y, hr41.y, (last)hr28.z
mad.f16 hr24.z, hr37.y, hr41.z, (last)hr24.z
mad.f16 hr20.z, hr37.y, hr41.w, (last)hr20.z
mad.f16 hr16.z, hr37.y, hr44.y, (last)hr16.z
mad.f16 hr12.z, hr37.y, hr44.z, (last)hr12.z
mad.f16 hr8.z, hr37.y, hr44.w, (last)hr8.z
mad.f16 hr32.w, hr37.z, hr41.x, (last)hr32.w
mad.f16 hr28.w, hr37.z, hr41.y, (last)hr28.w
mad.f16 hr24.w, hr37.z, hr41.z, (last)hr24.w
mad.f16 hr20.w, hr37.z, hr41.w, (last)hr20.w
mad.f16 hr16.w, hr37.z, hr44.y, (last)hr16.w
mad.f16 hr12.w, hr37.z, hr44.z, (last)hr12.w
mad.f16 hr8.w, hr37.z, hr44.w, (last)hr8.w
mad.f16 hr33.x, hr37.w, hr41.x, (last)hr33.x
mad.f16 hr29.x, hr37.w, hr41.y, (last)hr29.x
mad.f16 hr25.x, hr37.w, hr41.z, (last)hr25.x
mad.f16 hr21.x, hr37.w, hr41.w, (last)hr21.x
mad.f16 hr17.x, hr37.w, hr44.y, (last)hr17.x
mad.f16 hr13.x, hr37.w, hr44.z, (last)hr13.x
mad.f16 hr9.x, hr37.w, hr44.w, (last)hr9.x
(rpt1)mad.f16 hr45.y, (r)(last)hr45.y, hr45.x, (r)(last)hr5.w
(rpt1)mad.f16 hr45.w, (r)(last)hr45.w, hr45.x, (r)(last)hr6.y
isam.v.base0 (u16)(xyzw)hr5.w, r28.y, s#0, t#0
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr45.x, (r)(last)hr42.y
mad.f16 hr37.w, (last)hr37.w, hr45.x, (last)hr42.w
isam.v.base0 (u16)(xyzw)hr42.x, r28.z, s#0, t#0
mad.f16 hr33.z, hr3.w, hr41.x, (last)hr33.z
mad.f16 hr29.z, hr3.w, hr41.y, (last)hr29.z
mad.f16 hr25.z, hr3.w, hr41.z, (last)hr25.z
mad.f16 hr21.z, hr3.w, hr41.w, (last)hr21.z
mad.f16 hr17.z, hr3.w, hr44.y, (last)hr17.z
mad.f16 hr13.z, hr3.w, hr44.z, (last)hr13.z
mad.f16 hr9.z, hr3.w, hr44.w, (last)hr9.z
mad.f16 hr33.w, hr4.x, hr41.x, (last)hr33.w
mad.f16 hr29.w, hr4.x, hr41.y, (last)hr29.w
mad.f16 hr25.w, hr4.x, hr41.z, (last)hr25.w
mad.f16 hr21.w, hr4.x, hr41.w, (last)hr21.w
mad.f16 hr17.w, hr4.x, hr44.y, (last)hr17.w
mad.f16 hr13.w, hr4.x, hr44.z, (last)hr13.w
mad.f16 hr9.w, hr4.x, hr44.w, (last)hr9.w
mad.f16 hr34.x, hr4.y, hr41.x, (last)hr34.x
mad.f16 hr30.x, hr4.y, hr41.y, (last)hr30.x
mad.f16 hr26.x, hr4.y, hr41.z, (last)hr26.x
mad.f16 hr22.x, hr4.y, hr41.w, (last)hr22.x
mad.f16 hr18.x, hr4.y, hr44.y, (last)hr18.x
mad.f16 hr14.x, hr4.y, hr44.z, (last)hr14.x
mad.f16 hr10.x, hr4.y, hr44.w, (last)hr10.x
mad.f16 hr34.y, hr4.z, hr41.x, (last)hr34.y
mad.f16 hr30.y, hr4.z, hr41.y, (last)hr30.y
mad.f16 hr26.y, hr4.z, hr41.z, (last)hr26.y
mad.f16 hr22.y, hr4.z, hr41.w, (last)hr22.y
mad.f16 hr18.y, hr4.z, hr44.y, (last)hr18.y
mad.f16 hr14.y, hr4.z, hr44.z, (last)hr14.y
mad.f16 hr10.y, hr4.z, hr44.w, (last)hr10.y
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr45.x, (r)(last)hr4.w
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr45.x, (r)(last)hr5.y
ldl.u16 r4.w, l[r18.y+2944], 4
mad.f16 hr33.y, hr38.x, hr41.x, (last)hr33.y
mad.f16 hr29.y, hr38.x, hr41.y, (last)hr29.y
mad.f16 hr25.y, hr38.x, hr41.z, (last)hr25.y
mad.f16 hr21.y, hr38.x, hr41.w, (last)hr21.y
mad.f16 hr17.y, hr38.x, hr44.y, (last)hr17.y
mad.f16 hr13.y, hr38.x, hr44.z, (last)hr13.y
mad.f16 hr9.y, hr38.x, hr44.w, (last)hr9.y
mad.f16 hr38.x, (last)hr38.x, hr45.x, (last)hr43.x
(ss)mad.f16 hr31.z, hr4.w, hr41.x, (last)hr31.z
mad.f16 hr27.z, hr4.w, hr41.y, (last)hr27.z
mad.f16 hr23.z, hr4.w, hr41.z, (last)hr23.z
mad.f16 hr19.z, hr4.w, hr41.w, (last)hr19.z
mad.f16 hr15.z, hr4.w, hr44.y, (last)hr15.z
mad.f16 hr11.z, hr4.w, hr44.z, (last)hr11.z
mad.f16 hr7.z, hr4.w, hr44.w, (last)hr7.z
mad.f16 hr31.w, hr5.x, hr41.x, (last)hr31.w
mad.f16 hr27.w, hr5.x, hr41.y, (last)hr27.w
mad.f16 hr23.w, hr5.x, hr41.z, (last)hr23.w
mad.f16 hr19.w, hr5.x, hr41.w, (last)hr19.w
mad.f16 hr15.w, hr5.x, hr44.y, (last)hr15.w
mad.f16 hr11.w, hr5.x, hr44.z, (last)hr11.w
mad.f16 hr7.w, hr5.x, hr44.w, (last)hr7.w
(rpt1)mad.f16 hr32.x, (r)hr5.y, hr41.x, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr5.y, hr41.y, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr5.y, hr41.z, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr5.y, hr41.w, (r)(last)hr20.x
(rpt1)mad.f16 hr16.x, (r)hr5.y, hr44.y, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr5.y, hr44.z, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr5.y, hr44.w, (r)(last)hr8.x
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr45.x, (r)(last)hr43.y
mad.f16 hr5.y, (last)hr5.y, hr45.x, (last)hr43.w
ldl.u16 r43.x, l[r18.y+3072], 4
mad.f16 hr5.z, (last)hr5.z, hr45.x, (last)hr44.x
ldl.u16 r44.y, l[r18.y+3200], 4
ldl.u16 r0.z, l[r18.y+3328], 4
(sy)(ss)mad.f16 hr34.z, hr43.x, hr5.w, (last)hr34.z
mad.f16 hr30.z, hr43.x, hr6.x, (last)hr30.z
mad.f16 hr26.z, hr43.x, hr6.y, (last)hr26.z
mad.f16 hr22.z, hr43.x, hr6.z, (last)hr22.z
mad.f16 hr18.z, hr43.x, hr42.x, (last)hr18.z
mad.f16 hr14.z, hr43.x, hr42.y, (last)hr14.z
mad.f16 hr10.z, hr43.x, hr42.z, (last)hr10.z
mad.f16 hr34.w, hr43.y, hr5.w, (last)hr34.w
mad.f16 hr30.w, hr43.y, hr6.x, (last)hr30.w
mad.f16 hr26.w, hr43.y, hr6.y, (last)hr26.w
mad.f16 hr22.w, hr43.y, hr6.z, (last)hr22.w
mad.f16 hr18.w, hr43.y, hr42.x, (last)hr18.w
mad.f16 hr14.w, hr43.y, hr42.y, (last)hr14.w
mad.f16 hr10.w, hr43.y, hr42.z, (last)hr10.w
mad.f16 hr35.x, hr43.z, hr5.w, (last)hr35.x
mad.f16 hr31.x, hr43.z, hr6.x, (last)hr31.x
mad.f16 hr27.x, hr43.z, hr6.y, (last)hr27.x
mad.f16 hr23.x, hr43.z, hr6.z, (last)hr23.x
mad.f16 hr19.x, hr43.z, hr42.x, (last)hr19.x
mad.f16 hr15.x, hr43.z, hr42.y, (last)hr15.x
mad.f16 hr11.x, hr43.z, hr42.z, (last)hr11.x
mad.f16 hr35.y, hr43.w, hr5.w, (last)hr35.y
mad.f16 hr31.y, hr43.w, hr6.x, (last)hr31.y
mad.f16 hr27.y, hr43.w, hr6.y, (last)hr27.y
mad.f16 hr23.y, hr43.w, hr6.z, (last)hr23.y
mad.f16 hr19.y, hr43.w, hr42.x, (last)hr19.y
mad.f16 hr15.y, hr43.w, hr42.y, (last)hr15.y
mad.f16 hr11.y, hr43.w, hr42.z, (last)hr11.y
mad.f16 hr32.z, hr0.z, hr5.w, (last)hr32.z
mad.f16 hr28.z, hr0.z, hr6.x, (last)hr28.z
mad.f16 hr24.z, hr0.z, hr6.y, (last)hr24.z
mad.f16 hr20.z, hr0.z, hr6.z, (last)hr20.z
mad.f16 hr16.z, hr0.z, hr42.x, (last)hr16.z
mad.f16 hr12.z, hr0.z, hr42.y, (last)hr12.z
mad.f16 hr8.z, hr0.z, hr42.z, (last)hr8.z
mad.f16 hr32.w, hr0.w, hr5.w, (last)hr32.w
mad.f16 hr28.w, hr0.w, hr6.x, (last)hr28.w
mad.f16 hr24.w, hr0.w, hr6.y, (last)hr24.w
mad.f16 hr20.w, hr0.w, hr6.z, (last)hr20.w
mad.f16 hr16.w, hr0.w, hr42.x, (last)hr16.w
mad.f16 hr12.w, hr0.w, hr42.y, (last)hr12.w
mad.f16 hr8.w, hr0.w, hr42.z, (last)hr8.w
mad.f16 hr33.x, hr1.x, hr5.w, (last)hr33.x
mad.f16 hr29.x, hr1.x, hr6.x, (last)hr29.x
mad.f16 hr25.x, hr1.x, hr6.y, (last)hr25.x
mad.f16 hr21.x, hr1.x, hr6.z, (last)hr21.x
mad.f16 hr17.x, hr1.x, hr42.x, (last)hr17.x
mad.f16 hr13.x, hr1.x, hr42.y, (last)hr13.x
mad.f16 hr9.x, hr1.x, hr42.z, (last)hr9.x
(rpt1)mad.f16 hr43.x, (r)(last)hr43.x, hr42.w, (r)(last)hr45.y
(rpt1)mad.f16 hr43.z, (r)(last)hr43.z, hr42.w, (r)(last)hr45.w
isam.v.base0 (u16)(xyzw)hr45.y, r28.w, s#0, t#0
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr42.w, (r)(last)hr37.y
mad.f16 hr1.x, (last)hr1.x, hr42.w, (last)hr37.w
isam.v.base0 (u16)(xyzw)hr37.x, r29.x, s#0, t#0
mad.f16 hr33.z, hr44.y, hr5.w, (last)hr33.z
mad.f16 hr29.z, hr44.y, hr6.x, (last)hr29.z
mad.f16 hr25.z, hr44.y, hr6.y, (last)hr25.z
mad.f16 hr21.z, hr44.y, hr6.z, (last)hr21.z
mad.f16 hr17.z, hr44.y, hr42.x, (last)hr17.z
mad.f16 hr13.z, hr44.y, hr42.y, (last)hr13.z
mad.f16 hr9.z, hr44.y, hr42.z, (last)hr9.z
mad.f16 hr33.w, hr44.z, hr5.w, (last)hr33.w
mad.f16 hr29.w, hr44.z, hr6.x, (last)hr29.w
mad.f16 hr25.w, hr44.z, hr6.y, (last)hr25.w
mad.f16 hr21.w, hr44.z, hr6.z, (last)hr21.w
mad.f16 hr17.w, hr44.z, hr42.x, (last)hr17.w
mad.f16 hr13.w, hr44.z, hr42.y, (last)hr13.w
mad.f16 hr9.w, hr44.z, hr42.z, (last)hr9.w
mad.f16 hr34.x, hr44.w, hr5.w, (last)hr34.x
mad.f16 hr30.x, hr44.w, hr6.x, (last)hr30.x
mad.f16 hr26.x, hr44.w, hr6.y, (last)hr26.x
mad.f16 hr22.x, hr44.w, hr6.z, (last)hr22.x
mad.f16 hr18.x, hr44.w, hr42.x, (last)hr18.x
mad.f16 hr14.x, hr44.w, hr42.y, (last)hr14.x
mad.f16 hr10.x, hr44.w, hr42.z, (last)hr10.x
mad.f16 hr33.y, hr1.y, hr5.w, (last)hr33.y
mad.f16 hr29.y, hr1.y, hr6.x, (last)hr29.y
mad.f16 hr25.y, hr1.y, hr6.y, (last)hr25.y
mad.f16 hr21.y, hr1.y, hr6.z, (last)hr21.y
mad.f16 hr17.y, hr1.y, hr42.x, (last)hr17.y
mad.f16 hr13.y, hr1.y, hr42.y, (last)hr13.y
mad.f16 hr9.y, hr1.y, hr42.z, (last)hr9.y
(rpt1)mad.f16 hr44.y, (r)(last)hr44.y, hr42.w, (r)(last)hr3.w
mad.f16 hr44.w, (last)hr44.w, hr42.w, (last)hr4.y
ldl.u16 r3.z, l[r18.y+3456], 4
mad.f16 hr1.y, (last)hr1.y, hr42.w, (last)hr38.x
ldl.u16 r38.x, l[r18.y+3584], 4
ldl.u16 r41.x, l[r18.y+3712], 4
mad.f16 hr34.y, hr45.x, hr5.w, (last)hr34.y
mad.f16 hr30.y, hr45.x, hr6.x, (last)hr30.y
mad.f16 hr26.y, hr45.x, hr6.y, (last)hr26.y
mad.f16 hr22.y, hr45.x, hr6.z, (last)hr22.y
mad.f16 hr18.y, hr45.x, hr42.x, (last)hr18.y
mad.f16 hr14.y, hr45.x, hr42.y, (last)hr14.y
mad.f16 hr10.y, hr45.x, hr42.z, (last)hr10.y
mad.f16 hr45.x, (last)hr45.x, hr42.w, (last)hr4.z
(sy)(ss)mad.f16 hr34.w, hr38.y, hr45.y, (last)hr34.w
mad.f16 hr30.w, hr38.y, hr45.z, (last)hr30.w
mad.f16 hr26.w, hr38.y, hr45.w, (last)hr26.w
mad.f16 hr22.w, hr38.y, hr46.x, (last)hr22.w
mad.f16 hr18.w, hr38.y, hr37.x, (last)hr18.w
mad.f16 hr14.w, hr38.y, hr37.y, (last)hr14.w
mad.f16 hr10.w, hr38.y, hr37.z, (last)hr10.w
mad.f16 hr35.x, hr38.z, hr45.y, (last)hr35.x
mad.f16 hr31.x, hr38.z, hr45.z, (last)hr31.x
mad.f16 hr27.x, hr38.z, hr45.w, (last)hr27.x
mad.f16 hr23.x, hr38.z, hr46.x, (last)hr23.x
mad.f16 hr19.x, hr38.z, hr37.x, (last)hr19.x
mad.f16 hr15.x, hr38.z, hr37.y, (last)hr15.x
mad.f16 hr11.x, hr38.z, hr37.z, (last)hr11.x
mad.f16 hr35.y, hr38.w, hr45.y, (last)hr35.y
mad.f16 hr31.y, hr38.w, hr45.z, (last)hr31.y
mad.f16 hr27.y, hr38.w, hr45.w, (last)hr27.y
mad.f16 hr23.y, hr38.w, hr46.x, (last)hr23.y
mad.f16 hr19.y, hr38.w, hr37.x, (last)hr19.y
mad.f16 hr15.y, hr38.w, hr37.y, (last)hr15.y
mad.f16 hr11.y, hr38.w, hr37.z, (last)hr11.y
mad.f16 hr38.y, (last)hr38.y, hr37.w, (last)hr43.y
(rpt1)mad.f16 hr38.z, (r)(last)hr38.z, hr37.w, (r)(last)hr43.z
ldl.u16 r43.y, l[r18.y+3840], 4
mad.f16 hr31.z, hr3.z, hr5.w, (last)hr31.z
mad.f16 hr27.z, hr3.z, hr6.x, (last)hr27.z
mad.f16 hr23.z, hr3.z, hr6.y, (last)hr23.z
mad.f16 hr19.z, hr3.z, hr6.z, (last)hr19.z
mad.f16 hr15.z, hr3.z, hr42.x, (last)hr15.z
mad.f16 hr11.z, hr3.z, hr42.y, (last)hr11.z
mad.f16 hr7.z, hr3.z, hr42.z, (last)hr7.z
mad.f16 hr31.w, hr3.w, hr5.w, (last)hr31.w
mad.f16 hr27.w, hr3.w, hr6.x, (last)hr27.w
mad.f16 hr23.w, hr3.w, hr6.y, (last)hr23.w
mad.f16 hr19.w, hr3.w, hr6.z, (last)hr19.w
mad.f16 hr15.w, hr3.w, hr42.x, (last)hr15.w
mad.f16 hr11.w, hr3.w, hr42.y, (last)hr11.w
mad.f16 hr7.w, hr3.w, hr42.z, (last)hr7.w
(rpt1)mad.f16 hr32.x, (r)hr4.x, hr5.w, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr4.x, hr6.x, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr4.x, hr6.y, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr4.x, hr6.z, (r)(last)hr20.x
(rpt1)mad.f16 hr16.x, (r)hr4.x, hr42.x, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr4.x, hr42.y, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr4.x, hr42.z, (r)(last)hr8.x
(ss)mad.f16 hr32.z, hr43.y, hr45.y, (last)hr32.z
mad.f16 hr28.z, hr43.y, hr45.z, (last)hr28.z
mad.f16 hr24.z, hr43.y, hr45.w, (last)hr24.z
mad.f16 hr20.z, hr43.y, hr46.x, (last)hr20.z
mad.f16 hr16.z, hr43.y, hr37.x, (last)hr16.z
mad.f16 hr12.z, hr43.y, hr37.y, (last)hr12.z
mad.f16 hr8.z, hr43.y, hr37.z, (last)hr8.z
mad.f16 hr32.w, hr43.z, hr45.y, (last)hr32.w
mad.f16 hr28.w, hr43.z, hr45.z, (last)hr28.w
mad.f16 hr24.w, hr43.z, hr45.w, (last)hr24.w
mad.f16 hr20.w, hr43.z, hr46.x, (last)hr20.w
mad.f16 hr16.w, hr43.z, hr37.x, (last)hr16.w
mad.f16 hr12.w, hr43.z, hr37.y, (last)hr12.w
mad.f16 hr8.w, hr43.z, hr37.z, (last)hr8.w
mad.f16 hr33.x, hr43.w, hr45.y, (last)hr33.x
mad.f16 hr29.x, hr43.w, hr45.z, (last)hr29.x
mad.f16 hr25.x, hr43.w, hr45.w, (last)hr25.x
mad.f16 hr21.x, hr43.w, hr46.x, (last)hr21.x
mad.f16 hr17.x, hr43.w, hr37.x, (last)hr17.x
mad.f16 hr13.x, hr43.w, hr37.y, (last)hr13.x
mad.f16 hr9.x, hr43.w, hr37.z, (last)hr9.x
mad.f16 hr33.y, hr44.x, hr45.y, (last)hr33.y
mad.f16 hr29.y, hr44.x, hr45.z, (last)hr29.y
mad.f16 hr25.y, hr44.x, hr45.w, (last)hr25.y
mad.f16 hr21.y, hr44.x, hr46.x, (last)hr21.y
mad.f16 hr17.y, hr44.x, hr37.x, (last)hr17.y
mad.f16 hr13.y, hr44.x, hr37.y, (last)hr13.y
mad.f16 hr9.y, hr44.x, hr37.z, (last)hr9.y
(rpt1)mad.f16 hr3.z, (r)(last)hr3.z, hr42.w, (r)(last)hr4.w
(rpt1)mad.f16 hr4.x, (r)(last)hr4.x, hr42.w, (r)(last)hr5.y
isam.v.base0 (u16)(xyzw)hr42.x, r29.y, s#0, t#0
(rpt1)mad.f16 hr43.y, (r)(last)hr43.y, hr37.w, (r)(last)hr0.z
(rpt1)mad.f16 hr43.w, (r)(last)hr43.w, hr37.w, (r)(last)hr1.x
isam.v.base0 (u16)(xyzw)hr0.z, r29.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr5.w, r29.w, s#0, t#0
mad.f16 hr33.z, hr41.x, hr45.y, (last)hr33.z
mad.f16 hr29.z, hr41.x, hr45.z, (last)hr29.z
mad.f16 hr25.z, hr41.x, hr45.w, (last)hr25.z
mad.f16 hr21.z, hr41.x, hr46.x, (last)hr21.z
mad.f16 hr17.z, hr41.x, hr37.x, (last)hr17.z
mad.f16 hr13.z, hr41.x, hr37.y, (last)hr13.z
mad.f16 hr9.z, hr41.x, hr37.z, (last)hr9.z
mad.f16 hr33.w, hr41.y, hr45.y, (last)hr33.w
mad.f16 hr29.w, hr41.y, hr45.z, (last)hr29.w
mad.f16 hr25.w, hr41.y, hr45.w, (last)hr25.w
mad.f16 hr21.w, hr41.y, hr46.x, (last)hr21.w
mad.f16 hr17.w, hr41.y, hr37.x, (last)hr17.w
mad.f16 hr13.w, hr41.y, hr37.y, (last)hr13.w
mad.f16 hr9.w, hr41.y, hr37.z, (last)hr9.w
mad.f16 hr34.x, hr41.z, hr45.y, (last)hr34.x
mad.f16 hr30.x, hr41.z, hr45.z, (last)hr30.x
mad.f16 hr26.x, hr41.z, hr45.w, (last)hr26.x
mad.f16 hr22.x, hr41.z, hr46.x, (last)hr22.x
mad.f16 hr18.x, hr41.z, hr37.x, (last)hr18.x
mad.f16 hr14.x, hr41.z, hr37.y, (last)hr14.x
mad.f16 hr10.x, hr41.z, hr37.z, (last)hr10.x
mad.f16 hr34.y, hr41.w, hr45.y, (last)hr34.y
mad.f16 hr30.y, hr41.w, hr45.z, (last)hr30.y
mad.f16 hr26.y, hr41.w, hr45.w, (last)hr26.y
mad.f16 hr22.y, hr41.w, hr46.x, (last)hr22.y
mad.f16 hr18.y, hr41.w, hr37.x, (last)hr18.y
mad.f16 hr14.y, hr41.w, hr37.y, (last)hr14.y
mad.f16 hr10.y, hr41.w, hr37.z, (last)hr10.y
(rpt1)mad.f16 hr41.x, (r)(last)hr41.x, hr37.w, (r)(last)hr44.y
(rpt1)mad.f16 hr41.z, (r)(last)hr41.z, hr37.w, (r)(last)hr44.w
ldl.u16 r44.y, l[r18.y+3968], 4
mad.f16 hr34.z, hr38.x, hr45.y, (last)hr34.z
mad.f16 hr30.z, hr38.x, hr45.z, (last)hr30.z
mad.f16 hr26.z, hr38.x, hr45.w, (last)hr26.z
mad.f16 hr22.z, hr38.x, hr46.x, (last)hr22.z
mad.f16 hr18.z, hr38.x, hr37.x, (last)hr18.z
mad.f16 hr14.z, hr38.x, hr37.y, (last)hr14.z
mad.f16 hr10.z, hr38.x, hr37.z, (last)hr10.z
mad.f16 hr38.x, (last)hr38.x, hr37.w, (last)hr43.x
(ss)mad.f16 hr31.w, hr44.z, hr45.y, (last)hr31.w
mad.f16 hr27.w, hr44.z, hr45.z, (last)hr27.w
mad.f16 hr23.w, hr44.z, hr45.w, (last)hr23.w
mad.f16 hr19.w, hr44.z, hr46.x, (last)hr19.w
mad.f16 hr15.w, hr44.z, hr37.x, (last)hr15.w
mad.f16 hr11.w, hr44.z, hr37.y, (last)hr11.w
mad.f16 hr7.w, hr44.z, hr37.z, (last)hr7.w
(rpt1)mad.f16 hr32.x, (r)hr44.w, hr45.y, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr44.w, hr45.z, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr44.w, hr45.w, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr44.w, hr46.x, (r)(last)hr20.x
(rpt1)mad.f16 hr16.x, (r)hr44.w, hr37.x, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr44.w, hr37.y, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr44.w, hr37.z, (r)(last)hr8.x
mad.f16 hr44.z, (last)hr44.z, hr37.w, (last)hr3.w
(rpt1)mad.f16 hr44.w, (r)(last)hr44.w, hr37.w, (r)(last)hr4.x
ldl.u16 r3.w, l[r23.z], 4
ldl.u16 r4.w, l[r23.z+128], 4
mad.f16 hr31.z, hr44.y, hr45.y, (last)hr31.z
mad.f16 hr27.z, hr44.y, hr45.z, (last)hr27.z
mad.f16 hr23.z, hr44.y, hr45.w, (last)hr23.z
mad.f16 hr19.z, hr44.y, hr46.x, (last)hr19.z
mad.f16 hr15.z, hr44.y, hr37.x, (last)hr15.z
mad.f16 hr11.z, hr44.y, hr37.y, (last)hr11.z
mad.f16 hr7.z, hr44.y, hr37.z, (last)hr7.z
ldl.u16 r36.w, l[r23.z+256], 4
mad.f16 hr44.y, (last)hr44.y, hr37.w, (last)hr3.z
(sy)(ss)mad.f16 hr33.z, hr4.w, hr42.x, (last)hr33.z
mad.f16 hr29.z, hr4.w, hr42.y, (last)hr29.z
mad.f16 hr25.z, hr4.w, hr42.z, (last)hr25.z
mad.f16 hr21.z, hr4.w, hr42.w, (last)hr21.z
mad.f16 hr17.z, hr4.w, hr0.z, (last)hr17.z
mad.f16 hr13.z, hr4.w, hr0.w, (last)hr13.z
mad.f16 hr9.z, hr4.w, hr1.x, (last)hr9.z
mad.f16 hr33.w, hr5.x, hr42.x, (last)hr33.w
mad.f16 hr29.w, hr5.x, hr42.y, (last)hr29.w
mad.f16 hr25.w, hr5.x, hr42.z, (last)hr25.w
mad.f16 hr21.w, hr5.x, hr42.w, (last)hr21.w
mad.f16 hr17.w, hr5.x, hr0.z, (last)hr17.w
mad.f16 hr13.w, hr5.x, hr0.w, (last)hr13.w
mad.f16 hr9.w, hr5.x, hr1.x, (last)hr9.w
mad.f16 hr34.x, hr5.y, hr42.x, (last)hr34.x
mad.f16 hr30.x, hr5.y, hr42.y, (last)hr30.x
mad.f16 hr26.x, hr5.y, hr42.z, (last)hr26.x
mad.f16 hr22.x, hr5.y, hr42.w, (last)hr22.x
mad.f16 hr18.x, hr5.y, hr0.z, (last)hr18.x
mad.f16 hr14.x, hr5.y, hr0.w, (last)hr14.x
mad.f16 hr10.x, hr5.y, hr1.x, (last)hr10.x
mad.f16 hr34.y, hr5.z, hr42.x, (last)hr34.y
mad.f16 hr30.y, hr5.z, hr42.y, (last)hr30.y
mad.f16 hr26.y, hr5.z, hr42.z, (last)hr26.y
mad.f16 hr22.y, hr5.z, hr42.w, (last)hr22.y
mad.f16 hr18.y, hr5.z, hr0.z, (last)hr18.y
mad.f16 hr14.y, hr5.z, hr0.w, (last)hr14.y
mad.f16 hr10.y, hr5.z, hr1.x, (last)hr10.y
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr1.y, (r)(last)hr41.x
(rpt1)mad.f16 hr5.y, (r)(last)hr5.y, hr1.y, (r)(last)hr41.z
isam.v.base0 (u16)(xyzw)hr41.x, r30.x, s#0, t#0
mad.f16 hr34.z, hr3.w, hr42.x, (last)hr34.z
mad.f16 hr30.z, hr3.w, hr42.y, (last)hr30.z
mad.f16 hr26.z, hr3.w, hr42.z, (last)hr26.z
mad.f16 hr22.z, hr3.w, hr42.w, (last)hr22.z
mad.f16 hr18.z, hr3.w, hr0.z, (last)hr18.z
mad.f16 hr14.z, hr3.w, hr0.w, (last)hr14.z
mad.f16 hr10.z, hr3.w, hr1.x, (last)hr10.z
mad.f16 hr34.w, hr4.x, hr42.x, (last)hr34.w
mad.f16 hr30.w, hr4.x, hr42.y, (last)hr30.w
mad.f16 hr26.w, hr4.x, hr42.z, (last)hr26.w
mad.f16 hr22.w, hr4.x, hr42.w, (last)hr22.w
mad.f16 hr18.w, hr4.x, hr0.z, (last)hr18.w
mad.f16 hr14.w, hr4.x, hr0.w, (last)hr14.w
mad.f16 hr10.w, hr4.x, hr1.x, (last)hr10.w
mad.f16 hr35.x, hr4.y, hr42.x, (last)hr35.x
mad.f16 hr31.x, hr4.y, hr42.y, (last)hr31.x
mad.f16 hr27.x, hr4.y, hr42.z, (last)hr27.x
mad.f16 hr23.x, hr4.y, hr42.w, (last)hr23.x
mad.f16 hr19.x, hr4.y, hr0.z, (last)hr19.x
mad.f16 hr15.x, hr4.y, hr0.w, (last)hr15.x
mad.f16 hr11.x, hr4.y, hr1.x, (last)hr11.x
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr1.y, (r)(last)hr38.x
mad.f16 hr4.y, (last)hr4.y, hr1.y, (last)hr38.z
ldl.u16 r37.w, l[r23.z+384], 4
mad.f16 hr31.y, hr4.z, hr42.y, (last)hr31.y
mad.f16 hr27.y, hr4.z, hr42.z, (last)hr27.y
mad.f16 hr23.y, hr4.z, hr42.w, (last)hr23.y
mad.f16 hr32.z, hr36.w, hr42.x, (last)hr32.z
mad.f16 hr28.z, hr36.w, hr42.y, (last)hr28.z
mad.f16 hr24.z, hr36.w, hr42.z, (last)hr24.z
mad.f16 hr20.z, hr36.w, hr42.w, (last)hr20.z
mad.f16 hr16.z, hr36.w, hr0.z, (last)hr16.z
mad.f16 hr12.z, hr36.w, hr0.w, (last)hr12.z
mad.f16 hr8.z, hr36.w, hr1.x, (last)hr8.z
mad.f16 hr32.w, hr37.x, hr42.x, (last)hr32.w
mad.f16 hr28.w, hr37.x, hr42.y, (last)hr28.w
mad.f16 hr24.w, hr37.x, hr42.z, (last)hr24.w
mad.f16 hr20.w, hr37.x, hr42.w, (last)hr20.w
mad.f16 hr16.w, hr37.x, hr0.z, (last)hr16.w
mad.f16 hr12.w, hr37.x, hr0.w, (last)hr12.w
mad.f16 hr8.w, hr37.x, hr1.x, (last)hr8.w
mad.f16 hr33.x, hr37.y, hr42.x, (last)hr33.x
mad.f16 hr29.x, hr37.y, hr42.y, (last)hr29.x
mad.f16 hr25.x, hr37.y, hr42.z, (last)hr25.x
mad.f16 hr21.x, hr37.y, hr42.w, (last)hr21.x
mad.f16 hr17.x, hr37.y, hr0.z, (last)hr17.x
mad.f16 hr13.x, hr37.y, hr0.w, (last)hr13.x
mad.f16 hr9.x, hr37.y, hr1.x, (last)hr9.x
mad.f16 hr33.y, hr37.z, hr42.x, (last)hr33.y
mad.f16 hr29.y, hr37.z, hr42.y, (last)hr29.y
mad.f16 hr25.y, hr37.z, hr42.z, (last)hr25.y
mad.f16 hr21.y, hr37.z, hr42.w, (last)hr21.y
mad.f16 hr17.y, hr37.z, hr0.z, (last)hr17.y
mad.f16 hr13.y, hr37.z, hr0.w, (last)hr13.y
mad.f16 hr9.y, hr37.z, hr1.x, (last)hr9.y
(ss)mad.f16 hr27.z, hr37.w, hr42.y, (last)hr27.z
mad.f16 hr23.z, hr37.w, hr42.z, (last)hr23.z
mad.f16 hr19.z, hr37.w, hr42.w, (last)hr19.z
mad.f16 hr27.w, hr38.x, hr42.y, (last)hr27.w
mad.f16 hr23.w, hr38.x, hr42.z, (last)hr23.w
mad.f16 hr19.w, hr38.x, hr42.w, (last)hr19.w
(rpt1)mad.f16 hr28.x, (r)hr38.y, hr42.y, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr38.y, hr42.z, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr38.y, hr42.w, (r)(last)hr20.x
ldl.u16 r42.y, l[r23.w], 4
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr1.y, (r)(last)hr43.y
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr1.y, (r)(last)hr43.w
ldl.u16 r43.y, l[r23.w+128], 4
ldl.u16 r45.y, l[r23.w+256], 4
mad.f16 hr31.z, hr37.w, hr42.x, (last)hr31.z
mad.f16 hr15.z, hr37.w, hr0.z, (last)hr15.z
mad.f16 hr11.z, hr37.w, hr0.w, (last)hr11.z
mad.f16 hr7.z, hr37.w, hr1.x, (last)hr7.z
mad.f16 hr31.w, hr38.x, hr42.x, (last)hr31.w
mad.f16 hr15.w, hr38.x, hr0.z, (last)hr15.w
mad.f16 hr11.w, hr38.x, hr0.w, (last)hr11.w
mad.f16 hr7.w, hr38.x, hr1.x, (last)hr7.w
(rpt1)mad.f16 hr32.x, (r)hr38.y, hr42.x, (r)(last)hr32.x
(rpt1)mad.f16 hr16.x, (r)hr38.y, hr0.z, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr38.y, hr0.w, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr38.y, hr1.x, (r)(last)hr8.x
(ss)mad.f16 hr33.z, hr43.y, hr5.w, (last)hr33.z
mad.f16 hr29.z, hr43.y, hr6.x, (last)hr29.z
mad.f16 hr25.z, hr43.y, hr6.y, (last)hr25.z
mad.f16 hr21.z, hr43.y, hr6.z, (last)hr21.z
(sy)mad.f16 hr17.z, hr43.y, hr41.x, (last)hr17.z
mad.f16 hr13.z, hr43.y, hr41.y, (last)hr13.z
mad.f16 hr9.z, hr43.y, hr41.z, (last)hr9.z
mad.f16 hr33.w, hr43.z, hr5.w, (last)hr33.w
mad.f16 hr29.w, hr43.z, hr6.x, (last)hr29.w
mad.f16 hr25.w, hr43.z, hr6.y, (last)hr25.w
mad.f16 hr21.w, hr43.z, hr6.z, (last)hr21.w
mad.f16 hr17.w, hr43.z, hr41.x, (last)hr17.w
mad.f16 hr13.w, hr43.z, hr41.y, (last)hr13.w
mad.f16 hr9.w, hr43.z, hr41.z, (last)hr9.w
mad.f16 hr34.x, hr43.w, hr5.w, (last)hr34.x
mad.f16 hr30.x, hr43.w, hr6.x, (last)hr30.x
mad.f16 hr26.x, hr43.w, hr6.y, (last)hr26.x
mad.f16 hr22.x, hr43.w, hr6.z, (last)hr22.x
mad.f16 hr18.x, hr43.w, hr41.x, (last)hr18.x
mad.f16 hr14.x, hr43.w, hr41.y, (last)hr14.x
mad.f16 hr10.x, hr43.w, hr41.z, (last)hr10.x
mad.f16 hr34.y, hr44.x, hr5.w, (last)hr34.y
mad.f16 hr30.y, hr44.x, hr6.x, (last)hr30.y
mad.f16 hr26.y, hr44.x, hr6.y, (last)hr26.y
mad.f16 hr22.y, hr44.x, hr6.z, (last)hr22.y
mad.f16 hr18.y, hr44.x, hr41.x, (last)hr18.y
mad.f16 hr14.y, hr44.x, hr41.y, (last)hr14.y
mad.f16 hr10.y, hr44.x, hr41.z, (last)hr10.y
(rpt1)mad.f16 hr37.w, (r)(last)hr37.w, hr1.y, (r)(last)hr44.y
(rpt1)mad.f16 hr38.y, (r)(last)hr38.y, hr1.y, (r)(last)hr44.w
isam.v.base0 (u16)(xyzw)hr44.y, r30.y, s#0, t#0
(rpt1)mad.f16 hr43.y, (r)(last)hr43.y, hr41.w, (r)(last)hr4.w
(rpt1)mad.f16 hr43.w, (r)(last)hr43.w, hr41.w, (r)(last)hr5.y
isam.v.base0 (u16)(xyzw)hr4.w, r30.z, s#0, t#0
mad.f16 hr35.y, hr4.z, hr42.x, (last)hr35.y
mad.f16 hr19.y, hr4.z, hr0.z, (last)hr19.y
mad.f16 hr15.y, hr4.z, hr0.w, (last)hr15.y
mad.f16 hr11.y, hr4.z, hr1.x, (last)hr11.y
mad.f16 hr4.z, (last)hr4.z, hr1.y, (last)hr38.w
mad.f16 hr34.z, hr42.y, hr5.w, (last)hr34.z
mad.f16 hr30.z, hr42.y, hr6.x, (last)hr30.z
mad.f16 hr26.z, hr42.y, hr6.y, (last)hr26.z
mad.f16 hr22.z, hr42.y, hr6.z, (last)hr22.z
mad.f16 hr18.z, hr42.y, hr41.x, (last)hr18.z
mad.f16 hr14.z, hr42.y, hr41.y, (last)hr14.z
mad.f16 hr10.z, hr42.y, hr41.z, (last)hr10.z
mad.f16 hr34.w, hr42.z, hr5.w, (last)hr34.w
mad.f16 hr30.w, hr42.z, hr6.x, (last)hr30.w
mad.f16 hr26.w, hr42.z, hr6.y, (last)hr26.w
mad.f16 hr22.w, hr42.z, hr6.z, (last)hr22.w
mad.f16 hr18.w, hr42.z, hr41.x, (last)hr18.w
mad.f16 hr14.w, hr42.z, hr41.y, (last)hr14.w
mad.f16 hr10.w, hr42.z, hr41.z, (last)hr10.w
mad.f16 hr35.x, hr42.w, hr5.w, (last)hr35.x
mad.f16 hr31.x, hr42.w, hr6.x, (last)hr31.x
mad.f16 hr27.x, hr42.w, hr6.y, (last)hr27.x
mad.f16 hr23.x, hr42.w, hr6.z, (last)hr23.x
mad.f16 hr19.x, hr42.w, hr41.x, (last)hr19.x
mad.f16 hr15.x, hr42.w, hr41.y, (last)hr15.x
mad.f16 hr11.x, hr42.w, hr41.z, (last)hr11.x
mad.f16 hr31.y, hr43.x, hr6.x, (last)hr31.y
mad.f16 hr27.y, hr43.x, hr6.y, (last)hr27.y
mad.f16 hr23.y, hr43.x, hr6.z, (last)hr23.y
mad.f16 hr35.y, hr43.x, hr5.w, (last)hr35.y
mad.f16 hr19.y, hr43.x, hr41.x, (last)hr19.y
mad.f16 hr15.y, hr43.x, hr41.y, (last)hr15.y
mad.f16 hr11.y, hr43.x, hr41.z, (last)hr11.y
(rpt1)mad.f16 hr42.y, (r)(last)hr42.y, hr41.w, (r)(last)hr3.w
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr41.w, (r)(last)hr4.y
ldl.u16 r3.w, l[r23.w+384], 4
mad.f16 hr32.z, hr45.y, hr5.w, (last)hr32.z
mad.f16 hr28.z, hr45.y, hr6.x, (last)hr28.z
mad.f16 hr24.z, hr45.y, hr6.y, (last)hr24.z
mad.f16 hr20.z, hr45.y, hr6.z, (last)hr20.z
mad.f16 hr16.z, hr45.y, hr41.x, (last)hr16.z
mad.f16 hr12.z, hr45.y, hr41.y, (last)hr12.z
mad.f16 hr8.z, hr45.y, hr41.z, (last)hr8.z
mad.f16 hr32.w, hr45.z, hr5.w, (last)hr32.w
mad.f16 hr28.w, hr45.z, hr6.x, (last)hr28.w
mad.f16 hr24.w, hr45.z, hr6.y, (last)hr24.w
mad.f16 hr20.w, hr45.z, hr6.z, (last)hr20.w
mad.f16 hr16.w, hr45.z, hr41.x, (last)hr16.w
mad.f16 hr12.w, hr45.z, hr41.y, (last)hr12.w
mad.f16 hr8.w, hr45.z, hr41.z, (last)hr8.w
mad.f16 hr33.x, hr45.w, hr5.w, (last)hr33.x
mad.f16 hr29.x, hr45.w, hr6.x, (last)hr29.x
mad.f16 hr25.x, hr45.w, hr6.y, (last)hr25.x
mad.f16 hr21.x, hr45.w, hr6.z, (last)hr21.x
mad.f16 hr17.x, hr45.w, hr41.x, (last)hr17.x
mad.f16 hr13.x, hr45.w, hr41.y, (last)hr13.x
mad.f16 hr9.x, hr45.w, hr41.z, (last)hr9.x
mad.f16 hr33.y, hr46.x, hr5.w, (last)hr33.y
mad.f16 hr29.y, hr46.x, hr6.x, (last)hr29.y
mad.f16 hr25.y, hr46.x, hr6.y, (last)hr25.y
mad.f16 hr21.y, hr46.x, hr6.z, (last)hr21.y
mad.f16 hr17.y, hr46.x, hr41.x, (last)hr17.y
mad.f16 hr13.y, hr46.x, hr41.y, (last)hr13.y
mad.f16 hr9.y, hr46.x, hr41.z, (last)hr9.y
(ss)mad.f16 hr31.z, hr3.w, hr5.w, (last)hr31.z
mad.f16 hr27.z, hr3.w, hr6.x, (last)hr27.z
mad.f16 hr23.z, hr3.w, hr6.y, (last)hr23.z
mad.f16 hr19.z, hr3.w, hr6.z, (last)hr19.z
mad.f16 hr31.w, hr4.x, hr5.w, (last)hr31.w
mad.f16 hr27.w, hr4.x, hr6.x, (last)hr27.w
mad.f16 hr23.w, hr4.x, hr6.y, (last)hr23.w
mad.f16 hr19.w, hr4.x, hr6.z, (last)hr19.w
(rpt1)mad.f16 hr32.x, (r)hr4.y, hr5.w, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr4.y, hr6.x, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr4.y, hr6.y, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr4.y, hr6.z, (r)(last)hr20.x
ldl.u16 r5.w, l[r24.x], 4
(rpt1)mad.f16 hr45.y, (r)(last)hr45.y, hr41.w, (r)(last)hr36.w
(rpt1)mad.f16 hr45.w, (r)(last)hr45.w, hr41.w, (r)(last)hr37.y
ldl.u16 r36.w, l[r24.x+128], 4
mad.f16 hr15.z, hr3.w, hr41.x, (last)hr15.z
mad.f16 hr11.z, hr3.w, hr41.y, (last)hr11.z
mad.f16 hr7.z, hr3.w, hr41.z, (last)hr7.z
mad.f16 hr15.w, hr4.x, hr41.x, (last)hr15.w
mad.f16 hr11.w, hr4.x, hr41.y, (last)hr11.w
mad.f16 hr7.w, hr4.x, hr41.z, (last)hr7.w
(rpt1)mad.f16 hr16.x, (r)hr4.y, hr41.x, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr4.y, hr41.y, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr4.y, hr41.z, (r)(last)hr8.x
(sy)(ss)mad.f16 hr33.z, hr36.w, hr44.y, (last)hr33.z
mad.f16 hr29.z, hr36.w, hr44.z, (last)hr29.z
mad.f16 hr25.z, hr36.w, hr44.w, (last)hr25.z
mad.f16 hr21.z, hr36.w, hr45.x, (last)hr21.z
mad.f16 hr17.z, hr36.w, hr4.w, (last)hr17.z
mad.f16 hr13.z, hr36.w, hr5.x, (last)hr13.z
mad.f16 hr9.z, hr36.w, hr5.y, (last)hr9.z
mad.f16 hr33.w, hr37.x, hr44.y, (last)hr33.w
mad.f16 hr29.w, hr37.x, hr44.z, (last)hr29.w
mad.f16 hr25.w, hr37.x, hr44.w, (last)hr25.w
mad.f16 hr21.w, hr37.x, hr45.x, (last)hr21.w
mad.f16 hr17.w, hr37.x, hr4.w, (last)hr17.w
mad.f16 hr13.w, hr37.x, hr5.x, (last)hr13.w
mad.f16 hr9.w, hr37.x, hr5.y, (last)hr9.w
mad.f16 hr34.x, hr37.y, hr44.y, (last)hr34.x
mad.f16 hr30.x, hr37.y, hr44.z, (last)hr30.x
mad.f16 hr26.x, hr37.y, hr44.w, (last)hr26.x
mad.f16 hr22.x, hr37.y, hr45.x, (last)hr22.x
mad.f16 hr18.x, hr37.y, hr4.w, (last)hr18.x
mad.f16 hr14.x, hr37.y, hr5.x, (last)hr14.x
mad.f16 hr10.x, hr37.y, hr5.y, (last)hr10.x
mad.f16 hr34.y, hr37.z, hr44.y, (last)hr34.y
mad.f16 hr30.y, hr37.z, hr44.z, (last)hr30.y
mad.f16 hr26.y, hr37.z, hr44.w, (last)hr26.y
mad.f16 hr22.y, hr37.z, hr45.x, (last)hr22.y
mad.f16 hr18.y, hr37.z, hr4.w, (last)hr18.y
mad.f16 hr14.y, hr37.z, hr5.x, (last)hr14.y
mad.f16 hr10.y, hr37.z, hr5.y, (last)hr10.y
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr41.w, (r)(last)hr37.w
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr41.w, (r)(last)hr38.y
isam.v.base0 (u16)(xyzw)hr37.w, r19.z, s#0, t#0
ldl.u16 r41.y, l[r24.x+256], 4
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr5.z, (r)(last)hr43.y
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr5.z, (r)(last)hr43.w
isam.v.base0 (u16)(xyzw)hr43.y, r19.w, s#0, t#0
isam.v.base0 (u16)(xyzw)hr47.x, r20.x, s#0, t#0
mad.f16 hr34.z, hr5.w, hr44.y, (last)hr34.z
mad.f16 hr30.z, hr5.w, hr44.z, (last)hr30.z
mad.f16 hr26.z, hr5.w, hr44.w, (last)hr26.z
mad.f16 hr22.z, hr5.w, hr45.x, (last)hr22.z
mad.f16 hr18.z, hr5.w, hr4.w, (last)hr18.z
mad.f16 hr14.z, hr5.w, hr5.x, (last)hr14.z
mad.f16 hr10.z, hr5.w, hr5.y, (last)hr10.z
mad.f16 hr34.w, hr6.x, hr44.y, (last)hr34.w
mad.f16 hr30.w, hr6.x, hr44.z, (last)hr30.w
mad.f16 hr26.w, hr6.x, hr44.w, (last)hr26.w
mad.f16 hr22.w, hr6.x, hr45.x, (last)hr22.w
mad.f16 hr18.w, hr6.x, hr4.w, (last)hr18.w
mad.f16 hr14.w, hr6.x, hr5.x, (last)hr14.w
mad.f16 hr10.w, hr6.x, hr5.y, (last)hr10.w
mad.f16 hr35.x, hr6.y, hr44.y, (last)hr35.x
mad.f16 hr31.x, hr6.y, hr44.z, (last)hr31.x
mad.f16 hr27.x, hr6.y, hr44.w, (last)hr27.x
mad.f16 hr23.x, hr6.y, hr45.x, (last)hr23.x
mad.f16 hr19.x, hr6.y, hr4.w, (last)hr19.x
mad.f16 hr15.x, hr6.y, hr5.x, (last)hr15.x
mad.f16 hr11.x, hr6.y, hr5.y, (last)hr11.x
mad.f16 hr35.y, hr6.z, hr44.y, (last)hr35.y
mad.f16 hr31.y, hr6.z, hr44.z, (last)hr31.y
mad.f16 hr27.y, hr6.z, hr44.w, (last)hr27.y
mad.f16 hr23.y, hr6.z, hr45.x, (last)hr23.y
mad.f16 hr19.y, hr6.z, hr4.w, (last)hr19.y
mad.f16 hr15.y, hr6.z, hr5.x, (last)hr15.y
mad.f16 hr11.y, hr6.z, hr5.y, (last)hr11.y
(rpt1)mad.f16 hr5.w, (r)(last)hr5.w, hr5.z, (r)(last)hr42.y
(rpt1)mad.f16 hr6.y, (r)(last)hr6.y, hr5.z, (r)(last)hr42.w
ldl.u16 r42.y, l[r24.x+384], 4
(ss)mad.f16 hr32.z, hr41.y, hr44.y, (last)hr32.z
mad.f16 hr28.z, hr41.y, hr44.z, (last)hr28.z
mad.f16 hr24.z, hr41.y, hr44.w, (last)hr24.z
mad.f16 hr20.z, hr41.y, hr45.x, (last)hr20.z
mad.f16 hr32.w, hr41.z, hr44.y, (last)hr32.w
mad.f16 hr28.w, hr41.z, hr44.z, (last)hr28.w
mad.f16 hr24.w, hr41.z, hr44.w, (last)hr24.w
mad.f16 hr20.w, hr41.z, hr45.x, (last)hr20.w
mad.f16 hr33.x, hr41.w, hr44.y, (last)hr33.x
mad.f16 hr29.x, hr41.w, hr44.z, (last)hr29.x
mad.f16 hr25.x, hr41.w, hr44.w, (last)hr25.x
mad.f16 hr21.x, hr41.w, hr45.x, (last)hr21.x
mad.f16 hr33.y, hr42.x, hr44.y, (last)hr33.y
mad.f16 hr29.y, hr42.x, hr44.z, (last)hr29.y
mad.f16 hr25.y, hr42.x, hr44.w, (last)hr25.y
mad.f16 hr21.y, hr42.x, hr45.x, (last)hr21.y
mad.f16 hr31.z, hr42.y, hr44.y, (last)hr31.z
mad.f16 hr27.z, hr42.y, hr44.z, (last)hr27.z
mad.f16 hr23.z, hr42.y, hr44.w, (last)hr23.z
mad.f16 hr19.z, hr42.y, hr45.x, (last)hr19.z
mad.f16 hr31.w, hr42.z, hr44.y, (last)hr31.w
mad.f16 hr27.w, hr42.z, hr44.z, (last)hr27.w
mad.f16 hr23.w, hr42.z, hr44.w, (last)hr23.w
mad.f16 hr19.w, hr42.z, hr45.x, (last)hr19.w
(rpt1)mad.f16 hr32.x, (r)hr42.w, hr44.y, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr42.w, hr44.z, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr42.w, hr44.w, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr42.w, hr45.x, (r)(last)hr20.x
ldl.u16 r44.y, l[r24.y], 4
mad.f16 hr16.z, hr41.y, hr4.w, (last)hr16.z
mad.f16 hr12.z, hr41.y, hr5.x, (last)hr12.z
mad.f16 hr8.z, hr41.y, hr5.y, (last)hr8.z
mad.f16 hr16.w, hr41.z, hr4.w, (last)hr16.w
mad.f16 hr12.w, hr41.z, hr5.x, (last)hr12.w
mad.f16 hr8.w, hr41.z, hr5.y, (last)hr8.w
mad.f16 hr17.x, hr41.w, hr4.w, (last)hr17.x
mad.f16 hr13.x, hr41.w, hr5.x, (last)hr13.x
mad.f16 hr9.x, hr41.w, hr5.y, (last)hr9.x
mad.f16 hr17.y, hr42.x, hr4.w, (last)hr17.y
mad.f16 hr13.y, hr42.x, hr5.x, (last)hr13.y
mad.f16 hr9.y, hr42.x, hr5.y, (last)hr9.y
mad.f16 hr15.z, hr42.y, hr4.w, (last)hr15.z
mad.f16 hr11.z, hr42.y, hr5.x, (last)hr11.z
mad.f16 hr7.z, hr42.y, hr5.y, (last)hr7.z
mad.f16 hr15.w, hr42.z, hr4.w, (last)hr15.w
mad.f16 hr11.w, hr42.z, hr5.x, (last)hr11.w
mad.f16 hr7.w, hr42.z, hr5.y, (last)hr7.w
(rpt1)mad.f16 hr16.x, (r)hr42.w, hr4.w, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr42.w, hr5.x, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr42.w, hr5.y, (r)(last)hr8.x
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr5.z, (r)(last)hr45.y
(rpt1)mad.f16 hr41.w, (r)(last)hr41.w, hr5.z, (r)(last)hr45.w
ldl.u16 r45.y, l[r24.y+128], 4
(rpt1)mad.f16 hr42.y, (r)(last)hr42.y, hr5.z, (r)(last)hr3.w
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr5.z, (r)(last)hr4.y
ldl.u16 r3.w, l[r24.y+256], 4
ldl.u16 r4.w, l[r24.y+384], 4
(sy)(ss)mad.f16 hr34.z, hr44.y, hr37.w, (last)hr34.z
mad.f16 hr30.z, hr44.y, hr38.x, (last)hr30.z
mad.f16 hr26.z, hr44.y, hr38.y, (last)hr26.z
mad.f16 hr22.z, hr44.y, hr38.z, (last)hr22.z
mad.f16 hr18.z, hr44.y, hr43.y, (last)hr18.z
mad.f16 hr14.z, hr44.y, hr43.z, (last)hr14.z
mad.f16 hr10.z, hr44.y, hr43.w, (last)hr10.z
mad.f16 hr34.w, hr44.z, hr37.w, (last)hr34.w
mad.f16 hr30.w, hr44.z, hr38.x, (last)hr30.w
mad.f16 hr26.w, hr44.z, hr38.y, (last)hr26.w
mad.f16 hr22.w, hr44.z, hr38.z, (last)hr22.w
mad.f16 hr18.w, hr44.z, hr43.y, (last)hr18.w
mad.f16 hr14.w, hr44.z, hr43.z, (last)hr14.w
mad.f16 hr10.w, hr44.z, hr43.w, (last)hr10.w
mad.f16 hr35.x, hr44.w, hr37.w, (last)hr35.x
mad.f16 hr31.x, hr44.w, hr38.x, (last)hr31.x
mad.f16 hr27.x, hr44.w, hr38.y, (last)hr27.x
mad.f16 hr23.x, hr44.w, hr38.z, (last)hr23.x
mad.f16 hr19.x, hr44.w, hr43.y, (last)hr19.x
mad.f16 hr15.x, hr44.w, hr43.z, (last)hr15.x
mad.f16 hr11.x, hr44.w, hr43.w, (last)hr11.x
mad.f16 hr35.y, hr45.x, hr37.w, (last)hr35.y
mad.f16 hr31.y, hr45.x, hr38.x, (last)hr31.y
mad.f16 hr27.y, hr45.x, hr38.y, (last)hr27.y
mad.f16 hr23.y, hr45.x, hr38.z, (last)hr23.y
mad.f16 hr19.y, hr45.x, hr43.y, (last)hr19.y
mad.f16 hr15.y, hr45.x, hr43.z, (last)hr15.y
mad.f16 hr11.y, hr45.x, hr43.w, (last)hr11.y
(rpt1)mad.f16 hr44.y, (r)(last)hr44.y, hr44.x, (r)(last)hr5.w
(rpt1)mad.f16 hr44.w, (r)(last)hr44.w, hr44.x, (r)(last)hr6.y
isam.v.base0 (u16)(xyzw)hr5.w, r20.y, s#0, t#0
isam.v.base0 (u16)(xyzw)hr38.w, r30.w, s#0, t#0
mad.f16 hr33.z, hr45.y, hr37.w, (last)hr33.z
mad.f16 hr29.z, hr45.y, hr38.x, (last)hr29.z
mad.f16 hr25.z, hr45.y, hr38.y, (last)hr25.z
mad.f16 hr21.z, hr45.y, hr38.z, (last)hr21.z
mad.f16 hr17.z, hr45.y, hr43.y, (last)hr17.z
mad.f16 hr13.z, hr45.y, hr43.z, (last)hr13.z
mad.f16 hr9.z, hr45.y, hr43.w, (last)hr9.z
mad.f16 hr33.w, hr45.z, hr37.w, (last)hr33.w
mad.f16 hr29.w, hr45.z, hr38.x, (last)hr29.w
mad.f16 hr25.w, hr45.z, hr38.y, (last)hr25.w
mad.f16 hr21.w, hr45.z, hr38.z, (last)hr21.w
mad.f16 hr17.w, hr45.z, hr43.y, (last)hr17.w
mad.f16 hr13.w, hr45.z, hr43.z, (last)hr13.w
mad.f16 hr9.w, hr45.z, hr43.w, (last)hr9.w
mad.f16 hr34.x, hr45.w, hr37.w, (last)hr34.x
mad.f16 hr30.x, hr45.w, hr38.x, (last)hr30.x
mad.f16 hr26.x, hr45.w, hr38.y, (last)hr26.x
mad.f16 hr22.x, hr45.w, hr38.z, (last)hr22.x
mad.f16 hr18.x, hr45.w, hr43.y, (last)hr18.x
mad.f16 hr14.x, hr45.w, hr43.z, (last)hr14.x
mad.f16 hr10.x, hr45.w, hr43.w, (last)hr10.x
mad.f16 hr34.y, hr46.x, hr37.w, (last)hr34.y
mad.f16 hr30.y, hr46.x, hr38.x, (last)hr30.y
mad.f16 hr26.y, hr46.x, hr38.y, (last)hr26.y
mad.f16 hr22.y, hr46.x, hr38.z, (last)hr22.y
mad.f16 hr18.y, hr46.x, hr43.y, (last)hr18.y
mad.f16 hr14.y, hr46.x, hr43.z, (last)hr14.y
mad.f16 hr10.y, hr46.x, hr43.w, (last)hr10.y
mad.f16 hr32.z, hr3.w, hr37.w, (last)hr32.z
mad.f16 hr28.z, hr3.w, hr38.x, (last)hr28.z
mad.f16 hr24.z, hr3.w, hr38.y, (last)hr24.z
mad.f16 hr20.z, hr3.w, hr38.z, (last)hr20.z
mad.f16 hr32.w, hr4.x, hr37.w, (last)hr32.w
mad.f16 hr28.w, hr4.x, hr38.x, (last)hr28.w
mad.f16 hr24.w, hr4.x, hr38.y, (last)hr24.w
mad.f16 hr20.w, hr4.x, hr38.z, (last)hr20.w
mad.f16 hr33.x, hr4.y, hr37.w, (last)hr33.x
mad.f16 hr29.x, hr4.y, hr38.x, (last)hr29.x
mad.f16 hr25.x, hr4.y, hr38.y, (last)hr25.x
mad.f16 hr21.x, hr4.y, hr38.z, (last)hr21.x
mad.f16 hr33.y, hr4.z, hr37.w, (last)hr33.y
mad.f16 hr29.y, hr4.z, hr38.x, (last)hr29.y
mad.f16 hr25.y, hr4.z, hr38.y, (last)hr25.y
mad.f16 hr21.y, hr4.z, hr38.z, (last)hr21.y
mad.f16 hr31.z, hr4.w, hr37.w, (last)hr31.z
mad.f16 hr27.z, hr4.w, hr38.x, (last)hr27.z
mad.f16 hr23.z, hr4.w, hr38.y, (last)hr23.z
mad.f16 hr19.z, hr4.w, hr38.z, (last)hr19.z
mad.f16 hr31.w, hr5.x, hr37.w, (last)hr31.w
mad.f16 hr27.w, hr5.x, hr38.x, (last)hr27.w
mad.f16 hr23.w, hr5.x, hr38.y, (last)hr23.w
mad.f16 hr19.w, hr5.x, hr38.z, (last)hr19.w
(rpt1)mad.f16 hr32.x, (r)hr5.y, hr37.w, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr5.y, hr38.x, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr5.y, hr38.y, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr5.y, hr38.z, (r)(last)hr20.x
(rpt1)mad.f16 hr45.y, (r)(last)hr45.y, hr44.x, (r)(last)hr36.w
(rpt1)mad.f16 hr45.w, (r)(last)hr45.w, hr44.x, (r)(last)hr37.y
ldl.u16 r36.w, l[r24.w], 4
ldl.u16 r37.w, l[r24.w+128], 4
mad.f16 hr17.x, hr4.y, hr43.y, (last)hr17.x
mad.f16 hr13.x, hr4.y, hr43.z, (last)hr13.x
mad.f16 hr9.x, hr4.y, hr43.w, (last)hr9.x
mad.f16 hr17.y, hr4.z, hr43.y, (last)hr17.y
mad.f16 hr13.y, hr4.z, hr43.z, (last)hr13.y
mad.f16 hr9.y, hr4.z, hr43.w, (last)hr9.y
mad.f16 hr15.z, hr4.w, hr43.y, (last)hr15.z
mad.f16 hr11.z, hr4.w, hr43.z, (last)hr11.z
mad.f16 hr7.z, hr4.w, hr43.w, (last)hr7.z
mad.f16 hr15.w, hr5.x, hr43.y, (last)hr15.w
(ss)nop
ldl.u16 r39.w, l[r24.w+256], 4
mad.f16 hr11.w, hr5.x, hr43.z, (last)hr11.w
mad.f16 hr7.w, hr5.x, hr43.w, (last)hr7.w
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr44.x, (r)(last)hr41.w
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr44.x, (r)(last)hr42.y
isam.v.base0 (u16)(xyzw)hr41.w, r31.x, s#0, t#0
mad.f16 hr16.z, hr3.w, hr43.y, (last)hr16.z
mad.f16 hr12.z, hr3.w, hr43.z, (last)hr12.z
mad.f16 hr8.z, hr3.w, hr43.w, (last)hr8.z
mad.f16 hr16.w, hr4.x, hr43.y, (last)hr16.w
mad.f16 hr12.w, hr4.x, hr43.z, (last)hr12.w
mad.f16 hr8.w, hr4.x, hr43.w, (last)hr8.w
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr44.x, (r)(last)hr41.y
ldl.u16 r40.w, l[r24.w+384], 4
(rpt1)mad.f16 hr16.x, (r)hr5.y, hr43.y, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr5.y, hr43.z, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr5.y, hr43.w, (r)(last)hr8.x
(rpt1)mad.f16 hr5.y, (r)(last)hr5.y, hr44.x, (r)(last)hr42.w
ldl.u16 r42.w, l[r25.x], 4
mad.f16 hr34.z, hr36.w, hr47.x, (last)hr34.z
mad.f16 hr30.z, hr36.w, hr47.y, (last)hr30.z
mad.f16 hr26.z, hr36.w, hr47.z, (last)hr26.z
mad.f16 hr22.z, hr36.w, hr47.w, (last)hr22.z
mad.f16 hr34.w, hr37.x, hr47.x, (last)hr34.w
mad.f16 hr30.w, hr37.x, hr47.y, (last)hr30.w
mad.f16 hr26.w, hr37.x, hr47.z, (last)hr26.w
mad.f16 hr22.w, hr37.x, hr47.w, (last)hr22.w
mad.f16 hr35.x, hr37.y, hr47.x, (last)hr35.x
mad.f16 hr31.x, hr37.y, hr47.y, (last)hr31.x
mad.f16 hr27.x, hr37.y, hr47.z, (last)hr27.x
mad.f16 hr23.x, hr37.y, hr47.w, (last)hr23.x
mad.f16 hr35.y, hr37.z, hr47.x, (last)hr35.y
mad.f16 hr31.y, hr37.z, hr47.y, (last)hr31.y
mad.f16 hr27.y, hr37.z, hr47.z, (last)hr27.y
mad.f16 hr23.y, hr37.z, hr47.w, (last)hr23.y
mad.f16 hr33.z, hr37.w, hr47.x, (last)hr33.z
mad.f16 hr29.z, hr37.w, hr47.y, (last)hr29.z
mad.f16 hr25.z, hr37.w, hr47.z, (last)hr25.z
mad.f16 hr21.z, hr37.w, hr47.w, (last)hr21.z
mad.f16 hr33.w, hr38.x, hr47.x, (last)hr33.w
(sy)mad.f16 hr18.z, hr36.w, hr5.w, (last)hr18.z
mad.f16 hr14.z, hr36.w, hr6.x, (last)hr14.z
mad.f16 hr10.z, hr36.w, hr6.y, (last)hr10.z
mad.f16 hr18.w, hr37.x, hr5.w, (last)hr18.w
mad.f16 hr14.w, hr37.x, hr6.x, (last)hr14.w
mad.f16 hr10.w, hr37.x, hr6.y, (last)hr10.w
mad.f16 hr19.x, hr37.y, hr5.w, (last)hr19.x
mad.f16 hr15.x, hr37.y, hr6.x, (last)hr15.x
mad.f16 hr11.x, hr37.y, hr6.y, (last)hr11.x
mad.f16 hr19.y, hr37.z, hr5.w, (last)hr19.y
mad.f16 hr15.y, hr37.z, hr6.x, (last)hr15.y
mad.f16 hr11.y, hr37.z, hr6.y, (last)hr11.y
mad.f16 hr17.z, hr37.w, hr5.w, (last)hr17.z
mad.f16 hr13.z, hr37.w, hr6.x, (last)hr13.z
mad.f16 hr9.z, hr37.w, hr6.y, (last)hr9.z
mad.f16 hr29.w, hr38.x, hr47.y, (last)hr29.w
mad.f16 hr25.w, hr38.x, hr47.z, (last)hr25.w
mad.f16 hr21.w, hr38.x, hr47.w, (last)hr21.w
mad.f16 hr17.w, hr38.x, hr5.w, (last)hr17.w
mad.f16 hr13.w, hr38.x, hr6.x, (last)hr13.w
mad.f16 hr9.w, hr38.x, hr6.y, (last)hr9.w
mad.f16 hr34.x, hr38.y, hr47.x, (last)hr34.x
mad.f16 hr30.x, hr38.y, hr47.y, (last)hr30.x
mad.f16 hr26.x, hr38.y, hr47.z, (last)hr26.x
mad.f16 hr22.x, hr38.y, hr47.w, (last)hr22.x
mad.f16 hr18.x, hr38.y, hr5.w, (last)hr18.x
mad.f16 hr14.x, hr38.y, hr6.x, (last)hr14.x
mad.f16 hr10.x, hr38.y, hr6.y, (last)hr10.x
mad.f16 hr34.y, hr38.z, hr47.x, (last)hr34.y
mad.f16 hr30.y, hr38.z, hr47.y, (last)hr30.y
mad.f16 hr26.y, hr38.z, hr47.z, (last)hr26.y
mad.f16 hr22.y, hr38.z, hr47.w, (last)hr22.y
mad.f16 hr18.y, hr38.z, hr5.w, (last)hr18.y
mad.f16 hr14.y, hr38.z, hr6.x, (last)hr14.y
mad.f16 hr10.y, hr38.z, hr6.y, (last)hr10.y
(ss)mad.f16 hr32.z, hr39.w, hr47.x, (last)hr32.z
mad.f16 hr28.z, hr39.w, hr47.y, (last)hr28.z
mad.f16 hr24.z, hr39.w, hr47.z, (last)hr24.z
mad.f16 hr20.z, hr39.w, hr47.w, (last)hr20.z
mad.f16 hr32.w, hr40.x, hr47.x, (last)hr32.w
mad.f16 hr28.w, hr40.x, hr47.y, (last)hr28.w
mad.f16 hr24.w, hr40.x, hr47.z, (last)hr24.w
mad.f16 hr20.w, hr40.x, hr47.w, (last)hr20.w
mad.f16 hr33.x, hr40.y, hr47.x, (last)hr33.x
mad.f16 hr29.x, hr40.y, hr47.y, (last)hr29.x
mad.f16 hr25.x, hr40.y, hr47.z, (last)hr25.x
mad.f16 hr21.x, hr40.y, hr47.w, (last)hr21.x
mad.f16 hr17.x, hr40.y, hr5.w, (last)hr17.x
mad.f16 hr13.x, hr40.y, hr6.x, (last)hr13.x
mad.f16 hr9.x, hr40.y, hr6.y, (last)hr9.x
mad.f16 hr33.y, hr40.z, hr47.x, (last)hr33.y
mad.f16 hr29.y, hr40.z, hr47.y, (last)hr29.y
mad.f16 hr25.y, hr40.z, hr47.z, (last)hr25.y
mad.f16 hr21.y, hr40.z, hr47.w, (last)hr21.y
mad.f16 hr17.y, hr40.z, hr5.w, (last)hr17.y
mad.f16 hr13.y, hr40.z, hr6.x, (last)hr13.y
mad.f16 hr9.y, hr40.z, hr6.y, (last)hr9.y
mad.f16 hr16.z, hr39.w, hr5.w, (last)hr16.z
mad.f16 hr12.z, hr39.w, hr6.x, (last)hr12.z
mad.f16 hr8.z, hr39.w, hr6.y, (last)hr8.z
mad.f16 hr16.w, hr40.x, hr5.w, (last)hr16.w
mad.f16 hr12.w, hr40.x, hr6.x, (last)hr12.w
mad.f16 hr8.w, hr40.x, hr6.y, (last)hr8.w
mad.f16 hr31.z, hr40.w, hr47.x, (last)hr31.z
mad.f16 hr27.z, hr40.w, hr47.y, (last)hr27.z
mad.f16 hr23.z, hr40.w, hr47.z, (last)hr23.z
mad.f16 hr19.z, hr40.w, hr47.w, (last)hr19.z
mad.f16 hr15.z, hr40.w, hr5.w, (last)hr15.z
mad.f16 hr11.z, hr40.w, hr6.x, (last)hr11.z
mad.f16 hr7.z, hr40.w, hr6.y, (last)hr7.z
mad.f16 hr31.w, hr41.x, hr47.x, (last)hr31.w
mad.f16 hr27.w, hr41.x, hr47.y, (last)hr27.w
mad.f16 hr23.w, hr41.x, hr47.z, (last)hr23.w
mad.f16 hr19.w, hr41.x, hr47.w, (last)hr19.w
mad.f16 hr15.w, hr41.x, hr5.w, (last)hr15.w
mad.f16 hr11.w, hr41.x, hr6.x, (last)hr11.w
mad.f16 hr7.w, hr41.x, hr6.y, (last)hr7.w
(rpt1)mad.f16 hr32.x, (r)hr41.y, hr47.x, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr41.y, hr47.y, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr41.y, hr47.z, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr41.y, hr47.w, (r)(last)hr20.x
(rpt1)mad.f16 hr16.x, (r)hr41.y, hr5.w, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr41.y, hr6.x, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr41.y, hr6.y, (r)(last)hr8.x
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr6.z, (r)(last)hr44.y
ldl.u16 r43.w, l[r25.x+128], 4
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr6.z, (r)(last)hr44.w
(rpt1)mad.f16 hr37.w, (r)(last)hr37.w, hr6.z, (r)(last)hr45.y
isam.v.base0 (u16)(xyzw)hr44.w, r31.y, s#0, t#0
(rpt1)mad.f16 hr38.y, (r)(last)hr38.y, hr6.z, (r)(last)hr45.w
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr6.z, (r)(last)hr4.y
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr6.z, (r)(last)hr3.w
ldl.u16 r3.w, l[r25.x+256], 4
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr6.z, (r)(last)hr4.w
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr6.z, (r)(last)hr5.y
isam.v.base0 (u16)(xyzw)hr5.w, r31.z, s#0, t#0
ldl.u16 r4.w, l[r25.x+384], 4
mad.f16 hr34.z, hr42.w, hr38.w, (last)hr34.z
mad.f16 hr30.z, hr42.w, hr39.x, (last)hr30.z
mad.f16 hr26.z, hr42.w, hr39.y, (last)hr26.z
mad.f16 hr22.z, hr42.w, hr39.z, (last)hr22.z
mad.f16 hr34.w, hr43.x, hr38.w, (last)hr34.w
mad.f16 hr30.w, hr43.x, hr39.x, (last)hr30.w
mad.f16 hr26.w, hr43.x, hr39.y, (last)hr26.w
mad.f16 hr22.w, hr43.x, hr39.z, (last)hr22.w
mad.f16 hr35.x, hr43.y, hr38.w, (last)hr35.x
mad.f16 hr31.x, hr43.y, hr39.x, (last)hr31.x
mad.f16 hr27.x, hr43.y, hr39.y, (last)hr27.x
mad.f16 hr23.x, hr43.y, hr39.z, (last)hr23.x
mad.f16 hr35.y, hr43.z, hr38.w, (last)hr35.y
mad.f16 hr31.y, hr43.z, hr39.x, (last)hr31.y
mad.f16 hr27.y, hr43.z, hr39.y, (last)hr27.y
mad.f16 hr23.y, hr43.z, hr39.z, (last)hr23.y
mad.f16 hr18.z, hr42.w, hr41.w, (last)hr18.z
mad.f16 hr14.z, hr42.w, hr42.x, (last)hr14.z
mad.f16 hr10.z, hr42.w, hr42.y, (last)hr10.z
mad.f16 hr18.w, hr43.x, hr41.w, (last)hr18.w
mad.f16 hr14.w, hr43.x, hr42.x, (last)hr14.w
mad.f16 hr10.w, hr43.x, hr42.y, (last)hr10.w
mad.f16 hr19.x, hr43.y, hr41.w, (last)hr19.x
mad.f16 hr15.x, hr43.y, hr42.x, (last)hr15.x
mad.f16 hr11.x, hr43.y, hr42.y, (last)hr11.x
mad.f16 hr19.y, hr43.z, hr41.w, (last)hr19.y
mad.f16 hr15.y, hr43.z, hr42.x, (last)hr15.y
mad.f16 hr11.y, hr43.z, hr42.y, (last)hr11.y
(ss)mad.f16 hr33.z, hr43.w, hr38.w, (last)hr33.z
mad.f16 hr29.z, hr43.w, hr39.x, (last)hr29.z
mad.f16 hr25.z, hr43.w, hr39.y, (last)hr25.z
mad.f16 hr21.z, hr43.w, hr39.z, (last)hr21.z
mad.f16 hr17.z, hr43.w, hr41.w, (last)hr17.z
mad.f16 hr13.z, hr43.w, hr42.x, (last)hr13.z
mad.f16 hr9.z, hr43.w, hr42.y, (last)hr9.z
mad.f16 hr33.w, hr44.x, hr38.w, (last)hr33.w
mad.f16 hr29.w, hr44.x, hr39.x, (last)hr29.w
mad.f16 hr25.w, hr44.x, hr39.y, (last)hr25.w
mad.f16 hr21.w, hr44.x, hr39.z, (last)hr21.w
mad.f16 hr17.w, hr44.x, hr41.w, (last)hr17.w
mad.f16 hr13.w, hr44.x, hr42.x, (last)hr13.w
mad.f16 hr9.w, hr44.x, hr42.y, (last)hr9.w
mad.f16 hr34.x, hr44.y, hr38.w, (last)hr34.x
mad.f16 hr30.x, hr44.y, hr39.x, (last)hr30.x
mad.f16 hr26.x, hr44.y, hr39.y, (last)hr26.x
mad.f16 hr22.x, hr44.y, hr39.z, (last)hr22.x
mad.f16 hr18.x, hr44.y, hr41.w, (last)hr18.x
mad.f16 hr14.x, hr44.y, hr42.x, (last)hr14.x
mad.f16 hr10.x, hr44.y, hr42.y, (last)hr10.x
mad.f16 hr34.y, hr44.z, hr38.w, (last)hr34.y
mad.f16 hr30.y, hr44.z, hr39.x, (last)hr30.y
mad.f16 hr26.y, hr44.z, hr39.y, (last)hr26.y
mad.f16 hr22.y, hr44.z, hr39.z, (last)hr22.y
mad.f16 hr18.y, hr44.z, hr41.w, (last)hr18.y
mad.f16 hr14.y, hr44.z, hr42.x, (last)hr14.y
mad.f16 hr10.y, hr44.z, hr42.y, (last)hr10.y
mad.f16 hr32.z, hr3.w, hr38.w, (last)hr32.z
mad.f16 hr28.z, hr3.w, hr39.x, (last)hr28.z
mad.f16 hr24.z, hr3.w, hr39.y, (last)hr24.z
mad.f16 hr20.z, hr3.w, hr39.z, (last)hr20.z
mad.f16 hr16.z, hr3.w, hr41.w, (last)hr16.z
mad.f16 hr12.z, hr3.w, hr42.x, (last)hr12.z
mad.f16 hr8.z, hr3.w, hr42.y, (last)hr8.z
mad.f16 hr32.w, hr4.x, hr38.w, (last)hr32.w
mad.f16 hr28.w, hr4.x, hr39.x, (last)hr28.w
mad.f16 hr24.w, hr4.x, hr39.y, (last)hr24.w
mad.f16 hr20.w, hr4.x, hr39.z, (last)hr20.w
mad.f16 hr16.w, hr4.x, hr41.w, (last)hr16.w
mad.f16 hr12.w, hr4.x, hr42.x, (last)hr12.w
mad.f16 hr8.w, hr4.x, hr42.y, (last)hr8.w
mad.f16 hr33.x, hr4.y, hr38.w, (last)hr33.x
mad.f16 hr29.x, hr4.y, hr39.x, (last)hr29.x
mad.f16 hr25.x, hr4.y, hr39.y, (last)hr25.x
mad.f16 hr21.x, hr4.y, hr39.z, (last)hr21.x
mad.f16 hr17.x, hr4.y, hr41.w, (last)hr17.x
mad.f16 hr13.x, hr4.y, hr42.x, (last)hr13.x
mad.f16 hr9.x, hr4.y, hr42.y, (last)hr9.x
mad.f16 hr33.y, hr4.z, hr38.w, (last)hr33.y
mad.f16 hr29.y, hr4.z, hr39.x, (last)hr29.y
mad.f16 hr25.y, hr4.z, hr39.y, (last)hr25.y
mad.f16 hr21.y, hr4.z, hr39.z, (last)hr21.y
mad.f16 hr17.y, hr4.z, hr41.w, (last)hr17.y
mad.f16 hr13.y, hr4.z, hr42.x, (last)hr13.y
mad.f16 hr9.y, hr4.z, hr42.y, (last)hr9.y
mad.f16 hr31.z, hr4.w, hr38.w, (last)hr31.z
mad.f16 hr27.z, hr4.w, hr39.x, (last)hr27.z
mad.f16 hr23.z, hr4.w, hr39.y, (last)hr23.z
mad.f16 hr19.z, hr4.w, hr39.z, (last)hr19.z
mad.f16 hr15.z, hr4.w, hr41.w, (last)hr15.z
mad.f16 hr11.z, hr4.w, hr42.x, (last)hr11.z
mad.f16 hr7.z, hr4.w, hr42.y, (last)hr7.z
mad.f16 hr31.w, hr5.x, hr38.w, (last)hr31.w
mad.f16 hr27.w, hr5.x, hr39.x, (last)hr27.w
mad.f16 hr23.w, hr5.x, hr39.y, (last)hr23.w
mad.f16 hr19.w, hr5.x, hr39.z, (last)hr19.w
mad.f16 hr15.w, hr5.x, hr41.w, (last)hr15.w
mad.f16 hr11.w, hr5.x, hr42.x, (last)hr11.w
mad.f16 hr7.w, hr5.x, hr42.y, (last)hr7.w
(rpt1)mad.f16 hr32.x, (r)hr5.y, hr38.w, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr5.y, hr39.x, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr5.y, hr39.y, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr5.y, hr39.z, (r)(last)hr20.x
isam.v.base0 (u16)(xyzw)hr38.w, r17.w, s#0, t#0
(rpt1)mad.f16 hr16.x, (r)hr5.y, hr41.w, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr5.y, hr42.x, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr5.y, hr42.y, (r)(last)hr8.x
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr42.z, (r)(last)hr36.w
(rpt1)mad.f16 hr43.y, (r)(last)hr43.y, hr42.z, (r)(last)hr37.y
ldl.u16 r36.w, l[r25.y], 4
(rpt1)mad.f16 hr43.w, (r)(last)hr43.w, hr42.z, (r)(last)hr37.w
(rpt1)mad.f16 hr44.y, (r)(last)hr44.y, hr42.z, (r)(last)hr38.y
ldl.u16 r37.w, l[r25.y+128], 4
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr42.z, (r)(last)hr39.w
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr42.z, (r)(last)hr40.y
ldl.u16 r39.w, l[r25.y+256], 4
(rpt1)mad.f16 hr4.w, (r)(last)hr4.w, hr42.z, (r)(last)hr40.w
(rpt1)mad.f16 hr5.y, (r)(last)hr5.y, hr42.z, (r)(last)hr41.y
isam.v.base0 (u16)(xyzw)hr41.w, r18.x, s#0, t#0
ldl.u16 r40.w, l[r25.y+384], 4
(sy)(ss)mad.f16 hr34.z, hr36.w, hr44.w, (last)hr34.z
mad.f16 hr30.z, hr36.w, hr45.x, (last)hr30.z
mad.f16 hr26.z, hr36.w, hr45.y, (last)hr26.z
mad.f16 hr22.z, hr36.w, hr45.z, (last)hr22.z
mad.f16 hr18.z, hr36.w, hr5.w, (last)hr18.z
mad.f16 hr14.z, hr36.w, hr6.x, (last)hr14.z
mad.f16 hr10.z, hr36.w, hr6.y, (last)hr10.z
mad.f16 hr34.w, hr37.x, hr44.w, (last)hr34.w
mad.f16 hr30.w, hr37.x, hr45.x, (last)hr30.w
mad.f16 hr26.w, hr37.x, hr45.y, (last)hr26.w
mad.f16 hr22.w, hr37.x, hr45.z, (last)hr22.w
mad.f16 hr18.w, hr37.x, hr5.w, (last)hr18.w
mad.f16 hr14.w, hr37.x, hr6.x, (last)hr14.w
mad.f16 hr10.w, hr37.x, hr6.y, (last)hr10.w
mad.f16 hr35.x, hr37.y, hr44.w, (last)hr35.x
mad.f16 hr31.x, hr37.y, hr45.x, (last)hr31.x
mad.f16 hr27.x, hr37.y, hr45.y, (last)hr27.x
mad.f16 hr23.x, hr37.y, hr45.z, (last)hr23.x
mad.f16 hr19.x, hr37.y, hr5.w, (last)hr19.x
mad.f16 hr15.x, hr37.y, hr6.x, (last)hr15.x
mad.f16 hr11.x, hr37.y, hr6.y, (last)hr11.x
mad.f16 hr35.y, hr37.z, hr44.w, (last)hr35.y
mad.f16 hr31.y, hr37.z, hr45.x, (last)hr31.y
mad.f16 hr27.y, hr37.z, hr45.y, (last)hr27.y
mad.f16 hr23.y, hr37.z, hr45.z, (last)hr23.y
mad.f16 hr19.y, hr37.z, hr5.w, (last)hr19.y
mad.f16 hr15.y, hr37.z, hr6.x, (last)hr15.y
mad.f16 hr11.y, hr37.z, hr6.y, (last)hr11.y
mad.f16 hr33.z, hr37.w, hr44.w, (last)hr33.z
mad.f16 hr29.z, hr37.w, hr45.x, (last)hr29.z
mad.f16 hr25.z, hr37.w, hr45.y, (last)hr25.z
mad.f16 hr21.z, hr37.w, hr45.z, (last)hr21.z
mad.f16 hr17.z, hr37.w, hr5.w, (last)hr17.z
mad.f16 hr13.z, hr37.w, hr6.x, (last)hr13.z
mad.f16 hr9.z, hr37.w, hr6.y, (last)hr9.z
mad.f16 hr33.w, hr38.x, hr44.w, (last)hr33.w
mad.f16 hr29.w, hr38.x, hr45.x, (last)hr29.w
mad.f16 hr25.w, hr38.x, hr45.y, (last)hr25.w
mad.f16 hr21.w, hr38.x, hr45.z, (last)hr21.w
mad.f16 hr17.w, hr38.x, hr5.w, (last)hr17.w
mad.f16 hr13.w, hr38.x, hr6.x, (last)hr13.w
mad.f16 hr9.w, hr38.x, hr6.y, (last)hr9.w
mad.f16 hr34.x, hr38.y, hr44.w, (last)hr34.x
mad.f16 hr30.x, hr38.y, hr45.x, (last)hr30.x
mad.f16 hr26.x, hr38.y, hr45.y, (last)hr26.x
mad.f16 hr22.x, hr38.y, hr45.z, (last)hr22.x
mad.f16 hr18.x, hr38.y, hr5.w, (last)hr18.x
mad.f16 hr14.x, hr38.y, hr6.x, (last)hr14.x
mad.f16 hr10.x, hr38.y, hr6.y, (last)hr10.x
mad.f16 hr34.y, hr38.z, hr44.w, (last)hr34.y
mad.f16 hr30.y, hr38.z, hr45.x, (last)hr30.y
mad.f16 hr26.y, hr38.z, hr45.y, (last)hr26.y
mad.f16 hr22.y, hr38.z, hr45.z, (last)hr22.y
mad.f16 hr18.y, hr38.z, hr5.w, (last)hr18.y
mad.f16 hr14.y, hr38.z, hr6.x, (last)hr14.y
mad.f16 hr10.y, hr38.z, hr6.y, (last)hr10.y
mad.f16 hr32.z, hr39.w, hr44.w, (last)hr32.z
mad.f16 hr28.z, hr39.w, hr45.x, (last)hr28.z
mad.f16 hr24.z, hr39.w, hr45.y, (last)hr24.z
mad.f16 hr20.z, hr39.w, hr45.z, (last)hr20.z
mad.f16 hr32.w, hr40.x, hr44.w, (last)hr32.w
mad.f16 hr28.w, hr40.x, hr45.x, (last)hr28.w
mad.f16 hr24.w, hr40.x, hr45.y, (last)hr24.w
mad.f16 hr20.w, hr40.x, hr45.z, (last)hr20.w
mad.f16 hr33.x, hr40.y, hr44.w, (last)hr33.x
mad.f16 hr29.x, hr40.y, hr45.x, (last)hr29.x
mad.f16 hr25.x, hr40.y, hr45.y, (last)hr25.x
mad.f16 hr21.x, hr40.y, hr45.z, (last)hr21.x
mad.f16 hr33.y, hr40.z, hr44.w, (last)hr33.y
mad.f16 hr29.y, hr40.z, hr45.x, (last)hr29.y
mad.f16 hr25.y, hr40.z, hr45.y, (last)hr25.y
mad.f16 hr21.y, hr40.z, hr45.z, (last)hr21.y
mad.f16 hr31.z, hr40.w, hr44.w, (last)hr31.z
mad.f16 hr27.z, hr40.w, hr45.x, (last)hr27.z
mad.f16 hr23.z, hr40.w, hr45.y, (last)hr23.z
mad.f16 hr19.z, hr40.w, hr45.z, (last)hr19.z
mad.f16 hr31.w, hr41.x, hr44.w, (last)hr31.w
mad.f16 hr27.w, hr41.x, hr45.x, (last)hr27.w
mad.f16 hr23.w, hr41.x, hr45.y, (last)hr23.w
mad.f16 hr19.w, hr41.x, hr45.z, (last)hr19.w
(rpt1)mad.f16 hr32.x, (r)hr41.y, hr44.w, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr41.y, hr45.x, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr41.y, hr45.y, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr41.y, hr45.z, (r)(last)hr20.x
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr6.z, (r)(last)hr42.w
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr6.z, (r)(last)hr43.y
ldl.u16 r42.w, l[r25.z], 4
(rpt1)mad.f16 hr37.w, (r)(last)hr37.w, hr6.z, (r)(last)hr43.w
(rpt1)mad.f16 hr38.y, (r)(last)hr38.y, hr6.z, (r)(last)hr44.y
ldl.u16 r43.w, l[r25.z+128], 4
ldl.u16 r44.w, l[r25.z+256], 4
ldl.u16 r35.w, l[r25.z+384], 4
mad.f16 hr16.z, hr39.w, hr5.w, (last)hr16.z
mad.f16 hr12.z, hr39.w, hr6.x, (last)hr12.z
mad.f16 hr8.z, hr39.w, hr6.y, (last)hr8.z
mad.f16 hr16.w, hr40.x, hr5.w, (last)hr16.w
mad.f16 hr12.w, hr40.x, hr6.x, (last)hr12.w
mad.f16 hr8.w, hr40.x, hr6.y, (last)hr8.w
mad.f16 hr17.x, hr40.y, hr5.w, (last)hr17.x
mad.f16 hr13.x, hr40.y, hr6.x, (last)hr13.x
mad.f16 hr9.x, hr40.y, hr6.y, (last)hr9.x
mad.f16 hr17.y, hr40.z, hr5.w, (last)hr17.y
mad.f16 hr13.y, hr40.z, hr6.x, (last)hr13.y
mad.f16 hr9.y, hr40.z, hr6.y, (last)hr9.y
mad.f16 hr15.z, hr40.w, hr5.w, (last)hr15.z
mad.f16 hr11.z, hr40.w, hr6.x, (last)hr11.z
mad.f16 hr7.z, hr40.w, hr6.y, (last)hr7.z
mad.f16 hr15.w, hr41.x, hr5.w, (last)hr15.w
mad.f16 hr11.w, hr41.x, hr6.x, (last)hr11.w
mad.f16 hr7.w, hr41.x, hr6.y, (last)hr7.w
(rpt1)mad.f16 hr16.x, (r)hr41.y, hr5.w, (r)(last)hr16.x
(rpt1)mad.f16 hr12.x, (r)hr41.y, hr6.x, (r)(last)hr12.x
(rpt1)mad.f16 hr8.x, (r)hr41.y, hr6.y, (r)(last)hr8.x
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr6.z, (r)(last)hr3.w
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr6.z, (r)(last)hr4.y
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr6.z, (r)(last)hr4.w
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr6.z, (r)(last)hr5.y
(ss)mad.f16 hr34.z, hr42.w, hr38.w, (last)hr34.z
mad.f16 hr30.z, hr42.w, hr39.x, (last)hr30.z
mad.f16 hr26.z, hr42.w, hr39.y, (last)hr26.z
mad.f16 hr22.z, hr42.w, hr39.z, (last)hr22.z
mad.f16 hr18.z, hr42.w, hr41.w, (last)hr18.z
mad.f16 hr14.z, hr42.w, hr42.x, (last)hr14.z
mad.f16 hr10.z, hr42.w, hr42.y, (last)hr10.z
mad.f16 hr34.w, hr43.x, hr38.w, (last)hr34.w
mad.f16 hr30.w, hr43.x, hr39.x, (last)hr30.w
mad.f16 hr26.w, hr43.x, hr39.y, (last)hr26.w
mad.f16 hr22.w, hr43.x, hr39.z, (last)hr22.w
mad.f16 hr18.w, hr43.x, hr41.w, (last)hr18.w
mad.f16 hr14.w, hr43.x, hr42.x, (last)hr14.w
mad.f16 hr10.w, hr43.x, hr42.y, (last)hr10.w
mad.f16 hr6.w, (last)hr43.x, hr42.z, (last)hr37.x
mad.f16 hr35.x, hr43.y, hr38.w, (last)hr35.x
mad.f16 hr31.x, hr43.y, hr39.x, (last)hr31.x
mad.f16 hr27.x, hr43.y, hr39.y, (last)hr27.x
mad.f16 hr23.x, hr43.y, hr39.z, (last)hr23.x
mad.f16 hr19.x, hr43.y, hr41.w, (last)hr19.x
mad.f16 hr15.x, hr43.y, hr42.x, (last)hr15.x
mad.f16 hr11.x, hr43.y, hr42.y, (last)hr11.x
mad.f16 hr7.x, (last)hr43.y, hr42.z, (last)hr37.y
mad.f16 hr35.y, hr43.z, hr38.w, (last)hr35.y
mad.f16 hr31.y, hr43.z, hr39.x, (last)hr31.y
mad.f16 hr27.y, hr43.z, hr39.y, (last)hr27.y
mad.f16 hr23.y, hr43.z, hr39.z, (last)hr23.y
mad.f16 hr19.y, hr43.z, hr41.w, (last)hr19.y
mad.f16 hr15.y, hr43.z, hr42.x, (last)hr15.y
mad.f16 hr11.y, hr43.z, hr42.y, (last)hr11.y
mad.f16 hr7.y, (last)hr43.z, hr42.z, (last)hr37.z
mad.f16 hr33.z, hr43.w, hr38.w, (last)hr33.z
mad.f16 hr29.z, hr43.w, hr39.x, (last)hr29.z
mad.f16 hr25.z, hr43.w, hr39.y, (last)hr25.z
mad.f16 hr21.z, hr43.w, hr39.z, (last)hr21.z
mad.f16 hr17.z, hr43.w, hr41.w, (last)hr17.z
mad.f16 hr13.z, hr43.w, hr42.x, (last)hr13.z
mad.f16 hr9.z, hr43.w, hr42.y, (last)hr9.z
mad.f16 hr33.w, hr44.x, hr38.w, (last)hr33.w
mad.f16 hr29.w, hr44.x, hr39.x, (last)hr29.w
mad.f16 hr25.w, hr44.x, hr39.y, (last)hr25.w
mad.f16 hr21.w, hr44.x, hr39.z, (last)hr21.w
mad.f16 hr17.w, hr44.x, hr41.w, (last)hr17.w
mad.f16 hr13.w, hr44.x, hr42.x, (last)hr13.w
mad.f16 hr9.w, hr44.x, hr42.y, (last)hr9.w
mad.f16 hr34.x, hr44.y, hr38.w, (last)hr34.x
mad.f16 hr30.x, hr44.y, hr39.x, (last)hr30.x
mad.f16 hr26.x, hr44.y, hr39.y, (last)hr26.x
mad.f16 hr22.x, hr44.y, hr39.z, (last)hr22.x
mad.f16 hr18.x, hr44.y, hr41.w, (last)hr18.x
mad.f16 hr14.x, hr44.y, hr42.x, (last)hr14.x
mad.f16 hr10.x, hr44.y, hr42.y, (last)hr10.x
mad.f16 hr34.y, hr44.z, hr38.w, (last)hr34.y
mad.f16 hr30.y, hr44.z, hr39.x, (last)hr30.y
mad.f16 hr26.y, hr44.z, hr39.y, (last)hr26.y
mad.f16 hr22.y, hr44.z, hr39.z, (last)hr22.y
mad.f16 hr18.y, hr44.z, hr41.w, (last)hr18.y
mad.f16 hr14.y, hr44.z, hr42.x, (last)hr14.y
mad.f16 hr10.y, hr44.z, hr42.y, (last)hr10.y
mad.f16 hr32.z, hr44.w, hr38.w, (last)hr32.z
mad.f16 hr28.z, hr44.w, hr39.x, (last)hr28.z
mad.f16 hr24.z, hr44.w, hr39.y, (last)hr24.z
mad.f16 hr20.z, hr44.w, hr39.z, (last)hr20.z
mad.f16 hr32.w, hr45.x, hr38.w, (last)hr32.w
mad.f16 hr28.w, hr45.x, hr39.x, (last)hr28.w
mad.f16 hr24.w, hr45.x, hr39.y, (last)hr24.w
mad.f16 hr20.w, hr45.x, hr39.z, (last)hr20.w
mad.f16 hr33.x, hr45.y, hr38.w, (last)hr33.x
mad.f16 hr29.x, hr45.y, hr39.x, (last)hr29.x
mad.f16 hr25.x, hr45.y, hr39.y, (last)hr25.x
mad.f16 hr21.x, hr45.y, hr39.z, (last)hr21.x
mad.f16 hr33.y, hr45.z, hr38.w, (last)hr33.y
mad.f16 hr29.y, hr45.z, hr39.x, (last)hr29.y
mad.f16 hr25.y, hr45.z, hr39.y, (last)hr25.y
mad.f16 hr21.y, hr45.z, hr39.z, (last)hr21.y
mad.f16 hr31.z, hr35.w, hr38.w, (last)hr31.z
mad.f16 hr27.z, hr35.w, hr39.x, (last)hr27.z
mad.f16 hr23.z, hr35.w, hr39.y, (last)hr23.z
mad.f16 hr19.z, hr35.w, hr39.z, (last)hr19.z
mad.f16 hr31.w, hr36.x, hr38.w, (last)hr31.w
mad.f16 hr27.w, hr36.x, hr39.x, (last)hr27.w
mad.f16 hr23.w, hr36.x, hr39.y, (last)hr23.w
mad.f16 hr19.w, hr36.x, hr39.z, (last)hr19.w
(rpt1)mad.f16 hr32.x, (r)hr36.y, hr38.w, (r)(last)hr32.x
(rpt1)mad.f16 hr28.x, (r)hr36.y, hr39.x, (r)(last)hr28.x
(rpt1)mad.f16 hr24.x, (r)hr36.y, hr39.y, (r)(last)hr24.x
(rpt1)mad.f16 hr20.x, (r)hr36.y, hr39.z, (r)(last)hr20.x
fence.r.w
(sy)(ss)mad.f16 hr16.z, hr44.w, hr41.w, (last)hr16.z
mad.f16 hr12.z, hr44.w, hr42.x, (last)hr12.z
mad.f16 hr8.z, hr44.w, hr42.y, (last)hr8.z
mad.f16 hr16.w, hr45.x, hr41.w, (last)hr16.w
mad.f16 hr12.w, hr45.x, hr42.x, (last)hr12.w
mad.f16 hr8.w, hr45.x, hr42.y, (last)hr8.w
mad.f16 hr17.x, hr45.y, hr41.w, (last)hr17.x
mad.f16 hr13.x, hr45.y, hr42.x, (last)hr13.x
mad.f16 hr9.x, hr45.y, hr42.y, (last)hr9.x
mad.f16 hr17.y, hr45.z, hr41.w, (last)hr17.y
mad.f16 hr13.y, hr45.z, hr42.x, (last)hr13.y
mad.f16 hr9.y, hr45.z, hr42.y, (last)hr9.y
mad.f16 hr15.z, hr35.w, hr41.w, (last)hr15.z
mad.f16 hr11.z, hr35.w, hr42.x, (last)hr11.z
mad.f16 hr7.z, hr35.w, hr42.y, (last)hr7.z
mad.f16 hr15.w, hr36.x, hr41.w, (last)hr15.w
mad.f16 hr11.w, hr36.x, hr42.x, (last)hr11.w
mad.f16 hr7.w, hr36.x, hr42.y, (last)hr7.w
(rpt1)mad.f16 hr16.x, (r)hr36.y, hr41.w, (r)(last)hr16.x
mad.f16 hr5.w, (last)hr44.x, hr42.z, (last)hr38.x
(rpt1)mad.f16 hr12.x, (r)hr36.y, hr42.x, (r)(last)hr12.x
mad.f16 hr6.x, (last)hr44.y, hr42.z, (last)hr38.y
(rpt1)mad.f16 hr8.x, (r)hr36.y, hr42.y, (r)(last)hr8.x
mad.f16 hr6.y, (last)hr44.z, hr42.z, (last)hr38.z
mad.f16 hr4.z, (last)hr44.w, hr42.z, (last)hr39.w
mad.f16 hr3.z, (last)hr35.w, hr42.z, (last)hr40.w
mad.f16 hr4.w, (last)hr45.x, hr42.z, (last)hr40.x
mad.f16 hr3.w, (last)hr36.x, hr42.z, (last)hr41.x
mad.f16 hr5.x, (last)hr45.y, hr42.z, (last)hr40.y
mad.f16 hr4.x, (last)hr36.y, hr42.z, (last)hr41.y
mad.f16 hr5.y, (last)hr45.z, hr42.z, (last)hr40.z
mad.f16 hr4.y, (last)hr36.z, hr42.z, (last)hr41.z
mad.f16 hr6.z, (last)hr42.w, hr42.z, (last)hr36.w
mad.f16 hr5.z, (last)hr43.w, hr42.z, (last)hr37.w
bar.g
(sy)(ss)br p0.x, #l2262
jump #l229
l2262:
(jp)(eolm)nop
(nop3) add.u r23.y, r51.w, (last)r23.y
(nop3) shl.b r23.y, (last)r23.y, 9
(nop3) sad.s32 r23.y, r52.y, r23.y, (last)r1.y
(nop3) shl.b r23.y, (last)r23.y, 2
add.u r18.z, r23.y, 128
add.u r18.w, r23.y, 192
add.u r19.x, r23.y, c1.x
add.u r19.y, r23.y, c7.y
(rpt1)add.u r19.z, r23.y, (r)c7.z
add.u r20.x, r23.y, c5.w
add.u r20.y, r23.y, c8.x
(rpt1)add.u r20.z, r23.y, (r)c8.y
add.u r21.x, r23.y, c3.w
add.u r21.y, r23.y, c8.w
(rpt2)add.u r21.z, r23.y, (r)c9.x
add.u r22.y, r23.y, c13.z
(rpt3)add.u r23.z, r23.y, (r)c13.w
(rpt3)add.u r24.z, r23.y, (r)c14.w
(rpt3)add.u r25.z, r23.y, (r)c15.w
(rpt1)add.u r26.z, r23.y, (r)c16.w
stib.b.untyped.1d.u16.4.imm.base0 hr34.z, r23.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr33.z, r23.y+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr32.z, r18.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr31.z, r18.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr30.z, r19.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr29.z, r19.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr28.z, r19.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr27.z, r19.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr26.z, r20.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr25.z, r20.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr24.z, r20.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr23.z, r20.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr22.z, r21.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr21.z, r21.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr20.z, r21.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr19.z, r21.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr18.z, r22.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r22.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r23.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r23.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r24.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r24.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r24.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r24.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r25.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r25.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r25.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r25.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r26.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r26.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r26.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r26.w, 4
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
; CL prog 23/1: 2504 instr, 24 nops, 2480 non-nops, 129 mov, 0 cov, 4672 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 32 full, 20 constlen
; CL prog 23/1: 27 cat0, 129 cat1, 142 cat2, 2058 cat3, 0 cat4, 40 cat5, 104 cat6, 4 cat7
; CL prog 23/1: 114 sstall, 34 (ss), 115 systall, 21 (sy), 1 loops
; CL prog 23/1: 8 max_waves, 0 double_threadsize
; 93 preamble-instr, 1 early-preamble
