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
mov.u32u32 r9.x, c0.x
mov.u32u32 r9.y, c0.x
mov.u32u32 r9.z, c0.x
mov.u32u32 r9.w, c0.x
mov.u32u32 r10.x, c0.x
mov.u32u32 r10.y, c0.y
mov.u32u32 r10.z, c0.y
mov.u32u32 r10.w, c0.y
mov.u32u32 r11.x, c0.y
mov.u32u32 r11.y, c0.y
mov.u32u32 r11.z, c0.y
mov.u32u32 r11.w, c0.y
(rpt5)nop
l70:
add.u r49.z, r49.z, 1
cmps.s.ge up0.y, r49.z, c5.x
mad.f32 r1.x, r9.x, r1.x, r11.x
mad.f32 r1.y, r9.y, r1.y, r11.y
mad.f32 r1.z, r9.z, r1.z, r11.z
mad.f32 r1.w, r9.w, r1.w, r11.w
mad.f32 r2.x, r9.x, r2.x, r11.x
mad.f32 r2.y, r9.y, r2.y, r11.y
mad.f32 r2.z, r9.z, r2.z, r11.z
mad.f32 r2.w, r9.w, r2.w, r11.w
mad.f32 r3.x, r9.x, r3.x, r11.x
mad.f32 r3.y, r9.y, r3.y, r11.y
mad.f32 r3.z, r9.z, r3.z, r11.z
mad.f32 r3.w, r9.w, r3.w, r11.w
mad.f32 r4.x, r9.x, r4.x, r11.x
mad.f32 r4.y, r9.y, r4.y, r11.y
mad.f32 r4.z, r9.z, r4.z, r11.z
mad.f32 r4.w, r9.w, r4.w, r11.w
mad.f32 r5.x, r9.x, r5.x, r11.x
mad.f32 r5.y, r9.y, r5.y, r11.y
mad.f32 r5.z, r9.z, r5.z, r11.z
mad.f32 r5.w, r9.w, r5.w, r11.w
mad.f32 r6.x, r9.x, r6.x, r11.x
mad.f32 r6.y, r9.y, r6.y, r11.y
mad.f32 r6.z, r9.z, r6.z, r11.z
mad.f32 r6.w, r9.w, r6.w, r11.w
mad.f32 r7.x, r9.x, r7.x, r11.x
mad.f32 r7.y, r9.y, r7.y, r11.y
mad.f32 r7.z, r9.z, r7.z, r11.z
mad.f32 r7.w, r9.w, r7.w, r11.w
mad.f32 r8.x, r9.x, r8.x, r11.x
mad.f32 r8.y, r9.y, r8.y, r11.y
mad.f32 r8.z, r9.z, r8.z, r11.z
mad.f32 r8.w, r9.w, r8.w, r11.w
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
