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
isam.v.base0 (u16)(xyzw)hr40.w, r12.x, s#0, t#2
isam.v.base0 (u16)(xyzw)hr20.w, r12.x+64, s#0, t#2
ldl.u16 r39.z, l[r10.x], 4
ldl.u16 r0.z, l[r10.x+64], 4
ldl.u16 r23.x, l[r10.x+128], 4
(sy)(ss)mad.f16 hr17.z, hr40.w, hr39.z, (last)hr17.z
mad.f16 hr15.z, hr40.w, hr39.w, (last)hr15.z
mad.f16 hr13.z, hr40.w, hr40.x, (last)hr13.z
mad.f16 hr11.z, hr40.w, hr40.y, (last)hr11.z
mad.f16 hr16.w, hr21.x, hr39.z, (last)hr16.w
mad.f16 hr14.w, hr21.x, hr39.w, (last)hr14.w
mad.f16 hr12.w, hr21.x, hr40.x, (last)hr12.w
mad.f16 hr10.w, hr21.x, hr40.y, (last)hr10.w
(rpt1)mad.f16 hr17.x, (r)hr21.y, hr39.z, (r)(last)hr17.x
(rpt1)mad.f16 hr15.x, (r)hr21.y, hr39.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr21.y, hr40.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr21.y, hr40.y, (r)(last)hr11.x
mad.f16 hr9.z, hr40.w, hr0.z, (last)hr9.z
mad.f16 hr7.z, hr40.w, hr0.w, (last)hr7.z
mad.f16 hr5.z, hr40.w, hr1.x, (last)hr5.z
mad.f16 hr8.w, hr21.x, hr0.z, (last)hr8.w
mad.f16 hr6.w, hr21.x, hr0.w, (last)hr6.w
mad.f16 hr4.w, hr21.x, hr1.x, (last)hr4.w
(rpt1)mad.f16 hr9.x, (r)hr21.y, hr0.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr21.y, hr0.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr21.y, hr1.x, (r)(last)hr5.x
mad.f16 hr40.w, (last)hr40.w, hr1.y, (last)hr3.z
mad.f16 hr21.x, (last)hr21.x, hr1.y, (last)hr2.w
(rpt1)mad.f16 hr21.y, (r)(last)hr21.y, hr1.y, (r)(last)hr3.x
isam.v.base0 (u16)(xyzw)hr2.w, r12.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr18.w, r12.z, s#0, t#2
mad.f16 hr17.w, hr41.x, hr39.z, (last)hr17.w
mad.f16 hr15.w, hr41.x, hr39.w, (last)hr15.w
mad.f16 hr13.w, hr41.x, hr40.x, (last)hr13.w
mad.f16 hr11.w, hr41.x, hr40.y, (last)hr11.w
mad.f16 hr18.x, hr41.y, hr39.z, (last)hr18.x
mad.f16 hr16.x, hr41.y, hr39.w, (last)hr16.x
mad.f16 hr14.x, hr41.y, hr40.x, (last)hr14.x
mad.f16 hr12.x, hr41.y, hr40.y, (last)hr12.x
mad.f16 hr18.y, hr41.z, hr39.z, (last)hr18.y
mad.f16 hr16.y, hr41.z, hr39.w, (last)hr16.y
mad.f16 hr14.y, hr41.z, hr40.x, (last)hr14.y
mad.f16 hr12.y, hr41.z, hr40.y, (last)hr12.y
mad.f16 hr16.z, hr20.w, hr39.z, (last)hr16.z
mad.f16 hr14.z, hr20.w, hr39.w, (last)hr14.z
mad.f16 hr12.z, hr20.w, hr40.x, (last)hr12.z
mad.f16 hr10.z, hr20.w, hr40.y, (last)hr10.z
ldl.u16 r39.z, l[r10.x+192], 4
mad.f16 hr9.w, hr41.x, hr0.z, (last)hr9.w
(rpt1)mad.f16 hr10.x, (r)hr41.y, hr0.z, (r)(last)hr10.x
mad.f16 hr7.w, hr41.x, hr0.w, (last)hr7.w
(rpt1)mad.f16 hr8.x, (r)hr41.y, hr0.w, (r)(last)hr8.x
mad.f16 hr5.w, hr41.x, hr1.x, (last)hr5.w
(rpt1)mad.f16 hr6.x, (r)hr41.y, hr1.x, (r)(last)hr6.x
mad.f16 hr41.x, (last)hr41.x, hr1.y, (last)hr3.w
(ss)nop
ldl.u16 r24.x, l[r10.x+256], 4
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr1.y, (r)(last)hr4.x
mad.f16 hr8.z, hr20.w, hr0.z, (last)hr8.z
mad.f16 hr6.z, hr20.w, hr0.w, (last)hr6.z
mad.f16 hr4.z, hr20.w, hr1.x, (last)hr4.z
mad.f16 hr20.w, (last)hr20.w, hr1.y, (last)hr2.z
(sy)mad.f16 hr17.z, hr2.w, hr23.x, (last)hr17.z
mad.f16 hr15.z, hr2.w, hr23.y, (last)hr15.z
mad.f16 hr13.z, hr2.w, hr23.z, (last)hr13.z
mad.f16 hr11.z, hr2.w, hr23.w, (last)hr11.z
mad.f16 hr17.w, hr3.x, hr23.x, (last)hr17.w
mad.f16 hr15.w, hr3.x, hr23.y, (last)hr15.w
mad.f16 hr13.w, hr3.x, hr23.z, (last)hr13.w
mad.f16 hr11.w, hr3.x, hr23.w, (last)hr11.w
mad.f16 hr18.x, hr3.y, hr23.x, (last)hr18.x
mad.f16 hr16.x, hr3.y, hr23.y, (last)hr16.x
mad.f16 hr14.x, hr3.y, hr23.z, (last)hr14.x
mad.f16 hr12.x, hr3.y, hr23.w, (last)hr12.x
mad.f16 hr18.y, hr3.z, hr23.x, (last)hr18.y
mad.f16 hr16.y, hr3.z, hr23.y, (last)hr16.y
mad.f16 hr14.y, hr3.z, hr23.z, (last)hr14.y
mad.f16 hr12.y, hr3.z, hr23.w, (last)hr12.y
mad.f16 hr9.z, hr2.w, hr39.z, (last)hr9.z
mad.f16 hr7.z, hr2.w, hr39.w, (last)hr7.z
mad.f16 hr5.z, hr2.w, hr40.x, (last)hr5.z
mad.f16 hr9.w, hr3.x, hr39.z, (last)hr9.w
(rpt1)mad.f16 hr10.x, (r)hr3.y, hr39.z, (r)(last)hr10.x
mad.f16 hr7.w, hr3.x, hr39.w, (last)hr7.w
(rpt1)mad.f16 hr8.x, (r)hr3.y, hr39.w, (r)(last)hr8.x
mad.f16 hr5.w, hr3.x, hr40.x, (last)hr5.w
(rpt1)mad.f16 hr6.x, (r)hr3.y, hr40.x, (r)(last)hr6.x
(rpt1)mad.f16 hr2.w, (r)(last)hr2.w, hr40.y, (r)(last)hr40.w
(rpt1)mad.f16 hr3.y, (r)(last)hr3.y, hr40.y, (r)(last)hr41.y
isam.v.base0 (u16)(xyzw)hr40.w, r12.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr0.z, r13.x, s#0, t#2
mad.f16 hr16.w, hr19.x, hr23.x, (last)hr16.w
(rpt1)mad.f16 hr17.x, (r)hr19.y, hr23.x, (r)(last)hr17.x
mad.f16 hr16.z, hr18.w, hr23.x, (last)hr16.z
mad.f16 hr14.w, hr19.x, hr23.y, (last)hr14.w
mad.f16 hr12.w, hr19.x, hr23.z, (last)hr12.w
mad.f16 hr10.w, hr19.x, hr23.w, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr19.y, hr23.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr19.y, hr23.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr19.y, hr23.w, (r)(last)hr11.x
mad.f16 hr14.z, hr18.w, hr23.y, (last)hr14.z
mad.f16 hr12.z, hr18.w, hr23.z, (last)hr12.z
mad.f16 hr10.z, hr18.w, hr23.w, (last)hr10.z
mad.f16 hr8.w, hr19.x, hr39.z, (last)hr8.w
mad.f16 hr6.w, hr19.x, hr39.w, (last)hr6.w
mad.f16 hr4.w, hr19.x, hr40.x, (last)hr4.w
(rpt1)mad.f16 hr9.x, (r)hr19.y, hr39.z, (r)(last)hr9.x
(rpt1)mad.f16 hr7.x, (r)hr19.y, hr39.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr19.y, hr40.x, (r)(last)hr5.x
mad.f16 hr8.z, hr18.w, hr39.z, (last)hr8.z
mad.f16 hr6.z, hr18.w, hr39.w, (last)hr6.z
mad.f16 hr4.z, hr18.w, hr40.x, (last)hr4.z
mad.f16 hr19.x, (last)hr19.x, hr40.y, (last)hr21.x
(rpt1)mad.f16 hr19.y, (r)(last)hr19.y, hr40.y, (r)(last)hr21.y
mad.f16 hr18.w, (last)hr18.w, hr40.y, (last)hr20.w
isam.v.base0 (u16)(xyzw)hr20.w, r13.y, s#0, t#2
ldl.u16 r39.z, l[r10.x+320], 4
(sy)(ss)(rpt1)mad.f16 hr17.z, (r)hr40.w, hr24.x, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr41.y, hr24.x, (r)(last)hr18.x
mad.f16 hr16.w, hr0.w, hr24.x, (last)hr16.w
(rpt1)mad.f16 hr17.x, (r)hr1.x, hr24.x, (r)(last)hr17.x
mad.f16 hr16.z, hr0.z, hr24.x, (last)hr16.z
isam.v.base0 (u16)(xyzw)hr23.y, r13.z, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr26.y, r13.w, s#0, t#2
(ss)nop
isam.v.base0 (u16)(xyzw)hr27.y, r14.x, s#0, t#2
mad.f16 hr15.z, hr40.w, hr24.y, (last)hr15.z
mad.f16 hr13.z, hr40.w, hr24.z, (last)hr13.z
mad.f16 hr11.z, hr40.w, hr24.w, (last)hr11.z
mad.f16 hr15.w, hr41.x, hr24.y, (last)hr15.w
mad.f16 hr13.w, hr41.x, hr24.z, (last)hr13.w
mad.f16 hr11.w, hr41.x, hr24.w, (last)hr11.w
mad.f16 hr16.x, hr41.y, hr24.y, (last)hr16.x
mad.f16 hr14.x, hr41.y, hr24.z, (last)hr14.x
mad.f16 hr12.x, hr41.y, hr24.w, (last)hr12.x
mad.f16 hr16.y, hr41.z, hr24.y, (last)hr16.y
mad.f16 hr14.y, hr41.z, hr24.z, (last)hr14.y
mad.f16 hr12.y, hr41.z, hr24.w, (last)hr12.y
mad.f16 hr9.z, hr40.w, hr39.z, (last)hr9.z
mad.f16 hr7.z, hr40.w, hr39.w, (last)hr7.z
mad.f16 hr5.z, hr40.w, hr40.x, (last)hr5.z
mad.f16 hr9.w, hr41.x, hr39.z, (last)hr9.w
mad.f16 hr7.w, hr41.x, hr39.w, (last)hr7.w
mad.f16 hr5.w, hr41.x, hr40.x, (last)hr5.w
mad.f16 hr10.x, hr41.y, hr39.z, (last)hr10.x
mad.f16 hr8.x, hr41.y, hr39.w, (last)hr8.x
mad.f16 hr6.x, hr41.y, hr40.x, (last)hr6.x
mad.f16 hr10.y, hr41.z, hr39.z, (last)hr10.y
mad.f16 hr8.y, hr41.z, hr39.w, (last)hr8.y
mad.f16 hr6.y, hr41.z, hr40.x, (last)hr6.y
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr40.y, (r)(last)hr2.w
mad.f16 hr41.y, (last)hr41.y, hr40.y, (last)hr3.y
ldl.u16 r2.z, l[r10.x+384], 4
mad.f16 hr41.z, (last)hr41.z, hr40.y, (last)hr3.z
ldl.u16 r3.z, l[r10.x+448], 4
mad.f16 hr14.w, hr0.w, hr24.y, (last)hr14.w
mad.f16 hr12.w, hr0.w, hr24.z, (last)hr12.w
mad.f16 hr10.w, hr0.w, hr24.w, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr1.x, hr24.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr1.x, hr24.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr1.x, hr24.w, (r)(last)hr11.x
mad.f16 hr14.z, hr0.z, hr24.y, (last)hr14.z
mad.f16 hr12.z, hr0.z, hr24.z, (last)hr12.z
mad.f16 hr10.z, hr0.z, hr24.w, (last)hr10.z
ldl.u16 r24.y, l[r10.x+512], 4
ldl.u16 r25.y, l[r10.x+576], 4
(rpt1)mad.f16 hr8.z, (r)hr0.z, hr39.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr1.x, hr39.z, (r)(last)hr9.x
mad.f16 hr6.z, hr0.z, hr39.w, (last)hr6.z
mad.f16 hr4.z, hr0.z, hr40.x, (last)hr4.z
mad.f16 hr6.w, hr0.w, hr39.w, (last)hr6.w
mad.f16 hr4.w, hr0.w, hr40.x, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr1.x, hr39.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr1.x, hr40.x, (r)(last)hr5.x
(ss)mad.f16 hr15.z, hr20.w, hr2.w, (last)hr15.z
mad.f16 hr13.z, hr20.w, hr3.x, (last)hr13.z
mad.f16 hr11.z, hr20.w, hr3.y, (last)hr11.z
mad.f16 hr15.w, hr21.x, hr2.w, (last)hr15.w
mad.f16 hr13.w, hr21.x, hr3.x, (last)hr13.w
mad.f16 hr11.w, hr21.x, hr3.y, (last)hr11.w
mad.f16 hr16.x, hr21.y, hr2.w, (last)hr16.x
mad.f16 hr14.x, hr21.y, hr3.x, (last)hr14.x
mad.f16 hr12.x, hr21.y, hr3.y, (last)hr12.x
mad.f16 hr16.y, hr21.z, hr2.w, (last)hr16.y
mad.f16 hr14.y, hr21.z, hr3.x, (last)hr14.y
mad.f16 hr12.y, hr21.z, hr3.y, (last)hr12.y
(rpt1)mad.f16 hr9.z, (r)hr20.w, hr3.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr21.y, hr3.z, (r)(last)hr10.x
(sy)mad.f16 hr14.w, hr23.z, hr2.w, (last)hr14.w
mad.f16 hr12.w, hr23.z, hr3.x, (last)hr12.w
mad.f16 hr10.w, hr23.z, hr3.y, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr23.w, hr2.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr23.w, hr3.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr23.w, hr3.y, (r)(last)hr11.x
mad.f16 hr14.z, hr23.y, hr2.w, (last)hr14.z
mad.f16 hr12.z, hr23.y, hr3.x, (last)hr12.z
mad.f16 hr10.z, hr23.y, hr3.y, (last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr23.y, hr3.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr23.w, hr3.z, (r)(last)hr9.x
isam.v.base0 (u16)(xyzw)hr2.w, r14.y, s#0, t#2
(rpt1)mad.f16 hr0.z, (r)(last)hr0.z, hr40.y, (r)(last)hr18.w
(rpt1)mad.f16 hr1.x, (r)(last)hr1.x, hr40.y, (r)(last)hr19.y
isam.v.base0 (u16)(xyzw)hr18.w, r14.z, s#0, t#2
ldl.u16 r39.z, l[r10.x+640], 4
(rpt1)mad.f16 hr17.z, (r)hr20.w, hr2.z, (r)(last)hr17.z
mad.f16 hr18.x, hr21.y, hr2.z, (last)hr18.x
mad.f16 hr7.z, hr20.w, hr3.w, (last)hr7.z
mad.f16 hr5.z, hr20.w, hr4.x, (last)hr5.z
mad.f16 hr7.w, hr21.x, hr3.w, (last)hr7.w
mad.f16 hr5.w, hr21.x, hr4.x, (last)hr5.w
mad.f16 hr8.x, hr21.y, hr3.w, (last)hr8.x
mad.f16 hr6.x, hr21.y, hr4.x, (last)hr6.x
(rpt1)mad.f16 hr20.w, (r)(last)hr20.w, hr4.y, (r)(last)hr40.w
mad.f16 hr21.y, (last)hr21.y, hr4.y, (last)hr41.y
ldl.u16 r40.z, l[r10.x+704], 4
mad.f16 hr18.y, hr21.z, hr2.z, (last)hr18.y
(rpt1)mad.f16 hr16.z, (r)hr23.y, hr2.z, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr23.w, hr2.z, (r)(last)hr17.x
mad.f16 hr6.z, hr23.y, hr3.w, (last)hr6.z
mad.f16 hr4.z, hr23.y, hr4.x, (last)hr4.z
mad.f16 hr6.w, hr23.z, hr3.w, (last)hr6.w
mad.f16 hr4.w, hr23.z, hr4.x, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr23.w, hr3.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr23.w, hr4.x, (r)(last)hr5.x
(rpt1)mad.f16 hr23.y, (r)(last)hr23.y, hr4.y, (r)(last)hr0.z
(rpt1)mad.f16 hr23.w, (r)(last)hr23.w, hr4.y, (r)(last)hr1.x
mad.f16 hr8.y, hr21.z, hr3.w, (last)hr8.y
mad.f16 hr6.y, hr21.z, hr4.x, (last)hr6.y
mad.f16 hr15.z, hr26.y, hr24.z, (last)hr15.z
mad.f16 hr13.z, hr26.y, hr24.w, (last)hr13.z
mad.f16 hr11.z, hr26.y, hr25.x, (last)hr11.z
mad.f16 hr15.w, hr26.z, hr24.z, (last)hr15.w
mad.f16 hr13.w, hr26.z, hr24.w, (last)hr13.w
mad.f16 hr11.w, hr26.z, hr25.x, (last)hr11.w
mad.f16 hr16.x, hr26.w, hr24.z, (last)hr16.x
mad.f16 hr14.x, hr26.w, hr24.w, (last)hr14.x
mad.f16 hr12.x, hr26.w, hr25.x, (last)hr12.x
mad.f16 hr16.y, hr27.x, hr24.z, (last)hr16.y
mad.f16 hr14.y, hr27.x, hr24.w, (last)hr14.y
mad.f16 hr12.y, hr27.x, hr25.x, (last)hr12.y
mad.f16 hr14.w, hr27.z, hr24.z, (last)hr14.w
mad.f16 hr12.w, hr27.z, hr24.w, (last)hr12.w
mad.f16 hr10.w, hr27.z, hr25.x, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr27.w, hr24.z, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr27.w, hr24.w, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr27.w, hr25.x, (r)(last)hr11.x
mad.f16 hr14.z, hr27.y, hr24.z, (last)hr14.z
mad.f16 hr12.z, hr27.y, hr24.w, (last)hr12.z
mad.f16 hr10.z, hr27.y, hr25.x, (last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr27.y, hr25.y, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr27.w, hr25.y, (r)(last)hr9.x
(rpt1)mad.f16 hr17.z, (r)hr26.y, hr24.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr26.w, hr24.y, (r)(last)hr18.x
(rpt1)mad.f16 hr16.z, (r)hr27.y, hr24.y, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr27.w, hr24.y, (r)(last)hr17.x
mad.f16 hr6.z, hr27.y, hr25.z, (last)hr6.z
mad.f16 hr4.z, hr27.y, hr25.w, (last)hr4.z
mad.f16 hr6.w, hr27.z, hr25.z, (last)hr6.w
mad.f16 hr4.w, hr27.z, hr25.w, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr27.w, hr25.z, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr27.w, hr25.w, (r)(last)hr5.x
mad.f16 hr21.z, (last)hr21.z, hr4.y, (last)hr41.z
(rpt1)mad.f16 hr27.y, (r)(last)hr27.y, hr26.x, (r)(last)hr23.y
(rpt1)mad.f16 hr27.w, (r)(last)hr27.w, hr26.x, (r)(last)hr23.w
isam.v.base0 (u16)(xyzw)hr23.y, r14.w, s#0, t#2
isam.v.base0 (u16)(xyzw)hr24.y, r15.x, s#0, t#2
(rpt1)mad.f16 hr9.z, (r)hr26.y, hr25.y, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr26.w, hr25.y, (r)(last)hr10.x
mad.f16 hr7.z, hr26.y, hr25.z, (last)hr7.z
mad.f16 hr5.z, hr26.y, hr25.w, (last)hr5.z
mad.f16 hr7.w, hr26.z, hr25.z, (last)hr7.w
mad.f16 hr5.w, hr26.z, hr25.w, (last)hr5.w
mad.f16 hr8.x, hr26.w, hr25.z, (last)hr8.x
mad.f16 hr6.x, hr26.w, hr25.w, (last)hr6.x
mad.f16 hr8.y, hr27.x, hr25.z, (last)hr8.y
mad.f16 hr6.y, hr27.x, hr25.w, (last)hr6.y
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr26.x, (r)(last)hr20.w
mad.f16 hr26.w, (last)hr26.w, hr26.x, (last)hr21.y
ldl.u16 r20.z, l[r10.x+768], 4
mad.f16 hr27.x, (last)hr27.x, hr26.x, (last)hr21.z
ldl.u16 r21.z, l[r10.x+832], 4
ldl.u16 r25.y, l[r10.x+896], 4
(sy)(ss)mad.f16 hr14.w, hr19.x, hr39.w, (last)hr14.w
mad.f16 hr12.w, hr19.x, hr40.x, (last)hr12.w
mad.f16 hr10.w, hr19.x, hr40.y, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr19.y, hr39.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr19.y, hr40.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr19.y, hr40.y, (r)(last)hr11.x
mad.f16 hr14.z, hr18.w, hr39.w, (last)hr14.z
mad.f16 hr12.z, hr18.w, hr40.x, (last)hr12.z
mad.f16 hr10.z, hr18.w, hr40.y, (last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr18.w, hr40.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr19.y, hr40.z, (r)(last)hr9.x
(rpt1)mad.f16 hr16.z, (r)hr18.w, hr39.z, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr19.y, hr39.z, (r)(last)hr17.x
mad.f16 hr6.z, hr18.w, hr40.w, (last)hr6.z
mad.f16 hr4.z, hr18.w, hr41.x, (last)hr4.z
mad.f16 hr6.w, hr19.x, hr40.w, (last)hr6.w
mad.f16 hr4.w, hr19.x, hr41.x, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr19.y, hr40.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr19.y, hr41.x, (r)(last)hr5.x
(rpt1)mad.f16 hr18.w, (r)(last)hr18.w, hr41.y, (r)(last)hr27.y
(rpt1)mad.f16 hr19.y, (r)(last)hr19.y, hr41.y, (r)(last)hr27.w
isam.v.base0 (u16)(xyzw)hr27.y, r15.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr28.y, r15.z, s#0, t#2
mad.f16 hr15.z, hr2.w, hr39.w, (last)hr15.z
mad.f16 hr13.z, hr2.w, hr40.x, (last)hr13.z
mad.f16 hr11.z, hr2.w, hr40.y, (last)hr11.z
mad.f16 hr15.w, hr3.x, hr39.w, (last)hr15.w
mad.f16 hr13.w, hr3.x, hr40.x, (last)hr13.w
mad.f16 hr11.w, hr3.x, hr40.y, (last)hr11.w
mad.f16 hr16.x, hr3.y, hr39.w, (last)hr16.x
mad.f16 hr14.x, hr3.y, hr40.x, (last)hr14.x
mad.f16 hr12.x, hr3.y, hr40.y, (last)hr12.x
mad.f16 hr16.y, hr3.z, hr39.w, (last)hr16.y
mad.f16 hr14.y, hr3.z, hr40.x, (last)hr14.y
mad.f16 hr12.y, hr3.z, hr40.y, (last)hr12.y
(rpt1)mad.f16 hr17.z, (r)hr2.w, hr39.z, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr3.y, hr39.z, (r)(last)hr18.x
(rpt1)mad.f16 hr9.z, (r)hr2.w, hr40.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr3.y, hr40.z, (r)(last)hr10.x
isam.v.base0 (u16)(xyzw)hr39.w, r15.w, s#0, t#2
mad.f16 hr7.z, hr2.w, hr40.w, (last)hr7.z
mad.f16 hr5.z, hr2.w, hr41.x, (last)hr5.z
mad.f16 hr7.w, hr3.x, hr40.w, (last)hr7.w
mad.f16 hr5.w, hr3.x, hr41.x, (last)hr5.w
mad.f16 hr8.x, hr3.y, hr40.w, (last)hr8.x
mad.f16 hr6.x, hr3.y, hr41.x, (last)hr6.x
mad.f16 hr8.y, hr3.z, hr40.w, (last)hr8.y
mad.f16 hr6.y, hr3.z, hr41.x, (last)hr6.y
(rpt1)mad.f16 hr2.w, (r)(last)hr2.w, hr41.y, (r)(last)hr26.y
(rpt1)mad.f16 hr3.y, (r)(last)hr3.y, hr41.y, (r)(last)hr26.w
isam.v.base0 (u16)(xyzw)hr40.w, r16.x, s#0, t#2
ldl.u16 r26.y, l[r10.x+960], 4
ldl.u16 r29.y, l[r10.x+1024], 4
mad.f16 hr14.w, hr24.z, hr20.w, (last)hr14.w
mad.f16 hr12.w, hr24.z, hr21.x, (last)hr12.w
mad.f16 hr10.w, hr24.z, hr21.y, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr24.w, hr20.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr24.w, hr21.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr24.w, hr21.y, (r)(last)hr11.x
mad.f16 hr14.z, hr24.y, hr20.w, (last)hr14.z
(ss)nop
ldl.u16 r30.y, l[r10.x+1088], 4
ldl.u16 r0.z, l[r10.x+1152], 4
mad.f16 hr12.z, hr24.y, hr21.x, (last)hr12.z
mad.f16 hr10.z, hr24.y, hr21.y, (last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr24.y, hr21.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr24.w, hr21.z, (r)(last)hr9.x
(rpt1)mad.f16 hr16.z, (r)hr24.y, hr20.z, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr24.w, hr20.z, (r)(last)hr17.x
mad.f16 hr6.z, hr24.y, hr21.w, (last)hr6.z
mad.f16 hr4.z, hr24.y, hr22.x, (last)hr4.z
mad.f16 hr6.w, hr24.z, hr21.w, (last)hr6.w
mad.f16 hr4.w, hr24.z, hr22.x, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr24.w, hr21.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr24.w, hr22.x, (r)(last)hr5.x
mad.f16 hr15.z, hr23.y, hr20.w, (last)hr15.z
mad.f16 hr13.z, hr23.y, hr21.x, (last)hr13.z
mad.f16 hr11.z, hr23.y, hr21.y, (last)hr11.z
mad.f16 hr15.w, hr23.z, hr20.w, (last)hr15.w
mad.f16 hr13.w, hr23.z, hr21.x, (last)hr13.w
mad.f16 hr11.w, hr23.z, hr21.y, (last)hr11.w
mad.f16 hr16.x, hr23.w, hr20.w, (last)hr16.x
mad.f16 hr14.x, hr23.w, hr21.x, (last)hr14.x
mad.f16 hr12.x, hr23.w, hr21.y, (last)hr12.x
mad.f16 hr16.y, hr24.x, hr20.w, (last)hr16.y
mad.f16 hr14.y, hr24.x, hr21.x, (last)hr14.y
mad.f16 hr12.y, hr24.x, hr21.y, (last)hr12.y
(rpt1)mad.f16 hr17.z, (r)hr23.y, hr20.z, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr23.w, hr20.z, (r)(last)hr18.x
(rpt1)mad.f16 hr9.z, (r)hr23.y, hr21.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr23.w, hr21.z, (r)(last)hr10.x
mad.f16 hr7.z, hr23.y, hr21.w, (last)hr7.z
mad.f16 hr5.z, hr23.y, hr22.x, (last)hr5.z
mad.f16 hr7.w, hr23.z, hr21.w, (last)hr7.w
mad.f16 hr5.w, hr23.z, hr22.x, (last)hr5.w
mad.f16 hr8.x, hr23.w, hr21.w, (last)hr8.x
mad.f16 hr6.x, hr23.w, hr22.x, (last)hr6.x
mad.f16 hr8.y, hr24.x, hr21.w, (last)hr8.y
mad.f16 hr6.y, hr24.x, hr22.x, (last)hr6.y
(rpt1)mad.f16 hr24.y, (r)(last)hr24.y, hr22.y, (r)(last)hr18.w
(rpt1)mad.f16 hr24.w, (r)(last)hr24.w, hr22.y, (r)(last)hr19.y
isam.v.base0 (u16)(xyzw)hr18.w, r16.y, s#0, t#2
isam.v.base0 (u16)(xyzw)hr20.w, r16.z, s#0, t#2
(rpt1)mad.f16 hr23.y, (r)(last)hr23.y, hr22.y, (r)(last)hr2.w
mad.f16 hr23.w, (last)hr23.w, hr22.y, (last)hr3.y
ldl.u16 r2.z, l[r10.x+1216], 4
mad.f16 hr24.x, (last)hr24.x, hr22.y, (last)hr3.z
(sy)mad.f16 hr14.w, hr28.z, hr25.z, (last)hr14.w
mad.f16 hr12.w, hr28.z, hr25.w, (last)hr12.w
mad.f16 hr10.w, hr28.z, hr26.x, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr28.w, hr25.z, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr28.w, hr25.w, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr28.w, hr26.x, (r)(last)hr11.x
mad.f16 hr14.z, hr28.y, hr25.z, (last)hr14.z
mad.f16 hr12.z, hr28.y, hr25.w, (last)hr12.z
mad.f16 hr10.z, hr28.y, hr26.x, (last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr28.y, hr26.y, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr28.w, hr26.y, (r)(last)hr9.x
(rpt1)mad.f16 hr16.z, (r)hr28.y, hr25.y, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr28.w, hr25.y, (r)(last)hr17.x
mad.f16 hr6.z, hr28.y, hr26.z, (last)hr6.z
mad.f16 hr4.z, hr28.y, hr26.w, (last)hr4.z
mad.f16 hr6.w, hr28.z, hr26.z, (last)hr6.w
mad.f16 hr4.w, hr28.z, hr26.w, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr28.w, hr26.z, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr28.w, hr26.w, (r)(last)hr5.x
mad.f16 hr15.z, hr27.y, hr25.z, (last)hr15.z
mad.f16 hr13.z, hr27.y, hr25.w, (last)hr13.z
mad.f16 hr11.z, hr27.y, hr26.x, (last)hr11.z
mad.f16 hr15.w, hr27.z, hr25.z, (last)hr15.w
mad.f16 hr13.w, hr27.z, hr25.w, (last)hr13.w
mad.f16 hr11.w, hr27.z, hr26.x, (last)hr11.w
mad.f16 hr16.x, hr27.w, hr25.z, (last)hr16.x
mad.f16 hr14.x, hr27.w, hr25.w, (last)hr14.x
mad.f16 hr12.x, hr27.w, hr26.x, (last)hr12.x
mad.f16 hr16.y, hr28.x, hr25.z, (last)hr16.y
mad.f16 hr14.y, hr28.x, hr25.w, (last)hr14.y
mad.f16 hr12.y, hr28.x, hr26.x, (last)hr12.y
(rpt1)mad.f16 hr17.z, (r)hr27.y, hr25.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr27.w, hr25.y, (r)(last)hr18.x
isam.v.base0 (u16)(xyzw)hr25.y, r16.w, s#0, t#2
(rpt1)mad.f16 hr9.z, (r)hr27.y, hr26.y, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr27.w, hr26.y, (r)(last)hr10.x
mad.f16 hr7.z, hr27.y, hr26.z, (last)hr7.z
mad.f16 hr5.z, hr27.y, hr26.w, (last)hr5.z
mad.f16 hr7.w, hr27.z, hr26.z, (last)hr7.w
mad.f16 hr5.w, hr27.z, hr26.w, (last)hr5.w
mad.f16 hr8.x, hr27.w, hr26.z, (last)hr8.x
mad.f16 hr6.x, hr27.w, hr26.w, (last)hr6.x
mad.f16 hr8.y, hr28.x, hr26.z, (last)hr8.y
mad.f16 hr6.y, hr28.x, hr26.w, (last)hr6.y
(rpt1)mad.f16 hr28.y, (r)(last)hr28.y, hr27.x, (r)(last)hr24.y
(rpt1)mad.f16 hr28.w, (r)(last)hr28.w, hr27.x, (r)(last)hr24.w
(rpt1)mad.f16 hr27.y, (r)(last)hr27.y, hr27.x, (r)(last)hr23.y
mad.f16 hr27.w, (last)hr27.w, hr27.x, (last)hr23.w
ldl.u16 r23.x, l[r10.x+1280], 4
mad.f16 hr28.x, (last)hr28.x, hr27.x, (last)hr24.x
isam.v.base0 (u16)(xyzw)hr26.y, r17.x, s#0, t#2
ldl.u16 r24.x, l[r10.x+1344], 4
mad.f16 hr14.w, hr41.x, hr29.z, (last)hr14.w
mad.f16 hr12.w, hr41.x, hr29.w, (last)hr12.w
mad.f16 hr10.w, hr41.x, hr30.x, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr41.y, hr29.z, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr41.y, hr29.w, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr41.y, hr30.x, (r)(last)hr11.x
mad.f16 hr14.z, hr40.w, hr29.z, (last)hr14.z
mad.f16 hr12.z, hr40.w, hr29.w, (last)hr12.z
mad.f16 hr10.z, hr40.w, hr30.x, (last)hr10.z
(ss)(rpt1)mad.f16 hr8.z, (r)hr40.w, hr30.y, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr41.y, hr30.y, (r)(last)hr9.x
(rpt1)mad.f16 hr16.z, (r)hr40.w, hr29.y, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr41.y, hr29.y, (r)(last)hr17.x
mad.f16 hr6.z, hr40.w, hr30.z, (last)hr6.z
mad.f16 hr4.z, hr40.w, hr30.w, (last)hr4.z
mad.f16 hr6.w, hr41.x, hr30.z, (last)hr6.w
mad.f16 hr4.w, hr41.x, hr30.w, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr41.y, hr30.z, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr41.y, hr30.w, (r)(last)hr5.x
mad.f16 hr15.z, hr39.w, hr29.z, (last)hr15.z
mad.f16 hr13.z, hr39.w, hr29.w, (last)hr13.z
mad.f16 hr11.z, hr39.w, hr30.x, (last)hr11.z
mad.f16 hr15.w, hr40.x, hr29.z, (last)hr15.w
mad.f16 hr13.w, hr40.x, hr29.w, (last)hr13.w
mad.f16 hr11.w, hr40.x, hr30.x, (last)hr11.w
mad.f16 hr16.x, hr40.y, hr29.z, (last)hr16.x
mad.f16 hr14.x, hr40.y, hr29.w, (last)hr14.x
mad.f16 hr12.x, hr40.y, hr30.x, (last)hr12.x
mad.f16 hr16.y, hr40.z, hr29.z, (last)hr16.y
mad.f16 hr14.y, hr40.z, hr29.w, (last)hr14.y
mad.f16 hr12.y, hr40.z, hr30.x, (last)hr12.y
(rpt1)mad.f16 hr17.z, (r)hr39.w, hr29.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr40.y, hr29.y, (r)(last)hr18.x
isam.v.base0 (u16)(xyzw)hr29.y, r17.y, s#0, t#2
(rpt1)mad.f16 hr9.z, (r)hr39.w, hr30.y, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr40.y, hr30.y, (r)(last)hr10.x
mad.f16 hr7.z, hr39.w, hr30.z, (last)hr7.z
mad.f16 hr5.z, hr39.w, hr30.w, (last)hr5.z
mad.f16 hr7.w, hr40.x, hr30.z, (last)hr7.w
mad.f16 hr5.w, hr40.x, hr30.w, (last)hr5.w
mad.f16 hr8.x, hr40.y, hr30.z, (last)hr8.x
mad.f16 hr6.x, hr40.y, hr30.w, (last)hr6.x
mad.f16 hr8.y, hr40.z, hr30.z, (last)hr8.y
mad.f16 hr6.y, hr40.z, hr30.w, (last)hr6.y
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr31.x, (r)(last)hr28.y
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr31.x, (r)(last)hr28.w
(rpt1)mad.f16 hr39.w, (r)(last)hr39.w, hr31.x, (r)(last)hr27.y
(rpt1)mad.f16 hr40.y, (r)(last)hr40.y, hr31.x, (r)(last)hr27.w
isam.v.base0 (u16)(xyzw)hr30.y, r17.z, s#0, t#2
ldl.u16 r27.y, l[r10.x+1408], 4
ldl.u16 r28.y, l[r10.x+1472], 4
isam.v.base0 (u16)(xyzw)hr33.y, r17.w, s#0, t#2
ldl.u16 r31.y, l[r10.x+1536], 4
ldl.u16 r32.y, l[r10.x+1600], 4
mad.f16 hr14.w, hr21.x, hr0.w, (last)hr14.w
mad.f16 hr12.w, hr21.x, hr1.x, (last)hr12.w
mad.f16 hr10.w, hr21.x, hr1.y, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr21.y, hr0.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr21.y, hr1.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr21.y, hr1.y, (r)(last)hr11.x
mad.f16 hr14.z, hr20.w, hr0.w, (last)hr14.z
(ss)nop
isam.v.base0 (u16)(xyzw)hr34.y, r18.x, s#0, t#2
(ss)nop
ldl.u16 r35.y, l[r10.x+1664], 4
mad.f16 hr12.z, hr20.w, hr1.x, (last)hr12.z
mad.f16 hr10.z, hr20.w, hr1.y, (last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr20.w, hr2.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr21.y, hr2.z, (r)(last)hr9.x
(rpt1)mad.f16 hr16.z, (r)hr20.w, hr0.z, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr21.y, hr0.z, (r)(last)hr17.x
mad.f16 hr6.z, hr20.w, hr2.w, (last)hr6.z
mad.f16 hr4.z, hr20.w, hr3.x, (last)hr4.z
mad.f16 hr6.w, hr21.x, hr2.w, (last)hr6.w
mad.f16 hr4.w, hr21.x, hr3.x, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr21.y, hr2.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr21.y, hr3.x, (r)(last)hr5.x
mad.f16 hr15.z, hr18.w, hr0.w, (last)hr15.z
mad.f16 hr13.z, hr18.w, hr1.x, (last)hr13.z
mad.f16 hr11.z, hr18.w, hr1.y, (last)hr11.z
mad.f16 hr15.w, hr19.x, hr0.w, (last)hr15.w
mad.f16 hr13.w, hr19.x, hr1.x, (last)hr13.w
mad.f16 hr11.w, hr19.x, hr1.y, (last)hr11.w
mad.f16 hr16.x, hr19.y, hr0.w, (last)hr16.x
mad.f16 hr14.x, hr19.y, hr1.x, (last)hr14.x
mad.f16 hr12.x, hr19.y, hr1.y, (last)hr12.x
mad.f16 hr16.y, hr19.z, hr0.w, (last)hr16.y
mad.f16 hr14.y, hr19.z, hr1.x, (last)hr14.y
mad.f16 hr12.y, hr19.z, hr1.y, (last)hr12.y
(rpt1)mad.f16 hr17.z, (r)hr18.w, hr0.z, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr19.y, hr0.z, (r)(last)hr18.x
(rpt1)mad.f16 hr9.z, (r)hr18.w, hr2.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr19.y, hr2.z, (r)(last)hr10.x
mad.f16 hr7.z, hr18.w, hr2.w, (last)hr7.z
mad.f16 hr5.z, hr18.w, hr3.x, (last)hr5.z
mad.f16 hr7.w, hr19.x, hr2.w, (last)hr7.w
mad.f16 hr5.w, hr19.x, hr3.x, (last)hr5.w
mad.f16 hr8.x, hr19.y, hr2.w, (last)hr8.x
mad.f16 hr6.x, hr19.y, hr3.x, (last)hr6.x
mad.f16 hr8.y, hr19.z, hr2.w, (last)hr8.y
mad.f16 hr6.y, hr19.z, hr3.x, (last)hr6.y
(rpt1)mad.f16 hr20.w, (r)(last)hr20.w, hr3.y, (r)(last)hr40.w
(rpt1)mad.f16 hr21.y, (r)(last)hr21.y, hr3.y, (r)(last)hr41.y
isam.v.base0 (u16)(xyzw)hr40.w, r18.y, s#0, t#2
(rpt1)mad.f16 hr18.w, (r)(last)hr18.w, hr3.y, (r)(last)hr39.w
mad.f16 hr19.y, (last)hr19.y, hr3.y, (last)hr40.y
ldl.u16 r39.z, l[r10.x+1728], 4
mad.f16 hr19.z, (last)hr19.z, hr3.y, (last)hr40.z
isam.v.base0 (u16)(xyzw)hr2.w, r18.z, s#0, t#2
(sy)mad.f16 hr14.w, hr26.z, hr23.y, (last)hr14.w
mad.f16 hr12.w, hr26.z, hr23.z, (last)hr12.w
mad.f16 hr10.w, hr26.z, hr23.w, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr26.w, hr23.y, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr26.w, hr23.z, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr26.w, hr23.w, (r)(last)hr11.x
mad.f16 hr14.z, hr26.y, hr23.y, (last)hr14.z
mad.f16 hr12.z, hr26.y, hr23.z, (last)hr12.z
mad.f16 hr10.z, hr26.y, hr23.w, (last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr26.y, hr24.x, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr26.w, hr24.x, (r)(last)hr9.x
(rpt1)mad.f16 hr16.z, (r)hr26.y, hr23.x, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr26.w, hr23.x, (r)(last)hr17.x
mad.f16 hr6.z, hr26.y, hr24.y, (last)hr6.z
mad.f16 hr4.z, hr26.y, hr24.z, (last)hr4.z
mad.f16 hr6.w, hr26.z, hr24.y, (last)hr6.w
mad.f16 hr4.w, hr26.z, hr24.z, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr26.w, hr24.y, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr26.w, hr24.z, (r)(last)hr5.x
mad.f16 hr15.z, hr25.y, hr23.y, (last)hr15.z
mad.f16 hr13.z, hr25.y, hr23.z, (last)hr13.z
mad.f16 hr11.z, hr25.y, hr23.w, (last)hr11.z
mad.f16 hr15.w, hr25.z, hr23.y, (last)hr15.w
mad.f16 hr13.w, hr25.z, hr23.z, (last)hr13.w
mad.f16 hr11.w, hr25.z, hr23.w, (last)hr11.w
mad.f16 hr16.x, hr25.w, hr23.y, (last)hr16.x
mad.f16 hr14.x, hr25.w, hr23.z, (last)hr14.x
mad.f16 hr12.x, hr25.w, hr23.w, (last)hr12.x
mad.f16 hr16.y, hr26.x, hr23.y, (last)hr16.y
mad.f16 hr14.y, hr26.x, hr23.z, (last)hr14.y
mad.f16 hr12.y, hr26.x, hr23.w, (last)hr12.y
(rpt1)mad.f16 hr17.z, (r)hr25.y, hr23.x, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr25.w, hr23.x, (r)(last)hr18.x
(rpt1)mad.f16 hr9.z, (r)hr25.y, hr24.x, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr25.w, hr24.x, (r)(last)hr10.x
isam.v.base0 (u16)(xyzw)hr23.y, r18.w, s#0, t#2
mad.f16 hr7.z, hr25.y, hr24.y, (last)hr7.z
mad.f16 hr5.z, hr25.y, hr24.z, (last)hr5.z
mad.f16 hr7.w, hr25.z, hr24.y, (last)hr7.w
mad.f16 hr5.w, hr25.z, hr24.z, (last)hr5.w
mad.f16 hr8.x, hr25.w, hr24.y, (last)hr8.x
mad.f16 hr6.x, hr25.w, hr24.z, (last)hr6.x
mad.f16 hr8.y, hr26.x, hr24.y, (last)hr8.y
mad.f16 hr6.y, hr26.x, hr24.z, (last)hr6.y
(rpt1)mad.f16 hr26.y, (r)(last)hr26.y, hr24.w, (r)(last)hr20.w
(rpt1)mad.f16 hr26.w, (r)(last)hr26.w, hr24.w, (r)(last)hr21.y
(rpt1)mad.f16 hr25.y, (r)(last)hr25.y, hr24.w, (r)(last)hr18.w
mad.f16 hr25.w, (last)hr25.w, hr24.w, (last)hr19.y
ldl.u16 r18.z, l[r10.x+1792], 4
ldl.u16 r20.z, l[r10.x+1856], 4
mad.f16 hr26.x, (last)hr26.x, hr24.w, (last)hr19.z
isam.v.base0 (u16)(xyzw)hr24.y, r19.x, s#0, t#2
mad.f16 hr14.w, hr30.z, hr27.z, (last)hr14.w
mad.f16 hr12.w, hr30.z, hr27.w, (last)hr12.w
mad.f16 hr10.w, hr30.z, hr28.x, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr30.w, hr27.z, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr30.w, hr27.w, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr30.w, hr28.x, (r)(last)hr11.x
mad.f16 hr14.z, hr30.y, hr27.z, (last)hr14.z
mad.f16 hr12.z, hr30.y, hr27.w, (last)hr12.z
mad.f16 hr10.z, hr30.y, hr28.x, (last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr30.y, hr28.y, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr30.w, hr28.y, (r)(last)hr9.x
(rpt1)mad.f16 hr16.z, (r)hr30.y, hr27.y, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr30.w, hr27.y, (r)(last)hr17.x
mad.f16 hr6.z, hr30.y, hr28.z, (last)hr6.z
mad.f16 hr4.z, hr30.y, hr28.w, (last)hr4.z
mad.f16 hr6.w, hr30.z, hr28.z, (last)hr6.w
mad.f16 hr4.w, hr30.z, hr28.w, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr30.w, hr28.z, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr30.w, hr28.w, (r)(last)hr5.x
mad.f16 hr15.z, hr29.y, hr27.z, (last)hr15.z
mad.f16 hr13.z, hr29.y, hr27.w, (last)hr13.z
mad.f16 hr11.z, hr29.y, hr28.x, (last)hr11.z
mad.f16 hr15.w, hr29.z, hr27.z, (last)hr15.w
mad.f16 hr13.w, hr29.z, hr27.w, (last)hr13.w
mad.f16 hr11.w, hr29.z, hr28.x, (last)hr11.w
mad.f16 hr16.x, hr29.w, hr27.z, (last)hr16.x
mad.f16 hr14.x, hr29.w, hr27.w, (last)hr14.x
mad.f16 hr12.x, hr29.w, hr28.x, (last)hr12.x
mad.f16 hr16.y, hr30.x, hr27.z, (last)hr16.y
mad.f16 hr14.y, hr30.x, hr27.w, (last)hr14.y
mad.f16 hr12.y, hr30.x, hr28.x, (last)hr12.y
(rpt1)mad.f16 hr17.z, (r)hr29.y, hr27.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr29.w, hr27.y, (r)(last)hr18.x
isam.v.base0 (u16)(xyzw)hr27.y, r19.y, s#0, t#2
(rpt1)mad.f16 hr9.z, (r)hr29.y, hr28.y, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr29.w, hr28.y, (r)(last)hr10.x
mad.f16 hr7.z, hr29.y, hr28.z, (last)hr7.z
mad.f16 hr5.z, hr29.y, hr28.w, (last)hr5.z
mad.f16 hr7.w, hr29.z, hr28.z, (last)hr7.w
mad.f16 hr5.w, hr29.z, hr28.w, (last)hr5.w
mad.f16 hr8.x, hr29.w, hr28.z, (last)hr8.x
mad.f16 hr6.x, hr29.w, hr28.w, (last)hr6.x
mad.f16 hr8.y, hr30.x, hr28.z, (last)hr8.y
mad.f16 hr6.y, hr30.x, hr28.w, (last)hr6.y
(rpt1)mad.f16 hr30.y, (r)(last)hr30.y, hr29.x, (r)(last)hr26.y
(rpt1)mad.f16 hr30.w, (r)(last)hr30.w, hr29.x, (r)(last)hr26.w
(rpt1)mad.f16 hr29.y, (r)(last)hr29.y, hr29.x, (r)(last)hr25.y
(rpt1)mad.f16 hr29.w, (r)(last)hr29.w, hr29.x, (r)(last)hr25.w
isam.v.base0 (u16)(xyzw)hr28.y, r19.z, s#0, t#2
ldl.u16 r25.y, l[r10.x+1920], 4
ldl.u16 r26.y, l[r10.x+1984], 4
mad.f16 hr14.w, hr34.z, hr31.z, (last)hr14.w
mad.f16 hr12.w, hr34.z, hr31.w, (last)hr12.w
mad.f16 hr10.w, hr34.z, hr32.x, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr34.w, hr31.z, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr34.w, hr31.w, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr34.w, hr32.x, (r)(last)hr11.x
mad.f16 hr14.z, hr34.y, hr31.z, (last)hr14.z
mad.f16 hr12.z, hr34.y, hr31.w, (last)hr12.z
mad.f16 hr10.z, hr34.y, hr32.x, (last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr34.y, hr32.y, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr34.w, hr32.y, (r)(last)hr9.x
(rpt1)mad.f16 hr16.z, (r)hr34.y, hr31.y, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr34.w, hr31.y, (r)(last)hr17.x
mad.f16 hr6.z, hr34.y, hr32.z, (last)hr6.z
mad.f16 hr4.z, hr34.y, hr32.w, (last)hr4.z
mad.f16 hr6.w, hr34.z, hr32.z, (last)hr6.w
mad.f16 hr4.w, hr34.z, hr32.w, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr34.w, hr32.z, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr34.w, hr32.w, (r)(last)hr5.x
mad.f16 hr15.z, hr33.y, hr31.z, (last)hr15.z
mad.f16 hr13.z, hr33.y, hr31.w, (last)hr13.z
mad.f16 hr11.z, hr33.y, hr32.x, (last)hr11.z
mad.f16 hr15.w, hr33.z, hr31.z, (last)hr15.w
mad.f16 hr13.w, hr33.z, hr31.w, (last)hr13.w
mad.f16 hr11.w, hr33.z, hr32.x, (last)hr11.w
mad.f16 hr16.x, hr33.w, hr31.z, (last)hr16.x
mad.f16 hr14.x, hr33.w, hr31.w, (last)hr14.x
mad.f16 hr12.x, hr33.w, hr32.x, (last)hr12.x
mad.f16 hr16.y, hr34.x, hr31.z, (last)hr16.y
mad.f16 hr14.y, hr34.x, hr31.w, (last)hr14.y
mad.f16 hr12.y, hr34.x, hr32.x, (last)hr12.y
(rpt1)mad.f16 hr17.z, (r)hr33.y, hr31.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr33.w, hr31.y, (r)(last)hr18.x
(rpt1)mad.f16 hr9.z, (r)hr33.y, hr32.y, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr33.w, hr32.y, (r)(last)hr10.x
mad.f16 hr7.z, hr33.y, hr32.z, (last)hr7.z
mad.f16 hr5.z, hr33.y, hr32.w, (last)hr5.z
mad.f16 hr7.w, hr33.z, hr32.z, (last)hr7.w
mad.f16 hr5.w, hr33.z, hr32.w, (last)hr5.w
mad.f16 hr8.x, hr33.w, hr32.z, (last)hr8.x
mad.f16 hr6.x, hr33.w, hr32.w, (last)hr6.x
mad.f16 hr8.y, hr34.x, hr32.z, (last)hr8.y
mad.f16 hr6.y, hr34.x, hr32.w, (last)hr6.y
(rpt1)mad.f16 hr34.y, (r)(last)hr34.y, hr33.x, (r)(last)hr30.y
(rpt1)mad.f16 hr34.w, (r)(last)hr34.w, hr33.x, (r)(last)hr30.w
(rpt1)mad.f16 hr33.y, (r)(last)hr33.y, hr33.x, (r)(last)hr29.y
(rpt1)mad.f16 hr33.w, (r)(last)hr33.w, hr33.x, (r)(last)hr29.w
(ss)mad.f16 hr14.w, hr3.x, hr35.z, (last)hr14.w
mad.f16 hr12.w, hr3.x, hr35.w, (last)hr12.w
mad.f16 hr10.w, hr3.x, hr36.x, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr3.y, hr35.z, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr3.y, hr35.w, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr3.y, hr36.x, (r)(last)hr11.x
mad.f16 hr14.z, hr2.w, hr35.z, (last)hr14.z
mad.f16 hr12.z, hr2.w, hr35.w, (last)hr12.z
mad.f16 hr10.z, hr2.w, hr36.x, (last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr2.w, hr39.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr3.y, hr39.z, (r)(last)hr9.x
(rpt1)mad.f16 hr16.z, (r)hr2.w, hr35.y, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr3.y, hr35.y, (r)(last)hr17.x
mad.f16 hr6.z, hr2.w, hr39.w, (last)hr6.z
mad.f16 hr4.z, hr2.w, hr40.x, (last)hr4.z
mad.f16 hr6.w, hr3.x, hr39.w, (last)hr6.w
mad.f16 hr4.w, hr3.x, hr40.x, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr3.y, hr39.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr3.y, hr40.x, (r)(last)hr5.x
mad.f16 hr15.z, hr40.w, hr35.z, (last)hr15.z
mad.f16 hr13.z, hr40.w, hr35.w, (last)hr13.z
mad.f16 hr11.z, hr40.w, hr36.x, (last)hr11.z
mad.f16 hr15.w, hr41.x, hr35.z, (last)hr15.w
mad.f16 hr13.w, hr41.x, hr35.w, (last)hr13.w
mad.f16 hr11.w, hr41.x, hr36.x, (last)hr11.w
mad.f16 hr16.x, hr41.y, hr35.z, (last)hr16.x
mad.f16 hr14.x, hr41.y, hr35.w, (last)hr14.x
mad.f16 hr12.x, hr41.y, hr36.x, (last)hr12.x
mad.f16 hr16.y, hr41.z, hr35.z, (last)hr16.y
mad.f16 hr14.y, hr41.z, hr35.w, (last)hr14.y
mad.f16 hr12.y, hr41.z, hr36.x, (last)hr12.y
(rpt1)mad.f16 hr17.z, (r)hr40.w, hr35.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr41.y, hr35.y, (r)(last)hr18.x
(rpt1)mad.f16 hr9.z, (r)hr40.w, hr39.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr41.y, hr39.z, (r)(last)hr10.x
mad.f16 hr7.z, hr40.w, hr39.w, (last)hr7.z
mad.f16 hr5.z, hr40.w, hr40.x, (last)hr5.z
mad.f16 hr7.w, hr41.x, hr39.w, (last)hr7.w
mad.f16 hr5.w, hr41.x, hr40.x, (last)hr5.w
mad.f16 hr8.x, hr41.y, hr39.w, (last)hr8.x
mad.f16 hr6.x, hr41.y, hr40.x, (last)hr6.x
mad.f16 hr8.y, hr41.z, hr39.w, (last)hr8.y
mad.f16 hr6.y, hr41.z, hr40.x, (last)hr6.y
(rpt1)mad.f16 hr2.w, (r)(last)hr2.w, hr40.y, (r)(last)hr34.y
(rpt1)mad.f16 hr3.y, (r)(last)hr3.y, hr40.y, (r)(last)hr34.w
(rpt1)mad.f16 hr40.w, (r)(last)hr40.w, hr40.y, (r)(last)hr33.y
(rpt1)mad.f16 hr41.y, (r)(last)hr41.y, hr40.y, (r)(last)hr33.w
(sy)mad.f16 hr14.w, hr24.z, hr18.w, (last)hr14.w
mad.f16 hr12.w, hr24.z, hr19.x, (last)hr12.w
mad.f16 hr10.w, hr24.z, hr19.y, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr24.w, hr18.w, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr24.w, hr19.x, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr24.w, hr19.y, (r)(last)hr11.x
mad.f16 hr14.z, hr24.y, hr18.w, (last)hr14.z
mad.f16 hr12.z, hr24.y, hr19.x, (last)hr12.z
mad.f16 hr10.z, hr24.y, hr19.y, (last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr24.y, hr20.z, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr24.w, hr20.z, (r)(last)hr9.x
(rpt1)mad.f16 hr16.z, (r)hr24.y, hr18.z, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr24.w, hr18.z, (r)(last)hr17.x
mad.f16 hr6.z, hr24.y, hr20.w, (last)hr6.z
mad.f16 hr4.z, hr24.y, hr21.x, (last)hr4.z
mad.f16 hr6.w, hr24.z, hr20.w, (last)hr6.w
mad.f16 hr4.w, hr24.z, hr21.x, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr24.w, hr20.w, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr24.w, hr21.x, (r)(last)hr5.x
mad.f16 hr15.z, hr23.y, hr18.w, (last)hr15.z
mad.f16 hr13.z, hr23.y, hr19.x, (last)hr13.z
mad.f16 hr11.z, hr23.y, hr19.y, (last)hr11.z
mad.f16 hr15.w, hr23.z, hr18.w, (last)hr15.w
mad.f16 hr13.w, hr23.z, hr19.x, (last)hr13.w
mad.f16 hr11.w, hr23.z, hr19.y, (last)hr11.w
mad.f16 hr16.x, hr23.w, hr18.w, (last)hr16.x
mad.f16 hr14.x, hr23.w, hr19.x, (last)hr14.x
mad.f16 hr12.x, hr23.w, hr19.y, (last)hr12.x
mad.f16 hr16.y, hr24.x, hr18.w, (last)hr16.y
mad.f16 hr14.y, hr24.x, hr19.x, (last)hr14.y
mad.f16 hr12.y, hr24.x, hr19.y, (last)hr12.y
(rpt1)mad.f16 hr17.z, (r)hr23.y, hr18.z, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr23.w, hr18.z, (r)(last)hr18.x
(rpt1)mad.f16 hr9.z, (r)hr23.y, hr20.z, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr23.w, hr20.z, (r)(last)hr10.x
mad.f16 hr7.z, hr23.y, hr20.w, (last)hr7.z
mad.f16 hr5.z, hr23.y, hr21.x, (last)hr5.z
mad.f16 hr7.w, hr23.z, hr20.w, (last)hr7.w
mad.f16 hr5.w, hr23.z, hr21.x, (last)hr5.w
mad.f16 hr8.x, hr23.w, hr20.w, (last)hr8.x
mad.f16 hr6.x, hr23.w, hr21.x, (last)hr6.x
mad.f16 hr8.y, hr24.x, hr20.w, (last)hr8.y
mad.f16 hr6.y, hr24.x, hr21.x, (last)hr6.y
(rpt1)mad.f16 hr24.y, (r)(last)hr24.y, hr21.y, (r)(last)hr2.w
(rpt1)mad.f16 hr24.w, (r)(last)hr24.w, hr21.y, (r)(last)hr3.y
(rpt1)mad.f16 hr23.y, (r)(last)hr23.y, hr21.y, (r)(last)hr40.w
(rpt1)mad.f16 hr23.w, (r)(last)hr23.w, hr21.y, (r)(last)hr41.y
fence.r.w
(sy)(ss)mad.f16 hr14.w, hr28.z, hr25.z, (last)hr14.w
mad.f16 hr12.w, hr28.z, hr25.w, (last)hr12.w
mad.f16 hr10.w, hr28.z, hr26.x, (last)hr10.w
(rpt1)mad.f16 hr15.x, (r)hr28.w, hr25.z, (r)(last)hr15.x
(rpt1)mad.f16 hr13.x, (r)hr28.w, hr25.w, (r)(last)hr13.x
(rpt1)mad.f16 hr11.x, (r)hr28.w, hr26.x, (r)(last)hr11.x
mad.f16 hr14.z, hr28.y, hr25.z, (last)hr14.z
mad.f16 hr12.z, hr28.y, hr25.w, (last)hr12.z
mad.f16 hr10.z, hr28.y, hr26.x, (last)hr10.z
(rpt1)mad.f16 hr8.z, (r)hr28.y, hr26.y, (r)(last)hr8.z
(rpt1)mad.f16 hr9.x, (r)hr28.w, hr26.y, (r)(last)hr9.x
(rpt1)mad.f16 hr16.z, (r)hr28.y, hr25.y, (r)(last)hr16.z
(rpt1)mad.f16 hr17.x, (r)hr28.w, hr25.y, (r)(last)hr17.x
mad.f16 hr6.z, hr28.y, hr26.z, (last)hr6.z
mad.f16 hr4.z, hr28.y, hr26.w, (last)hr4.z
mad.f16 hr6.w, hr28.z, hr26.z, (last)hr6.w
mad.f16 hr4.w, hr28.z, hr26.w, (last)hr4.w
(rpt1)mad.f16 hr7.x, (r)hr28.w, hr26.z, (r)(last)hr7.x
(rpt1)mad.f16 hr5.x, (r)hr28.w, hr26.w, (r)(last)hr5.x
mad.f16 hr15.z, hr27.y, hr25.z, (last)hr15.z
mad.f16 hr13.z, hr27.y, hr25.w, (last)hr13.z
mad.f16 hr11.z, hr27.y, hr26.x, (last)hr11.z
mad.f16 hr15.w, hr27.z, hr25.z, (last)hr15.w
mad.f16 hr13.w, hr27.z, hr25.w, (last)hr13.w
mad.f16 hr11.w, hr27.z, hr26.x, (last)hr11.w
mad.f16 hr16.x, hr27.w, hr25.z, (last)hr16.x
mad.f16 hr14.x, hr27.w, hr25.w, (last)hr14.x
mad.f16 hr12.x, hr27.w, hr26.x, (last)hr12.x
mad.f16 hr16.y, hr28.x, hr25.z, (last)hr16.y
mad.f16 hr14.y, hr28.x, hr25.w, (last)hr14.y
mad.f16 hr12.y, hr28.x, hr26.x, (last)hr12.y
(rpt1)mad.f16 hr17.z, (r)hr27.y, hr25.y, (r)(last)hr17.z
(rpt1)mad.f16 hr18.x, (r)hr27.w, hr25.y, (r)(last)hr18.x
(rpt1)mad.f16 hr9.z, (r)hr27.y, hr26.y, (r)(last)hr9.z
(rpt1)mad.f16 hr10.x, (r)hr27.w, hr26.y, (r)(last)hr10.x
mad.f16 hr7.z, hr27.y, hr26.z, (last)hr7.z
mad.f16 hr5.z, hr27.y, hr26.w, (last)hr5.z
mad.f16 hr7.w, hr27.z, hr26.z, (last)hr7.w
mad.f16 hr5.w, hr27.z, hr26.w, (last)hr5.w
mad.f16 hr8.x, hr27.w, hr26.z, (last)hr8.x
mad.f16 hr6.x, hr27.w, hr26.w, (last)hr6.x
mad.f16 hr8.y, hr28.x, hr26.z, (last)hr8.y
mad.f16 hr6.y, hr28.x, hr26.w, (last)hr6.y
(rpt1)mad.f16 hr2.z, (r)(last)hr28.y, hr27.x, (r)(last)hr24.y
(rpt1)mad.f16 hr3.x, (r)(last)hr28.w, hr27.x, (r)(last)hr24.w
(rpt1)mad.f16 hr3.z, (r)(last)hr27.y, hr27.x, (r)(last)hr23.y
(rpt1)mad.f16 hr4.x, (r)(last)hr27.w, hr27.x, (r)(last)hr23.w
bar.g
(sy)(ss)br p0.x, #l1034
jump #l128
l1034:
(jp)(eolm)nop
(nop3) add.u r11.y, r51.w, (last)r11.y
(nop3) shl.b r11.y, (last)r11.y, 9
(nop3) sad.s32 r11.y, r52.w, r11.y, (last)r1.x
(nop3) shl.b r11.y, (last)r11.y, 2
add.u r14.w, r11.y, c1.x
add.u r15.x, r11.y, c8.y
add.u r15.y, r11.y, c4.z
add.u r15.z, r11.y, c8.x
add.u r15.w, r11.y, c4.y
add.u r16.x, r11.y, c7.w
(rpt1)add.u r16.y, r11.y, (r)c8.z
(rpt3)add.u r16.w, r11.y, (r)c9.x
(rpt1)add.u r17.w, r11.y, (r)c10.x
stib.b.untyped.1d.u16.4.imm.base0 hr17.z, r11.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr16.z, r11.y+64, 4
stib.b.untyped.1d.u16.4.imm.base0 hr15.z, r14.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.z, r15.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.z, r15.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.z, r15.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.z, r15.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.z, r16.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.z, r16.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr8.z, r16.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.z, r16.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.z, r17.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.z, r17.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr4.z, r17.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr3.z, r17.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr2.z, r18.x, 4
end
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 1284 instr, 26 nops, 1258 non-nops, 65 mov, 0 cov, 2150 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 21 full, 12 constlen
; CL prog 23/1: 29 cat0, 65 cat1, 74 cat2, 1028 cat3, 0 cat4, 34 cat5, 50 cat6, 4 cat7
; CL prog 23/1: 30 sstall, 17 (ss), 188 systall, 13 (sy), 1 loops
; CL prog 23/1: 12 max_waves, 0 double_threadsize
; 58 preamble-instr, 1 early-preamble
