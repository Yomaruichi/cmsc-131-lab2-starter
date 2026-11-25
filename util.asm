;
; util.asm - gcd_asm and sum_range_asm, both recursive, callable from C.
;
; This is your starting point: it assembles and links as-is, so the build
; works before you write any code. Right now gcd_asm returns 0 and
; sum_range_asm returns 0, so the benchmark's --gcd and --reentrancy demos
; fail. Your job is to replace both.
;
; The contracts, from bench.c:
;
;       int b                       [ebp+12]
;       int a                       [ebp+8]
;       int gcd_asm(int a, int b)   returns the greatest common divisor
;
;       int hi                      [ebp+12]
;       int lo                      [ebp+8]
;       int sum_range_asm(lo, hi)   returns the sum of lo..hi inclusive
;
; Both are C-facing and must obey cdecl: prologue, args at [ebp+8]+, return
; in eax, preserve ebx/esi/edi/ebp, clean arguments after every call.
;
; gcd_asm also sets the global `gcd_depth` to the recursion depth of its
; most recent call. The depth is the number of gcd calls on the stack at
; the deepest point, the first call counted as 1. gcd(1071, 462) makes
; four calls, so it reaches 4. bench.c declares the global extern and
; prints it after --gcd:
;
;       int gcd_depth               (in .bss, exported, one int)
;
; The manual's requirements:
;
;   * Both recursive (Euclid's algorithm for gcd).
;   * sum_range_asm must be reentrant. It has to stay correct when a second
;     call begins before the first has finished. That means no .data or
;     .bss storage that changes during execution. Everything lives on the
;     stack and in registers. The static gcd_depth global is gcd's, not
;     sum_range's, and it is diagnostic rather than part of a result.
;   * sum_range_asm calls the C function bench_callback(void) once each
;     time C calls it, which is how bench makes one call overlap another.
;     The recursive calls must not call it again. bench counts the calls.
;     Declare it extern and call it with cdecl. It is not in the manual's
;     pseudocode, but it is what the reentrancy demo runs on.
;   * No calls into the C standard library.
;
; Euclid:
;
;   gcd(a, b):
;       if b == 0: return a
;       return gcd(b, a % b)
;
; sum_range, written so that nothing lives outside the stack:
;
;   sum_range(lo, hi):
;       if lo > hi: return 0
;       return lo + sum_range(lo + 1, hi)
;

; Windows C puts a leading underscore on every exported name. Linux C does
; not. The Makefile passes -d ELF_TYPE on Linux. This block then respells
; the names below to match. asm_io.inc does the same for _asm_main in the
; bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _gcd_asm gcd_asm
  %define _sum_range_asm sum_range_asm
  %define _gcd_depth gcd_depth
  %define _bench_callback bench_callback
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

segment .bss
        global  _gcd_depth
_gcd_depth      resd    1

segment .text
        global  _gcd_asm
        extern  _bench_callback
_gcd_asm:
        enter   0,0
        pusha

        ;
        ; TODO: gcd. Count the calls. Reset gcd_depth at entry, then keep
        ; the deepest level reached, with the first call as level 1. Carry
        ; the current level in a register or count it in the global, but
        ; leave the peak behind. bench.c reads gcd_depth after the call
        ; returns, so a counter that returns to zero on exit prints 0.
        ;

        popa
        mov     eax, 0
        leave
        ret

        global  _sum_range_asm
;
; Frame of _sum_range_asm after enter 0,0:
;
;       [ebp+12]    hi
;       [ebp+8]     lo
;       [ebp+4]     return address into C
;       [ebp]       caller's ebp
;
; This routine uses only eax, ecx, and edx, which cdecl lets it change,
; so it saves no other register. pusha/popa is not used: popa would
; restore eax and erase the result.
;
; Reentrancy: lo, hi, and every partial sum live in this call's own
; stack frames or in eax. Nothing is written to .data or .bss. A second
; call that starts inside bench_callback gets its own frames, so it
; cannot change the first call's values.
;
_sum_range_asm:
        enter   0,0

        ; Once per call from C. The recursion below does not call it.
        call    _bench_callback         ; no arguments, nothing to remove

        push    dword [ebp+12]          ; hi
        push    dword [ebp+8]           ; lo
        call    sum_range_recursive
        add     esp, 8                  ; remove the two arguments

        leave                           ; result is already in eax
        ret

;
; sum_range_recursive(lo, hi): the sum of lo..hi inclusive.
;
; Internal routine. It uses the same convention as cdecl: arguments
; pushed right to left, caller removes them, result in eax, only eax
; changed. Not global, so C cannot call it.
;
;       if lo > hi:  return 0
;       if lo == hi: return lo
;       return lo + sum_range_recursive(lo + 1, hi)
;
; The lo == hi case stops before lo + 1 is computed. Without it,
; sum_range_asm(2147483647, 2147483647) would compute lo + 1, which
; wraps to -2147483648, and the recursion would not stop.
;
sum_range_recursive:
        enter   0,0

        mov     eax, [ebp+8]            ; eax = lo
        cmp     eax, [ebp+12]           ; signed compare with hi
        jg      .empty                  ; lo > hi
        je      .done                   ; lo == hi: the sum is lo

        push    dword [ebp+12]          ; hi
        inc     eax
        push    eax                     ; lo + 1, cannot overflow here
        call    sum_range_recursive
        add     esp, 8                  ; remove the two arguments

        add     eax, [ebp+8]            ; lo + sum of (lo + 1)..hi
        jmp     .done

.empty:
        xor     eax, eax                ; empty range sums to 0

.done:
        leave
        ret
