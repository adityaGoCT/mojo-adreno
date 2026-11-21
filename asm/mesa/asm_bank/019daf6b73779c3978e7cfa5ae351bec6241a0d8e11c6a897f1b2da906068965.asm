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
@const(c4.x)	0x00002000, 0x00001800, 0x00001000, 0x00000840
@const(c5.x)	0x00001040, 0x00001840, 0x00020000, 0x00007840
@const(c6.x)	0x00007040, 0x00006840, 0x00006040, 0x00005840
@const(c7.x)	0x00005040, 0x00004840, 0x00004040, 0x00003840
@const(c8.x)	0x00003040, 0x00002840, 0x00002040, 0x00020040
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
mov.u32u32 r52.z, 2112
mov.u32u32 r52.w, 0x1040
mov.u32u32 r53.x, 0x1840
mov.u32u32 r53.y, 0x20000
mov.u32u32 r53.z, 0x7840
mov.u32u32 r53.w, 0x7040
mov.u32u32 r54.x, 0x6840
mov.u32u32 r54.y, 0x6040
mov.u32u32 r54.z, 0x5840
mov.u32u32 r54.w, 0x5040
mov.u32u32 r55.x, 0x4840
mov.u32u32 r55.y, 0x4040
mov.u32u32 r55.z, 0x3840
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
(ss)mov.u32u32 r48.w, 0x3040
mov.u32u32 r49.x, 0x2840
mov.u32u32 r49.y, 0x2040
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
l130:
shr.b r52.z, r52.x, 2
shr.b r52.w, r51.w, 2
shl.b r53.x, r52.y, 9
add.u r10.z, r0.x, 256
shl.b r9.w, r0.w, 8
(rpt1)shl.b r10.x, (r)r1.x, 3
shr.b r10.z, (last)r10.z, 5
shl.b r10.w, r1.z, 2
(ss)add.u r11.y, r52.y, r0.w
sad.s32 r12.x, r53.x, r1.z, r52.w
shl.b r11.x, r10.z, 8
add.u r10.z, r52.y, (last)r10.z
add.u r52.y, r52.y, 16
cmps.u.ge up0.x, r52.y, c1.x
shl.b r11.y, (last)r11.y, 9
add.u r9.w, (last)r9.w, r10.x
shl.b r12.x, (last)r12.x, 2
shl.b r10.z, (last)r10.z, 9
sad.s32 r11.y, r52.z, r11.y, r1.x
add.u r11.x, (last)r11.x, (last)r10.x
add.u r12.y, r12.x, c1.x
sad.s32 r10.z, r52.z, r10.z, r1.x
shl.b r11.y, (last)r11.y, 2
add.u r12.z, r12.x, c4.w
add.u r12.w, r12.x, c4.z
shl.b r10.z, (last)r10.z, 2
add.u r13.x, r12.x, c5.x
add.u r13.y, r12.x, c4.y
add.u r13.z, r12.x, c5.y
isam.v.base0 (u16)(xyzw)hr23.x, r11.y, s#0, t#2
add.u r13.w, r12.x, c4.x
add.u r14.x, r12.x, c8.z
add.u r14.y, r12.x, c3.w
isam.v.base0 (u16)(xyzw)hr39.z, r10.z, s#0, t#2
add.u r14.z, r12.x, c8.y
add.u r14.w, r12.x, c3.z
add.u r15.x, r12.x, c8.x
add.u r15.y, r12.x, c3.y
add.u r15.z, r12.x, c7.w
add.u r15.w, r12.x, c3.x
add.u r16.x, r12.x, c7.z
add.u r16.y, r12.x, c2.w
add.u r16.z, r12.x, c7.y
add.u r16.w, r12.x, c2.z
add.u r17.x, r12.x, c7.x
add.u r17.y, r12.x, c2.y
add.u r17.z, r12.x, c6.w
add.u r17.w, r12.x, c2.x
add.u r18.x, r12.x, c6.z
add.u r18.y, r12.x, c1.w
add.u r18.z, r12.x, c6.y
add.u r18.w, r12.x, c1.z
add.u r19.x, r12.x, c6.x
add.u r19.y, r12.x, c1.y
add.u r19.z, r12.x, c5.w
(sy)stl.u16 l[r9.w], r23.x, 4
stl.u16 l[r11.x], r39.z, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
isam.v.base0 (u16)(xyzw)hr40.z, r12.x, s#0, t#0
ldl.u16 r22.x, l[r10.y], 4
isam.v.base0 (u16)(xyzw)hr23.x, r12.x+64, s#0, t#0
ldl.u16 r39.z, l[r10.y+128], 4
(sy)(ss)mad.f16 hr18.z, hr22.x, hr40.z, (last)hr18.z
mad.f16 hr16.z, hr22.x, hr40.w, (last)hr16.z
mad.f16 hr14.z, hr22.x, hr41.x, (last)hr14.z
mad.f16 hr12.z, hr22.x, hr41.y, (last)hr12.z
mad.f16 hr18.w, hr22.y, hr40.z, (last)hr18.w
mad.f16 hr16.w, hr22.y, hr40.w, (last)hr16.w
mad.f16 hr14.w, hr22.y, hr41.x, (last)hr14.w
mad.f16 hr12.w, hr22.y, hr41.y, (last)hr12.w
mad.f16 hr19.x, hr22.z, hr40.z, (last)hr19.x
mad.f16 hr17.x, hr22.z, hr40.w, (last)hr17.x
mad.f16 hr15.x, hr22.z, hr41.x, (last)hr15.x
mad.f16 hr13.x, hr22.z, hr41.y, (last)hr13.x
mad.f16 hr19.y, hr22.w, hr40.z, (last)hr19.y
mad.f16 hr17.y, hr22.w, hr40.w, (last)hr17.y
mad.f16 hr15.y, hr22.w, hr41.x, (last)hr15.y
mad.f16 hr13.y, hr22.w, hr41.y, (last)hr13.y
mad.f16 hr17.z, hr39.z, hr40.z, (last)hr17.z
mad.f16 hr15.z, hr39.z, hr40.w, (last)hr15.z
mad.f16 hr13.z, hr39.z, hr41.x, (last)hr13.z
mad.f16 hr11.z, hr39.z, hr41.y, (last)hr11.z
mad.f16 hr17.w, hr39.w, hr40.z, (last)hr17.w
mad.f16 hr15.w, hr39.w, hr40.w, (last)hr15.w
mad.f16 hr13.w, hr39.w, hr41.x, (last)hr13.w
mad.f16 hr11.w, hr39.w, hr41.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr40.x, hr40.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr40.x, hr40.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr40.x, hr41.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr40.x, hr41.y, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr40.z, r12.y, s#0, t#0
isam.v.base0 (u16)(xyzw)hr19.z, r12.z, s#0, t#0
(ss)nop
isam.v.base0 (u16)(xyzw)hr24.x, r12.w, s#0, t#0
(rpt1)mad.f16 hr10.z, (r)hr22.x, hr23.x, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr22.z, hr23.x, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr22.x, hr23.y, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr22.z, hr23.y, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr22.x, hr23.z, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr22.z, hr23.z, (r)(last)hr7.x
mad.f16 hr9.z, hr39.z, hr23.x, (last)hr9.z
mad.f16 hr7.z, hr39.z, hr23.y, (last)hr7.z
mad.f16 hr5.z, hr39.z, hr23.z, (last)hr5.z
mad.f16 hr9.w, hr39.w, hr23.x, (last)hr9.w
mad.f16 hr7.w, hr39.w, hr23.y, (last)hr7.w
mad.f16 hr5.w, hr39.w, hr23.z, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr40.x, hr23.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr40.x, hr23.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr40.x, hr23.z, (r)(last)hr6.x
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr23.w, (r)(last)hr4.z
(rpt1)mad.f16 hr22.z, (r)(last)hr22.z, hr23.w, (r)(last)hr5.x
(rpt1)mad.f16 hr39.z, (r)(last)hr39.z, hr23.w, (r)(last)hr3.z
(rpt1)mad.f16 hr40.x, (r)(last)hr40.x, hr23.w, (r)(last)hr4.x
ldl.u16 r3.w, l[r10.y+256], 4
ldl.u16 r23.x, l[r10.y+384], 4
(sy)(ss)mad.f16 hr17.z, hr23.x, hr40.z, (last)hr17.z
ldl.u16 r25.x, l[r10.y+512], 4
mad.f16 hr15.z, hr23.x, hr40.w, (last)hr15.z
mad.f16 hr13.z, hr23.x, hr41.x, (last)hr13.z
mad.f16 hr11.z, hr23.x, hr41.y, (last)hr11.z
mad.f16 hr9.z, hr23.x, hr19.z, (last)hr9.z
mad.f16 hr7.z, hr23.x, hr19.w, (last)hr7.z
mad.f16 hr5.z, hr23.x, hr20.x, (last)hr5.z
mad.f16 hr17.w, hr23.y, hr40.z, (last)hr17.w
mad.f16 hr15.w, hr23.y, hr40.w, (last)hr15.w
mad.f16 hr13.w, hr23.y, hr41.x, (last)hr13.w
mad.f16 hr11.w, hr23.y, hr41.y, (last)hr11.w
mad.f16 hr9.w, hr23.y, hr19.z, (last)hr9.w
mad.f16 hr7.w, hr23.y, hr19.w, (last)hr7.w
mad.f16 hr5.w, hr23.y, hr20.x, (last)hr5.w
(rpt1)mad.f16 hr18.x, (r)hr23.z, hr40.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr23.z, hr40.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr23.z, hr41.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr23.z, hr41.y, (r)(last)hr12.x
(rpt1)mad.f16 hr10.x, (r)hr23.z, hr19.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr23.z, hr19.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr23.z, hr20.x, (r)(last)hr6.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr20.y, (r)(last)hr39.z
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr20.y, (r)(last)hr40.x
isam.v.base0 (u16)(xyzw)hr39.z, r13.x, s#0, t#0
isam.v.base0 (u16)(xyzw)hr0.z, r13.y, s#0, t#0
mad.f16 hr18.z, hr3.w, hr40.z, (last)hr18.z
mad.f16 hr16.z, hr3.w, hr40.w, (last)hr16.z
mad.f16 hr14.z, hr3.w, hr41.x, (last)hr14.z
mad.f16 hr12.z, hr3.w, hr41.y, (last)hr12.z
mad.f16 hr18.w, hr4.x, hr40.z, (last)hr18.w
mad.f16 hr16.w, hr4.x, hr40.w, (last)hr16.w
mad.f16 hr14.w, hr4.x, hr41.x, (last)hr14.w
mad.f16 hr12.w, hr4.x, hr41.y, (last)hr12.w
mad.f16 hr19.x, hr4.y, hr40.z, (last)hr19.x
mad.f16 hr17.x, hr4.y, hr40.w, (last)hr17.x
mad.f16 hr15.x, hr4.y, hr41.x, (last)hr15.x
mad.f16 hr13.x, hr4.y, hr41.y, (last)hr13.x
mad.f16 hr19.y, hr4.z, hr40.z, (last)hr19.y
mad.f16 hr17.y, hr4.z, hr40.w, (last)hr17.y
mad.f16 hr15.y, hr4.z, hr41.x, (last)hr15.y
mad.f16 hr13.y, hr4.z, hr41.y, (last)hr13.y
ldl.u16 r40.w, l[r10.y+640], 4
(rpt1)mad.f16 hr10.z, (r)hr3.w, hr19.z, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr4.y, hr19.z, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr3.w, hr19.w, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr4.y, hr19.w, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr3.w, hr20.x, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr4.y, hr20.x, (r)(last)hr7.x
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr20.y, (r)(last)hr22.x
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr20.y, (r)(last)hr22.z
isam.v.base0 (u16)(xyzw)hr19.z, r13.z, s#0, t#0
(ss)mad.f16 hr18.z, hr25.x, hr24.x, (last)hr18.z
mad.f16 hr16.z, hr25.x, hr24.y, (last)hr16.z
mad.f16 hr14.z, hr25.x, hr24.z, (last)hr14.z
mad.f16 hr12.z, hr25.x, hr24.w, (last)hr12.z
mad.f16 hr18.w, hr25.y, hr24.x, (last)hr18.w
mad.f16 hr16.w, hr25.y, hr24.y, (last)hr16.w
mad.f16 hr14.w, hr25.y, hr24.z, (last)hr14.w
mad.f16 hr12.w, hr25.y, hr24.w, (last)hr12.w
mad.f16 hr19.x, hr25.z, hr24.x, (last)hr19.x
mad.f16 hr17.x, hr25.z, hr24.y, (last)hr17.x
mad.f16 hr15.x, hr25.z, hr24.z, (last)hr15.x
mad.f16 hr13.x, hr25.z, hr24.w, (last)hr13.x
mad.f16 hr19.y, hr25.w, hr24.x, (last)hr19.y
mad.f16 hr17.y, hr25.w, hr24.y, (last)hr17.y
mad.f16 hr15.y, hr25.w, hr24.z, (last)hr15.y
mad.f16 hr13.y, hr25.w, hr24.w, (last)hr13.y
mad.f16 hr17.z, hr40.w, hr24.x, (last)hr17.z
mad.f16 hr15.z, hr40.w, hr24.y, (last)hr15.z
mad.f16 hr13.z, hr40.w, hr24.z, (last)hr13.z
mad.f16 hr11.z, hr40.w, hr24.w, (last)hr11.z
mad.f16 hr17.w, hr41.x, hr24.x, (last)hr17.w
mad.f16 hr15.w, hr41.x, hr24.y, (last)hr15.w
mad.f16 hr13.w, hr41.x, hr24.z, (last)hr13.w
mad.f16 hr11.w, hr41.x, hr24.w, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr41.y, hr24.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr41.y, hr24.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr41.y, hr24.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr41.y, hr24.w, (r)(last)hr12.x
(sy)(rpt1)mad.f16 hr10.z, (r)hr25.x, hr39.z, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr25.z, hr39.z, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr25.x, hr39.w, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr25.z, hr39.w, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr25.x, hr40.x, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr25.z, hr40.x, (r)(last)hr7.x
(rpt1)mad.f16 hr25.x, (r)(last)hr25.x, hr40.y, (r)(last)hr3.w
(rpt1)mad.f16 hr25.z, (r)(last)hr25.z, hr40.y, (r)(last)hr4.y
ldl.u16 r3.w, l[r10.y+768], 4
ldl.u16 r22.x, l[r10.y+896], 4
ldl.u16 r24.x, l[r10.y+1024], 4
ldl.u16 r26.y, l[r10.y+1152], 4
mad.f16 hr9.z, hr40.w, hr39.z, (last)hr9.z
mad.f16 hr7.z, hr40.w, hr39.w, (last)hr7.z
mad.f16 hr5.z, hr40.w, hr40.x, (last)hr5.z
mad.f16 hr9.w, hr41.x, hr39.z, (last)hr9.w
mad.f16 hr7.w, hr41.x, hr39.w, (last)hr7.w
mad.f16 hr5.w, hr41.x, hr40.x, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr41.y, hr39.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr41.y, hr39.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr41.y, hr40.x, (r)(last)hr6.x
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr40.y, (r)(last)hr23.x
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr40.y, (r)(last)hr23.z
isam.v.base0 (u16)(xyzw)hr23.x, r13.w, s#0, t#0
ldl.u16 r39.w, l[r10.y+1280], 4
(ss)mad.f16 hr18.z, hr3.w, hr0.z, (last)hr18.z
mad.f16 hr16.z, hr3.w, hr0.w, (last)hr16.z
mad.f16 hr14.z, hr3.w, hr1.x, (last)hr14.z
mad.f16 hr12.z, hr3.w, hr1.y, (last)hr12.z
mad.f16 hr18.w, hr4.x, hr0.z, (last)hr18.w
mad.f16 hr16.w, hr4.x, hr0.w, (last)hr16.w
mad.f16 hr14.w, hr4.x, hr1.x, (last)hr14.w
mad.f16 hr12.w, hr4.x, hr1.y, (last)hr12.w
mad.f16 hr19.x, hr4.y, hr0.z, (last)hr19.x
mad.f16 hr17.x, hr4.y, hr0.w, (last)hr17.x
mad.f16 hr15.x, hr4.y, hr1.x, (last)hr15.x
mad.f16 hr13.x, hr4.y, hr1.y, (last)hr13.x
mad.f16 hr19.y, hr4.z, hr0.z, (last)hr19.y
mad.f16 hr17.y, hr4.z, hr0.w, (last)hr17.y
mad.f16 hr15.y, hr4.z, hr1.x, (last)hr15.y
mad.f16 hr13.y, hr4.z, hr1.y, (last)hr13.y
(rpt1)mad.f16 hr10.z, (r)hr3.w, hr19.z, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr4.y, hr19.z, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr3.w, hr19.w, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr4.y, hr19.w, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr3.w, hr20.x, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr4.y, hr20.x, (r)(last)hr7.x
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr20.y, (r)(last)hr25.x
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr20.y, (r)(last)hr25.z
isam.v.base0 (u16)(xyzw)hr25.x, r14.x, s#0, t#0
(ss)nop
isam.v.base0 (u16)(xyzw)hr27.y, r14.y, s#0, t#0
mad.f16 hr17.z, hr22.x, hr0.z, (last)hr17.z
mad.f16 hr15.z, hr22.x, hr0.w, (last)hr15.z
mad.f16 hr13.z, hr22.x, hr1.x, (last)hr13.z
mad.f16 hr11.z, hr22.x, hr1.y, (last)hr11.z
mad.f16 hr17.w, hr22.y, hr0.z, (last)hr17.w
mad.f16 hr15.w, hr22.y, hr0.w, (last)hr15.w
mad.f16 hr13.w, hr22.y, hr1.x, (last)hr13.w
mad.f16 hr11.w, hr22.y, hr1.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr22.z, hr0.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr22.z, hr0.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr22.z, hr1.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr22.z, hr1.y, (r)(last)hr12.x
mad.f16 hr9.z, hr22.x, hr19.z, (last)hr9.z
mad.f16 hr7.z, hr22.x, hr19.w, (last)hr7.z
mad.f16 hr5.z, hr22.x, hr20.x, (last)hr5.z
mad.f16 hr9.w, hr22.y, hr19.z, (last)hr9.w
mad.f16 hr7.w, hr22.y, hr19.w, (last)hr7.w
mad.f16 hr5.w, hr22.y, hr20.x, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr22.z, hr19.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr22.z, hr19.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr22.z, hr20.x, (r)(last)hr6.x
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr20.y, (r)(last)hr40.w
(rpt1)mad.f16 hr22.z, (r)(last)hr22.z, hr20.y, (r)(last)hr41.y
isam.v.base0 (u16)(xyzw)hr40.w, r14.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr19.z, r14.w, s#0, t#0
(sy)mad.f16 hr18.z, hr24.x, hr23.x, (last)hr18.z
mad.f16 hr16.z, hr24.x, hr23.y, (last)hr16.z
mad.f16 hr14.z, hr24.x, hr23.z, (last)hr14.z
mad.f16 hr12.z, hr24.x, hr23.w, (last)hr12.z
mad.f16 hr18.w, hr24.y, hr23.x, (last)hr18.w
mad.f16 hr16.w, hr24.y, hr23.y, (last)hr16.w
mad.f16 hr14.w, hr24.y, hr23.z, (last)hr14.w
mad.f16 hr12.w, hr24.y, hr23.w, (last)hr12.w
mad.f16 hr19.x, hr24.z, hr23.x, (last)hr19.x
mad.f16 hr17.x, hr24.z, hr23.y, (last)hr17.x
mad.f16 hr15.x, hr24.z, hr23.z, (last)hr15.x
mad.f16 hr13.x, hr24.z, hr23.w, (last)hr13.x
mad.f16 hr19.y, hr24.w, hr23.x, (last)hr19.y
mad.f16 hr17.y, hr24.w, hr23.y, (last)hr17.y
mad.f16 hr15.y, hr24.w, hr23.z, (last)hr15.y
mad.f16 hr13.y, hr24.w, hr23.w, (last)hr13.y
mad.f16 hr17.z, hr26.y, hr23.x, (last)hr17.z
mad.f16 hr15.z, hr26.y, hr23.y, (last)hr15.z
mad.f16 hr13.z, hr26.y, hr23.z, (last)hr13.z
mad.f16 hr11.z, hr26.y, hr23.w, (last)hr11.z
mad.f16 hr17.w, hr26.z, hr23.x, (last)hr17.w
mad.f16 hr15.w, hr26.z, hr23.y, (last)hr15.w
mad.f16 hr13.w, hr26.z, hr23.z, (last)hr13.w
mad.f16 hr11.w, hr26.z, hr23.w, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr26.w, hr23.x, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr26.w, hr23.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr26.w, hr23.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr26.w, hr23.w, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr23.x, r15.x, s#0, t#0
(rpt1)mad.f16 hr10.z, (r)hr24.x, hr25.x, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr24.z, hr25.x, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr24.x, hr25.y, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr24.z, hr25.y, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr24.x, hr25.z, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr24.z, hr25.z, (r)(last)hr7.x
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr25.w, (r)(last)hr3.w
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr25.w, (r)(last)hr4.y
ldl.u16 r3.w, l[r10.y+1408], 4
mad.f16 hr9.z, hr26.y, hr25.x, (last)hr9.z
mad.f16 hr7.z, hr26.y, hr25.y, (last)hr7.z
mad.f16 hr5.z, hr26.y, hr25.z, (last)hr5.z
mad.f16 hr9.w, hr26.z, hr25.x, (last)hr9.w
mad.f16 hr7.w, hr26.z, hr25.y, (last)hr7.w
mad.f16 hr5.w, hr26.z, hr25.z, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr26.w, hr25.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr26.w, hr25.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr26.w, hr25.z, (r)(last)hr6.x
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr25.w, (r)(last)hr22.x
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr25.w, (r)(last)hr22.z
isam.v.base0 (u16)(xyzw)hr25.x, r15.y, s#0, t#0
ldl.u16 r22.x, l[r10.y+1536], 4
mad.f16 hr18.z, hr39.w, hr27.y, (last)hr18.z
mad.f16 hr16.z, hr39.w, hr27.z, (last)hr16.z
mad.f16 hr14.z, hr39.w, hr27.w, (last)hr14.z
mad.f16 hr12.z, hr39.w, hr28.x, (last)hr12.z
mad.f16 hr18.w, hr40.x, hr27.y, (last)hr18.w
mad.f16 hr16.w, hr40.x, hr27.z, (last)hr16.w
mad.f16 hr14.w, hr40.x, hr27.w, (last)hr14.w
mad.f16 hr12.w, hr40.x, hr28.x, (last)hr12.w
mad.f16 hr19.x, hr40.y, hr27.y, (last)hr19.x
mad.f16 hr17.x, hr40.y, hr27.z, (last)hr17.x
mad.f16 hr15.x, hr40.y, hr27.w, (last)hr15.x
mad.f16 hr13.x, hr40.y, hr28.x, (last)hr13.x
mad.f16 hr19.y, hr40.z, hr27.y, (last)hr19.y
mad.f16 hr17.y, hr40.z, hr27.z, (last)hr17.y
mad.f16 hr15.y, hr40.z, hr27.w, (last)hr15.y
mad.f16 hr13.y, hr40.z, hr28.x, (last)hr13.y
(ss)mad.f16 hr17.z, hr3.w, hr27.y, (last)hr17.z
mad.f16 hr15.z, hr3.w, hr27.z, (last)hr15.z
mad.f16 hr13.z, hr3.w, hr27.w, (last)hr13.z
mad.f16 hr11.z, hr3.w, hr28.x, (last)hr11.z
mad.f16 hr17.w, hr4.x, hr27.y, (last)hr17.w
mad.f16 hr15.w, hr4.x, hr27.z, (last)hr15.w
mad.f16 hr13.w, hr4.x, hr27.w, (last)hr13.w
mad.f16 hr11.w, hr4.x, hr28.x, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr4.y, hr27.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr4.y, hr27.z, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr4.y, hr27.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr4.y, hr28.x, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr27.y, r15.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr29.y, r15.w, s#0, t#0
(rpt1)mad.f16 hr10.z, (r)hr39.w, hr40.w, (r)(last)hr10.z
(rpt1)mad.f16 hr11.x, (r)hr40.y, hr40.w, (r)(last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr39.w, hr41.x, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr40.y, hr41.x, (r)(last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr39.w, hr41.y, (r)(last)hr6.z
(rpt1)mad.f16 hr7.x, (r)hr40.y, hr41.y, (r)(last)hr7.x
mad.f16 hr9.z, hr3.w, hr40.w, (last)hr9.z
mad.f16 hr7.z, hr3.w, hr41.x, (last)hr7.z
mad.f16 hr5.z, hr3.w, hr41.y, (last)hr5.z
mad.f16 hr9.w, hr4.x, hr40.w, (last)hr9.w
mad.f16 hr7.w, hr4.x, hr41.x, (last)hr7.w
mad.f16 hr5.w, hr4.x, hr41.y, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr4.y, hr40.w, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr4.y, hr41.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr4.y, hr41.y, (r)(last)hr6.x
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr41.z, (r)(last)hr24.x
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr41.z, (r)(last)hr24.z
ldl.u16 r24.x, l[r10.y+1664], 4
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr41.z, (r)(last)hr26.y
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr41.z, (r)(last)hr26.w
ldl.u16 r26.y, l[r10.y+1792], 4
ldl.u16 r28.y, l[r10.y+1920], 4
mad.f16 hr18.z, hr22.x, hr19.z, (last)hr18.z
mad.f16 hr16.z, hr22.x, hr19.w, (last)hr16.z
mad.f16 hr14.z, hr22.x, hr20.x, (last)hr14.z
mad.f16 hr12.z, hr22.x, hr20.y, (last)hr12.z
mad.f16 hr18.w, hr22.y, hr19.z, (last)hr18.w
mad.f16 hr16.w, hr22.y, hr19.w, (last)hr16.w
mad.f16 hr14.w, hr22.y, hr20.x, (last)hr14.w
mad.f16 hr12.w, hr22.y, hr20.y, (last)hr12.w
mad.f16 hr19.x, hr22.z, hr19.z, (last)hr19.x
mad.f16 hr17.x, hr22.z, hr19.w, (last)hr17.x
(ss)nop
ldl.u16 r30.w, l[r10.y+2048], 4
ldl.u16 r40.w, l[r10.y+2176], 4
mad.f16 hr15.x, hr22.z, hr20.x, (last)hr15.x
mad.f16 hr13.x, hr22.z, hr20.y, (last)hr13.x
(sy)(rpt1)mad.f16 hr10.z, (r)hr22.x, hr23.x, (r)(last)hr10.z
mad.f16 hr11.x, hr22.z, hr23.x, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr22.x, hr23.y, (r)(last)hr8.z
mad.f16 hr9.x, hr22.z, hr23.y, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr22.x, hr23.z, (r)(last)hr6.z
mad.f16 hr7.x, hr22.z, hr23.z, (last)hr7.x
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr23.w, (r)(last)hr39.w
mad.f16 hr22.z, (last)hr22.z, hr23.w, (last)hr40.y
isam.v.base0 (u16)(xyzw)hr39.z, r16.x, s#0, t#0
isam.v.base0 (u16)(xyzw)hr0.z, r16.y, s#0, t#0
mad.f16 hr19.y, hr22.w, hr19.z, (last)hr19.y
mad.f16 hr17.y, hr22.w, hr19.w, (last)hr17.y
mad.f16 hr15.y, hr22.w, hr20.x, (last)hr15.y
mad.f16 hr13.y, hr22.w, hr20.y, (last)hr13.y
mad.f16 hr17.z, hr24.x, hr19.z, (last)hr17.z
mad.f16 hr15.z, hr24.x, hr19.w, (last)hr15.z
mad.f16 hr13.z, hr24.x, hr20.x, (last)hr13.z
mad.f16 hr11.z, hr24.x, hr20.y, (last)hr11.z
mad.f16 hr17.w, hr24.y, hr19.z, (last)hr17.w
mad.f16 hr15.w, hr24.y, hr19.w, (last)hr15.w
mad.f16 hr13.w, hr24.y, hr20.x, (last)hr13.w
mad.f16 hr11.w, hr24.y, hr20.y, (last)hr11.w
(rpt1)mad.f16 hr18.x, (r)hr24.z, hr19.z, (r)(last)hr18.x
(rpt1)mad.f16 hr16.x, (r)hr24.z, hr19.w, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr24.z, hr20.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr24.z, hr20.y, (r)(last)hr12.x
isam.v.base0 (u16)(xyzw)hr19.z, r16.z, s#0, t#0
mad.f16 hr11.y, hr22.w, hr23.x, (last)hr11.y
mad.f16 hr9.y, hr22.w, hr23.y, (last)hr9.y
mad.f16 hr7.y, hr22.w, hr23.z, (last)hr7.y
mad.f16 hr9.z, hr24.x, hr23.x, (last)hr9.z
mad.f16 hr7.z, hr24.x, hr23.y, (last)hr7.z
mad.f16 hr5.z, hr24.x, hr23.z, (last)hr5.z
mad.f16 hr9.w, hr24.y, hr23.x, (last)hr9.w
mad.f16 hr7.w, hr24.y, hr23.y, (last)hr7.w
mad.f16 hr5.w, hr24.y, hr23.z, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr24.z, hr23.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr24.z, hr23.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr24.z, hr23.z, (r)(last)hr6.x
mad.f16 hr16.z, hr26.y, hr25.y, (last)hr16.z
mad.f16 hr14.z, hr26.y, hr25.z, (last)hr14.z
mad.f16 hr12.z, hr26.y, hr25.w, (last)hr12.z
mad.f16 hr16.w, hr26.z, hr25.y, (last)hr16.w
mad.f16 hr14.w, hr26.z, hr25.z, (last)hr14.w
mad.f16 hr12.w, hr26.z, hr25.w, (last)hr12.w
mad.f16 hr17.x, hr26.w, hr25.y, (last)hr17.x
mad.f16 hr15.x, hr26.w, hr25.z, (last)hr15.x
mad.f16 hr13.x, hr26.w, hr25.w, (last)hr13.x
mad.f16 hr17.y, hr27.x, hr25.y, (last)hr17.y
mad.f16 hr15.y, hr27.x, hr25.z, (last)hr15.y
mad.f16 hr13.y, hr27.x, hr25.w, (last)hr13.y
mad.f16 hr15.z, hr28.y, hr25.y, (last)hr15.z
mad.f16 hr13.z, hr28.y, hr25.z, (last)hr13.z
mad.f16 hr11.z, hr28.y, hr25.w, (last)hr11.z
mad.f16 hr15.w, hr28.z, hr25.y, (last)hr15.w
mad.f16 hr13.w, hr28.z, hr25.z, (last)hr13.w
mad.f16 hr11.w, hr28.z, hr25.w, (last)hr11.w
(rpt1)mad.f16 hr16.x, (r)hr28.w, hr25.y, (r)(last)hr16.x
(rpt1)mad.f16 hr14.x, (r)hr28.w, hr25.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr28.w, hr25.w, (r)(last)hr12.x
mad.f16 hr22.w, (last)hr22.w, hr23.w, (last)hr40.z
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr23.w, (r)(last)hr3.w
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr23.w, (r)(last)hr4.y
isam.v.base0 (u16)(xyzw)hr23.x, r16.w, s#0, t#0
isam.v.base0 (u16)(xyzw)hr25.y, r17.x, s#0, t#0
ldl.u16 r4.x, l[r10.y+2304], 4
(rpt1)mad.f16 hr18.z, (r)hr26.y, hr25.x, (r)(last)hr18.z
mad.f16 hr19.x, hr26.w, hr25.x, (last)hr19.x
(rpt1)mad.f16 hr10.z, (r)hr26.y, hr27.y, (r)(last)hr10.z
mad.f16 hr11.x, hr26.w, hr27.y, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr26.y, hr27.z, (r)(last)hr8.z
mad.f16 hr9.x, hr26.w, hr27.z, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr26.y, hr27.w, (r)(last)hr6.z
mad.f16 hr7.x, hr26.w, hr27.w, (last)hr7.x
mad.f16 hr19.y, hr27.x, hr25.x, (last)hr19.y
(rpt1)mad.f16 hr17.z, (r)hr28.y, hr25.x, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr28.w, hr25.x, (r)(last)hr18.x
mad.f16 hr11.y, hr27.x, hr27.y, (last)hr11.y
mad.f16 hr9.y, hr27.x, hr27.z, (last)hr9.y
mad.f16 hr7.y, hr27.x, hr27.w, (last)hr7.y
mad.f16 hr9.z, hr28.y, hr27.y, (last)hr9.z
mad.f16 hr7.z, hr28.y, hr27.z, (last)hr7.z
mad.f16 hr5.z, hr28.y, hr27.w, (last)hr5.z
mad.f16 hr9.w, hr28.z, hr27.y, (last)hr9.w
mad.f16 hr7.w, hr28.z, hr27.z, (last)hr7.w
mad.f16 hr5.w, hr28.z, hr27.w, (last)hr5.w
(rpt1)mad.f16 hr10.x, (r)hr28.w, hr27.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr28.w, hr27.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr28.w, hr27.w, (r)(last)hr6.x
(ss)mad.f16 hr14.z, hr30.w, hr29.w, (last)hr14.z
mad.f16 hr12.z, hr30.w, hr30.x, (last)hr12.z
mad.f16 hr14.w, hr31.x, hr29.w, (last)hr14.w
mad.f16 hr12.w, hr31.x, hr30.x, (last)hr12.w
mad.f16 hr15.x, hr31.y, hr29.w, (last)hr15.x
mad.f16 hr13.x, hr31.y, hr30.x, (last)hr13.x
mad.f16 hr15.y, hr31.z, hr29.w, (last)hr15.y
mad.f16 hr13.y, hr31.z, hr30.x, (last)hr13.y
mad.f16 hr13.z, hr40.w, hr29.w, (last)hr13.z
mad.f16 hr11.z, hr40.w, hr30.x, (last)hr11.z
mad.f16 hr13.w, hr41.x, hr29.w, (last)hr13.w
mad.f16 hr11.w, hr41.x, hr30.x, (last)hr11.w
(rpt1)mad.f16 hr14.x, (r)hr41.y, hr29.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr41.y, hr30.x, (r)(last)hr12.x
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr28.x, (r)(last)hr22.x
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr28.x, (r)(last)hr22.z
ldl.u16 r22.x, l[r10.y+2432], 4
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr28.x, (r)(last)hr24.x
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr28.x, (r)(last)hr24.z
isam.v.base0 (u16)(xyzw)hr27.y, r17.y, s#0, t#0
isam.v.base0 (u16)(xyzw)hr29.w, r17.z, s#0, t#0
ldl.u16 r24.y, l[r10.y+2560], 4
isam.v.base0 (u16)(xyzw)hr31.w, r17.w, s#0, t#0
(rpt1)mad.f16 hr16.z, (r)hr30.w, hr29.z, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr31.y, hr29.z, (r)(last)hr17.x
(rpt1)mad.f16 hr18.z, (r)hr30.w, hr29.y, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr31.y, hr29.y, (r)(last)hr19.x
mad.f16 hr15.z, hr40.w, hr29.z, (last)hr15.z
(ss)nop
isam.v.base0 (u16)(xyzw)hr34.x, r18.x, s#0, t#0
(ss)nop
isam.v.base0 (u16)(xyzw)hr36.x, r18.y, s#0, t#0
mad.f16 hr15.w, hr41.x, hr29.z, (last)hr15.w
(rpt1)mad.f16 hr16.x, (r)hr41.y, hr29.z, (r)(last)hr16.x
(rpt1)mad.f16 hr17.z, (r)hr40.w, hr29.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr41.y, hr29.y, (r)(last)hr18.x
(sy)(rpt1)mad.f16 hr10.z, (r)hr30.w, hr39.z, (r)(last)hr10.z
mad.f16 hr11.x, hr31.y, hr39.z, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr30.w, hr39.w, (r)(last)hr8.z
mad.f16 hr9.x, hr31.y, hr39.w, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr30.w, hr40.x, (r)(last)hr6.z
mad.f16 hr7.x, hr31.y, hr40.x, (last)hr7.x
mad.f16 hr11.y, hr31.z, hr39.z, (last)hr11.y
mad.f16 hr9.y, hr31.z, hr39.w, (last)hr9.y
mad.f16 hr7.y, hr31.z, hr40.x, (last)hr7.y
(rpt1)mad.f16 hr30.w, (r)(last)hr30.w, hr40.y, (r)(last)hr26.y
(rpt1)mad.f16 hr31.y, (r)(last)hr31.y, hr40.y, (r)(last)hr26.w
ldl.u16 r26.y, l[r10.y+2688], 4
(rpt1)mad.f16 hr10.x, (r)hr41.y, hr39.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr41.y, hr39.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr41.y, hr40.x, (r)(last)hr6.x
mad.f16 hr14.z, hr4.x, hr1.x, (last)hr14.z
mad.f16 hr12.z, hr4.x, hr1.y, (last)hr12.z
mad.f16 hr14.w, hr4.y, hr1.x, (last)hr14.w
mad.f16 hr12.w, hr4.y, hr1.y, (last)hr12.w
mad.f16 hr15.x, hr4.z, hr1.x, (last)hr15.x
mad.f16 hr13.x, hr4.z, hr1.y, (last)hr13.x
mad.f16 hr15.y, hr4.w, hr1.x, (last)hr15.y
mad.f16 hr13.y, hr4.w, hr1.y, (last)hr13.y
(rpt1)mad.f16 hr16.z, (r)hr4.x, hr0.w, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr4.z, hr0.w, (r)(last)hr17.x
(rpt1)mad.f16 hr18.z, (r)hr4.x, hr0.z, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr4.z, hr0.z, (r)(last)hr19.x
(rpt1)mad.f16 hr10.z, (r)hr4.x, hr19.z, (r)(last)hr10.z
mad.f16 hr11.x, hr4.z, hr19.z, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr4.x, hr19.w, (r)(last)hr8.z
mad.f16 hr9.x, hr4.z, hr19.w, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr4.x, hr20.x, (r)(last)hr6.z
mad.f16 hr7.x, hr4.z, hr20.x, (last)hr7.x
mad.f16 hr11.y, hr4.w, hr19.z, (last)hr11.y
mad.f16 hr9.y, hr4.w, hr19.w, (last)hr9.y
mad.f16 hr7.y, hr4.w, hr20.x, (last)hr7.y
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr40.y, (r)(last)hr28.w
ldl.u16 r28.w, l[r10.y+2816], 4
(rpt1)mad.f16 hr4.x, (r)(last)hr4.x, hr20.y, (r)(last)hr30.w
(rpt1)mad.f16 hr4.z, (r)(last)hr4.z, hr20.y, (r)(last)hr31.y
ldl.u16 r30.w, l[r10.y+2944], 4
ldl.u16 r33.x, l[r10.y+3072], 4
ldl.u16 r35.x, l[r10.y+3200], 4
mad.f16 hr9.z, hr40.w, hr39.z, (last)hr9.z
mad.f16 hr7.z, hr40.w, hr39.w, (last)hr7.z
mad.f16 hr5.z, hr40.w, hr40.x, (last)hr5.z
mad.f16 hr9.w, hr41.x, hr39.z, (last)hr9.w
mad.f16 hr7.w, hr41.x, hr39.w, (last)hr7.w
mad.f16 hr5.w, hr41.x, hr40.x, (last)hr5.w
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr40.y, (r)(last)hr28.y
ldl.u16 r39.w, l[r10.y+3328], 4
mad.f16 hr13.z, hr22.x, hr1.x, (last)hr13.z
mad.f16 hr11.z, hr22.x, hr1.y, (last)hr11.z
mad.f16 hr13.w, hr22.y, hr1.x, (last)hr13.w
mad.f16 hr11.w, hr22.y, hr1.y, (last)hr11.w
(rpt1)mad.f16 hr14.x, (r)hr22.z, hr1.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr22.z, hr1.y, (r)(last)hr12.x
(rpt1)mad.f16 hr15.z, (r)hr22.x, hr0.w, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr22.z, hr0.w, (r)(last)hr16.x
(rpt1)mad.f16 hr17.z, (r)hr22.x, hr0.z, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr22.z, hr0.z, (r)(last)hr18.x
(rpt1)mad.f16 hr10.x, (r)hr22.z, hr19.z, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr22.z, hr19.w, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr22.z, hr20.x, (r)(last)hr6.x
mad.f16 hr9.z, hr22.x, hr19.z, (last)hr9.z
mad.f16 hr7.z, hr22.x, hr19.w, (last)hr7.z
mad.f16 hr5.z, hr22.x, hr20.x, (last)hr5.z
mad.f16 hr9.w, hr22.y, hr19.z, (last)hr9.w
mad.f16 hr7.w, hr22.y, hr19.w, (last)hr7.w
mad.f16 hr5.w, hr22.y, hr20.x, (last)hr5.w
(rpt1)mad.f16 hr22.z, (r)(last)hr22.z, hr20.y, (r)(last)hr41.y
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr20.y, (r)(last)hr40.w
isam.v.base0 (u16)(xyzw)hr40.w, r18.z, s#0, t#0
isam.v.base0 (u16)(xyzw)hr19.z, r18.w, s#0, t#0
mad.f16 hr14.z, hr24.y, hr23.z, (last)hr14.z
mad.f16 hr12.z, hr24.y, hr23.w, (last)hr12.z
mad.f16 hr14.w, hr24.z, hr23.z, (last)hr14.w
mad.f16 hr12.w, hr24.z, hr23.w, (last)hr12.w
mad.f16 hr15.x, hr24.w, hr23.z, (last)hr15.x
mad.f16 hr13.x, hr24.w, hr23.w, (last)hr13.x
mad.f16 hr15.y, hr25.x, hr23.z, (last)hr15.y
mad.f16 hr13.y, hr25.x, hr23.w, (last)hr13.y
(rpt1)mad.f16 hr16.z, (r)hr24.y, hr23.y, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr24.w, hr23.y, (r)(last)hr17.x
(rpt1)mad.f16 hr18.z, (r)hr24.y, hr23.x, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr24.w, hr23.x, (r)(last)hr19.x
mad.f16 hr11.y, hr25.x, hr25.y, (last)hr11.y
mad.f16 hr9.y, hr25.x, hr25.z, (last)hr9.y
mad.f16 hr7.y, hr25.x, hr25.w, (last)hr7.y
(ss)mad.f16 hr13.z, hr26.y, hr23.z, (last)hr13.z
mad.f16 hr11.z, hr26.y, hr23.w, (last)hr11.z
mad.f16 hr13.w, hr26.z, hr23.z, (last)hr13.w
mad.f16 hr11.w, hr26.z, hr23.w, (last)hr11.w
(rpt1)mad.f16 hr14.x, (r)hr26.w, hr23.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr26.w, hr23.w, (r)(last)hr12.x
(rpt1)mad.f16 hr15.z, (r)hr26.y, hr23.y, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr26.w, hr23.y, (r)(last)hr16.x
(rpt1)mad.f16 hr17.z, (r)hr26.y, hr23.x, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr26.w, hr23.x, (r)(last)hr18.x
isam.v.base0 (u16)(xyzw)hr23.x, r19.x, s#0, t#0
mad.f16 hr25.x, (last)hr25.x, hr26.x, (last)hr4.w
(rpt1)mad.f16 hr10.z, (r)hr24.y, hr25.y, (r)(last)hr10.z
mad.f16 hr11.x, hr24.w, hr25.y, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr24.y, hr25.z, (r)(last)hr8.z
mad.f16 hr9.x, hr24.w, hr25.z, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr24.y, hr25.w, (r)(last)hr6.z
mad.f16 hr7.x, hr24.w, hr25.w, (last)hr7.x
(rpt1)mad.f16 hr10.x, (r)hr26.w, hr25.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr26.w, hr25.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr26.w, hr25.w, (r)(last)hr6.x
mad.f16 hr9.z, hr26.y, hr25.y, (last)hr9.z
mad.f16 hr7.z, hr26.y, hr25.z, (last)hr7.z
mad.f16 hr5.z, hr26.y, hr25.w, (last)hr5.z
mad.f16 hr9.w, hr26.z, hr25.y, (last)hr9.w
mad.f16 hr7.w, hr26.z, hr25.z, (last)hr7.w
mad.f16 hr5.w, hr26.z, hr25.w, (last)hr5.w
mad.f16 hr14.z, hr28.w, hr27.w, (last)hr14.z
mad.f16 hr12.z, hr28.w, hr28.x, (last)hr12.z
mad.f16 hr14.w, hr29.x, hr27.w, (last)hr14.w
mad.f16 hr12.w, hr29.x, hr28.x, (last)hr12.w
mad.f16 hr15.x, hr29.y, hr27.w, (last)hr15.x
mad.f16 hr13.x, hr29.y, hr28.x, (last)hr13.x
mad.f16 hr15.y, hr29.z, hr27.w, (last)hr15.y
mad.f16 hr13.y, hr29.z, hr28.x, (last)hr13.y
(rpt1)mad.f16 hr16.z, (r)hr28.w, hr27.z, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr29.y, hr27.z, (r)(last)hr17.x
(rpt1)mad.f16 hr18.z, (r)hr28.w, hr27.y, (r)(last)hr18.z
(rpt1)mad.f16 hr19.x, (r)hr29.y, hr27.y, (r)(last)hr19.x
mad.f16 hr11.y, hr29.z, hr29.w, (last)hr11.y
mad.f16 hr9.y, hr29.z, hr30.x, (last)hr9.y
mad.f16 hr7.y, hr29.z, hr30.y, (last)hr7.y
mad.f16 hr13.z, hr30.w, hr27.w, (last)hr13.z
mad.f16 hr11.z, hr30.w, hr28.x, (last)hr11.z
mad.f16 hr13.w, hr31.x, hr27.w, (last)hr13.w
mad.f16 hr11.w, hr31.x, hr28.x, (last)hr11.w
(rpt1)mad.f16 hr14.x, (r)hr31.y, hr27.w, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr31.y, hr28.x, (r)(last)hr12.x
(rpt1)mad.f16 hr15.z, (r)hr30.w, hr27.z, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr31.y, hr27.z, (r)(last)hr16.x
(rpt1)mad.f16 hr17.z, (r)hr30.w, hr27.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr31.y, hr27.y, (r)(last)hr18.x
mad.f16 hr29.z, (last)hr29.z, hr30.z, (last)hr25.x
isam.v.base0 (u16)(xyzw)hr25.x, r19.y, s#0, t#0
isam.v.base0 (u16)(xyzw)hr27.y, r19.z, s#0, t#0
(rpt1)mad.f16 hr24.y, (r)(last)hr24.y, hr26.x, (r)(last)hr4.x
mad.f16 hr24.w, (last)hr24.w, hr26.x, (last)hr4.z
ldl.u16 r3.w, l[r10.y+3456], 4
(rpt1)mad.f16 hr10.z, (r)hr28.w, hr29.w, (r)(last)hr10.z
mad.f16 hr11.x, hr29.y, hr29.w, (last)hr11.x
(rpt1)mad.f16 hr8.z, (r)hr28.w, hr30.x, (r)(last)hr8.z
mad.f16 hr9.x, hr29.y, hr30.x, (last)hr9.x
(rpt1)mad.f16 hr6.z, (r)hr28.w, hr30.y, (r)(last)hr6.z
mad.f16 hr7.x, hr29.y, hr30.y, (last)hr7.x
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr26.x, (r)(last)hr22.z
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr26.x, (r)(last)hr22.x
ldl.u16 r22.x, l[r10.y+3584], 4
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr30.z, (r)(last)hr24.y
mad.f16 hr29.y, (last)hr29.y, hr30.z, (last)hr24.w
ldl.u16 r24.x, l[r10.y+3712], 4
(rpt1)mad.f16 hr10.x, (r)hr31.y, hr29.w, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr31.y, hr30.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr31.y, hr30.y, (r)(last)hr6.x
mad.f16 hr9.z, hr30.w, hr29.w, (last)hr9.z
mad.f16 hr7.z, hr30.w, hr30.x, (last)hr7.z
mad.f16 hr5.z, hr30.w, hr30.y, (last)hr5.z
mad.f16 hr9.w, hr31.x, hr29.w, (last)hr9.w
mad.f16 hr7.w, hr31.x, hr30.x, (last)hr7.w
mad.f16 hr5.w, hr31.x, hr30.y, (last)hr5.w
mad.f16 hr14.z, hr33.x, hr32.y, (last)hr14.z
mad.f16 hr12.z, hr33.x, hr32.z, (last)hr12.z
mad.f16 hr14.w, hr33.y, hr32.y, (last)hr14.w
mad.f16 hr12.w, hr33.y, hr32.z, (last)hr12.w
(rpt1)mad.f16 hr16.z, (r)hr33.x, hr32.x, (r)(last)hr16.z
(rpt1)mad.f16 hr18.z, (r)hr33.x, hr31.w, (r)(last)hr18.z
(rpt1)mad.f16 hr10.z, (r)hr33.x, hr34.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr33.x, hr34.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr33.x, hr34.z, (r)(last)hr6.z
(rpt1)mad.f16 hr31.y, (r)(last)hr31.y, hr30.z, (r)(last)hr26.w
(rpt1)mad.f16 hr30.w, (r)(last)hr30.w, hr30.z, (r)(last)hr26.y
ldl.u16 r26.y, l[r10.y+3840], 4
(rpt1)mad.f16 hr33.x, (r)(last)hr33.x, hr34.w, (r)(last)hr28.w
ldl.u16 r28.y, l[r10.y+3968], 4
mad.f16 hr15.x, hr33.z, hr32.y, (last)hr15.x
mad.f16 hr13.x, hr33.z, hr32.z, (last)hr13.x
mad.f16 hr15.y, hr33.w, hr32.y, (last)hr15.y
mad.f16 hr13.y, hr33.w, hr32.z, (last)hr13.y
(rpt1)mad.f16 hr17.x, (r)hr33.z, hr32.x, (r)(last)hr17.x
(rpt1)mad.f16 hr19.x, (r)hr33.z, hr31.w, (r)(last)hr19.x
mad.f16 hr11.y, hr33.w, hr34.x, (last)hr11.y
mad.f16 hr9.y, hr33.w, hr34.y, (last)hr9.y
mad.f16 hr7.y, hr33.w, hr34.z, (last)hr7.y
mad.f16 hr13.z, hr35.x, hr32.y, (last)hr13.z
mad.f16 hr11.z, hr35.x, hr32.z, (last)hr11.z
mad.f16 hr13.w, hr35.y, hr32.y, (last)hr13.w
mad.f16 hr11.w, hr35.y, hr32.z, (last)hr11.w
(rpt1)mad.f16 hr14.x, (r)hr35.z, hr32.y, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr35.z, hr32.z, (r)(last)hr12.x
(rpt1)mad.f16 hr15.z, (r)hr35.x, hr32.x, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr35.z, hr32.x, (r)(last)hr16.x
(rpt1)mad.f16 hr17.z, (r)hr35.x, hr31.w, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr35.z, hr31.w, (r)(last)hr18.x
mad.f16 hr11.x, hr33.z, hr34.x, (last)hr11.x
mad.f16 hr9.x, hr33.z, hr34.y, (last)hr9.x
mad.f16 hr7.x, hr33.z, hr34.z, (last)hr7.x
(rpt1)mad.f16 hr10.x, (r)hr35.z, hr34.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr35.z, hr34.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr35.z, hr34.z, (r)(last)hr6.x
mad.f16 hr9.z, hr35.x, hr34.x, (last)hr9.z
mad.f16 hr7.z, hr35.x, hr34.y, (last)hr7.z
mad.f16 hr5.z, hr35.x, hr34.z, (last)hr5.z
mad.f16 hr9.w, hr35.y, hr34.x, (last)hr9.w
mad.f16 hr7.w, hr35.y, hr34.y, (last)hr7.w
mad.f16 hr5.w, hr35.y, hr34.z, (last)hr5.w
mad.f16 hr33.w, (last)hr33.w, hr34.w, (last)hr29.z
mad.f16 hr33.z, (last)hr33.z, hr34.w, (last)hr29.y
(rpt1)mad.f16 hr35.z, (r)(last)hr35.z, hr34.w, (r)(last)hr31.y
(rpt1)mad.f16 hr35.x, (r)(last)hr35.x, hr34.w, (r)(last)hr30.w
mad.f16 hr14.z, hr39.w, hr36.z, (last)hr14.z
mad.f16 hr12.z, hr39.w, hr36.w, (last)hr12.z
mad.f16 hr14.w, hr40.x, hr36.z, (last)hr14.w
mad.f16 hr12.w, hr40.x, hr36.w, (last)hr12.w
(rpt1)mad.f16 hr16.z, (r)hr39.w, hr36.y, (r)(last)hr16.z
(rpt1)mad.f16 hr18.z, (r)hr39.w, hr36.x, (r)(last)hr18.z
(sy)(rpt1)mad.f16 hr10.z, (r)hr39.w, hr40.w, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr39.w, hr41.x, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr39.w, hr41.y, (r)(last)hr6.z
mad.f16 hr15.x, hr40.y, hr36.z, (last)hr15.x
mad.f16 hr13.x, hr40.y, hr36.w, (last)hr13.x
mad.f16 hr15.y, hr40.z, hr36.z, (last)hr15.y
mad.f16 hr13.y, hr40.z, hr36.w, (last)hr13.y
(rpt1)mad.f16 hr17.x, (r)hr40.y, hr36.y, (r)(last)hr17.x
(rpt1)mad.f16 hr19.x, (r)hr40.y, hr36.x, (r)(last)hr19.x
mad.f16 hr11.y, hr40.z, hr40.w, (last)hr11.y
mad.f16 hr9.y, hr40.z, hr41.x, (last)hr9.y
mad.f16 hr7.y, hr40.z, hr41.y, (last)hr7.y
(ss)mad.f16 hr13.z, hr3.w, hr36.z, (last)hr13.z
mad.f16 hr11.z, hr3.w, hr36.w, (last)hr11.z
mad.f16 hr13.w, hr4.x, hr36.z, (last)hr13.w
mad.f16 hr11.w, hr4.x, hr36.w, (last)hr11.w
(rpt1)mad.f16 hr14.x, (r)hr4.y, hr36.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr4.y, hr36.w, (r)(last)hr12.x
(rpt1)mad.f16 hr15.z, (r)hr3.w, hr36.y, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr4.y, hr36.y, (r)(last)hr16.x
(rpt1)mad.f16 hr17.z, (r)hr3.w, hr36.x, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr4.y, hr36.x, (r)(last)hr18.x
mad.f16 hr11.x, hr40.y, hr40.w, (last)hr11.x
mad.f16 hr9.x, hr40.y, hr41.x, (last)hr9.x
mad.f16 hr7.x, hr40.y, hr41.y, (last)hr7.x
(rpt1)mad.f16 hr10.x, (r)hr4.y, hr40.w, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr4.y, hr41.x, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr4.y, hr41.y, (r)(last)hr6.x
mad.f16 hr9.z, hr3.w, hr40.w, (last)hr9.z
mad.f16 hr7.z, hr3.w, hr41.x, (last)hr7.z
mad.f16 hr5.z, hr3.w, hr41.y, (last)hr5.z
mad.f16 hr9.w, hr4.x, hr40.w, (last)hr9.w
mad.f16 hr7.w, hr4.x, hr41.x, (last)hr7.w
mad.f16 hr5.w, hr4.x, hr41.y, (last)hr5.w
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr41.z, (r)(last)hr33.x
mad.f16 hr40.z, (last)hr40.z, hr41.z, (last)hr33.w
mad.f16 hr40.y, (last)hr40.y, hr41.z, (last)hr33.z
(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr41.z, (r)(last)hr35.z
(rpt1)mad.f16 hr3.w, (r)(last)hr3.w, hr41.z, (r)(last)hr35.x
mad.f16 hr14.z, hr22.x, hr20.x, (last)hr14.z
mad.f16 hr12.z, hr22.x, hr20.y, (last)hr12.z
mad.f16 hr14.w, hr22.y, hr20.x, (last)hr14.w
mad.f16 hr12.w, hr22.y, hr20.y, (last)hr12.w
(rpt1)mad.f16 hr16.z, (r)hr22.x, hr19.w, (r)(last)hr16.z
(rpt1)mad.f16 hr18.z, (r)hr22.x, hr19.z, (r)(last)hr18.z
(rpt1)mad.f16 hr10.z, (r)hr22.x, hr23.x, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr22.x, hr23.y, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr22.x, hr23.z, (r)(last)hr6.z
mad.f16 hr15.x, hr22.z, hr20.x, (last)hr15.x
mad.f16 hr13.x, hr22.z, hr20.y, (last)hr13.x
mad.f16 hr15.y, hr22.w, hr20.x, (last)hr15.y
mad.f16 hr13.y, hr22.w, hr20.y, (last)hr13.y
(rpt1)mad.f16 hr17.x, (r)hr22.z, hr19.w, (r)(last)hr17.x
(rpt1)mad.f16 hr19.x, (r)hr22.z, hr19.z, (r)(last)hr19.x
mad.f16 hr11.y, hr22.w, hr23.x, (last)hr11.y
mad.f16 hr9.y, hr22.w, hr23.y, (last)hr9.y
mad.f16 hr7.y, hr22.w, hr23.z, (last)hr7.y
mad.f16 hr13.z, hr24.x, hr20.x, (last)hr13.z
mad.f16 hr11.z, hr24.x, hr20.y, (last)hr11.z
mad.f16 hr13.w, hr24.y, hr20.x, (last)hr13.w
mad.f16 hr11.w, hr24.y, hr20.y, (last)hr11.w
(rpt1)mad.f16 hr14.x, (r)hr24.z, hr20.x, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr24.z, hr20.y, (r)(last)hr12.x
(rpt1)mad.f16 hr15.z, (r)hr24.x, hr19.w, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr24.z, hr19.w, (r)(last)hr16.x
(rpt1)mad.f16 hr17.z, (r)hr24.x, hr19.z, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr24.z, hr19.z, (r)(last)hr18.x
mad.f16 hr11.x, hr22.z, hr23.x, (last)hr11.x
mad.f16 hr9.x, hr22.z, hr23.y, (last)hr9.x
mad.f16 hr7.x, hr22.z, hr23.z, (last)hr7.x
(rpt1)mad.f16 hr10.x, (r)hr24.z, hr23.x, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr24.z, hr23.y, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr24.z, hr23.z, (r)(last)hr6.x
mad.f16 hr9.z, hr24.x, hr23.x, (last)hr9.z
mad.f16 hr7.z, hr24.x, hr23.y, (last)hr7.z
mad.f16 hr5.z, hr24.x, hr23.z, (last)hr5.z
mad.f16 hr9.w, hr24.y, hr23.x, (last)hr9.w
mad.f16 hr7.w, hr24.y, hr23.y, (last)hr7.w
mad.f16 hr5.w, hr24.y, hr23.z, (last)hr5.w
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr23.w, (r)(last)hr39.w
mad.f16 hr22.w, (last)hr22.w, hr23.w, (last)hr40.z
mad.f16 hr22.z, (last)hr22.z, hr23.w, (last)hr40.y
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr23.w, (r)(last)hr4.y
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr23.w, (r)(last)hr3.w
fence.r.w
(sy)(ss)mad.f16 hr14.z, hr26.y, hr25.z, (last)hr14.z
mad.f16 hr12.z, hr26.y, hr25.w, (last)hr12.z
mad.f16 hr14.w, hr26.z, hr25.z, (last)hr14.w
mad.f16 hr12.w, hr26.z, hr25.w, (last)hr12.w
(rpt1)mad.f16 hr16.z, (r)hr26.y, hr25.y, (r)(last)hr16.z
(rpt1)mad.f16 hr18.z, (r)hr26.y, hr25.x, (r)(last)hr18.z
(rpt1)mad.f16 hr10.z, (r)hr26.y, hr27.y, (r)(last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr26.y, hr27.z, (r)(last)hr8.z
(rpt1)mad.f16 hr6.z, (r)hr26.y, hr27.w, (r)(last)hr6.z
mad.f16 hr15.x, hr26.w, hr25.z, (last)hr15.x
mad.f16 hr13.x, hr26.w, hr25.w, (last)hr13.x
mad.f16 hr15.y, hr27.x, hr25.z, (last)hr15.y
mad.f16 hr13.y, hr27.x, hr25.w, (last)hr13.y
(rpt1)mad.f16 hr17.x, (r)hr26.w, hr25.y, (r)(last)hr17.x
(rpt1)mad.f16 hr19.x, (r)hr26.w, hr25.x, (r)(last)hr19.x
mad.f16 hr11.y, hr27.x, hr27.y, (last)hr11.y
mad.f16 hr9.y, hr27.x, hr27.z, (last)hr9.y
mad.f16 hr7.y, hr27.x, hr27.w, (last)hr7.y
mad.f16 hr13.z, hr28.y, hr25.z, (last)hr13.z
mad.f16 hr11.z, hr28.y, hr25.w, (last)hr11.z
mad.f16 hr13.w, hr28.z, hr25.z, (last)hr13.w
mad.f16 hr11.w, hr28.z, hr25.w, (last)hr11.w
(rpt1)mad.f16 hr14.x, (r)hr28.w, hr25.z, (r)(last)hr14.x
(rpt1)mad.f16 hr12.x, (r)hr28.w, hr25.w, (r)(last)hr12.x
(rpt1)mad.f16 hr15.z, (r)hr28.y, hr25.y, (r)(last)hr15.z
(rpt1)mad.f16 hr16.x, (r)hr28.w, hr25.y, (r)(last)hr16.x
(rpt1)mad.f16 hr17.z, (r)hr28.y, hr25.x, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr28.w, hr25.x, (r)(last)hr18.x
mad.f16 hr11.x, hr26.w, hr27.y, (last)hr11.x
mad.f16 hr9.x, hr26.w, hr27.z, (last)hr9.x
mad.f16 hr7.x, hr26.w, hr27.w, (last)hr7.x
(rpt1)mad.f16 hr10.x, (r)hr28.w, hr27.y, (r)(last)hr10.x
(rpt1)mad.f16 hr8.x, (r)hr28.w, hr27.z, (r)(last)hr8.x
(rpt1)mad.f16 hr6.x, (r)hr28.w, hr27.w, (r)(last)hr6.x
mad.f16 hr9.z, hr28.y, hr27.y, (last)hr9.z
mad.f16 hr7.z, hr28.y, hr27.z, (last)hr7.z
mad.f16 hr5.z, hr28.y, hr27.w, (last)hr5.z
mad.f16 hr9.w, hr28.z, hr27.y, (last)hr9.w
mad.f16 hr7.w, hr28.z, hr27.z, (last)hr7.w
mad.f16 hr5.w, hr28.z, hr27.w, (last)hr5.w
mad.f16 hr4.w, (last)hr26.z, hr28.x, (last)hr22.y
mad.f16 hr5.y, (last)hr27.x, hr28.x, (last)hr22.w
mad.f16 hr5.x, (last)hr26.w, hr28.x, (last)hr22.z
mad.f16 hr4.y, (last)hr29.x, hr28.x, (last)hr24.w
mad.f16 hr4.z, (last)hr26.y, hr28.x, (last)hr22.x
(rpt1)mad.f16 hr3.z, (r)(last)hr28.y, hr28.x, (r)(last)hr24.x
mad.f16 hr4.x, (last)hr28.w, hr28.x, (last)hr24.z
bar.g
(sy)(ss)br p0.x, #l1005
jump #l130
l1005:
(jp)(eolm)nop
(nop3) add.u r10.w, r51.w, (last)r10.w
(nop3) shl.b r10.w, (last)r10.w, 9
(nop3) sad.s32 r10.w, r52.z, r10.w, (last)r1.y
(nop3) shl.b r10.w, (last)r10.w, 2
add.u r14.w, r10.w, c1.x
add.u r15.x, r10.w, c4.w
add.u r15.y, r10.w, c4.z
stib.b.untyped.1d.u16.4.imm.base0 hr18.z, r10.w, 4
add.u r15.z, r10.w, c5.x
add.u r15.w, r10.w, c4.y
(rpt1)add.u r16.x, r10.w, (r)c5.y
(rpt1)add.u r16.z, (r)c8.w, r10.w
(rpt1)add.u r17.x, (r)c9.y, r10.w
(rpt1)add.u r17.z, (r)c9.w, r10.w
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r10.w+64, 4
(ss)add.u r10.w, c10.y, (last)r10.w
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r14.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r15.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r15.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r15.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r15.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r16.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r16.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r16.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r16.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r17.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r17.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r17.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r17.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r10.w, 4
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
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1285 instr, 25 nops, 1260 non-nops, 65 mov, 0 cov, 2112 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 21 full, 12 constlen
; CL prog 23/1: 28 cat0, 65 cat1, 76 cat2, 1028 cat3, 0 cat4, 34 cat5, 50 cat6, 4 cat7
; CL prog 23/1: 30 sstall, 19 (ss), 139 systall, 12 (sy), 1 loops
; CL prog 23/1: 12 max_waves, 0 double_threadsize
; 58 preamble-instr, 1 early-preamble
