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
(sy)nop
mov.u16u16 hr20.y, hr2.x
mov.u16u16 hr21.z, hr9.y
mov.u16u16 hr31.w, hr9.y
(rpt5)nop
mov.u16u16 hr2.x, hr21.z
mov.u16u16 hr2.y, hr21.z
mov.u16u16 hr2.z, hr21.z
mov.u16u16 hr2.w, hr21.z
mov.u16u16 hr3.x, hr21.z
mov.u16u16 hr3.y, hr21.z
mov.u16u16 hr3.z, hr21.z
mov.u16u16 hr3.w, hr21.z
mov.u16u16 hr4.x, hr21.z
mov.u16u16 hr4.y, hr21.z
mov.u16u16 hr4.z, hr21.z
mov.u16u16 hr4.w, hr21.z
mov.u16u16 hr5.x, hr21.z
mov.u16u16 hr5.y, hr21.z
mov.u16u16 hr5.z, hr21.z
mov.u16u16 hr5.w, hr21.z
mov.u16u16 hr6.x, hr21.z
mov.u16u16 hr6.y, hr21.z
mov.u16u16 hr6.z, hr21.z
mov.u16u16 hr6.w, hr21.z
mov.u16u16 hr7.x, hr21.z
mov.u16u16 hr7.y, hr21.z
mov.u16u16 hr7.z, hr21.z
mov.u16u16 hr7.w, hr21.z
mov.u16u16 hr8.x, hr21.z
mov.u16u16 hr8.y, hr21.z
mov.u16u16 hr8.z, hr21.z
mov.u16u16 hr8.w, hr21.z
mov.u16u16 hr9.x, hr21.z
mov.u16u16 hr9.y, hr21.z
mov.u16u16 hr9.z, hr21.z
mov.u16u16 hr9.w, hr21.z
mov.u16u16 hr10.x, hr21.z
mov.u16u16 hr10.y, hr21.z
mov.u16u16 hr10.z, hr21.z
mov.u16u16 hr10.w, hr21.z
mov.u16u16 hr11.x, hr21.z
mov.u16u16 hr11.y, hr21.z
mov.u16u16 hr11.z, hr21.z
mov.u16u16 hr11.w, hr21.z
mov.u16u16 hr12.x, hr21.z
mov.u16u16 hr12.y, hr21.z
mov.u16u16 hr12.z, hr21.z
mov.u16u16 hr12.w, hr21.z
mov.u16u16 hr13.x, hr21.z
mov.u16u16 hr13.y, hr21.z
mov.u16u16 hr13.z, hr21.z
mov.u16u16 hr13.w, hr21.z
mov.u16u16 hr14.x, hr21.z
mov.u16u16 hr14.y, hr21.z
mov.u16u16 hr14.z, hr21.z
mov.u16u16 hr14.w, hr21.z
mov.u16u16 hr15.x, hr21.z
mov.u16u16 hr15.y, hr21.z
mov.u16u16 hr15.z, hr21.z
mov.u16u16 hr15.w, hr21.z
mov.u16u16 hr16.x, hr21.z
mov.u16u16 hr16.y, hr21.z
mov.u16u16 hr16.z, hr21.z
mov.u16u16 hr16.w, hr21.z
mov.u16u16 hr17.x, hr21.z
mov.u16u16 hr17.y, hr21.z
mov.u16u16 hr17.z, hr21.z
mov.u16u16 hr17.w, hr21.z
(rpt5)nop
l98:
add.u r52.z, r52.z, 1
cmps.s.ge up0.y, r52.z, c1.x
mad.f16 hr2.x, hr20.y, hr21.z, hr2.x
mad.f16 hr2.y, hr20.y, hr21.z, hr2.y
mad.f16 hr2.z, hr20.y, hr21.z, hr2.z
mad.f16 hr2.w, hr20.y, hr21.z, hr2.w
mad.f16 hr3.x, hr20.y, hr21.z, hr3.x
mad.f16 hr3.y, hr20.y, hr21.z, hr3.y
mad.f16 hr3.z, hr20.y, hr21.z, hr3.z
mad.f16 hr3.w, hr20.y, hr21.z, hr3.w
mad.f16 hr4.x, hr20.y, hr21.z, hr4.x
mad.f16 hr4.y, hr20.y, hr21.z, hr4.y
mad.f16 hr4.z, hr20.y, hr21.z, hr4.z
mad.f16 hr4.w, hr20.y, hr21.z, hr4.w
mad.f16 hr5.x, hr20.y, hr21.z, hr5.x
mad.f16 hr5.y, hr20.y, hr21.z, hr5.y
mad.f16 hr5.z, hr20.y, hr21.z, hr5.z
mad.f16 hr5.w, hr20.y, hr21.z, hr5.w
mad.f16 hr6.x, hr20.y, hr21.z, hr6.x
mad.f16 hr6.y, hr20.y, hr21.z, hr6.y
mad.f16 hr6.z, hr20.y, hr21.z, hr6.z
mad.f16 hr6.w, hr20.y, hr21.z, hr6.w
mad.f16 hr7.x, hr20.y, hr21.z, hr7.x
mad.f16 hr7.y, hr20.y, hr21.z, hr7.y
mad.f16 hr7.z, hr20.y, hr21.z, hr7.z
mad.f16 hr7.w, hr20.y, hr21.z, hr7.w
mad.f16 hr8.x, hr20.y, hr21.z, hr8.x
mad.f16 hr8.y, hr20.y, hr21.z, hr8.y
mad.f16 hr8.z, hr20.y, hr21.z, hr8.z
mad.f16 hr8.w, hr20.y, hr21.z, hr8.w
mad.f16 hr9.x, hr20.y, hr21.z, hr9.x
mad.f16 hr9.y, hr20.y, hr21.z, hr9.y
mad.f16 hr9.z, hr20.y, hr21.z, hr9.z
mad.f16 hr9.w, hr20.y, hr21.z, hr9.w
mad.f16 hr10.x, hr20.y, hr21.z, hr10.x
mad.f16 hr10.y, hr20.y, hr21.z, hr10.y
mad.f16 hr10.z, hr20.y, hr21.z, hr10.z
mad.f16 hr10.w, hr20.y, hr21.z, hr10.w
mad.f16 hr11.x, hr20.y, hr21.z, hr11.x
mad.f16 hr11.y, hr20.y, hr21.z, hr11.y
mad.f16 hr11.z, hr20.y, hr21.z, hr11.z
mad.f16 hr11.w, hr20.y, hr21.z, hr11.w
mad.f16 hr12.x, hr20.y, hr21.z, hr12.x
mad.f16 hr12.y, hr20.y, hr21.z, hr12.y
mad.f16 hr12.z, hr20.y, hr21.z, hr12.z
mad.f16 hr12.w, hr20.y, hr21.z, hr12.w
mad.f16 hr13.x, hr20.y, hr21.z, hr13.x
mad.f16 hr13.y, hr20.y, hr21.z, hr13.y
mad.f16 hr13.z, hr20.y, hr21.z, hr13.z
mad.f16 hr13.w, hr20.y, hr21.z, hr13.w
mad.f16 hr14.x, hr20.y, hr21.z, hr14.x
mad.f16 hr14.y, hr20.y, hr21.z, hr14.y
mad.f16 hr14.z, hr20.y, hr21.z, hr14.z
mad.f16 hr14.w, hr20.y, hr21.z, hr14.w
mad.f16 hr15.x, hr20.y, hr21.z, hr15.x
mad.f16 hr15.y, hr20.y, hr21.z, hr15.y
mad.f16 hr15.z, hr20.y, hr21.z, hr15.z
mad.f16 hr15.w, hr20.y, hr21.z, hr15.w
mad.f16 hr16.x, hr20.y, hr21.z, hr16.x
mad.f16 hr16.y, hr20.y, hr21.z, hr16.y
mad.f16 hr16.z, hr20.y, hr21.z, hr16.z
mad.f16 hr16.w, hr20.y, hr21.z, hr16.w
mad.f16 hr17.x, hr20.y, hr21.z, hr17.x
mad.f16 hr17.y, hr20.y, hr21.z, hr17.y
mad.f16 hr17.z, hr20.y, hr21.z, hr17.z
mad.f16 hr17.w, hr20.y, hr21.z, hr17.w
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
