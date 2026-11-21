; num_ubos:           0
; num_driver_params:  0
; offsets:
;   ubo_ranges                 c4.x (1 vec4)
;   preamble                   c0.x (4 vec4)
; ubo_state:
;   num_enabled:      1
;   range[0]:
;     block:          1
;     offset:         c4.x
;     size:           1 vec4 (16b -> 32b)
@in(r0.x)	in0 (wrmask=0x7)
@in(r48.x)	in1 (wrmask=0x7)
@const(c5.x)	0x00000200, 0x3a800000, 0x40400000, 0x40a00000
@const(c6.x)	0x40c00000, 0x40e00000, 0x41000000, 0x41100000
@const(c7.x)	0x41200000, 0x41300000, 0x41400000, 0x41500000
@const(c8.x)	0x41600000, 0x41700000, 0x449a4000, 0xd0d0d0d0
shps #l34
getone #l34
alias.tex.b32.0 r40.x, (0x0)
isam.v.base0 (u16)(xy)hr1.z, r40.x, s#0, t#0
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
mova1 a1.x, 16
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[20], r48.w, 4
stc.u32 c[24], r49.w, 4
stc.u32 c[28], r50.w, 4
stc.u32 c[32], r51.w, 3
(sy)(ss)mov.u16u16 hr49.z, (last)hr1.z
mov.u16u16 hr49.w, (last)hr1.w
(ss)(rpt1)cov.f16f32 r49.x, (r)hr49.z
(ss)nop
stc.u32 c[0], r49.x, 2
(rpt1)nop
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l34:
(jp)mov.u32u32 r49.z, 0
cov.u32f16 hr1.z, r0.x
(rpt2)nop
(nop3) mul.f hr1.w, (last)hr1.z, hc5.y
add.f hr2.w, hr1.w, hc8.y
add.f hr2.z, hr1.w, hc8.x
add.f hr2.y, hr1.w, hc7.w
add.f hr4.x, hr1.w, hc7.z
add.f hr3.w, hr1.w, hc7.y
add.f hr3.z, hr1.w, hc7.x
add.f hr3.y, hr1.w, hc6.w
add.f hr5.y, hr1.w, hc6.z
add.f hr5.x, hr1.w, hc6.y
add.f hr4.w, hr1.w, hc6.x
add.f hr4.z, hr1.w, hc5.w
add.f hr5.w, hr1.w, h(4.0)
add.f hr6.y, hr1.w, hc5.z
add.f hr6.w, hr1.w, h(2.0)
add.f hr7.y, hr1.w, h(1.0)
mov.u16u16 hr17.z, hr1.w
mov.u16u16 hr17.y, hr1.w
mov.u16u16 hr2.x, hr1.w
mov.u16u16 hr3.x, hr2.w
mov.u16u16 hr8.x, hr2.w
mov.u16u16 hr7.w, hr2.w
mov.u16u16 hr8.w, hr2.z
mov.u16u16 hr8.z, hr2.z
mov.u16u16 hr8.y, hr2.z
mov.u16u16 hr9.z, hr2.y
mov.u16u16 hr9.y, hr2.y
mov.u16u16 hr9.x, hr2.y
mov.u16u16 hr10.x, hr4.x
mov.u16u16 hr9.w, hr4.x
mov.u16u16 hr4.y, hr4.x
mov.u16u16 hr10.w, hr3.w
mov.u16u16 hr10.z, hr3.w
mov.u16u16 hr10.y, hr3.w
mov.u16u16 hr11.z, hr3.z
mov.u16u16 hr11.y, hr3.z
mov.u16u16 hr11.x, hr3.z
mov.u16u16 hr12.y, hr3.y
mov.u16u16 hr12.x, hr3.y
mov.u16u16 hr11.w, hr3.y
mov.u16u16 hr12.w, hr5.y
mov.u16u16 hr12.z, hr5.y
mov.u16u16 hr5.z, hr5.y
mov.u16u16 hr13.z, hr5.x
mov.u16u16 hr13.y, hr5.x
mov.u16u16 hr13.x, hr5.x
mov.u16u16 hr14.y, hr4.w
mov.u16u16 hr14.x, hr4.w
mov.u16u16 hr13.w, hr4.w
mov.u16u16 hr15.x, hr4.z
mov.u16u16 hr14.w, hr4.z
mov.u16u16 hr14.z, hr4.z
mov.u16u16 hr15.z, hr5.w
mov.u16u16 hr15.y, hr5.w
mov.u16u16 hr6.x, hr5.w
mov.u16u16 hr16.x, hr6.y
mov.u16u16 hr15.w, hr6.y
mov.u16u16 hr6.z, hr6.y
mov.u16u16 hr16.z, hr6.w
mov.u16u16 hr16.y, hr6.w
mov.u16u16 hr7.x, hr6.w
mov.u16u16 hr17.x, hr7.y
mov.u16u16 hr16.w, hr7.y
mov.u16u16 hr7.z, hr7.y
l101:
add.u r49.z, r49.z, 1
cmps.s.ge up0.y, r49.z, c5.x
(rpt1)mad.f16 hr2.w, hc0.x, (r)hr2.w, hc0.y
(rpt1)mad.f16 hr7.w, hc0.x, (r)hr7.w, hc0.y
mad.f16 hr2.z, hc0.x, hr2.z, hc0.y
mad.f16 hr8.y, hc0.x, hr8.y, hc0.y
(rpt1)mad.f16 hr8.z, hc0.x, (r)hr8.z, hc0.y
mad.f16 hr2.y, hc0.x, hr2.y, hc0.y
mad.f16 hr9.x, hc0.x, hr9.x, hc0.y
(rpt1)mad.f16 hr9.y, hc0.x, (r)hr9.y, hc0.y
(rpt1)mad.f16 hr4.x, hc0.x, (r)hr4.x, hc0.y
(rpt1)mad.f16 hr9.w, hc0.x, (r)hr9.w, hc0.y
mad.f16 hr3.w, hc0.x, hr3.w, hc0.y
mad.f16 hr10.y, hc0.x, hr10.y, hc0.y
(rpt1)mad.f16 hr10.z, hc0.x, (r)hr10.z, hc0.y
mad.f16 hr3.z, hc0.x, hr3.z, hc0.y
mad.f16 hr11.x, hc0.x, hr11.x, hc0.y
(rpt1)mad.f16 hr11.y, hc0.x, (r)hr11.y, hc0.y
mad.f16 hr3.y, hc0.x, hr3.y, hc0.y
mad.f16 hr11.w, hc0.x, hr11.w, hc0.y
(rpt1)mad.f16 hr12.x, hc0.x, (r)hr12.x, hc0.y
(rpt1)mad.f16 hr5.y, hc0.x, (r)hr5.y, hc0.y
(rpt1)mad.f16 hr12.z, hc0.x, (r)hr12.z, hc0.y
mad.f16 hr5.x, hc0.x, hr5.x, hc0.y
mad.f16 hr13.x, hc0.x, hr13.x, hc0.y
(rpt1)mad.f16 hr13.y, hc0.x, (r)hr13.y, hc0.y
mad.f16 hr4.w, hc0.x, hr4.w, hc0.y
mad.f16 hr13.w, hc0.x, hr13.w, hc0.y
(rpt1)mad.f16 hr14.x, hc0.x, (r)hr14.x, hc0.y
mad.f16 hr4.z, hc0.x, hr4.z, hc0.y
mad.f16 hr14.z, hc0.x, hr14.z, hc0.y
(rpt1)mad.f16 hr14.w, hc0.x, (r)hr14.w, hc0.y
(rpt1)mad.f16 hr5.w, hc0.x, (r)hr5.w, hc0.y
(rpt1)mad.f16 hr15.y, hc0.x, (r)hr15.y, hc0.y
(rpt1)mad.f16 hr6.y, hc0.x, (r)hr6.y, hc0.y
(rpt1)mad.f16 hr15.w, hc0.x, (r)hr15.w, hc0.y
(rpt1)mad.f16 hr6.w, hc0.x, (r)hr6.w, hc0.y
(rpt1)mad.f16 hr16.y, hc0.x, (r)hr16.y, hc0.y
(rpt1)mad.f16 hr7.y, hc0.x, (r)hr7.y, hc0.y
(rpt1)mad.f16 hr16.w, hc0.x, (r)hr16.w, hc0.y
(rpt1)mad.f16 hr1.w, hc0.x, (r)hr1.w, hc0.y
(rpt1)mad.f16 hr17.y, hc0.x, (r)hr17.y, hc0.y
(ss)br p0.y, #l145
jump #l101
l145:
(jp)(rpt1)add.f hr1.w, (last)(r)hr1.w, (last)(r)hr7.y
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr16.w
(rpt1)add.f hr1.w, (last)(r)hr1.w, (last)(r)hr6.w
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr16.y
(rpt1)add.f hr1.w, (last)(r)hr1.w, (last)(r)hr6.y
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr15.w
(rpt1)add.f hr1.w, (last)(r)hr1.w, (last)(r)hr5.w
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr15.y
add.f hr1.w, (last)hr1.w, (last)hr4.z
add.f hr2.x, (last)hr2.x, (last)hr14.z
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr14.w
add.f hr1.w, (last)hr1.w, (last)hr4.w
add.f hr2.x, (last)hr2.x, (last)hr13.w
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr14.x
add.f hr1.w, (last)hr1.w, (last)hr5.x
add.f hr2.x, (last)hr2.x, (last)hr13.x
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr13.y
(rpt1)add.f hr1.w, (last)(r)hr1.w, (last)(r)hr5.y
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr12.z
add.f hr1.w, (last)hr1.w, (last)hr3.y
add.f hr2.x, (last)hr2.x, (last)hr11.w
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr12.x
add.f hr1.w, (last)hr1.w, (last)hr3.z
add.f hr2.x, (last)hr2.x, (last)hr11.x
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr11.y
add.f hr1.w, (last)hr1.w, (last)hr3.w
add.f hr2.x, (last)hr2.x, (last)hr10.y
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr10.z
(rpt1)add.f hr1.w, (last)(r)hr1.w, (last)(r)hr4.x
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr9.w
add.f hr1.w, (last)hr1.w, (last)hr2.y
add.f hr2.x, (last)hr2.x, (last)hr9.x
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr9.y
add.f hr1.w, (last)hr1.w, (last)hr2.z
add.f hr2.x, (last)hr2.x, (last)hr8.y
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr8.z
(rpt1)add.f hr1.w, (last)(r)hr1.w, (last)(r)hr2.w
(rpt1)add.f hr17.y, (last)(r)hr17.y, (last)(r)hr7.w
nop
(nop3) add.f hr1.w, (last)hr1.w, (last)hr2.x
(nop3) add.f hr1.w, (last)hr1.w, (last)hr17.y
(nop3) add.f r9.x, (last)hr1.w, (last)hr17.z
(nop3) cmps.f.eq p0.x, r9.x, c8.z
(rpt2)nop
predt
add.u r48.x, r48.x, c4.x
shl.b r48.x, r48.x, 7
(ss)(nop3) add.u r0.x, r48.x, (last)r0.x
(rpt2)nop
stib.b.untyped.1d.u32.1.imm.base0 r9.x, r0.x, 4
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
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 240 instr, 35 nops, 205 non-nops, 49 mov, 1 cov, 416 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 10 full, 12 constlen
; CL prog 23/1: 40 cat0, 50 cat1, 85 cat2, 64 cat3, 0 cat4, 0 cat5, 1 cat6, 0 cat7
; CL prog 23/1: 6 sstall, 2 (ss), 0 systall, 0 (sy), 1 loops
; CL prog 23/1: 16 max_waves, 0 double_threadsize
; 36 preamble-instr, 0 early-preamble
