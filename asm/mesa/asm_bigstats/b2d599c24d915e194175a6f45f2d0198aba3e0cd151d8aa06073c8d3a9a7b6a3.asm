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
@const(c8.x)	0x00001020, 0x00000820, 0x00007840, 0x00007040
@const(c9.x)	0x00006840, 0x00006040, 0x00005840, 0x00005040
@const(c10.x)	0x00004840, 0x00004040, 0x00003840, 0x00003040
@const(c11.x)	0x00002840, 0x00002040, 0x00001840, 0x00001040
@const(c12.x)	0x00000840, 0x00007860, 0x00007060, 0x00006860
@const(c13.x)	0x00006060, 0x00005860, 0x00005060, 0x00004860
@const(c14.x)	0x00004060, 0x00003860, 0x00003060, 0x00002860
@const(c15.x)	0x00002060, 0x00001860, 0x00001060, 0x00000860
@const(c16.x)	0x00020000, 0x00020020, 0x00020040, 0x00020060
@const(c17.x)	0x00020800, 0x00020820, 0x00020840, 0x00020860
@const(c18.x)	0x00021000, 0x00021020, 0x00021040, 0x00021060
@const(c19.x)	0x00021800, 0x00021820, 0x00021840, 0x00021860
shps #l106
getone #l106
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
mov.u32u32 r49.y, 0x7840
mov.u32u32 r49.z, 0x7040
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 4
stc.u32 c[20], r52.w, 4
stc.u32 c[24], r53.w, 4
stc.u32 c[28], r54.w, 4
(ss)mov.u32u32 r49.w, 0x6840
mov.u32u32 r50.x, 0x6040
mov.u32u32 r50.y, 0x5840
mov.u32u32 r50.z, 0x5040
mov.u32u32 r50.w, 0x4840
mov.u32u32 r51.x, 0x4040
mov.u32u32 r51.y, 0x3840
mov.u32u32 r51.z, 0x3040
mov.u32u32 r51.w, 0x2840
mov.u32u32 r52.x, 0x2040
mov.u32u32 r52.y, 0x1840
mov.u32u32 r52.z, 0x1040
mov.u32u32 r52.w, 2112
mov.u32u32 r53.x, 0x7860
mov.u32u32 r53.y, 0x7060
mov.u32u32 r53.z, 0x6860
mov.u32u32 r53.w, 0x6060
mov.u32u32 r54.x, 0x5860
mov.u32u32 r54.y, 0x5060
mov.u32u32 r54.z, 0x4860
mov.u32u32 r54.w, 0x4060
mov.u32u32 r55.x, 0x3860
mov.u32u32 r55.y, 0x3060
mov.u32u32 r55.z, 0x2860
stc.u32 c[32], r48.w, 4
(ss)nop
stc.u32 c[36], r49.w, 4
mov.u32u32 r48.w, 0x2060
mov.u32u32 r49.x, 0x1860
mov.u32u32 r49.y, 0x1060
mov.u32u32 r49.z, 2144
stc.u32 c[40], r50.w, 4
stc.u32 c[44], r51.w, 4
stc.u32 c[48], r52.w, 4
stc.u32 c[52], r53.w, 4
stc.u32 c[56], r54.w, 4
(ss)mov.u32u32 r49.w, 0x20000
mov.u32u32 r50.x, 0x20020
mov.u32u32 r50.y, 0x20040
mov.u32u32 r50.z, 0x20060
mov.u32u32 r50.w, 0x20800
mov.u32u32 r51.x, 0x20820
mov.u32u32 r51.y, 0x20840
mov.u32u32 r51.z, 0x20860
mov.u32u32 r51.w, 0x21000
mov.u32u32 r52.x, 0x21020
mov.u32u32 r52.y, 0x21040
mov.u32u32 r52.z, 0x21060
mov.u32u32 r52.w, 0x21800
mov.u32u32 r53.x, 0x21820
mov.u32u32 r53.y, 0x21840
mov.u32u32 r53.z, 0x21860
stc.u32 c[60], r48.w, 4
(ss)nop
stc.u32 c[64], r49.w, 4
stc.u32 c[68], r50.w, 4
stc.u32 c[72], r51.w, 4
stc.u32 c[76], r52.w, 4
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l106:
(jp)(rpt1)add.u r53.w, (r)r48.x, (r)c0.x
mov.u32u32 r54.w, 0
shl.b r54.z, r53.w, 7
shl.b r54.y, r54.x, 7
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
l243:
(rpt1)shr.b r55.x, (r)r54.y, 2
shl.b r55.z, r54.w, 9
add.u r18.z, r0.x, 128
add.u r18.w, r0.x, 256
add.u r19.x, r0.x, 384
shl.b r18.x, r0.w, 8
(rpt2)shr.b r18.z, (last)(r)r18.z, 5
(ss)add.u r19.y, r54.w, r0.w
(rpt2)add.u r19.z, r54.w, (r)r18.z
add.u r54.w, r54.w, 16
cmps.u.ge up0.x, r54.w, c1.x
shl.b r19.y, (last)r19.y, 9
(rpt2)shl.b r19.z, (last)(r)r19.z, 9
sad.s32 r19.y, r55.x, r19.y, r1.x
(rpt2)sad.s32 r19.z, r55.x, (r)r19.z, r1.x
shl.b r19.y, (last)r19.y, 2
(rpt1)shl.b r19.z, (last)(r)r19.z, 2
shl.b r20.x, (last)r20.x, 2
shl.b r18.y, r1.x, 3
sad.s32 r22.x, r55.z, r1.w, r55.y
shl.b r18.z, (last)r18.z, 8
isam.v.base0 (u16)(xyzw)hr40.z, r19.y, s#0, t#0
shl.b r18.w, (last)r18.w, 8
isam.v.base0 (u16)(xyzw)hr42.x, r19.z, s#0, t#0
shl.b r19.x, (last)r19.x, 8
isam.v.base0 (u16)(xyzw)hr43.x, r19.w, s#0, t#0
add.u r18.x, (last)r18.x, r18.y
isam.v.base0 (u16)(xyzw)hr44.z, r20.x, s#0, t#0
shl.b r22.x, (last)r22.x, 2
(rpt2)add.u r18.z, (last)(r)r18.z, (last)r18.y
add.u r22.w, r22.x, c1.x
add.u r23.x, r22.x, c8.y
add.u r23.y, r22.x, c12.x
add.u r23.z, r22.x, c15.w
add.u r23.w, r22.x, c4.z
add.u r24.x, r22.x, c8.x
add.u r24.y, r22.x, c11.w
add.u r24.z, r22.x, c15.z
add.u r24.w, r22.x, c4.y
add.u r25.x, r22.x, c7.w
add.u r25.y, r22.x, c11.z
add.u r25.z, r22.x, c15.y
add.u r25.w, r22.x, c4.x
add.u r26.x, r22.x, c7.z
add.u r26.y, r22.x, c11.y
add.u r26.z, r22.x, c15.x
add.u r26.w, r22.x, c3.w
add.u r27.x, r22.x, c7.y
add.u r27.y, r22.x, c11.x
add.u r27.z, r22.x, c14.w
add.u r27.w, r22.x, c3.z
add.u r28.x, r22.x, c7.x
add.u r28.y, r22.x, c10.w
add.u r28.z, r22.x, c14.z
add.u r28.w, r22.x, c3.y
add.u r29.x, r22.x, c6.w
add.u r29.y, r22.x, c10.z
add.u r29.z, r22.x, c14.y
add.u r29.w, r22.x, c3.x
add.u r30.x, r22.x, c6.z
add.u r30.y, r22.x, c10.y
add.u r30.z, r22.x, c14.x
add.u r30.w, r22.x, c2.w
add.u r31.x, r22.x, c6.y
add.u r31.y, r22.x, c10.x
(sy)stl.u16 l[r18.x], r40.z, 4
stl.u16 l[r18.z], r42.x, 4
stl.u16 l[r18.w], r43.x, 4
stl.u16 l[r19.x], r44.z, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
isam.v.base0 (u16)(xyzw)hr36.y, r22.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr44.z, r22.x+32, s#0, t#2
ldl.u16 r0.z, l[r1.z], 4
ldl.u16 r42.x, l[r1.z+128], 4
ldl.u16 r43.x, l[r1.z+256], 4
add.u r31.z, r22.x, c13.w
add.u r31.w, r22.x, c2.z
add.u r32.x, r22.x, c6.x
add.u r32.y, r22.x, c9.w
add.u r32.z, r22.x, c13.z
add.u r19.y, r22.x, c9.z
add.u r19.z, r22.x, c13.y
add.u r19.w, r22.x, c2.x
add.u r20.x, r22.x, c5.z
add.u r32.w, r22.x, c1.w
add.u r33.x, r22.x, c5.y
add.u r33.y, r22.x, c9.x
add.u r33.z, r22.x, c12.w
add.u r33.w, r22.x, c1.z
add.u r34.x, r22.x, c5.x
add.u r34.y, r22.x, c8.w
add.u r34.z, r22.x, c12.z
add.u r34.w, r22.x, c1.y
add.u r35.x, r22.x, c4.w
add.u r35.y, r22.x, c8.z
add.u r35.z, r22.x, c12.y
add.u r20.y, r22.x, c9.y
add.u r20.z, r22.x, c13.x
add.u r18.w, r22.x, c2.y
add.u r19.x, r22.x, c5.w
mov.u32u32 r36.x, (last)r0.w
shl.b r20.w, r1.y, 2
mov.u32u32 r35.w, (last)r18.w
(sy)(ss)mad.f16 hr34.x, hr44.z, hr0.z, (last)hr34.x
mad.f16 hr30.x, hr44.z, hr0.w, (last)hr30.x
mad.f16 hr26.x, hr44.z, hr1.x, (last)hr26.x
mad.f16 hr22.x, hr44.z, hr1.y, (last)hr22.x
mad.f16 hr34.y, hr44.w, hr0.z, (last)hr34.y
mad.f16 hr30.y, hr44.w, hr0.w, (last)hr30.y
mad.f16 hr26.y, hr44.w, hr1.x, (last)hr26.y
mad.f16 hr22.y, hr44.w, hr1.y, (last)hr22.y
mad.f16 hr34.z, hr45.x, hr0.z, (last)hr34.z
mad.f16 hr30.z, hr45.x, hr0.w, (last)hr30.z
mad.f16 hr26.z, hr45.x, hr1.x, (last)hr26.z
mad.f16 hr22.z, hr45.x, hr1.y, (last)hr22.z
mad.f16 hr34.w, hr45.y, hr0.z, (last)hr34.w
mad.f16 hr30.w, hr45.y, hr0.w, (last)hr30.w
mad.f16 hr26.w, hr45.y, hr1.x, (last)hr26.w
mad.f16 hr22.w, hr45.y, hr1.y, (last)hr22.w
mad.f16 hr18.x, hr44.z, hr42.x, (last)hr18.x
mad.f16 hr14.x, hr44.z, hr42.y, (last)hr14.x
mad.f16 hr10.x, hr44.z, hr42.z, (last)hr10.x
mad.f16 hr18.y, hr44.w, hr42.x, (last)hr18.y
mad.f16 hr14.y, hr44.w, hr42.y, (last)hr14.y
mad.f16 hr10.y, hr44.w, hr42.z, (last)hr10.y
mad.f16 hr18.z, hr45.x, hr42.x, (last)hr18.z
mad.f16 hr14.z, hr45.x, hr42.y, (last)hr14.z
mad.f16 hr10.z, hr45.x, hr42.z, (last)hr10.z
mad.f16 hr18.w, hr45.y, hr42.x, (last)hr18.w
mad.f16 hr14.w, hr45.y, hr42.y, (last)hr14.w
mad.f16 hr10.w, hr45.y, hr42.z, (last)hr10.w
(rpt1)mad.f16 hr44.z, (r)(last)hr44.z, hr42.w, (r)(last)hr6.x
(rpt1)mad.f16 hr45.x, (r)(last)hr45.x, hr42.w, (r)(last)hr6.z
isam.v.base0 (u16)(xyzw)hr6.x, r22.x+64, s#0, t#2
mad.f16 hr35.x, hr36.y, hr0.z, (last)hr35.x
mad.f16 hr31.x, hr36.y, hr0.w, (last)hr31.x
mad.f16 hr27.x, hr36.y, hr1.x, (last)hr27.x
mad.f16 hr23.x, hr36.y, hr1.y, (last)hr23.x
mad.f16 hr35.y, hr36.z, hr0.z, (last)hr35.y
mad.f16 hr31.y, hr36.z, hr0.w, (last)hr31.y
mad.f16 hr27.y, hr36.z, hr1.x, (last)hr27.y
mad.f16 hr23.y, hr36.z, hr1.y, (last)hr23.y
mad.f16 hr35.z, hr36.w, hr0.z, (last)hr35.z
mad.f16 hr31.z, hr36.w, hr0.w, (last)hr31.z
mad.f16 hr27.z, hr36.w, hr1.x, (last)hr27.z
mad.f16 hr23.z, hr36.w, hr1.y, (last)hr23.z
mad.f16 hr35.w, hr37.x, hr0.z, (last)hr35.w
mad.f16 hr31.w, hr37.x, hr0.w, (last)hr31.w
mad.f16 hr27.w, hr37.x, hr1.x, (last)hr27.w
mad.f16 hr23.w, hr37.x, hr1.y, (last)hr23.w
(rpt1)mad.f16 hr19.x, (r)hr36.y, hr42.x, (r)(last)hr19.x
(rpt1)mad.f16 hr19.z, (r)hr36.w, hr42.x, (r)(last)hr19.z
(rpt1)mad.f16 hr15.x, (r)hr36.y, hr42.y, (r)(last)hr15.x
(rpt1)mad.f16 hr15.z, (r)hr36.w, hr42.y, (r)(last)hr15.z
(rpt1)mad.f16 hr11.x, (r)hr36.y, hr42.z, (r)(last)hr11.x
(rpt1)mad.f16 hr11.z, (r)hr36.w, hr42.z, (r)(last)hr11.z
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr42.w, (r)(last)hr7.x
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr42.w, (r)(last)hr7.z
ldl.u16 r7.x, l[r1.z+384], 4
(rpt2)nop
mov.u16u16 hr36.x, (last)hr37.x
ldl.u16 r37.x, l[r1.z+512], 4
(sy)mad.f16 hr33.x, hr6.x, hr0.z, (last)hr33.x
mad.f16 hr29.x, hr6.x, hr0.w, (last)hr29.x
mad.f16 hr25.x, hr6.x, hr1.x, (last)hr25.x
mad.f16 hr21.x, hr6.x, hr1.y, (last)hr21.x
mad.f16 hr17.x, hr6.x, hr42.x, (last)hr17.x
mad.f16 hr13.x, hr6.x, hr42.y, (last)hr13.x
mad.f16 hr9.x, hr6.x, hr42.z, (last)hr9.x
mad.f16 hr33.y, hr6.y, hr0.z, (last)hr33.y
mad.f16 hr29.y, hr6.y, hr0.w, (last)hr29.y
mad.f16 hr25.y, hr6.y, hr1.x, (last)hr25.y
mad.f16 hr21.y, hr6.y, hr1.y, (last)hr21.y
mad.f16 hr17.y, hr6.y, hr42.x, (last)hr17.y
mad.f16 hr13.y, hr6.y, hr42.y, (last)hr13.y
mad.f16 hr9.y, hr6.y, hr42.z, (last)hr9.y
mad.f16 hr33.z, hr6.z, hr0.z, (last)hr33.z
mad.f16 hr29.z, hr6.z, hr0.w, (last)hr29.z
mad.f16 hr25.z, hr6.z, hr1.x, (last)hr25.z
mad.f16 hr21.z, hr6.z, hr1.y, (last)hr21.z
mad.f16 hr17.z, hr6.z, hr42.x, (last)hr17.z
mad.f16 hr13.z, hr6.z, hr42.y, (last)hr13.z
mad.f16 hr9.z, hr6.z, hr42.z, (last)hr9.z
mad.f16 hr33.w, hr6.w, hr0.z, (last)hr33.w
mad.f16 hr29.w, hr6.w, hr0.w, (last)hr29.w
mad.f16 hr25.w, hr6.w, hr1.x, (last)hr25.w
mad.f16 hr21.w, hr6.w, hr1.y, (last)hr21.w
mad.f16 hr17.w, hr6.w, hr42.x, (last)hr17.w
mad.f16 hr13.w, hr6.w, hr42.y, (last)hr13.w
mad.f16 hr9.w, hr6.w, hr42.z, (last)hr9.w
(rpt1)mad.f16 hr6.x, (r)(last)hr6.x, hr42.w, (r)(last)hr5.x
(rpt1)mad.f16 hr6.z, (r)(last)hr6.z, hr42.w, (r)(last)hr5.z
isam.v.base0 (u16)(xyzw)hr5.x, r22.x+96, s#0, t#2
(ss)mov.u16u16 hr44.x, (last)hr1.x
mov.u16u16 hr44.y, (last)hr1.y
ldl.u16 r1.x, l[r1.z+640], 4
(sy)mad.f16 hr32.x, hr5.x, hr0.z, (last)hr32.x
mad.f16 hr28.x, hr5.x, hr0.w, (last)hr28.x
mad.f16 hr16.x, hr5.x, hr42.x, (last)hr16.x
mad.f16 hr12.x, hr5.x, hr42.y, (last)hr12.x
mad.f16 hr8.x, hr5.x, hr42.z, (last)hr8.x
mad.f16 hr32.y, hr5.y, hr0.z, (last)hr32.y
mad.f16 hr28.y, hr5.y, hr0.w, (last)hr28.y
mad.f16 hr16.y, hr5.y, hr42.x, (last)hr16.y
mad.f16 hr12.y, hr5.y, hr42.y, (last)hr12.y
mad.f16 hr8.y, hr5.y, hr42.z, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr5.z, hr0.z, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr5.z, hr0.w, (r)(last)hr28.z
(rpt1)mad.f16 hr16.z, (r)hr5.z, hr42.x, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr5.z, hr42.y, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr5.z, hr42.z, (r)(last)hr8.z
(rpt1)mad.f16 hr24.x, (r)hr5.x, hr44.x, (r)(last)hr24.x
(rpt1)mad.f16 hr24.z, (r)hr5.z, hr44.x, (r)(last)hr24.z
(rpt1)mad.f16 hr20.x, (r)hr5.x, hr44.y, (r)(last)hr20.x
(rpt1)mad.f16 hr20.z, (r)hr5.z, hr44.y, (r)(last)hr20.z
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr42.w, (r)(last)hr4.x
(rpt1)mad.f16 hr5.z, (r)(last)hr5.z, hr42.w, (r)(last)hr4.z
isam.v.base0 (u16)(xyzw)hr42.x, r22.w, s#0, t#2
ldl.u16 r4.x, l[r1.z+768], 4
(sy)mad.f16 hr35.x, hr42.x, hr43.x, (last)hr35.x
mad.f16 hr31.x, hr42.x, hr43.y, (last)hr31.x
mad.f16 hr27.x, hr42.x, hr43.z, (last)hr27.x
mad.f16 hr23.x, hr42.x, hr43.w, (last)hr23.x
mad.f16 hr35.y, hr42.y, hr43.x, (last)hr35.y
mad.f16 hr31.y, hr42.y, hr43.y, (last)hr31.y
mad.f16 hr27.y, hr42.y, hr43.z, (last)hr27.y
mad.f16 hr23.y, hr42.y, hr43.w, (last)hr23.y
mad.f16 hr35.z, hr42.z, hr43.x, (last)hr35.z
mad.f16 hr31.z, hr42.z, hr43.y, (last)hr31.z
mad.f16 hr19.x, hr42.x, hr7.x, (last)hr19.x
mad.f16 hr15.x, hr42.x, hr7.y, (last)hr15.x
mad.f16 hr11.x, hr42.x, hr7.z, (last)hr11.x
mad.f16 hr19.y, hr42.y, hr7.x, (last)hr19.y
mad.f16 hr15.y, hr42.y, hr7.y, (last)hr15.y
mad.f16 hr11.y, hr42.y, hr7.z, (last)hr11.y
mad.f16 hr27.z, hr42.z, hr43.z, (last)hr27.z
mad.f16 hr23.z, hr42.z, hr43.w, (last)hr23.z
mad.f16 hr19.z, hr42.z, hr7.x, (last)hr19.z
mad.f16 hr15.z, hr42.z, hr7.y, (last)hr15.z
mad.f16 hr11.z, hr42.z, hr7.z, (last)hr11.z
mad.f16 hr35.w, hr42.w, hr43.x, (last)hr35.w
mad.f16 hr31.w, hr42.w, hr43.y, (last)hr31.w
mad.f16 hr27.w, hr42.w, hr43.z, (last)hr27.w
mad.f16 hr23.w, hr42.w, hr43.w, (last)hr23.w
mad.f16 hr19.w, hr42.w, hr7.x, (last)hr19.w
mad.f16 hr15.w, hr42.w, hr7.y, (last)hr15.w
mad.f16 hr11.w, hr42.w, hr7.z, (last)hr11.w
(rpt1)mad.f16 hr42.x, (r)(last)hr42.x, hr7.w, (r)(last)hr36.y
mad.f16 hr42.z, (last)hr42.z, hr7.w, (last)hr36.w
mad.f16 hr42.w, (last)hr42.w, hr7.w, (last)hr36.x
isam.v.base0 (u16)(xyzw)hr36.x, r23.x, s#0, t#2
(ss)nop
ldl.u16 r45.z, l[r1.z+896], 4
(sy)mad.f16 hr34.x, hr36.x, hr43.x, (last)hr34.x
mad.f16 hr30.x, hr36.x, hr43.y, (last)hr30.x
mad.f16 hr26.x, hr36.x, hr43.z, (last)hr26.x
mad.f16 hr22.x, hr36.x, hr43.w, (last)hr22.x
mad.f16 hr18.x, hr36.x, hr7.x, (last)hr18.x
mad.f16 hr14.x, hr36.x, hr7.y, (last)hr14.x
mad.f16 hr10.x, hr36.x, hr7.z, (last)hr10.x
mad.f16 hr34.y, hr36.y, hr43.x, (last)hr34.y
mad.f16 hr30.y, hr36.y, hr43.y, (last)hr30.y
mad.f16 hr26.y, hr36.y, hr43.z, (last)hr26.y
mad.f16 hr22.y, hr36.y, hr43.w, (last)hr22.y
mad.f16 hr18.y, hr36.y, hr7.x, (last)hr18.y
mad.f16 hr14.y, hr36.y, hr7.y, (last)hr14.y
mad.f16 hr10.y, hr36.y, hr7.z, (last)hr10.y
(rpt1)mad.f16 hr36.x, (r)(last)hr36.x, hr7.w, (r)(last)hr44.z
isam.v.base0 (u16)(xyzw)hr44.x, r23.y, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr46.z, r23.z, s#0, t#2
mad.f16 hr34.z, hr36.z, hr43.x, (last)hr34.z
mad.f16 hr30.z, hr36.z, hr43.y, (last)hr30.z
mad.f16 hr26.z, hr36.z, hr43.z, (last)hr26.z
mad.f16 hr22.z, hr36.z, hr43.w, (last)hr22.z
mad.f16 hr18.z, hr36.z, hr7.x, (last)hr18.z
mad.f16 hr14.z, hr36.z, hr7.y, (last)hr14.z
mad.f16 hr10.z, hr36.z, hr7.z, (last)hr10.z
mad.f16 hr34.w, hr36.w, hr43.x, (last)hr34.w
mad.f16 hr30.w, hr36.w, hr43.y, (last)hr30.w
mad.f16 hr26.w, hr36.w, hr43.z, (last)hr26.w
mad.f16 hr22.w, hr36.w, hr43.w, (last)hr22.w
mad.f16 hr18.w, hr36.w, hr7.x, (last)hr18.w
mad.f16 hr14.w, hr36.w, hr7.y, (last)hr14.w
mad.f16 hr10.w, hr36.w, hr7.z, (last)hr10.w
(rpt1)mad.f16 hr36.z, (r)(last)hr36.z, hr7.w, (r)(last)hr45.x
mov.u32u32 r22.z, (last)r0.x
ldl.u16 r0.x, l[r1.z+1024], 4
(sy)mad.f16 hr33.x, hr44.x, hr43.x, (last)hr33.x
mad.f16 hr29.x, hr44.x, hr43.y, (last)hr29.x
mad.f16 hr25.x, hr44.x, hr43.z, (last)hr25.x
mad.f16 hr21.x, hr44.x, hr43.w, (last)hr21.x
mad.f16 hr17.x, hr44.x, hr7.x, (last)hr17.x
mad.f16 hr13.x, hr44.x, hr7.y, (last)hr13.x
mad.f16 hr9.x, hr44.x, hr7.z, (last)hr9.x
mad.f16 hr33.y, hr44.y, hr43.x, (last)hr33.y
mad.f16 hr29.y, hr44.y, hr43.y, (last)hr29.y
mad.f16 hr25.y, hr44.y, hr43.z, (last)hr25.y
mad.f16 hr21.y, hr44.y, hr43.w, (last)hr21.y
mad.f16 hr17.y, hr44.y, hr7.x, (last)hr17.y
mad.f16 hr13.y, hr44.y, hr7.y, (last)hr13.y
mad.f16 hr9.y, hr44.y, hr7.z, (last)hr9.y
mad.f16 hr33.z, hr44.z, hr43.x, (last)hr33.z
mad.f16 hr29.z, hr44.z, hr43.y, (last)hr29.z
mad.f16 hr25.z, hr44.z, hr43.z, (last)hr25.z
mad.f16 hr21.z, hr44.z, hr43.w, (last)hr21.z
mad.f16 hr17.z, hr44.z, hr7.x, (last)hr17.z
mad.f16 hr13.z, hr44.z, hr7.y, (last)hr13.z
mad.f16 hr9.z, hr44.z, hr7.z, (last)hr9.z
mad.f16 hr33.w, hr44.w, hr43.x, (last)hr33.w
mad.f16 hr29.w, hr44.w, hr43.y, (last)hr29.w
mad.f16 hr25.w, hr44.w, hr43.z, (last)hr25.w
mad.f16 hr21.w, hr44.w, hr43.w, (last)hr21.w
mad.f16 hr17.w, hr44.w, hr7.x, (last)hr17.w
mad.f16 hr13.w, hr44.w, hr7.y, (last)hr13.w
mad.f16 hr9.w, hr44.w, hr7.z, (last)hr9.w
mad.f16 hr32.x, hr46.z, hr43.x, (last)hr32.x
mad.f16 hr28.x, hr46.z, hr43.y, (last)hr28.x
mad.f16 hr24.x, hr46.z, hr43.z, (last)hr24.x
mad.f16 hr20.x, hr46.z, hr43.w, (last)hr20.x
mad.f16 hr16.x, hr46.z, hr7.x, (last)hr16.x
mad.f16 hr12.x, hr46.z, hr7.y, (last)hr12.x
mad.f16 hr8.x, hr46.z, hr7.z, (last)hr8.x
mad.f16 hr32.y, hr46.w, hr43.x, (last)hr32.y
mad.f16 hr28.y, hr46.w, hr43.y, (last)hr28.y
mad.f16 hr24.y, hr46.w, hr43.z, (last)hr24.y
mad.f16 hr20.y, hr46.w, hr43.w, (last)hr20.y
mad.f16 hr16.y, hr46.w, hr7.x, (last)hr16.y
mad.f16 hr12.y, hr46.w, hr7.y, (last)hr12.y
mad.f16 hr8.y, hr46.w, hr7.z, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr47.x, hr43.x, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr47.x, hr43.y, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr47.x, hr43.z, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr47.x, hr43.w, (r)(last)hr20.z
(rpt1)mad.f16 hr16.z, (r)hr47.x, hr7.x, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr47.x, hr7.y, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr47.x, hr7.z, (r)(last)hr8.z
(rpt1)mad.f16 hr44.x, (r)(last)hr44.x, hr7.w, (r)(last)hr6.x
(rpt1)mad.f16 hr44.z, (r)(last)hr44.z, hr7.w, (r)(last)hr6.z
ldl.u16 r6.x, l[r1.z+1152], 4
ldl.u16 r43.x, l[r1.z+1280], 4
(rpt1)mad.f16 hr46.z, (r)(last)hr46.z, hr7.w, (r)(last)hr5.x
(rpt1)mad.f16 hr47.x, (r)(last)hr47.x, hr7.w, (r)(last)hr5.z
isam.v.base0 (u16)(xyzw)hr7.x, r23.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr5.x, r24.x, s#0, t#2
(sy)mad.f16 hr34.x, hr5.x, hr37.x, (last)hr34.x
mad.f16 hr30.x, hr5.x, hr37.y, (last)hr30.x
mad.f16 hr26.x, hr5.x, hr37.z, (last)hr26.x
mad.f16 hr22.x, hr5.x, hr37.w, (last)hr22.x
mad.f16 hr18.x, hr5.x, hr1.x, (last)hr18.x
mad.f16 hr14.x, hr5.x, hr1.y, (last)hr14.x
mad.f16 hr10.x, hr5.x, hr1.z, (last)hr10.x
mad.f16 hr34.y, hr5.y, hr37.x, (last)hr34.y
mad.f16 hr30.y, hr5.y, hr37.y, (last)hr30.y
mad.f16 hr26.y, hr5.y, hr37.z, (last)hr26.y
mad.f16 hr22.y, hr5.y, hr37.w, (last)hr22.y
mad.f16 hr18.y, hr5.y, hr1.x, (last)hr18.y
mad.f16 hr14.y, hr5.y, hr1.y, (last)hr14.y
mad.f16 hr10.y, hr5.y, hr1.z, (last)hr10.y
mad.f16 hr34.z, hr5.z, hr37.x, (last)hr34.z
mad.f16 hr30.z, hr5.z, hr37.y, (last)hr30.z
mad.f16 hr26.z, hr5.z, hr37.z, (last)hr26.z
mad.f16 hr22.z, hr5.z, hr37.w, (last)hr22.z
mad.f16 hr18.z, hr5.z, hr1.x, (last)hr18.z
mad.f16 hr14.z, hr5.z, hr1.y, (last)hr14.z
mad.f16 hr10.z, hr5.z, hr1.z, (last)hr10.z
mad.f16 hr34.w, hr5.w, hr37.x, (last)hr34.w
mad.f16 hr30.w, hr5.w, hr37.y, (last)hr30.w
mad.f16 hr26.w, hr5.w, hr37.z, (last)hr26.w
mad.f16 hr22.w, hr5.w, hr37.w, (last)hr22.w
mad.f16 hr18.w, hr5.w, hr1.x, (last)hr18.w
mad.f16 hr14.w, hr5.w, hr1.y, (last)hr14.w
mad.f16 hr10.w, hr5.w, hr1.z, (last)hr10.w
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr1.w, (r)(last)hr36.x
(rpt1)mad.f16 hr5.z, (r)(last)hr5.z, hr1.w, (r)(last)hr36.z
isam.v.base0 (u16)(xyzw)hr36.x, r24.y, s#0, t#2
mov.u16u16 hr47.z, hr1.z
mov.u16u16 hr47.w, hr1.w
mad.f16 hr35.x, hr7.x, hr37.x, (last)hr35.x
mad.f16 hr31.x, hr7.x, hr37.y, (last)hr31.x
mad.f16 hr27.x, hr7.x, hr37.z, (last)hr27.x
mad.f16 hr23.x, hr7.x, hr37.w, (last)hr23.x
mad.f16 hr19.x, hr7.x, hr1.x, (last)hr19.x
mad.f16 hr15.x, hr7.x, hr1.y, (last)hr15.x
mad.f16 hr11.x, hr7.x, hr1.z, (last)hr11.x
mad.f16 hr35.y, hr7.y, hr37.x, (last)hr35.y
mad.f16 hr31.y, hr7.y, hr37.y, (last)hr31.y
mad.f16 hr27.y, hr7.y, hr37.z, (last)hr27.y
mad.f16 hr23.y, hr7.y, hr37.w, (last)hr23.y
mad.f16 hr19.y, hr7.y, hr1.x, (last)hr19.y
mad.f16 hr15.y, hr7.y, hr1.y, (last)hr15.y
mad.f16 hr11.y, hr7.y, hr1.z, (last)hr11.y
mad.f16 hr35.z, hr7.z, hr37.x, (last)hr35.z
mad.f16 hr31.z, hr7.z, hr37.y, (last)hr31.z
mad.f16 hr27.z, hr7.z, hr37.z, (last)hr27.z
mad.f16 hr23.z, hr7.z, hr37.w, (last)hr23.z
mad.f16 hr19.z, hr7.z, hr1.x, (last)hr19.z
mad.f16 hr15.z, hr7.z, hr1.y, (last)hr15.z
mad.f16 hr11.z, hr7.z, hr1.z, (last)hr11.z
mad.f16 hr35.w, hr7.w, hr37.x, (last)hr35.w
mad.f16 hr31.w, hr7.w, hr37.y, (last)hr31.w
mad.f16 hr27.w, hr7.w, hr37.z, (last)hr27.w
mad.f16 hr23.w, hr7.w, hr37.w, (last)hr23.w
mad.f16 hr19.w, hr7.w, hr1.x, (last)hr19.w
mad.f16 hr15.w, hr7.w, hr1.y, (last)hr15.w
mad.f16 hr11.w, hr7.w, hr1.z, (last)hr11.w
(rpt1)mad.f16 hr7.x, (r)(last)hr7.x, hr1.w, (r)(last)hr42.x
(rpt1)mad.f16 hr7.z, (r)(last)hr7.z, hr1.w, (r)(last)hr42.z
ldl.u16 r42.x, l[r1.z+1408], 4
mov.u32u32 r24.x, (last)r1.x
ldl.u16 r1.z, l[r1.z+1536], 4
(sy)mad.f16 hr33.x, hr36.x, hr37.x, (last)hr33.x
mad.f16 hr29.x, hr36.x, hr37.y, (last)hr29.x
mad.f16 hr25.x, hr36.x, hr37.z, (last)hr25.x
mad.f16 hr21.x, hr36.x, hr37.w, (last)hr21.x
mad.f16 hr17.x, hr36.x, hr1.x, (last)hr17.x
mad.f16 hr13.x, hr36.x, hr1.y, (last)hr13.x
mad.f16 hr33.y, hr36.y, hr37.x, (last)hr33.y
mad.f16 hr29.y, hr36.y, hr37.y, (last)hr29.y
mad.f16 hr25.y, hr36.y, hr37.z, (last)hr25.y
mad.f16 hr21.y, hr36.y, hr37.w, (last)hr21.y
mad.f16 hr17.y, hr36.y, hr1.x, (last)hr17.y
mad.f16 hr13.y, hr36.y, hr1.y, (last)hr13.y
mad.f16 hr33.z, hr36.z, hr37.x, (last)hr33.z
mad.f16 hr29.z, hr36.z, hr37.y, (last)hr29.z
mad.f16 hr25.z, hr36.z, hr37.z, (last)hr25.z
mad.f16 hr21.z, hr36.z, hr37.w, (last)hr21.z
mad.f16 hr17.z, hr36.z, hr1.x, (last)hr17.z
mad.f16 hr13.z, hr36.z, hr1.y, (last)hr13.z
mad.f16 hr33.w, hr36.w, hr37.x, (last)hr33.w
mad.f16 hr29.w, hr36.w, hr37.y, (last)hr29.w
mad.f16 hr25.w, hr36.w, hr37.z, (last)hr25.w
mad.f16 hr21.w, hr36.w, hr37.w, (last)hr21.w
mad.f16 hr17.w, hr36.w, hr1.x, (last)hr17.w
mad.f16 hr13.w, hr36.w, hr1.y, (last)hr13.w
(rpt1)mad.f16 hr9.x, (r)hr36.x, hr47.z, (r)(last)hr9.x
(rpt1)mad.f16 hr9.z, (r)hr36.z, hr47.z, (r)(last)hr9.z
(rpt1)mad.f16 hr36.x, (r)(last)hr36.x, hr47.w, (r)(last)hr44.x
(rpt1)mad.f16 hr36.z, (r)(last)hr36.z, hr47.w, (r)(last)hr44.z
isam.v.base0 (u16)(xyzw)hr44.x, r24.z, s#0, t#2
(ss)mov.u32u32 r24.z, (last)r1.z
mov.u32u32 r24.y, (last)r1.y
(sy)mad.f16 hr8.x, hr44.x, hr47.z, (last)hr8.x
mad.f16 hr32.y, hr44.y, hr37.x, (last)hr32.y
mad.f16 hr28.y, hr44.y, hr37.y, (last)hr28.y
mad.f16 hr24.y, hr44.y, hr37.z, (last)hr24.y
mad.f16 hr20.y, hr44.y, hr37.w, (last)hr20.y
ldl.u16 r2.z, l[r24.z+1664], 4
mad.f16 hr16.y, hr44.y, hr1.x, (last)hr16.y
mad.f16 hr12.y, hr44.y, hr1.y, (last)hr12.y
mad.f16 hr8.y, hr44.y, hr47.z, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr44.z, hr37.x, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr44.z, hr37.y, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr44.z, hr37.z, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr44.z, hr37.w, (r)(last)hr20.z
(rpt1)mad.f16 hr16.z, (r)hr44.z, hr1.x, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr44.z, hr1.y, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr44.z, hr47.z, (r)(last)hr8.z
mad.f16 hr44.y, (last)hr44.y, hr47.w, (last)hr46.w
(rpt1)mad.f16 hr44.z, (r)(last)hr44.z, hr47.w, (r)(last)hr47.x
isam.v.base0 (u16)(xyzw)hr46.w, r24.w, s#0, t#2
mad.f16 hr32.x, hr44.x, hr37.x, (last)hr32.x
mad.f16 hr28.x, hr44.x, hr37.y, (last)hr28.x
mad.f16 hr24.x, hr44.x, hr37.z, (last)hr24.x
mad.f16 hr20.x, hr44.x, hr37.w, (last)hr20.x
ldl.u16 r37.x, l[r24.z+1792], 4
mad.f16 hr16.x, hr44.x, hr1.x, (last)hr16.x
mad.f16 hr12.x, hr44.x, hr1.y, (last)hr12.x
mad.f16 hr44.x, (last)hr44.x, hr47.w, (last)hr46.z
mov.u16u16 hr47.w, (last)hr0.w
mov.u16u16 hr46.z, (last)hr0.z
ldl.u16 r0.z, l[r24.z+1920], 4
(sy)mad.f16 hr35.x, hr46.w, hr4.x, (last)hr35.x
mad.f16 hr31.x, hr46.w, hr4.y, (last)hr31.x
mad.f16 hr27.x, hr46.w, hr4.z, (last)hr27.x
mad.f16 hr23.x, hr46.w, hr4.w, (last)hr23.x
mad.f16 hr35.y, hr47.x, hr4.x, (last)hr35.y
mad.f16 hr31.y, hr47.x, hr4.y, (last)hr31.y
mad.f16 hr27.y, hr47.x, hr4.z, (last)hr27.y
mad.f16 hr23.y, hr47.x, hr4.w, (last)hr23.y
mad.f16 hr35.z, hr47.y, hr4.x, (last)hr35.z
mad.f16 hr31.z, hr47.y, hr4.y, (last)hr31.z
mad.f16 hr19.x, hr46.w, hr45.z, (last)hr19.x
mad.f16 hr15.x, hr46.w, hr45.w, (last)hr15.x
mad.f16 hr11.x, hr46.w, hr46.x, (last)hr11.x
mad.f16 hr19.y, hr47.x, hr45.z, (last)hr19.y
mad.f16 hr15.y, hr47.x, hr45.w, (last)hr15.y
mad.f16 hr11.y, hr47.x, hr46.x, (last)hr11.y
mad.f16 hr27.z, hr47.y, hr4.z, (last)hr27.z
mad.f16 hr23.z, hr47.y, hr4.w, (last)hr23.z
mad.f16 hr19.z, hr47.y, hr45.z, (last)hr19.z
mad.f16 hr15.z, hr47.y, hr45.w, (last)hr15.z
mad.f16 hr11.z, hr47.y, hr46.x, (last)hr11.z
mad.f16 hr35.w, hr47.z, hr4.x, (last)hr35.w
mad.f16 hr31.w, hr47.z, hr4.y, (last)hr31.w
mad.f16 hr27.w, hr47.z, hr4.z, (last)hr27.w
mad.f16 hr23.w, hr47.z, hr4.w, (last)hr23.w
mad.f16 hr19.w, hr47.z, hr45.z, (last)hr19.w
mad.f16 hr15.w, hr47.z, hr45.w, (last)hr15.w
mad.f16 hr11.w, hr47.z, hr46.x, (last)hr11.w
(rpt1)mad.f16 hr46.w, (r)(last)hr46.w, hr46.y, (r)(last)hr7.x
(rpt1)mad.f16 hr47.y, (r)(last)hr47.y, hr46.y, (r)(last)hr7.z
isam.v.base0 (u16)(xyzw)hr7.x, r25.x, s#0, t#2
mov.u32u32 r24.w, (last)r19.x
(ss)mov.u32u32 r25.x, (last)r19.y
ldl.u16 r38.x, l[r24.z+2048], 4
(sy)mad.f16 hr34.x, hr7.x, hr4.x, (last)hr34.x
mad.f16 hr30.x, hr7.x, hr4.y, (last)hr30.x
mad.f16 hr26.x, hr7.x, hr4.z, (last)hr26.x
mad.f16 hr22.x, hr7.x, hr4.w, (last)hr22.x
mad.f16 hr18.x, hr7.x, hr45.z, (last)hr18.x
mad.f16 hr14.x, hr7.x, hr45.w, (last)hr14.x
mad.f16 hr10.x, hr7.x, hr46.x, (last)hr10.x
mad.f16 hr34.y, hr7.y, hr4.x, (last)hr34.y
mad.f16 hr30.y, hr7.y, hr4.y, (last)hr30.y
mad.f16 hr26.y, hr7.y, hr4.z, (last)hr26.y
mad.f16 hr22.y, hr7.y, hr4.w, (last)hr22.y
mad.f16 hr18.y, hr7.y, hr45.z, (last)hr18.y
mad.f16 hr14.y, hr7.y, hr45.w, (last)hr14.y
mad.f16 hr10.y, hr7.y, hr46.x, (last)hr10.y
mad.f16 hr34.z, hr7.z, hr4.x, (last)hr34.z
mad.f16 hr30.z, hr7.z, hr4.y, (last)hr30.z
mad.f16 hr26.z, hr7.z, hr4.z, (last)hr26.z
mad.f16 hr22.z, hr7.z, hr4.w, (last)hr22.z
mad.f16 hr18.z, hr7.z, hr45.z, (last)hr18.z
mad.f16 hr14.z, hr7.z, hr45.w, (last)hr14.z
mad.f16 hr10.z, hr7.z, hr46.x, (last)hr10.z
mad.f16 hr34.w, hr7.w, hr4.x, (last)hr34.w
mad.f16 hr30.w, hr7.w, hr4.y, (last)hr30.w
mad.f16 hr26.w, hr7.w, hr4.z, (last)hr26.w
mad.f16 hr22.w, hr7.w, hr4.w, (last)hr22.w
mad.f16 hr18.w, hr7.w, hr45.z, (last)hr18.w
mad.f16 hr14.w, hr7.w, hr45.w, (last)hr14.w
mad.f16 hr10.w, hr7.w, hr46.x, (last)hr10.w
(rpt1)mad.f16 hr7.x, (r)(last)hr7.x, hr46.y, (r)(last)hr5.x
(rpt1)mad.f16 hr7.z, (r)(last)hr7.z, hr46.y, (r)(last)hr5.z
isam.v.base0 (u16)(xyzw)hr5.x, r25.y, s#0, t#2
(ss)mov.u32u32 r25.y, (last)r19.z
(sy)mad.f16 hr33.x, hr5.x, hr4.x, (last)hr33.x
mad.f16 hr29.x, hr5.x, hr4.y, (last)hr29.x
mad.f16 hr25.x, hr5.x, hr4.z, (last)hr25.x
mad.f16 hr21.x, hr5.x, hr4.w, (last)hr21.x
mad.f16 hr17.x, hr5.x, hr45.z, (last)hr17.x
mad.f16 hr13.x, hr5.x, hr45.w, (last)hr13.x
mad.f16 hr9.x, hr5.x, hr46.x, (last)hr9.x
mad.f16 hr33.y, hr5.y, hr4.x, (last)hr33.y
mad.f16 hr29.y, hr5.y, hr4.y, (last)hr29.y
mad.f16 hr25.y, hr5.y, hr4.z, (last)hr25.y
mad.f16 hr21.y, hr5.y, hr4.w, (last)hr21.y
mad.f16 hr17.y, hr5.y, hr45.z, (last)hr17.y
mad.f16 hr13.y, hr5.y, hr45.w, (last)hr13.y
mad.f16 hr9.y, hr5.y, hr46.x, (last)hr9.y
mad.f16 hr33.z, hr5.z, hr4.x, (last)hr33.z
mad.f16 hr29.z, hr5.z, hr4.y, (last)hr29.z
mad.f16 hr25.z, hr5.z, hr4.z, (last)hr25.z
mad.f16 hr21.z, hr5.z, hr4.w, (last)hr21.z
mad.f16 hr17.z, hr5.z, hr45.z, (last)hr17.z
mad.f16 hr13.z, hr5.z, hr45.w, (last)hr13.z
mad.f16 hr9.z, hr5.z, hr46.x, (last)hr9.z
mad.f16 hr33.w, hr5.w, hr4.x, (last)hr33.w
mad.f16 hr29.w, hr5.w, hr4.y, (last)hr29.w
mad.f16 hr25.w, hr5.w, hr4.z, (last)hr25.w
mad.f16 hr21.w, hr5.w, hr4.w, (last)hr21.w
mad.f16 hr17.w, hr5.w, hr45.z, (last)hr17.w
mad.f16 hr13.w, hr5.w, hr45.w, (last)hr13.w
mad.f16 hr9.w, hr5.w, hr46.x, (last)hr9.w
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr46.y, (r)(last)hr36.x
(rpt1)mad.f16 hr5.z, (r)(last)hr5.z, hr46.y, (r)(last)hr36.z
isam.v.base0 (u16)(xyzw)hr36.x, r25.z, s#0, t#2
(ss)mov.u32u32 r25.z, (last)r19.w
ldl.u16 r39.x, l[r24.z+2176], 4
(sy)mad.f16 hr32.x, hr36.x, hr4.x, (last)hr32.x
mad.f16 hr28.x, hr36.x, hr4.y, (last)hr28.x
mad.f16 hr24.x, hr36.x, hr4.z, (last)hr24.x
mad.f16 hr20.x, hr36.x, hr4.w, (last)hr20.x
mad.f16 hr16.x, hr36.x, hr45.z, (last)hr16.x
mad.f16 hr12.x, hr36.x, hr45.w, (last)hr12.x
mad.f16 hr8.x, hr36.x, hr46.x, (last)hr8.x
mad.f16 hr32.y, hr36.y, hr4.x, (last)hr32.y
mad.f16 hr28.y, hr36.y, hr4.y, (last)hr28.y
mad.f16 hr24.y, hr36.y, hr4.z, (last)hr24.y
mad.f16 hr20.y, hr36.y, hr4.w, (last)hr20.y
mad.f16 hr16.y, hr36.y, hr45.z, (last)hr16.y
mad.f16 hr12.y, hr36.y, hr45.w, (last)hr12.y
mad.f16 hr8.y, hr36.y, hr46.x, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr36.z, hr4.x, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr36.z, hr4.y, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr36.z, hr4.z, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr36.z, hr4.w, (r)(last)hr20.z
(rpt1)mad.f16 hr16.z, (r)hr36.z, hr45.z, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr36.z, hr45.w, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr36.z, hr46.x, (r)(last)hr8.z
(rpt1)mad.f16 hr36.x, (r)(last)hr36.x, hr46.y, (r)(last)hr44.x
(rpt1)mad.f16 hr36.z, (r)(last)hr36.z, hr46.y, (r)(last)hr44.z
isam.v.base0 (u16)(xyzw)hr44.x, r25.w, s#0, t#2
ldl.u16 r45.z, l[r24.z+2304], 4
ldl.u16 r4.x, l[r24.z+2432], 4
(sy)mad.f16 hr35.x, hr44.x, hr0.x, (last)hr35.x
mad.f16 hr31.x, hr44.x, hr0.y, (last)hr31.x
mad.f16 hr27.x, hr44.x, hr46.z, (last)hr27.x
mad.f16 hr23.x, hr44.x, hr47.w, (last)hr23.x
mad.f16 hr19.x, hr44.x, hr6.x, (last)hr19.x
mad.f16 hr15.x, hr44.x, hr6.y, (last)hr15.x
mad.f16 hr11.x, hr44.x, hr6.z, (last)hr11.x
mad.f16 hr35.y, hr44.y, hr0.x, (last)hr35.y
mad.f16 hr31.y, hr44.y, hr0.y, (last)hr31.y
mad.f16 hr27.y, hr44.y, hr46.z, (last)hr27.y
mad.f16 hr23.y, hr44.y, hr47.w, (last)hr23.y
mad.f16 hr19.y, hr44.y, hr6.x, (last)hr19.y
mad.f16 hr15.y, hr44.y, hr6.y, (last)hr15.y
mad.f16 hr11.y, hr44.y, hr6.z, (last)hr11.y
mad.f16 hr35.z, hr44.z, hr0.x, (last)hr35.z
mad.f16 hr31.z, hr44.z, hr0.y, (last)hr31.z
mad.f16 hr27.z, hr44.z, hr46.z, (last)hr27.z
mad.f16 hr23.z, hr44.z, hr47.w, (last)hr23.z
mad.f16 hr19.z, hr44.z, hr6.x, (last)hr19.z
mad.f16 hr15.z, hr44.z, hr6.y, (last)hr15.z
mad.f16 hr11.z, hr44.z, hr6.z, (last)hr11.z
mad.f16 hr35.w, hr44.w, hr0.x, (last)hr35.w
mad.f16 hr31.w, hr44.w, hr0.y, (last)hr31.w
mad.f16 hr27.w, hr44.w, hr46.z, (last)hr27.w
mad.f16 hr23.w, hr44.w, hr47.w, (last)hr23.w
mad.f16 hr19.w, hr44.w, hr6.x, (last)hr19.w
mad.f16 hr15.w, hr44.w, hr6.y, (last)hr15.w
mad.f16 hr11.w, hr44.w, hr6.z, (last)hr11.w
(rpt1)mad.f16 hr44.x, (r)(last)hr44.x, hr6.w, (r)(last)hr46.w
(rpt1)mad.f16 hr44.z, (r)(last)hr44.z, hr6.w, (r)(last)hr47.y
isam.v.base0 (u16)(xyzw)hr46.w, r26.x, s#0, t#2
mov.u32u32 r25.w, (last)r20.x
(ss)mov.u32u32 r26.x, (last)r20.y
ldl.u16 r40.x, l[r24.z+2560], 4
(sy)mad.f16 hr34.x, hr46.w, hr0.x, (last)hr34.x
mad.f16 hr30.x, hr46.w, hr0.y, (last)hr30.x
mad.f16 hr26.x, hr46.w, hr46.z, (last)hr26.x
mad.f16 hr22.x, hr46.w, hr47.w, (last)hr22.x
mad.f16 hr18.x, hr46.w, hr6.x, (last)hr18.x
mad.f16 hr14.x, hr46.w, hr6.y, (last)hr14.x
mad.f16 hr10.x, hr46.w, hr6.z, (last)hr10.x
mad.f16 hr34.y, hr47.x, hr0.x, (last)hr34.y
mad.f16 hr30.y, hr47.x, hr0.y, (last)hr30.y
mad.f16 hr26.y, hr47.x, hr46.z, (last)hr26.y
mad.f16 hr22.y, hr47.x, hr47.w, (last)hr22.y
mad.f16 hr18.y, hr47.x, hr6.x, (last)hr18.y
mad.f16 hr14.y, hr47.x, hr6.y, (last)hr14.y
mad.f16 hr10.y, hr47.x, hr6.z, (last)hr10.y
mad.f16 hr34.z, hr47.y, hr0.x, (last)hr34.z
mad.f16 hr30.z, hr47.y, hr0.y, (last)hr30.z
mad.f16 hr26.z, hr47.y, hr46.z, (last)hr26.z
mad.f16 hr22.z, hr47.y, hr47.w, (last)hr22.z
mad.f16 hr18.z, hr47.y, hr6.x, (last)hr18.z
mad.f16 hr14.z, hr47.y, hr6.y, (last)hr14.z
mad.f16 hr10.z, hr47.y, hr6.z, (last)hr10.z
mad.f16 hr34.w, hr47.z, hr0.x, (last)hr34.w
mad.f16 hr30.w, hr47.z, hr0.y, (last)hr30.w
mad.f16 hr26.w, hr47.z, hr46.z, (last)hr26.w
mad.f16 hr22.w, hr47.z, hr47.w, (last)hr22.w
mad.f16 hr18.w, hr47.z, hr6.x, (last)hr18.w
mad.f16 hr14.w, hr47.z, hr6.y, (last)hr14.w
mad.f16 hr10.w, hr47.z, hr6.z, (last)hr10.w
(rpt1)mad.f16 hr46.w, (r)(last)hr46.w, hr6.w, (r)(last)hr7.x
(rpt1)mad.f16 hr47.y, (r)(last)hr47.y, hr6.w, (r)(last)hr7.z
isam.v.base0 (u16)(xyzw)hr7.x, r26.y, s#0, t#2
(ss)mov.u32u32 r26.y, (last)r20.z
(sy)mad.f16 hr33.x, hr7.x, hr0.x, (last)hr33.x
mad.f16 hr29.x, hr7.x, hr0.y, (last)hr29.x
mad.f16 hr25.x, hr7.x, hr46.z, (last)hr25.x
mad.f16 hr21.x, hr7.x, hr47.w, (last)hr21.x
mad.f16 hr17.x, hr7.x, hr6.x, (last)hr17.x
mad.f16 hr13.x, hr7.x, hr6.y, (last)hr13.x
mad.f16 hr9.x, hr7.x, hr6.z, (last)hr9.x
mad.f16 hr33.y, hr7.y, hr0.x, (last)hr33.y
mad.f16 hr29.y, hr7.y, hr0.y, (last)hr29.y
mad.f16 hr25.y, hr7.y, hr46.z, (last)hr25.y
mad.f16 hr21.y, hr7.y, hr47.w, (last)hr21.y
mad.f16 hr17.y, hr7.y, hr6.x, (last)hr17.y
mad.f16 hr13.y, hr7.y, hr6.y, (last)hr13.y
mad.f16 hr9.y, hr7.y, hr6.z, (last)hr9.y
mad.f16 hr33.z, hr7.z, hr0.x, (last)hr33.z
mad.f16 hr29.z, hr7.z, hr0.y, (last)hr29.z
mad.f16 hr25.z, hr7.z, hr46.z, (last)hr25.z
mad.f16 hr21.z, hr7.z, hr47.w, (last)hr21.z
mad.f16 hr17.z, hr7.z, hr6.x, (last)hr17.z
mad.f16 hr13.z, hr7.z, hr6.y, (last)hr13.z
mad.f16 hr9.z, hr7.z, hr6.z, (last)hr9.z
mad.f16 hr33.w, hr7.w, hr0.x, (last)hr33.w
mad.f16 hr29.w, hr7.w, hr0.y, (last)hr29.w
mad.f16 hr25.w, hr7.w, hr46.z, (last)hr25.w
mad.f16 hr21.w, hr7.w, hr47.w, (last)hr21.w
mad.f16 hr17.w, hr7.w, hr6.x, (last)hr17.w
mad.f16 hr13.w, hr7.w, hr6.y, (last)hr13.w
mad.f16 hr9.w, hr7.w, hr6.z, (last)hr9.w
(rpt1)mad.f16 hr7.x, (r)(last)hr7.x, hr6.w, (r)(last)hr5.x
(rpt1)mad.f16 hr7.z, (r)(last)hr7.z, hr6.w, (r)(last)hr5.z
isam.v.base0 (u16)(xyzw)hr5.x, r26.z, s#0, t#2
(ss)mov.u32u32 r26.z, (last)r20.w
ldl.u16 r41.x, l[r24.z+2688], 4
(sy)mad.f16 hr32.x, hr5.x, hr0.x, (last)hr32.x
mad.f16 hr28.x, hr5.x, hr0.y, (last)hr28.x
mad.f16 hr24.x, hr5.x, hr46.z, (last)hr24.x
mad.f16 hr20.x, hr5.x, hr47.w, (last)hr20.x
mad.f16 hr16.x, hr5.x, hr6.x, (last)hr16.x
mad.f16 hr12.x, hr5.x, hr6.y, (last)hr12.x
mad.f16 hr8.x, hr5.x, hr6.z, (last)hr8.x
mad.f16 hr32.y, hr5.y, hr0.x, (last)hr32.y
mad.f16 hr28.y, hr5.y, hr0.y, (last)hr28.y
mad.f16 hr24.y, hr5.y, hr46.z, (last)hr24.y
mad.f16 hr20.y, hr5.y, hr47.w, (last)hr20.y
mad.f16 hr16.y, hr5.y, hr6.x, (last)hr16.y
mad.f16 hr12.y, hr5.y, hr6.y, (last)hr12.y
mad.f16 hr8.y, hr5.y, hr6.z, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr5.z, hr0.x, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr5.z, hr0.y, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr5.z, hr46.z, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr5.z, hr47.w, (r)(last)hr20.z
(rpt1)mad.f16 hr16.z, (r)hr5.z, hr6.x, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr5.z, hr6.y, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr5.z, hr6.z, (r)(last)hr8.z
(rpt1)mad.f16 hr5.x, (r)(last)hr5.x, hr6.w, (r)(last)hr36.x
(rpt1)mad.f16 hr5.z, (r)(last)hr5.z, hr6.w, (r)(last)hr36.z
isam.v.base0 (u16)(xyzw)hr6.x, r26.w, s#0, t#2
ldl.u16 r36.x, l[r24.z+2816], 4
(sy)mad.f16 hr35.x, hr6.x, hr43.x, (last)hr35.x
mad.f16 hr31.x, hr6.x, hr43.y, (last)hr31.x
mad.f16 hr27.x, hr6.x, hr43.z, (last)hr27.x
mad.f16 hr23.x, hr6.x, hr43.w, (last)hr23.x
mad.f16 hr19.x, hr6.x, hr42.x, (last)hr19.x
mad.f16 hr15.x, hr6.x, hr42.y, (last)hr15.x
mad.f16 hr11.x, hr6.x, hr42.z, (last)hr11.x
mad.f16 hr35.y, hr6.y, hr43.x, (last)hr35.y
mad.f16 hr31.y, hr6.y, hr43.y, (last)hr31.y
mad.f16 hr27.y, hr6.y, hr43.z, (last)hr27.y
mad.f16 hr23.y, hr6.y, hr43.w, (last)hr23.y
mad.f16 hr19.y, hr6.y, hr42.x, (last)hr19.y
mad.f16 hr15.y, hr6.y, hr42.y, (last)hr15.y
mad.f16 hr11.y, hr6.y, hr42.z, (last)hr11.y
mad.f16 hr35.z, hr6.z, hr43.x, (last)hr35.z
mad.f16 hr31.z, hr6.z, hr43.y, (last)hr31.z
mad.f16 hr27.z, hr6.z, hr43.z, (last)hr27.z
mad.f16 hr23.z, hr6.z, hr43.w, (last)hr23.z
mad.f16 hr19.z, hr6.z, hr42.x, (last)hr19.z
mad.f16 hr15.z, hr6.z, hr42.y, (last)hr15.z
mad.f16 hr11.z, hr6.z, hr42.z, (last)hr11.z
mad.f16 hr35.w, hr6.w, hr43.x, (last)hr35.w
mad.f16 hr31.w, hr6.w, hr43.y, (last)hr31.w
mad.f16 hr27.w, hr6.w, hr43.z, (last)hr27.w
mad.f16 hr23.w, hr6.w, hr43.w, (last)hr23.w
mad.f16 hr19.w, hr6.w, hr42.x, (last)hr19.w
mad.f16 hr15.w, hr6.w, hr42.y, (last)hr15.w
mad.f16 hr11.w, hr6.w, hr42.z, (last)hr11.w
(rpt1)mad.f16 hr6.x, (r)(last)hr6.x, hr42.w, (r)(last)hr44.x
(rpt1)mad.f16 hr6.z, (r)(last)hr6.z, hr42.w, (r)(last)hr44.z
isam.v.base0 (u16)(xyzw)hr44.x, r27.x, s#0, t#2
(sy)mad.f16 hr34.x, hr44.x, hr43.x, (last)hr34.x
mad.f16 hr30.x, hr44.x, hr43.y, (last)hr30.x
mad.f16 hr26.x, hr44.x, hr43.z, (last)hr26.x
mad.f16 hr22.x, hr44.x, hr43.w, (last)hr22.x
mad.f16 hr18.x, hr44.x, hr42.x, (last)hr18.x
mad.f16 hr14.x, hr44.x, hr42.y, (last)hr14.x
mad.f16 hr10.x, hr44.x, hr42.z, (last)hr10.x
mad.f16 hr34.y, hr44.y, hr43.x, (last)hr34.y
mad.f16 hr30.y, hr44.y, hr43.y, (last)hr30.y
mad.f16 hr26.y, hr44.y, hr43.z, (last)hr26.y
mad.f16 hr22.y, hr44.y, hr43.w, (last)hr22.y
mad.f16 hr18.y, hr44.y, hr42.x, (last)hr18.y
mad.f16 hr14.y, hr44.y, hr42.y, (last)hr14.y
mad.f16 hr10.y, hr44.y, hr42.z, (last)hr10.y
mad.f16 hr34.z, hr44.z, hr43.x, (last)hr34.z
mad.f16 hr30.z, hr44.z, hr43.y, (last)hr30.z
mad.f16 hr26.z, hr44.z, hr43.z, (last)hr26.z
mad.f16 hr22.z, hr44.z, hr43.w, (last)hr22.z
mad.f16 hr18.z, hr44.z, hr42.x, (last)hr18.z
mad.f16 hr14.z, hr44.z, hr42.y, (last)hr14.z
mad.f16 hr10.z, hr44.z, hr42.z, (last)hr10.z
(rpt1)mad.f16 hr44.x, (r)(last)hr44.x, hr42.w, (r)(last)hr46.w
mad.f16 hr44.z, (last)hr44.z, hr42.w, (last)hr47.y
isam.v.base0 (u16)(xyzw)hr46.z, r27.y, s#0, t#2
mad.f16 hr34.w, hr44.w, hr43.x, (last)hr34.w
mad.f16 hr30.w, hr44.w, hr43.y, (last)hr30.w
mad.f16 hr26.w, hr44.w, hr43.z, (last)hr26.w
mad.f16 hr22.w, hr44.w, hr43.w, (last)hr22.w
mad.f16 hr18.w, hr44.w, hr42.x, (last)hr18.w
mad.f16 hr14.w, hr44.w, hr42.y, (last)hr14.w
mad.f16 hr10.w, hr44.w, hr42.z, (last)hr10.w
mad.f16 hr44.w, (last)hr44.w, hr42.w, (last)hr47.z
(sy)mad.f16 hr33.x, hr46.z, hr43.x, (last)hr33.x
mad.f16 hr29.x, hr46.z, hr43.y, (last)hr29.x
mad.f16 hr25.x, hr46.z, hr43.z, (last)hr25.x
mad.f16 hr21.x, hr46.z, hr43.w, (last)hr21.x
mad.f16 hr17.x, hr46.z, hr42.x, (last)hr17.x
mad.f16 hr13.x, hr46.z, hr42.y, (last)hr13.x
mad.f16 hr9.x, hr46.z, hr42.z, (last)hr9.x
mad.f16 hr33.y, hr46.w, hr43.x, (last)hr33.y
mad.f16 hr29.y, hr46.w, hr43.y, (last)hr29.y
mad.f16 hr25.y, hr46.w, hr43.z, (last)hr25.y
mad.f16 hr21.y, hr46.w, hr43.w, (last)hr21.y
mad.f16 hr17.y, hr46.w, hr42.x, (last)hr17.y
mad.f16 hr13.y, hr46.w, hr42.y, (last)hr13.y
mad.f16 hr9.y, hr46.w, hr42.z, (last)hr9.y
mad.f16 hr33.z, hr47.x, hr43.x, (last)hr33.z
mad.f16 hr29.z, hr47.x, hr43.y, (last)hr29.z
mad.f16 hr25.z, hr47.x, hr43.z, (last)hr25.z
mad.f16 hr21.z, hr47.x, hr43.w, (last)hr21.z
mad.f16 hr17.z, hr47.x, hr42.x, (last)hr17.z
mad.f16 hr13.z, hr47.x, hr42.y, (last)hr13.z
mad.f16 hr9.z, hr47.x, hr42.z, (last)hr9.z
mad.f16 hr33.w, hr47.y, hr43.x, (last)hr33.w
mad.f16 hr29.w, hr47.y, hr43.y, (last)hr29.w
mad.f16 hr25.w, hr47.y, hr43.z, (last)hr25.w
mad.f16 hr21.w, hr47.y, hr43.w, (last)hr21.w
mad.f16 hr17.w, hr47.y, hr42.x, (last)hr17.w
mad.f16 hr13.w, hr47.y, hr42.y, (last)hr13.w
mad.f16 hr9.w, hr47.y, hr42.z, (last)hr9.w
(rpt1)mad.f16 hr46.z, (r)(last)hr46.z, hr42.w, (r)(last)hr7.x
(rpt1)mad.f16 hr47.x, (r)(last)hr47.x, hr42.w, (r)(last)hr7.z
isam.v.base0 (u16)(xyzw)hr7.x, r27.z, s#0, t#2
(sy)mad.f16 hr32.x, hr7.x, hr43.x, (last)hr32.x
mad.f16 hr28.x, hr7.x, hr43.y, (last)hr28.x
mad.f16 hr24.x, hr7.x, hr43.z, (last)hr24.x
mad.f16 hr20.x, hr7.x, hr43.w, (last)hr20.x
mad.f16 hr16.x, hr7.x, hr42.x, (last)hr16.x
mad.f16 hr12.x, hr7.x, hr42.y, (last)hr12.x
mad.f16 hr8.x, hr7.x, hr42.z, (last)hr8.x
mad.f16 hr32.y, hr7.y, hr43.x, (last)hr32.y
mad.f16 hr28.y, hr7.y, hr43.y, (last)hr28.y
mad.f16 hr24.y, hr7.y, hr43.z, (last)hr24.y
mad.f16 hr20.y, hr7.y, hr43.w, (last)hr20.y
mad.f16 hr16.y, hr7.y, hr42.x, (last)hr16.y
mad.f16 hr12.y, hr7.y, hr42.y, (last)hr12.y
mad.f16 hr8.y, hr7.y, hr42.z, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr7.z, hr43.x, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr7.z, hr43.y, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr7.z, hr43.z, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr7.z, hr43.w, (r)(last)hr20.z
(rpt1)mad.f16 hr16.z, (r)hr7.z, hr42.x, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr7.z, hr42.y, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr7.z, hr42.z, (r)(last)hr8.z
(rpt1)mad.f16 hr7.x, (r)(last)hr7.x, hr42.w, (r)(last)hr5.x
(rpt1)mad.f16 hr7.z, (r)(last)hr7.z, hr42.w, (r)(last)hr5.z
isam.v.base0 (u16)(xyzw)hr42.y, r27.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr5.x, r28.x, s#0, t#2
(sy)mad.f16 hr35.x, hr42.y, hr1.z, (last)hr35.x
mad.f16 hr31.x, hr42.y, hr1.w, (last)hr31.x
mad.f16 hr27.x, hr42.y, hr2.x, (last)hr27.x
mad.f16 hr23.x, hr42.y, hr2.y, (last)hr23.x
mad.f16 hr19.x, hr42.y, hr2.z, (last)hr19.x
mad.f16 hr15.x, hr42.y, hr2.w, (last)hr15.x
mad.f16 hr11.x, hr42.y, hr3.x, (last)hr11.x
mad.f16 hr35.y, hr42.z, hr1.z, (last)hr35.y
mad.f16 hr31.y, hr42.z, hr1.w, (last)hr31.y
mad.f16 hr27.y, hr42.z, hr2.x, (last)hr27.y
mad.f16 hr23.y, hr42.z, hr2.y, (last)hr23.y
mad.f16 hr19.y, hr42.z, hr2.z, (last)hr19.y
mad.f16 hr15.y, hr42.z, hr2.w, (last)hr15.y
mad.f16 hr11.y, hr42.z, hr3.x, (last)hr11.y
mad.f16 hr35.z, hr42.w, hr1.z, (last)hr35.z
mad.f16 hr31.z, hr42.w, hr1.w, (last)hr31.z
mad.f16 hr27.z, hr42.w, hr2.x, (last)hr27.z
mad.f16 hr23.z, hr42.w, hr2.y, (last)hr23.z
mad.f16 hr19.z, hr42.w, hr2.z, (last)hr19.z
mad.f16 hr15.z, hr42.w, hr2.w, (last)hr15.z
mad.f16 hr11.z, hr42.w, hr3.x, (last)hr11.z
mad.f16 hr35.w, hr43.x, hr1.z, (last)hr35.w
mad.f16 hr31.w, hr43.x, hr1.w, (last)hr31.w
mad.f16 hr27.w, hr43.x, hr2.x, (last)hr27.w
mad.f16 hr23.w, hr43.x, hr2.y, (last)hr23.w
mad.f16 hr19.w, hr43.x, hr2.z, (last)hr19.w
mad.f16 hr15.w, hr43.x, hr2.w, (last)hr15.w
mad.f16 hr11.w, hr43.x, hr3.x, (last)hr11.w
(rpt1)mad.f16 hr42.y, (r)(last)hr42.y, hr3.y, (r)(last)hr6.x
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr3.y, (r)(last)hr6.z
isam.v.base0 (u16)(xyzw)hr6.x, r28.y, s#0, t#2
mad.f16 hr34.x, hr5.x, hr1.z, (last)hr34.x
mad.f16 hr30.x, hr5.x, hr1.w, (last)hr30.x
mad.f16 hr26.x, hr5.x, hr2.x, (last)hr26.x
mad.f16 hr22.x, hr5.x, hr2.y, (last)hr22.x
mad.f16 hr18.x, hr5.x, hr2.z, (last)hr18.x
mad.f16 hr14.x, hr5.x, hr2.w, (last)hr14.x
mad.f16 hr10.x, hr5.x, hr3.x, (last)hr10.x
mad.f16 hr5.x, (last)hr5.x, hr3.y, (last)hr44.x
isam.v.base0 (u16)(xyzw)hr43.y, r28.z, s#0, t#2
mad.f16 hr34.y, hr5.y, hr1.z, (last)hr34.y
mad.f16 hr30.y, hr5.y, hr1.w, (last)hr30.y
mad.f16 hr26.y, hr5.y, hr2.x, (last)hr26.y
mad.f16 hr22.y, hr5.y, hr2.y, (last)hr22.y
mad.f16 hr34.z, hr5.z, hr1.z, (last)hr34.z
mad.f16 hr30.z, hr5.z, hr1.w, (last)hr30.z
mad.f16 hr26.z, hr5.z, hr2.x, (last)hr26.z
mad.f16 hr22.z, hr5.z, hr2.y, (last)hr22.z
mad.f16 hr34.w, hr5.w, hr1.z, (last)hr34.w
mad.f16 hr30.w, hr5.w, hr1.w, (last)hr30.w
mad.f16 hr26.w, hr5.w, hr2.x, (last)hr26.w
mad.f16 hr22.w, hr5.w, hr2.y, (last)hr22.w
mad.f16 hr18.y, hr5.y, hr2.z, (last)hr18.y
mad.f16 hr14.y, hr5.y, hr2.w, (last)hr14.y
mad.f16 hr10.y, hr5.y, hr3.x, (last)hr10.y
mad.f16 hr18.z, hr5.z, hr2.z, (last)hr18.z
mad.f16 hr14.z, hr5.z, hr2.w, (last)hr14.z
mad.f16 hr10.z, hr5.z, hr3.x, (last)hr10.z
mad.f16 hr18.w, hr5.w, hr2.z, (last)hr18.w
mad.f16 hr14.w, hr5.w, hr2.w, (last)hr14.w
mad.f16 hr10.w, hr5.w, hr3.x, (last)hr10.w
mad.f16 hr5.y, (last)hr5.y, hr3.y, (last)hr44.y
(rpt1)mad.f16 hr5.z, (r)(last)hr5.z, hr3.y, (r)(last)hr44.z
(sy)mad.f16 hr33.y, hr6.y, hr1.z, (last)hr33.y
mad.f16 hr29.y, hr6.y, hr1.w, (last)hr29.y
mad.f16 hr25.y, hr6.y, hr2.x, (last)hr25.y
mad.f16 hr21.y, hr6.y, hr2.y, (last)hr21.y
mad.f16 hr17.y, hr6.y, hr2.z, (last)hr17.y
mad.f16 hr13.y, hr6.y, hr2.w, (last)hr13.y
mad.f16 hr9.y, hr6.y, hr3.x, (last)hr9.y
mad.f16 hr33.z, hr6.z, hr1.z, (last)hr33.z
mad.f16 hr29.z, hr6.z, hr1.w, (last)hr29.z
mad.f16 hr25.z, hr6.z, hr2.x, (last)hr25.z
mad.f16 hr21.z, hr6.z, hr2.y, (last)hr21.z
mad.f16 hr17.z, hr6.z, hr2.z, (last)hr17.z
mad.f16 hr13.z, hr6.z, hr2.w, (last)hr13.z
mad.f16 hr9.z, hr6.z, hr3.x, (last)hr9.z
mad.f16 hr33.w, hr6.w, hr1.z, (last)hr33.w
mad.f16 hr29.w, hr6.w, hr1.w, (last)hr29.w
mad.f16 hr25.w, hr6.w, hr2.x, (last)hr25.w
mad.f16 hr21.w, hr6.w, hr2.y, (last)hr21.w
mad.f16 hr17.w, hr6.w, hr2.z, (last)hr17.w
mad.f16 hr13.w, hr6.w, hr2.w, (last)hr13.w
mad.f16 hr9.w, hr6.w, hr3.x, (last)hr9.w
mad.f16 hr6.y, (last)hr6.y, hr3.y, (last)hr46.w
(rpt1)mad.f16 hr6.z, (r)(last)hr6.z, hr3.y, (r)(last)hr47.x
isam.v.base0 (u16)(xyzw)hr46.w, r28.w, s#0, t#2
mad.f16 hr33.x, hr6.x, hr1.z, (last)hr33.x
mad.f16 hr29.x, hr6.x, hr1.w, (last)hr29.x
mad.f16 hr25.x, hr6.x, hr2.x, (last)hr25.x
mad.f16 hr21.x, hr6.x, hr2.y, (last)hr21.x
mad.f16 hr32.x, hr43.y, hr1.z, (last)hr32.x
mad.f16 hr28.x, hr43.y, hr1.w, (last)hr28.x
mad.f16 hr24.x, hr43.y, hr2.x, (last)hr24.x
mad.f16 hr20.x, hr43.y, hr2.y, (last)hr20.x
mad.f16 hr32.y, hr43.z, hr1.z, (last)hr32.y
mad.f16 hr28.y, hr43.z, hr1.w, (last)hr28.y
mad.f16 hr24.y, hr43.z, hr2.x, (last)hr24.y
mad.f16 hr20.y, hr43.z, hr2.y, (last)hr20.y
(rpt1)mad.f16 hr32.z, (r)hr43.w, hr1.z, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr43.w, hr1.w, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr43.w, hr2.x, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr43.w, hr2.y, (r)(last)hr20.z
isam.v.base0 (u16)(xyzw)hr1.z, r29.x, s#0, t#2
mad.f16 hr16.x, hr43.y, hr2.z, (last)hr16.x
mad.f16 hr12.x, hr43.y, hr2.w, (last)hr12.x
mad.f16 hr8.x, hr43.y, hr3.x, (last)hr8.x
mad.f16 hr43.y, (last)hr43.y, hr3.y, (last)hr7.x
mad.f16 hr17.x, hr6.x, hr2.z, (last)hr17.x
mad.f16 hr13.x, hr6.x, hr2.w, (last)hr13.x
mad.f16 hr9.x, hr6.x, hr3.x, (last)hr9.x
mad.f16 hr16.y, hr43.z, hr2.z, (last)hr16.y
mad.f16 hr12.y, hr43.z, hr2.w, (last)hr12.y
mad.f16 hr8.y, hr43.z, hr3.x, (last)hr8.y
(rpt1)mad.f16 hr16.z, (r)hr43.w, hr2.z, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr43.w, hr2.w, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr43.w, hr3.x, (r)(last)hr8.z
mad.f16 hr6.x, (last)hr6.x, hr3.y, (last)hr46.z
mad.f16 hr43.z, (last)hr43.z, hr3.y, (last)hr7.y
(rpt1)mad.f16 hr43.w, (r)(last)hr43.w, hr3.y, (r)(last)hr7.z
ldl.u16 r2.z, l[r24.z+2944], 4
(sy)mad.f16 hr35.x, hr46.w, hr37.x, (last)hr35.x
mad.f16 hr31.x, hr46.w, hr37.y, (last)hr31.x
mad.f16 hr27.x, hr46.w, hr37.z, (last)hr27.x
mad.f16 hr23.x, hr46.w, hr37.w, (last)hr23.x
mad.f16 hr19.x, hr46.w, hr0.z, (last)hr19.x
mad.f16 hr15.x, hr46.w, hr0.w, (last)hr15.x
mad.f16 hr11.x, hr46.w, hr1.x, (last)hr11.x
mad.f16 hr35.y, hr47.x, hr37.x, (last)hr35.y
mad.f16 hr31.y, hr47.x, hr37.y, (last)hr31.y
mad.f16 hr27.y, hr47.x, hr37.z, (last)hr27.y
mad.f16 hr23.y, hr47.x, hr37.w, (last)hr23.y
mad.f16 hr19.y, hr47.x, hr0.z, (last)hr19.y
mad.f16 hr15.y, hr47.x, hr0.w, (last)hr15.y
mad.f16 hr11.y, hr47.x, hr1.x, (last)hr11.y
mad.f16 hr35.z, hr47.y, hr37.x, (last)hr35.z
mad.f16 hr31.z, hr47.y, hr37.y, (last)hr31.z
mad.f16 hr27.z, hr47.y, hr37.z, (last)hr27.z
mad.f16 hr23.z, hr47.y, hr37.w, (last)hr23.z
mad.f16 hr19.z, hr47.y, hr0.z, (last)hr19.z
mad.f16 hr15.z, hr47.y, hr0.w, (last)hr15.z
mad.f16 hr11.z, hr47.y, hr1.x, (last)hr11.z
mad.f16 hr35.w, hr47.z, hr37.x, (last)hr35.w
mad.f16 hr31.w, hr47.z, hr37.y, (last)hr31.w
mad.f16 hr27.w, hr47.z, hr37.z, (last)hr27.w
mad.f16 hr23.w, hr47.z, hr37.w, (last)hr23.w
mad.f16 hr19.w, hr47.z, hr0.z, (last)hr19.w
mad.f16 hr15.w, hr47.z, hr0.w, (last)hr15.w
mad.f16 hr11.w, hr47.z, hr1.x, (last)hr11.w
(rpt1)mad.f16 hr46.w, (r)(last)hr46.w, hr1.y, (r)(last)hr42.y
(rpt1)mad.f16 hr47.y, (r)(last)hr47.y, hr1.y, (r)(last)hr42.w
isam.v.base0 (u16)(xyzw)hr42.y, r29.y, s#0, t#2
mad.f16 hr34.x, hr1.z, hr37.x, (last)hr34.x
mad.f16 hr30.x, hr1.z, hr37.y, (last)hr30.x
mad.f16 hr26.x, hr1.z, hr37.z, (last)hr26.x
mad.f16 hr22.x, hr1.z, hr37.w, (last)hr22.x
mad.f16 hr18.x, hr1.z, hr0.z, (last)hr18.x
mad.f16 hr14.x, hr1.z, hr0.w, (last)hr14.x
mad.f16 hr10.x, hr1.z, hr1.x, (last)hr10.x
mad.f16 hr34.y, hr1.w, hr37.x, (last)hr34.y
mad.f16 hr30.y, hr1.w, hr37.y, (last)hr30.y
mad.f16 hr26.y, hr1.w, hr37.z, (last)hr26.y
mad.f16 hr22.y, hr1.w, hr37.w, (last)hr22.y
mad.f16 hr18.y, hr1.w, hr0.z, (last)hr18.y
mad.f16 hr14.y, hr1.w, hr0.w, (last)hr14.y
mad.f16 hr10.y, hr1.w, hr1.x, (last)hr10.y
mad.f16 hr34.z, hr2.x, hr37.x, (last)hr34.z
mad.f16 hr30.z, hr2.x, hr37.y, (last)hr30.z
mad.f16 hr26.z, hr2.x, hr37.z, (last)hr26.z
mad.f16 hr22.z, hr2.x, hr37.w, (last)hr22.z
mad.f16 hr18.z, hr2.x, hr0.z, (last)hr18.z
mad.f16 hr14.z, hr2.x, hr0.w, (last)hr14.z
mad.f16 hr10.z, hr2.x, hr1.x, (last)hr10.z
mad.f16 hr34.w, hr2.y, hr37.x, (last)hr34.w
mad.f16 hr30.w, hr2.y, hr37.y, (last)hr30.w
mad.f16 hr26.w, hr2.y, hr37.z, (last)hr26.w
mad.f16 hr22.w, hr2.y, hr37.w, (last)hr22.w
mad.f16 hr18.w, hr2.y, hr0.z, (last)hr18.w
mad.f16 hr14.w, hr2.y, hr0.w, (last)hr14.w
mad.f16 hr10.w, hr2.y, hr1.x, (last)hr10.w
(rpt1)mad.f16 hr1.z, (r)(last)hr1.z, hr1.y, (r)(last)hr5.x
(rpt1)mad.f16 hr2.x, (r)(last)hr2.x, hr1.y, (r)(last)hr5.z
ldl.u16 r5.x, l[r24.z+3072], 4
(sy)mad.f16 hr33.y, hr42.z, hr37.x, (last)hr33.y
mad.f16 hr29.y, hr42.z, hr37.y, (last)hr29.y
mad.f16 hr25.y, hr42.z, hr37.z, (last)hr25.y
mad.f16 hr21.y, hr42.z, hr37.w, (last)hr21.y
mad.f16 hr17.y, hr42.z, hr0.z, (last)hr17.y
mad.f16 hr13.y, hr42.z, hr0.w, (last)hr13.y
mad.f16 hr9.y, hr42.z, hr1.x, (last)hr9.y
mad.f16 hr33.z, hr42.w, hr37.x, (last)hr33.z
mad.f16 hr29.z, hr42.w, hr37.y, (last)hr29.z
mad.f16 hr25.z, hr42.w, hr37.z, (last)hr25.z
mad.f16 hr21.z, hr42.w, hr37.w, (last)hr21.z
mad.f16 hr17.z, hr42.w, hr0.z, (last)hr17.z
mad.f16 hr13.z, hr42.w, hr0.w, (last)hr13.z
mad.f16 hr9.z, hr42.w, hr1.x, (last)hr9.z
mad.f16 hr33.w, hr43.x, hr37.x, (last)hr33.w
mad.f16 hr29.w, hr43.x, hr37.y, (last)hr29.w
mad.f16 hr25.w, hr43.x, hr37.z, (last)hr25.w
mad.f16 hr21.w, hr43.x, hr37.w, (last)hr21.w
mad.f16 hr17.w, hr43.x, hr0.z, (last)hr17.w
mad.f16 hr13.w, hr43.x, hr0.w, (last)hr13.w
mad.f16 hr9.w, hr43.x, hr1.x, (last)hr9.w
mad.f16 hr42.z, (last)hr42.z, hr1.y, (last)hr6.y
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr1.y, (r)(last)hr6.z
isam.v.base0 (u16)(xyzw)hr6.y, r29.z, s#0, t#2
mad.f16 hr33.x, hr42.y, hr37.x, (last)hr33.x
mad.f16 hr29.x, hr42.y, hr37.y, (last)hr29.x
mad.f16 hr25.x, hr42.y, hr37.z, (last)hr25.x
mad.f16 hr21.x, hr42.y, hr37.w, (last)hr21.x
mad.f16 hr17.x, hr42.y, hr0.z, (last)hr17.x
mad.f16 hr13.x, hr42.y, hr0.w, (last)hr13.x
mad.f16 hr9.x, hr42.y, hr1.x, (last)hr9.x
mad.f16 hr42.y, (last)hr42.y, hr1.y, (last)hr6.x
(sy)mov.u16u16 hr0.x, (last)hr7.x
ldl.u16 r7.x, l[r24.z+3200], 4
mad.f16 hr32.x, hr6.y, hr37.x, (last)hr32.x
mad.f16 hr28.x, hr6.y, hr37.y, (last)hr28.x
mad.f16 hr24.x, hr6.y, hr37.z, (last)hr24.x
mad.f16 hr20.x, hr6.y, hr37.w, (last)hr20.x
mad.f16 hr16.x, hr6.y, hr0.z, (last)hr16.x
mad.f16 hr12.x, hr6.y, hr0.w, (last)hr12.x
mad.f16 hr8.x, hr6.y, hr1.x, (last)hr8.x
mad.f16 hr32.y, hr6.z, hr37.x, (last)hr32.y
mad.f16 hr28.y, hr6.z, hr37.y, (last)hr28.y
mad.f16 hr24.y, hr6.z, hr37.z, (last)hr24.y
mad.f16 hr20.y, hr6.z, hr37.w, (last)hr20.y
mad.f16 hr16.y, hr6.z, hr0.z, (last)hr16.y
mad.f16 hr12.y, hr6.z, hr0.w, (last)hr12.y
mad.f16 hr8.y, hr6.z, hr1.x, (last)hr8.y
mad.f16 hr32.z, hr6.w, hr37.x, (last)hr32.z
mad.f16 hr28.z, hr6.w, hr37.y, (last)hr28.z
mad.f16 hr24.z, hr6.w, hr37.z, (last)hr24.z
mad.f16 hr20.z, hr6.w, hr37.w, (last)hr20.z
mad.f16 hr16.z, hr6.w, hr0.z, (last)hr16.z
mad.f16 hr12.z, hr6.w, hr0.w, (last)hr12.z
mad.f16 hr8.z, hr6.w, hr1.x, (last)hr8.z
mad.f16 hr32.w, hr0.x, hr37.x, (last)hr32.w
mad.f16 hr28.w, hr0.x, hr37.y, (last)hr28.w
mad.f16 hr24.w, hr0.x, hr37.z, (last)hr24.w
mad.f16 hr20.w, hr0.x, hr37.w, (last)hr20.w
isam.v.base0 (u16)(xyzw)hr37.x, r29.w, s#0, t#2
mad.f16 hr16.w, hr0.x, hr0.z, (last)hr16.w
mad.f16 hr12.w, hr0.x, hr0.w, (last)hr12.w
mad.f16 hr8.w, hr0.x, hr1.x, (last)hr8.w
isam.v.base0 (u16)(xyzw)hr0.y, r30.x, s#0, t#2
(rpt1)mad.f16 hr6.y, (r)(last)hr6.y, hr1.y, (r)(last)hr43.y
mad.f16 hr6.w, (last)hr6.w, hr1.y, (last)hr43.w
mad.f16 hr0.x, (last)hr0.x, hr1.y, (last)hr44.x
ldl.u16 r43.y, l[r24.z+3328], 4
(sy)mad.f16 hr34.x, hr0.y, hr38.x, (last)hr34.x
mad.f16 hr30.x, hr0.y, hr38.y, (last)hr30.x
mad.f16 hr26.x, hr0.y, hr38.z, (last)hr26.x
mad.f16 hr22.x, hr0.y, hr38.w, (last)hr22.x
mad.f16 hr18.x, hr0.y, hr39.x, (last)hr18.x
mad.f16 hr14.x, hr0.y, hr39.y, (last)hr14.x
mad.f16 hr10.x, hr0.y, hr39.z, (last)hr10.x
mad.f16 hr34.y, hr0.z, hr38.x, (last)hr34.y
mad.f16 hr30.y, hr0.z, hr38.y, (last)hr30.y
mad.f16 hr26.y, hr0.z, hr38.z, (last)hr26.y
mad.f16 hr22.y, hr0.z, hr38.w, (last)hr22.y
mad.f16 hr18.y, hr0.z, hr39.x, (last)hr18.y
mad.f16 hr14.y, hr0.z, hr39.y, (last)hr14.y
mad.f16 hr10.y, hr0.z, hr39.z, (last)hr10.y
mad.f16 hr34.z, hr0.w, hr38.x, (last)hr34.z
mad.f16 hr30.z, hr0.w, hr38.y, (last)hr30.z
mad.f16 hr26.z, hr0.w, hr38.z, (last)hr26.z
mad.f16 hr22.z, hr0.w, hr38.w, (last)hr22.z
mad.f16 hr18.z, hr0.w, hr39.x, (last)hr18.z
mad.f16 hr14.z, hr0.w, hr39.y, (last)hr14.z
mad.f16 hr10.z, hr0.w, hr39.z, (last)hr10.z
(rpt1)mad.f16 hr0.y, (r)(last)hr0.y, hr39.w, (r)(last)hr1.z
mad.f16 hr0.w, (last)hr0.w, hr39.w, (last)hr2.x
isam.v.base0 (u16)(xyzw)hr1.y, r30.y, s#0, t#2
mad.f16 hr35.x, hr37.x, hr38.x, (last)hr35.x
mad.f16 hr31.x, hr37.x, hr38.y, (last)hr31.x
mad.f16 hr27.x, hr37.x, hr38.z, (last)hr27.x
mad.f16 hr23.x, hr37.x, hr38.w, (last)hr23.x
mad.f16 hr35.y, hr37.y, hr38.x, (last)hr35.y
mad.f16 hr31.y, hr37.y, hr38.y, (last)hr31.y
mad.f16 hr27.y, hr37.y, hr38.z, (last)hr27.y
mad.f16 hr23.y, hr37.y, hr38.w, (last)hr23.y
mad.f16 hr35.z, hr37.z, hr38.x, (last)hr35.z
mad.f16 hr31.z, hr37.z, hr38.y, (last)hr31.z
mad.f16 hr27.z, hr37.z, hr38.z, (last)hr27.z
mad.f16 hr23.z, hr37.z, hr38.w, (last)hr23.z
mad.f16 hr35.w, hr37.w, hr38.x, (last)hr35.w
mad.f16 hr31.w, hr37.w, hr38.y, (last)hr31.w
mad.f16 hr27.w, hr37.w, hr38.z, (last)hr27.w
mad.f16 hr23.w, hr37.w, hr38.w, (last)hr23.w
mad.f16 hr34.w, hr1.x, hr38.x, (last)hr34.w
mad.f16 hr30.w, hr1.x, hr38.y, (last)hr30.w
mad.f16 hr26.w, hr1.x, hr38.z, (last)hr26.w
mad.f16 hr22.w, hr1.x, hr38.w, (last)hr22.w
mad.f16 hr19.x, hr37.x, hr39.x, (last)hr19.x
mad.f16 hr15.x, hr37.x, hr39.y, (last)hr15.x
mad.f16 hr11.x, hr37.x, hr39.z, (last)hr11.x
mad.f16 hr19.y, hr37.y, hr39.x, (last)hr19.y
mad.f16 hr15.y, hr37.y, hr39.y, (last)hr15.y
mad.f16 hr11.y, hr37.y, hr39.z, (last)hr11.y
mad.f16 hr19.z, hr37.z, hr39.x, (last)hr19.z
mad.f16 hr15.z, hr37.z, hr39.y, (last)hr15.z
mad.f16 hr11.z, hr37.z, hr39.z, (last)hr11.z
mad.f16 hr19.w, hr37.w, hr39.x, (last)hr19.w
mad.f16 hr15.w, hr37.w, hr39.y, (last)hr15.w
mad.f16 hr11.w, hr37.w, hr39.z, (last)hr11.w
(rpt1)mad.f16 hr37.x, (r)(last)hr37.x, hr39.w, (r)(last)hr46.w
mad.f16 hr37.z, (last)hr37.z, hr39.w, (last)hr47.y
ldl.u16 r46.z, l[r24.z+3456], 4
mad.f16 hr37.w, (last)hr37.w, hr39.w, (last)hr47.z
mad.f16 hr18.w, hr1.x, hr39.x, (last)hr18.w
mad.f16 hr14.w, hr1.x, hr39.y, (last)hr14.w
(sy)mad.f16 hr33.x, hr1.y, hr38.x, (last)hr33.x
mad.f16 hr29.x, hr1.y, hr38.y, (last)hr29.x
mad.f16 hr25.x, hr1.y, hr38.z, (last)hr25.x
mad.f16 hr21.x, hr1.y, hr38.w, (last)hr21.x
mad.f16 hr17.x, hr1.y, hr39.x, (last)hr17.x
mad.f16 hr13.x, hr1.y, hr39.y, (last)hr13.x
mad.f16 hr9.x, hr1.y, hr39.z, (last)hr9.x
mad.f16 hr33.y, hr1.z, hr38.x, (last)hr33.y
mad.f16 hr29.y, hr1.z, hr38.y, (last)hr29.y
mad.f16 hr25.y, hr1.z, hr38.z, (last)hr25.y
mad.f16 hr21.y, hr1.z, hr38.w, (last)hr21.y
mad.f16 hr17.y, hr1.z, hr39.x, (last)hr17.y
mad.f16 hr13.y, hr1.z, hr39.y, (last)hr13.y
mad.f16 hr9.y, hr1.z, hr39.z, (last)hr9.y
mad.f16 hr33.z, hr1.w, hr38.x, (last)hr33.z
mad.f16 hr29.z, hr1.w, hr38.y, (last)hr29.z
mad.f16 hr25.z, hr1.w, hr38.z, (last)hr25.z
mad.f16 hr21.z, hr1.w, hr38.w, (last)hr21.z
mad.f16 hr17.z, hr1.w, hr39.x, (last)hr17.z
mad.f16 hr13.z, hr1.w, hr39.y, (last)hr13.z
mad.f16 hr9.z, hr1.w, hr39.z, (last)hr9.z
(rpt1)mad.f16 hr1.y, (r)(last)hr1.y, hr39.w, (r)(last)hr42.y
mad.f16 hr1.w, (last)hr1.w, hr39.w, (last)hr42.w
isam.v.base0 (u16)(xyzw)hr42.x, r30.z, s#0, t#2
mad.f16 hr33.w, hr2.x, hr38.x, (last)hr33.w
mad.f16 hr29.w, hr2.x, hr38.y, (last)hr29.w
mad.f16 hr25.w, hr2.x, hr38.z, (last)hr25.w
mad.f16 hr21.w, hr2.x, hr38.w, (last)hr21.w
mad.f16 hr10.w, hr1.x, hr39.z, (last)hr10.w
mad.f16 hr1.x, (last)hr1.x, hr39.w, (last)hr2.y
mad.f16 hr17.w, hr2.x, hr39.x, (last)hr17.w
mad.f16 hr13.w, hr2.x, hr39.y, (last)hr13.w
mad.f16 hr9.w, hr2.x, hr39.z, (last)hr9.w
mad.f16 hr2.x, (last)hr2.x, hr39.w, (last)hr43.x
(ss)mov.u16u16 hr6.x, (last)hr47.x
mov.u16u16 hr2.y, (last)hr44.x
ldl.u16 r44.x, l[r24.z+3584], 4
mov.u16u16 hr43.x, (last)hr47.y
ldl.u16 r47.x, l[r24.z+3712], 4
(sy)mad.f16 hr32.x, hr42.x, hr38.x, (last)hr32.x
mad.f16 hr28.x, hr42.x, hr38.y, (last)hr28.x
mad.f16 hr24.x, hr42.x, hr38.z, (last)hr24.x
mad.f16 hr20.x, hr42.x, hr38.w, (last)hr20.x
mad.f16 hr32.y, hr42.y, hr38.x, (last)hr32.y
mad.f16 hr28.y, hr42.y, hr38.y, (last)hr28.y
mad.f16 hr24.y, hr42.y, hr38.z, (last)hr24.y
mad.f16 hr20.y, hr42.y, hr38.w, (last)hr20.y
(rpt1)mad.f16 hr32.z, (r)hr42.z, hr38.x, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr42.z, hr38.y, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr42.z, hr38.z, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr42.z, hr38.w, (r)(last)hr20.z
isam.v.base0 (u16)(xyzw)hr38.x, r30.w, s#0, t#2
mad.f16 hr16.w, hr42.w, hr39.x, (last)hr16.w
mad.f16 hr12.w, hr42.w, hr39.y, (last)hr12.w
mad.f16 hr8.w, hr42.w, hr39.z, (last)hr8.w
mad.f16 hr42.w, (last)hr42.w, hr39.w, (last)hr0.x
mad.f16 hr16.x, hr42.x, hr39.x, (last)hr16.x
mad.f16 hr12.x, hr42.x, hr39.y, (last)hr12.x
mad.f16 hr8.x, hr42.x, hr39.z, (last)hr8.x
mad.f16 hr16.y, hr42.y, hr39.x, (last)hr16.y
mad.f16 hr12.y, hr42.y, hr39.y, (last)hr12.y
mad.f16 hr8.y, hr42.y, hr39.z, (last)hr8.y
mad.f16 hr16.z, hr42.z, hr39.x, (last)hr16.z
mad.f16 hr12.z, hr42.z, hr39.y, (last)hr12.z
mad.f16 hr8.z, hr42.z, hr39.z, (last)hr8.z
(rpt1)mad.f16 hr42.x, (r)(last)hr42.x, hr39.w, (r)(last)hr6.y
mad.f16 hr42.z, (last)hr42.z, hr39.w, (last)hr6.w
ldl.u16 r39.x, l[r24.z+3840], 4
(sy)mad.f16 hr35.x, hr38.x, hr45.z, (last)hr35.x
mad.f16 hr31.x, hr38.x, hr45.w, (last)hr31.x
mad.f16 hr27.x, hr38.x, hr46.x, (last)hr27.x
mad.f16 hr23.x, hr38.x, hr46.y, (last)hr23.x
mad.f16 hr19.x, hr38.x, hr4.x, (last)hr19.x
mad.f16 hr15.x, hr38.x, hr4.y, (last)hr15.x
mad.f16 hr11.x, hr38.x, hr4.z, (last)hr11.x
mad.f16 hr35.y, hr38.y, hr45.z, (last)hr35.y
mad.f16 hr31.y, hr38.y, hr45.w, (last)hr31.y
mad.f16 hr27.y, hr38.y, hr46.x, (last)hr27.y
mad.f16 hr23.y, hr38.y, hr46.y, (last)hr23.y
mad.f16 hr19.y, hr38.y, hr4.x, (last)hr19.y
mad.f16 hr15.y, hr38.y, hr4.y, (last)hr15.y
mad.f16 hr11.y, hr38.y, hr4.z, (last)hr11.y
mad.f16 hr35.z, hr38.z, hr45.z, (last)hr35.z
mad.f16 hr31.z, hr38.z, hr45.w, (last)hr31.z
mad.f16 hr27.z, hr38.z, hr46.x, (last)hr27.z
mad.f16 hr23.z, hr38.z, hr46.y, (last)hr23.z
mad.f16 hr19.z, hr38.z, hr4.x, (last)hr19.z
mad.f16 hr15.z, hr38.z, hr4.y, (last)hr15.z
mad.f16 hr11.z, hr38.z, hr4.z, (last)hr11.z
mad.f16 hr35.w, hr38.w, hr45.z, (last)hr35.w
mad.f16 hr31.w, hr38.w, hr45.w, (last)hr31.w
mad.f16 hr27.w, hr38.w, hr46.x, (last)hr27.w
mad.f16 hr23.w, hr38.w, hr46.y, (last)hr23.w
mad.f16 hr19.w, hr38.w, hr4.x, (last)hr19.w
mad.f16 hr15.w, hr38.w, hr4.y, (last)hr15.w
mad.f16 hr11.w, hr38.w, hr4.z, (last)hr11.w
(rpt1)mad.f16 hr38.x, (r)(last)hr38.x, hr4.w, (r)(last)hr37.x
(rpt1)mad.f16 hr38.z, (r)(last)hr38.z, hr4.w, (r)(last)hr37.z
isam.v.base0 (u16)(xyzw)hr37.x, r31.x, s#0, t#2
(sy)mad.f16 hr34.x, hr37.x, hr45.z, (last)hr34.x
mad.f16 hr30.x, hr37.x, hr45.w, (last)hr30.x
mad.f16 hr26.x, hr37.x, hr46.x, (last)hr26.x
mad.f16 hr22.x, hr37.x, hr46.y, (last)hr22.x
mad.f16 hr18.x, hr37.x, hr4.x, (last)hr18.x
mad.f16 hr14.x, hr37.x, hr4.y, (last)hr14.x
mad.f16 hr10.x, hr37.x, hr4.z, (last)hr10.x
mad.f16 hr34.y, hr37.y, hr45.z, (last)hr34.y
mad.f16 hr30.y, hr37.y, hr45.w, (last)hr30.y
mad.f16 hr26.y, hr37.y, hr46.x, (last)hr26.y
mad.f16 hr22.y, hr37.y, hr46.y, (last)hr22.y
mad.f16 hr18.y, hr37.y, hr4.x, (last)hr18.y
mad.f16 hr14.y, hr37.y, hr4.y, (last)hr14.y
mad.f16 hr10.y, hr37.y, hr4.z, (last)hr10.y
mad.f16 hr34.z, hr37.z, hr45.z, (last)hr34.z
mad.f16 hr30.z, hr37.z, hr45.w, (last)hr30.z
mad.f16 hr26.z, hr37.z, hr46.x, (last)hr26.z
mad.f16 hr22.z, hr37.z, hr46.y, (last)hr22.z
mad.f16 hr18.z, hr37.z, hr4.x, (last)hr18.z
mad.f16 hr14.z, hr37.z, hr4.y, (last)hr14.z
mad.f16 hr10.z, hr37.z, hr4.z, (last)hr10.z
(rpt1)mad.f16 hr37.x, (r)(last)hr37.x, hr4.w, (r)(last)hr0.y
mad.f16 hr37.z, (last)hr37.z, hr4.w, (last)hr0.w
isam.v.base0 (u16)(xyzw)hr0.x, r31.y, s#0, t#2
mad.f16 hr34.w, hr37.w, hr45.z, (last)hr34.w
mad.f16 hr30.w, hr37.w, hr45.w, (last)hr30.w
mad.f16 hr26.w, hr37.w, hr46.x, (last)hr26.w
mad.f16 hr22.w, hr37.w, hr46.y, (last)hr22.w
mad.f16 hr18.w, hr37.w, hr4.x, (last)hr18.w
mad.f16 hr14.w, hr37.w, hr4.y, (last)hr14.w
mad.f16 hr10.w, hr37.w, hr4.z, (last)hr10.w
mad.f16 hr37.w, (last)hr37.w, hr4.w, (last)hr1.x
(sy)mad.f16 hr33.x, hr0.x, hr45.z, (last)hr33.x
mad.f16 hr29.x, hr0.x, hr45.w, (last)hr29.x
mad.f16 hr25.x, hr0.x, hr46.x, (last)hr25.x
mad.f16 hr21.x, hr0.x, hr46.y, (last)hr21.x
mad.f16 hr17.x, hr0.x, hr4.x, (last)hr17.x
mad.f16 hr13.x, hr0.x, hr4.y, (last)hr13.x
mad.f16 hr9.x, hr0.x, hr4.z, (last)hr9.x
mad.f16 hr33.y, hr0.y, hr45.z, (last)hr33.y
mad.f16 hr29.y, hr0.y, hr45.w, (last)hr29.y
mad.f16 hr25.y, hr0.y, hr46.x, (last)hr25.y
mad.f16 hr21.y, hr0.y, hr46.y, (last)hr21.y
mad.f16 hr17.y, hr0.y, hr4.x, (last)hr17.y
mad.f16 hr13.y, hr0.y, hr4.y, (last)hr13.y
mad.f16 hr9.y, hr0.y, hr4.z, (last)hr9.y
mad.f16 hr33.z, hr0.z, hr45.z, (last)hr33.z
mad.f16 hr29.z, hr0.z, hr45.w, (last)hr29.z
mad.f16 hr25.z, hr0.z, hr46.x, (last)hr25.z
mad.f16 hr21.z, hr0.z, hr46.y, (last)hr21.z
mad.f16 hr17.z, hr0.z, hr4.x, (last)hr17.z
mad.f16 hr13.z, hr0.z, hr4.y, (last)hr13.z
mad.f16 hr9.z, hr0.z, hr4.z, (last)hr9.z
(rpt1)mad.f16 hr0.x, (r)(last)hr0.x, hr4.w, (r)(last)hr1.y
mad.f16 hr0.z, (last)hr0.z, hr4.w, (last)hr1.w
isam.v.base0 (u16)(xyzw)hr1.x, r31.z, s#0, t#2
mad.f16 hr33.w, hr0.w, hr45.z, (last)hr33.w
mad.f16 hr29.w, hr0.w, hr45.w, (last)hr29.w
mad.f16 hr25.w, hr0.w, hr46.x, (last)hr25.w
mad.f16 hr21.w, hr0.w, hr46.y, (last)hr21.w
mad.f16 hr17.w, hr0.w, hr4.x, (last)hr17.w
mad.f16 hr13.w, hr0.w, hr4.y, (last)hr13.w
mad.f16 hr9.w, hr0.w, hr4.z, (last)hr9.w
mad.f16 hr0.w, (last)hr0.w, hr4.w, (last)hr2.x
(sy)mad.f16 hr32.x, hr1.x, hr45.z, (last)hr32.x
mad.f16 hr28.x, hr1.x, hr45.w, (last)hr28.x
mad.f16 hr24.x, hr1.x, hr46.x, (last)hr24.x
mad.f16 hr20.x, hr1.x, hr46.y, (last)hr20.x
mad.f16 hr16.x, hr1.x, hr4.x, (last)hr16.x
mad.f16 hr12.x, hr1.x, hr4.y, (last)hr12.x
mad.f16 hr8.x, hr1.x, hr4.z, (last)hr8.x
mad.f16 hr32.y, hr1.y, hr45.z, (last)hr32.y
mad.f16 hr28.y, hr1.y, hr45.w, (last)hr28.y
mad.f16 hr24.y, hr1.y, hr46.x, (last)hr24.y
mad.f16 hr20.y, hr1.y, hr46.y, (last)hr20.y
mad.f16 hr16.y, hr1.y, hr4.x, (last)hr16.y
mad.f16 hr12.y, hr1.y, hr4.y, (last)hr12.y
mad.f16 hr8.y, hr1.y, hr4.z, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr1.z, hr45.z, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr1.z, hr45.w, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr1.z, hr46.x, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr1.z, hr46.y, (r)(last)hr20.z
(rpt1)mad.f16 hr16.z, (r)hr1.z, hr4.x, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr1.z, hr4.y, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr1.z, hr4.z, (r)(last)hr8.z
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr4.w, (r)(last)hr42.x
(rpt1)mad.f16 hr1.z, (r)(last)hr1.z, hr4.w, (r)(last)hr42.z
isam.v.base0 (u16)(xyzw)hr4.x, r31.w, s#0, t#2
(sy)mad.f16 hr35.x, hr4.x, hr40.x, (last)hr35.x
mad.f16 hr31.x, hr4.x, hr40.y, (last)hr31.x
mad.f16 hr27.x, hr4.x, hr40.z, (last)hr27.x
mad.f16 hr23.x, hr4.x, hr40.w, (last)hr23.x
mad.f16 hr19.x, hr4.x, hr41.x, (last)hr19.x
mad.f16 hr15.x, hr4.x, hr41.y, (last)hr15.x
mad.f16 hr11.x, hr4.x, hr41.z, (last)hr11.x
mad.f16 hr35.y, hr4.y, hr40.x, (last)hr35.y
mad.f16 hr31.y, hr4.y, hr40.y, (last)hr31.y
mad.f16 hr27.y, hr4.y, hr40.z, (last)hr27.y
mad.f16 hr23.y, hr4.y, hr40.w, (last)hr23.y
mad.f16 hr19.y, hr4.y, hr41.x, (last)hr19.y
mad.f16 hr15.y, hr4.y, hr41.y, (last)hr15.y
mad.f16 hr11.y, hr4.y, hr41.z, (last)hr11.y
mad.f16 hr35.z, hr4.z, hr40.x, (last)hr35.z
mad.f16 hr31.z, hr4.z, hr40.y, (last)hr31.z
mad.f16 hr27.z, hr4.z, hr40.z, (last)hr27.z
mad.f16 hr23.z, hr4.z, hr40.w, (last)hr23.z
mad.f16 hr19.z, hr4.z, hr41.x, (last)hr19.z
mad.f16 hr15.z, hr4.z, hr41.y, (last)hr15.z
mad.f16 hr11.z, hr4.z, hr41.z, (last)hr11.z
mad.f16 hr35.w, hr4.w, hr40.x, (last)hr35.w
mad.f16 hr31.w, hr4.w, hr40.y, (last)hr31.w
mad.f16 hr27.w, hr4.w, hr40.z, (last)hr27.w
mad.f16 hr23.w, hr4.w, hr40.w, (last)hr23.w
mad.f16 hr19.w, hr4.w, hr41.x, (last)hr19.w
mad.f16 hr15.w, hr4.w, hr41.y, (last)hr15.w
mad.f16 hr11.w, hr4.w, hr41.z, (last)hr11.w
(rpt1)mad.f16 hr4.x, (r)(last)hr4.x, hr41.w, (r)(last)hr38.x
(rpt1)mad.f16 hr4.z, (r)(last)hr4.z, hr41.w, (r)(last)hr38.z
isam.v.base0 (u16)(xyzw)hr38.x, r32.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr42.x, r32.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr45.z, r32.z, s#0, t#2
(sy)mad.f16 hr30.x, hr38.x, hr40.y, (last)hr30.x
mad.f16 hr26.x, hr38.x, hr40.z, (last)hr26.x
mad.f16 hr22.x, hr38.x, hr40.w, (last)hr22.x
mad.f16 hr18.x, hr38.x, hr41.x, (last)hr18.x
mad.f16 hr30.y, hr38.y, hr40.y, (last)hr30.y
mad.f16 hr26.y, hr38.y, hr40.z, (last)hr26.y
mad.f16 hr22.y, hr38.y, hr40.w, (last)hr22.y
mad.f16 hr18.y, hr38.y, hr41.x, (last)hr18.y
mad.f16 hr30.z, hr38.z, hr40.y, (last)hr30.z
mad.f16 hr26.z, hr38.z, hr40.z, (last)hr26.z
mad.f16 hr22.z, hr38.z, hr40.w, (last)hr22.z
mad.f16 hr18.z, hr38.z, hr41.x, (last)hr18.z
mad.f16 hr30.w, hr38.w, hr40.y, (last)hr30.w
mad.f16 hr26.w, hr38.w, hr40.z, (last)hr26.w
mad.f16 hr22.w, hr38.w, hr40.w, (last)hr22.w
mad.f16 hr18.w, hr38.w, hr41.x, (last)hr18.w
mad.f16 hr33.x, hr42.x, hr40.x, (last)hr33.x
mad.f16 hr29.x, hr42.x, hr40.y, (last)hr29.x
mad.f16 hr25.x, hr42.x, hr40.z, (last)hr25.x
mad.f16 hr21.x, hr42.x, hr40.w, (last)hr21.x
mad.f16 hr17.x, hr42.x, hr41.x, (last)hr17.x
mad.f16 hr13.x, hr42.x, hr41.y, (last)hr13.x
mad.f16 hr9.x, hr42.x, hr41.z, (last)hr9.x
mad.f16 hr33.y, hr42.y, hr40.x, (last)hr33.y
mad.f16 hr29.y, hr42.y, hr40.y, (last)hr29.y
mad.f16 hr25.y, hr42.y, hr40.z, (last)hr25.y
mad.f16 hr21.y, hr42.y, hr40.w, (last)hr21.y
mad.f16 hr17.y, hr42.y, hr41.x, (last)hr17.y
mad.f16 hr13.y, hr42.y, hr41.y, (last)hr13.y
mad.f16 hr9.y, hr42.y, hr41.z, (last)hr9.y
mad.f16 hr33.z, hr42.z, hr40.x, (last)hr33.z
mad.f16 hr29.z, hr42.z, hr40.y, (last)hr29.z
mad.f16 hr25.z, hr42.z, hr40.z, (last)hr25.z
mad.f16 hr21.z, hr42.z, hr40.w, (last)hr21.z
mad.f16 hr17.z, hr42.z, hr41.x, (last)hr17.z
mad.f16 hr13.z, hr42.z, hr41.y, (last)hr13.z
mad.f16 hr9.z, hr42.z, hr41.z, (last)hr9.z
mad.f16 hr33.w, hr42.w, hr40.x, (last)hr33.w
mad.f16 hr29.w, hr42.w, hr40.y, (last)hr29.w
mad.f16 hr25.w, hr42.w, hr40.z, (last)hr25.w
mad.f16 hr21.w, hr42.w, hr40.w, (last)hr21.w
mad.f16 hr17.w, hr42.w, hr41.x, (last)hr17.w
mad.f16 hr13.w, hr42.w, hr41.y, (last)hr13.w
mad.f16 hr9.w, hr42.w, hr41.z, (last)hr9.w
mad.f16 hr28.x, hr45.z, hr40.y, (last)hr28.x
mad.f16 hr24.x, hr45.z, hr40.z, (last)hr24.x
mad.f16 hr20.x, hr45.z, hr40.w, (last)hr20.x
mad.f16 hr16.x, hr45.z, hr41.x, (last)hr16.x
mad.f16 hr32.y, hr45.w, hr40.x, (last)hr32.y
mad.f16 hr28.y, hr45.w, hr40.y, (last)hr28.y
mad.f16 hr24.y, hr45.w, hr40.z, (last)hr24.y
mad.f16 hr20.y, hr45.w, hr40.w, (last)hr20.y
mad.f16 hr16.y, hr45.w, hr41.x, (last)hr16.y
mad.f16 hr12.y, hr45.w, hr41.y, (last)hr12.y
mad.f16 hr8.y, hr45.w, hr41.z, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr46.x, hr40.x, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr46.x, hr40.y, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr46.x, hr40.z, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr46.x, hr40.w, (r)(last)hr20.z
(rpt1)mad.f16 hr16.z, (r)hr46.x, hr41.x, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr46.x, hr41.y, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr46.x, hr41.z, (r)(last)hr8.z
(rpt1)mad.f16 hr42.x, (r)(last)hr42.x, hr41.w, (r)(last)hr0.x
(rpt1)mad.f16 hr42.z, (r)(last)hr42.z, hr41.w, (r)(last)hr0.z
isam.v.base0 (u16)(xyzw)hr0.x, r35.w, s#0, t#2
mad.f16 hr45.w, (last)hr45.w, hr41.w, (last)hr1.y
(rpt1)mad.f16 hr46.x, (r)(last)hr46.x, hr41.w, (r)(last)hr1.z
isam.v.base0 (u16)(xyzw)hr1.y, r24.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr40.y, r25.x, s#0, t#2
mad.f16 hr34.x, hr38.x, hr40.x, (last)hr34.x
mad.f16 hr14.x, hr38.x, hr41.y, (last)hr14.x
mad.f16 hr10.x, hr38.x, hr41.z, (last)hr10.x
mad.f16 hr34.y, hr38.y, hr40.x, (last)hr34.y
mad.f16 hr14.y, hr38.y, hr41.y, (last)hr14.y
mad.f16 hr10.y, hr38.y, hr41.z, (last)hr10.y
mad.f16 hr34.z, hr38.z, hr40.x, (last)hr34.z
mad.f16 hr14.z, hr38.z, hr41.y, (last)hr14.z
mad.f16 hr10.z, hr38.z, hr41.z, (last)hr10.z
mad.f16 hr34.w, hr38.w, hr40.x, (last)hr34.w
mad.f16 hr14.w, hr38.w, hr41.y, (last)hr14.w
mad.f16 hr10.w, hr38.w, hr41.z, (last)hr10.w
mad.f16 hr32.x, hr45.z, hr40.x, (last)hr32.x
mad.f16 hr12.x, hr45.z, hr41.y, (last)hr12.x
mad.f16 hr8.x, hr45.z, hr41.z, (last)hr8.x
(rpt1)mad.f16 hr38.x, (r)(last)hr38.x, hr41.w, (r)(last)hr37.x
(rpt1)mad.f16 hr38.z, (r)(last)hr38.z, hr41.w, (r)(last)hr37.z
mad.f16 hr45.z, (last)hr45.z, hr41.w, (last)hr1.x
(sy)mad.f16 hr33.x, hr40.y, hr36.x, (last)hr33.x
mad.f16 hr29.x, hr40.y, hr36.y, (last)hr29.x
mad.f16 hr25.x, hr40.y, hr36.z, (last)hr25.x
mad.f16 hr21.x, hr40.y, hr36.w, (last)hr21.x
mad.f16 hr17.x, hr40.y, hr2.z, (last)hr17.x
mad.f16 hr13.x, hr40.y, hr2.w, (last)hr13.x
mad.f16 hr9.x, hr40.y, hr3.x, (last)hr9.x
mad.f16 hr40.y, (last)hr40.y, hr3.y, (last)hr42.x
isam.v.base0 (u16)(xyzw)hr41.y, r25.y, s#0, t#2
mad.f16 hr31.x, hr0.x, hr36.y, (last)hr31.x
mad.f16 hr27.x, hr0.x, hr36.z, (last)hr27.x
mad.f16 hr23.x, hr0.x, hr36.w, (last)hr23.x
mad.f16 hr31.y, hr0.y, hr36.y, (last)hr31.y
mad.f16 hr27.y, hr0.y, hr36.z, (last)hr27.y
mad.f16 hr23.y, hr0.y, hr36.w, (last)hr23.y
mad.f16 hr31.z, hr0.z, hr36.y, (last)hr31.z
mad.f16 hr27.z, hr0.z, hr36.z, (last)hr27.z
mad.f16 hr23.z, hr0.z, hr36.w, (last)hr23.z
mad.f16 hr31.w, hr0.w, hr36.y, (last)hr31.w
mad.f16 hr27.w, hr0.w, hr36.z, (last)hr27.w
mad.f16 hr23.w, hr0.w, hr36.w, (last)hr23.w
mad.f16 hr30.x, hr1.y, hr36.y, (last)hr30.x
mad.f16 hr26.x, hr1.y, hr36.z, (last)hr26.x
mad.f16 hr22.x, hr1.y, hr36.w, (last)hr22.x
mad.f16 hr30.y, hr1.z, hr36.y, (last)hr30.y
mad.f16 hr26.y, hr1.z, hr36.z, (last)hr26.y
mad.f16 hr22.y, hr1.z, hr36.w, (last)hr22.y
mad.f16 hr30.z, hr1.w, hr36.y, (last)hr30.z
mad.f16 hr26.z, hr1.w, hr36.z, (last)hr26.z
mad.f16 hr22.z, hr1.w, hr36.w, (last)hr22.z
mad.f16 hr30.w, hr2.x, hr36.y, (last)hr30.w
mad.f16 hr26.w, hr2.x, hr36.z, (last)hr26.w
mad.f16 hr22.w, hr2.x, hr36.w, (last)hr22.w
mad.f16 hr29.y, hr40.z, hr36.y, (last)hr29.y
mad.f16 hr25.y, hr40.z, hr36.z, (last)hr25.y
mad.f16 hr21.y, hr40.z, hr36.w, (last)hr21.y
mad.f16 hr29.z, hr40.w, hr36.y, (last)hr29.z
mad.f16 hr25.z, hr40.w, hr36.z, (last)hr25.z
mad.f16 hr21.z, hr40.w, hr36.w, (last)hr21.z
mad.f16 hr29.w, hr41.x, hr36.y, (last)hr29.w
mad.f16 hr25.w, hr41.x, hr36.z, (last)hr25.w
mad.f16 hr21.w, hr41.x, hr36.w, (last)hr21.w
mad.f16 hr35.y, hr0.y, hr36.x, (last)hr35.y
mad.f16 hr19.y, hr0.y, hr2.z, (last)hr19.y
mad.f16 hr15.y, hr0.y, hr2.w, (last)hr15.y
mad.f16 hr11.y, hr0.y, hr3.x, (last)hr11.y
mad.f16 hr35.z, hr0.z, hr36.x, (last)hr35.z
mad.f16 hr19.z, hr0.z, hr2.z, (last)hr19.z
(sy)mad.f16 hr28.x, hr41.y, hr36.y, (last)hr28.x
mad.f16 hr24.x, hr41.y, hr36.z, (last)hr24.x
mad.f16 hr20.x, hr41.y, hr36.w, (last)hr20.x
mad.f16 hr28.y, hr41.z, hr36.y, (last)hr28.y
mad.f16 hr24.y, hr41.z, hr36.z, (last)hr24.y
mad.f16 hr20.y, hr41.z, hr36.w, (last)hr20.y
(rpt1)mad.f16 hr28.z, (r)hr41.w, hr36.y, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr41.w, hr36.z, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr41.w, hr36.w, (r)(last)hr20.z
isam.v.base0 (u16)(xyzw)hr36.y, r25.z, s#0, t#2
mad.f16 hr15.z, hr0.z, hr2.w, (last)hr15.z
mad.f16 hr11.z, hr0.z, hr3.x, (last)hr11.z
mad.f16 hr35.w, hr0.w, hr36.x, (last)hr35.w
mad.f16 hr19.w, hr0.w, hr2.z, (last)hr19.w
mad.f16 hr15.w, hr0.w, hr2.w, (last)hr15.w
mad.f16 hr11.w, hr0.w, hr3.x, (last)hr11.w
mad.f16 hr0.y, (last)hr0.y, hr3.y, (last)hr4.y
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr3.y, (r)(last)hr4.z
mad.f16 hr18.x, hr1.y, hr2.z, (last)hr18.x
mad.f16 hr34.x, hr1.y, hr36.x, (last)hr34.x
mad.f16 hr14.x, hr1.y, hr2.w, (last)hr14.x
mad.f16 hr10.x, hr1.y, hr3.x, (last)hr10.x
mad.f16 hr32.x, hr41.y, hr36.x, (last)hr32.x
mad.f16 hr16.x, hr41.y, hr2.z, (last)hr16.x
mad.f16 hr12.x, hr41.y, hr2.w, (last)hr12.x
mad.f16 hr8.x, hr41.y, hr3.x, (last)hr8.x
mad.f16 hr32.y, hr41.z, hr36.x, (last)hr32.y
mad.f16 hr16.y, hr41.z, hr2.z, (last)hr16.y
mad.f16 hr12.y, hr41.z, hr2.w, (last)hr12.y
mad.f16 hr8.y, hr41.z, hr3.x, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr41.w, hr36.x, (r)(last)hr32.z
(rpt1)mad.f16 hr16.z, (r)hr41.w, hr2.z, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr41.w, hr2.w, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr41.w, hr3.x, (r)(last)hr8.z
mad.f16 hr1.y, (last)hr1.y, hr3.y, (last)hr38.x
isam.v.base0 (u16)(xyzw)hr37.y, r25.w, s#0, t#2
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr3.y, (r)(last)hr45.z
(rpt1)mad.f16 hr41.w, (r)(last)hr41.w, hr3.y, (r)(last)hr46.x
isam.v.base0 (u16)(xyzw)hr45.z, r26.x, s#0, t#2
mad.f16 hr19.x, hr0.x, hr2.z, (last)hr19.x
mad.f16 hr18.y, hr1.z, hr2.z, (last)hr18.y
(rpt1)mad.f16 hr18.z, (r)hr1.w, hr2.z, (r)(last)hr18.z
mad.f16 hr33.y, hr40.z, hr36.x, (last)hr33.y
mad.f16 hr17.y, hr40.z, hr2.z, (last)hr17.y
mad.f16 hr13.y, hr40.z, hr2.w, (last)hr13.y
mad.f16 hr9.y, hr40.z, hr3.x, (last)hr9.y
mad.f16 hr33.z, hr40.w, hr36.x, (last)hr33.z
mad.f16 hr17.z, hr40.w, hr2.z, (last)hr17.z
mad.f16 hr13.z, hr40.w, hr2.w, (last)hr13.z
mad.f16 hr9.z, hr40.w, hr3.x, (last)hr9.z
mad.f16 hr33.w, hr41.x, hr36.x, (last)hr33.w
mad.f16 hr17.w, hr41.x, hr2.z, (last)hr17.w
mad.f16 hr13.w, hr41.x, hr2.w, (last)hr13.w
mad.f16 hr9.w, hr41.x, hr3.x, (last)hr9.w
mad.f16 hr34.y, hr1.z, hr36.x, (last)hr34.y
mad.f16 hr14.y, hr1.z, hr2.w, (last)hr14.y
mad.f16 hr10.y, hr1.z, hr3.x, (last)hr10.y
mad.f16 hr34.z, hr1.w, hr36.x, (last)hr34.z
mad.f16 hr14.z, hr1.w, hr2.w, (last)hr14.z
mad.f16 hr10.z, hr1.w, hr3.x, (last)hr10.z
mad.f16 hr34.w, hr2.x, hr36.x, (last)hr34.w
mad.f16 hr14.w, hr2.x, hr2.w, (last)hr14.w
mad.f16 hr10.w, hr2.x, hr3.x, (last)hr10.w
mad.f16 hr40.z, (last)hr40.z, hr3.y, (last)hr42.y
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr3.y, (r)(last)hr42.z
mad.f16 hr1.z, (last)hr1.z, hr3.y, (last)hr38.y
(rpt1)mad.f16 hr1.w, (r)(last)hr1.w, hr3.y, (r)(last)hr38.z
mad.f16 hr35.x, hr0.x, hr36.x, (last)hr35.x
mad.f16 hr15.x, hr0.x, hr2.w, (last)hr15.x
mad.f16 hr11.x, hr0.x, hr3.x, (last)hr11.x
mad.f16 hr0.x, (last)hr0.x, hr3.y, (last)hr4.x
ldl.u16 r4.x, l[r24.z+3968], 4
fence.r.w
(sy)(ss)mad.f16 hr35.y, hr36.z, hr5.x, (last)hr35.y
mad.f16 hr31.y, hr36.z, hr5.y, (last)hr31.y
mad.f16 hr27.y, hr36.z, hr5.z, (last)hr27.y
mad.f16 hr23.y, hr36.z, hr5.w, (last)hr23.y
mad.f16 hr19.y, hr36.z, hr7.x, (last)hr19.y
mad.f16 hr15.y, hr36.z, hr7.y, (last)hr15.y
mad.f16 hr11.y, hr36.z, hr7.z, (last)hr11.y
mad.f16 hr35.z, hr36.w, hr5.x, (last)hr35.z
mad.f16 hr31.z, hr36.w, hr5.y, (last)hr31.z
mad.f16 hr27.z, hr36.w, hr5.z, (last)hr27.z
mad.f16 hr23.z, hr36.w, hr5.w, (last)hr23.z
mad.f16 hr19.z, hr36.w, hr7.x, (last)hr19.z
mad.f16 hr31.w, hr37.x, hr5.y, (last)hr31.w
mad.f16 hr27.w, hr37.x, hr5.z, (last)hr27.w
mad.f16 hr23.w, hr37.x, hr5.w, (last)hr23.w
mad.f16 hr15.z, hr36.w, hr7.y, (last)hr15.z
mad.f16 hr11.z, hr36.w, hr7.z, (last)hr11.z
mad.f16 hr35.w, hr37.x, hr5.x, (last)hr35.w
mad.f16 hr19.w, hr37.x, hr7.x, (last)hr19.w
mad.f16 hr15.w, hr37.x, hr7.y, (last)hr15.w
mad.f16 hr11.w, hr37.x, hr7.z, (last)hr11.w
mad.f16 hr36.z, (last)hr36.z, hr7.w, (last)hr0.y
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr7.w, (r)(last)hr0.z
isam.v.base0 (u16)(xyzw)hr0.y, r26.y, s#0, t#2
mad.f16 hr34.x, hr37.y, hr5.x, (last)hr34.x
mad.f16 hr30.x, hr37.y, hr5.y, (last)hr30.x
mad.f16 hr26.x, hr37.y, hr5.z, (last)hr26.x
mad.f16 hr22.x, hr37.y, hr5.w, (last)hr22.x
mad.f16 hr18.x, hr37.y, hr7.x, (last)hr18.x
mad.f16 hr14.x, hr37.y, hr7.y, (last)hr14.x
mad.f16 hr10.x, hr37.y, hr7.z, (last)hr10.x
mad.f16 hr30.y, hr37.z, hr5.y, (last)hr30.y
mad.f16 hr26.y, hr37.z, hr5.z, (last)hr26.y
mad.f16 hr22.y, hr37.z, hr5.w, (last)hr22.y
mad.f16 hr30.z, hr37.w, hr5.y, (last)hr30.z
mad.f16 hr26.z, hr37.w, hr5.z, (last)hr26.z
mad.f16 hr22.z, hr37.w, hr5.w, (last)hr22.z
mad.f16 hr30.w, hr38.x, hr5.y, (last)hr30.w
mad.f16 hr26.w, hr38.x, hr5.z, (last)hr26.w
mad.f16 hr22.w, hr38.x, hr5.w, (last)hr22.w
mad.f16 hr33.x, hr45.z, hr5.x, (last)hr33.x
mad.f16 hr29.x, hr45.z, hr5.y, (last)hr29.x
mad.f16 hr25.x, hr45.z, hr5.z, (last)hr25.x
mad.f16 hr21.x, hr45.z, hr5.w, (last)hr21.x
mad.f16 hr17.x, hr45.z, hr7.x, (last)hr17.x
mad.f16 hr13.x, hr45.z, hr7.y, (last)hr13.x
mad.f16 hr9.x, hr45.z, hr7.z, (last)hr9.x
mad.f16 hr29.y, hr45.w, hr5.y, (last)hr29.y
mad.f16 hr25.y, hr45.w, hr5.z, (last)hr25.y
mad.f16 hr21.y, hr45.w, hr5.w, (last)hr21.y
mad.f16 hr29.z, hr46.x, hr5.y, (last)hr29.z
mad.f16 hr25.z, hr46.x, hr5.z, (last)hr25.z
mad.f16 hr21.z, hr46.x, hr5.w, (last)hr21.z
mad.f16 hr29.w, hr46.y, hr5.y, (last)hr29.w
mad.f16 hr25.w, hr46.y, hr5.z, (last)hr25.w
mad.f16 hr21.w, hr46.y, hr5.w, (last)hr21.w
mad.f16 hr19.x, hr36.y, hr7.x, (last)hr19.x
mad.f16 hr18.y, hr37.z, hr7.x, (last)hr18.y
(rpt1)mad.f16 hr18.z, (r)hr37.w, hr7.x, (r)(last)hr18.z
mad.f16 hr33.y, hr45.w, hr5.x, (last)hr33.y
mad.f16 hr17.y, hr45.w, hr7.x, (last)hr17.y
mad.f16 hr13.y, hr45.w, hr7.y, (last)hr13.y
mad.f16 hr9.y, hr45.w, hr7.z, (last)hr9.y
mad.f16 hr33.z, hr46.x, hr5.x, (last)hr33.z
mad.f16 hr17.z, hr46.x, hr7.x, (last)hr17.z
mad.f16 hr13.z, hr46.x, hr7.y, (last)hr13.z
mad.f16 hr9.z, hr46.x, hr7.z, (last)hr9.z
mad.f16 hr33.w, hr46.y, hr5.x, (last)hr33.w
mad.f16 hr17.w, hr46.y, hr7.x, (last)hr17.w
mad.f16 hr13.w, hr46.y, hr7.y, (last)hr13.w
mad.f16 hr9.w, hr46.y, hr7.z, (last)hr9.w
mad.f16 hr34.y, hr37.z, hr5.x, (last)hr34.y
mad.f16 hr14.y, hr37.z, hr7.y, (last)hr14.y
mad.f16 hr10.y, hr37.z, hr7.z, (last)hr10.y
mad.f16 hr34.z, hr37.w, hr5.x, (last)hr34.z
mad.f16 hr14.z, hr37.w, hr7.y, (last)hr14.z
mad.f16 hr10.z, hr37.w, hr7.z, (last)hr10.z
mad.f16 hr34.w, hr38.x, hr5.x, (last)hr34.w
mad.f16 hr14.w, hr38.x, hr7.y, (last)hr14.w
mad.f16 hr10.w, hr38.x, hr7.z, (last)hr10.w
(sy)mad.f16 hr32.x, hr0.y, hr5.x, (last)hr32.x
mad.f16 hr28.x, hr0.y, hr5.y, (last)hr28.x
mad.f16 hr24.x, hr0.y, hr5.z, (last)hr24.x
mad.f16 hr20.x, hr0.y, hr5.w, (last)hr20.x
mad.f16 hr16.x, hr0.y, hr7.x, (last)hr16.x
mad.f16 hr12.x, hr0.y, hr7.y, (last)hr12.x
mad.f16 hr8.x, hr0.y, hr7.z, (last)hr8.x
mad.f16 hr32.y, hr0.z, hr5.x, (last)hr32.y
mad.f16 hr28.y, hr0.z, hr5.y, (last)hr28.y
mad.f16 hr24.y, hr0.z, hr5.z, (last)hr24.y
mad.f16 hr20.y, hr0.z, hr5.w, (last)hr20.y
mad.f16 hr16.y, hr0.z, hr7.x, (last)hr16.y
mad.f16 hr12.y, hr0.z, hr7.y, (last)hr12.y
mad.f16 hr8.y, hr0.z, hr7.z, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr0.w, hr5.x, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr0.w, hr5.y, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr0.w, hr5.z, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr0.w, hr5.w, (r)(last)hr20.z
(rpt1)mad.f16 hr16.z, (r)hr0.w, hr7.x, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr0.w, hr7.y, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr0.w, hr7.z, (r)(last)hr8.z
mad.f16 hr37.y, (last)hr37.y, hr7.w, (last)hr1.y
(rpt1)mad.f16 hr45.z, (r)(last)hr45.z, hr7.w, (r)(last)hr40.y
(rpt1)mad.f16 hr46.x, (r)(last)hr46.x, hr7.w, (r)(last)hr40.w
mad.f16 hr37.z, (last)hr37.z, hr7.w, (last)hr1.z
(rpt1)mad.f16 hr37.w, (r)(last)hr37.w, hr7.w, (r)(last)hr1.w
isam.v.base0 (u16)(xyzw)hr1.y, r32.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr40.y, r33.x, s#0, t#2
(rpt1)mad.f16 hr0.y, (r)(last)hr0.y, hr7.w, (r)(last)hr41.y
(rpt1)mad.f16 hr0.w, (r)(last)hr0.w, hr7.w, (r)(last)hr41.w
isam.v.base0 (u16)(xyzw)hr41.y, r33.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr6.y, r33.z, s#0, t#2
mad.f16 hr31.x, hr36.y, hr5.y, (last)hr31.x
mad.f16 hr27.x, hr36.y, hr5.z, (last)hr27.x
mad.f16 hr23.x, hr36.y, hr5.w, (last)hr23.x
mad.f16 hr35.x, hr36.y, hr5.x, (last)hr35.x
mad.f16 hr15.x, hr36.y, hr7.y, (last)hr15.x
mad.f16 hr11.x, hr36.y, hr7.z, (last)hr11.x
mad.f16 hr36.y, (last)hr36.y, hr7.w, (last)hr0.x
(sy)mad.f16 hr19.x, hr1.y, hr46.z, (last)hr19.x
mad.f16 hr35.y, hr1.z, hr43.y, (last)hr35.y
mad.f16 hr31.y, hr1.z, hr43.z, (last)hr31.y
mad.f16 hr27.y, hr1.z, hr43.w, (last)hr27.y
mad.f16 hr23.y, hr1.z, hr2.y, (last)hr23.y
mad.f16 hr19.y, hr1.z, hr46.z, (last)hr19.y
mad.f16 hr15.y, hr1.z, hr46.w, (last)hr15.y
mad.f16 hr11.y, hr1.z, hr6.x, (last)hr11.y
mad.f16 hr35.z, hr1.w, hr43.y, (last)hr35.z
mad.f16 hr31.z, hr1.w, hr43.z, (last)hr31.z
mad.f16 hr27.z, hr1.w, hr43.w, (last)hr27.z
mad.f16 hr23.z, hr1.w, hr2.y, (last)hr23.z
mad.f16 hr19.z, hr1.w, hr46.z, (last)hr19.z
mad.f16 hr15.z, hr1.w, hr46.w, (last)hr15.z
mad.f16 hr11.z, hr1.w, hr6.x, (last)hr11.z
mad.f16 hr35.w, hr2.x, hr43.y, (last)hr35.w
mad.f16 hr31.w, hr2.x, hr43.z, (last)hr31.w
mad.f16 hr27.w, hr2.x, hr43.w, (last)hr27.w
mad.f16 hr23.w, hr2.x, hr2.y, (last)hr23.w
mad.f16 hr19.w, hr2.x, hr46.z, (last)hr19.w
mad.f16 hr15.w, hr2.x, hr46.w, (last)hr15.w
mad.f16 hr11.w, hr2.x, hr6.x, (last)hr11.w
mad.f16 hr34.x, hr40.y, hr43.y, (last)hr34.x
mad.f16 hr30.x, hr40.y, hr43.z, (last)hr30.x
mad.f16 hr26.x, hr40.y, hr43.w, (last)hr26.x
mad.f16 hr22.x, hr40.y, hr2.y, (last)hr22.x
mad.f16 hr18.x, hr40.y, hr46.z, (last)hr18.x
mad.f16 hr14.x, hr40.y, hr46.w, (last)hr14.x
mad.f16 hr10.x, hr40.y, hr6.x, (last)hr10.x
mad.f16 hr34.y, hr40.z, hr43.y, (last)hr34.y
mad.f16 hr30.y, hr40.z, hr43.z, (last)hr30.y
mad.f16 hr26.y, hr40.z, hr43.w, (last)hr26.y
mad.f16 hr22.y, hr40.z, hr2.y, (last)hr22.y
mad.f16 hr18.y, hr40.z, hr46.z, (last)hr18.y
mad.f16 hr14.y, hr40.z, hr46.w, (last)hr14.y
mad.f16 hr10.y, hr40.z, hr6.x, (last)hr10.y
mad.f16 hr34.z, hr40.w, hr43.y, (last)hr34.z
mad.f16 hr30.z, hr40.w, hr43.z, (last)hr30.z
mad.f16 hr26.z, hr40.w, hr43.w, (last)hr26.z
mad.f16 hr22.z, hr40.w, hr2.y, (last)hr22.z
mad.f16 hr18.z, hr40.w, hr46.z, (last)hr18.z
mad.f16 hr14.z, hr40.w, hr46.w, (last)hr14.z
mad.f16 hr10.z, hr40.w, hr6.x, (last)hr10.z
mad.f16 hr34.w, hr41.x, hr43.y, (last)hr34.w
mad.f16 hr30.w, hr41.x, hr43.z, (last)hr30.w
mad.f16 hr26.w, hr41.x, hr43.w, (last)hr26.w
mad.f16 hr22.w, hr41.x, hr2.y, (last)hr22.w
mad.f16 hr18.w, hr41.x, hr46.z, (last)hr18.w
mad.f16 hr14.w, hr41.x, hr46.w, (last)hr14.w
mad.f16 hr10.w, hr41.x, hr6.x, (last)hr10.w
mad.f16 hr33.x, hr41.y, hr43.y, (last)hr33.x
mad.f16 hr29.x, hr41.y, hr43.z, (last)hr29.x
mad.f16 hr25.x, hr41.y, hr43.w, (last)hr25.x
mad.f16 hr21.x, hr41.y, hr2.y, (last)hr21.x
mad.f16 hr17.x, hr41.y, hr46.z, (last)hr17.x
mad.f16 hr13.x, hr41.y, hr46.w, (last)hr13.x
mad.f16 hr9.x, hr41.y, hr6.x, (last)hr9.x
mad.f16 hr33.y, hr41.z, hr43.y, (last)hr33.y
mad.f16 hr29.y, hr41.z, hr43.z, (last)hr29.y
mad.f16 hr25.y, hr41.z, hr43.w, (last)hr25.y
mad.f16 hr21.y, hr41.z, hr2.y, (last)hr21.y
mad.f16 hr17.y, hr41.z, hr46.z, (last)hr17.y
mad.f16 hr13.y, hr41.z, hr46.w, (last)hr13.y
mad.f16 hr9.y, hr41.z, hr6.x, (last)hr9.y
mad.f16 hr33.z, hr41.w, hr43.y, (last)hr33.z
mad.f16 hr29.z, hr41.w, hr43.z, (last)hr29.z
mad.f16 hr25.z, hr41.w, hr43.w, (last)hr25.z
mad.f16 hr21.z, hr41.w, hr2.y, (last)hr21.z
mad.f16 hr17.z, hr41.w, hr46.z, (last)hr17.z
mad.f16 hr13.z, hr41.w, hr46.w, (last)hr13.z
mad.f16 hr9.z, hr41.w, hr6.x, (last)hr9.z
mad.f16 hr33.w, hr42.x, hr43.y, (last)hr33.w
mad.f16 hr29.w, hr42.x, hr43.z, (last)hr29.w
mad.f16 hr25.w, hr42.x, hr43.w, (last)hr25.w
mad.f16 hr21.w, hr42.x, hr2.y, (last)hr21.w
mad.f16 hr17.w, hr42.x, hr46.z, (last)hr17.w
mad.f16 hr13.w, hr42.x, hr46.w, (last)hr13.w
mad.f16 hr9.w, hr42.x, hr6.x, (last)hr9.w
mad.f16 hr32.x, hr6.y, hr43.y, (last)hr32.x
mad.f16 hr28.x, hr6.y, hr43.z, (last)hr28.x
mad.f16 hr24.x, hr6.y, hr43.w, (last)hr24.x
mad.f16 hr20.x, hr6.y, hr2.y, (last)hr20.x
mad.f16 hr16.x, hr6.y, hr46.z, (last)hr16.x
mad.f16 hr12.x, hr6.y, hr46.w, (last)hr12.x
mad.f16 hr8.x, hr6.y, hr6.x, (last)hr8.x
mad.f16 hr32.y, hr6.z, hr43.y, (last)hr32.y
mad.f16 hr28.y, hr6.z, hr43.z, (last)hr28.y
mad.f16 hr24.y, hr6.z, hr43.w, (last)hr24.y
mad.f16 hr20.y, hr6.z, hr2.y, (last)hr20.y
mad.f16 hr16.y, hr6.z, hr46.z, (last)hr16.y
mad.f16 hr12.y, hr6.z, hr46.w, (last)hr12.y
mad.f16 hr8.y, hr6.z, hr6.x, (last)hr8.y
(rpt1)mad.f16 hr32.z, (r)hr6.w, hr43.y, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr6.w, hr43.z, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr6.w, hr43.w, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr6.w, hr2.y, (r)(last)hr20.z
(rpt1)mad.f16 hr16.z, (r)hr6.w, hr46.z, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr6.w, hr46.w, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr6.w, hr6.x, (r)(last)hr8.z
mad.f16 hr31.x, hr1.y, hr43.z, (last)hr31.x
mad.f16 hr27.x, hr1.y, hr43.w, (last)hr27.x
mad.f16 hr23.x, hr1.y, hr2.y, (last)hr23.x
mad.f16 hr35.x, hr1.y, hr43.y, (last)hr35.x
mad.f16 hr15.x, hr1.y, hr46.w, (last)hr15.x
mad.f16 hr11.x, hr1.y, hr6.x, (last)hr11.x
mad.f16 hr1.z, (last)hr1.z, hr43.x, (last)hr36.z
(rpt1)mad.f16 hr1.w, (r)(last)hr1.w, hr43.x, (r)(last)hr36.w
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr43.x, (r)(last)hr37.y
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr43.x, (r)(last)hr37.w
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr43.x, (r)(last)hr45.z
(rpt1)mad.f16 hr41.w, (r)(last)hr41.w, hr43.x, (r)(last)hr46.x
(rpt1)mad.f16 hr6.y, (r)(last)hr6.y, hr43.x, (r)(last)hr0.y
(rpt1)mad.f16 hr6.w, (r)(last)hr6.w, hr43.x, (r)(last)hr0.w
mad.f16 hr1.y, (last)hr1.y, hr43.x, (last)hr36.y
isam.v.base0 (u16)(xyzw)hr36.y, r33.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr37.y, r34.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr42.y, r34.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr45.w, r34.z, s#0, t#2
(sy)mad.f16 hr35.x, hr36.y, hr44.x, (last)hr35.x
mad.f16 hr31.x, hr36.y, hr44.y, (last)hr31.x
mad.f16 hr27.x, hr36.y, hr44.z, (last)hr27.x
mad.f16 hr23.x, hr36.y, hr44.w, (last)hr23.x
mad.f16 hr19.x, hr36.y, hr47.x, (last)hr19.x
mad.f16 hr15.x, hr36.y, hr47.y, (last)hr15.x
mad.f16 hr11.x, hr36.y, hr47.z, (last)hr11.x
mad.f16 hr35.y, hr36.z, hr44.x, (last)hr35.y
mad.f16 hr31.y, hr36.z, hr44.y, (last)hr31.y
mad.f16 hr27.y, hr36.z, hr44.z, (last)hr27.y
mad.f16 hr23.y, hr36.z, hr44.w, (last)hr23.y
mad.f16 hr19.y, hr36.z, hr47.x, (last)hr19.y
mad.f16 hr15.y, hr36.z, hr47.y, (last)hr15.y
mad.f16 hr11.y, hr36.z, hr47.z, (last)hr11.y
mad.f16 hr35.z, hr36.w, hr44.x, (last)hr35.z
mad.f16 hr31.z, hr36.w, hr44.y, (last)hr31.z
mad.f16 hr27.z, hr36.w, hr44.z, (last)hr27.z
mad.f16 hr23.z, hr36.w, hr44.w, (last)hr23.z
mad.f16 hr19.z, hr36.w, hr47.x, (last)hr19.z
mad.f16 hr15.z, hr36.w, hr47.y, (last)hr15.z
mad.f16 hr11.z, hr36.w, hr47.z, (last)hr11.z
mad.f16 hr35.w, hr37.x, hr44.x, (last)hr35.w
mad.f16 hr31.w, hr37.x, hr44.y, (last)hr31.w
mad.f16 hr27.w, hr37.x, hr44.z, (last)hr27.w
mad.f16 hr23.w, hr37.x, hr44.w, (last)hr23.w
mad.f16 hr19.w, hr37.x, hr47.x, (last)hr19.w
mad.f16 hr15.w, hr37.x, hr47.y, (last)hr15.w
mad.f16 hr11.w, hr37.x, hr47.z, (last)hr11.w
mad.f16 hr18.x, hr37.y, hr47.x, (last)hr18.x
mad.f16 hr14.x, hr37.y, hr47.y, (last)hr14.x
mad.f16 hr10.x, hr37.y, hr47.z, (last)hr10.x
mad.f16 hr18.y, hr37.z, hr47.x, (last)hr18.y
mad.f16 hr14.y, hr37.z, hr47.y, (last)hr14.y
mad.f16 hr10.y, hr37.z, hr47.z, (last)hr10.y
mad.f16 hr18.z, hr37.w, hr47.x, (last)hr18.z
mad.f16 hr14.z, hr37.w, hr47.y, (last)hr14.z
mad.f16 hr10.z, hr37.w, hr47.z, (last)hr10.z
mad.f16 hr18.w, hr38.x, hr47.x, (last)hr18.w
mad.f16 hr14.w, hr38.x, hr47.y, (last)hr14.w
mad.f16 hr10.w, hr38.x, hr47.z, (last)hr10.w
mad.f16 hr17.x, hr42.y, hr47.x, (last)hr17.x
mad.f16 hr13.x, hr42.y, hr47.y, (last)hr13.x
mad.f16 hr9.x, hr42.y, hr47.z, (last)hr9.x
mad.f16 hr17.y, hr42.z, hr47.x, (last)hr17.y
mad.f16 hr13.y, hr42.z, hr47.y, (last)hr13.y
mad.f16 hr9.y, hr42.z, hr47.z, (last)hr9.y
mad.f16 hr17.z, hr42.w, hr47.x, (last)hr17.z
mad.f16 hr13.z, hr42.w, hr47.y, (last)hr13.z
mad.f16 hr9.z, hr42.w, hr47.z, (last)hr9.z
mad.f16 hr17.w, hr43.x, hr47.x, (last)hr17.w
mad.f16 hr13.w, hr43.x, hr47.y, (last)hr13.w
mad.f16 hr9.w, hr43.x, hr47.z, (last)hr9.w
mad.f16 hr16.x, hr45.w, hr47.x, (last)hr16.x
mad.f16 hr12.x, hr45.w, hr47.y, (last)hr12.x
mad.f16 hr8.x, hr45.w, hr47.z, (last)hr8.x
mad.f16 hr16.y, hr46.x, hr47.x, (last)hr16.y
mad.f16 hr12.y, hr46.x, hr47.y, (last)hr12.y
mad.f16 hr8.y, hr46.x, hr47.z, (last)hr8.y
(rpt1)mad.f16 hr16.z, (r)hr46.y, hr47.x, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr46.y, hr47.y, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr46.y, hr47.z, (r)(last)hr8.z
isam.v.base0 (u16)(xyzw)hr46.w, r34.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr0.y, r35.x, s#0, t#2
(rpt1)mad.f16 hr36.y, (r)(last)hr36.y, hr47.w, (r)(last)hr1.y
(rpt1)mad.f16 hr36.w, (r)(last)hr36.w, hr47.w, (r)(last)hr1.w
isam.v.base0 (u16)(xyzw)hr1.y, r35.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr2.y, r35.z, s#0, t#2
mad.f16 hr34.x, hr37.y, hr44.x, (last)hr34.x
mad.f16 hr30.x, hr37.y, hr44.y, (last)hr30.x
mad.f16 hr26.x, hr37.y, hr44.z, (last)hr26.x
mad.f16 hr22.x, hr37.y, hr44.w, (last)hr22.x
mad.f16 hr34.y, hr37.z, hr44.x, (last)hr34.y
mad.f16 hr30.y, hr37.z, hr44.y, (last)hr30.y
mad.f16 hr26.y, hr37.z, hr44.z, (last)hr26.y
mad.f16 hr22.y, hr37.z, hr44.w, (last)hr22.y
mad.f16 hr34.z, hr37.w, hr44.x, (last)hr34.z
mad.f16 hr30.z, hr37.w, hr44.y, (last)hr30.z
mad.f16 hr26.z, hr37.w, hr44.z, (last)hr26.z
mad.f16 hr22.z, hr37.w, hr44.w, (last)hr22.z
mad.f16 hr34.w, hr38.x, hr44.x, (last)hr34.w
mad.f16 hr30.w, hr38.x, hr44.y, (last)hr30.w
mad.f16 hr26.w, hr38.x, hr44.z, (last)hr26.w
mad.f16 hr22.w, hr38.x, hr44.w, (last)hr22.w
mad.f16 hr33.x, hr42.y, hr44.x, (last)hr33.x
mad.f16 hr29.x, hr42.y, hr44.y, (last)hr29.x
mad.f16 hr25.x, hr42.y, hr44.z, (last)hr25.x
mad.f16 hr21.x, hr42.y, hr44.w, (last)hr21.x
mad.f16 hr33.y, hr42.z, hr44.x, (last)hr33.y
mad.f16 hr29.y, hr42.z, hr44.y, (last)hr29.y
mad.f16 hr25.y, hr42.z, hr44.z, (last)hr25.y
mad.f16 hr21.y, hr42.z, hr44.w, (last)hr21.y
mad.f16 hr33.z, hr42.w, hr44.x, (last)hr33.z
mad.f16 hr29.z, hr42.w, hr44.y, (last)hr29.z
mad.f16 hr25.z, hr42.w, hr44.z, (last)hr25.z
mad.f16 hr21.z, hr42.w, hr44.w, (last)hr21.z
mad.f16 hr33.w, hr43.x, hr44.x, (last)hr33.w
mad.f16 hr29.w, hr43.x, hr44.y, (last)hr29.w
mad.f16 hr25.w, hr43.x, hr44.z, (last)hr25.w
mad.f16 hr21.w, hr43.x, hr44.w, (last)hr21.w
mad.f16 hr32.x, hr45.w, hr44.x, (last)hr32.x
mad.f16 hr28.x, hr45.w, hr44.y, (last)hr28.x
mad.f16 hr24.x, hr45.w, hr44.z, (last)hr24.x
mad.f16 hr20.x, hr45.w, hr44.w, (last)hr20.x
mad.f16 hr32.y, hr46.x, hr44.x, (last)hr32.y
mad.f16 hr28.y, hr46.x, hr44.y, (last)hr28.y
mad.f16 hr24.y, hr46.x, hr44.z, (last)hr24.y
mad.f16 hr20.y, hr46.x, hr44.w, (last)hr20.y
(rpt1)mad.f16 hr32.z, (r)hr46.y, hr44.x, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr46.y, hr44.y, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr46.y, hr44.z, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr46.y, hr44.w, (r)(last)hr20.z
(rpt1)mad.f16 hr37.y, (r)(last)hr37.y, hr47.w, (r)(last)hr40.y
(rpt1)mad.f16 hr37.w, (r)(last)hr37.w, hr47.w, (r)(last)hr40.w
(rpt1)mad.f16 hr42.y, (r)(last)hr42.y, hr47.w, (r)(last)hr41.y
(rpt1)mad.f16 hr42.w, (r)(last)hr42.w, hr47.w, (r)(last)hr41.w
(rpt1)mad.f16 hr45.w, (r)(last)hr45.w, hr47.w, (r)(last)hr6.y
(rpt1)mad.f16 hr46.y, (r)(last)hr46.y, hr47.w, (r)(last)hr6.w
(sy)mad.f16 hr35.x, hr46.w, hr39.x, (last)hr35.x
mad.f16 hr31.x, hr46.w, hr39.y, (last)hr31.x
mad.f16 hr27.x, hr46.w, hr39.z, (last)hr27.x
mad.f16 hr23.x, hr46.w, hr39.w, (last)hr23.x
mad.f16 hr19.x, hr46.w, hr4.x, (last)hr19.x
mad.f16 hr15.x, hr46.w, hr4.y, (last)hr15.x
mad.f16 hr11.x, hr46.w, hr4.z, (last)hr11.x
mad.f16 hr35.y, hr47.x, hr39.x, (last)hr35.y
mad.f16 hr31.y, hr47.x, hr39.y, (last)hr31.y
mad.f16 hr27.y, hr47.x, hr39.z, (last)hr27.y
mad.f16 hr23.y, hr47.x, hr39.w, (last)hr23.y
mad.f16 hr19.y, hr47.x, hr4.x, (last)hr19.y
mad.f16 hr15.y, hr47.x, hr4.y, (last)hr15.y
mad.f16 hr11.y, hr47.x, hr4.z, (last)hr11.y
mad.f16 hr35.z, hr47.y, hr39.x, (last)hr35.z
mad.f16 hr31.z, hr47.y, hr39.y, (last)hr31.z
mad.f16 hr27.z, hr47.y, hr39.z, (last)hr27.z
mad.f16 hr23.z, hr47.y, hr39.w, (last)hr23.z
mad.f16 hr19.z, hr47.y, hr4.x, (last)hr19.z
mad.f16 hr15.z, hr47.y, hr4.y, (last)hr15.z
mad.f16 hr11.z, hr47.y, hr4.z, (last)hr11.z
mad.f16 hr35.w, hr47.z, hr39.x, (last)hr35.w
mad.f16 hr31.w, hr47.z, hr39.y, (last)hr31.w
mad.f16 hr27.w, hr47.z, hr39.z, (last)hr27.w
mad.f16 hr23.w, hr47.z, hr39.w, (last)hr23.w
mad.f16 hr19.w, hr47.z, hr4.x, (last)hr19.w
mad.f16 hr15.w, hr47.z, hr4.y, (last)hr15.w
mad.f16 hr11.w, hr47.z, hr4.z, (last)hr11.w
mad.f16 hr18.x, hr0.y, hr4.x, (last)hr18.x
mad.f16 hr14.x, hr0.y, hr4.y, (last)hr14.x
mad.f16 hr10.x, hr0.y, hr4.z, (last)hr10.x
mad.f16 hr18.y, hr0.z, hr4.x, (last)hr18.y
mad.f16 hr14.y, hr0.z, hr4.y, (last)hr14.y
mad.f16 hr10.y, hr0.z, hr4.z, (last)hr10.y
mad.f16 hr18.z, hr0.w, hr4.x, (last)hr18.z
mad.f16 hr14.z, hr0.w, hr4.y, (last)hr14.z
mad.f16 hr10.z, hr0.w, hr4.z, (last)hr10.z
mad.f16 hr18.w, hr1.x, hr4.x, (last)hr18.w
mad.f16 hr14.w, hr1.x, hr4.y, (last)hr14.w
mad.f16 hr10.w, hr1.x, hr4.z, (last)hr10.w
mad.f16 hr7.y, (last)hr47.x, hr4.w, (last)hr36.z
(rpt1)mad.f16 hr7.z, (r)(last)hr47.y, hr4.w, (r)(last)hr36.w
mad.f16 hr17.x, hr1.y, hr4.x, (last)hr17.x
mad.f16 hr13.x, hr1.y, hr4.y, (last)hr13.x
mad.f16 hr9.x, hr1.y, hr4.z, (last)hr9.x
mad.f16 hr17.y, hr1.z, hr4.x, (last)hr17.y
mad.f16 hr13.y, hr1.z, hr4.y, (last)hr13.y
mad.f16 hr9.y, hr1.z, hr4.z, (last)hr9.y
mad.f16 hr17.z, hr1.w, hr4.x, (last)hr17.z
mad.f16 hr13.z, hr1.w, hr4.y, (last)hr13.z
mad.f16 hr9.z, hr1.w, hr4.z, (last)hr9.z
mad.f16 hr17.w, hr2.x, hr4.x, (last)hr17.w
mad.f16 hr13.w, hr2.x, hr4.y, (last)hr13.w
mad.f16 hr9.w, hr2.x, hr4.z, (last)hr9.w
mad.f16 hr16.x, hr2.y, hr4.x, (last)hr16.x
mad.f16 hr12.x, hr2.y, hr4.y, (last)hr12.x
mad.f16 hr8.x, hr2.y, hr4.z, (last)hr8.x
mad.f16 hr16.y, hr2.z, hr4.x, (last)hr16.y
mad.f16 hr12.y, hr2.z, hr4.y, (last)hr12.y
mad.f16 hr8.y, hr2.z, hr4.z, (last)hr8.y
(rpt1)mad.f16 hr16.z, (r)hr2.w, hr4.x, (r)(last)hr16.z
(rpt1)mad.f16 hr12.z, (r)hr2.w, hr4.y, (r)(last)hr12.z
(rpt1)mad.f16 hr8.z, (r)hr2.w, hr4.z, (r)(last)hr8.z
bar.g
(sy)(ss)mad.f16 hr34.x, hr0.y, hr39.x, (last)hr34.x
mad.f16 hr30.x, hr0.y, hr39.y, (last)hr30.x
mad.f16 hr26.x, hr0.y, hr39.z, (last)hr26.x
mad.f16 hr22.x, hr0.y, hr39.w, (last)hr22.x
mad.f16 hr34.y, hr0.z, hr39.x, (last)hr34.y
mad.f16 hr30.y, hr0.z, hr39.y, (last)hr30.y
mad.f16 hr26.y, hr0.z, hr39.z, (last)hr26.y
mad.f16 hr22.y, hr0.z, hr39.w, (last)hr22.y
mad.f16 hr34.z, hr0.w, hr39.x, (last)hr34.z
mad.f16 hr30.z, hr0.w, hr39.y, (last)hr30.z
mad.f16 hr26.z, hr0.w, hr39.z, (last)hr26.z
mad.f16 hr22.z, hr0.w, hr39.w, (last)hr22.z
mad.f16 hr34.w, hr1.x, hr39.x, (last)hr34.w
mad.f16 hr30.w, hr1.x, hr39.y, (last)hr30.w
mad.f16 hr26.w, hr1.x, hr39.z, (last)hr26.w
mad.f16 hr22.w, hr1.x, hr39.w, (last)hr22.w
mad.f16 hr33.x, hr1.y, hr39.x, (last)hr33.x
mad.f16 hr29.x, hr1.y, hr39.y, (last)hr29.x
mad.f16 hr25.x, hr1.y, hr39.z, (last)hr25.x
mad.f16 hr21.x, hr1.y, hr39.w, (last)hr21.x
mad.f16 hr33.y, hr1.z, hr39.x, (last)hr33.y
mad.f16 hr29.y, hr1.z, hr39.y, (last)hr29.y
mad.f16 hr25.y, hr1.z, hr39.z, (last)hr25.y
mad.f16 hr21.y, hr1.z, hr39.w, (last)hr21.y
mad.f16 hr33.z, hr1.w, hr39.x, (last)hr33.z
mad.f16 hr29.z, hr1.w, hr39.y, (last)hr29.z
mad.f16 hr25.z, hr1.w, hr39.z, (last)hr25.z
mad.f16 hr21.z, hr1.w, hr39.w, (last)hr21.z
mad.f16 hr33.w, hr2.x, hr39.x, (last)hr33.w
mad.f16 hr29.w, hr2.x, hr39.y, (last)hr29.w
mad.f16 hr25.w, hr2.x, hr39.z, (last)hr25.w
mad.f16 hr21.w, hr2.x, hr39.w, (last)hr21.w
mad.f16 hr32.x, hr2.y, hr39.x, (last)hr32.x
mad.f16 hr28.x, hr2.y, hr39.y, (last)hr28.x
mad.f16 hr24.x, hr2.y, hr39.z, (last)hr24.x
mad.f16 hr20.x, hr2.y, hr39.w, (last)hr20.x
mad.f16 hr32.y, hr2.z, hr39.x, (last)hr32.y
mad.f16 hr28.y, hr2.z, hr39.y, (last)hr28.y
mad.f16 hr24.y, hr2.z, hr39.z, (last)hr24.y
mad.f16 hr20.y, hr2.z, hr39.w, (last)hr20.y
(rpt1)mad.f16 hr32.z, (r)hr2.w, hr39.x, (r)(last)hr32.z
(rpt1)mad.f16 hr28.z, (r)hr2.w, hr39.y, (r)(last)hr28.z
(rpt1)mad.f16 hr24.z, (r)hr2.w, hr39.z, (r)(last)hr24.z
(rpt1)mad.f16 hr20.z, (r)hr2.w, hr39.w, (r)(last)hr20.z
mad.f16 hr6.x, (last)hr0.y, hr4.w, (last)hr37.y
(rpt1)mad.f16 hr5.x, (r)(last)hr1.y, hr4.w, (r)(last)hr42.y
(rpt1)mad.f16 hr5.z, (r)(last)hr1.w, hr4.w, (r)(last)hr42.w
mad.f16 hr36.x, (last)hr2.y, hr4.w, (last)hr45.w
mad.f16 hr6.y, (last)hr0.z, hr4.w, (last)hr37.z
(rpt1)mad.f16 hr6.z, (r)(last)hr0.w, hr4.w, (r)(last)hr37.w
mad.f16 hr7.x, (last)hr46.w, hr4.w, (last)hr36.y
(rpt1)mad.f16 hr36.z, (r)(last)hr2.w, hr4.w, (r)(last)hr46.y
mad.f16 hr36.y, (last)hr2.z, hr4.w, (last)hr46.x
br p0.x, #l2308
mov.u16u16 hr4.x, hr36.x
mov.u16u16 hr4.z, hr36.z
mov.u16u16 hr4.w, hr36.w
mov.u16u16 hr4.y, hr36.y
mov.u32u32 r0.x, (last)r22.z
mov.u32u32 r1.x, (last)r24.x
mov.u32u32 r1.y, (last)r24.y
mov.u32u32 r1.z, (last)r24.z
mov.u32u32 r0.w, (last)r36.x
jump #l243
l2308:
(jp)(eolm)nop
(nop3) add.u r26.z, r54.y, (last)r26.z
(nop3) shl.b r26.z, (last)r26.z, 9
(nop3) sad.s32 r26.z, r55.y, r26.z, (last)r1.w
(nop3) shl.b r26.z, (last)r26.z, 2
add.u r18.z, r26.z, c1.x
add.u r18.w, r26.z, c8.y
add.u r19.x, r26.z, c12.x
add.u r19.y, r26.z, c15.w
add.u r19.z, r26.z, c4.z
add.u r19.w, r26.z, c8.x
add.u r20.x, r26.z, c11.w
add.u r20.y, r26.z, c15.z
add.u r20.z, r26.z, c4.y
add.u r20.w, r26.z, c7.w
add.u r21.x, r26.z, c11.z
add.u r21.y, r26.z, c15.y
(rpt1)add.u r21.z, r26.z, (r)c16.x
(rpt1)add.u r22.x, (r)c16.z, r26.z
(rpt1)add.u r22.z, r26.z, (r)c17.x
(rpt1)add.u r23.x, (r)c17.z, r26.z
(rpt1)add.u r23.z, r26.z, (r)c18.x
(rpt1)add.u r24.x, (r)c18.z, r26.z
(rpt1)add.u r24.z, r26.z, (r)c19.x
(rpt1)add.u r25.x, (r)c19.z, r26.z
stib.b.untyped.1d.u16.4.imm.base0 hr35.x, r26.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr34.x, r26.z+32, 4
stib.b.untyped.1d.u16.4.imm.base0 hr33.x, r26.z+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr32.x, r26.z+96, 4
stib.b.untyped.1d.u16.4.imm.base0 hr31.x, r18.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr30.x, r18.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr29.x, r19.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr28.x, r19.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr27.x, r19.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr26.x, r19.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr25.x, r20.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr24.x, r20.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr23.x, r20.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr22.x, r20.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr21.x, r21.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr20.x, r21.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr19.x, r21.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr18.x, r21.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr17.x, r22.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.x, r22.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.x, r22.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.x, r22.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.x, r23.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.x, r23.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.x, r23.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.x, r23.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr9.x, r24.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr8.x, r24.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.x, r24.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.x, r24.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r25.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr36.x, r25.y, 4
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
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 2519 instr, 25 nops, 2494 non-nops, 163 mov, 0 cov, 4768 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 37 full, 20 constlen
; CL prog 23/1: 28 cat0, 163 cat1, 134 cat2, 2054 cat3, 0 cat4, 68 cat5, 68 cat6, 4 cat7
; CL prog 23/1: 9 sstall, 17 (ss), 1113 systall, 46 (sy), 1 loops
; CL prog 23/1: 6 max_waves, 0 double_threadsize
; 106 preamble-instr, 1 early-preamble
