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
and.b r0.w, r0.x, 1
cov.u32f32 r1.z, r0.x
nop
(nop1) and.b r1.y, (last)r1.y, 1
(nop1) mul.f r1.w, (last)r1.z, c1.y
isam.v.base0 (u16)(x)hr2.x, r0.w, s#0, t#0
(rpt1)nop
add.f r2.w, r1.w, c4.y
isam.v.base0 (u16)(x)hr15.z, r1.y, s#0, t#0
add.f r2.z, r1.w, c4.x
add.f r2.y, r1.w, c3.w
add.f r4.x, r1.w, c3.z
add.f r3.w, r1.w, c3.y
add.f r3.z, r1.w, c3.x
add.f r3.y, r1.w, c2.w
add.f r5.y, r1.w, c2.z
add.f r5.x, r1.w, c2.y
add.f r4.w, r1.w, c2.x
add.f r4.z, r1.w, c1.w
add.f r5.w, r1.w, (4.0)
add.f r6.y, r1.w, c1.z
add.f r6.w, r1.w, (2.0)
add.f r7.y, r1.w, (1.0)
mov.u32u32 r0.z, r1.w
mov.u32u32 r0.y, r1.w
mov.u32u32 r2.x, r1.w
mov.u32u32 r3.x, r2.w
mov.u32u32 r8.w, r2.w
mov.u32u32 r8.z, r2.w
mov.u32u32 r9.z, r2.z
mov.u32u32 r9.y, r2.z
mov.u32u32 r9.x, r2.z
mov.u32u32 r10.y, r2.y
mov.u32u32 r10.x, r2.y
mov.u32u32 r9.w, r2.y
mov.u32u32 r10.w, r4.x
mov.u32u32 r10.z, r4.x
mov.u32u32 r4.y, r4.x
(sy)cov.f16f32 r8.x, (last)hr2.x
cov.f16f32 r8.y, (last)hr15.z
mov.u32u32 r11.z, r3.w
mov.u32u32 r11.y, r3.w
mov.u32u32 r11.x, r3.w
mov.u32u32 r12.y, r3.z
mov.u32u32 r12.x, r3.z
mov.u32u32 r11.w, r3.z
mov.u32u32 r13.x, r3.y
mov.u32u32 r12.w, r3.y
mov.u32u32 r12.z, r3.y
mov.u32u32 r13.z, r5.y
mov.u32u32 r13.y, r5.y
mov.u32u32 r5.z, r5.y
mov.u32u32 r14.y, r5.x
mov.u32u32 r14.x, r5.x
mov.u32u32 r13.w, r5.x
mov.u32u32 r15.x, r4.w
mov.u32u32 r14.w, r4.w
mov.u32u32 r14.z, r4.w
mov.u32u32 r15.w, r4.z
mov.u32u32 r15.z, r4.z
mov.u32u32 r15.y, r4.z
mov.u32u32 r16.y, r5.w
mov.u32u32 r16.x, r5.w
mov.u32u32 r6.x, r5.w
mov.u32u32 r16.w, r6.y
mov.u32u32 r16.z, r6.y
mov.u32u32 r6.z, r6.y
mov.u32u32 r17.y, r6.w
mov.u32u32 r17.x, r6.w
mov.u32u32 r7.x, r6.w
mov.u32u32 r17.w, r7.y
mov.u32u32 r17.z, r7.y
mov.u32u32 r7.z, r7.y
l102:
add.u r52.z, r52.z, 1
cmps.s.ge up0.y, r52.z, c1.x
(rpt1)mad.f32 r2.w, (r)(last)r2.w, r8.x, r8.y
(rpt1)mad.f32 r8.z, (r)(last)r8.z, r8.x, r8.y
mad.f32 r2.z, (last)r2.z, r8.x, r8.y
mad.f32 r9.x, (last)r9.x, r8.x, r8.y
(rpt1)mad.f32 r9.y, (r)(last)r9.y, r8.x, r8.y
mad.f32 r2.y, (last)r2.y, r8.x, r8.y
mad.f32 r9.w, (last)r9.w, r8.x, r8.y
(rpt1)mad.f32 r10.x, (r)(last)r10.x, r8.x, r8.y
(rpt1)mad.f32 r4.x, (r)(last)r4.x, r8.x, r8.y
(rpt1)mad.f32 r10.z, (r)(last)r10.z, r8.x, r8.y
mad.f32 r3.w, (last)r3.w, r8.x, r8.y
mad.f32 r11.x, (last)r11.x, r8.x, r8.y
(rpt1)mad.f32 r11.y, (r)(last)r11.y, r8.x, r8.y
mad.f32 r3.z, (last)r3.z, r8.x, r8.y
mad.f32 r11.w, (last)r11.w, r8.x, r8.y
(rpt1)mad.f32 r12.x, (r)(last)r12.x, r8.x, r8.y
mad.f32 r3.y, (last)r3.y, r8.x, r8.y
mad.f32 r12.z, (last)r12.z, r8.x, r8.y
(rpt1)mad.f32 r12.w, (r)(last)r12.w, r8.x, r8.y
(rpt1)mad.f32 r5.y, (r)(last)r5.y, r8.x, r8.y
(rpt1)mad.f32 r13.y, (r)(last)r13.y, r8.x, r8.y
mad.f32 r5.x, (last)r5.x, r8.x, r8.y
mad.f32 r13.w, (last)r13.w, r8.x, r8.y
(rpt1)mad.f32 r14.x, (r)(last)r14.x, r8.x, r8.y
mad.f32 r4.w, (last)r4.w, r8.x, r8.y
mad.f32 r14.z, (last)r14.z, r8.x, r8.y
(rpt1)mad.f32 r14.w, (r)(last)r14.w, r8.x, r8.y
mad.f32 r4.z, (last)r4.z, r8.x, r8.y
mad.f32 r15.y, (last)r15.y, r8.x, r8.y
(rpt1)mad.f32 r15.z, (r)(last)r15.z, r8.x, r8.y
(rpt1)mad.f32 r5.w, (r)(last)r5.w, r8.x, r8.y
(rpt1)mad.f32 r16.x, (r)(last)r16.x, r8.x, r8.y
(rpt1)mad.f32 r6.y, (r)(last)r6.y, r8.x, r8.y
(rpt1)mad.f32 r16.z, (r)(last)r16.z, r8.x, r8.y
(rpt1)mad.f32 r6.w, (r)(last)r6.w, r8.x, r8.y
(rpt1)mad.f32 r17.x, (r)(last)r17.x, r8.x, r8.y
(rpt1)mad.f32 r7.y, (r)(last)r7.y, r8.x, r8.y
(rpt1)mad.f32 r17.z, (r)(last)r17.z, r8.x, r8.y
(rpt1)mad.f32 r1.w, (r)(last)r1.w, r8.x, r8.y
(rpt1)mad.f32 r0.y, (r)(last)r0.y, r8.x, r8.y
(ss)br p0.y, #l146
jump #l102
l146:
(jp)(rpt1)add.f r1.w, (last)(r)r1.w, (last)(r)r7.y
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r17.z
(rpt1)add.f r1.w, (last)(r)r1.w, (last)(r)r6.w
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r17.x
(rpt1)add.f r1.w, (last)(r)r1.w, (last)(r)r6.y
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r16.z
(rpt1)add.f r1.w, (last)(r)r1.w, (last)(r)r5.w
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r16.x
add.f r1.w, (last)r1.w, (last)r4.z
add.f r2.x, (last)r2.x, (last)r15.y
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r15.z
add.f r1.w, (last)r1.w, (last)r4.w
add.f r2.x, (last)r2.x, (last)r14.z
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r14.w
add.f r1.w, (last)r1.w, (last)r5.x
add.f r2.x, (last)r2.x, (last)r13.w
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r14.x
(rpt1)add.f r1.w, (last)(r)r1.w, (last)(r)r5.y
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r13.y
add.f r1.w, (last)r1.w, (last)r3.y
add.f r2.x, (last)r2.x, (last)r12.z
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r12.w
add.f r1.w, (last)r1.w, (last)r3.z
add.f r2.x, (last)r2.x, (last)r11.w
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r12.x
add.f r1.w, (last)r1.w, (last)r3.w
add.f r2.x, (last)r2.x, (last)r11.x
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r11.y
(rpt1)add.f r1.w, (last)(r)r1.w, (last)(r)r4.x
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r10.z
add.f r1.w, (last)r1.w, (last)r2.y
add.f r2.x, (last)r2.x, (last)r9.w
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r10.x
add.f r1.w, (last)r1.w, (last)r2.z
add.f r2.x, (last)r2.x, (last)r9.x
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r9.y
(rpt1)add.f r1.w, (last)(r)r1.w, (last)(r)r2.w
(rpt1)add.f r0.y, (last)(r)r0.y, (last)(r)r8.z
nop
(nop3) add.f r1.w, (last)r1.w, (last)r2.x
(nop3) add.f r1.w, (last)r1.w, (last)r0.y
(nop3) add.f r1.w, (last)r1.w, (last)r0.z
(nop3) cmps.f.eq p0.x, r1.w, c4.z
(rpt2)nop
predt
add.u r48.x, r48.x, c0.x
shl.b r48.x, r48.x, 7
(ss)(nop3) add.u r0.x, r48.x, (last)r0.x
(rpt2)nop
stib.b.untyped.1d.u32.1.imm.base0 r1.w, r0.x, 4
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
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 246 instr, 34 nops, 212 non-nops, 49 mov, 3 cov, 416 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 18 full, 8 constlen
; CL prog 23/1: 39 cat0, 52 cat1, 88 cat2, 64 cat3, 0 cat4, 2 cat5, 1 cat6, 0 cat7
; CL prog 23/1: 6 sstall, 2 (ss), 0 systall, 1 (sy), 1 loops
; CL prog 23/1: 14 max_waves, 0 double_threadsize
; 27 preamble-instr, 1 early-preamble
