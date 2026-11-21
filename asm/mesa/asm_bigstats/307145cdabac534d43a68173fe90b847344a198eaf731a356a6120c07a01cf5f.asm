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
@const(c4.x)	0x00002000, 0x00001800, 0x00001000, 0x00007840
@const(c5.x)	0x00007040, 0x00006840, 0x00006040, 0x00005840
@const(c6.x)	0x00005040, 0x00004840, 0x00004040, 0x00003840
@const(c7.x)	0x00003040, 0x00002840, 0x00002040, 0x00001840
@const(c8.x)	0x00001040, 0x00000840, 0x00010000, 0x00010040
@const(c9.x)	0x00010800, 0x00010840, 0x00011000, 0x00011040
@const(c10.x)	0x00011800, 0x00011840, 0x00020000, 0x00020040
@const(c11.x)	0x00020800, 0x00020840, 0x00021000, 0x00021040
@const(c12.x)	0x00021800, 0x00021840, 0x00030000, 0x00030040
@const(c13.x)	0x00030800, 0x00030840, 0x00031000, 0x00031040
@const(c14.x)	0x00031800, 0x00031840, 0xd0d0d0d0, 0xd0d0d0d0
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
mov.u32u32 r51.y, 0x20000
mov.u32u32 r51.z, 0x20040
mov.u32u32 r51.w, 0x20800
mov.u32u32 r52.x, 0x20840
mov.u32u32 r52.y, 0x21000
mov.u32u32 r52.z, 0x21040
mov.u32u32 r52.w, 0x21800
mov.u32u32 r53.x, 0x21840
mov.u32u32 r53.y, 0x30000
mov.u32u32 r53.z, 0x30040
mov.u32u32 r53.w, 0x30800
mov.u32u32 r54.x, 0x30840
mov.u32u32 r54.y, 0x31000
mov.u32u32 r54.z, 0x31040
mov.u32u32 r54.w, 0x31800
mov.u32u32 r55.x, 0x31840
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
shl.b r48.w, r55.y, 7
shl.b r48.z, r55.z, 7
shr.b r0.w, r0.x, 5
and.b r1.x, r0.x, 31
shr.b r1.y, r0.x, 4
and.b r1.z, r0.x, 15
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
l214:
(rpt1)shr.b r49.y, (r)r48.z, 2
shl.b r49.w, r49.x, 9
add.u r18.y, r0.x, 128
add.u r18.z, r0.x, 256
add.u r18.w, r0.x, 384
shl.b r17.w, r0.w, 8
(rpt2)shr.b r18.y, (last)(r)r18.y, 5
(ss)add.u r19.x, r49.x, r0.w
(rpt2)add.u r19.y, r49.x, (r)r18.y
add.u r49.x, r49.x, 16
cmps.u.ge up0.x, r49.x, c1.x
shl.b r19.x, (last)r19.x, 9
(rpt2)shl.b r19.y, (last)(r)r19.y, 9
sad.s32 r19.x, r49.y, r19.x, r1.x
(rpt2)sad.s32 r19.y, r49.y, (r)r19.y, r1.x
shl.b r19.x, (last)r19.x, 2
(rpt1)shl.b r19.y, (last)(r)r19.y, 2
shl.b r19.w, (last)r19.w, 2
shl.b r18.x, r1.x, 3
(rpt1)shl.b r18.y, (last)(r)r18.y, 8
isam.v.base0 (u16)(xyzw)hr40.x, r19.x, s#0, t#0
shl.b r18.w, (last)r18.w, 8
isam.v.base0 (u16)(xyzw)hr42.x, r19.y, s#0, t#0
shl.b r20.z, r1.y, 3
isam.v.base0 (u16)(xyzw)hr43.x, r19.z, s#0, t#0
add.u r17.w, (last)r17.w, r18.x
isam.v.base0 (u16)(xyzw)hr44.z, r19.w, s#0, t#0
(rpt2)add.u r18.y, (last)(r)r18.y, (last)r18.x
sad.s32 r22.x, r49.w, r1.z, r49.z
(nop2) shl.b r20.w, r1.y, 2
(nop3) shl.b r22.x, (last)r22.x, 2
add.u r22.w, r22.x, c1.x
add.u r23.x, r22.x, c8.y
add.u r23.y, r22.x, c4.z
add.u r23.z, r22.x, c8.x
add.u r23.w, r22.x, c4.y
add.u r24.x, r22.x, c7.w
add.u r24.y, r22.x, c4.x
add.u r24.z, r22.x, c7.z
add.u r24.w, r22.x, c3.w
add.u r25.x, r22.x, c7.y
add.u r25.y, r22.x, c3.z
add.u r25.z, r22.x, c7.x
add.u r25.w, r22.x, c3.y
add.u r26.x, r22.x, c6.w
add.u r26.y, r22.x, c3.x
add.u r26.z, r22.x, c6.z
add.u r26.w, r22.x, c2.w
add.u r27.x, r22.x, c6.y
add.u r27.y, r22.x, c2.z
add.u r27.z, r22.x, c6.x
add.u r27.w, r22.x, c2.y
add.u r28.x, r22.x, c5.w
add.u r28.y, r22.x, c2.x
add.u r28.z, r22.x, c5.z
add.u r28.w, r22.x, c1.w
add.u r29.x, r22.x, c5.y
add.u r29.y, r22.x, c1.z
add.u r29.z, r22.x, c5.x
add.u r29.w, r22.x, c1.y
add.u r30.x, r22.x, c4.w
(sy)stl.u16 l[r17.w], r40.x, 4
stl.u16 l[r18.y], r42.x, 4
stl.u16 l[r18.z], r43.x, 4
stl.u16 l[r18.w], r44.z, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
ldl.u16 r0.z, l[r20.z], 4
ldl.u16 r36.w, l[r20.z+64], 4
isam.v.base0 (u16)(xyzw)hr35.w, r22.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr37.w, r22.x+64, s#0, t#2
ldl.u16 r38.w, l[r20.z+128], 4
isam.v.base0 (u16)(xyzw)hr42.y, r22.w, s#0, t#2
ldl.u16 r39.w, l[r20.z+192], 4
(ss)nop
isam.v.base0 (u16)(xyzw)hr45.y, r23.x, s#0, t#2
ldl.u16 r43.y, l[r20.z+256], 4
ldl.u16 r44.y, l[r20.z+320], 4
(sy)mad.f16 hr34.z, hr35.w, hr0.z, (last)hr34.z
mad.f16 hr32.z, hr35.w, hr0.w, (last)hr32.z
mad.f16 hr30.z, hr35.w, hr1.x, (last)hr30.z
mad.f16 hr28.z, hr35.w, hr1.y, (last)hr28.z
mad.f16 hr34.w, hr36.x, hr0.z, (last)hr34.w
mad.f16 hr32.w, hr36.x, hr0.w, (last)hr32.w
mad.f16 hr30.w, hr36.x, hr1.x, (last)hr30.w
mad.f16 hr28.w, hr36.x, hr1.y, (last)hr28.w
mad.f16 hr35.x, hr36.y, hr0.z, (last)hr35.x
mad.f16 hr33.x, hr36.y, hr0.w, (last)hr33.x
mad.f16 hr31.x, hr36.y, hr1.x, (last)hr31.x
mad.f16 hr29.x, hr36.y, hr1.y, (last)hr29.x
mad.f16 hr35.y, hr36.z, hr0.z, (last)hr35.y
mad.f16 hr33.y, hr36.z, hr0.w, (last)hr33.y
mad.f16 hr31.y, hr36.z, hr1.x, (last)hr31.y
mad.f16 hr29.y, hr36.z, hr1.y, (last)hr29.y
(rpt1)mad.f16 hr26.z, (r)hr35.w, hr36.w, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr36.y, hr36.w, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr35.w, hr37.x, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr36.y, hr37.x, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr35.w, hr37.y, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr36.y, hr37.y, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr35.w, hr37.z, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr36.y, hr37.z, (r)(last)hr21.x
mad.f16 hr33.z, hr37.w, hr0.z, (last)hr33.z
mad.f16 hr31.z, hr37.w, hr0.w, (last)hr31.z
mad.f16 hr29.z, hr37.w, hr1.x, (last)hr29.z
mad.f16 hr27.z, hr37.w, hr1.y, (last)hr27.z
mad.f16 hr25.z, hr37.w, hr36.w, (last)hr25.z
mad.f16 hr23.z, hr37.w, hr37.x, (last)hr23.z
mad.f16 hr21.z, hr37.w, hr37.y, (last)hr21.z
mad.f16 hr19.z, hr37.w, hr37.z, (last)hr19.z
mad.f16 hr33.w, hr38.x, hr0.z, (last)hr33.w
mad.f16 hr31.w, hr38.x, hr0.w, (last)hr31.w
mad.f16 hr29.w, hr38.x, hr1.x, (last)hr29.w
mad.f16 hr27.w, hr38.x, hr1.y, (last)hr27.w
mad.f16 hr25.w, hr38.x, hr36.w, (last)hr25.w
mad.f16 hr23.w, hr38.x, hr37.x, (last)hr23.w
mad.f16 hr21.w, hr38.x, hr37.y, (last)hr21.w
mad.f16 hr19.w, hr38.x, hr37.z, (last)hr19.w
(rpt1)mad.f16 hr34.x, (r)hr38.y, hr0.z, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr38.y, hr0.w, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr38.y, hr1.x, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr38.y, hr1.y, (r)(last)hr28.x
ldl.u16 r0.z, l[r20.z+384], 4
(rpt1)mad.f16 hr26.x, (r)hr38.y, hr36.w, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr38.y, hr37.x, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr38.y, hr37.y, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr38.y, hr37.z, (r)(last)hr20.x
isam.v.base0 (u16)(xyzw)hr36.w, r23.y, s#0, t#2
(rpt1)mad.f16 hr18.z, (r)hr35.w, hr38.w, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr36.y, hr38.w, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr37.w, hr38.w, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr38.y, hr38.w, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr35.w, hr39.x, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr36.y, hr39.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr37.w, hr39.x, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr38.y, hr39.x, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr35.w, hr39.y, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr36.y, hr39.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr37.w, hr39.y, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr38.y, hr39.y, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr35.w, hr39.z, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr36.y, hr39.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr37.w, hr39.z, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr38.y, hr39.z, (r)(last)hr12.x
(rpt1)mad.f16 hr10.z, (r)hr35.w, hr39.w, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr36.y, hr39.w, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr37.w, hr39.w, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr38.y, hr39.w, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr35.w, hr40.x, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr36.y, hr40.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr37.w, hr40.x, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr38.y, hr40.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr35.w, hr40.y, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr36.y, hr40.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr37.w, hr40.y, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr38.y, hr40.y, (r)(last)hr6.x
(rpt1)mad.f16 hr35.w, (r)(last)hr35.w, hr40.z, (r)(last)hr4.z
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr40.z, (r)(last)hr5.x
(rpt1)mad.f16 hr37.w, (r)(last)hr37.w, hr40.z, (r)(last)hr3.z
(rpt1)mad.f16 hr38.y, (r)(last)hr38.y, hr40.z, (r)(last)hr4.x
isam.v.base0 (u16)(xyzw)hr39.w, r23.z, s#0, t#2
ldl.u16 r3.z, l[r20.z+448], 4
(ss)mad.f16 hr34.z, hr42.y, hr43.y, (last)hr34.z
isam.v.base0 (u16)(xyzw)hr46.y, r23.w, s#0, t#2
mad.f16 hr32.z, hr42.y, hr43.z, (last)hr32.z
mad.f16 hr30.z, hr42.y, hr43.w, (last)hr30.z
mad.f16 hr28.z, hr42.y, hr44.x, (last)hr28.z
mad.f16 hr34.w, hr42.z, hr43.y, (last)hr34.w
mad.f16 hr32.w, hr42.z, hr43.z, (last)hr32.w
mad.f16 hr30.w, hr42.z, hr43.w, (last)hr30.w
mad.f16 hr28.w, hr42.z, hr44.x, (last)hr28.w
mad.f16 hr35.x, hr42.w, hr43.y, (last)hr35.x
mad.f16 hr33.x, hr42.w, hr43.z, (last)hr33.x
mad.f16 hr31.x, hr42.w, hr43.w, (last)hr31.x
mad.f16 hr29.x, hr42.w, hr44.x, (last)hr29.x
mad.f16 hr35.y, hr43.x, hr43.y, (last)hr35.y
mad.f16 hr33.y, hr43.x, hr43.z, (last)hr33.y
mad.f16 hr31.y, hr43.x, hr43.w, (last)hr31.y
mad.f16 hr29.y, hr43.x, hr44.x, (last)hr29.y
(rpt1)mad.f16 hr26.z, (r)hr42.y, hr44.y, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr42.w, hr44.y, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr42.y, hr44.z, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr42.w, hr44.z, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr42.y, hr44.w, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr42.w, hr44.w, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr42.y, hr45.x, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr42.w, hr45.x, (r)(last)hr21.x
(rpt1)mad.f16 hr18.z, (r)hr42.y, hr0.z, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr42.w, hr0.z, (r)(last)hr19.x
(rpt1)mad.f16 hr16.z, (r)hr42.y, hr0.w, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr42.w, hr0.w, (r)(last)hr17.x
(rpt1)mad.f16 hr14.z, (r)hr42.y, hr1.x, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr42.w, hr1.x, (r)(last)hr15.x
(rpt1)mad.f16 hr12.z, (r)hr42.y, hr1.y, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr42.w, hr1.y, (r)(last)hr13.x
(rpt1)mad.f16 hr10.z, (r)hr42.y, hr3.z, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr42.w, hr3.z, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr42.y, hr3.w, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr42.w, hr3.w, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr42.y, hr4.x, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr42.w, hr4.x, (r)(last)hr7.x
(rpt1)mad.f16 hr42.y, (r)(last)hr42.y, hr4.y, (r)(last)hr35.w
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr4.y, (r)(last)hr36.y
isam.v.base0 (u16)(xyzw)hr35.w, r24.x, s#0, t#2
mad.f16 hr33.z, hr45.y, hr43.y, (last)hr33.z
mad.f16 hr31.z, hr45.y, hr43.z, (last)hr31.z
mad.f16 hr29.z, hr45.y, hr43.w, (last)hr29.z
mad.f16 hr27.z, hr45.y, hr44.x, (last)hr27.z
mad.f16 hr25.z, hr45.y, hr44.y, (last)hr25.z
mad.f16 hr23.z, hr45.y, hr44.z, (last)hr23.z
mad.f16 hr21.z, hr45.y, hr44.w, (last)hr21.z
mad.f16 hr19.z, hr45.y, hr45.x, (last)hr19.z
mad.f16 hr33.w, hr45.z, hr43.y, (last)hr33.w
mad.f16 hr31.w, hr45.z, hr43.z, (last)hr31.w
mad.f16 hr29.w, hr45.z, hr43.w, (last)hr29.w
mad.f16 hr27.w, hr45.z, hr44.x, (last)hr27.w
mad.f16 hr25.w, hr45.z, hr44.y, (last)hr25.w
mad.f16 hr23.w, hr45.z, hr44.z, (last)hr23.w
mad.f16 hr21.w, hr45.z, hr44.w, (last)hr21.w
mad.f16 hr19.w, hr45.z, hr45.x, (last)hr19.w
(rpt1)mad.f16 hr34.x, (r)hr45.w, hr43.y, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr45.w, hr43.z, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr45.w, hr43.w, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr45.w, hr44.x, (r)(last)hr28.x
(rpt1)mad.f16 hr26.x, (r)hr45.w, hr44.y, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr45.w, hr44.z, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr45.w, hr44.w, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr45.w, hr45.x, (r)(last)hr20.x
(rpt1)mad.f16 hr17.z, (r)hr45.y, hr0.z, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr45.w, hr0.z, (r)(last)hr18.x
(rpt1)mad.f16 hr15.z, (r)hr45.y, hr0.w, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr45.w, hr0.w, (r)(last)hr16.x
(rpt1)mad.f16 hr13.z, (r)hr45.y, hr1.x, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr45.w, hr1.x, (r)(last)hr14.x
(rpt1)mad.f16 hr11.z, (r)hr45.y, hr1.y, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr45.w, hr1.y, (r)(last)hr12.x
(rpt1)mad.f16 hr9.z, (r)hr45.y, hr3.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr45.w, hr3.z, (r)(last)hr10.x
(rpt1)mad.f16 hr7.z, (r)hr45.y, hr3.w, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr45.w, hr3.w, (r)(last)hr8.x
(rpt1)mad.f16 hr5.z, (r)hr45.y, hr4.x, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr45.w, hr4.x, (r)(last)hr6.x
(rpt1)mad.f16 hr45.y, (r)(last)hr45.y, hr4.y, (r)(last)hr37.w
(rpt1)mad.f16 hr45.w, (r)(last)hr45.w, hr4.y, (r)(last)hr38.y
ldl.u16 r37.w, l[r20.z+512], 4
ldl.u16 r38.w, l[r20.z+576], 4
ldl.u16 r43.y, l[r20.z+640], 4
ldl.u16 r44.y, l[r20.z+704], 4
ldl.u16 r0.z, l[r20.z+768], 4
ldl.u16 r3.z, l[r20.z+832], 4
(sy)(ss)(rpt1)mad.f16 hr34.z, (r)hr36.w, hr37.w, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr37.y, hr37.w, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr36.w, hr38.x, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr37.y, hr38.x, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr36.w, hr38.y, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr37.y, hr38.y, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr36.w, hr38.z, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr37.y, hr38.z, (r)(last)hr29.x
mad.f16 hr33.z, hr39.w, hr37.w, (last)hr33.z
mad.f16 hr31.z, hr39.w, hr38.x, (last)hr31.z
mad.f16 hr29.z, hr39.w, hr38.y, (last)hr29.z
mad.f16 hr27.z, hr39.w, hr38.z, (last)hr27.z
mad.f16 hr33.w, hr40.x, hr37.w, (last)hr33.w
mad.f16 hr31.w, hr40.x, hr38.x, (last)hr31.w
mad.f16 hr29.w, hr40.x, hr38.y, (last)hr29.w
mad.f16 hr27.w, hr40.x, hr38.z, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr40.y, hr37.w, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr40.y, hr38.x, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr40.y, hr38.y, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr40.y, hr38.z, (r)(last)hr28.x
ldl.u16 r37.w, l[r20.z+896], 4
(rpt1)mad.f16 hr26.z, (r)hr36.w, hr38.w, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr37.y, hr38.w, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr36.w, hr39.x, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr37.y, hr39.x, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr36.w, hr39.y, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr37.y, hr39.y, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr36.w, hr39.z, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr37.y, hr39.z, (r)(last)hr21.x
mad.f16 hr25.z, hr39.w, hr38.w, (last)hr25.z
mad.f16 hr23.z, hr39.w, hr39.x, (last)hr23.z
mad.f16 hr21.z, hr39.w, hr39.y, (last)hr21.z
mad.f16 hr19.z, hr39.w, hr39.z, (last)hr19.z
mad.f16 hr25.w, hr40.x, hr38.w, (last)hr25.w
mad.f16 hr23.w, hr40.x, hr39.x, (last)hr23.w
mad.f16 hr21.w, hr40.x, hr39.y, (last)hr21.w
mad.f16 hr19.w, hr40.x, hr39.z, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr40.y, hr38.w, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr40.y, hr39.x, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr40.y, hr39.y, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr40.y, hr39.z, (r)(last)hr20.x
ldl.u16 r38.w, l[r20.z+960], 4
(rpt1)mad.f16 hr18.z, (r)hr36.w, hr43.y, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr37.y, hr43.y, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr39.w, hr43.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr40.y, hr43.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr36.w, hr43.z, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr37.y, hr43.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr39.w, hr43.z, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr40.y, hr43.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr36.w, hr43.w, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr37.y, hr43.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr39.w, hr43.w, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr40.y, hr43.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr36.w, hr44.x, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr37.y, hr44.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr39.w, hr44.x, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr40.y, hr44.x, (r)(last)hr12.x
ldl.u16 r43.y, l[r20.z+1024], 4
(rpt1)mad.f16 hr10.z, (r)hr36.w, hr44.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr37.y, hr44.y, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr39.w, hr44.y, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr40.y, hr44.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr36.w, hr44.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr37.y, hr44.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr39.w, hr44.z, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr40.y, hr44.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr36.w, hr44.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr37.y, hr44.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr39.w, hr44.w, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr40.y, hr44.w, (r)(last)hr6.x
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr45.x, (r)(last)hr42.y
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr45.x, (r)(last)hr42.w
isam.v.base0 (u16)(xyzw)hr42.y, r24.y, s#0, t#2
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr45.x, (r)(last)hr45.y
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr45.x, (r)(last)hr45.w
isam.v.base0 (u16)(xyzw)hr45.y, r24.z, s#0, t#2
ldl.u16 r44.y, l[r20.z+1088], 4
(rpt1)mad.f16 hr34.z, (r)hr46.y, hr0.z, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr46.w, hr0.z, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr46.y, hr0.w, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr46.w, hr0.w, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr46.y, hr1.x, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr46.w, hr1.x, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr46.y, hr1.y, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr46.w, hr1.y, (r)(last)hr29.x
mad.f16 hr33.z, hr35.w, hr0.z, (last)hr33.z
mad.f16 hr31.z, hr35.w, hr0.w, (last)hr31.z
mad.f16 hr29.z, hr35.w, hr1.x, (last)hr29.z
mad.f16 hr27.z, hr35.w, hr1.y, (last)hr27.z
mad.f16 hr33.w, hr36.x, hr0.z, (last)hr33.w
mad.f16 hr31.w, hr36.x, hr0.w, (last)hr31.w
mad.f16 hr29.w, hr36.x, hr1.x, (last)hr29.w
mad.f16 hr27.w, hr36.x, hr1.y, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr36.y, hr0.z, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr36.y, hr0.w, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr36.y, hr1.x, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr36.y, hr1.y, (r)(last)hr28.x
ldl.u16 r0.z, l[r20.z+1152], 4
(rpt1)mad.f16 hr26.z, (r)hr46.y, hr3.z, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr46.w, hr3.z, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr46.y, hr3.w, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr46.w, hr3.w, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr46.y, hr4.x, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr46.w, hr4.x, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr46.y, hr4.y, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr46.w, hr4.y, (r)(last)hr21.x
mad.f16 hr25.z, hr35.w, hr3.z, (last)hr25.z
mad.f16 hr23.z, hr35.w, hr3.w, (last)hr23.z
mad.f16 hr21.z, hr35.w, hr4.x, (last)hr21.z
mad.f16 hr19.z, hr35.w, hr4.y, (last)hr19.z
mad.f16 hr25.w, hr36.x, hr3.z, (last)hr25.w
mad.f16 hr23.w, hr36.x, hr3.w, (last)hr23.w
mad.f16 hr21.w, hr36.x, hr4.x, (last)hr21.w
mad.f16 hr19.w, hr36.x, hr4.y, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr36.y, hr3.z, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr36.y, hr3.w, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr36.y, hr4.x, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr36.y, hr4.y, (r)(last)hr20.x
ldl.u16 r3.z, l[r20.z+1216], 4
(ss)(rpt1)mad.f16 hr18.z, (r)hr46.y, hr37.w, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr46.w, hr37.w, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr35.w, hr37.w, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr36.y, hr37.w, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr46.y, hr38.x, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr46.w, hr38.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr35.w, hr38.x, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr36.y, hr38.x, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr46.y, hr38.y, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr46.w, hr38.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr35.w, hr38.y, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr36.y, hr38.y, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr46.y, hr38.z, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr46.w, hr38.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr35.w, hr38.z, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr36.y, hr38.z, (r)(last)hr12.x
ldl.u16 r37.w, l[r20.z+1280], 4
(rpt1)mad.f16 hr10.z, (r)hr46.y, hr38.w, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr46.w, hr38.w, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr35.w, hr38.w, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr36.y, hr38.w, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr46.y, hr39.x, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr46.w, hr39.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr35.w, hr39.x, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr36.y, hr39.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr46.y, hr39.y, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr46.w, hr39.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr35.w, hr39.y, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr36.y, hr39.y, (r)(last)hr6.x
(rpt1)mad.f16 hr46.y, (r)(last)hr46.y, hr39.z, (r)(last)hr36.w
(rpt1)mad.f16 hr46.w, (r)(last)hr46.w, hr39.z, (r)(last)hr37.y
isam.v.base0 (u16)(xyzw)hr36.w, r24.w, s#0, t#2
(rpt1)mad.f16 hr35.w, (r)(last)hr35.w, hr39.z, (r)(last)hr39.w
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr39.z, (r)(last)hr40.y
isam.v.base0 (u16)(xyzw)hr39.w, r25.x, s#0, t#2
ldl.u16 r38.w, l[r20.z+1344], 4
(sy)(rpt1)mad.f16 hr34.z, (r)hr42.y, hr43.y, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr42.w, hr43.y, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr42.y, hr43.z, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr42.w, hr43.z, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr42.y, hr43.w, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr42.w, hr43.w, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr42.y, hr44.x, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr42.w, hr44.x, (r)(last)hr29.x
mad.f16 hr33.z, hr45.y, hr43.y, (last)hr33.z
mad.f16 hr31.z, hr45.y, hr43.z, (last)hr31.z
mad.f16 hr29.z, hr45.y, hr43.w, (last)hr29.z
mad.f16 hr27.z, hr45.y, hr44.x, (last)hr27.z
mad.f16 hr33.w, hr45.z, hr43.y, (last)hr33.w
mad.f16 hr31.w, hr45.z, hr43.z, (last)hr31.w
mad.f16 hr29.w, hr45.z, hr43.w, (last)hr29.w
mad.f16 hr27.w, hr45.z, hr44.x, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr45.w, hr43.y, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr45.w, hr43.z, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr45.w, hr43.w, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr45.w, hr44.x, (r)(last)hr28.x
ldl.u16 r43.y, l[r20.z+1408], 4
(rpt1)mad.f16 hr26.z, (r)hr42.y, hr44.y, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr42.w, hr44.y, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr42.y, hr44.z, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr42.w, hr44.z, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr42.y, hr44.w, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr42.w, hr44.w, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr42.y, hr45.x, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr42.w, hr45.x, (r)(last)hr21.x
mad.f16 hr25.z, hr45.y, hr44.y, (last)hr25.z
mad.f16 hr23.z, hr45.y, hr44.z, (last)hr23.z
mad.f16 hr21.z, hr45.y, hr44.w, (last)hr21.z
mad.f16 hr19.z, hr45.y, hr45.x, (last)hr19.z
mad.f16 hr25.w, hr45.z, hr44.y, (last)hr25.w
mad.f16 hr23.w, hr45.z, hr44.z, (last)hr23.w
mad.f16 hr21.w, hr45.z, hr44.w, (last)hr21.w
mad.f16 hr19.w, hr45.z, hr45.x, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr45.w, hr44.y, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr45.w, hr44.z, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr45.w, hr44.w, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr45.w, hr45.x, (r)(last)hr20.x
ldl.u16 r44.y, l[r20.z+1472], 4
(rpt1)mad.f16 hr18.z, (r)hr42.y, hr0.z, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr42.w, hr0.z, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr45.y, hr0.z, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr45.w, hr0.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr42.y, hr0.w, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr42.w, hr0.w, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr45.y, hr0.w, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr45.w, hr0.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr42.y, hr1.x, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr42.w, hr1.x, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr45.y, hr1.x, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr45.w, hr1.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr42.y, hr1.y, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr42.w, hr1.y, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr45.y, hr1.y, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr45.w, hr1.y, (r)(last)hr12.x
ldl.u16 r0.z, l[r20.z+1536], 4
(rpt1)mad.f16 hr10.z, (r)hr42.y, hr3.z, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr42.w, hr3.z, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr45.y, hr3.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr45.w, hr3.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr42.y, hr3.w, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr42.w, hr3.w, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr45.y, hr3.w, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr45.w, hr3.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr42.y, hr4.x, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr42.w, hr4.x, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr45.y, hr4.x, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr45.w, hr4.x, (r)(last)hr6.x
(rpt1)mad.f16 hr42.y, (r)(last)hr42.y, hr4.y, (r)(last)hr46.y
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr4.y, (r)(last)hr46.w
isam.v.base0 (u16)(xyzw)hr46.y, r25.y, s#0, t#2
(rpt1)mad.f16 hr45.y, (r)(last)hr45.y, hr4.y, (r)(last)hr35.w
(rpt1)mad.f16 hr45.w, (r)(last)hr45.w, hr4.y, (r)(last)hr36.y
isam.v.base0 (u16)(xyzw)hr35.w, r25.z, s#0, t#2
ldl.u16 r3.z, l[r20.z+1600], 4
(ss)(rpt1)mad.f16 hr34.z, (r)hr36.w, hr37.w, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr37.y, hr37.w, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr36.w, hr38.x, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr37.y, hr38.x, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr36.w, hr38.y, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr37.y, hr38.y, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr36.w, hr38.z, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr37.y, hr38.z, (r)(last)hr29.x
mad.f16 hr33.z, hr39.w, hr37.w, (last)hr33.z
mad.f16 hr31.z, hr39.w, hr38.x, (last)hr31.z
mad.f16 hr29.z, hr39.w, hr38.y, (last)hr29.z
mad.f16 hr27.z, hr39.w, hr38.z, (last)hr27.z
mad.f16 hr33.w, hr40.x, hr37.w, (last)hr33.w
mad.f16 hr31.w, hr40.x, hr38.x, (last)hr31.w
mad.f16 hr29.w, hr40.x, hr38.y, (last)hr29.w
mad.f16 hr27.w, hr40.x, hr38.z, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr40.y, hr37.w, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr40.y, hr38.x, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr40.y, hr38.y, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr40.y, hr38.z, (r)(last)hr28.x
ldl.u16 r37.w, l[r20.z+1664], 4
(rpt1)mad.f16 hr26.z, (r)hr36.w, hr38.w, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr37.y, hr38.w, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr36.w, hr39.x, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr37.y, hr39.x, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr36.w, hr39.y, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr37.y, hr39.y, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr36.w, hr39.z, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr37.y, hr39.z, (r)(last)hr21.x
mad.f16 hr25.z, hr39.w, hr38.w, (last)hr25.z
mad.f16 hr23.z, hr39.w, hr39.x, (last)hr23.z
mad.f16 hr21.z, hr39.w, hr39.y, (last)hr21.z
mad.f16 hr19.z, hr39.w, hr39.z, (last)hr19.z
mad.f16 hr25.w, hr40.x, hr38.w, (last)hr25.w
mad.f16 hr23.w, hr40.x, hr39.x, (last)hr23.w
mad.f16 hr21.w, hr40.x, hr39.y, (last)hr21.w
mad.f16 hr19.w, hr40.x, hr39.z, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr40.y, hr38.w, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr40.y, hr39.x, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr40.y, hr39.y, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr40.y, hr39.z, (r)(last)hr20.x
ldl.u16 r38.w, l[r20.z+1728], 4
(rpt1)mad.f16 hr18.z, (r)hr36.w, hr43.y, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr37.y, hr43.y, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr39.w, hr43.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr40.y, hr43.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr36.w, hr43.z, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr37.y, hr43.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr39.w, hr43.z, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr40.y, hr43.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr36.w, hr43.w, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr37.y, hr43.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr39.w, hr43.w, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr40.y, hr43.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr36.w, hr44.x, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr37.y, hr44.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr39.w, hr44.x, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr40.y, hr44.x, (r)(last)hr12.x
ldl.u16 r43.y, l[r20.z+1792], 4
(rpt1)mad.f16 hr10.z, (r)hr36.w, hr44.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr37.y, hr44.y, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr39.w, hr44.y, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr40.y, hr44.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr36.w, hr44.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr37.y, hr44.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr39.w, hr44.z, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr40.y, hr44.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr36.w, hr44.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr37.y, hr44.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr39.w, hr44.w, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr40.y, hr44.w, (r)(last)hr6.x
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr45.x, (r)(last)hr42.y
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr45.x, (r)(last)hr42.w
isam.v.base0 (u16)(xyzw)hr42.y, r25.w, s#0, t#2
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr45.x, (r)(last)hr45.y
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr45.x, (r)(last)hr45.w
isam.v.base0 (u16)(xyzw)hr45.y, r26.x, s#0, t#2
ldl.u16 r44.y, l[r20.z+1856], 4
(sy)(rpt1)mad.f16 hr34.z, (r)hr46.y, hr0.z, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr46.w, hr0.z, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr46.y, hr0.w, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr46.w, hr0.w, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr46.y, hr1.x, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr46.w, hr1.x, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr46.y, hr1.y, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr46.w, hr1.y, (r)(last)hr29.x
mad.f16 hr33.z, hr35.w, hr0.z, (last)hr33.z
mad.f16 hr31.z, hr35.w, hr0.w, (last)hr31.z
mad.f16 hr29.z, hr35.w, hr1.x, (last)hr29.z
mad.f16 hr27.z, hr35.w, hr1.y, (last)hr27.z
mad.f16 hr33.w, hr36.x, hr0.z, (last)hr33.w
mad.f16 hr31.w, hr36.x, hr0.w, (last)hr31.w
mad.f16 hr29.w, hr36.x, hr1.x, (last)hr29.w
mad.f16 hr27.w, hr36.x, hr1.y, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr36.y, hr0.z, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr36.y, hr0.w, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr36.y, hr1.x, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr36.y, hr1.y, (r)(last)hr28.x
ldl.u16 r0.z, l[r20.z+1920], 4
(rpt1)mad.f16 hr26.z, (r)hr46.y, hr3.z, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr46.w, hr3.z, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr46.y, hr3.w, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr46.w, hr3.w, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr46.y, hr4.x, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr46.w, hr4.x, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr46.y, hr4.y, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr46.w, hr4.y, (r)(last)hr21.x
mad.f16 hr25.z, hr35.w, hr3.z, (last)hr25.z
mad.f16 hr23.z, hr35.w, hr3.w, (last)hr23.z
mad.f16 hr21.z, hr35.w, hr4.x, (last)hr21.z
mad.f16 hr19.z, hr35.w, hr4.y, (last)hr19.z
mad.f16 hr25.w, hr36.x, hr3.z, (last)hr25.w
mad.f16 hr23.w, hr36.x, hr3.w, (last)hr23.w
mad.f16 hr21.w, hr36.x, hr4.x, (last)hr21.w
mad.f16 hr19.w, hr36.x, hr4.y, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr36.y, hr3.z, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr36.y, hr3.w, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr36.y, hr4.x, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr36.y, hr4.y, (r)(last)hr20.x
ldl.u16 r3.z, l[r20.z+1984], 4
(ss)(rpt1)mad.f16 hr18.z, (r)hr46.y, hr37.w, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr46.w, hr37.w, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr35.w, hr37.w, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr36.y, hr37.w, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr46.y, hr38.x, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr46.w, hr38.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr35.w, hr38.x, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr36.y, hr38.x, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr46.y, hr38.y, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr46.w, hr38.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr35.w, hr38.y, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr36.y, hr38.y, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr46.y, hr38.z, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr46.w, hr38.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr35.w, hr38.z, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr36.y, hr38.z, (r)(last)hr12.x
ldl.u16 r37.w, l[r20.z+2048], 4
(rpt1)mad.f16 hr10.z, (r)hr46.y, hr38.w, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr46.w, hr38.w, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr35.w, hr38.w, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr36.y, hr38.w, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr46.y, hr39.x, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr46.w, hr39.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr35.w, hr39.x, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr36.y, hr39.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr46.y, hr39.y, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr46.w, hr39.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr35.w, hr39.y, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr36.y, hr39.y, (r)(last)hr6.x
(rpt1)mad.f16 hr46.y, (r)(last)hr46.y, hr39.z, (r)(last)hr36.w
(rpt1)mad.f16 hr46.w, (r)(last)hr46.w, hr39.z, (r)(last)hr37.y
isam.v.base0 (u16)(xyzw)hr36.w, r26.y, s#0, t#2
(rpt1)mad.f16 hr35.w, (r)(last)hr35.w, hr39.z, (r)(last)hr39.w
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr39.z, (r)(last)hr40.y
isam.v.base0 (u16)(xyzw)hr39.w, r26.z, s#0, t#2
ldl.u16 r38.w, l[r20.z+2112], 4
(rpt1)mad.f16 hr34.z, (r)hr42.y, hr43.y, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr42.w, hr43.y, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr42.y, hr43.z, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr42.w, hr43.z, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr42.y, hr43.w, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr42.w, hr43.w, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr42.y, hr44.x, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr42.w, hr44.x, (r)(last)hr29.x
mad.f16 hr33.z, hr45.y, hr43.y, (last)hr33.z
mad.f16 hr31.z, hr45.y, hr43.z, (last)hr31.z
mad.f16 hr29.z, hr45.y, hr43.w, (last)hr29.z
mad.f16 hr27.z, hr45.y, hr44.x, (last)hr27.z
mad.f16 hr33.w, hr45.z, hr43.y, (last)hr33.w
mad.f16 hr31.w, hr45.z, hr43.z, (last)hr31.w
mad.f16 hr29.w, hr45.z, hr43.w, (last)hr29.w
mad.f16 hr27.w, hr45.z, hr44.x, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr45.w, hr43.y, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr45.w, hr43.z, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr45.w, hr43.w, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr45.w, hr44.x, (r)(last)hr28.x
ldl.u16 r43.y, l[r20.z+2176], 4
(rpt1)mad.f16 hr26.z, (r)hr42.y, hr44.y, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr42.w, hr44.y, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr42.y, hr44.z, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr42.w, hr44.z, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr42.y, hr44.w, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr42.w, hr44.w, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr42.y, hr45.x, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr42.w, hr45.x, (r)(last)hr21.x
mad.f16 hr25.z, hr45.y, hr44.y, (last)hr25.z
mad.f16 hr23.z, hr45.y, hr44.z, (last)hr23.z
mad.f16 hr21.z, hr45.y, hr44.w, (last)hr21.z
mad.f16 hr19.z, hr45.y, hr45.x, (last)hr19.z
mad.f16 hr25.w, hr45.z, hr44.y, (last)hr25.w
mad.f16 hr23.w, hr45.z, hr44.z, (last)hr23.w
mad.f16 hr21.w, hr45.z, hr44.w, (last)hr21.w
mad.f16 hr19.w, hr45.z, hr45.x, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr45.w, hr44.y, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr45.w, hr44.z, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr45.w, hr44.w, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr45.w, hr45.x, (r)(last)hr20.x
ldl.u16 r44.y, l[r20.z+2240], 4
(rpt1)mad.f16 hr18.z, (r)hr42.y, hr0.z, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr42.w, hr0.z, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr45.y, hr0.z, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr45.w, hr0.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr42.y, hr0.w, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr42.w, hr0.w, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr45.y, hr0.w, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr45.w, hr0.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr42.y, hr1.x, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr42.w, hr1.x, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr45.y, hr1.x, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr45.w, hr1.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr42.y, hr1.y, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr42.w, hr1.y, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr45.y, hr1.y, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr45.w, hr1.y, (r)(last)hr12.x
ldl.u16 r0.z, l[r20.z+2304], 4
(rpt1)mad.f16 hr10.z, (r)hr42.y, hr3.z, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr42.w, hr3.z, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr45.y, hr3.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr45.w, hr3.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr42.y, hr3.w, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr42.w, hr3.w, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr45.y, hr3.w, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr45.w, hr3.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr42.y, hr4.x, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr42.w, hr4.x, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr45.y, hr4.x, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr45.w, hr4.x, (r)(last)hr6.x
(rpt1)mad.f16 hr42.y, (r)(last)hr42.y, hr4.y, (r)(last)hr46.y
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr4.y, (r)(last)hr46.w
isam.v.base0 (u16)(xyzw)hr46.y, r26.w, s#0, t#2
(rpt1)mad.f16 hr45.y, (r)(last)hr45.y, hr4.y, (r)(last)hr35.w
(rpt1)mad.f16 hr45.w, (r)(last)hr45.w, hr4.y, (r)(last)hr36.y
isam.v.base0 (u16)(xyzw)hr35.w, r27.x, s#0, t#2
ldl.u16 r3.z, l[r20.z+2368], 4
(sy)(ss)(rpt1)mad.f16 hr34.z, (r)hr36.w, hr37.w, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr37.y, hr37.w, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr36.w, hr38.x, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr37.y, hr38.x, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr36.w, hr38.y, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr37.y, hr38.y, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr36.w, hr38.z, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr37.y, hr38.z, (r)(last)hr29.x
mad.f16 hr33.z, hr39.w, hr37.w, (last)hr33.z
mad.f16 hr31.z, hr39.w, hr38.x, (last)hr31.z
mad.f16 hr29.z, hr39.w, hr38.y, (last)hr29.z
mad.f16 hr27.z, hr39.w, hr38.z, (last)hr27.z
mad.f16 hr33.w, hr40.x, hr37.w, (last)hr33.w
mad.f16 hr31.w, hr40.x, hr38.x, (last)hr31.w
mad.f16 hr29.w, hr40.x, hr38.y, (last)hr29.w
mad.f16 hr27.w, hr40.x, hr38.z, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr40.y, hr37.w, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr40.y, hr38.x, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr40.y, hr38.y, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr40.y, hr38.z, (r)(last)hr28.x
ldl.u16 r37.w, l[r20.z+2432], 4
(rpt1)mad.f16 hr26.z, (r)hr36.w, hr38.w, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr37.y, hr38.w, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr36.w, hr39.x, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr37.y, hr39.x, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr36.w, hr39.y, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr37.y, hr39.y, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr36.w, hr39.z, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr37.y, hr39.z, (r)(last)hr21.x
mad.f16 hr25.z, hr39.w, hr38.w, (last)hr25.z
mad.f16 hr23.z, hr39.w, hr39.x, (last)hr23.z
mad.f16 hr21.z, hr39.w, hr39.y, (last)hr21.z
mad.f16 hr19.z, hr39.w, hr39.z, (last)hr19.z
mad.f16 hr25.w, hr40.x, hr38.w, (last)hr25.w
mad.f16 hr23.w, hr40.x, hr39.x, (last)hr23.w
mad.f16 hr21.w, hr40.x, hr39.y, (last)hr21.w
mad.f16 hr19.w, hr40.x, hr39.z, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr40.y, hr38.w, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr40.y, hr39.x, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr40.y, hr39.y, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr40.y, hr39.z, (r)(last)hr20.x
ldl.u16 r38.w, l[r20.z+2496], 4
(rpt1)mad.f16 hr18.z, (r)hr36.w, hr43.y, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr37.y, hr43.y, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr39.w, hr43.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr40.y, hr43.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr36.w, hr43.z, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr37.y, hr43.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr39.w, hr43.z, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr40.y, hr43.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr36.w, hr43.w, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr37.y, hr43.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr39.w, hr43.w, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr40.y, hr43.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr36.w, hr44.x, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr37.y, hr44.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr39.w, hr44.x, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr40.y, hr44.x, (r)(last)hr12.x
ldl.u16 r43.y, l[r20.z+2560], 4
(rpt1)mad.f16 hr10.z, (r)hr36.w, hr44.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr37.y, hr44.y, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr39.w, hr44.y, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr40.y, hr44.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr36.w, hr44.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr37.y, hr44.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr39.w, hr44.z, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr40.y, hr44.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr36.w, hr44.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr37.y, hr44.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr39.w, hr44.w, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr40.y, hr44.w, (r)(last)hr6.x
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr45.x, (r)(last)hr42.y
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr45.x, (r)(last)hr42.w
isam.v.base0 (u16)(xyzw)hr42.y, r27.y, s#0, t#2
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr45.x, (r)(last)hr45.y
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr45.x, (r)(last)hr45.w
isam.v.base0 (u16)(xyzw)hr45.y, r27.z, s#0, t#2
ldl.u16 r44.y, l[r20.z+2624], 4
(rpt1)mad.f16 hr34.z, (r)hr46.y, hr0.z, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr46.w, hr0.z, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr46.y, hr0.w, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr46.w, hr0.w, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr46.y, hr1.x, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr46.w, hr1.x, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr46.y, hr1.y, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr46.w, hr1.y, (r)(last)hr29.x
mad.f16 hr33.z, hr35.w, hr0.z, (last)hr33.z
mad.f16 hr31.z, hr35.w, hr0.w, (last)hr31.z
mad.f16 hr29.z, hr35.w, hr1.x, (last)hr29.z
mad.f16 hr27.z, hr35.w, hr1.y, (last)hr27.z
mad.f16 hr33.w, hr36.x, hr0.z, (last)hr33.w
mad.f16 hr31.w, hr36.x, hr0.w, (last)hr31.w
mad.f16 hr29.w, hr36.x, hr1.x, (last)hr29.w
mad.f16 hr27.w, hr36.x, hr1.y, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr36.y, hr0.z, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr36.y, hr0.w, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr36.y, hr1.x, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr36.y, hr1.y, (r)(last)hr28.x
ldl.u16 r0.z, l[r20.z+2688], 4
(rpt1)mad.f16 hr26.z, (r)hr46.y, hr3.z, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr46.w, hr3.z, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr46.y, hr3.w, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr46.w, hr3.w, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr46.y, hr4.x, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr46.w, hr4.x, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr46.y, hr4.y, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr46.w, hr4.y, (r)(last)hr21.x
mad.f16 hr25.z, hr35.w, hr3.z, (last)hr25.z
mad.f16 hr23.z, hr35.w, hr3.w, (last)hr23.z
mad.f16 hr21.z, hr35.w, hr4.x, (last)hr21.z
mad.f16 hr19.z, hr35.w, hr4.y, (last)hr19.z
mad.f16 hr25.w, hr36.x, hr3.z, (last)hr25.w
mad.f16 hr23.w, hr36.x, hr3.w, (last)hr23.w
mad.f16 hr21.w, hr36.x, hr4.x, (last)hr21.w
mad.f16 hr19.w, hr36.x, hr4.y, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr36.y, hr3.z, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr36.y, hr3.w, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr36.y, hr4.x, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr36.y, hr4.y, (r)(last)hr20.x
ldl.u16 r3.z, l[r20.z+2752], 4
(ss)(rpt1)mad.f16 hr18.z, (r)hr46.y, hr37.w, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr46.w, hr37.w, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr35.w, hr37.w, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr36.y, hr37.w, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr46.y, hr38.x, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr46.w, hr38.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr35.w, hr38.x, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr36.y, hr38.x, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr46.y, hr38.y, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr46.w, hr38.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr35.w, hr38.y, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr36.y, hr38.y, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr46.y, hr38.z, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr46.w, hr38.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr35.w, hr38.z, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr36.y, hr38.z, (r)(last)hr12.x
ldl.u16 r37.w, l[r20.z+2816], 4
(rpt1)mad.f16 hr10.z, (r)hr46.y, hr38.w, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr46.w, hr38.w, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr35.w, hr38.w, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr36.y, hr38.w, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr46.y, hr39.x, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr46.w, hr39.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr35.w, hr39.x, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr36.y, hr39.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr46.y, hr39.y, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr46.w, hr39.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr35.w, hr39.y, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr36.y, hr39.y, (r)(last)hr6.x
(rpt1)mad.f16 hr46.y, (r)(last)hr46.y, hr39.z, (r)(last)hr36.w
(rpt1)mad.f16 hr46.w, (r)(last)hr46.w, hr39.z, (r)(last)hr37.y
isam.v.base0 (u16)(xyzw)hr36.w, r27.w, s#0, t#2
(rpt1)mad.f16 hr35.w, (r)(last)hr35.w, hr39.z, (r)(last)hr39.w
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr39.z, (r)(last)hr40.y
isam.v.base0 (u16)(xyzw)hr39.w, r28.x, s#0, t#2
ldl.u16 r38.w, l[r20.z+2880], 4
(sy)(rpt1)mad.f16 hr34.z, (r)hr42.y, hr43.y, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr42.w, hr43.y, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr42.y, hr43.z, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr42.w, hr43.z, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr42.y, hr43.w, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr42.w, hr43.w, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr42.y, hr44.x, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr42.w, hr44.x, (r)(last)hr29.x
mad.f16 hr33.z, hr45.y, hr43.y, (last)hr33.z
mad.f16 hr31.z, hr45.y, hr43.z, (last)hr31.z
mad.f16 hr29.z, hr45.y, hr43.w, (last)hr29.z
mad.f16 hr27.z, hr45.y, hr44.x, (last)hr27.z
mad.f16 hr33.w, hr45.z, hr43.y, (last)hr33.w
mad.f16 hr31.w, hr45.z, hr43.z, (last)hr31.w
mad.f16 hr29.w, hr45.z, hr43.w, (last)hr29.w
mad.f16 hr27.w, hr45.z, hr44.x, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr45.w, hr43.y, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr45.w, hr43.z, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr45.w, hr43.w, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr45.w, hr44.x, (r)(last)hr28.x
ldl.u16 r43.y, l[r20.z+2944], 4
(rpt1)mad.f16 hr26.z, (r)hr42.y, hr44.y, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr42.w, hr44.y, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr42.y, hr44.z, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr42.w, hr44.z, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr42.y, hr44.w, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr42.w, hr44.w, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr42.y, hr45.x, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr42.w, hr45.x, (r)(last)hr21.x
mad.f16 hr25.z, hr45.y, hr44.y, (last)hr25.z
mad.f16 hr23.z, hr45.y, hr44.z, (last)hr23.z
mad.f16 hr21.z, hr45.y, hr44.w, (last)hr21.z
mad.f16 hr19.z, hr45.y, hr45.x, (last)hr19.z
mad.f16 hr25.w, hr45.z, hr44.y, (last)hr25.w
mad.f16 hr23.w, hr45.z, hr44.z, (last)hr23.w
mad.f16 hr21.w, hr45.z, hr44.w, (last)hr21.w
mad.f16 hr19.w, hr45.z, hr45.x, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr45.w, hr44.y, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr45.w, hr44.z, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr45.w, hr44.w, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr45.w, hr45.x, (r)(last)hr20.x
ldl.u16 r44.y, l[r20.z+3008], 4
(rpt1)mad.f16 hr18.z, (r)hr42.y, hr0.z, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr42.w, hr0.z, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr45.y, hr0.z, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr45.w, hr0.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr42.y, hr0.w, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr42.w, hr0.w, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr45.y, hr0.w, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr45.w, hr0.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr42.y, hr1.x, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr42.w, hr1.x, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr45.y, hr1.x, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr45.w, hr1.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr42.y, hr1.y, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr42.w, hr1.y, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr45.y, hr1.y, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr45.w, hr1.y, (r)(last)hr12.x
ldl.u16 r0.z, l[r20.z+3072], 4
(rpt1)mad.f16 hr10.z, (r)hr42.y, hr3.z, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr42.w, hr3.z, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr45.y, hr3.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr45.w, hr3.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr42.y, hr3.w, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr42.w, hr3.w, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr45.y, hr3.w, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr45.w, hr3.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr42.y, hr4.x, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr42.w, hr4.x, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr45.y, hr4.x, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr45.w, hr4.x, (r)(last)hr6.x
(rpt1)mad.f16 hr42.y, (r)(last)hr42.y, hr4.y, (r)(last)hr46.y
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr4.y, (r)(last)hr46.w
isam.v.base0 (u16)(xyzw)hr46.y, r28.y, s#0, t#2
(rpt1)mad.f16 hr45.y, (r)(last)hr45.y, hr4.y, (r)(last)hr35.w
(rpt1)mad.f16 hr45.w, (r)(last)hr45.w, hr4.y, (r)(last)hr36.y
isam.v.base0 (u16)(xyzw)hr35.w, r28.z, s#0, t#2
ldl.u16 r3.z, l[r20.z+3136], 4
(ss)(rpt1)mad.f16 hr34.z, (r)hr36.w, hr37.w, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr37.y, hr37.w, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr36.w, hr38.x, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr37.y, hr38.x, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr36.w, hr38.y, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr37.y, hr38.y, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr36.w, hr38.z, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr37.y, hr38.z, (r)(last)hr29.x
mad.f16 hr33.z, hr39.w, hr37.w, (last)hr33.z
mad.f16 hr31.z, hr39.w, hr38.x, (last)hr31.z
mad.f16 hr29.z, hr39.w, hr38.y, (last)hr29.z
mad.f16 hr27.z, hr39.w, hr38.z, (last)hr27.z
mad.f16 hr33.w, hr40.x, hr37.w, (last)hr33.w
mad.f16 hr31.w, hr40.x, hr38.x, (last)hr31.w
mad.f16 hr29.w, hr40.x, hr38.y, (last)hr29.w
mad.f16 hr27.w, hr40.x, hr38.z, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr40.y, hr37.w, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr40.y, hr38.x, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr40.y, hr38.y, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr40.y, hr38.z, (r)(last)hr28.x
ldl.u16 r37.w, l[r20.z+3200], 4
(rpt1)mad.f16 hr26.z, (r)hr36.w, hr38.w, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr37.y, hr38.w, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr36.w, hr39.x, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr37.y, hr39.x, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr36.w, hr39.y, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr37.y, hr39.y, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr36.w, hr39.z, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr37.y, hr39.z, (r)(last)hr21.x
mad.f16 hr25.z, hr39.w, hr38.w, (last)hr25.z
mad.f16 hr23.z, hr39.w, hr39.x, (last)hr23.z
mad.f16 hr21.z, hr39.w, hr39.y, (last)hr21.z
mad.f16 hr19.z, hr39.w, hr39.z, (last)hr19.z
mad.f16 hr25.w, hr40.x, hr38.w, (last)hr25.w
mad.f16 hr23.w, hr40.x, hr39.x, (last)hr23.w
mad.f16 hr21.w, hr40.x, hr39.y, (last)hr21.w
mad.f16 hr19.w, hr40.x, hr39.z, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr40.y, hr38.w, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr40.y, hr39.x, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr40.y, hr39.y, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr40.y, hr39.z, (r)(last)hr20.x
ldl.u16 r38.w, l[r20.z+3264], 4
(rpt1)mad.f16 hr18.z, (r)hr36.w, hr43.y, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr37.y, hr43.y, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr39.w, hr43.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr40.y, hr43.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr36.w, hr43.z, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr37.y, hr43.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr39.w, hr43.z, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr40.y, hr43.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr36.w, hr43.w, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr37.y, hr43.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr39.w, hr43.w, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr40.y, hr43.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr36.w, hr44.x, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr37.y, hr44.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr39.w, hr44.x, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr40.y, hr44.x, (r)(last)hr12.x
ldl.u16 r43.y, l[r20.z+3328], 4
(rpt1)mad.f16 hr10.z, (r)hr36.w, hr44.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr37.y, hr44.y, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr39.w, hr44.y, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr40.y, hr44.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr36.w, hr44.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr37.y, hr44.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr39.w, hr44.z, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr40.y, hr44.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr36.w, hr44.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr37.y, hr44.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr39.w, hr44.w, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr40.y, hr44.w, (r)(last)hr6.x
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr45.x, (r)(last)hr42.y
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr45.x, (r)(last)hr42.w
isam.v.base0 (u16)(xyzw)hr42.y, r28.w, s#0, t#2
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr45.x, (r)(last)hr45.y
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr45.x, (r)(last)hr45.w
isam.v.base0 (u16)(xyzw)hr45.y, r29.x, s#0, t#2
ldl.u16 r44.y, l[r20.z+3392], 4
(sy)(rpt1)mad.f16 hr34.z, (r)hr46.y, hr0.z, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr46.w, hr0.z, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr46.y, hr0.w, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr46.w, hr0.w, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr46.y, hr1.x, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr46.w, hr1.x, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr46.y, hr1.y, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr46.w, hr1.y, (r)(last)hr29.x
mad.f16 hr33.z, hr35.w, hr0.z, (last)hr33.z
mad.f16 hr31.z, hr35.w, hr0.w, (last)hr31.z
mad.f16 hr29.z, hr35.w, hr1.x, (last)hr29.z
mad.f16 hr27.z, hr35.w, hr1.y, (last)hr27.z
mad.f16 hr33.w, hr36.x, hr0.z, (last)hr33.w
mad.f16 hr31.w, hr36.x, hr0.w, (last)hr31.w
mad.f16 hr29.w, hr36.x, hr1.x, (last)hr29.w
mad.f16 hr27.w, hr36.x, hr1.y, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr36.y, hr0.z, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr36.y, hr0.w, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr36.y, hr1.x, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr36.y, hr1.y, (r)(last)hr28.x
ldl.u16 r0.z, l[r20.z+3456], 4
(rpt1)mad.f16 hr26.z, (r)hr46.y, hr3.z, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr46.w, hr3.z, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr46.y, hr3.w, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr46.w, hr3.w, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr46.y, hr4.x, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr46.w, hr4.x, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr46.y, hr4.y, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr46.w, hr4.y, (r)(last)hr21.x
mad.f16 hr25.z, hr35.w, hr3.z, (last)hr25.z
mad.f16 hr23.z, hr35.w, hr3.w, (last)hr23.z
mad.f16 hr21.z, hr35.w, hr4.x, (last)hr21.z
mad.f16 hr19.z, hr35.w, hr4.y, (last)hr19.z
mad.f16 hr25.w, hr36.x, hr3.z, (last)hr25.w
mad.f16 hr23.w, hr36.x, hr3.w, (last)hr23.w
mad.f16 hr21.w, hr36.x, hr4.x, (last)hr21.w
mad.f16 hr19.w, hr36.x, hr4.y, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr36.y, hr3.z, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr36.y, hr3.w, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr36.y, hr4.x, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr36.y, hr4.y, (r)(last)hr20.x
ldl.u16 r3.z, l[r20.z+3520], 4
(ss)(rpt1)mad.f16 hr18.z, (r)hr46.y, hr37.w, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr46.w, hr37.w, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr35.w, hr37.w, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr36.y, hr37.w, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr46.y, hr38.x, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr46.w, hr38.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr35.w, hr38.x, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr36.y, hr38.x, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr46.y, hr38.y, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr46.w, hr38.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr35.w, hr38.y, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr36.y, hr38.y, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr46.y, hr38.z, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr46.w, hr38.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr35.w, hr38.z, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr36.y, hr38.z, (r)(last)hr12.x
ldl.u16 r37.w, l[r20.z+3584], 4
(rpt1)mad.f16 hr10.z, (r)hr46.y, hr38.w, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr46.w, hr38.w, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr35.w, hr38.w, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr36.y, hr38.w, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr46.y, hr39.x, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr46.w, hr39.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr35.w, hr39.x, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr36.y, hr39.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr46.y, hr39.y, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr46.w, hr39.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr35.w, hr39.y, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr36.y, hr39.y, (r)(last)hr6.x
(rpt1)mad.f16 hr46.y, (r)(last)hr46.y, hr39.z, (r)(last)hr36.w
(rpt1)mad.f16 hr46.w, (r)(last)hr46.w, hr39.z, (r)(last)hr37.y
isam.v.base0 (u16)(xyzw)hr36.w, r29.y, s#0, t#2
(rpt1)mad.f16 hr35.w, (r)(last)hr35.w, hr39.z, (r)(last)hr39.w
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr39.z, (r)(last)hr40.y
isam.v.base0 (u16)(xyzw)hr39.w, r29.z, s#0, t#2
ldl.u16 r38.w, l[r20.z+3648], 4
(rpt1)mad.f16 hr34.z, (r)hr42.y, hr43.y, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr42.w, hr43.y, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr42.y, hr43.z, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr42.w, hr43.z, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr42.y, hr43.w, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr42.w, hr43.w, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr42.y, hr44.x, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr42.w, hr44.x, (r)(last)hr29.x
mad.f16 hr33.z, hr45.y, hr43.y, (last)hr33.z
mad.f16 hr31.z, hr45.y, hr43.z, (last)hr31.z
mad.f16 hr29.z, hr45.y, hr43.w, (last)hr29.z
mad.f16 hr27.z, hr45.y, hr44.x, (last)hr27.z
mad.f16 hr33.w, hr45.z, hr43.y, (last)hr33.w
mad.f16 hr31.w, hr45.z, hr43.z, (last)hr31.w
mad.f16 hr29.w, hr45.z, hr43.w, (last)hr29.w
mad.f16 hr27.w, hr45.z, hr44.x, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr45.w, hr43.y, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr45.w, hr43.z, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr45.w, hr43.w, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr45.w, hr44.x, (r)(last)hr28.x
ldl.u16 r43.y, l[r20.z+3712], 4
(rpt1)mad.f16 hr26.z, (r)hr42.y, hr44.y, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr42.w, hr44.y, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr42.y, hr44.z, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr42.w, hr44.z, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr42.y, hr44.w, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr42.w, hr44.w, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr42.y, hr45.x, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr42.w, hr45.x, (r)(last)hr21.x
mad.f16 hr25.z, hr45.y, hr44.y, (last)hr25.z
mad.f16 hr23.z, hr45.y, hr44.z, (last)hr23.z
mad.f16 hr21.z, hr45.y, hr44.w, (last)hr21.z
mad.f16 hr19.z, hr45.y, hr45.x, (last)hr19.z
mad.f16 hr25.w, hr45.z, hr44.y, (last)hr25.w
mad.f16 hr23.w, hr45.z, hr44.z, (last)hr23.w
mad.f16 hr21.w, hr45.z, hr44.w, (last)hr21.w
mad.f16 hr19.w, hr45.z, hr45.x, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr45.w, hr44.y, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr45.w, hr44.z, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr45.w, hr44.w, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr45.w, hr45.x, (r)(last)hr20.x
ldl.u16 r44.y, l[r20.z+3776], 4
(rpt1)mad.f16 hr18.z, (r)hr42.y, hr0.z, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr42.w, hr0.z, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr45.y, hr0.z, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr45.w, hr0.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr42.y, hr0.w, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr42.w, hr0.w, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr45.y, hr0.w, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr45.w, hr0.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr42.y, hr1.x, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr42.w, hr1.x, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr45.y, hr1.x, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr45.w, hr1.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr42.y, hr1.y, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr42.w, hr1.y, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr45.y, hr1.y, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr45.w, hr1.y, (r)(last)hr12.x
ldl.u16 r0.z, l[r20.z+3840], 4
(rpt1)mad.f16 hr10.z, (r)hr42.y, hr3.z, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr42.w, hr3.z, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr45.y, hr3.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr45.w, hr3.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr42.y, hr3.w, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr42.w, hr3.w, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr45.y, hr3.w, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr45.w, hr3.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr42.y, hr4.x, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr42.w, hr4.x, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr45.y, hr4.x, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr45.w, hr4.x, (r)(last)hr6.x
(rpt1)mad.f16 hr42.y, (r)(last)hr42.y, hr4.y, (r)(last)hr46.y
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr4.y, (r)(last)hr46.w
isam.v.base0 (u16)(xyzw)hr46.y, r29.w, s#0, t#2
(rpt1)mad.f16 hr45.y, (r)(last)hr45.y, hr4.y, (r)(last)hr35.w
(rpt1)mad.f16 hr45.w, (r)(last)hr45.w, hr4.y, (r)(last)hr36.y
isam.v.base0 (u16)(xyzw)hr35.w, r30.x, s#0, t#2
ldl.u16 r3.z, l[r20.z+3904], 4
(sy)(ss)(rpt1)mad.f16 hr34.z, (r)hr36.w, hr37.w, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr37.y, hr37.w, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr36.w, hr38.x, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr37.y, hr38.x, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr36.w, hr38.y, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr37.y, hr38.y, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr36.w, hr38.z, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr37.y, hr38.z, (r)(last)hr29.x
mad.f16 hr33.z, hr39.w, hr37.w, (last)hr33.z
mad.f16 hr31.z, hr39.w, hr38.x, (last)hr31.z
mad.f16 hr29.z, hr39.w, hr38.y, (last)hr29.z
mad.f16 hr27.z, hr39.w, hr38.z, (last)hr27.z
mad.f16 hr33.w, hr40.x, hr37.w, (last)hr33.w
mad.f16 hr31.w, hr40.x, hr38.x, (last)hr31.w
mad.f16 hr29.w, hr40.x, hr38.y, (last)hr29.w
mad.f16 hr27.w, hr40.x, hr38.z, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr40.y, hr37.w, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr40.y, hr38.x, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr40.y, hr38.y, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr40.y, hr38.z, (r)(last)hr28.x
ldl.u16 r37.w, l[r20.z+3968], 4
(rpt1)mad.f16 hr26.z, (r)hr36.w, hr38.w, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr37.y, hr38.w, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr36.w, hr39.x, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr37.y, hr39.x, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr36.w, hr39.y, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr37.y, hr39.y, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr36.w, hr39.z, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr37.y, hr39.z, (r)(last)hr21.x
mad.f16 hr25.z, hr39.w, hr38.w, (last)hr25.z
mad.f16 hr23.z, hr39.w, hr39.x, (last)hr23.z
mad.f16 hr21.z, hr39.w, hr39.y, (last)hr21.z
mad.f16 hr19.z, hr39.w, hr39.z, (last)hr19.z
mad.f16 hr25.w, hr40.x, hr38.w, (last)hr25.w
mad.f16 hr23.w, hr40.x, hr39.x, (last)hr23.w
mad.f16 hr21.w, hr40.x, hr39.y, (last)hr21.w
mad.f16 hr19.w, hr40.x, hr39.z, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr40.y, hr38.w, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr40.y, hr39.x, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr40.y, hr39.y, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr40.y, hr39.z, (r)(last)hr20.x
ldl.u16 r38.w, l[r20.z+4032], 4
(rpt1)mad.f16 hr18.z, (r)hr36.w, hr43.y, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr37.y, hr43.y, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr39.w, hr43.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr40.y, hr43.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr36.w, hr43.z, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr37.y, hr43.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr39.w, hr43.z, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr40.y, hr43.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr36.w, hr43.w, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr37.y, hr43.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr39.w, hr43.w, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr40.y, hr43.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr36.w, hr44.x, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr37.y, hr44.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr39.w, hr44.x, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr40.y, hr44.x, (r)(last)hr12.x
(rpt1)mad.f16 hr10.z, (r)hr36.w, hr44.y, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr37.y, hr44.y, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr39.w, hr44.y, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr40.y, hr44.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr36.w, hr44.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr37.y, hr44.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr39.w, hr44.z, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr40.y, hr44.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr36.w, hr44.w, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr37.y, hr44.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr39.w, hr44.w, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr40.y, hr44.w, (r)(last)hr6.x
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr45.x, (r)(last)hr42.y
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr45.x, (r)(last)hr42.w
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr45.x, (r)(last)hr45.y
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr45.x, (r)(last)hr45.w
(rpt1)mad.f16 hr34.z, (r)hr46.y, hr0.z, (r)(last)hr34.z
(rpt1)mad.f16 hr35.x, (r)hr46.w, hr0.z, (r)(last)hr35.x
(rpt1)mad.f16 hr32.z, (r)hr46.y, hr0.w, (r)(last)hr32.z
(rpt1)mad.f16 hr33.x, (r)hr46.w, hr0.w, (r)(last)hr33.x
(rpt1)mad.f16 hr30.z, (r)hr46.y, hr1.x, (r)(last)hr30.z
(rpt1)mad.f16 hr31.x, (r)hr46.w, hr1.x, (r)(last)hr31.x
(rpt1)mad.f16 hr28.z, (r)hr46.y, hr1.y, (r)(last)hr28.z
(rpt1)mad.f16 hr29.x, (r)hr46.w, hr1.y, (r)(last)hr29.x
mad.f16 hr33.z, hr35.w, hr0.z, (last)hr33.z
mad.f16 hr31.z, hr35.w, hr0.w, (last)hr31.z
mad.f16 hr29.z, hr35.w, hr1.x, (last)hr29.z
mad.f16 hr27.z, hr35.w, hr1.y, (last)hr27.z
mad.f16 hr33.w, hr36.x, hr0.z, (last)hr33.w
mad.f16 hr31.w, hr36.x, hr0.w, (last)hr31.w
mad.f16 hr29.w, hr36.x, hr1.x, (last)hr29.w
mad.f16 hr27.w, hr36.x, hr1.y, (last)hr27.w
(rpt1)mad.f16 hr34.x, (r)hr36.y, hr0.z, (r)(last)hr34.x
(rpt1)mad.f16 hr32.x, (r)hr36.y, hr0.w, (r)(last)hr32.x
(rpt1)mad.f16 hr30.x, (r)hr36.y, hr1.x, (r)(last)hr30.x
(rpt1)mad.f16 hr28.x, (r)hr36.y, hr1.y, (r)(last)hr28.x
(rpt1)mad.f16 hr26.z, (r)hr46.y, hr3.z, (r)(last)hr26.z
(rpt1)mad.f16 hr27.x, (r)hr46.w, hr3.z, (r)(last)hr27.x
(rpt1)mad.f16 hr24.z, (r)hr46.y, hr3.w, (r)(last)hr24.z
(rpt1)mad.f16 hr25.x, (r)hr46.w, hr3.w, (r)(last)hr25.x
(rpt1)mad.f16 hr22.z, (r)hr46.y, hr4.x, (r)(last)hr22.z
(rpt1)mad.f16 hr23.x, (r)hr46.w, hr4.x, (r)(last)hr23.x
(rpt1)mad.f16 hr20.z, (r)hr46.y, hr4.y, (r)(last)hr20.z
(rpt1)mad.f16 hr21.x, (r)hr46.w, hr4.y, (r)(last)hr21.x
mad.f16 hr25.z, hr35.w, hr3.z, (last)hr25.z
mad.f16 hr23.z, hr35.w, hr3.w, (last)hr23.z
mad.f16 hr21.z, hr35.w, hr4.x, (last)hr21.z
mad.f16 hr19.z, hr35.w, hr4.y, (last)hr19.z
mad.f16 hr25.w, hr36.x, hr3.z, (last)hr25.w
mad.f16 hr23.w, hr36.x, hr3.w, (last)hr23.w
mad.f16 hr21.w, hr36.x, hr4.x, (last)hr21.w
mad.f16 hr19.w, hr36.x, hr4.y, (last)hr19.w
(rpt1)mad.f16 hr26.x, (r)hr36.y, hr3.z, (r)(last)hr26.x
(rpt1)mad.f16 hr24.x, (r)hr36.y, hr3.w, (r)(last)hr24.x
(rpt1)mad.f16 hr22.x, (r)hr36.y, hr4.x, (r)(last)hr22.x
(rpt1)mad.f16 hr20.x, (r)hr36.y, hr4.y, (r)(last)hr20.x
fence.r.w
(sy)(ss)(rpt1)mad.f16 hr18.z, (r)hr46.y, hr37.w, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr46.w, hr37.w, (r)(last)hr19.x
(rpt1)mad.f16 hr17.z, (r)hr35.w, hr37.w, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr36.y, hr37.w, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr46.y, hr38.x, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr46.w, hr38.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.z, (r)hr35.w, hr38.x, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr36.y, hr38.x, (r)(last)hr16.x
(rpt1)mad.f16 hr14.z, (r)hr46.y, hr38.y, (r)(last)hr14.z
(rpt1)mad.f16 hr15.x, (r)hr46.w, hr38.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.z, (r)hr35.w, hr38.y, (r)(last)hr13.z
(rpt1)mad.f16 hr14.x, (r)hr36.y, hr38.y, (r)(last)hr14.x
(rpt1)mad.f16 hr12.z, (r)hr46.y, hr38.z, (r)(last)hr12.z
(rpt1)mad.f16 hr13.x, (r)hr46.w, hr38.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.z, (r)hr35.w, hr38.z, (r)(last)hr11.z
(rpt1)mad.f16 hr12.x, (r)hr36.y, hr38.z, (r)(last)hr12.x
(rpt1)mad.f16 hr10.z, (r)hr46.y, hr38.w, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr46.w, hr38.w, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr35.w, hr38.w, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr36.y, hr38.w, (r)(last)hr10.x
(rpt1)mad.f16 hr8.z, (r)hr46.y, hr39.x, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr46.w, hr39.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.z, (r)hr35.w, hr39.x, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr36.y, hr39.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.z, (r)hr46.y, hr39.y, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr46.w, hr39.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.z, (r)hr35.w, hr39.y, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr36.y, hr39.y, (r)(last)hr6.x
(rpt1)mad.f16 hr4.z, (r)(last)hr46.y, hr39.z, (r)(last)hr36.w
(rpt1)mad.f16 hr5.x, (r)(last)hr46.w, hr39.z, (r)(last)hr37.y
(rpt1)mad.f16 hr3.z, (r)(last)hr35.w, hr39.z, (r)(last)hr39.w
(rpt1)mad.f16 hr4.x, (r)(last)hr36.y, hr39.z, (r)(last)hr40.y
bar.g
(sy)(ss)br p0.x, #l1551
jump #l214
l1551:
(jp)(eolm)nop
(nop3) add.u r20.w, r48.z, (last)r20.w
(nop3) shl.b r20.w, (last)r20.w, 9
(nop3) sad.s32 r20.w, r49.z, r20.w, (last)r1.z
(nop3) shl.b r20.w, (last)r20.w, 2
add.u r21.x, r20.w, c1.x
add.u r21.y, r20.w, c8.y
add.u r21.z, r20.w, c4.z
stib.b.untyped.1d.u16.4.imm.base0 hr34.z, r20.w, 4
add.u r21.w, r20.w, c8.x
add.u r22.x, r20.w, c4.y
add.u r22.y, r20.w, c7.w
(rpt1)add.u r22.z, r20.w, (r)c8.z
(rpt3)add.u r23.x, r20.w, (r)c9.x
(rpt2)add.u r24.x, r20.w, (r)c10.x
(rpt1)add.u r24.w, (r)c10.w, r20.w
(rpt1)add.u r25.y, (r)c11.y, r20.w
(rpt1)add.u r25.w, (r)c11.w, r20.w
(rpt1)add.u r26.y, (r)c12.y, r20.w
(rpt1)add.u r26.w, (r)c12.w, r20.w
(rpt1)add.u r27.y, (r)c13.y, r20.w
(rpt1)add.u r27.w, (r)c13.w, r20.w
stib.b.untyped.1d.u16.4.imm.base0 hr33.z, r20.w+64, 4
(ss)add.u r20.w, c14.y, (last)r20.w
stib.b.untyped.1d.u16.4.imm.base0 hr32.z, r21.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr31.z, r21.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr30.z, r21.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr29.z, r21.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr28.z, r22.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr27.z, r22.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr26.z, r22.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr25.z, r22.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr24.z, r23.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr23.z, r23.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr22.z, r23.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr21.z, r23.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr20.z, r24.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr19.z, r24.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr18.z, r24.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r24.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r25.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r25.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r25.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r25.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r26.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r26.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r26.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r26.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r27.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r27.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r27.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r27.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r28.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r20.w, 4
end
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 2458 instr, 26 nops, 2432 non-nops, 129 mov, 0 cov, 3232 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 31 full, 16 constlen
; CL prog 23/1: 29 cat0, 129 cat1, 106 cat2, 2054 cat3, 0 cat4, 36 cat5, 100 cat6, 4 cat7
; CL prog 23/1: 110 sstall, 17 (ss), 265 systall, 13 (sy), 1 loops
; CL prog 23/1: 8 max_waves, 0 double_threadsize
; 78 preamble-instr, 1 early-preamble
