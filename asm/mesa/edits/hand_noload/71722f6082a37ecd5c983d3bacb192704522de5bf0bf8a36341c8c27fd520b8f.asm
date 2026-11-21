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
mov.u32u32 r48.w, 2048
mov.u32u32 r49.x, 0x1800
mov.u32u32 r49.y, 4096
mov.u32u32 r49.z, 0x1840
mov.u32u32 r49.w, 0x1040
mov.u32u32 r50.x, 2112
mov.u32u32 r50.y, 0x20000
mov.u32u32 r50.z, 0x20040
mov.u32u32 r50.w, 0x20800
mov.u32u32 r51.x, 0x20840
mov.u32u32 r51.y, 0x21000
mov.u32u32 r51.z, 0x21040
mov.u32u32 r51.w, 0x21800
mov.u32u32 r52.x, 0x21840
mova1.u a1.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 0
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 2
resinfo.b.untyped.1d.u32.1.imm.base0 r63.x, 4
(ss)nop
stc.u32 c[4], r48.w, 4
stc.u32 c[8], r49.w, 4
stc.u32 c[12], r50.w, 4
stc.u32 c[16], r51.w, 2
ldc.1.k.imm c[a1.x], 1, 1
(sy)(ss)shpe
l27:
(jp)(rpt1)add.u r52.y, (r)r48.x, (r)c0.x
mov.u32u32 r53.y, 0
shl.b r53.x, r52.y, 7
shl.b r52.w, r52.z, 7
shr.b r0.w, r0.x, 4
mov.u16u16 hr2.x, 0
mov.u16u16 hr2.y, 0
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
mov.u16u16 hr2.w, 0
mov.u16u16 hr2.z, 0
and.b r0.x, (last)r0.x, 15
(rpt1)shr.b r53.z, (r)r52.w, 2
shl.b r54.x, r53.y, 9
(ss)(nop2) sad.s32 r18.x, r54.x, r0.w, r53.z
sad.s32 r18.y, r54.x, r0.x, r53.w
(nop2) shl.b r18.x, r18.x, 2
shl.b r18.y, r18.y, 2
(rpt2)nop
l97:
add.u r53.y, r53.y, 4
cmps.u.ge up0.x, r53.y, c1.x
add.u r18.z, r18.x, c1.x
add.u r18.w, r18.y, c1.x
add.u r19.x, r18.x, c1.z
add.u r19.y, r18.y, c1.z
add.u r19.z, r18.x, c1.y
add.u r19.w, r18.y, c1.y
(ss)add.u r18.x, r19.z, c1.x
add.u r18.y, r19.w, c1.x
(sy)(rpt3)mad.f16 hr17.x, (r)hr18.y, hr26.y, (r)hr17.x
(rpt3)mad.f16 hr16.x, (r)hr19.y, hr26.y, (r)hr16.x
(rpt3)mad.f16 hr15.x, (r)hr18.y, hr26.z, (r)hr15.x
(rpt3)mad.f16 hr14.x, (r)hr19.y, hr26.z, (r)hr14.x
(rpt3)mad.f16 hr13.x, (r)hr18.y, hr26.w, (r)hr13.x
(rpt3)mad.f16 hr12.x, (r)hr19.y, hr26.w, (r)hr12.x
(rpt3)mad.f16 hr11.x, (r)hr18.y, hr27.x, (r)hr11.x
(rpt3)mad.f16 hr10.x, (r)hr19.y, hr27.x, (r)hr10.x
(rpt3)mad.f16 hr9.x, (r)hr18.y, hr27.y, (r)hr9.x
(rpt3)mad.f16 hr8.x, (r)hr19.y, hr27.y, (r)hr8.x
(rpt3)mad.f16 hr7.x, (r)hr18.y, hr27.z, (r)hr7.x
(rpt3)mad.f16 hr6.x, (r)hr19.y, hr27.z, (r)hr6.x
(rpt3)mad.f16 hr5.x, (r)hr18.y, hr27.w, (r)hr5.x
(rpt3)mad.f16 hr4.x, (r)hr19.y, hr27.w, (r)hr4.x
(rpt3)mad.f16 hr3.x, (r)hr18.y, hr28.x, (r)hr3.x
(rpt3)mad.f16 hr2.x, (r)hr19.y, hr28.x, (r)hr2.x
(rpt3)mad.f16 hr17.x, (r)hr20.y, hr28.y, (r)hr17.x
(rpt3)mad.f16 hr16.x, (r)hr21.y, hr28.y, (r)hr16.x
(rpt3)mad.f16 hr15.x, (r)hr20.y, hr28.z, (r)hr15.x
(rpt3)mad.f16 hr14.x, (r)hr21.y, hr28.z, (r)hr14.x
(rpt3)mad.f16 hr13.x, (r)hr20.y, hr28.w, (r)hr13.x
(rpt3)mad.f16 hr12.x, (r)hr21.y, hr28.w, (r)hr12.x
(rpt3)mad.f16 hr11.x, (r)hr20.y, hr29.x, (r)hr11.x
(rpt3)mad.f16 hr10.x, (r)hr21.y, hr29.x, (r)hr10.x
(rpt3)mad.f16 hr9.x, (r)hr20.y, hr29.y, (r)hr9.x
(rpt3)mad.f16 hr8.x, (r)hr21.y, hr29.y, (r)hr8.x
(rpt3)mad.f16 hr7.x, (r)hr20.y, hr29.z, (r)hr7.x
(rpt3)mad.f16 hr6.x, (r)hr21.y, hr29.z, (r)hr6.x
(rpt3)mad.f16 hr5.x, (r)hr20.y, hr29.w, (r)hr5.x
(rpt3)mad.f16 hr4.x, (r)hr21.y, hr29.w, (r)hr4.x
(rpt3)mad.f16 hr3.x, (r)hr20.y, hr30.x, (r)hr3.x
(rpt3)mad.f16 hr2.x, (r)hr21.y, hr30.x, (r)hr2.x
(rpt3)mad.f16 hr17.x, (r)hr22.y, hr30.y, (r)hr17.x
(rpt3)mad.f16 hr16.x, (r)hr23.y, hr30.y, (r)hr16.x
(rpt3)mad.f16 hr15.x, (r)hr22.y, hr30.z, (r)hr15.x
(rpt3)mad.f16 hr14.x, (r)hr23.y, hr30.z, (r)hr14.x
(rpt3)mad.f16 hr13.x, (r)hr22.y, hr30.w, (r)hr13.x
(rpt3)mad.f16 hr12.x, (r)hr23.y, hr30.w, (r)hr12.x
(rpt3)mad.f16 hr11.x, (r)hr22.y, hr31.x, (r)hr11.x
(rpt3)mad.f16 hr10.x, (r)hr23.y, hr31.x, (r)hr10.x
(rpt3)mad.f16 hr9.x, (r)hr22.y, hr31.y, (r)hr9.x
(rpt3)mad.f16 hr8.x, (r)hr23.y, hr31.y, (r)hr8.x
(rpt3)mad.f16 hr7.x, (r)hr22.y, hr31.z, (r)hr7.x
(rpt3)mad.f16 hr6.x, (r)hr23.y, hr31.z, (r)hr6.x
(rpt3)mad.f16 hr5.x, (r)hr22.y, hr31.w, (r)hr5.x
(rpt3)mad.f16 hr4.x, (r)hr23.y, hr31.w, (r)hr4.x
(rpt3)mad.f16 hr3.x, (r)hr22.y, hr32.x, (r)hr3.x
(rpt3)mad.f16 hr2.x, (r)hr23.y, hr32.x, (r)hr2.x
(rpt3)mad.f16 hr17.x, (r)hr24.y, hr32.y, (r)hr17.x
(rpt3)mad.f16 hr16.x, (r)hr25.y, hr32.y, (r)hr16.x
(rpt3)mad.f16 hr15.x, (r)hr24.y, hr32.z, (r)hr15.x
(rpt3)mad.f16 hr14.x, (r)hr25.y, hr32.z, (r)hr14.x
(rpt3)mad.f16 hr13.x, (r)hr24.y, hr32.w, (r)hr13.x
(rpt3)mad.f16 hr12.x, (r)hr25.y, hr32.w, (r)hr12.x
(rpt3)mad.f16 hr11.x, (r)hr24.y, hr33.x, (r)hr11.x
(rpt3)mad.f16 hr10.x, (r)hr25.y, hr33.x, (r)hr10.x
(rpt3)mad.f16 hr9.x, (r)hr24.y, hr33.y, (r)hr9.x
(rpt3)mad.f16 hr8.x, (r)hr25.y, hr33.y, (r)hr8.x
(rpt3)mad.f16 hr7.x, (r)hr24.y, hr33.z, (r)hr7.x
(rpt3)mad.f16 hr6.x, (r)hr25.y, hr33.z, (r)hr6.x
(rpt3)mad.f16 hr5.x, (r)hr24.y, hr33.w, (r)hr5.x
(rpt3)mad.f16 hr4.x, (r)hr25.y, hr33.w, (r)hr4.x
(rpt3)mad.f16 hr3.x, (r)hr24.y, hr34.x, (r)hr3.x
(rpt3)mad.f16 hr2.x, (r)hr25.y, hr34.x, (r)hr2.x
(ss)br p0.x, #l349
jump #l97
l349:
(jp)(sy)(nop3) shl.b r0.w, (last)r0.w, 2
(nop3) add.u r0.w, r52.w, (last)r0.w
(nop3) shl.b r0.w, (last)r0.w, 9
(nop3) sad.s32 r0.w, r53.w, r0.w, (last)r0.x
(nop3) shl.b r0.w, (last)r0.w, 2
add.u r12.x, r0.w, c1.x
add.u r12.y, r0.w, c2.y
add.u r12.z, r0.w, c1.z
stib.b.untyped.1d.u16.4.imm.base0 hr17.x, r0.w, 4
add.u r12.w, r0.w, c2.x
add.u r13.x, r0.w, c1.y
add.u r13.y, r0.w, c1.w
add.u r13.z, r0.w, c2.z
(rpt1)add.u r13.w, (r)c2.w, r0.w
(rpt1)add.u r14.y, (r)c3.y, r0.w
(rpt1)add.u r14.w, (r)c3.w, r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr16.x, r0.w+64, 4
(ss)add.u r0.w, c4.y, (last)r0.w
stib.b.untyped.1d.u16.4.imm.base0 hr15.x, r12.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr14.x, r12.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr13.x, r12.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr12.x, r12.w, 4
stib.b.untyped.1d.u16.4.imm.base0 hr11.x, r13.x, 4
stib.b.untyped.1d.u16.4.imm.base0 hr10.x, r13.y, 4
stib.b.untyped.1d.u16.4.imm.base0 hr9.x, r13.z, 4
stib.b.untyped.1d.u16.4.imm.base0 hr8.x, r13.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr7.x, r14.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr6.x, r14.y, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr5.x, r14.z, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr4.x, r14.w, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr3.x, r15.x, 4
nop
stib.b.untyped.1d.u16.4.imm.base0 hr2.x, r0.w, 4
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
; CL: outputs:
; CL: inputs: r0.x (SYSTEM_VALUE_LOCAL_INVOCATION_ID slot=42 cm=7,il=0,b=0) r48.x (SYSTEM_VALUE_WORKGROUP_ID slot=47 cm=7,il=0,b=0)
; CL prog 23/1: 428 instr, 26 nops, 402 non-nops, 65 mov, 0 cov, 800 dwords
; CL prog 23/1: 0 last-baryf, 0 last-helper, 0 half, 16 full, 8 constlen
; CL prog 23/1: 29 cat0, 65 cat1, 43 cat2, 259 cat3, 0 cat4, 16 cat5, 16 cat6, 0 cat7
; CL prog 23/1: 6 sstall, 3 (ss), 38 systall, 2 (sy), 1 loops
; CL prog 23/1: 16 max_waves, 0 double_threadsize
; 27 preamble-instr, 1 early-preamble
