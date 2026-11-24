<!--no-pdf-->
# CMSC 131 Lab 2 Starter

[![lab2-checks](https://github.com/WhiteLicorice/cmsc-131-lab2-starter/actions/workflows/test.yml/badge.svg)](https://github.com/WhiteLicorice/cmsc-131-lab2-starter/actions/workflows/test.yml)

A C-callable library of sort, search, and utility routines in assembly. The manual is the assignment. This file is the repository's own notes.

## Layout

```text
Makefile       platform preamble and build rules
bench.c        provided: file I/O, timing, the C-side comparison, the hostile caller
cdecl.h        provided: the calling-convention macros
LICENSE        provided
sort.asm       yours
search.asm     yours
util.asm       yours
run_tests.sh   provided: the correctness gate
tests/         provided: the test corpus
```

## What to Run

On Windows, run these commands in Git Bash, the shell from Block 1. In that
shell, `make` is your alias for `mingw32-make`. On Linux, use your terminal.

```bash
make
make check
```

`make` builds `bench`. `make check` builds, then runs `./run_tests.sh`,
which reports each check and exits nonzero when any of them fail. Each run
is captured first. Its exit status is read before its text is examined,
so a program that prints the right line and then crashes still fails.

## Reading a First Run

The assembly files ship as stubs that assemble and link as-is, so the build
works before you write any code. Right now they do nothing useful, and 19
of the 36 checks fail. The seventeen that pass prove little. Four are files
that arrive empty, single-element, or already sorted. `gcd(0, 0)` expects 0.
The hostile caller cannot be upset by a stub that touches no register. The
rest are argument and file refusals that the harness performs before any
assembly runs. That red run is the correct starting state for a starter. The
badge stays red until you implement the routines.

The provided files are fixtures. The grader compares your fork against the
starter. An edit to `bench.c`, `Makefile`, `run_tests.sh`, or a `tests/`
file appears as a diff in the open.

## Documentation

The three sections at the end of this file are yours. Complete Design Notes
and Subsystem Ownership before the Week 1 progress report. Complete Quirks
and Issues before the Week 3 progress report. Each section says what it
needs. Leave the rest of this file as it is.

---

## Design Notes

Complete this section before the Week 1 progress report and finish it by
Week 3. The syllabus asks for problem analysis, a solution architecture,
and an estimated timeline. The manual's Deliverables section lists what
this activity adds. Keep each part short. Update it when the plan changes.

### Problem analysis

The four routines `bench.c` expects and what each one returns. Which
registers you preserve and why.

#### Registers

All four routines are called from C, so they follow cdecl. The caller
pushes the arguments right to left, so the first argument is at
`[ebp+8]`, the second at `[ebp+12]`, and the third at `[ebp+16]`. The
caller removes them after the call returns. The result goes in `eax`.

C expects `ebx`, `esi`, `edi`, and `ebp` to hold the same values after
the call as before it. A routine that uses one of them pushes it after
the prologue and pops it, in reverse order, before `leave`. `ebp` is
handled by `enter` and `leave`. The routines can change `eax`, `ecx`,
and `edx` freely, because C saves those itself when it needs them.

`esp` must also be back where it started. Every push has a matching
pop, and after each call a routine makes, it removes the arguments it
pushed (`add esp, 8` for two arguments).

The stubs use `pusha` and `popa`. We replace them, because `popa` also
restores `eax` and so overwrites the return value.

`bench --hostile` checks this. It puts a known value in `ebx`, `esi`,
and `edi`, calls each routine, and fails if any of them changed or if
`esp` moved.

### Solution architecture

A stack frame diagram for one recursive call of `qsort_asm`, showing where
the arguments, the return address, saved `ebp`, and the saved registers
sit. Why `sum_range_asm` is reentrant.

#### Why `sum_range_asm` is reentrant

`sum_range_asm` calls `bench_callback` once, and `bench.c` starts a
second `sum_range_asm(1, 100)` inside that callback. The first call has
not finished yet. Both calls must still return the right sum.

They do, because neither call stores anything in `.data` or `.bss`.
Each call keeps `lo` and `hi` in its own stack frame, at `[ebp+8]` and
`[ebp+12]`. Each partial sum is in `eax` and is added on the way back
up the recursion. The second call pushes new frames below the first
call's frames and removes them before it returns. The first call's
frames are not changed.

The recursion is in a second routine, `sum_range_recursive`. Only
`sum_range_asm` calls `bench_callback`, so the callback runs once per
call from C and not once per level. `bench --reentrancy` reports
500500 for the outer call, 5050 for the nested call, and 2 callbacks.

### Measurements

The ratio `bench` reports on `random1000.txt`, `sorted1000.txt`,
`reverse1000.txt`, `duplicates.txt`, and `identical.txt`. Your worst case
and its cause. One improvement and its estimated effect.

| File | Ratio |
|---|---|
| `random1000.txt` | |
| `sorted1000.txt` | |
| `reverse1000.txt` | |
| `duplicates.txt` | |
| `identical.txt` | |

### Timeline

One line per week. Name the subsystem each week finishes and the member
who owns it.

| Week | Goal | Owner |
|---|---|---|
| 1 | Setup: ownership, timeline, and a build that runs `bench` on a provided file | @RalphREE |
| 2 | Sorting (`qsort_asm`) and Searching (`bsearch_asm`, `gcd_asm`) pass their checks | @AdrianMoser1 (Sorting), @Yomaruichi (Searching) |
| 3 | Convention and measurement: `sum_range_asm` reentrant, `--hostile` passes, all 36 checks, measurements | @RalphREE |
| 4 | Defense | All three |

## Subsystem Ownership

Complete this section before the Week 1 progress report. The manual lists
the three subsystems. Each member owns one. In a group of four, two members
share one. The commit history must agree with this table.

| Subsystem | Owner |
|---|---|
| Sorting (`qsort_asm` and its partition) | @AdrianMoser1 |
| Searching (`bsearch_asm`, `gcd_asm`) | @Yomaruichi |
| Convention and measurement (`sum_range_asm`, the benchmarks) | @RalphREE |

`gcd_asm` lives in `util.asm` but belongs to Searching, so @Yomaruichi owns it.
`util.asm` is shared: @Yomaruichi edits only `gcd_asm` and `gcd_depth`, and @RalphREE
edits only `sum_range_asm`.

Reviews: @Yomaruichi reviews Sorting, @RalphREE reviews Searching, and @AdrianMoser1 reviews
Convention and measurement.

## Quirks and Issues

Complete this section before the Week 3 progress report. The syllabus asks
for documentation of quirks and issues with the complete implementation.
One entry per item. State what happens, what causes it, and what the group
did about it.

### Known issues

- 

### Quirks

- `sum_range_asm(2147483647, 2147483647)` could recurse without end.
  With only the `lo > hi` base case, the routine computes `lo + 1`,
  which wraps to -2147483648, so `lo > hi` is never true. The routine
  now stops when `lo == hi` and returns `lo`, so it computes `lo + 1`
  only when `lo < hi`, where it cannot overflow.
- `sum_range_asm` recurses once per number in the range, so a very
  large range uses a lot of stack. Each level uses 16 bytes. The
  reentrancy check sums 1..1000, which is well within the stack.
