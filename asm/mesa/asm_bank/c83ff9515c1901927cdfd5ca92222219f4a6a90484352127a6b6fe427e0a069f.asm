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
@const(c8.x)	0x00001040, 0x00000840, 0x00020000, 0x00020040
@const(c9.x)	0x00020800, 0x00020840, 0x00021000, 0x00021040
@const(c10.x)	0x00021800, 0x00021840, 0xd0d0d0d0, 0xd0d0d0d0
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
mov.u32u32 r49.y, 0x20000
mov.u32u32 r49.z, 0x20040
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 4
stc.u32 c[20], r52.w, 4
stc.u32 c[24], r53.w, 4
stc.u32 c[28], r54.w, 4
(ss)mov.u32u32 r49.w, 0x20800
mov.u32u32 r50.x, 0x20840
mov.u32u32 r50.y, 0x21000
mov.u32u32 r50.z, 0x21040
mov.u32u32 r50.w, 0x21800
mov.u32u32 r51.x, 0x21840
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
shl.b r51.w, r51.z, 7
shr.b r0.w, r0.x, 5
and.b r1.x, r0.x, 31
shr.b r1.y, r0.x, 4
and.b r1.z, r0.x, 15
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
l130:
(rpt1)shr.b r52.z, (r)r51.w, 2
shl.b r53.x, r52.y, 9
add.u r10.y, r0.x, 256
shl.b r9.w, r0.w, 8
shl.b r10.x, r1.x, 3
shl.b r10.z, r1.y, 3
shr.b r10.y, (last)r10.y, 5
shl.b r11.w, r1.y, 2
(ss)add.u r10.w, r52.y, r0.w
sad.s32 r12.z, r53.x, r1.z, r52.w
add.u r11.x, r52.y, r10.y
add.u r52.y, r52.y, 16
cmps.u.ge up0.x, r52.y, c1.x
shl.b r10.y, (last)r10.y, 8
shl.b r10.w, (last)r10.w, 9
add.u r9.w, (last)r9.w, r10.x
shl.b r11.x, (last)r11.x, 9
shl.b r12.z, (last)r12.z, 2
sad.s32 r10.w, r52.z, r10.w, r1.x
add.u r10.y, (last)r10.y, (last)r10.x
sad.s32 r11.x, r52.z, r11.x, r1.x
add.u r12.w, r12.z, c1.x
shl.b r10.w, (last)r10.w, 2
add.u r13.x, r12.z, c8.y
shl.b r11.x, (last)r11.x, 2
add.u r13.y, r12.z, c4.z
add.u r13.z, r12.z, c8.x
add.u r13.w, r12.z, c4.y
add.u r14.x, r12.z, c7.w
isam.v.base0 (u16)(xyzw)hr22.z, r10.w, s#0, t#0
add.u r14.y, r12.z, c4.x
add.u r14.z, r12.z, c7.z
isam.v.base0 (u16)(xyzw)hr24.x, r11.x, s#0, t#0
add.u r14.w, r12.z, c3.w
add.u r15.x, r12.z, c7.y
add.u r15.y, r12.z, c3.z
add.u r15.z, r12.z, c7.x
add.u r15.w, r12.z, c3.y
add.u r16.x, r12.z, c6.w
add.u r16.y, r12.z, c3.x
add.u r16.z, r12.z, c6.z
add.u r16.w, r12.z, c2.w
add.u r17.x, r12.z, c6.y
add.u r17.y, r12.z, c2.z
add.u r17.z, r12.z, c6.x
add.u r17.w, r12.z, c2.y
add.u r18.x, r12.z, c5.w
add.u r18.y, r12.z, c2.x
add.u r18.z, r12.z, c5.z
add.u r18.w, r12.z, c1.w
add.u r19.x, r12.z, c5.y
add.u r19.y, r12.z, c1.z
add.u r19.z, r12.z, c5.x
add.u r19.w, r12.z, c1.y
add.u r20.x, r12.z, c4.w
(sy)stl.u16 l[r9.w], r22.z, 4
stl.u16 l[r10.y], r24.x, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
isam.v.base0 (u16)(xyzw)hr19.w, r12.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr24.x, r12.z+64, s#0, t#2
ldl.u16 r40.z, l[r10.z], 4
ldl.u16 r21.z, l[r10.z+128], 4
ldl.u16 r0.z, l[r10.z+256], 4
(sy)(ss)mad.f16 hr18.z, hr19.w, hr40.z, (last)hr18.z
mad.f16 hr16.z, hr19.w, hr40.w, (last)hr16.z
mad.f16 hr14.z, hr19.w, hr41.x, (last)hr14.z
mad.f16 hr12.z, hr19.w, hr41.y, (last)hr12.z
mad.f16 hr18.w, hr20.x, hr40.z, (last)hr18.w
mad.f16 hr16.w, hr20.x, hr40.w, (last)hr16.w
mad.f16 hr14.w, hr20.x, hr41.x, (last)hr14.w
mad.f16 hr12.w, hr20.x, hr41.y, (last)hr12.w
mad.f16 hr19.x, hr20.y, hr40.z, (last)hr19.x
mad.f16 hr17.x, hr20.y, hr40.w, (last)hr17.x
mad.f16 hr15.x, hr20.y, hr41.x, (last)hr15.x
mad.f16 hr13.x, hr20.y, hr41.y, (last)hr13.x
mad.f16 hr19.y, hr20.z, hr40.z, (last)hr19.y
mad.f16 hr17.y, hr20.z, hr40.w, (last)hr17.y
mad.f16 hr15.y, hr20.z, hr41.x, (last)hr15.y
mad.f16 hr13.y, hr20.z, hr41.y, (last)hr13.y
mad.f16 hr17.z, hr24.x, hr40.z, (last)hr17.z
mad.f16 hr15.z, hr24.x, hr40.w, (last)hr15.z
mad.f16 hr13.z, hr24.x, hr41.x, (last)hr13.z
mad.f16 hr11.z, hr24.x, hr41.y, (last)hr11.z
mad.f16 hr17.w, hr24.y, hr40.z, (last)hr17.w
mad.f16 hr15.w, hr24.y, hr40.w, (last)hr15.w
mad.f16 hr13.w, hr24.y, hr41.x, (last)hr13.w
mad.f16 hr11.w, hr24.y, hr41.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr24.z, hr40.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr24.z, hr40.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr24.z, hr41.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr24.z, hr41.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.z, (r)hr19.w, hr21.z, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr20.y, hr21.z, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr19.w, hr21.w, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr20.y, hr21.w, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr19.w, hr22.x, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr20.y, hr22.x, (r)(last)hr7.x
mad.f16 hr9.z, hr24.x, hr21.z, (last)hr9.z
mad.f16 hr7.z, hr24.x, hr21.w, (last)hr7.z
mad.f16 hr5.z, hr24.x, hr22.x, (last)hr5.z
mad.f16 hr9.w, hr24.y, hr21.z, (last)hr9.w
mad.f16 hr7.w, hr24.y, hr21.w, (last)hr7.w
mad.f16 hr5.w, hr24.y, hr22.x, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr24.z, hr21.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr24.z, hr21.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr24.z, hr22.x, (r)(last)hr6.x
(rpt1)mad.f16 hr19.w, (r)(last)hr19.w, hr22.y, (r)(last)hr4.z
(rpt1)mad.f16 hr20.y, (r)(last)hr20.y, hr22.y, (r)(last)hr5.x
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr22.y, (r)(last)hr3.z
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr22.y, (r)(last)hr4.x
isam.v.base0 (u16)(xyzw)hr22.x, r12.w, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr25.y, r13.x, s#0, t#2
ldl.u16 r3.z, l[r10.z+384], 4
ldl.u16 r40.z, l[r10.z+512], 4
(sy)mad.f16 hr18.z, hr22.x, hr0.z, (last)hr18.z
mad.f16 hr16.z, hr22.x, hr0.w, (last)hr16.z
mad.f16 hr14.z, hr22.x, hr1.x, (last)hr14.z
mad.f16 hr12.z, hr22.x, hr1.y, (last)hr12.z
mad.f16 hr18.w, hr22.y, hr0.z, (last)hr18.w
mad.f16 hr16.w, hr22.y, hr0.w, (last)hr16.w
mad.f16 hr14.w, hr22.y, hr1.x, (last)hr14.w
mad.f16 hr12.w, hr22.y, hr1.y, (last)hr12.w
mad.f16 hr19.x, hr22.z, hr0.z, (last)hr19.x
mad.f16 hr17.x, hr22.z, hr0.w, (last)hr17.x
mad.f16 hr15.x, hr22.z, hr1.x, (last)hr15.x
mad.f16 hr13.x, hr22.z, hr1.y, (last)hr13.x
mad.f16 hr19.y, hr22.w, hr0.z, (last)hr19.y
mad.f16 hr17.y, hr22.w, hr0.w, (last)hr17.y
mad.f16 hr15.y, hr22.w, hr1.x, (last)hr15.y
mad.f16 hr13.y, hr22.w, hr1.y, (last)hr13.y
mad.f16 hr17.z, hr25.y, hr0.z, (last)hr17.z
mad.f16 hr15.z, hr25.y, hr0.w, (last)hr15.z
mad.f16 hr13.z, hr25.y, hr1.x, (last)hr13.z
mad.f16 hr11.z, hr25.y, hr1.y, (last)hr11.z
mad.f16 hr17.w, hr25.z, hr0.z, (last)hr17.w
mad.f16 hr15.w, hr25.z, hr0.w, (last)hr15.w
mad.f16 hr13.w, hr25.z, hr1.x, (last)hr13.w
mad.f16 hr11.w, hr25.z, hr1.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr25.w, hr0.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr25.w, hr0.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr25.w, hr1.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr25.w, hr1.y, (r)(last)hr12.x
ldl.u16 r0.z, l[r10.z+640], 4
(ss)mad.f16 hr10.z, hr22.x, hr3.z, (last)hr10.z
mad.f16 hr8.z, hr22.x, hr3.w, (last)hr8.z
mad.f16 hr6.z, hr22.x, hr4.x, (last)hr6.z
mad.f16 hr10.w, hr22.y, hr3.z, (last)hr10.w
mad.f16 hr8.w, hr22.y, hr3.w, (last)hr8.w
mad.f16 hr6.w, hr22.y, hr4.x, (last)hr6.w
mad.f16 hr11.x, hr22.z, hr3.z, (last)hr11.x
mad.f16 hr9.x, hr22.z, hr3.w, (last)hr9.x
mad.f16 hr7.x, hr22.z, hr4.x, (last)hr7.x
mad.f16 hr11.y, hr22.w, hr3.z, (last)hr11.y
mad.f16 hr9.y, hr22.w, hr3.w, (last)hr9.y
mad.f16 hr7.y, hr22.w, hr4.x, (last)hr7.y
mad.f16 hr9.z, hr25.y, hr3.z, (last)hr9.z
mad.f16 hr7.z, hr25.y, hr3.w, (last)hr7.z
mad.f16 hr5.z, hr25.y, hr4.x, (last)hr5.z
mad.f16 hr9.w, hr25.z, hr3.z, (last)hr9.w
mad.f16 hr7.w, hr25.z, hr3.w, (last)hr7.w
mad.f16 hr5.w, hr25.z, hr4.x, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr25.w, hr3.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr25.w, hr3.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr25.w, hr4.x, (r)(last)hr6.x
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr4.y, (r)(last)hr19.w
(rpt1)mad.f16 hr22.z, (r)(last)hr22.z, hr4.y, (r)(last)hr20.y
(rpt1)mad.f16 hr25.y, (r)(last)hr25.y, hr4.y, (r)(last)hr24.x
(rpt1)mad.f16 hr25.w, (r)(last)hr25.w, hr4.y, (r)(last)hr24.z
isam.v.base0 (u16)(xyzw)hr3.w, r13.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr19.w, r13.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr24.x, r13.w, s#0, t#2
(sy)mad.f16 hr18.z, hr3.w, hr40.z, (last)hr18.z
mad.f16 hr16.z, hr3.w, hr40.w, (last)hr16.z
mad.f16 hr14.z, hr3.w, hr41.x, (last)hr14.z
mad.f16 hr12.z, hr3.w, hr41.y, (last)hr12.z
mad.f16 hr10.z, hr3.w, hr0.z, (last)hr10.z
mad.f16 hr8.z, hr3.w, hr0.w, (last)hr8.z
mad.f16 hr6.z, hr3.w, hr1.x, (last)hr6.z
mad.f16 hr18.w, hr4.x, hr40.z, (last)hr18.w
mad.f16 hr16.w, hr4.x, hr40.w, (last)hr16.w
mad.f16 hr14.w, hr4.x, hr41.x, (last)hr14.w
mad.f16 hr12.w, hr4.x, hr41.y, (last)hr12.w
mad.f16 hr10.w, hr4.x, hr0.z, (last)hr10.w
mad.f16 hr8.w, hr4.x, hr0.w, (last)hr8.w
mad.f16 hr6.w, hr4.x, hr1.x, (last)hr6.w
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr1.y, (r)(last)hr22.x
ldl.u16 r21.z, l[r10.z+768], 4
mad.f16 hr19.x, hr4.y, hr40.z, (last)hr19.x
mad.f16 hr17.x, hr4.y, hr40.w, (last)hr17.x
mad.f16 hr15.x, hr4.y, hr41.x, (last)hr15.x
mad.f16 hr13.x, hr4.y, hr41.y, (last)hr13.x
mad.f16 hr11.x, hr4.y, hr0.z, (last)hr11.x
mad.f16 hr9.x, hr4.y, hr0.w, (last)hr9.x
mad.f16 hr7.x, hr4.y, hr1.x, (last)hr7.x
mad.f16 hr19.y, hr4.z, hr40.z, (last)hr19.y
mad.f16 hr17.y, hr4.z, hr40.w, (last)hr17.y
mad.f16 hr15.y, hr4.z, hr41.x, (last)hr15.y
mad.f16 hr13.y, hr4.z, hr41.y, (last)hr13.y
mad.f16 hr11.y, hr4.z, hr0.z, (last)hr11.y
mad.f16 hr9.y, hr4.z, hr0.w, (last)hr9.y
mad.f16 hr7.y, hr4.z, hr1.x, (last)hr7.y
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr1.y, (r)(last)hr22.z
ldl.u16 r22.z, l[r10.z+896], 4
mad.f16 hr17.z, hr19.w, hr40.z, (last)hr17.z
mad.f16 hr15.z, hr19.w, hr40.w, (last)hr15.z
mad.f16 hr13.z, hr19.w, hr41.x, (last)hr13.z
mad.f16 hr11.z, hr19.w, hr41.y, (last)hr11.z
mad.f16 hr9.z, hr19.w, hr0.z, (last)hr9.z
mad.f16 hr7.z, hr19.w, hr0.w, (last)hr7.z
mad.f16 hr5.z, hr19.w, hr1.x, (last)hr5.z
mad.f16 hr17.w, hr20.x, hr40.z, (last)hr17.w
mad.f16 hr15.w, hr20.x, hr40.w, (last)hr15.w
mad.f16 hr13.w, hr20.x, hr41.x, (last)hr13.w
mad.f16 hr11.w, hr20.x, hr41.y, (last)hr11.w
mad.f16 hr9.w, hr20.x, hr0.z, (last)hr9.w
mad.f16 hr7.w, hr20.x, hr0.w, (last)hr7.w
mad.f16 hr5.w, hr20.x, hr1.x, (last)hr5.w
mad.f16 hr18.x, hr20.y, hr40.z, (last)hr18.x
mad.f16 hr16.x, hr20.y, hr40.w, (last)hr16.x
mad.f16 hr14.x, hr20.y, hr41.x, (last)hr14.x
mad.f16 hr12.x, hr20.y, hr41.y, (last)hr12.x
mad.f16 hr10.x, hr20.y, hr0.z, (last)hr10.x
mad.f16 hr8.x, hr20.y, hr0.w, (last)hr8.x
mad.f16 hr6.x, hr20.y, hr1.x, (last)hr6.x
(rpt1)mad.f16 hr19.w, (r)(last)hr19.w, hr1.y, (r)(last)hr25.y
mad.f16 hr20.y, (last)hr20.y, hr1.y, (last)hr25.w
isam.v.base0 (u16)(xyzw)hr25.x, r14.x, s#0, t#2
mad.f16 hr16.y, hr20.z, hr40.w, (last)hr16.y
mad.f16 hr14.y, hr20.z, hr41.x, (last)hr14.y
mad.f16 hr12.y, hr20.z, hr41.y, (last)hr12.y
isam.v.base0 (u16)(xyzw)hr40.w, r14.y, s#0, t#2
(ss)mad.f16 hr18.z, hr24.x, hr21.z, (last)hr18.z
mad.f16 hr16.z, hr24.x, hr21.w, (last)hr16.z
mad.f16 hr14.z, hr24.x, hr22.x, (last)hr14.z
mad.f16 hr12.z, hr24.x, hr22.y, (last)hr12.z
mad.f16 hr18.w, hr24.y, hr21.z, (last)hr18.w
mad.f16 hr16.w, hr24.y, hr21.w, (last)hr16.w
mad.f16 hr14.w, hr24.y, hr22.x, (last)hr14.w
mad.f16 hr12.w, hr24.y, hr22.y, (last)hr12.w
mad.f16 hr19.x, hr24.z, hr21.z, (last)hr19.x
mad.f16 hr17.x, hr24.z, hr21.w, (last)hr17.x
mad.f16 hr15.x, hr24.z, hr22.x, (last)hr15.x
mad.f16 hr13.x, hr24.z, hr22.y, (last)hr13.x
mad.f16 hr19.y, hr24.w, hr21.z, (last)hr19.y
mad.f16 hr17.y, hr24.w, hr21.w, (last)hr17.y
mad.f16 hr15.y, hr24.w, hr22.x, (last)hr15.y
mad.f16 hr13.y, hr24.w, hr22.y, (last)hr13.y
mad.f16 hr10.z, hr24.x, hr22.z, (last)hr10.z
mad.f16 hr8.z, hr24.x, hr22.w, (last)hr8.z
mad.f16 hr6.z, hr24.x, hr23.x, (last)hr6.z
mad.f16 hr10.w, hr24.y, hr22.z, (last)hr10.w
mad.f16 hr8.w, hr24.y, hr22.w, (last)hr8.w
mad.f16 hr6.w, hr24.y, hr23.x, (last)hr6.w
mad.f16 hr11.x, hr24.z, hr22.z, (last)hr11.x
mad.f16 hr9.x, hr24.z, hr22.w, (last)hr9.x
mad.f16 hr7.x, hr24.z, hr23.x, (last)hr7.x
mad.f16 hr11.y, hr24.w, hr22.z, (last)hr11.y
mad.f16 hr9.y, hr24.w, hr22.w, (last)hr9.y
mad.f16 hr7.y, hr24.w, hr23.x, (last)hr7.y
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr23.y, (r)(last)hr3.w
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr23.y, (r)(last)hr4.y
isam.v.base0 (u16)(xyzw)hr3.w, r14.z, s#0, t#2
mad.f16 hr18.y, hr20.z, hr40.z, (last)hr18.y
mad.f16 hr10.y, hr20.z, hr0.z, (last)hr10.y
mad.f16 hr8.y, hr20.z, hr0.w, (last)hr8.y
mad.f16 hr6.y, hr20.z, hr1.x, (last)hr6.y
mad.f16 hr20.z, (last)hr20.z, hr1.y, (last)hr26.x
ldl.u16 r26.x, l[r10.z+1024], 4
ldl.u16 r27.x, l[r10.z+1152], 4
(sy)mad.f16 hr17.z, hr25.x, hr21.z, (last)hr17.z
mad.f16 hr15.z, hr25.x, hr21.w, (last)hr15.z
mad.f16 hr13.z, hr25.x, hr22.x, (last)hr13.z
mad.f16 hr11.z, hr25.x, hr22.y, (last)hr11.z
mad.f16 hr9.z, hr25.x, hr22.z, (last)hr9.z
mad.f16 hr7.z, hr25.x, hr22.w, (last)hr7.z
mad.f16 hr5.z, hr25.x, hr23.x, (last)hr5.z
mad.f16 hr17.w, hr25.y, hr21.z, (last)hr17.w
mad.f16 hr15.w, hr25.y, hr21.w, (last)hr15.w
mad.f16 hr13.w, hr25.y, hr22.x, (last)hr13.w
mad.f16 hr11.w, hr25.y, hr22.y, (last)hr11.w
mad.f16 hr9.w, hr25.y, hr22.z, (last)hr9.w
mad.f16 hr7.w, hr25.y, hr22.w, (last)hr7.w
mad.f16 hr5.w, hr25.y, hr23.x, (last)hr5.w
mad.f16 hr18.x, hr25.z, hr21.z, (last)hr18.x
mad.f16 hr16.x, hr25.z, hr21.w, (last)hr16.x
mad.f16 hr14.x, hr25.z, hr22.x, (last)hr14.x
mad.f16 hr12.x, hr25.z, hr22.y, (last)hr12.x
mad.f16 hr10.x, hr25.z, hr22.z, (last)hr10.x
mad.f16 hr8.x, hr25.z, hr22.w, (last)hr8.x
mad.f16 hr6.x, hr25.z, hr23.x, (last)hr6.x
mad.f16 hr16.y, hr25.w, hr21.w, (last)hr16.y
mad.f16 hr14.y, hr25.w, hr22.x, (last)hr14.y
mad.f16 hr12.y, hr25.w, hr22.y, (last)hr12.y
mad.f16 hr18.y, hr25.w, hr21.z, (last)hr18.y
mad.f16 hr10.y, hr25.w, hr22.z, (last)hr10.y
mad.f16 hr8.y, hr25.w, hr22.w, (last)hr8.y
mad.f16 hr6.y, hr25.w, hr23.x, (last)hr6.y
(rpt1)mad.f16 hr25.x, (r)(last)hr25.x, hr23.y, (r)(last)hr19.w
mad.f16 hr25.z, (last)hr25.z, hr23.y, (last)hr20.y
ldl.u16 r19.z, l[r10.z+1280], 4
ldl.u16 r21.z, l[r10.z+1408], 4
mad.f16 hr25.w, (last)hr25.w, hr23.y, (last)hr20.z
(ss)mad.f16 hr18.z, hr40.w, hr26.x, (last)hr18.z
mad.f16 hr16.z, hr40.w, hr26.y, (last)hr16.z
mad.f16 hr14.z, hr40.w, hr26.z, (last)hr14.z
mad.f16 hr12.z, hr40.w, hr26.w, (last)hr12.z
mad.f16 hr18.w, hr41.x, hr26.x, (last)hr18.w
mad.f16 hr16.w, hr41.x, hr26.y, (last)hr16.w
mad.f16 hr14.w, hr41.x, hr26.z, (last)hr14.w
mad.f16 hr12.w, hr41.x, hr26.w, (last)hr12.w
mad.f16 hr19.x, hr41.y, hr26.x, (last)hr19.x
mad.f16 hr17.x, hr41.y, hr26.y, (last)hr17.x
mad.f16 hr15.x, hr41.y, hr26.z, (last)hr15.x
mad.f16 hr13.x, hr41.y, hr26.w, (last)hr13.x
mad.f16 hr19.y, hr41.z, hr26.x, (last)hr19.y
mad.f16 hr17.y, hr41.z, hr26.y, (last)hr17.y
mad.f16 hr15.y, hr41.z, hr26.z, (last)hr15.y
mad.f16 hr13.y, hr41.z, hr26.w, (last)hr13.y
mad.f16 hr10.z, hr40.w, hr27.x, (last)hr10.z
mad.f16 hr8.z, hr40.w, hr27.y, (last)hr8.z
mad.f16 hr6.z, hr40.w, hr27.z, (last)hr6.z
mad.f16 hr10.w, hr41.x, hr27.x, (last)hr10.w
mad.f16 hr8.w, hr41.x, hr27.y, (last)hr8.w
mad.f16 hr6.w, hr41.x, hr27.z, (last)hr6.w
mad.f16 hr11.x, hr41.y, hr27.x, (last)hr11.x
mad.f16 hr9.x, hr41.y, hr27.y, (last)hr9.x
mad.f16 hr7.x, hr41.y, hr27.z, (last)hr7.x
mad.f16 hr11.y, hr41.z, hr27.x, (last)hr11.y
mad.f16 hr9.y, hr41.z, hr27.y, (last)hr9.y
mad.f16 hr7.y, hr41.z, hr27.z, (last)hr7.y
mad.f16 hr17.z, hr3.w, hr26.x, (last)hr17.z
mad.f16 hr15.z, hr3.w, hr26.y, (last)hr15.z
mad.f16 hr13.z, hr3.w, hr26.z, (last)hr13.z
mad.f16 hr11.z, hr3.w, hr26.w, (last)hr11.z
mad.f16 hr9.z, hr3.w, hr27.x, (last)hr9.z
mad.f16 hr7.z, hr3.w, hr27.y, (last)hr7.z
mad.f16 hr5.z, hr3.w, hr27.z, (last)hr5.z
mad.f16 hr17.w, hr4.x, hr26.x, (last)hr17.w
mad.f16 hr15.w, hr4.x, hr26.y, (last)hr15.w
mad.f16 hr13.w, hr4.x, hr26.z, (last)hr13.w
mad.f16 hr11.w, hr4.x, hr26.w, (last)hr11.w
mad.f16 hr9.w, hr4.x, hr27.x, (last)hr9.w
mad.f16 hr7.w, hr4.x, hr27.y, (last)hr7.w
mad.f16 hr5.w, hr4.x, hr27.z, (last)hr5.w
mad.f16 hr18.x, hr4.y, hr26.x, (last)hr18.x
mad.f16 hr16.x, hr4.y, hr26.y, (last)hr16.x
mad.f16 hr14.x, hr4.y, hr26.z, (last)hr14.x
mad.f16 hr12.x, hr4.y, hr26.w, (last)hr12.x
mad.f16 hr10.x, hr4.y, hr27.x, (last)hr10.x
mad.f16 hr8.x, hr4.y, hr27.y, (last)hr8.x
mad.f16 hr6.x, hr4.y, hr27.z, (last)hr6.x
mad.f16 hr16.y, hr4.z, hr26.y, (last)hr16.y
mad.f16 hr14.y, hr4.z, hr26.z, (last)hr14.y
mad.f16 hr12.y, hr4.z, hr26.w, (last)hr12.y
mad.f16 hr18.y, hr4.z, hr26.x, (last)hr18.y
ldl.u16 r26.x, l[r10.z+1536], 4
mad.f16 hr10.y, hr4.z, hr27.x, (last)hr10.y
mad.f16 hr8.y, hr4.z, hr27.y, (last)hr8.y
mad.f16 hr6.y, hr4.z, hr27.z, (last)hr6.y
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr27.w, (r)(last)hr24.x
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr27.w, (r)(last)hr24.z
isam.v.base0 (u16)(xyzw)hr24.x, r14.w, s#0, t#2
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr27.w, (r)(last)hr25.x
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr27.w, (r)(last)hr25.z
isam.v.base0 (u16)(xyzw)hr25.x, r15.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr28.y, r15.y, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr29.y, r15.z, s#0, t#2
ldl.u16 r27.x, l[r10.z+1664], 4
(sy)mad.f16 hr16.z, hr24.x, hr19.w, (last)hr16.z
ldl.u16 r30.y, l[r10.z+1792], 4
mad.f16 hr14.z, hr24.x, hr20.x, (last)hr14.z
mad.f16 hr12.z, hr24.x, hr20.y, (last)hr12.z
mad.f16 hr16.w, hr24.y, hr19.w, (last)hr16.w
mad.f16 hr14.w, hr24.y, hr20.x, (last)hr14.w
mad.f16 hr12.w, hr24.y, hr20.y, (last)hr12.w
mad.f16 hr17.x, hr24.z, hr19.w, (last)hr17.x
mad.f16 hr15.x, hr24.z, hr20.x, (last)hr15.x
mad.f16 hr13.x, hr24.z, hr20.y, (last)hr13.x
mad.f16 hr17.y, hr24.w, hr19.w, (last)hr17.y
mad.f16 hr15.y, hr24.w, hr20.x, (last)hr15.y
mad.f16 hr13.y, hr24.w, hr20.y, (last)hr13.y
mad.f16 hr17.z, hr25.x, hr19.z, (last)hr17.z
mad.f16 hr15.z, hr25.x, hr19.w, (last)hr15.z
mad.f16 hr13.z, hr25.x, hr20.x, (last)hr13.z
mad.f16 hr11.z, hr25.x, hr20.y, (last)hr11.z
mad.f16 hr9.z, hr25.x, hr21.z, (last)hr9.z
mad.f16 hr7.z, hr25.x, hr21.w, (last)hr7.z
mad.f16 hr5.z, hr25.x, hr22.x, (last)hr5.z
mad.f16 hr17.w, hr25.y, hr19.z, (last)hr17.w
mad.f16 hr15.w, hr25.y, hr19.w, (last)hr15.w
mad.f16 hr13.w, hr25.y, hr20.x, (last)hr13.w
mad.f16 hr11.w, hr25.y, hr20.y, (last)hr11.w
mad.f16 hr9.w, hr25.y, hr21.z, (last)hr9.w
mad.f16 hr7.w, hr25.y, hr21.w, (last)hr7.w
mad.f16 hr5.w, hr25.y, hr22.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr25.z, hr19.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr25.z, hr19.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr25.z, hr20.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr25.z, hr20.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr25.z, hr21.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr25.z, hr21.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr25.z, hr22.x, (r)(last)hr6.x
(rpt1)mad.f16 hr25.x, (r)(last)hr25.x, hr22.y, (r)(last)hr3.w
(rpt1)mad.f16 hr25.z, (r)(last)hr25.z, hr22.y, (r)(last)hr4.y
isam.v.base0 (u16)(xyzw)hr3.w, r15.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr19.w, r16.x, s#0, t#2
mad.f16 hr18.z, hr24.x, hr19.z, (last)hr18.z
mad.f16 hr10.z, hr24.x, hr21.z, (last)hr10.z
mad.f16 hr8.z, hr24.x, hr21.w, (last)hr8.z
mad.f16 hr6.z, hr24.x, hr22.x, (last)hr6.z
mad.f16 hr18.w, hr24.y, hr19.z, (last)hr18.w
mad.f16 hr10.w, hr24.y, hr21.z, (last)hr10.w
mad.f16 hr8.w, hr24.y, hr21.w, (last)hr8.w
mad.f16 hr6.w, hr24.y, hr22.x, (last)hr6.w
mad.f16 hr19.x, hr24.z, hr19.z, (last)hr19.x
mad.f16 hr11.x, hr24.z, hr21.z, (last)hr11.x
mad.f16 hr9.x, hr24.z, hr21.w, (last)hr9.x
mad.f16 hr7.x, hr24.z, hr22.x, (last)hr7.x
mad.f16 hr19.y, hr24.w, hr19.z, (last)hr19.y
mad.f16 hr11.y, hr24.w, hr21.z, (last)hr11.y
mad.f16 hr9.y, hr24.w, hr21.w, (last)hr9.y
mad.f16 hr7.y, hr24.w, hr22.x, (last)hr7.y
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr22.y, (r)(last)hr40.w
mad.f16 hr24.z, (last)hr24.z, hr22.y, (last)hr41.y
ldl.u16 r40.z, l[r10.z+1920], 4
mad.f16 hr24.w, (last)hr24.w, hr22.y, (last)hr41.z
ldl.u16 r21.z, l[r10.z+2048], 4
ldl.u16 r22.z, l[r10.z+2176], 4
mad.f16 hr16.z, hr28.y, hr26.y, (last)hr16.z
mad.f16 hr14.z, hr28.y, hr26.z, (last)hr14.z
mad.f16 hr12.z, hr28.y, hr26.w, (last)hr12.z
mad.f16 hr16.w, hr28.z, hr26.y, (last)hr16.w
mad.f16 hr14.w, hr28.z, hr26.z, (last)hr14.w
mad.f16 hr12.w, hr28.z, hr26.w, (last)hr12.w
mad.f16 hr17.x, hr28.w, hr26.y, (last)hr17.x
mad.f16 hr15.x, hr28.w, hr26.z, (last)hr15.x
mad.f16 hr13.x, hr28.w, hr26.w, (last)hr13.x
mad.f16 hr17.y, hr29.x, hr26.y, (last)hr17.y
mad.f16 hr15.y, hr29.x, hr26.z, (last)hr15.y
mad.f16 hr13.y, hr29.x, hr26.w, (last)hr13.y
mad.f16 hr17.z, hr29.y, hr26.x, (last)hr17.z
mad.f16 hr15.z, hr29.y, hr26.y, (last)hr15.z
mad.f16 hr13.z, hr29.y, hr26.z, (last)hr13.z
mad.f16 hr11.z, hr29.y, hr26.w, (last)hr11.z
(ss)mad.f16 hr9.z, hr29.y, hr27.x, (last)hr9.z
mad.f16 hr7.z, hr29.y, hr27.y, (last)hr7.z
mad.f16 hr5.z, hr29.y, hr27.z, (last)hr5.z
mad.f16 hr17.w, hr29.z, hr26.x, (last)hr17.w
mad.f16 hr15.w, hr29.z, hr26.y, (last)hr15.w
mad.f16 hr13.w, hr29.z, hr26.z, (last)hr13.w
mad.f16 hr11.w, hr29.z, hr26.w, (last)hr11.w
mad.f16 hr9.w, hr29.z, hr27.x, (last)hr9.w
mad.f16 hr7.w, hr29.z, hr27.y, (last)hr7.w
mad.f16 hr5.w, hr29.z, hr27.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr29.w, hr26.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr29.w, hr26.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr29.w, hr26.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr29.w, hr26.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr29.w, hr27.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr29.w, hr27.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr29.w, hr27.z, (r)(last)hr6.x
mad.f16 hr18.z, hr28.y, hr26.x, (last)hr18.z
mad.f16 hr10.z, hr28.y, hr27.x, (last)hr10.z
mad.f16 hr8.z, hr28.y, hr27.y, (last)hr8.z
mad.f16 hr6.z, hr28.y, hr27.z, (last)hr6.z
mad.f16 hr18.w, hr28.z, hr26.x, (last)hr18.w
mad.f16 hr10.w, hr28.z, hr27.x, (last)hr10.w
mad.f16 hr8.w, hr28.z, hr27.y, (last)hr8.w
mad.f16 hr6.w, hr28.z, hr27.z, (last)hr6.w
mad.f16 hr19.x, hr28.w, hr26.x, (last)hr19.x
mad.f16 hr11.x, hr28.w, hr27.x, (last)hr11.x
mad.f16 hr9.x, hr28.w, hr27.y, (last)hr9.x
mad.f16 hr7.x, hr28.w, hr27.z, (last)hr7.x
mad.f16 hr19.y, hr29.x, hr26.x, (last)hr19.y
ldl.u16 r26.x, l[r10.z+2304], 4
mad.f16 hr11.y, hr29.x, hr27.x, (last)hr11.y
mad.f16 hr9.y, hr29.x, hr27.y, (last)hr9.y
mad.f16 hr7.y, hr29.x, hr27.z, (last)hr7.y
(rpt1)mad.f16 hr29.y, (r)(last)hr29.y, hr27.w, (r)(last)hr25.x
(rpt1)mad.f16 hr29.w, (r)(last)hr29.w, hr27.w, (r)(last)hr25.z
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr27.w, (r)(last)hr24.x
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr27.w, (r)(last)hr24.z
isam.v.base0 (u16)(xyzw)hr24.x, r16.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr25.x, r16.z, s#0, t#2
ldl.u16 r27.x, l[r10.z+2432], 4
(sy)mad.f16 hr16.z, hr3.w, hr30.z, (last)hr16.z
mad.f16 hr14.z, hr3.w, hr30.w, (last)hr14.z
mad.f16 hr12.z, hr3.w, hr31.x, (last)hr12.z
mad.f16 hr16.w, hr4.x, hr30.z, (last)hr16.w
mad.f16 hr14.w, hr4.x, hr30.w, (last)hr14.w
mad.f16 hr12.w, hr4.x, hr31.x, (last)hr12.w
mad.f16 hr17.x, hr4.y, hr30.z, (last)hr17.x
mad.f16 hr15.x, hr4.y, hr30.w, (last)hr15.x
mad.f16 hr13.x, hr4.y, hr31.x, (last)hr13.x
mad.f16 hr17.y, hr4.z, hr30.z, (last)hr17.y
mad.f16 hr15.y, hr4.z, hr30.w, (last)hr15.y
mad.f16 hr13.y, hr4.z, hr31.x, (last)hr13.y
mad.f16 hr17.z, hr19.w, hr30.y, (last)hr17.z
mad.f16 hr15.z, hr19.w, hr30.z, (last)hr15.z
mad.f16 hr13.z, hr19.w, hr30.w, (last)hr13.z
mad.f16 hr11.z, hr19.w, hr31.x, (last)hr11.z
mad.f16 hr9.z, hr19.w, hr40.z, (last)hr9.z
mad.f16 hr7.z, hr19.w, hr40.w, (last)hr7.z
mad.f16 hr5.z, hr19.w, hr41.x, (last)hr5.z
mad.f16 hr17.w, hr20.x, hr30.y, (last)hr17.w
mad.f16 hr15.w, hr20.x, hr30.z, (last)hr15.w
mad.f16 hr13.w, hr20.x, hr30.w, (last)hr13.w
mad.f16 hr11.w, hr20.x, hr31.x, (last)hr11.w
mad.f16 hr9.w, hr20.x, hr40.z, (last)hr9.w
mad.f16 hr7.w, hr20.x, hr40.w, (last)hr7.w
mad.f16 hr5.w, hr20.x, hr41.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr20.y, hr30.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr20.y, hr30.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr20.y, hr30.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr20.y, hr31.x, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr20.y, hr40.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr20.y, hr40.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr20.y, hr41.x, (r)(last)hr6.x
mad.f16 hr18.z, hr3.w, hr30.y, (last)hr18.z
mad.f16 hr10.z, hr3.w, hr40.z, (last)hr10.z
mad.f16 hr8.z, hr3.w, hr40.w, (last)hr8.z
mad.f16 hr6.z, hr3.w, hr41.x, (last)hr6.z
mad.f16 hr18.w, hr4.x, hr30.y, (last)hr18.w
mad.f16 hr10.w, hr4.x, hr40.z, (last)hr10.w
mad.f16 hr8.w, hr4.x, hr40.w, (last)hr8.w
mad.f16 hr6.w, hr4.x, hr41.x, (last)hr6.w
mad.f16 hr19.x, hr4.y, hr30.y, (last)hr19.x
mad.f16 hr11.x, hr4.y, hr40.z, (last)hr11.x
mad.f16 hr9.x, hr4.y, hr40.w, (last)hr9.x
mad.f16 hr7.x, hr4.y, hr41.x, (last)hr7.x
mad.f16 hr19.y, hr4.z, hr30.y, (last)hr19.y
ldl.u16 r30.y, l[r10.z+2560], 4
ldl.u16 r31.y, l[r10.z+2688], 4
mad.f16 hr11.y, hr4.z, hr40.z, (last)hr11.y
mad.f16 hr9.y, hr4.z, hr40.w, (last)hr9.y
mad.f16 hr7.y, hr4.z, hr41.x, (last)hr7.y
(rpt1)mad.f16 hr19.w, (r)(last)hr19.w, hr41.y, (r)(last)hr29.y
(rpt1)mad.f16 hr20.y, (r)(last)hr20.y, hr41.y, (r)(last)hr29.w
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr41.y, (r)(last)hr28.y
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr41.y, (r)(last)hr28.w
isam.v.base0 (u16)(xyzw)hr28.y, r16.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr29.y, r17.x, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr32.w, r17.y, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr33.w, r17.z, s#0, t#2
ldl.u16 r40.z, l[r10.z+2816], 4
ldl.u16 r0.z, l[r10.z+2944], 4
mad.f16 hr16.w, hr24.y, hr21.w, (last)hr16.w
mad.f16 hr14.w, hr24.y, hr22.x, (last)hr14.w
mad.f16 hr12.w, hr24.y, hr22.y, (last)hr12.w
mad.f16 hr17.x, hr24.z, hr21.w, (last)hr17.x
mad.f16 hr15.x, hr24.z, hr22.x, (last)hr15.x
mad.f16 hr13.x, hr24.z, hr22.y, (last)hr13.x
mad.f16 hr17.y, hr24.w, hr21.w, (last)hr17.y
mad.f16 hr15.y, hr24.w, hr22.x, (last)hr15.y
mad.f16 hr13.y, hr24.w, hr22.y, (last)hr13.y
mad.f16 hr17.w, hr25.y, hr21.z, (last)hr17.w
mad.f16 hr15.w, hr25.y, hr21.w, (last)hr15.w
mad.f16 hr13.w, hr25.y, hr22.x, (last)hr13.w
mad.f16 hr11.w, hr25.y, hr22.y, (last)hr11.w
mad.f16 hr9.w, hr25.y, hr22.z, (last)hr9.w
mad.f16 hr7.w, hr25.y, hr22.w, (last)hr7.w
mad.f16 hr5.w, hr25.y, hr23.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr25.z, hr21.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr25.z, hr21.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr25.z, hr22.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr25.z, hr22.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr25.z, hr22.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr25.z, hr22.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr25.z, hr23.x, (r)(last)hr6.x
mad.f16 hr18.w, hr24.y, hr21.z, (last)hr18.w
mad.f16 hr10.w, hr24.y, hr22.z, (last)hr10.w
mad.f16 hr8.w, hr24.y, hr22.w, (last)hr8.w
mad.f16 hr6.w, hr24.y, hr23.x, (last)hr6.w
mad.f16 hr19.x, hr24.z, hr21.z, (last)hr19.x
mad.f16 hr11.x, hr24.z, hr22.z, (last)hr11.x
mad.f16 hr9.x, hr24.z, hr22.w, (last)hr9.x
mad.f16 hr7.x, hr24.z, hr23.x, (last)hr7.x
mad.f16 hr19.y, hr24.w, hr21.z, (last)hr19.y
mad.f16 hr11.y, hr24.w, hr22.z, (last)hr11.y
mad.f16 hr9.y, hr24.w, hr22.w, (last)hr9.y
mad.f16 hr7.y, hr24.w, hr23.x, (last)hr7.y
mad.f16 hr25.y, (last)hr25.y, hr23.y, (last)hr20.x
(rpt1)mad.f16 hr25.z, (r)(last)hr25.z, hr23.y, (r)(last)hr20.y
mad.f16 hr24.y, (last)hr24.y, hr23.y, (last)hr4.x
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr23.y, (r)(last)hr4.y
isam.v.base0 (u16)(xyzw)hr4.x, r17.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr20.x, r18.x, s#0, t#2
mad.f16 hr16.z, hr24.x, hr21.w, (last)hr16.z
mad.f16 hr14.z, hr24.x, hr22.x, (last)hr14.z
mad.f16 hr12.z, hr24.x, hr22.y, (last)hr12.z
mad.f16 hr15.z, hr25.x, hr21.w, (last)hr15.z
mad.f16 hr13.z, hr25.x, hr22.x, (last)hr13.z
mad.f16 hr11.z, hr25.x, hr22.y, (last)hr11.z
mad.f16 hr9.z, hr25.x, hr22.z, (last)hr9.z
mad.f16 hr10.z, hr24.x, hr22.z, (last)hr10.z
mad.f16 hr17.z, hr25.x, hr21.z, (last)hr17.z
mad.f16 hr7.z, hr25.x, hr22.w, (last)hr7.z
mad.f16 hr5.z, hr25.x, hr23.x, (last)hr5.z
mad.f16 hr18.z, hr24.x, hr21.z, (last)hr18.z
ldl.u16 r21.z, l[r10.z+3072], 4
mad.f16 hr8.z, hr24.x, hr22.w, (last)hr8.z
mad.f16 hr6.z, hr24.x, hr23.x, (last)hr6.z
mad.f16 hr25.x, (last)hr25.x, hr23.y, (last)hr19.w
mad.f16 hr24.x, (last)hr24.x, hr23.y, (last)hr3.w
ldl.u16 r22.z, l[r10.z+3200], 4
(sy)mad.f16 hr16.w, hr28.z, hr26.y, (last)hr16.w
mad.f16 hr14.w, hr28.z, hr26.z, (last)hr14.w
mad.f16 hr12.w, hr28.z, hr26.w, (last)hr12.w
mad.f16 hr17.x, hr28.w, hr26.y, (last)hr17.x
mad.f16 hr15.x, hr28.w, hr26.z, (last)hr15.x
mad.f16 hr13.x, hr28.w, hr26.w, (last)hr13.x
mad.f16 hr17.y, hr29.x, hr26.y, (last)hr17.y
mad.f16 hr15.y, hr29.x, hr26.z, (last)hr15.y
mad.f16 hr13.y, hr29.x, hr26.w, (last)hr13.y
mad.f16 hr15.w, hr29.z, hr26.y, (last)hr15.w
mad.f16 hr13.w, hr29.z, hr26.z, (last)hr13.w
mad.f16 hr11.w, hr29.z, hr26.w, (last)hr11.w
mad.f16 hr9.w, hr29.z, hr27.x, (last)hr9.w
(rpt1)mad.f16 hr16.x, (r)hr29.w, hr26.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr29.w, hr26.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr29.w, hr26.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr29.w, hr27.x, (r)(last)hr10.x
mad.f16 hr10.w, hr28.z, hr27.x, (last)hr10.w
(rpt1)mad.f16 hr11.x, (r)hr28.w, hr27.x, (r)(last)hr11.x
mad.f16 hr16.z, hr28.y, hr26.y, (last)hr16.z
mad.f16 hr14.z, hr28.y, hr26.z, (last)hr14.z
mad.f16 hr12.z, hr28.y, hr26.w, (last)hr12.z
mad.f16 hr15.z, hr29.y, hr26.y, (last)hr15.z
mad.f16 hr13.z, hr29.y, hr26.z, (last)hr13.z
mad.f16 hr11.z, hr29.y, hr26.w, (last)hr11.z
mad.f16 hr9.z, hr29.y, hr27.x, (last)hr9.z
mad.f16 hr10.z, hr28.y, hr27.x, (last)hr10.z
ldl.u16 r26.y, l[r10.z+3328], 4
mad.f16 hr17.w, hr29.z, hr26.x, (last)hr17.w
mad.f16 hr7.w, hr29.z, hr27.y, (last)hr7.w
mad.f16 hr5.w, hr29.z, hr27.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr29.w, hr26.x, (r)(last)hr18.x
(rpt1)mad.f16 hr8.x, (r)hr29.w, hr27.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr29.w, hr27.z, (r)(last)hr6.x
mad.f16 hr18.w, hr28.z, hr26.x, (last)hr18.w
mad.f16 hr8.w, hr28.z, hr27.y, (last)hr8.w
mad.f16 hr6.w, hr28.z, hr27.z, (last)hr6.w
mad.f16 hr19.x, hr28.w, hr26.x, (last)hr19.x
mad.f16 hr9.x, hr28.w, hr27.y, (last)hr9.x
mad.f16 hr7.x, hr28.w, hr27.z, (last)hr7.x
mad.f16 hr19.y, hr29.x, hr26.x, (last)hr19.y
mad.f16 hr9.y, hr29.x, hr27.y, (last)hr9.y
mad.f16 hr7.y, hr29.x, hr27.z, (last)hr7.y
mad.f16 hr17.z, hr29.y, hr26.x, (last)hr17.z
mad.f16 hr7.z, hr29.y, hr27.y, (last)hr7.z
mad.f16 hr5.z, hr29.y, hr27.z, (last)hr5.z
mad.f16 hr18.z, hr28.y, hr26.x, (last)hr18.z
mad.f16 hr29.z, (last)hr29.z, hr27.w, (last)hr25.y
(rpt1)mad.f16 hr29.w, (r)(last)hr29.w, hr27.w, (r)(last)hr25.z
mad.f16 hr28.z, (last)hr28.z, hr27.w, (last)hr24.y
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr27.w, (r)(last)hr24.z
mad.f16 hr29.y, (last)hr29.y, hr27.w, (last)hr25.x
isam.v.base0 (u16)(xyzw)hr24.y, r18.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr25.y, r18.z, s#0, t#2
mad.f16 hr8.z, hr28.y, hr27.y, (last)hr8.z
mad.f16 hr16.w, hr33.x, hr30.z, (last)hr16.w
mad.f16 hr14.w, hr33.x, hr30.w, (last)hr14.w
mad.f16 hr12.w, hr33.x, hr31.x, (last)hr12.w
mad.f16 hr17.x, hr33.y, hr30.z, (last)hr17.x
mad.f16 hr15.x, hr33.y, hr30.w, (last)hr15.x
mad.f16 hr13.x, hr33.y, hr31.x, (last)hr13.x
mad.f16 hr17.y, hr33.z, hr30.z, (last)hr17.y
mad.f16 hr15.y, hr33.z, hr30.w, (last)hr15.y
mad.f16 hr13.y, hr33.z, hr31.x, (last)hr13.y
mad.f16 hr15.w, hr34.x, hr30.z, (last)hr15.w
mad.f16 hr13.w, hr34.x, hr30.w, (last)hr13.w
mad.f16 hr11.w, hr34.x, hr31.x, (last)hr11.w
mad.f16 hr9.w, hr34.x, hr31.y, (last)hr9.w
(rpt1)mad.f16 hr16.x, (r)hr34.y, hr30.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr34.y, hr30.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr34.y, hr31.x, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr34.y, hr31.y, (r)(last)hr10.x
mad.f16 hr10.w, hr33.x, hr31.y, (last)hr10.w
(rpt1)mad.f16 hr11.x, (r)hr33.y, hr31.y, (r)(last)hr11.x
mad.f16 hr16.z, hr32.w, hr30.z, (last)hr16.z
mad.f16 hr15.z, hr33.w, hr30.z, (last)hr15.z
mad.f16 hr13.z, hr33.w, hr30.w, (last)hr13.z
mad.f16 hr11.z, hr33.w, hr31.x, (last)hr11.z
mad.f16 hr9.z, hr33.w, hr31.y, (last)hr9.z
mad.f16 hr17.w, hr34.x, hr30.y, (last)hr17.w
mad.f16 hr7.w, hr34.x, hr31.z, (last)hr7.w
mad.f16 hr5.w, hr34.x, hr31.w, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr34.y, hr30.y, (r)(last)hr18.x
(rpt1)mad.f16 hr8.x, (r)hr34.y, hr31.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr34.y, hr31.w, (r)(last)hr6.x
mad.f16 hr18.w, hr33.x, hr30.y, (last)hr18.w
mad.f16 hr8.w, hr33.x, hr31.z, (last)hr8.w
mad.f16 hr6.w, hr33.x, hr31.w, (last)hr6.w
mad.f16 hr19.x, hr33.y, hr30.y, (last)hr19.x
mad.f16 hr9.x, hr33.y, hr31.z, (last)hr9.x
mad.f16 hr7.x, hr33.y, hr31.w, (last)hr7.x
mad.f16 hr19.y, hr33.z, hr30.y, (last)hr19.y
mad.f16 hr9.y, hr33.z, hr31.z, (last)hr9.y
mad.f16 hr7.y, hr33.z, hr31.w, (last)hr7.y
mad.f16 hr17.z, hr33.w, hr30.y, (last)hr17.z
mad.f16 hr7.z, hr33.w, hr31.z, (last)hr7.z
mad.f16 hr5.z, hr33.w, hr31.w, (last)hr5.z
mad.f16 hr18.z, hr32.w, hr30.y, (last)hr18.z
mad.f16 hr34.x, (last)hr34.x, hr32.x, (last)hr29.z
(rpt1)mad.f16 hr34.y, (r)(last)hr34.y, hr32.x, (r)(last)hr29.w
mad.f16 hr33.x, (last)hr33.x, hr32.x, (last)hr28.z
(rpt1)mad.f16 hr33.y, (r)(last)hr33.y, hr32.x, (r)(last)hr28.w
mad.f16 hr33.w, (last)hr33.w, hr32.x, (last)hr29.y
isam.v.base0 (u16)(xyzw)hr28.w, r18.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr29.w, r19.x, s#0, t#2
mad.f16 hr6.z, hr28.y, hr27.z, (last)hr6.z
mad.f16 hr14.z, hr32.w, hr30.w, (last)hr14.z
mad.f16 hr12.z, hr32.w, hr31.x, (last)hr12.z
mad.f16 hr10.z, hr32.w, hr31.y, (last)hr10.z
mad.f16 hr8.z, hr32.w, hr31.z, (last)hr8.z
(ss)mad.f16 hr16.w, hr4.y, hr40.w, (last)hr16.w
mad.f16 hr14.w, hr4.y, hr41.x, (last)hr14.w
mad.f16 hr12.w, hr4.y, hr41.y, (last)hr12.w
mad.f16 hr17.x, hr4.z, hr40.w, (last)hr17.x
mad.f16 hr15.x, hr4.z, hr41.x, (last)hr15.x
mad.f16 hr13.x, hr4.z, hr41.y, (last)hr13.x
mad.f16 hr17.y, hr4.w, hr40.w, (last)hr17.y
mad.f16 hr15.y, hr4.w, hr41.x, (last)hr15.y
mad.f16 hr13.y, hr4.w, hr41.y, (last)hr13.y
mad.f16 hr15.w, hr20.y, hr40.w, (last)hr15.w
mad.f16 hr13.w, hr20.y, hr41.x, (last)hr13.w
mad.f16 hr11.w, hr20.y, hr41.y, (last)hr11.w
mad.f16 hr9.w, hr20.y, hr0.z, (last)hr9.w
(rpt1)mad.f16 hr16.x, (r)hr20.z, hr40.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr20.z, hr41.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr20.z, hr41.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr20.z, hr0.z, (r)(last)hr10.x
mad.f16 hr10.w, hr4.y, hr0.z, (last)hr10.w
(rpt1)mad.f16 hr11.x, (r)hr4.z, hr0.z, (r)(last)hr11.x
mad.f16 hr15.z, hr20.x, hr40.w, (last)hr15.z
mad.f16 hr13.z, hr20.x, hr41.x, (last)hr13.z
mad.f16 hr11.z, hr20.x, hr41.y, (last)hr11.z
mad.f16 hr9.z, hr20.x, hr0.z, (last)hr9.z
mad.f16 hr17.w, hr20.y, hr40.z, (last)hr17.w
mad.f16 hr7.w, hr20.y, hr0.w, (last)hr7.w
mad.f16 hr5.w, hr20.y, hr1.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr20.z, hr40.z, (r)(last)hr18.x
(rpt1)mad.f16 hr8.x, (r)hr20.z, hr0.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr20.z, hr1.x, (r)(last)hr6.x
mad.f16 hr18.w, hr4.y, hr40.z, (last)hr18.w
mad.f16 hr8.w, hr4.y, hr0.w, (last)hr8.w
mad.f16 hr6.w, hr4.y, hr1.x, (last)hr6.w
mad.f16 hr19.x, hr4.z, hr40.z, (last)hr19.x
mad.f16 hr9.x, hr4.z, hr0.w, (last)hr9.x
mad.f16 hr7.x, hr4.z, hr1.x, (last)hr7.x
mad.f16 hr19.y, hr4.w, hr40.z, (last)hr19.y
mad.f16 hr9.y, hr4.w, hr0.w, (last)hr9.y
mad.f16 hr7.y, hr4.w, hr1.x, (last)hr7.y
mad.f16 hr17.z, hr20.x, hr40.z, (last)hr17.z
mad.f16 hr7.z, hr20.x, hr0.w, (last)hr7.z
mad.f16 hr5.z, hr20.x, hr1.x, (last)hr5.z
mad.f16 hr28.y, (last)hr28.y, hr27.w, (last)hr24.x
ldl.u16 r27.y, l[r10.z+3456], 4
ldl.u16 r30.w, l[r10.z+3584], 4
mad.f16 hr20.y, (last)hr20.y, hr1.y, (last)hr34.x
(rpt1)mad.f16 hr20.z, (r)(last)hr20.z, hr1.y, (r)(last)hr34.y
mad.f16 hr4.y, (last)hr4.y, hr1.y, (last)hr33.x
(rpt1)mad.f16 hr4.z, (r)(last)hr4.z, hr1.y, (r)(last)hr33.y
mad.f16 hr20.x, (last)hr20.x, hr1.y, (last)hr33.w
isam.v.base0 (u16)(xyzw)hr33.x, r19.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr34.x, r19.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr37.y, r19.w, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr38.y, r20.x, s#0, t#2
mad.f16 hr6.z, hr32.w, hr31.w, (last)hr6.z
mad.f16 hr32.w, (last)hr32.w, hr32.x, (last)hr28.y
ldl.u16 r31.w, l[r10.z+3712], 4
ldl.u16 r35.x, l[r10.z+3840], 4
ldl.u16 r36.x, l[r10.z+3968], 4
mad.f16 hr16.z, hr4.x, hr40.w, (last)hr16.z
mad.f16 hr18.z, hr4.x, hr40.z, (last)hr18.z
mad.f16 hr14.z, hr4.x, hr41.x, (last)hr14.z
mad.f16 hr12.z, hr4.x, hr41.y, (last)hr12.z
mad.f16 hr10.z, hr4.x, hr0.z, (last)hr10.z
mad.f16 hr8.z, hr4.x, hr0.w, (last)hr8.z
mad.f16 hr6.z, hr4.x, hr1.x, (last)hr6.z
mad.f16 hr4.x, (last)hr4.x, hr1.y, (last)hr32.w
fence.r.w
(sy)(ss)mad.f16 hr16.w, hr24.z, hr21.w, (last)hr16.w
mad.f16 hr14.w, hr24.z, hr22.x, (last)hr14.w
mad.f16 hr12.w, hr24.z, hr22.y, (last)hr12.w
mad.f16 hr17.x, hr24.w, hr21.w, (last)hr17.x
mad.f16 hr15.x, hr24.w, hr22.x, (last)hr15.x
mad.f16 hr13.x, hr24.w, hr22.y, (last)hr13.x
mad.f16 hr17.y, hr25.x, hr21.w, (last)hr17.y
mad.f16 hr15.y, hr25.x, hr22.x, (last)hr15.y
mad.f16 hr13.y, hr25.x, hr22.y, (last)hr13.y
mad.f16 hr15.w, hr25.z, hr21.w, (last)hr15.w
mad.f16 hr13.w, hr25.z, hr22.x, (last)hr13.w
mad.f16 hr11.w, hr25.z, hr22.y, (last)hr11.w
mad.f16 hr9.w, hr25.z, hr22.z, (last)hr9.w
(rpt1)mad.f16 hr16.x, (r)hr25.w, hr21.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr25.w, hr22.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr25.w, hr22.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr25.w, hr22.z, (r)(last)hr10.x
mad.f16 hr10.w, hr24.z, hr22.z, (last)hr10.w
(rpt1)mad.f16 hr11.x, (r)hr24.w, hr22.z, (r)(last)hr11.x
mad.f16 hr15.z, hr25.y, hr21.w, (last)hr15.z
mad.f16 hr13.z, hr25.y, hr22.x, (last)hr13.z
mad.f16 hr11.z, hr25.y, hr22.y, (last)hr11.z
mad.f16 hr9.z, hr25.y, hr22.z, (last)hr9.z
mad.f16 hr17.w, hr25.z, hr21.z, (last)hr17.w
mad.f16 hr7.w, hr25.z, hr22.w, (last)hr7.w
mad.f16 hr5.w, hr25.z, hr23.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr25.w, hr21.z, (r)(last)hr18.x
(rpt1)mad.f16 hr8.x, (r)hr25.w, hr22.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr25.w, hr23.x, (r)(last)hr6.x
mad.f16 hr18.w, hr24.z, hr21.z, (last)hr18.w
mad.f16 hr8.w, hr24.z, hr22.w, (last)hr8.w
mad.f16 hr6.w, hr24.z, hr23.x, (last)hr6.w
mad.f16 hr19.x, hr24.w, hr21.z, (last)hr19.x
mad.f16 hr9.x, hr24.w, hr22.w, (last)hr9.x
mad.f16 hr7.x, hr24.w, hr23.x, (last)hr7.x
mad.f16 hr19.y, hr25.x, hr21.z, (last)hr19.y
mad.f16 hr9.y, hr25.x, hr22.w, (last)hr9.y
mad.f16 hr7.y, hr25.x, hr23.x, (last)hr7.y
mad.f16 hr17.z, hr25.y, hr21.z, (last)hr17.z
mad.f16 hr7.z, hr25.y, hr22.w, (last)hr7.z
mad.f16 hr5.z, hr25.y, hr23.x, (last)hr5.z
mad.f16 hr16.z, hr24.y, hr21.w, (last)hr16.z
mad.f16 hr18.z, hr24.y, hr21.z, (last)hr18.z
mad.f16 hr14.z, hr24.y, hr22.x, (last)hr14.z
mad.f16 hr12.z, hr24.y, hr22.y, (last)hr12.z
mad.f16 hr10.z, hr24.y, hr22.z, (last)hr10.z
mad.f16 hr8.z, hr24.y, hr22.w, (last)hr8.z
mad.f16 hr6.z, hr24.y, hr23.x, (last)hr6.z
mad.f16 hr25.z, (last)hr25.z, hr23.y, (last)hr20.y
(rpt1)mad.f16 hr25.w, (r)(last)hr25.w, hr23.y, (r)(last)hr20.z
mad.f16 hr24.z, (last)hr24.z, hr23.y, (last)hr4.y
(rpt1)mad.f16 hr24.w, (r)(last)hr24.w, hr23.y, (r)(last)hr4.z
mad.f16 hr25.y, (last)hr25.y, hr23.y, (last)hr20.x
mad.f16 hr24.y, (last)hr24.y, hr23.y, (last)hr4.x
mad.f16 hr16.w, hr29.x, hr26.z, (last)hr16.w
mad.f16 hr14.w, hr29.x, hr26.w, (last)hr14.w
mad.f16 hr12.w, hr29.x, hr27.x, (last)hr12.w
mad.f16 hr17.x, hr29.y, hr26.z, (last)hr17.x
mad.f16 hr15.x, hr29.y, hr26.w, (last)hr15.x
mad.f16 hr13.x, hr29.y, hr27.x, (last)hr13.x
mad.f16 hr17.y, hr29.z, hr26.z, (last)hr17.y
mad.f16 hr15.y, hr29.z, hr26.w, (last)hr15.y
mad.f16 hr13.y, hr29.z, hr27.x, (last)hr13.y
mad.f16 hr15.w, hr30.x, hr26.z, (last)hr15.w
mad.f16 hr13.w, hr30.x, hr26.w, (last)hr13.w
mad.f16 hr11.w, hr30.x, hr27.x, (last)hr11.w
mad.f16 hr9.w, hr30.x, hr27.y, (last)hr9.w
(rpt1)mad.f16 hr16.x, (r)hr30.y, hr26.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr30.y, hr26.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr30.y, hr27.x, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr30.y, hr27.y, (r)(last)hr10.x
mad.f16 hr10.w, hr29.x, hr27.y, (last)hr10.w
(rpt1)mad.f16 hr11.x, (r)hr29.y, hr27.y, (r)(last)hr11.x
mad.f16 hr15.z, hr29.w, hr26.z, (last)hr15.z
mad.f16 hr13.z, hr29.w, hr26.w, (last)hr13.z
mad.f16 hr11.z, hr29.w, hr27.x, (last)hr11.z
mad.f16 hr9.z, hr29.w, hr27.y, (last)hr9.z
mad.f16 hr17.w, hr30.x, hr26.y, (last)hr17.w
mad.f16 hr7.w, hr30.x, hr27.z, (last)hr7.w
mad.f16 hr5.w, hr30.x, hr27.w, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr30.y, hr26.y, (r)(last)hr18.x
(rpt1)mad.f16 hr8.x, (r)hr30.y, hr27.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr30.y, hr27.w, (r)(last)hr6.x
mad.f16 hr18.w, hr29.x, hr26.y, (last)hr18.w
mad.f16 hr8.w, hr29.x, hr27.z, (last)hr8.w
mad.f16 hr6.w, hr29.x, hr27.w, (last)hr6.w
mad.f16 hr19.x, hr29.y, hr26.y, (last)hr19.x
mad.f16 hr9.x, hr29.y, hr27.z, (last)hr9.x
mad.f16 hr7.x, hr29.y, hr27.w, (last)hr7.x
mad.f16 hr19.y, hr29.z, hr26.y, (last)hr19.y
mad.f16 hr9.y, hr29.z, hr27.z, (last)hr9.y
mad.f16 hr7.y, hr29.z, hr27.w, (last)hr7.y
mad.f16 hr17.z, hr29.w, hr26.y, (last)hr17.z
mad.f16 hr7.z, hr29.w, hr27.z, (last)hr7.z
mad.f16 hr5.z, hr29.w, hr27.w, (last)hr5.z
mad.f16 hr16.z, hr28.w, hr26.z, (last)hr16.z
mad.f16 hr18.z, hr28.w, hr26.y, (last)hr18.z
mad.f16 hr14.z, hr28.w, hr26.w, (last)hr14.z
mad.f16 hr12.z, hr28.w, hr27.x, (last)hr12.z
mad.f16 hr10.z, hr28.w, hr27.y, (last)hr10.z
mad.f16 hr8.z, hr28.w, hr27.z, (last)hr8.z
mad.f16 hr6.z, hr28.w, hr27.w, (last)hr6.z
mad.f16 hr30.x, (last)hr30.x, hr28.x, (last)hr25.z
(rpt1)mad.f16 hr30.y, (r)(last)hr30.y, hr28.x, (r)(last)hr25.w
mad.f16 hr29.x, (last)hr29.x, hr28.x, (last)hr24.z
(rpt1)mad.f16 hr29.y, (r)(last)hr29.y, hr28.x, (r)(last)hr24.w
mad.f16 hr29.w, (last)hr29.w, hr28.x, (last)hr25.y
mad.f16 hr28.w, (last)hr28.w, hr28.x, (last)hr24.y
mad.f16 hr16.w, hr33.y, hr31.x, (last)hr16.w
mad.f16 hr14.w, hr33.y, hr31.y, (last)hr14.w
mad.f16 hr12.w, hr33.y, hr31.z, (last)hr12.w
mad.f16 hr17.x, hr33.z, hr31.x, (last)hr17.x
mad.f16 hr15.x, hr33.z, hr31.y, (last)hr15.x
mad.f16 hr13.x, hr33.z, hr31.z, (last)hr13.x
mad.f16 hr17.y, hr33.w, hr31.x, (last)hr17.y
mad.f16 hr15.y, hr33.w, hr31.y, (last)hr15.y
mad.f16 hr13.y, hr33.w, hr31.z, (last)hr13.y
mad.f16 hr15.w, hr34.y, hr31.x, (last)hr15.w
mad.f16 hr13.w, hr34.y, hr31.y, (last)hr13.w
mad.f16 hr11.w, hr34.y, hr31.z, (last)hr11.w
mad.f16 hr9.w, hr34.y, hr31.w, (last)hr9.w
(rpt1)mad.f16 hr16.x, (r)hr34.z, hr31.x, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr34.z, hr31.y, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr34.z, hr31.z, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr34.z, hr31.w, (r)(last)hr10.x
mad.f16 hr10.w, hr33.y, hr31.w, (last)hr10.w
(rpt1)mad.f16 hr11.x, (r)hr33.z, hr31.w, (r)(last)hr11.x
mad.f16 hr15.z, hr34.x, hr31.x, (last)hr15.z
mad.f16 hr13.z, hr34.x, hr31.y, (last)hr13.z
mad.f16 hr11.z, hr34.x, hr31.z, (last)hr11.z
mad.f16 hr9.z, hr34.x, hr31.w, (last)hr9.z
mad.f16 hr17.w, hr34.y, hr30.w, (last)hr17.w
mad.f16 hr7.w, hr34.y, hr32.x, (last)hr7.w
mad.f16 hr5.w, hr34.y, hr32.y, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr34.z, hr30.w, (r)(last)hr18.x
(rpt1)mad.f16 hr8.x, (r)hr34.z, hr32.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr34.z, hr32.y, (r)(last)hr6.x
mad.f16 hr18.w, hr33.y, hr30.w, (last)hr18.w
mad.f16 hr8.w, hr33.y, hr32.x, (last)hr8.w
mad.f16 hr6.w, hr33.y, hr32.y, (last)hr6.w
mad.f16 hr19.x, hr33.z, hr30.w, (last)hr19.x
mad.f16 hr9.x, hr33.z, hr32.x, (last)hr9.x
mad.f16 hr7.x, hr33.z, hr32.y, (last)hr7.x
mad.f16 hr19.y, hr33.w, hr30.w, (last)hr19.y
mad.f16 hr9.y, hr33.w, hr32.x, (last)hr9.y
mad.f16 hr7.y, hr33.w, hr32.y, (last)hr7.y
mad.f16 hr17.z, hr34.x, hr30.w, (last)hr17.z
mad.f16 hr7.z, hr34.x, hr32.x, (last)hr7.z
mad.f16 hr5.z, hr34.x, hr32.y, (last)hr5.z
mad.f16 hr16.z, hr33.x, hr31.x, (last)hr16.z
mad.f16 hr18.z, hr33.x, hr30.w, (last)hr18.z
mad.f16 hr14.z, hr33.x, hr31.y, (last)hr14.z
mad.f16 hr12.z, hr33.x, hr31.z, (last)hr12.z
mad.f16 hr10.z, hr33.x, hr31.w, (last)hr10.z
mad.f16 hr8.z, hr33.x, hr32.x, (last)hr8.z
mad.f16 hr6.z, hr33.x, hr32.y, (last)hr6.z
mad.f16 hr34.y, (last)hr34.y, hr32.z, (last)hr30.x
(rpt1)mad.f16 hr34.z, (r)(last)hr34.z, hr32.z, (r)(last)hr30.y
mad.f16 hr33.y, (last)hr33.y, hr32.z, (last)hr29.x
(rpt1)mad.f16 hr33.z, (r)(last)hr33.z, hr32.z, (r)(last)hr29.y
mad.f16 hr34.x, (last)hr34.x, hr32.z, (last)hr29.w
mad.f16 hr33.x, (last)hr33.x, hr32.z, (last)hr28.w
bar.g
(sy)(ss)mad.f16 hr16.w, hr37.z, hr35.y, (last)hr16.w
mad.f16 hr14.w, hr37.z, hr35.z, (last)hr14.w
mad.f16 hr12.w, hr37.z, hr35.w, (last)hr12.w
mad.f16 hr17.x, hr37.w, hr35.y, (last)hr17.x
mad.f16 hr15.x, hr37.w, hr35.z, (last)hr15.x
mad.f16 hr13.x, hr37.w, hr35.w, (last)hr13.x
mad.f16 hr17.y, hr38.x, hr35.y, (last)hr17.y
mad.f16 hr15.y, hr38.x, hr35.z, (last)hr15.y
mad.f16 hr13.y, hr38.x, hr35.w, (last)hr13.y
mad.f16 hr15.w, hr38.z, hr35.y, (last)hr15.w
mad.f16 hr13.w, hr38.z, hr35.z, (last)hr13.w
mad.f16 hr11.w, hr38.z, hr35.w, (last)hr11.w
mad.f16 hr9.w, hr38.z, hr36.x, (last)hr9.w
(rpt1)mad.f16 hr16.x, (r)hr38.w, hr35.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr38.w, hr35.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr38.w, hr35.w, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr38.w, hr36.x, (r)(last)hr10.x
mad.f16 hr10.w, hr37.z, hr36.x, (last)hr10.w
(rpt1)mad.f16 hr11.x, (r)hr37.w, hr36.x, (r)(last)hr11.x
mad.f16 hr15.z, hr38.y, hr35.y, (last)hr15.z
mad.f16 hr13.z, hr38.y, hr35.z, (last)hr13.z
mad.f16 hr11.z, hr38.y, hr35.w, (last)hr11.z
mad.f16 hr9.z, hr38.y, hr36.x, (last)hr9.z
mad.f16 hr17.w, hr38.z, hr35.x, (last)hr17.w
mad.f16 hr7.w, hr38.z, hr36.y, (last)hr7.w
mad.f16 hr5.w, hr38.z, hr36.z, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr38.w, hr35.x, (r)(last)hr18.x
(rpt1)mad.f16 hr8.x, (r)hr38.w, hr36.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr38.w, hr36.z, (r)(last)hr6.x
mad.f16 hr18.w, hr37.z, hr35.x, (last)hr18.w
mad.f16 hr8.w, hr37.z, hr36.y, (last)hr8.w
mad.f16 hr6.w, hr37.z, hr36.z, (last)hr6.w
mad.f16 hr19.x, hr37.w, hr35.x, (last)hr19.x
mad.f16 hr9.x, hr37.w, hr36.y, (last)hr9.x
mad.f16 hr7.x, hr37.w, hr36.z, (last)hr7.x
mad.f16 hr19.y, hr38.x, hr35.x, (last)hr19.y
mad.f16 hr9.y, hr38.x, hr36.y, (last)hr9.y
mad.f16 hr7.y, hr38.x, hr36.z, (last)hr7.y
mad.f16 hr17.z, hr38.y, hr35.x, (last)hr17.z
mad.f16 hr7.z, hr38.y, hr36.y, (last)hr7.z
mad.f16 hr5.z, hr38.y, hr36.z, (last)hr5.z
mad.f16 hr16.z, hr37.y, hr35.y, (last)hr16.z
mad.f16 hr18.z, hr37.y, hr35.x, (last)hr18.z
mad.f16 hr14.z, hr37.y, hr35.z, (last)hr14.z
mad.f16 hr12.z, hr37.y, hr35.w, (last)hr12.z
mad.f16 hr10.z, hr37.y, hr36.x, (last)hr10.z
mad.f16 hr8.z, hr37.y, hr36.y, (last)hr8.z
mad.f16 hr6.z, hr37.y, hr36.z, (last)hr6.z
mad.f16 hr3.w, (last)hr38.z, hr36.w, (last)hr34.y
(rpt1)mad.f16 hr4.x, (r)(last)hr38.w, hr36.w, (r)(last)hr34.z
mad.f16 hr4.w, (last)hr37.z, hr36.w, (last)hr33.y
(rpt1)mad.f16 hr5.x, (r)(last)hr37.w, hr36.w, (r)(last)hr33.z
mad.f16 hr3.z, (last)hr38.y, hr36.w, (last)hr34.x
mad.f16 hr4.z, (last)hr37.y, hr36.w, (last)hr33.x
br p0.x, #l1138
jump #l130
l1138:
(jp)(eolm)nop
(nop3) add.u r11.w, r51.w, (last)r11.w
(nop3) shl.b r11.w, (last)r11.w, 9
(nop3) sad.s32 r11.w, r52.w, r11.w, (last)r1.z
(nop3) shl.b r11.w, (last)r11.w, 2
add.u r19.w, r11.w, c1.x
add.u r20.x, r11.w, c8.y
add.u r20.y, r11.w, c4.z
add.u r20.z, r11.w, c8.x
add.u r0.x, r11.w, c4.y
add.u r0.y, r11.w, c7.w
add.u r0.z, r11.w, c8.z
(rpt1)add.u r0.w, (r)c8.w, r11.w
(rpt1)add.u r1.y, (r)c9.y, r11.w
stib.b.untyped.1d.u16.4.imm.base0 hr18.z, r11.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r11.w+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r19.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r20.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r20.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r20.z, 4
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
(ss)(rpt1)add.u r3.y, (r)c9.w, r11.w
(nop3) add.u r11.w, c10.y, (last)r11.w
nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r3.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r3.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r11.w, 4
end
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1291 instr, 31 nops, 1260 non-nops, 65 mov, 0 cov, 2368 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 21 full, 12 constlen
; CL prog 23/1: 34 cat0, 65 cat1, 76 cat2, 1028 cat3, 0 cat4, 34 cat5, 50 cat6, 4 cat7
; CL prog 23/1: 30 sstall, 17 (ss), 283 systall, 12 (sy), 1 loops
; CL prog 23/1: 12 max_waves, 0 double_threadsize
; 58 preamble-instr, 1 early-preamble
