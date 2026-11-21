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
@const(c1.x)	0x00000200, 0x3a800000, 0x40400000, 0x40a00000
@const(c2.x)	0x40c00000, 0x40e00000, 0x41000000, 0x41100000
@const(c3.x)	0x41200000, 0x41300000, 0x41400000, 0x41500000
@const(c4.x)	0x41600000, 0x41700000, 0x449a4000, 0xd0d0d0d0
shps #l27
getone #l27
mov.u32u32 r48.w, 512
mov.u32u32 r49.x, 0x3a800000
mov.u32u32 r49.y, 0x40400000
mov.u32u32 r49.z, 0x40a00000
mov.u32u32 r49.w, 0x40c00000
mov.u32u32 r50.x, 0x40e00000
mov.u32u32 r50.y, 0x41000000
mov.u32u32 r50.z, 0x41100000
mov.u32u32 r50.w, 0x41200000
mov.u32u32 r51.x, 0x41300000
mov.u32u32 r51.y, 0x41400000
mov.u32u32 r51.z, 0x41500000
mov.u32u32 r51.w, 0x41600000
mov.u32u32 r52.x, 0x41700000
mov.u32u32 r52.y, 0x449a4000
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 3
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l27:
(jp)mov.u32u32 r52.z, 0
add.u r1.y, r0.x, 1
cov.u32f16 hr3.x, r0.x
(nop1) and.b r0.w, r0.x, 1
and.b r1.y, (last)r1.y, 1
(nop3) mul.f hr3.y, (last)hr3.x, hc1.y
add.f hr4.y, hr3.y, hc4.y
isam.v.base0 (u16)(x)hr2.x, r0.w, s#0, t#0
add.f hr4.x, hr3.y, hc4.x
isam.v.base0 (u16)(x)hr9.y, r1.y, s#0, t#0
add.f hr3.w, hr3.y, hc3.w
add.f hr5.z, hr3.y, hc3.z
add.f hr5.y, hr3.y, hc3.y
add.f hr5.x, hr3.y, hc3.x
add.f hr4.w, hr3.y, hc2.w
add.f hr6.w, hr3.y, hc2.z
add.f hr6.z, hr3.y, hc2.y
add.f hr6.y, hr3.y, hc2.x
add.f hr6.x, hr3.y, hc1.w
add.f hr7.y, hr3.y, h(4.0)
add.f hr7.w, hr3.y, hc1.z
add.f hr8.y, hr3.y, h(2.0)
add.f hr8.w, hr3.y, h(1.0)
mov.u16u16 hr19.y, hr3.y
mov.u16u16 hr19.x, hr3.y
mov.u16u16 hr3.z, hr3.y
mov.u16u16 hr4.z, hr4.y
mov.u16u16 hr9.w, hr4.y
mov.u16u16 hr9.z, hr4.y
mov.u16u16 hr10.z, hr4.x
mov.u16u16 hr10.y, hr4.x
mov.u16u16 hr10.x, hr4.x
mov.u16u16 hr11.y, hr3.w
mov.u16u16 hr11.x, hr3.w
mov.u16u16 hr10.w, hr3.w
mov.u16u16 hr11.w, hr5.z
mov.u16u16 hr11.z, hr5.z
mov.u16u16 hr5.w, hr5.z
mov.u16u16 hr12.z, hr5.y
mov.u16u16 hr12.y, hr5.y
mov.u16u16 hr12.x, hr5.y
mov.u16u16 hr13.y, hr5.x
mov.u16u16 hr13.x, hr5.x
mov.u16u16 hr12.w, hr5.x
mov.u16u16 hr14.x, hr4.w
mov.u16u16 hr13.w, hr4.w
mov.u16u16 hr13.z, hr4.w
mov.u16u16 hr14.z, hr6.w
mov.u16u16 hr14.y, hr6.w
mov.u16u16 hr7.x, hr6.w
mov.u16u16 hr15.y, hr6.z
mov.u16u16 hr15.x, hr6.z
mov.u16u16 hr14.w, hr6.z
mov.u16u16 hr16.x, hr6.y
mov.u16u16 hr15.w, hr6.y
mov.u16u16 hr15.z, hr6.y
mov.u16u16 hr16.w, hr6.x
mov.u16u16 hr16.z, hr6.x
mov.u16u16 hr16.y, hr6.x
mov.u16u16 hr17.y, hr7.y
mov.u16u16 hr17.x, hr7.y
mov.u16u16 hr7.z, hr7.y
mov.u16u16 hr17.w, hr7.w
mov.u16u16 hr17.z, hr7.w
mov.u16u16 hr8.x, hr7.w
mov.u16u16 hr18.y, hr8.y
mov.u16u16 hr18.x, hr8.y
mov.u16u16 hr8.z, hr8.y
mov.u16u16 hr18.w, hr8.w
mov.u16u16 hr18.z, hr8.w
mov.u16u16 hr9.x, hr8.w
l98:
add.u r52.z, r52.z, 1
cmps.s.ge up0.y, r52.z, c1.x
(sy)(rpt1)mad.f16 hr4.y, (r)(last)hr4.y, hr2.x, hr9.y
(rpt1)mad.f16 hr9.z, (r)(last)hr9.z, hr2.x, hr9.y
mad.f16 hr4.x, (last)hr4.x, hr2.x, hr9.y
mad.f16 hr10.x, (last)hr10.x, hr2.x, hr9.y
(rpt1)mad.f16 hr10.y, (r)(last)hr10.y, hr2.x, hr9.y
mad.f16 hr3.w, (last)hr3.w, hr2.x, hr9.y
mad.f16 hr10.w, (last)hr10.w, hr2.x, hr9.y
(rpt1)mad.f16 hr11.x, (r)(last)hr11.x, hr2.x, hr9.y
(rpt1)mad.f16 hr5.z, (r)(last)hr5.z, hr2.x, hr9.y
(rpt1)mad.f16 hr11.z, (r)(last)hr11.z, hr2.x, hr9.y
mad.f16 hr5.y, (last)hr5.y, hr2.x, hr9.y
mad.f16 hr12.x, (last)hr12.x, hr2.x, hr9.y
(rpt1)mad.f16 hr12.y, (r)(last)hr12.y, hr2.x, hr9.y
mad.f16 hr5.x, (last)hr5.x, hr2.x, hr9.y
mad.f16 hr12.w, (last)hr12.w, hr2.x, hr9.y
(rpt1)mad.f16 hr13.x, (r)(last)hr13.x, hr2.x, hr9.y
mad.f16 hr4.w, (last)hr4.w, hr2.x, hr9.y
mad.f16 hr13.z, (last)hr13.z, hr2.x, hr9.y
(rpt1)mad.f16 hr13.w, (r)(last)hr13.w, hr2.x, hr9.y
(rpt1)mad.f16 hr6.w, (r)(last)hr6.w, hr2.x, hr9.y
(rpt1)mad.f16 hr14.y, (r)(last)hr14.y, hr2.x, hr9.y
mad.f16 hr6.z, (last)hr6.z, hr2.x, hr9.y
mad.f16 hr14.w, (last)hr14.w, hr2.x, hr9.y
(rpt1)mad.f16 hr15.x, (r)(last)hr15.x, hr2.x, hr9.y
mad.f16 hr6.y, (last)hr6.y, hr2.x, hr9.y
mad.f16 hr15.z, (last)hr15.z, hr2.x, hr9.y
(rpt1)mad.f16 hr15.w, (r)(last)hr15.w, hr2.x, hr9.y
mad.f16 hr6.x, (last)hr6.x, hr2.x, hr9.y
mad.f16 hr16.y, (last)hr16.y, hr2.x, hr9.y
(rpt1)mad.f16 hr16.z, (r)(last)hr16.z, hr2.x, hr9.y
(rpt1)mad.f16 hr7.y, (r)(last)hr7.y, hr2.x, hr9.y
(rpt1)mad.f16 hr17.x, (r)(last)hr17.x, hr2.x, hr9.y
(rpt1)mad.f16 hr7.w, (r)(last)hr7.w, hr2.x, hr9.y
(rpt1)mad.f16 hr17.z, (r)(last)hr17.z, hr2.x, hr9.y
(rpt1)mad.f16 hr8.y, (r)(last)hr8.y, hr2.x, hr9.y
(rpt1)mad.f16 hr18.x, (r)(last)hr18.x, hr2.x, hr9.y
(rpt1)mad.f16 hr8.w, (r)(last)hr8.w, hr2.x, hr9.y
(rpt1)mad.f16 hr18.z, (r)(last)hr18.z, hr2.x, hr9.y
(rpt1)mad.f16 hr3.y, (r)(last)hr3.y, hr2.x, hr9.y
(rpt1)mad.f16 hr19.x, (r)(last)hr19.x, hr2.x, hr9.y
(ss)br p0.y, #l142
jump #l98
l142:
(jp)(rpt1)add.f hr3.y, (last)(r)hr3.y, (last)(r)hr8.w
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr18.z
(rpt1)add.f hr3.y, (last)(r)hr3.y, (last)(r)hr8.y
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr18.x
(rpt1)add.f hr3.y, (last)(r)hr3.y, (last)(r)hr7.w
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr17.z
(rpt1)add.f hr3.y, (last)(r)hr3.y, (last)(r)hr7.y
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr17.x
add.f hr3.y, (last)hr3.y, (last)hr6.x
add.f hr3.z, (last)hr3.z, (last)hr16.y
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr16.z
add.f hr3.y, (last)hr3.y, (last)hr6.y
add.f hr3.z, (last)hr3.z, (last)hr15.z
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr15.w
add.f hr3.y, (last)hr3.y, (last)hr6.z
add.f hr3.z, (last)hr3.z, (last)hr14.w
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr15.x
(rpt1)add.f hr3.y, (last)(r)hr3.y, (last)(r)hr6.w
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr14.y
add.f hr3.y, (last)hr3.y, (last)hr4.w
add.f hr3.z, (last)hr3.z, (last)hr13.z
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr13.w
add.f hr3.y, (last)hr3.y, (last)hr5.x
add.f hr3.z, (last)hr3.z, (last)hr12.w
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr13.x
add.f hr3.y, (last)hr3.y, (last)hr5.y
add.f hr3.z, (last)hr3.z, (last)hr12.x
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr12.y
(rpt1)add.f hr3.y, (last)(r)hr3.y, (last)(r)hr5.z
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr11.z
add.f hr3.y, (last)hr3.y, (last)hr3.w
add.f hr3.z, (last)hr3.z, (last)hr10.w
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr11.x
add.f hr3.y, (last)hr3.y, (last)hr4.x
add.f hr3.z, (last)hr3.z, (last)hr10.x
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr10.y
(rpt1)add.f hr3.y, (last)(r)hr3.y, (last)(r)hr4.y
(rpt1)add.f hr19.x, (last)(r)hr19.x, (last)(r)hr9.z
nop
(nop3) add.f hr3.y, (last)hr3.y, (last)hr3.z
(nop3) add.f hr3.y, (last)hr3.y, (last)hr19.x
(nop3) add.f r9.w, (last)hr3.y, (last)hr19.y
(nop3) cmps.f.eq p0.x, r9.w, c4.z
(rpt2)nop
predt
add.u r48.x, r48.x, c0.x
shl.b r48.x, r48.x, 7
(ss)(nop3) add.u r0.x, r48.x, (last)r0.x
(rpt2)nop
stib.b.untyped.1d.u32.1.imm.base0 r9.w, r0.x, 4
prede
(eogm)(rpt6)nop
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
; CL prog 23/1: 243 instr, 33 nops, 210 non-nops, 49 mov, 1 cov, 416 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 10 full, 8 constlen
; CL prog 23/1: 38 cat0, 50 cat1, 88 cat2, 64 cat3, 0 cat4, 2 cat5, 1 cat6, 0 cat7
; CL prog 23/1: 6 sstall, 2 (ss), 0 systall, 1 (sy), 1 loops
; CL prog 23/1: 16 max_waves, 0 double_threadsize
; 27 preamble-instr, 1 early-preamble
