unit x64;

interface

procedure MoveFast(const src; var dst; cnt: NativeInt);

implementation

type
{$ifdef CPU64}
  PtrInt = NativeInt;
  PtrUInt = NativeUInt;
{$else}
  PtrInt = integer;
  PtrUInt = cardinal;
{$endif CPU64}

const
  NONTEMPORALSIZE = 512 * 1024;


procedure MoveFast(const src; var dst; cnt: NativeInt);
asm .noframe // rcx/rdi=src rdx/rsi=dst r8/rdx=cnt
        mov     rax, cnt             // rax=r8/rdx=cnt
        lea     r10, [rip + @jmptab] // 0..16 dedicated sub-functions
        sub     rax, 16
        ja      @up16                // >16 or <0
        {$ifdef WIN64ABI}    // circumvent FPC asm bug and adapt to xmm ABI
        jmp     qword ptr [r10 + r8 * 8]
@up16:  // >16 or <0
        jng     @z  // <0
        movups  xmm0, oword ptr [src + rax]    // last 16   = xmm0
        movups  xmm1, oword ptr [src]          // first 16  = xmm1
        cmp     rax, 96 - 16
        {$else}
        jmp     qword ptr [r10 + rdx * 8]
@neg:   ret
@up16:  // >16 or <0
        jng     @neg  // <0
        mov     r8, rdx
        movups  xmm0, oword ptr [src + rax]    // last 16   = xmm0
        movups  xmm1, oword ptr [src]          // first 16  = xmm1
        cmp     rdx, 144  // more volatile xmm registers on SystemV ABI
        {$endif WIN64ABI}
        ja      @lrg         // >96/144
        // cnt = 17..96/144
        cmp     al, $10
        jbe     @sml10
        movups  xmm2, oword ptr [src + $10]    // second 16
        cmp     al, $20
        jbe     @sml20
        movups  xmm3, oword ptr [src + $20]    // third 16
        cmp     al, $30
        jbe     @sml30
        movups  xmm4, oword ptr [src + $30]    // fourth 16
        cmp     al, $40
        jbe     @sml40
        movups  xmm5, oword ptr [src + $40]    // fifth 16
        // xmm0..xmm5 are volatile on both Win64 and SystemV ABI
        // xmm6 and up are also volatile on SystemV ABI so allow more bytes
        {$ifdef SYSVABI}
        cmp     al, $50
        jbe     @sml50
        movups  xmm6, oword ptr [src + $50]
        cmp     al, $60
        jbe     @sml60
        movups  xmm7, oword ptr [src + $60]
        cmp     al, $70
        jbe     @sml70
        movups  xmm8, oword ptr [src + $70]
        // more registers increases code size ([dst+$80]) so are not used
        movups  oword ptr [dst + $70], xmm8
@sml70: movups  oword ptr [dst + $60], xmm7
@sml60: movups  oword ptr [dst + $50], xmm6
@sml50: {$endif SYSVABI}
        movups  oword ptr [dst + $40], xmm5    // fifth 16
@sml40: movups  oword ptr [dst + $30], xmm4    // fourth 16
@sml30: movups  oword ptr [dst + $20], xmm3    // third 16
@sml20: movups  oword ptr [dst + $10], xmm2    // second 16
@sml10: movups  oword ptr [dst],       xmm1    // first 16
        movups  oword ptr [dst + rax], xmm0    // last 16 (may be overlapping)
@z:     ret
@lrg:   // cnt > 96/144 or cnt < 0
        mov     r11d, NONTEMPORALSIZE
        mov     r10, dst
        add     rax, 16       // restore rax=cnt as expected below
        jl      @z            // cnt < 0
        sub     r10, src
        jz      @z            // src=dst
        cmp     r10, cnt      // move backwards if unsigned(dst-src) < cnt
        jb      @lrgbwd
        // forward ERMSB/SSE2/AVX move for cnt > 96/144 bytes
        mov     r9, dst       // dst will be 16/32 bytes aligned for writes
        {$ifdef WITH_ERMS}
        {$ifdef WIN64ABI}   // 145 bytes seems good enough for ERMSB on a server
        cmp     rax, SSE2MAXSIZE
        jb      @fsse2      // 97..255 bytes may be not enough for ERMSB nor AVX
        {$endif WIN64ABI}
        cmp     rax, r11
        jae     @lrgfwd       // non-temporal move > 512KB is better than ERMSB
        // 256/145..512K could use the "rep movsb" ERMSB pattern on all CPUs
        cld
        {$ifdef WIN64ABI}
        push    rsi
        push    rdi
        mov     rsi, src
        mov     rdi, dst
        mov     rcx, r8
        rep movsb
        pop     rdi
        pop     rsi
        {$else}
        xchg    rsi, rdi // dst=rsi and src=rdi -> swap
        mov     rcx, r8
        rep movsb
        {$endif WIN64ABI}
        ret
        {$else}
        jmp     @lrgfwd
        {$endif WITH_ERMS}
        {$ifdef ASMX64AVXNOCONST} // limited AVX asm on Delphi 11
@lrgbwd:// backward SSE2/AVX move
        cmp     rax, SSE2MAXSIZE
        jb      @bsse2 // 97/129..255 bytes is not worth AVX context transition
        test    byte ptr [rip + X64CpuFeatures], 1 shl cpuAVX
        jz      @bsse2
        jmp     @bavx
@lrgfwd:// forward SSE2/AVX move
        test    byte ptr [rip + X64CpuFeatures], 1 shl cpuAVX
        jnz     @favx
        {$else}
@lrgfwd:{$endif ASMX64AVXNOCONST}
@fsse2: // forward SSE2 move
        lea     src, [src + rax - 16]
        lea     rax, [rax + dst - 16]
        mov     r10, rax
        neg     rax
        and     dst, -16                     // 16-byte aligned writes
        lea     rax, [rax + dst + 16]
        cmp     r8, r11
        jb      @fwd                         // bypass cache for cnt>512KB
        jmp     @fwdnt
        // backward SSE2/AVX move for cnt > 96/144 bytes
        // note: ERMSB is not available on "std rep move" which is slower
        {$ifndef ASMX64AVXNOCONST}
@lrgbwd:{$endif ASMX64AVXNOCONST}
@bsse2: // backward SSE2 move
        sub     rax, 16
        mov     r9, rax
        add     rax, dst
        and     rax, -16                     // 16-byte aligned writes
        sub     rax, dst
        cmp     r8, r11
        jae     @bwdnt                       // bypass cache for cnt>512KB
        jmp     @bwd
        {$ifdef ASMX64AVXNOCONST}
@bavx:  // backward AVX move
        sub     rax, 32
        mov     r9, rax
        vmovups ymm2, yword ptr [src + rax]  // last 32
        vmovups ymm1, yword ptr [src]        // first 32
        add     rax, dst
        and     rax, -32                     // 32-byte aligned writes
        sub     rax, dst
        cmp     r8, r11
        jae     @bavxn                       // bypass cache for cnt>512KB
        jmp     @bavxr
@favx:  // forward AVX move
        vmovups ymm2, yword ptr [src]        // first 32
        lea     src, [src + rax - 32]
        lea     dst, [dst + rax - 32]
        vmovups ymm1, yword ptr [src]        // last 32
        neg     rax
        add     rax, dst
        and     rax, -32                     // 32-byte aligned writes
        sub     rax, dst
        add     rax, 64
        cmp     r8, r11
        jb      @favxr                       // bypass cache for cnt>512KB
        jmp     @favxn
        // forward temporal AVX loop
{$ifdef FPC} align 16 {$else} .align 16 {$endif}
@favxr: vmovups ymm0, yword ptr [src + rax]
        vmovaps yword ptr [dst + rax], ymm0  // most CPUs have one store unit
        add     rax, 32
        jl      @favxr
@favxe: vmovups yword ptr [dst], ymm1        // last 32
        vmovups yword ptr [r9], ymm2         // first 32
// https://software.intel.com/en-us/articles/avoiding-avx-sse-transition-penalties
        vzeroupper
        ret
        // forward non-temporal AVX loop
{$ifdef FPC} align 16 {$else} .align 16 {$endif}
@favxn: vmovups ymm0, yword ptr [src + rax]
        // circumvent FPC inline asm bug with vmovntps [dst + rax], ymm0
        {$ifdef WIN64ABI}
        vmovntps [rdx + rax], ymm0           // rdx=dst on Win64
        {$else}
        vmovntps [rsi + rax], ymm0           // rsi=dst on POSIX
        {$endif WIN64ABI}
        add     rax, 32
        jl      @favxn
        sfence
        jmp     @favxe
        {$endif ASMX64AVXNOCONST}
        // forward temporal SSE2 loop
{$ifdef FPC} align 16 {$else} .align 16 {$endif}
@fwd:   movups  xmm2, oword ptr [src + rax]
        movaps  [r10 + rax], xmm2
        add     rax, 16
        jl      @fwd
        movups  oword ptr [r10], xmm0        // last 16
        movups  oword ptr [r9], xmm1         // first 16
        ret
        // forward non-temporal SSE2 loop
{$ifdef FPC} align 16 {$else} .align 16 {$endif}
@fwdnt: movups  xmm2, oword ptr [src + rax]
        movntdq [r10 + rax], xmm2
        add     rax, 16
        jl      @fwdnt
        sfence
        movups  oword ptr [r10], xmm0        // last 16
        movups  oword ptr [r9], xmm1         // first 16
        ret
        // backward temporal SSE2 loop
{$ifdef FPC} align 16 {$else} .align 16 {$endif}
@bwd:   movups  xmm2, oword ptr [src + rax]
        movaps  oword ptr [dst + rax], xmm2
        sub     rax, 16
        jg      @bwd
        movups  oword ptr [dst], xmm1        // first 16
        movups  oword ptr [dst + r9], xmm0   // last 16
        ret
        // backward non-temporal SSE2 loop
{$ifdef FPC} align 16 {$else} .align 16 {$endif}
@bwdnt: movups  xmm2, oword ptr [src + rax]
        movntdq oword ptr [dst + rax], xmm2
        sub     rax, 16
        jg      @bwdnt
        sfence
        movups  oword ptr [dst], xmm1        // first 16
        movups  oword ptr [dst + r9], xmm0   // last 16
        ret
        {$ifdef ASMX64AVXNOCONST}
        // backward temporal AVX loop
{$ifdef FPC} align 16 {$else} .align 16 {$endif}
@bavxr: vmovups ymm0, yword ptr [src + rax]
        vmovaps yword ptr [dst + rax], ymm0
        sub     rax, 32
        jg      @bavxr
@bavxe: vmovups yword ptr [dst], ymm1        // first 32
        vmovups yword ptr [dst + r9], ymm2   // last 32
        vzeroupper
        ret
        // backward non-temporal AVX loop
{$ifdef FPC} align 16 {$else} .align 16 {$endif}
@bavxn: vmovups ymm0, yword ptr [src + rax]
        // circumvent FPC inline asm bug with vmovntps [dst + rax], ymm0
        {$ifdef WIN64ABI}
        vmovntps [rdx + rax], ymm0           // rdx=dst on Win64
        {$else}
        vmovntps [rsi + rax], ymm0           // rsi=dst on POSIX
        {$endif WIN64ABI}
        sub     rax, 32
        jg      @bavxn
        sfence
        jmp     @bavxe
        {$endif ASMX64AVXNOCONST}
        // dedicated branchless sub-functions for 0..16 bytes
{$ifdef FPC} align 8 {$else} .align 8 {$endif}
@jmptab:dq      @00, @01, @02, @03, @04, @05, @06, @07
        dq      @08, @09, @10, @11, @12, @13, @14, @15, @16
@01:    mov     al, byte ptr [src]
        mov     byte ptr [dst], al
@00:    ret
@02:    movzx   eax, word ptr [src]
        mov     word ptr [dst], ax
        ret
@03:    movzx   eax, word ptr [src]
        mov     cl, byte ptr [src + 2]
        mov     word ptr [dst], ax
        mov     byte ptr [dst + 2], cl
        ret
@04:    mov     eax, dword ptr [src]
        mov     dword ptr [dst], eax
        ret
@05:    mov     eax, dword ptr [src]
        mov     cl, byte ptr [src + 4]
        mov     dword ptr [dst], eax
        mov     byte ptr [dst + 4], cl
        ret
@06:    mov     eax, dword ptr [src]
        movzx   ecx, word ptr [src + 4]
        mov     dword ptr [dst], eax
        mov     word ptr [dst + 4], cx
        ret
@07:    mov     r8d, dword ptr [src]         // faster with no overlapping
        movzx   eax, word ptr [src + 4]
        mov     cl, byte ptr [src + 6]
        mov     dword ptr [dst], r8d
        mov     word ptr [dst + 4], ax
        mov     byte ptr [dst + 6], cl
        ret
@08:    mov     rax, qword ptr [src]
        mov     [dst], rax
        ret
@09:    mov     rax, qword ptr [src]
        mov     cl, byte ptr [src + 8]
        mov     [dst], rax
        mov     byte ptr [dst + 8], cl
        ret
@10:    mov     rax, qword ptr [src]
        movzx   ecx, word ptr [src + 8]
        mov     [dst], rax
        mov     word ptr [dst + 8], cx
        ret
@11:    mov     r8, qword ptr [src]
        movzx   eax, word ptr [src + 8]
        mov     cl, byte ptr [src + 10]
        mov     [dst], r8
        mov     word ptr [dst + 8], ax
        mov     byte ptr [dst + 10], cl
        ret
@12:    mov     rax, qword ptr [src]
        mov     ecx, dword ptr [src + 8]
        mov     [dst], rax
        mov     dword ptr [dst + 8], ecx
        ret
@13:    mov     r8, qword ptr [src]
        mov     eax, dword ptr [src + 8]
        mov     cl, byte ptr [src + 12]
        mov     [dst], r8
        mov     dword ptr [dst + 8], eax
        mov     byte ptr [dst + 12], cl
        ret
@14:    mov     r8, qword ptr [src]
        mov     eax, dword ptr [src + 8]
        movzx   ecx, word ptr [src + 12]
        mov     [dst], r8
        mov     dword ptr [dst + 8], eax
        mov     word ptr [dst + 12], cx
        ret
@15:    mov     r8, qword ptr [src]
        mov     rax, qword ptr [src + 7] // overlap is the easiest solution
        mov     [dst], r8
        mov     [dst + 7], rax
        ret
@16:    movups  xmm0, oword ptr [src]
        movups  oword [dst], xmm0
end;

end.

