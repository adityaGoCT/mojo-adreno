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
shps #l35
getone #l35
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
stc.u32 c[0], r49.x, 1
stc.u32 c[1], r49.y, 1
(rpt1)nop
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l35:
(jp)mov.u32u32 r49.z, 0
cov.u32f32 r0.w, r0.x
(rpt2)nop
(nop3) mul.f r1.x, (last)r0.w, c5.y
add.f r2.x, r1.x, c8.y
add.f r1.w, r1.x, c8.x
add.f r1.z, r1.x, c7.w
add.f r3.y, r1.x, c7.z
add.f r3.x, r1.x, c7.y
add.f r2.w, r1.x, c7.x
add.f r2.z, r1.x, c6.w
add.f r4.z, r1.x, c6.z
add.f r4.y, r1.x, c6.y
add.f r4.x, r1.x, c6.x
add.f r3.w, r1.x, c5.w
add.f r5.x, r1.x, (4.0)
add.f r5.z, r1.x, c5.z
add.f r6.x, r1.x, (2.0)
add.f r6.z, r1.x, (1.0)
mov.u32u32 r1.y, r1.x
mov.u32u32 r2.y, r2.x
mov.u32u32 r7.x, r1.w
mov.u32u32 r7.y, r1.z
mov.u32u32 r3.z, r3.y
mov.u32u32 r7.z, r3.x
mov.u32u32 r7.w, r2.w
mov.u32u32 r8.x, r2.z
mov.u32u32 r4.w, r4.z
mov.u32u32 r8.y, r4.y
mov.u32u32 r8.z, r4.x
mov.u32u32 r8.w, r3.w
mov.u32u32 r5.y, r5.x
mov.u32u32 r5.w, r5.z
mov.u32u32 r6.y, r6.x
mov.u32u32 r6.w, r6.z
cov.f32f16 hr18.x, c0.x
cov.f32f16 hr18.y, c0.x
cov.f32f16 hr18.z, c0.x
cov.f32f16 hr18.w, c0.x
cov.f32f16 hr19.x, c0.y
cov.f32f16 hr19.y, c0.y
cov.f32f16 hr19.z, c0.y
cov.f32f16 hr19.w, c0.y
cov.f32f16 hr20.x, c0.y
cov.f32f16 hr20.y, c0.y
cov.f32f16 hr20.z, c0.y
cov.f32f16 hr20.w, c0.y
(rpt5)nop
l70:
add.u r49.z, r49.z, 1
cmps.s.ge up0.y, r49.z, c5.x
mad.f16 hr2.x, hr18.y, hr20.y, hr2.x
mad.f16 hr2.y, hr18.z, hr20.z, hr2.y
mad.f16 hr2.z, hr18.w, hr20.w, hr2.z
mad.f16 hr2.w, hr18.x, hr20.x, hr2.w
mad.f16 hr3.x, hr18.y, hr20.y, hr3.x
mad.f16 hr3.y, hr18.z, hr20.z, hr3.y
mad.f16 hr3.z, hr18.w, hr20.w, hr3.z
mad.f16 hr3.w, hr18.x, hr20.x, hr3.w
mad.f16 hr4.x, hr18.y, hr20.y, hr4.x
mad.f16 hr4.y, hr18.z, hr20.z, hr4.y
mad.f16 hr4.z, hr18.w, hr20.w, hr4.z
mad.f16 hr4.w, hr18.x, hr20.x, hr4.w
mad.f16 hr5.x, hr18.y, hr20.y, hr5.x
mad.f16 hr5.y, hr18.z, hr20.z, hr5.y
mad.f16 hr5.z, hr18.w, hr20.w, hr5.z
mad.f16 hr5.w, hr18.x, hr20.x, hr5.w
mad.f16 hr6.x, hr18.y, hr20.y, hr6.x
mad.f16 hr6.y, hr18.z, hr20.z, hr6.y
mad.f16 hr6.z, hr18.w, hr20.w, hr6.z
mad.f16 hr6.w, hr18.x, hr20.x, hr6.w
mad.f16 hr7.x, hr18.y, hr20.y, hr7.x
mad.f16 hr7.y, hr18.z, hr20.z, hr7.y
mad.f16 hr7.z, hr18.w, hr20.w, hr7.z
mad.f16 hr7.w, hr18.x, hr20.x, hr7.w
mad.f16 hr8.x, hr18.y, hr20.y, hr8.x
mad.f16 hr8.y, hr18.z, hr20.z, hr8.y
mad.f16 hr8.z, hr18.w, hr20.w, hr8.z
mad.f16 hr8.w, hr18.x, hr20.x, hr8.w
mad.f16 hr9.x, hr18.y, hr20.y, hr9.x
mad.f16 hr9.y, hr18.z, hr20.z, hr9.y
mad.f16 hr9.z, hr18.w, hr20.w, hr9.z
mad.f16 hr9.w, hr18.x, hr20.x, hr9.w
mad.f16 hr10.x, hr18.y, hr20.y, hr10.x
mad.f16 hr10.y, hr18.z, hr20.z, hr10.y
mad.f16 hr10.z, hr18.w, hr20.w, hr10.z
mad.f16 hr10.w, hr18.x, hr20.x, hr10.w
mad.f16 hr11.x, hr18.y, hr20.y, hr11.x
mad.f16 hr11.y, hr18.z, hr20.z, hr11.y
mad.f16 hr11.z, hr18.w, hr20.w, hr11.z
mad.f16 hr11.w, hr18.x, hr20.x, hr11.w
mad.f16 hr12.x, hr18.y, hr20.y, hr12.x
mad.f16 hr12.y, hr18.z, hr20.z, hr12.y
mad.f16 hr12.z, hr18.w, hr20.w, hr12.z
mad.f16 hr12.w, hr18.x, hr20.x, hr12.w
mad.f16 hr13.x, hr18.y, hr20.y, hr13.x
mad.f16 hr13.y, hr18.z, hr20.z, hr13.y
mad.f16 hr13.z, hr18.w, hr20.w, hr13.z
mad.f16 hr13.w, hr18.x, hr20.x, hr13.w
mad.f16 hr14.x, hr18.y, hr20.y, hr14.x
mad.f16 hr14.y, hr18.z, hr20.z, hr14.y
mad.f16 hr14.z, hr18.w, hr20.w, hr14.z
mad.f16 hr14.w, hr18.x, hr20.x, hr14.w
mad.f16 hr15.x, hr18.y, hr20.y, hr15.x
mad.f16 hr15.y, hr18.z, hr20.z, hr15.y
mad.f16 hr15.z, hr18.w, hr20.w, hr15.z
mad.f16 hr15.w, hr18.x, hr20.x, hr15.w
mad.f16 hr16.x, hr18.y, hr20.y, hr16.x
mad.f16 hr16.y, hr18.z, hr20.z, hr16.y
mad.f16 hr16.z, hr18.w, hr20.w, hr16.z
mad.f16 hr16.w, hr18.x, hr20.x, hr16.w
mad.f16 hr17.x, hr18.y, hr20.y, hr17.x
mad.f16 hr17.y, hr18.z, hr20.z, hr17.y
mad.f16 hr17.z, hr18.w, hr20.w, hr17.z
mad.f16 hr17.w, hr18.x, hr20.x, hr17.w
(ss)br p0.y, #l98
jump #l70
l98:
(jp)(rpt1)nop
(rpt1)add.f r1.x, (last)(r)r1.x, (last)(r)r6.z
(rpt1)nop
(rpt1)add.f r1.x, (last)(r)r1.x, (last)(r)r6.x
(rpt1)nop
(rpt1)add.f r1.x, (last)(r)r1.x, (last)(r)r5.z
(rpt1)nop
(rpt1)add.f r1.x, (last)(r)r1.x, (last)(r)r5.x
(rpt1)nop
add.f r1.x, (last)r1.x, (last)r3.w
(nop2) add.f r1.y, (last)r1.y, (last)r8.w
add.f r1.x, (last)r1.x, (last)r4.x
(nop2) add.f r1.y, (last)r1.y, (last)r8.z
add.f r1.x, (last)r1.x, (last)r4.y
(nop2) add.f r1.y, (last)r1.y, (last)r8.y
(rpt1)add.f r1.x, (last)(r)r1.x, (last)(r)r4.z
(rpt1)nop
add.f r1.x, (last)r1.x, (last)r2.z
(nop2) add.f r1.y, (last)r1.y, (last)r8.x
add.f r1.x, (last)r1.x, (last)r2.w
(nop2) add.f r1.y, (last)r1.y, (last)r7.w
add.f r1.x, (last)r1.x, (last)r3.x
(nop2) add.f r1.y, (last)r1.y, (last)r7.z
(rpt1)add.f r1.x, (last)(r)r1.x, (last)(r)r3.y
(rpt1)nop
add.f r1.x, (last)r1.x, (last)r1.z
(nop2) add.f r1.y, (last)r1.y, (last)r7.y
add.f r1.x, (last)r1.x, (last)r1.w
(nop2) add.f r1.y, (last)r1.y, (last)r7.x
(rpt1)add.f r1.x, (last)(r)r1.x, (last)(r)r2.x
(rpt2)nop
(nop3) add.f r1.x, (last)r1.x, (last)r1.y
(nop3) cmps.f.eq p0.x, r1.x, c8.z
(rpt2)nop
predt
add.u r48.x, r48.x, c4.x
shl.b r48.x, r48.x, 7
(ss)(nop3) add.u r0.x, r48.x, (last)r0.x
(rpt2)nop
stib.b.untyped.1d.u32.1.imm.base0 r1.x, r0.x, 4
prede
(eogm)(rpt6)nop
end
nop
nop
nop
nop
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 170 instr, 61 nops, 109 non-nops, 17 mov, 1 cov, 290 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 9 full, 12 constlen
; CL prog 23/1: 66 cat0, 18 cat1, 53 cat2, 32 cat3, 0 cat4, 0 cat5, 1 cat6, 0 cat7
; CL prog 23/1: 6 sstall, 2 (ss), 0 systall, 0 (sy), 1 loops
; CL prog 23/1: 16 max_waves, 0 double_threadsize
; 37 preamble-instr, 0 early-preamble
