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
@const(c10.x)	0x00011800, 0x00011840, 0xd0d0d0d0, 0xd0d0d0d0
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
shl.b r51.w, r51.z, 6
shr.b r0.w, r0.x, 4
and.b r1.x, r0.x, 15
mov.u16u16 hr2.z, 0
mov.u16u16 hr2.w, 0
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
mov.u16u16 hr3.w, 0
mov.u16u16 hr3.z, 0
mov.u16u16 hr3.y, 0
mov.u16u16 hr3.x, 0
l128:
(rpt1)shr.b r52.z, (r)r51.w, 2
shl.b r53.x, r52.y, 9
add.u r9.w, r0.x, 128
shl.b r9.y, r0.w, 7
shl.b r9.z, r1.x, 3
shl.b r10.x, r0.w, 3
shr.b r9.w, (last)r9.w, 4
shl.b r11.y, r0.w, 2
(ss)add.u r10.y, r52.y, r0.w
sad.s32 r12.x, r53.x, r1.x, r52.w
add.u r10.z, r52.y, r9.w
add.u r52.y, r52.y, 16
cmps.u.ge up0.x, r52.y, c1.x
shl.b r9.w, (last)r9.w, 7
shl.b r10.y, (last)r10.y, 9
add.u r9.y, (last)r9.y, r9.z
shl.b r10.z, (last)r10.z, 9
shl.b r12.x, (last)r12.x, 2
sad.s32 r10.y, r52.z, r10.y, r1.x
add.u r9.w, (last)r9.w, (last)r9.z
sad.s32 r10.z, r52.z, r10.z, r1.x
add.u r12.y, r12.x, c1.x
shl.b r10.y, (last)r10.y, 2
add.u r12.z, r12.x, c8.y
shl.b r10.z, (last)r10.z, 2
add.u r12.w, r12.x, c4.z
add.u r13.x, r12.x, c8.x
add.u r13.y, r12.x, c4.y
add.u r13.z, r12.x, c7.w
isam.v.base0 (u16)(xyzw)hr21.z, r10.y, s#0, t#0
add.u r13.w, r12.x, c4.x
add.u r14.x, r12.x, c7.z
isam.v.base0 (u16)(xyzw)hr23.x, r10.z, s#0, t#0
add.u r14.y, r12.x, c3.w
add.u r14.z, r12.x, c7.y
add.u r14.w, r12.x, c3.z
add.u r15.x, r12.x, c7.x
add.u r15.y, r12.x, c3.y
add.u r15.z, r12.x, c6.w
add.u r15.w, r12.x, c3.x
add.u r16.x, r12.x, c6.z
add.u r16.y, r12.x, c2.w
add.u r16.z, r12.x, c6.y
add.u r16.w, r12.x, c2.z
add.u r17.x, r12.x, c6.x
add.u r17.y, r12.x, c2.y
add.u r17.z, r12.x, c5.w
add.u r17.w, r12.x, c2.x
add.u r18.x, r12.x, c5.z
add.u r18.y, r12.x, c1.w
add.u r18.z, r12.x, c5.y
add.u r18.w, r12.x, c1.z
add.u r19.x, r12.x, c5.x
add.u r19.y, r12.x, c1.y
add.u r19.z, r12.x, c4.w
(sy)stl.u16 l[r9.y], r21.z, 4
stl.u16 l[r9.w], r23.x, 4
fence.r.w
(sy)(ss)bar.g
(sy)(ss)nop
isam.v.base0 (u16)(xyzw)hr40.z, r12.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr18.z, r12.x+64, s#0, t#2
isam.v.base0 (u16)(xyzw)hr23.x, r12.y, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr24.x, r12.z, s#0, t#2
(sy)(ss)mad.f16 hr17.z, hr40.z, hr39.z, (last)hr17.z
mad.f16 hr15.z, hr40.z, hr39.w, (last)hr15.z
mad.f16 hr13.z, hr40.z, hr40.x, (last)hr13.z
mad.f16 hr11.z, hr40.z, hr40.y, (last)hr11.z
mad.f16 hr17.w, hr40.w, hr39.z, (last)hr17.w
mad.f16 hr15.w, hr40.w, hr39.w, (last)hr15.w
mad.f16 hr13.w, hr40.w, hr40.x, (last)hr13.w
mad.f16 hr11.w, hr40.w, hr40.y, (last)hr11.w
mad.f16 hr18.x, hr41.x, hr39.z, (last)hr18.x
mad.f16 hr16.x, hr41.x, hr39.w, (last)hr16.x
mad.f16 hr14.x, hr41.x, hr40.x, (last)hr14.x
mad.f16 hr12.x, hr41.x, hr40.y, (last)hr12.x
mad.f16 hr18.y, hr41.y, hr39.z, (last)hr18.y
mad.f16 hr16.y, hr41.y, hr39.w, (last)hr16.y
mad.f16 hr14.y, hr41.y, hr40.x, (last)hr14.y
mad.f16 hr12.y, hr41.y, hr40.y, (last)hr12.y
mad.f16 hr16.z, hr18.z, hr39.z, (last)hr16.z
mad.f16 hr14.z, hr18.z, hr39.w, (last)hr14.z
mad.f16 hr12.z, hr18.z, hr40.x, (last)hr12.z
mad.f16 hr10.z, hr18.z, hr40.y, (last)hr10.z
mad.f16 hr16.w, hr18.w, hr39.z, (last)hr16.w
mad.f16 hr14.w, hr18.w, hr39.w, (last)hr14.w
mad.f16 hr12.w, hr18.w, hr40.x, (last)hr12.w
mad.f16 hr10.w, hr18.w, hr40.y, (last)hr10.w
(rpt1)mad.f16 hr17.x, (r)hr19.x, hr39.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr19.x, hr39.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr19.x, hr40.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr19.x, hr40.y, (r)(last)hr11.x
(rpt1)mad.f16 hr9.z, (r)hr40.z, hr0.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr41.x, hr0.z, (r)(last)hr10.x
(rpt1)mad.f16 hr7.z, (r)hr40.z, hr0.w, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr41.x, hr0.w, (r)(last)hr8.x
(rpt1)mad.f16 hr5.z, (r)hr40.z, hr1.x, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr41.x, hr1.x, (r)(last)hr6.x
mad.f16 hr8.z, hr18.z, hr0.z, (last)hr8.z
mad.f16 hr6.z, hr18.z, hr0.w, (last)hr6.z
mad.f16 hr4.z, hr18.z, hr1.x, (last)hr4.z
mad.f16 hr8.w, hr18.w, hr0.z, (last)hr8.w
mad.f16 hr6.w, hr18.w, hr0.w, (last)hr6.w
mad.f16 hr4.w, hr18.w, hr1.x, (last)hr4.w
(rpt1)mad.f16 hr9.x, (r)hr19.x, hr0.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr19.x, hr0.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr19.x, hr1.x, (r)(last)hr5.x
(rpt1)mad.f16 hr40.z, (r)(last)hr40.z, hr1.y, (r)(last)hr3.z
(rpt1)mad.f16 hr41.x, (r)(last)hr41.x, hr1.y, (r)(last)hr4.x
(rpt1)mad.f16 hr18.z, (r)(last)hr18.z, hr1.y, (r)(last)hr2.z
(rpt1)mad.f16 hr19.x, (r)(last)hr19.x, hr1.y, (r)(last)hr3.x
isam.v.base0 (u16)(xyzw)hr0.z, r12.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr2.z, r13.x, s#0, t#2
mad.f16 hr17.z, hr23.x, hr20.z, (last)hr17.z
mad.f16 hr15.z, hr23.x, hr20.w, (last)hr15.z
mad.f16 hr13.z, hr23.x, hr21.x, (last)hr13.z
mad.f16 hr11.z, hr23.x, hr21.y, (last)hr11.z
mad.f16 hr17.w, hr23.y, hr20.z, (last)hr17.w
mad.f16 hr15.w, hr23.y, hr20.w, (last)hr15.w
mad.f16 hr13.w, hr23.y, hr21.x, (last)hr13.w
mad.f16 hr11.w, hr23.y, hr21.y, (last)hr11.w
mad.f16 hr18.x, hr23.z, hr20.z, (last)hr18.x
mad.f16 hr16.x, hr23.z, hr20.w, (last)hr16.x
mad.f16 hr14.x, hr23.z, hr21.x, (last)hr14.x
mad.f16 hr12.x, hr23.z, hr21.y, (last)hr12.x
mad.f16 hr18.y, hr23.w, hr20.z, (last)hr18.y
mad.f16 hr16.y, hr23.w, hr20.w, (last)hr16.y
mad.f16 hr14.y, hr23.w, hr21.x, (last)hr14.y
mad.f16 hr12.y, hr23.w, hr21.y, (last)hr12.y
mad.f16 hr16.z, hr24.x, hr20.z, (last)hr16.z
mad.f16 hr14.z, hr24.x, hr20.w, (last)hr14.z
mad.f16 hr12.z, hr24.x, hr21.x, (last)hr12.z
mad.f16 hr10.z, hr24.x, hr21.y, (last)hr10.z
mad.f16 hr16.w, hr24.y, hr20.z, (last)hr16.w
mad.f16 hr14.w, hr24.y, hr20.w, (last)hr14.w
mad.f16 hr12.w, hr24.y, hr21.x, (last)hr12.w
mad.f16 hr10.w, hr24.y, hr21.y, (last)hr10.w
(rpt1)mad.f16 hr17.x, (r)hr24.z, hr20.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr24.z, hr20.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr24.z, hr21.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr24.z, hr21.y, (r)(last)hr11.x
isam.v.base0 (u16)(xyzw)hr20.z, r13.y, s#0, t#2
(rpt1)mad.f16 hr9.z, (r)hr23.x, hr21.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr23.z, hr21.z, (r)(last)hr10.x
(rpt1)mad.f16 hr7.z, (r)hr23.x, hr21.w, (r)(last)hr7.z
(rpt1)mad.f16 hr8.x, (r)hr23.z, hr21.w, (r)(last)hr8.x
(rpt1)mad.f16 hr5.z, (r)hr23.x, hr22.x, (r)(last)hr5.z
(rpt1)mad.f16 hr6.x, (r)hr23.z, hr22.x, (r)(last)hr6.x
mad.f16 hr8.z, hr24.x, hr21.z, (last)hr8.z
mad.f16 hr6.z, hr24.x, hr21.w, (last)hr6.z
mad.f16 hr4.z, hr24.x, hr22.x, (last)hr4.z
mad.f16 hr8.w, hr24.y, hr21.z, (last)hr8.w
mad.f16 hr6.w, hr24.y, hr21.w, (last)hr6.w
mad.f16 hr4.w, hr24.y, hr22.x, (last)hr4.w
(rpt1)mad.f16 hr9.x, (r)hr24.z, hr21.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr24.z, hr21.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr24.z, hr22.x, (r)(last)hr5.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr22.y, (r)(last)hr40.z
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr22.y, (r)(last)hr41.x
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr22.y, (r)(last)hr18.z
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr22.y, (r)(last)hr19.x
isam.v.base0 (u16)(xyzw)hr21.z, r13.z, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr25.x, r13.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr26.x, r14.x, s#0, t#2
(sy)mad.f16 hr17.z, hr0.z, hr39.z, (last)hr17.z
mad.f16 hr15.z, hr0.z, hr39.w, (last)hr15.z
mad.f16 hr13.z, hr0.z, hr40.x, (last)hr13.z
mad.f16 hr11.z, hr0.z, hr40.y, (last)hr11.z
mad.f16 hr17.w, hr0.w, hr39.z, (last)hr17.w
mad.f16 hr15.w, hr0.w, hr39.w, (last)hr15.w
mad.f16 hr13.w, hr0.w, hr40.x, (last)hr13.w
mad.f16 hr11.w, hr0.w, hr40.y, (last)hr11.w
mad.f16 hr18.x, hr1.x, hr39.z, (last)hr18.x
mad.f16 hr16.x, hr1.x, hr39.w, (last)hr16.x
mad.f16 hr14.x, hr1.x, hr40.x, (last)hr14.x
mad.f16 hr12.x, hr1.x, hr40.y, (last)hr12.x
mad.f16 hr18.y, hr1.y, hr39.z, (last)hr18.y
mad.f16 hr16.y, hr1.y, hr39.w, (last)hr16.y
mad.f16 hr14.y, hr1.y, hr40.x, (last)hr14.y
mad.f16 hr12.y, hr1.y, hr40.y, (last)hr12.y
mad.f16 hr16.z, hr2.z, hr39.z, (last)hr16.z
mad.f16 hr14.z, hr2.z, hr39.w, (last)hr14.z
mad.f16 hr12.z, hr2.z, hr40.x, (last)hr12.z
mad.f16 hr10.z, hr2.z, hr40.y, (last)hr10.z
mad.f16 hr16.w, hr2.w, hr39.z, (last)hr16.w
mad.f16 hr14.w, hr2.w, hr39.w, (last)hr14.w
mad.f16 hr12.w, hr2.w, hr40.x, (last)hr12.w
mad.f16 hr10.w, hr2.w, hr40.y, (last)hr10.w
(rpt1)mad.f16 hr17.x, (r)hr3.x, hr39.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr3.x, hr39.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr3.x, hr40.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr3.x, hr40.y, (r)(last)hr11.x
mad.f16 hr9.z, hr0.z, hr40.z, (last)hr9.z
mad.f16 hr7.z, hr0.z, hr40.w, (last)hr7.z
mad.f16 hr5.z, hr0.z, hr41.x, (last)hr5.z
mad.f16 hr9.w, hr0.w, hr40.z, (last)hr9.w
mad.f16 hr7.w, hr0.w, hr40.w, (last)hr7.w
mad.f16 hr5.w, hr0.w, hr41.x, (last)hr5.w
mad.f16 hr10.x, hr1.x, hr40.z, (last)hr10.x
mad.f16 hr8.x, hr1.x, hr40.w, (last)hr8.x
mad.f16 hr6.x, hr1.x, hr41.x, (last)hr6.x
mad.f16 hr10.y, hr1.y, hr40.z, (last)hr10.y
mad.f16 hr8.y, hr1.y, hr40.w, (last)hr8.y
mad.f16 hr6.y, hr1.y, hr41.x, (last)hr6.y
mad.f16 hr8.z, hr2.z, hr40.z, (last)hr8.z
mad.f16 hr6.z, hr2.z, hr40.w, (last)hr6.z
mad.f16 hr4.z, hr2.z, hr41.x, (last)hr4.z
mad.f16 hr8.w, hr2.w, hr40.z, (last)hr8.w
mad.f16 hr6.w, hr2.w, hr40.w, (last)hr6.w
mad.f16 hr4.w, hr2.w, hr41.x, (last)hr4.w
(rpt1)mad.f16 hr9.x, (r)hr3.x, hr40.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr3.x, hr40.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr3.x, hr41.x, (r)(last)hr5.x
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr41.y, (r)(last)hr23.x
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr41.y, (r)(last)hr23.z
(rpt1)mad.f16 hr2.z, (r)(last)hr2.z, hr41.y, (r)(last)hr24.x
(rpt1)mad.f16 hr3.x, (r)(last)hr3.x, hr41.y, (r)(last)hr24.z
isam.v.base0 (u16)(xyzw)hr40.z, r14.y, s#0, t#2
mad.f16 hr17.z, hr20.z, hr3.z, (last)hr17.z
mad.f16 hr15.z, hr20.z, hr3.w, (last)hr15.z
mad.f16 hr13.z, hr20.z, hr4.x, (last)hr13.z
mad.f16 hr11.z, hr20.z, hr4.y, (last)hr11.z
mad.f16 hr17.w, hr20.w, hr3.z, (last)hr17.w
mad.f16 hr15.w, hr20.w, hr3.w, (last)hr15.w
mad.f16 hr13.w, hr20.w, hr4.x, (last)hr13.w
mad.f16 hr11.w, hr20.w, hr4.y, (last)hr11.w
mad.f16 hr18.x, hr21.x, hr3.z, (last)hr18.x
mad.f16 hr16.x, hr21.x, hr3.w, (last)hr16.x
mad.f16 hr14.x, hr21.x, hr4.x, (last)hr14.x
mad.f16 hr12.x, hr21.x, hr4.y, (last)hr12.x
mad.f16 hr18.y, hr21.y, hr3.z, (last)hr18.y
mad.f16 hr16.y, hr21.y, hr3.w, (last)hr16.y
mad.f16 hr14.y, hr21.y, hr4.x, (last)hr14.y
mad.f16 hr12.y, hr21.y, hr4.y, (last)hr12.y
mad.f16 hr9.z, hr20.z, hr18.z, (last)hr9.z
mad.f16 hr7.z, hr20.z, hr18.w, (last)hr7.z
mad.f16 hr5.z, hr20.z, hr19.x, (last)hr5.z
mad.f16 hr9.w, hr20.w, hr18.z, (last)hr9.w
mad.f16 hr7.w, hr20.w, hr18.w, (last)hr7.w
mad.f16 hr5.w, hr20.w, hr19.x, (last)hr5.w
mad.f16 hr10.x, hr21.x, hr18.z, (last)hr10.x
mad.f16 hr8.x, hr21.x, hr18.w, (last)hr8.x
mad.f16 hr6.x, hr21.x, hr19.x, (last)hr6.x
mad.f16 hr10.y, hr21.y, hr18.z, (last)hr10.y
mad.f16 hr8.y, hr21.y, hr18.w, (last)hr8.y
mad.f16 hr6.y, hr21.y, hr19.x, (last)hr6.y
(rpt1)mad.f16 hr20.z, (r)(last)hr20.z, hr19.y, (r)(last)hr0.z
(rpt1)mad.f16 hr21.x, (r)(last)hr21.x, hr19.y, (r)(last)hr1.x
isam.v.base0 (u16)(xyzw)hr0.z, r14.z, s#0, t#2
mad.f16 hr16.z, hr21.z, hr3.z, (last)hr16.z
mad.f16 hr14.z, hr21.z, hr3.w, (last)hr14.z
mad.f16 hr12.z, hr21.z, hr4.x, (last)hr12.z
mad.f16 hr10.z, hr21.z, hr4.y, (last)hr10.z
mad.f16 hr16.w, hr21.w, hr3.z, (last)hr16.w
mad.f16 hr14.w, hr21.w, hr3.w, (last)hr14.w
mad.f16 hr12.w, hr21.w, hr4.x, (last)hr12.w
mad.f16 hr10.w, hr21.w, hr4.y, (last)hr10.w
(rpt1)mad.f16 hr17.x, (r)hr22.x, hr3.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr22.x, hr3.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr22.x, hr4.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr22.x, hr4.y, (r)(last)hr11.x
mad.f16 hr8.z, hr21.z, hr18.z, (last)hr8.z
mad.f16 hr6.z, hr21.z, hr18.w, (last)hr6.z
mad.f16 hr4.z, hr21.z, hr19.x, (last)hr4.z
mad.f16 hr8.w, hr21.w, hr18.z, (last)hr8.w
mad.f16 hr6.w, hr21.w, hr18.w, (last)hr6.w
mad.f16 hr4.w, hr21.w, hr19.x, (last)hr4.w
(rpt1)mad.f16 hr9.x, (r)hr22.x, hr18.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr22.x, hr18.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr22.x, hr19.x, (r)(last)hr5.x
(ss)mad.f16 hr17.z, hr25.x, hr23.x, (last)hr17.z
mad.f16 hr15.z, hr25.x, hr23.y, (last)hr15.z
mad.f16 hr13.z, hr25.x, hr23.z, (last)hr13.z
mad.f16 hr11.z, hr25.x, hr23.w, (last)hr11.z
mad.f16 hr17.w, hr25.y, hr23.x, (last)hr17.w
mad.f16 hr15.w, hr25.y, hr23.y, (last)hr15.w
mad.f16 hr13.w, hr25.y, hr23.z, (last)hr13.w
mad.f16 hr11.w, hr25.y, hr23.w, (last)hr11.w
mad.f16 hr18.x, hr25.z, hr23.x, (last)hr18.x
mad.f16 hr16.x, hr25.z, hr23.y, (last)hr16.x
mad.f16 hr14.x, hr25.z, hr23.z, (last)hr14.x
mad.f16 hr12.x, hr25.z, hr23.w, (last)hr12.x
mad.f16 hr18.y, hr25.w, hr23.x, (last)hr18.y
mad.f16 hr16.y, hr25.w, hr23.y, (last)hr16.y
mad.f16 hr14.y, hr25.w, hr23.z, (last)hr14.y
mad.f16 hr12.y, hr25.w, hr23.w, (last)hr12.y
mad.f16 hr9.z, hr25.x, hr24.x, (last)hr9.z
mad.f16 hr7.z, hr25.x, hr24.y, (last)hr7.z
mad.f16 hr5.z, hr25.x, hr24.z, (last)hr5.z
mad.f16 hr9.w, hr25.y, hr24.x, (last)hr9.w
mad.f16 hr7.w, hr25.y, hr24.y, (last)hr7.w
mad.f16 hr5.w, hr25.y, hr24.z, (last)hr5.w
mad.f16 hr10.x, hr25.z, hr24.x, (last)hr10.x
mad.f16 hr8.x, hr25.z, hr24.y, (last)hr8.x
mad.f16 hr6.x, hr25.z, hr24.z, (last)hr6.x
mad.f16 hr10.y, hr25.w, hr24.x, (last)hr10.y
mad.f16 hr8.y, hr25.w, hr24.y, (last)hr8.y
mad.f16 hr6.y, hr25.w, hr24.z, (last)hr6.y
(rpt1)mad.f16 hr21.z, (r)(last)hr21.z, hr19.y, (r)(last)hr2.z
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr19.y, (r)(last)hr3.x
isam.v.base0 (u16)(xyzw)hr18.z, r14.w, s#0, t#2
(rpt1)mad.f16 hr25.x, (r)(last)hr25.x, hr24.w, (r)(last)hr20.z
(rpt1)mad.f16 hr25.z, (r)(last)hr25.z, hr24.w, (r)(last)hr21.x
isam.v.base0 (u16)(xyzw)hr20.z, r15.x, s#0, t#2
mad.f16 hr16.z, hr26.x, hr23.x, (last)hr16.z
mad.f16 hr14.z, hr26.x, hr23.y, (last)hr14.z
mad.f16 hr12.z, hr26.x, hr23.z, (last)hr12.z
mad.f16 hr10.z, hr26.x, hr23.w, (last)hr10.z
mad.f16 hr16.w, hr26.y, hr23.x, (last)hr16.w
mad.f16 hr14.w, hr26.y, hr23.y, (last)hr14.w
mad.f16 hr12.w, hr26.y, hr23.z, (last)hr12.w
mad.f16 hr10.w, hr26.y, hr23.w, (last)hr10.w
(rpt1)mad.f16 hr17.x, (r)hr26.z, hr23.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr26.z, hr23.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr26.z, hr23.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr26.z, hr23.w, (r)(last)hr11.x
mad.f16 hr8.z, hr26.x, hr24.x, (last)hr8.z
mad.f16 hr6.z, hr26.x, hr24.y, (last)hr6.z
mad.f16 hr4.z, hr26.x, hr24.z, (last)hr4.z
mad.f16 hr8.w, hr26.y, hr24.x, (last)hr8.w
mad.f16 hr6.w, hr26.y, hr24.y, (last)hr6.w
mad.f16 hr4.w, hr26.y, hr24.z, (last)hr4.w
(rpt1)mad.f16 hr9.x, (r)hr26.z, hr24.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr26.z, hr24.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr26.z, hr24.z, (r)(last)hr5.x
(rpt1)mad.f16 hr26.x, (r)(last)hr26.x, hr24.w, (r)(last)hr21.z
(rpt1)mad.f16 hr26.z, (r)(last)hr26.z, hr24.w, (r)(last)hr22.x
isam.v.base0 (u16)(xyzw)hr24.x, r15.y, s#0, t#2
(sy)mad.f16 hr17.z, hr40.z, hr27.x, (last)hr17.z
mad.f16 hr15.z, hr40.z, hr27.y, (last)hr15.z
mad.f16 hr13.z, hr40.z, hr27.z, (last)hr13.z
mad.f16 hr11.z, hr40.z, hr27.w, (last)hr11.z
mad.f16 hr17.w, hr40.w, hr27.x, (last)hr17.w
mad.f16 hr15.w, hr40.w, hr27.y, (last)hr15.w
mad.f16 hr13.w, hr40.w, hr27.z, (last)hr13.w
mad.f16 hr11.w, hr40.w, hr27.w, (last)hr11.w
mad.f16 hr18.x, hr41.x, hr27.x, (last)hr18.x
mad.f16 hr16.x, hr41.x, hr27.y, (last)hr16.x
mad.f16 hr14.x, hr41.x, hr27.z, (last)hr14.x
mad.f16 hr12.x, hr41.x, hr27.w, (last)hr12.x
mad.f16 hr18.y, hr41.y, hr27.x, (last)hr18.y
mad.f16 hr16.y, hr41.y, hr27.y, (last)hr16.y
mad.f16 hr14.y, hr41.y, hr27.z, (last)hr14.y
mad.f16 hr12.y, hr41.y, hr27.w, (last)hr12.y
mad.f16 hr9.z, hr40.z, hr39.z, (last)hr9.z
mad.f16 hr7.z, hr40.z, hr39.w, (last)hr7.z
mad.f16 hr5.z, hr40.z, hr40.x, (last)hr5.z
mad.f16 hr9.w, hr40.w, hr39.z, (last)hr9.w
mad.f16 hr7.w, hr40.w, hr39.w, (last)hr7.w
mad.f16 hr5.w, hr40.w, hr40.x, (last)hr5.w
mad.f16 hr10.x, hr41.x, hr39.z, (last)hr10.x
mad.f16 hr8.x, hr41.x, hr39.w, (last)hr8.x
mad.f16 hr6.x, hr41.x, hr40.x, (last)hr6.x
mad.f16 hr10.y, hr41.y, hr39.z, (last)hr10.y
mad.f16 hr8.y, hr41.y, hr39.w, (last)hr8.y
mad.f16 hr6.y, hr41.y, hr40.x, (last)hr6.y
(rpt1)mad.f16 hr40.z, (r)(last)hr40.z, hr40.y, (r)(last)hr25.x
(rpt1)mad.f16 hr41.x, (r)(last)hr41.x, hr40.y, (r)(last)hr25.z
isam.v.base0 (u16)(xyzw)hr25.x, r15.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr28.x, r15.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr29.x, r16.x, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr32.x, r16.y, s#0, t#2
mad.f16 hr16.z, hr0.z, hr27.x, (last)hr16.z
mad.f16 hr14.z, hr0.z, hr27.y, (last)hr14.z
mad.f16 hr12.z, hr0.z, hr27.z, (last)hr12.z
mad.f16 hr10.z, hr0.z, hr27.w, (last)hr10.z
mad.f16 hr16.w, hr0.w, hr27.x, (last)hr16.w
mad.f16 hr14.w, hr0.w, hr27.y, (last)hr14.w
mad.f16 hr12.w, hr0.w, hr27.z, (last)hr12.w
mad.f16 hr10.w, hr0.w, hr27.w, (last)hr10.w
(rpt1)mad.f16 hr17.x, (r)hr1.x, hr27.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr1.x, hr27.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr1.x, hr27.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr1.x, hr27.w, (r)(last)hr11.x
mad.f16 hr8.z, hr0.z, hr39.z, (last)hr8.z
mad.f16 hr6.z, hr0.z, hr39.w, (last)hr6.z
mad.f16 hr4.z, hr0.z, hr40.x, (last)hr4.z
mad.f16 hr8.w, hr0.w, hr39.z, (last)hr8.w
mad.f16 hr6.w, hr0.w, hr39.w, (last)hr6.w
mad.f16 hr4.w, hr0.w, hr40.x, (last)hr4.w
(rpt1)mad.f16 hr9.x, (r)hr1.x, hr39.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr1.x, hr39.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr1.x, hr40.x, (r)(last)hr5.x
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr40.y, (r)(last)hr26.x
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr40.y, (r)(last)hr26.z
isam.v.base0 (u16)(xyzw)hr39.z, r16.z, s#0, t#2
mad.f16 hr17.z, hr18.z, hr2.z, (last)hr17.z
mad.f16 hr15.z, hr18.z, hr2.w, (last)hr15.z
mad.f16 hr13.z, hr18.z, hr3.x, (last)hr13.z
mad.f16 hr11.z, hr18.z, hr3.y, (last)hr11.z
mad.f16 hr17.w, hr18.w, hr2.z, (last)hr17.w
mad.f16 hr15.w, hr18.w, hr2.w, (last)hr15.w
mad.f16 hr13.w, hr18.w, hr3.x, (last)hr13.w
mad.f16 hr11.w, hr18.w, hr3.y, (last)hr11.w
mad.f16 hr18.x, hr19.x, hr2.z, (last)hr18.x
mad.f16 hr16.x, hr19.x, hr2.w, (last)hr16.x
mad.f16 hr14.x, hr19.x, hr3.x, (last)hr14.x
mad.f16 hr12.x, hr19.x, hr3.y, (last)hr12.x
mad.f16 hr18.y, hr19.y, hr2.z, (last)hr18.y
mad.f16 hr16.y, hr19.y, hr2.w, (last)hr16.y
mad.f16 hr14.y, hr19.y, hr3.x, (last)hr14.y
mad.f16 hr12.y, hr19.y, hr3.y, (last)hr12.y
mad.f16 hr16.z, hr20.z, hr2.z, (last)hr16.z
mad.f16 hr14.z, hr20.z, hr2.w, (last)hr14.z
mad.f16 hr12.z, hr20.z, hr3.x, (last)hr12.z
mad.f16 hr10.z, hr20.z, hr3.y, (last)hr10.z
mad.f16 hr16.w, hr20.w, hr2.z, (last)hr16.w
mad.f16 hr14.w, hr20.w, hr2.w, (last)hr14.w
mad.f16 hr12.w, hr20.w, hr3.x, (last)hr12.w
mad.f16 hr10.w, hr20.w, hr3.y, (last)hr10.w
(rpt1)mad.f16 hr17.x, (r)hr21.x, hr2.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr21.x, hr2.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr21.x, hr3.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr21.x, hr3.y, (r)(last)hr11.x
isam.v.base0 (u16)(xyzw)hr2.z, r16.w, s#0, t#2
mad.f16 hr9.z, hr18.z, hr3.z, (last)hr9.z
mad.f16 hr7.z, hr18.z, hr3.w, (last)hr7.z
mad.f16 hr5.z, hr18.z, hr4.x, (last)hr5.z
mad.f16 hr9.w, hr18.w, hr3.z, (last)hr9.w
mad.f16 hr7.w, hr18.w, hr3.w, (last)hr7.w
mad.f16 hr5.w, hr18.w, hr4.x, (last)hr5.w
mad.f16 hr10.x, hr19.x, hr3.z, (last)hr10.x
mad.f16 hr8.x, hr19.x, hr3.w, (last)hr8.x
mad.f16 hr6.x, hr19.x, hr4.x, (last)hr6.x
mad.f16 hr10.y, hr19.y, hr3.z, (last)hr10.y
mad.f16 hr8.y, hr19.y, hr3.w, (last)hr8.y
mad.f16 hr6.y, hr19.y, hr4.x, (last)hr6.y
mad.f16 hr8.z, hr20.z, hr3.z, (last)hr8.z
mad.f16 hr6.z, hr20.z, hr3.w, (last)hr6.z
mad.f16 hr4.z, hr20.z, hr4.x, (last)hr4.z
mad.f16 hr8.w, hr20.w, hr3.z, (last)hr8.w
mad.f16 hr6.w, hr20.w, hr3.w, (last)hr6.w
mad.f16 hr4.w, hr20.w, hr4.x, (last)hr4.w
(rpt1)mad.f16 hr9.x, (r)hr21.x, hr3.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr21.x, hr3.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr21.x, hr4.x, (r)(last)hr5.x
(rpt1)mad.f16 hr18.z, (r)(last)hr18.z, hr4.y, (r)(last)hr40.z
(rpt1)mad.f16 hr19.x, (r)(last)hr19.x, hr4.y, (r)(last)hr41.x
(rpt1)mad.f16 hr20.z, (r)(last)hr20.z, hr4.y, (r)(last)hr0.z
(rpt1)mad.f16 hr21.x, (r)(last)hr21.x, hr4.y, (r)(last)hr1.x
isam.v.base0 (u16)(xyzw)hr3.z, r17.x, s#0, t#2
mad.f16 hr17.z, hr24.x, hr21.z, (last)hr17.z
mad.f16 hr15.z, hr24.x, hr21.w, (last)hr15.z
mad.f16 hr13.z, hr24.x, hr22.x, (last)hr13.z
mad.f16 hr11.z, hr24.x, hr22.y, (last)hr11.z
mad.f16 hr17.w, hr24.y, hr21.z, (last)hr17.w
mad.f16 hr15.w, hr24.y, hr21.w, (last)hr15.w
mad.f16 hr13.w, hr24.y, hr22.x, (last)hr13.w
mad.f16 hr11.w, hr24.y, hr22.y, (last)hr11.w
mad.f16 hr18.x, hr24.z, hr21.z, (last)hr18.x
mad.f16 hr16.x, hr24.z, hr21.w, (last)hr16.x
mad.f16 hr14.x, hr24.z, hr22.x, (last)hr14.x
mad.f16 hr12.x, hr24.z, hr22.y, (last)hr12.x
mad.f16 hr18.y, hr24.w, hr21.z, (last)hr18.y
mad.f16 hr16.y, hr24.w, hr21.w, (last)hr16.y
mad.f16 hr14.y, hr24.w, hr22.x, (last)hr14.y
mad.f16 hr12.y, hr24.w, hr22.y, (last)hr12.y
mad.f16 hr9.z, hr24.x, hr23.x, (last)hr9.z
mad.f16 hr7.z, hr24.x, hr23.y, (last)hr7.z
mad.f16 hr5.z, hr24.x, hr23.z, (last)hr5.z
mad.f16 hr9.w, hr24.y, hr23.x, (last)hr9.w
mad.f16 hr7.w, hr24.y, hr23.y, (last)hr7.w
mad.f16 hr5.w, hr24.y, hr23.z, (last)hr5.w
mad.f16 hr10.x, hr24.z, hr23.x, (last)hr10.x
mad.f16 hr8.x, hr24.z, hr23.y, (last)hr8.x
mad.f16 hr6.x, hr24.z, hr23.z, (last)hr6.x
mad.f16 hr10.y, hr24.w, hr23.x, (last)hr10.y
mad.f16 hr8.y, hr24.w, hr23.y, (last)hr8.y
mad.f16 hr6.y, hr24.w, hr23.z, (last)hr6.y
(rpt1)mad.f16 hr24.x, (r)(last)hr24.x, hr23.w, (r)(last)hr18.z
(rpt1)mad.f16 hr24.z, (r)(last)hr24.z, hr23.w, (r)(last)hr19.x
(sy)mad.f16 hr16.z, hr25.x, hr21.z, (last)hr16.z
mad.f16 hr14.z, hr25.x, hr21.w, (last)hr14.z
mad.f16 hr12.z, hr25.x, hr22.x, (last)hr12.z
mad.f16 hr10.z, hr25.x, hr22.y, (last)hr10.z
mad.f16 hr16.w, hr25.y, hr21.z, (last)hr16.w
mad.f16 hr14.w, hr25.y, hr21.w, (last)hr14.w
mad.f16 hr12.w, hr25.y, hr22.x, (last)hr12.w
mad.f16 hr10.w, hr25.y, hr22.y, (last)hr10.w
(rpt1)mad.f16 hr17.x, (r)hr25.z, hr21.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr25.z, hr21.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr25.z, hr22.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr25.z, hr22.y, (r)(last)hr11.x
isam.v.base0 (u16)(xyzw)hr21.z, r17.y, s#0, t#2
mad.f16 hr8.z, hr25.x, hr23.x, (last)hr8.z
mad.f16 hr6.z, hr25.x, hr23.y, (last)hr6.z
mad.f16 hr4.z, hr25.x, hr23.z, (last)hr4.z
mad.f16 hr8.w, hr25.y, hr23.x, (last)hr8.w
mad.f16 hr6.w, hr25.y, hr23.y, (last)hr6.w
mad.f16 hr4.w, hr25.y, hr23.z, (last)hr4.w
(rpt1)mad.f16 hr9.x, (r)hr25.z, hr23.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr25.z, hr23.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr25.z, hr23.z, (r)(last)hr5.x
(rpt1)mad.f16 hr25.x, (r)(last)hr25.x, hr23.w, (r)(last)hr20.z
(rpt1)mad.f16 hr25.z, (r)(last)hr25.z, hr23.w, (r)(last)hr21.x
isam.v.base0 (u16)(xyzw)hr23.x, r17.z, s#0, t#2
(ss)mad.f16 hr17.z, hr28.x, hr26.x, (last)hr17.z
mad.f16 hr15.z, hr28.x, hr26.y, (last)hr15.z
mad.f16 hr13.z, hr28.x, hr26.z, (last)hr13.z
mad.f16 hr11.z, hr28.x, hr26.w, (last)hr11.z
mad.f16 hr17.w, hr28.y, hr26.x, (last)hr17.w
mad.f16 hr15.w, hr28.y, hr26.y, (last)hr15.w
mad.f16 hr13.w, hr28.y, hr26.z, (last)hr13.w
mad.f16 hr11.w, hr28.y, hr26.w, (last)hr11.w
mad.f16 hr18.x, hr28.z, hr26.x, (last)hr18.x
mad.f16 hr16.x, hr28.z, hr26.y, (last)hr16.x
mad.f16 hr14.x, hr28.z, hr26.z, (last)hr14.x
mad.f16 hr12.x, hr28.z, hr26.w, (last)hr12.x
mad.f16 hr18.y, hr28.w, hr26.x, (last)hr18.y
mad.f16 hr16.y, hr28.w, hr26.y, (last)hr16.y
mad.f16 hr14.y, hr28.w, hr26.z, (last)hr14.y
mad.f16 hr12.y, hr28.w, hr26.w, (last)hr12.y
mad.f16 hr9.z, hr28.x, hr27.x, (last)hr9.z
mad.f16 hr7.z, hr28.x, hr27.y, (last)hr7.z
mad.f16 hr5.z, hr28.x, hr27.z, (last)hr5.z
mad.f16 hr9.w, hr28.y, hr27.x, (last)hr9.w
mad.f16 hr7.w, hr28.y, hr27.y, (last)hr7.w
mad.f16 hr5.w, hr28.y, hr27.z, (last)hr5.w
mad.f16 hr10.x, hr28.z, hr27.x, (last)hr10.x
mad.f16 hr8.x, hr28.z, hr27.y, (last)hr8.x
mad.f16 hr6.x, hr28.z, hr27.z, (last)hr6.x
mad.f16 hr10.y, hr28.w, hr27.x, (last)hr10.y
mad.f16 hr8.y, hr28.w, hr27.y, (last)hr8.y
mad.f16 hr6.y, hr28.w, hr27.z, (last)hr6.y
mad.f16 hr16.z, hr29.x, hr26.x, (last)hr16.z
mad.f16 hr14.z, hr29.x, hr26.y, (last)hr14.z
mad.f16 hr12.z, hr29.x, hr26.z, (last)hr12.z
mad.f16 hr10.z, hr29.x, hr26.w, (last)hr10.z
mad.f16 hr16.w, hr29.y, hr26.x, (last)hr16.w
mad.f16 hr14.w, hr29.y, hr26.y, (last)hr14.w
mad.f16 hr12.w, hr29.y, hr26.z, (last)hr12.w
mad.f16 hr10.w, hr29.y, hr26.w, (last)hr10.w
(rpt1)mad.f16 hr17.x, (r)hr29.z, hr26.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr29.z, hr26.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr29.z, hr26.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr29.z, hr26.w, (r)(last)hr11.x
isam.v.base0 (u16)(xyzw)hr26.x, r17.w, s#0, t#2
mad.f16 hr8.z, hr29.x, hr27.x, (last)hr8.z
mad.f16 hr6.z, hr29.x, hr27.y, (last)hr6.z
mad.f16 hr4.z, hr29.x, hr27.z, (last)hr4.z
mad.f16 hr8.w, hr29.y, hr27.x, (last)hr8.w
mad.f16 hr6.w, hr29.y, hr27.y, (last)hr6.w
mad.f16 hr4.w, hr29.y, hr27.z, (last)hr4.w
(rpt1)mad.f16 hr9.x, (r)hr29.z, hr27.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr29.z, hr27.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr29.z, hr27.z, (r)(last)hr5.x
(rpt1)mad.f16 hr28.x, (r)(last)hr28.x, hr27.w, (r)(last)hr24.x
(rpt1)mad.f16 hr28.z, (r)(last)hr28.z, hr27.w, (r)(last)hr24.z
(rpt1)mad.f16 hr29.x, (r)(last)hr29.x, hr27.w, (r)(last)hr25.x
(rpt1)mad.f16 hr29.z, (r)(last)hr29.z, hr27.w, (r)(last)hr25.z
isam.v.base0 (u16)(xyzw)hr27.x, r18.x, s#0, t#2
mad.f16 hr17.z, hr32.x, hr30.x, (last)hr17.z
mad.f16 hr15.z, hr32.x, hr30.y, (last)hr15.z
mad.f16 hr13.z, hr32.x, hr30.z, (last)hr13.z
mad.f16 hr11.z, hr32.x, hr30.w, (last)hr11.z
mad.f16 hr17.w, hr32.y, hr30.x, (last)hr17.w
mad.f16 hr15.w, hr32.y, hr30.y, (last)hr15.w
mad.f16 hr13.w, hr32.y, hr30.z, (last)hr13.w
mad.f16 hr11.w, hr32.y, hr30.w, (last)hr11.w
mad.f16 hr18.x, hr32.z, hr30.x, (last)hr18.x
mad.f16 hr16.x, hr32.z, hr30.y, (last)hr16.x
mad.f16 hr14.x, hr32.z, hr30.z, (last)hr14.x
mad.f16 hr12.x, hr32.z, hr30.w, (last)hr12.x
mad.f16 hr18.y, hr32.w, hr30.x, (last)hr18.y
mad.f16 hr16.y, hr32.w, hr30.y, (last)hr16.y
mad.f16 hr14.y, hr32.w, hr30.z, (last)hr14.y
mad.f16 hr12.y, hr32.w, hr30.w, (last)hr12.y
mad.f16 hr9.z, hr32.x, hr31.x, (last)hr9.z
mad.f16 hr7.z, hr32.x, hr31.y, (last)hr7.z
mad.f16 hr5.z, hr32.x, hr31.z, (last)hr5.z
mad.f16 hr9.w, hr32.y, hr31.x, (last)hr9.w
mad.f16 hr7.w, hr32.y, hr31.y, (last)hr7.w
mad.f16 hr5.w, hr32.y, hr31.z, (last)hr5.w
mad.f16 hr10.x, hr32.z, hr31.x, (last)hr10.x
mad.f16 hr8.x, hr32.z, hr31.y, (last)hr8.x
mad.f16 hr6.x, hr32.z, hr31.z, (last)hr6.x
mad.f16 hr10.y, hr32.w, hr31.x, (last)hr10.y
mad.f16 hr8.y, hr32.w, hr31.y, (last)hr8.y
mad.f16 hr6.y, hr32.w, hr31.z, (last)hr6.y
mad.f16 hr16.z, hr39.z, hr30.x, (last)hr16.z
mad.f16 hr14.z, hr39.z, hr30.y, (last)hr14.z
mad.f16 hr12.z, hr39.z, hr30.z, (last)hr12.z
mad.f16 hr10.z, hr39.z, hr30.w, (last)hr10.z
mad.f16 hr16.w, hr39.w, hr30.x, (last)hr16.w
mad.f16 hr14.w, hr39.w, hr30.y, (last)hr14.w
mad.f16 hr12.w, hr39.w, hr30.z, (last)hr12.w
mad.f16 hr10.w, hr39.w, hr30.w, (last)hr10.w
(rpt1)mad.f16 hr17.x, (r)hr40.x, hr30.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr40.x, hr30.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr40.x, hr30.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr40.x, hr30.w, (r)(last)hr11.x
isam.v.base0 (u16)(xyzw)hr30.x, r18.y, s#0, t#2
mad.f16 hr8.z, hr39.z, hr31.x, (last)hr8.z
mad.f16 hr6.z, hr39.z, hr31.y, (last)hr6.z
mad.f16 hr4.z, hr39.z, hr31.z, (last)hr4.z
mad.f16 hr8.w, hr39.w, hr31.x, (last)hr8.w
mad.f16 hr6.w, hr39.w, hr31.y, (last)hr6.w
mad.f16 hr4.w, hr39.w, hr31.z, (last)hr4.w
(rpt1)mad.f16 hr9.x, (r)hr40.x, hr31.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr40.x, hr31.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr40.x, hr31.z, (r)(last)hr5.x
(rpt1)mad.f16 hr32.x, (r)(last)hr32.x, hr31.w, (r)(last)hr28.x
(rpt1)mad.f16 hr32.z, (r)(last)hr32.z, hr31.w, (r)(last)hr28.z
(rpt1)mad.f16 hr39.z, (r)(last)hr39.z, hr31.w, (r)(last)hr29.x
(rpt1)mad.f16 hr40.x, (r)(last)hr40.x, hr31.w, (r)(last)hr29.z
isam.v.base0 (u16)(xyzw)hr31.x, r18.z, s#0, t#2
isam.v.base0 (u16)(xyzw)hr34.x, r18.w, s#0, t#2
mad.f16 hr17.z, hr2.z, hr40.z, (last)hr17.z
mad.f16 hr15.z, hr2.z, hr40.w, (last)hr15.z
mad.f16 hr13.z, hr2.z, hr41.x, (last)hr13.z
mad.f16 hr11.z, hr2.z, hr41.y, (last)hr11.z
mad.f16 hr17.w, hr2.w, hr40.z, (last)hr17.w
mad.f16 hr15.w, hr2.w, hr40.w, (last)hr15.w
mad.f16 hr13.w, hr2.w, hr41.x, (last)hr13.w
mad.f16 hr11.w, hr2.w, hr41.y, (last)hr11.w
mad.f16 hr18.x, hr3.x, hr40.z, (last)hr18.x
(ss)nop
isam.v.base0 (u16)(xyzw)hr35.x, r19.x, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr38.x, r19.y, s#0, t#2
mad.f16 hr16.x, hr3.x, hr40.w, (last)hr16.x
mad.f16 hr14.x, hr3.x, hr41.x, (last)hr14.x
mad.f16 hr12.x, hr3.x, hr41.y, (last)hr12.x
mad.f16 hr18.y, hr3.y, hr40.z, (last)hr18.y
mad.f16 hr16.y, hr3.y, hr40.w, (last)hr16.y
mad.f16 hr14.y, hr3.y, hr41.x, (last)hr14.y
mad.f16 hr12.y, hr3.y, hr41.y, (last)hr12.y
mad.f16 hr9.z, hr2.z, hr0.z, (last)hr9.z
mad.f16 hr7.z, hr2.z, hr0.w, (last)hr7.z
mad.f16 hr5.z, hr2.z, hr1.x, (last)hr5.z
mad.f16 hr9.w, hr2.w, hr0.z, (last)hr9.w
mad.f16 hr7.w, hr2.w, hr0.w, (last)hr7.w
mad.f16 hr5.w, hr2.w, hr1.x, (last)hr5.w
mad.f16 hr10.x, hr3.x, hr0.z, (last)hr10.x
mad.f16 hr8.x, hr3.x, hr0.w, (last)hr8.x
mad.f16 hr6.x, hr3.x, hr1.x, (last)hr6.x
mad.f16 hr10.y, hr3.y, hr0.z, (last)hr10.y
mad.f16 hr8.y, hr3.y, hr0.w, (last)hr8.y
mad.f16 hr6.y, hr3.y, hr1.x, (last)hr6.y
(rpt1)mad.f16 hr2.z, (r)(last)hr2.z, hr1.y, (r)(last)hr32.x
(rpt1)mad.f16 hr3.x, (r)(last)hr3.x, hr1.y, (r)(last)hr32.z
mad.f16 hr16.z, hr3.z, hr40.z, (last)hr16.z
mad.f16 hr14.z, hr3.z, hr40.w, (last)hr14.z
mad.f16 hr12.z, hr3.z, hr41.x, (last)hr12.z
mad.f16 hr10.z, hr3.z, hr41.y, (last)hr10.z
mad.f16 hr16.w, hr3.w, hr40.z, (last)hr16.w
mad.f16 hr14.w, hr3.w, hr40.w, (last)hr14.w
mad.f16 hr12.w, hr3.w, hr41.x, (last)hr12.w
mad.f16 hr10.w, hr3.w, hr41.y, (last)hr10.w
mad.f16 hr8.z, hr3.z, hr0.z, (last)hr8.z
mad.f16 hr6.z, hr3.z, hr0.w, (last)hr6.z
mad.f16 hr4.z, hr3.z, hr1.x, (last)hr4.z
mad.f16 hr8.w, hr3.w, hr0.z, (last)hr8.w
mad.f16 hr6.w, hr3.w, hr0.w, (last)hr6.w
mad.f16 hr4.w, hr3.w, hr1.x, (last)hr4.w
(rpt1)mad.f16 hr3.z, (r)(last)hr3.z, hr1.y, (r)(last)hr39.z
isam.v.base0 (u16)(xyzw)hr39.x, r19.z, s#0, t#2
(rpt1)mad.f16 hr17.x, (r)hr4.x, hr40.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr4.x, hr40.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr4.x, hr41.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr4.x, hr41.y, (r)(last)hr11.x
(rpt1)mad.f16 hr9.x, (r)hr4.x, hr0.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr4.x, hr0.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr4.x, hr1.x, (r)(last)hr5.x
(rpt1)mad.f16 hr4.x, (r)(last)hr4.x, hr1.y, (r)(last)hr40.x
fence.r.w
(sy)(ss)mad.f16 hr17.z, hr21.z, hr18.z, (last)hr17.z
mad.f16 hr15.z, hr21.z, hr18.w, (last)hr15.z
mad.f16 hr13.z, hr21.z, hr19.x, (last)hr13.z
mad.f16 hr11.z, hr21.z, hr19.y, (last)hr11.z
mad.f16 hr17.w, hr21.w, hr18.z, (last)hr17.w
mad.f16 hr15.w, hr21.w, hr18.w, (last)hr15.w
mad.f16 hr13.w, hr21.w, hr19.x, (last)hr13.w
mad.f16 hr11.w, hr21.w, hr19.y, (last)hr11.w
mad.f16 hr18.x, hr22.x, hr18.z, (last)hr18.x
mad.f16 hr16.x, hr22.x, hr18.w, (last)hr16.x
mad.f16 hr14.x, hr22.x, hr19.x, (last)hr14.x
mad.f16 hr12.x, hr22.x, hr19.y, (last)hr12.x
mad.f16 hr18.y, hr22.y, hr18.z, (last)hr18.y
mad.f16 hr16.y, hr22.y, hr18.w, (last)hr16.y
mad.f16 hr14.y, hr22.y, hr19.x, (last)hr14.y
mad.f16 hr12.y, hr22.y, hr19.y, (last)hr12.y
mad.f16 hr9.z, hr21.z, hr20.z, (last)hr9.z
mad.f16 hr7.z, hr21.z, hr20.w, (last)hr7.z
mad.f16 hr5.z, hr21.z, hr21.x, (last)hr5.z
mad.f16 hr9.w, hr21.w, hr20.z, (last)hr9.w
mad.f16 hr7.w, hr21.w, hr20.w, (last)hr7.w
mad.f16 hr5.w, hr21.w, hr21.x, (last)hr5.w
mad.f16 hr10.x, hr22.x, hr20.z, (last)hr10.x
mad.f16 hr8.x, hr22.x, hr20.w, (last)hr8.x
mad.f16 hr6.x, hr22.x, hr21.x, (last)hr6.x
mad.f16 hr10.y, hr22.y, hr20.z, (last)hr10.y
mad.f16 hr8.y, hr22.y, hr20.w, (last)hr8.y
mad.f16 hr6.y, hr22.y, hr21.x, (last)hr6.y
mad.f16 hr16.z, hr23.x, hr18.z, (last)hr16.z
mad.f16 hr14.z, hr23.x, hr18.w, (last)hr14.z
mad.f16 hr12.z, hr23.x, hr19.x, (last)hr12.z
mad.f16 hr10.z, hr23.x, hr19.y, (last)hr10.z
mad.f16 hr16.w, hr23.y, hr18.z, (last)hr16.w
mad.f16 hr14.w, hr23.y, hr18.w, (last)hr14.w
mad.f16 hr12.w, hr23.y, hr19.x, (last)hr12.w
mad.f16 hr10.w, hr23.y, hr19.y, (last)hr10.w
mad.f16 hr8.z, hr23.x, hr20.z, (last)hr8.z
mad.f16 hr6.z, hr23.x, hr20.w, (last)hr6.z
mad.f16 hr4.z, hr23.x, hr21.x, (last)hr4.z
mad.f16 hr8.w, hr23.y, hr20.z, (last)hr8.w
mad.f16 hr6.w, hr23.y, hr20.w, (last)hr6.w
mad.f16 hr4.w, hr23.y, hr21.x, (last)hr4.w
(rpt1)mad.f16 hr17.x, (r)hr23.z, hr18.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr23.z, hr18.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr23.z, hr19.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr23.z, hr19.y, (r)(last)hr11.x
(rpt1)mad.f16 hr9.x, (r)hr23.z, hr20.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr23.z, hr20.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr23.z, hr21.x, (r)(last)hr5.x
(rpt1)mad.f16 hr21.z, (r)(last)hr21.z, hr21.y, (r)(last)hr2.z
(rpt1)mad.f16 hr22.x, (r)(last)hr22.x, hr21.y, (r)(last)hr3.x
(rpt1)mad.f16 hr23.x, (r)(last)hr23.x, hr21.y, (r)(last)hr3.z
(rpt1)mad.f16 hr23.z, (r)(last)hr23.z, hr21.y, (r)(last)hr4.x
mad.f16 hr17.z, hr26.x, hr24.x, (last)hr17.z
mad.f16 hr15.z, hr26.x, hr24.y, (last)hr15.z
mad.f16 hr13.z, hr26.x, hr24.z, (last)hr13.z
mad.f16 hr11.z, hr26.x, hr24.w, (last)hr11.z
mad.f16 hr17.w, hr26.y, hr24.x, (last)hr17.w
mad.f16 hr15.w, hr26.y, hr24.y, (last)hr15.w
mad.f16 hr13.w, hr26.y, hr24.z, (last)hr13.w
mad.f16 hr11.w, hr26.y, hr24.w, (last)hr11.w
mad.f16 hr18.x, hr26.z, hr24.x, (last)hr18.x
mad.f16 hr16.x, hr26.z, hr24.y, (last)hr16.x
mad.f16 hr14.x, hr26.z, hr24.z, (last)hr14.x
mad.f16 hr12.x, hr26.z, hr24.w, (last)hr12.x
mad.f16 hr18.y, hr26.w, hr24.x, (last)hr18.y
mad.f16 hr16.y, hr26.w, hr24.y, (last)hr16.y
mad.f16 hr14.y, hr26.w, hr24.z, (last)hr14.y
mad.f16 hr12.y, hr26.w, hr24.w, (last)hr12.y
mad.f16 hr9.z, hr26.x, hr25.x, (last)hr9.z
mad.f16 hr7.z, hr26.x, hr25.y, (last)hr7.z
mad.f16 hr5.z, hr26.x, hr25.z, (last)hr5.z
mad.f16 hr9.w, hr26.y, hr25.x, (last)hr9.w
mad.f16 hr7.w, hr26.y, hr25.y, (last)hr7.w
mad.f16 hr5.w, hr26.y, hr25.z, (last)hr5.w
mad.f16 hr10.x, hr26.z, hr25.x, (last)hr10.x
mad.f16 hr8.x, hr26.z, hr25.y, (last)hr8.x
mad.f16 hr6.x, hr26.z, hr25.z, (last)hr6.x
mad.f16 hr10.y, hr26.w, hr25.x, (last)hr10.y
mad.f16 hr8.y, hr26.w, hr25.y, (last)hr8.y
mad.f16 hr6.y, hr26.w, hr25.z, (last)hr6.y
mad.f16 hr16.z, hr27.x, hr24.x, (last)hr16.z
mad.f16 hr14.z, hr27.x, hr24.y, (last)hr14.z
mad.f16 hr12.z, hr27.x, hr24.z, (last)hr12.z
mad.f16 hr10.z, hr27.x, hr24.w, (last)hr10.z
mad.f16 hr16.w, hr27.y, hr24.x, (last)hr16.w
mad.f16 hr14.w, hr27.y, hr24.y, (last)hr14.w
mad.f16 hr12.w, hr27.y, hr24.z, (last)hr12.w
mad.f16 hr10.w, hr27.y, hr24.w, (last)hr10.w
mad.f16 hr8.z, hr27.x, hr25.x, (last)hr8.z
mad.f16 hr6.z, hr27.x, hr25.y, (last)hr6.z
mad.f16 hr4.z, hr27.x, hr25.z, (last)hr4.z
mad.f16 hr8.w, hr27.y, hr25.x, (last)hr8.w
mad.f16 hr6.w, hr27.y, hr25.y, (last)hr6.w
mad.f16 hr4.w, hr27.y, hr25.z, (last)hr4.w
(rpt1)mad.f16 hr17.x, (r)hr27.z, hr24.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr27.z, hr24.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr27.z, hr24.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr27.z, hr24.w, (r)(last)hr11.x
(rpt1)mad.f16 hr9.x, (r)hr27.z, hr25.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr27.z, hr25.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr27.z, hr25.z, (r)(last)hr5.x
(rpt1)mad.f16 hr26.x, (r)(last)hr26.x, hr25.w, (r)(last)hr21.z
(rpt1)mad.f16 hr26.z, (r)(last)hr26.z, hr25.w, (r)(last)hr22.x
(rpt1)mad.f16 hr27.x, (r)(last)hr27.x, hr25.w, (r)(last)hr23.x
(rpt1)mad.f16 hr27.z, (r)(last)hr27.z, hr25.w, (r)(last)hr23.z
mad.f16 hr17.z, hr30.x, hr28.x, (last)hr17.z
mad.f16 hr15.z, hr30.x, hr28.y, (last)hr15.z
mad.f16 hr13.z, hr30.x, hr28.z, (last)hr13.z
mad.f16 hr11.z, hr30.x, hr28.w, (last)hr11.z
mad.f16 hr17.w, hr30.y, hr28.x, (last)hr17.w
mad.f16 hr15.w, hr30.y, hr28.y, (last)hr15.w
mad.f16 hr13.w, hr30.y, hr28.z, (last)hr13.w
mad.f16 hr11.w, hr30.y, hr28.w, (last)hr11.w
mad.f16 hr18.x, hr30.z, hr28.x, (last)hr18.x
mad.f16 hr16.x, hr30.z, hr28.y, (last)hr16.x
mad.f16 hr14.x, hr30.z, hr28.z, (last)hr14.x
mad.f16 hr12.x, hr30.z, hr28.w, (last)hr12.x
mad.f16 hr18.y, hr30.w, hr28.x, (last)hr18.y
mad.f16 hr16.y, hr30.w, hr28.y, (last)hr16.y
mad.f16 hr14.y, hr30.w, hr28.z, (last)hr14.y
mad.f16 hr12.y, hr30.w, hr28.w, (last)hr12.y
mad.f16 hr9.z, hr30.x, hr29.x, (last)hr9.z
mad.f16 hr7.z, hr30.x, hr29.y, (last)hr7.z
mad.f16 hr5.z, hr30.x, hr29.z, (last)hr5.z
mad.f16 hr9.w, hr30.y, hr29.x, (last)hr9.w
mad.f16 hr7.w, hr30.y, hr29.y, (last)hr7.w
mad.f16 hr5.w, hr30.y, hr29.z, (last)hr5.w
mad.f16 hr10.x, hr30.z, hr29.x, (last)hr10.x
mad.f16 hr8.x, hr30.z, hr29.y, (last)hr8.x
mad.f16 hr6.x, hr30.z, hr29.z, (last)hr6.x
mad.f16 hr10.y, hr30.w, hr29.x, (last)hr10.y
mad.f16 hr8.y, hr30.w, hr29.y, (last)hr8.y
mad.f16 hr6.y, hr30.w, hr29.z, (last)hr6.y
mad.f16 hr16.z, hr31.x, hr28.x, (last)hr16.z
mad.f16 hr14.z, hr31.x, hr28.y, (last)hr14.z
mad.f16 hr12.z, hr31.x, hr28.z, (last)hr12.z
mad.f16 hr10.z, hr31.x, hr28.w, (last)hr10.z
mad.f16 hr16.w, hr31.y, hr28.x, (last)hr16.w
mad.f16 hr14.w, hr31.y, hr28.y, (last)hr14.w
mad.f16 hr12.w, hr31.y, hr28.z, (last)hr12.w
mad.f16 hr10.w, hr31.y, hr28.w, (last)hr10.w
mad.f16 hr8.z, hr31.x, hr29.x, (last)hr8.z
mad.f16 hr6.z, hr31.x, hr29.y, (last)hr6.z
mad.f16 hr4.z, hr31.x, hr29.z, (last)hr4.z
mad.f16 hr8.w, hr31.y, hr29.x, (last)hr8.w
mad.f16 hr6.w, hr31.y, hr29.y, (last)hr6.w
mad.f16 hr4.w, hr31.y, hr29.z, (last)hr4.w
(rpt1)mad.f16 hr17.x, (r)hr31.z, hr28.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr31.z, hr28.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr31.z, hr28.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr31.z, hr28.w, (r)(last)hr11.x
(rpt1)mad.f16 hr9.x, (r)hr31.z, hr29.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr31.z, hr29.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr31.z, hr29.z, (r)(last)hr5.x
(rpt1)mad.f16 hr30.x, (r)(last)hr30.x, hr29.w, (r)(last)hr26.x
(rpt1)mad.f16 hr30.z, (r)(last)hr30.z, hr29.w, (r)(last)hr26.z
(rpt1)mad.f16 hr31.x, (r)(last)hr31.x, hr29.w, (r)(last)hr27.x
(rpt1)mad.f16 hr31.z, (r)(last)hr31.z, hr29.w, (r)(last)hr27.z
mad.f16 hr17.z, hr34.x, hr32.x, (last)hr17.z
mad.f16 hr15.z, hr34.x, hr32.y, (last)hr15.z
mad.f16 hr13.z, hr34.x, hr32.z, (last)hr13.z
mad.f16 hr11.z, hr34.x, hr32.w, (last)hr11.z
mad.f16 hr17.w, hr34.y, hr32.x, (last)hr17.w
mad.f16 hr15.w, hr34.y, hr32.y, (last)hr15.w
mad.f16 hr13.w, hr34.y, hr32.z, (last)hr13.w
mad.f16 hr11.w, hr34.y, hr32.w, (last)hr11.w
mad.f16 hr18.x, hr34.z, hr32.x, (last)hr18.x
mad.f16 hr16.x, hr34.z, hr32.y, (last)hr16.x
mad.f16 hr14.x, hr34.z, hr32.z, (last)hr14.x
mad.f16 hr12.x, hr34.z, hr32.w, (last)hr12.x
mad.f16 hr18.y, hr34.w, hr32.x, (last)hr18.y
mad.f16 hr16.y, hr34.w, hr32.y, (last)hr16.y
mad.f16 hr14.y, hr34.w, hr32.z, (last)hr14.y
mad.f16 hr12.y, hr34.w, hr32.w, (last)hr12.y
mad.f16 hr9.z, hr34.x, hr33.x, (last)hr9.z
mad.f16 hr7.z, hr34.x, hr33.y, (last)hr7.z
mad.f16 hr5.z, hr34.x, hr33.z, (last)hr5.z
mad.f16 hr9.w, hr34.y, hr33.x, (last)hr9.w
mad.f16 hr7.w, hr34.y, hr33.y, (last)hr7.w
mad.f16 hr5.w, hr34.y, hr33.z, (last)hr5.w
mad.f16 hr10.x, hr34.z, hr33.x, (last)hr10.x
mad.f16 hr8.x, hr34.z, hr33.y, (last)hr8.x
mad.f16 hr6.x, hr34.z, hr33.z, (last)hr6.x
mad.f16 hr10.y, hr34.w, hr33.x, (last)hr10.y
mad.f16 hr8.y, hr34.w, hr33.y, (last)hr8.y
mad.f16 hr6.y, hr34.w, hr33.z, (last)hr6.y
mad.f16 hr16.z, hr35.x, hr32.x, (last)hr16.z
mad.f16 hr14.z, hr35.x, hr32.y, (last)hr14.z
mad.f16 hr12.z, hr35.x, hr32.z, (last)hr12.z
mad.f16 hr10.z, hr35.x, hr32.w, (last)hr10.z
mad.f16 hr16.w, hr35.y, hr32.x, (last)hr16.w
mad.f16 hr14.w, hr35.y, hr32.y, (last)hr14.w
mad.f16 hr12.w, hr35.y, hr32.z, (last)hr12.w
mad.f16 hr10.w, hr35.y, hr32.w, (last)hr10.w
mad.f16 hr8.z, hr35.x, hr33.x, (last)hr8.z
mad.f16 hr6.z, hr35.x, hr33.y, (last)hr6.z
mad.f16 hr4.z, hr35.x, hr33.z, (last)hr4.z
mad.f16 hr8.w, hr35.y, hr33.x, (last)hr8.w
mad.f16 hr6.w, hr35.y, hr33.y, (last)hr6.w
mad.f16 hr4.w, hr35.y, hr33.z, (last)hr4.w
(rpt1)mad.f16 hr17.x, (r)hr35.z, hr32.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr35.z, hr32.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr35.z, hr32.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr35.z, hr32.w, (r)(last)hr11.x
(rpt1)mad.f16 hr9.x, (r)hr35.z, hr33.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr35.z, hr33.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr35.z, hr33.z, (r)(last)hr5.x
(rpt1)mad.f16 hr34.x, (r)(last)hr34.x, hr33.w, (r)(last)hr30.x
(rpt1)mad.f16 hr34.z, (r)(last)hr34.z, hr33.w, (r)(last)hr30.z
(rpt1)mad.f16 hr35.x, (r)(last)hr35.x, hr33.w, (r)(last)hr31.x
(rpt1)mad.f16 hr35.z, (r)(last)hr35.z, hr33.w, (r)(last)hr31.z
bar.g
(sy)(ss)mad.f16 hr17.z, hr38.x, hr36.x, (last)hr17.z
mad.f16 hr15.z, hr38.x, hr36.y, (last)hr15.z
mad.f16 hr13.z, hr38.x, hr36.z, (last)hr13.z
mad.f16 hr11.z, hr38.x, hr36.w, (last)hr11.z
mad.f16 hr17.w, hr38.y, hr36.x, (last)hr17.w
mad.f16 hr15.w, hr38.y, hr36.y, (last)hr15.w
mad.f16 hr13.w, hr38.y, hr36.z, (last)hr13.w
mad.f16 hr11.w, hr38.y, hr36.w, (last)hr11.w
mad.f16 hr18.x, hr38.z, hr36.x, (last)hr18.x
mad.f16 hr16.x, hr38.z, hr36.y, (last)hr16.x
mad.f16 hr14.x, hr38.z, hr36.z, (last)hr14.x
mad.f16 hr12.x, hr38.z, hr36.w, (last)hr12.x
mad.f16 hr18.y, hr38.w, hr36.x, (last)hr18.y
mad.f16 hr16.y, hr38.w, hr36.y, (last)hr16.y
mad.f16 hr14.y, hr38.w, hr36.z, (last)hr14.y
mad.f16 hr12.y, hr38.w, hr36.w, (last)hr12.y
mad.f16 hr9.z, hr38.x, hr37.x, (last)hr9.z
mad.f16 hr7.z, hr38.x, hr37.y, (last)hr7.z
mad.f16 hr5.z, hr38.x, hr37.z, (last)hr5.z
mad.f16 hr9.w, hr38.y, hr37.x, (last)hr9.w
mad.f16 hr7.w, hr38.y, hr37.y, (last)hr7.w
mad.f16 hr5.w, hr38.y, hr37.z, (last)hr5.w
mad.f16 hr10.x, hr38.z, hr37.x, (last)hr10.x
mad.f16 hr8.x, hr38.z, hr37.y, (last)hr8.x
mad.f16 hr6.x, hr38.z, hr37.z, (last)hr6.x
mad.f16 hr10.y, hr38.w, hr37.x, (last)hr10.y
mad.f16 hr8.y, hr38.w, hr37.y, (last)hr8.y
mad.f16 hr6.y, hr38.w, hr37.z, (last)hr6.y
mad.f16 hr16.z, hr39.x, hr36.x, (last)hr16.z
mad.f16 hr14.z, hr39.x, hr36.y, (last)hr14.z
mad.f16 hr12.z, hr39.x, hr36.z, (last)hr12.z
mad.f16 hr10.z, hr39.x, hr36.w, (last)hr10.z
mad.f16 hr16.w, hr39.y, hr36.x, (last)hr16.w
mad.f16 hr14.w, hr39.y, hr36.y, (last)hr14.w
mad.f16 hr12.w, hr39.y, hr36.z, (last)hr12.w
mad.f16 hr10.w, hr39.y, hr36.w, (last)hr10.w
mad.f16 hr8.z, hr39.x, hr37.x, (last)hr8.z
mad.f16 hr6.z, hr39.x, hr37.y, (last)hr6.z
mad.f16 hr4.z, hr39.x, hr37.z, (last)hr4.z
mad.f16 hr8.w, hr39.y, hr37.x, (last)hr8.w
mad.f16 hr6.w, hr39.y, hr37.y, (last)hr6.w
mad.f16 hr4.w, hr39.y, hr37.z, (last)hr4.w
(rpt1)mad.f16 hr17.x, (r)hr39.z, hr36.x, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr39.z, hr36.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr39.z, hr36.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr39.z, hr36.w, (r)(last)hr11.x
(rpt1)mad.f16 hr9.x, (r)hr39.z, hr37.x, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr39.z, hr37.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr39.z, hr37.z, (r)(last)hr5.x
(rpt1)mad.f16 hr3.z, (r)(last)hr38.x, hr37.w, (r)(last)hr34.x
(rpt1)mad.f16 hr4.x, (r)(last)hr38.z, hr37.w, (r)(last)hr34.z
(rpt1)mad.f16 hr2.z, (r)(last)hr39.x, hr37.w, (r)(last)hr35.x
(rpt1)mad.f16 hr3.x, (r)(last)hr39.z, hr37.w, (r)(last)hr35.z
br p0.x, #l1097
jump #l128
l1097:
(jp)(eolm)nop
(nop3) add.u r11.y, r51.w, (last)r11.y
(nop3) shl.b r11.y, (last)r11.y, 9
(nop3) sad.s32 r11.y, r52.w, r11.y, (last)r1.x
(nop3) shl.b r11.y, (last)r11.y, 2
add.u r20.x, r11.y, c1.x
add.u r20.y, r11.y, c8.y
add.u r20.z, r11.y, c4.z
add.u r20.w, r11.y, c8.x
add.u r0.x, r11.y, c4.y
add.u r0.y, r11.y, c7.w
(rpt1)add.u r0.z, r11.y, (r)c8.z
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r11.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r11.y+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r20.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r20.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r20.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r20.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r0.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r0.y, 4
(ss)(rpt1)add.u r5.y, r11.y, (r)c10.x
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r0.z, 4
(ss)(rpt1)add.u r4.w, r11.y, (r)c9.z
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r0.w, 4
(ss)(rpt1)add.u r4.y, (last)r11.y, (r)c9.x
(rpt4)nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r4.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r4.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r4.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r5.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r5.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr2.z, r5.z, 4
end
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1287 instr, 29 nops, 1258 non-nops, 65 mov, 0 cov, 2278 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 21 full, 12 constlen
; CL prog 23/1: 32 cat0, 65 cat1, 74 cat2, 1028 cat3, 0 cat4, 34 cat5, 50 cat6, 4 cat7
; CL prog 23/1: 30 sstall, 16 (ss), 155 systall, 9 (sy), 1 loops
; CL prog 23/1: 12 max_waves, 0 double_threadsize
; 58 preamble-instr, 1 early-preamble
