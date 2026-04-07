# Agent Instructions

This repository is the main project repo for Topic 2: AI for Design Verification (Google Track).
Use it to generate and refine Verilog testbenches for visible benchmark problems while treating the benchmark repository as an external dataset.

## Required Workflow

1. Read `specs/problem.txt` before writing any testbench code.
2. Inspect the relevant RTL candidates in the external benchmark repository.
3. Infer the expected module name, interface, timing style, and observable behaviors from the visible problem and the candidate RTL files.
4. Write the generated testbench to `generated/tb.v`.
5. Run `python3 run_eval.py --tb generated/tb.v --rtl-dir <external_problem_rtl_dir> --spec specs/problem.txt`.
6. Review `logs/eval_results.json` and `reports/summary.json`.
7. If multiple RTL candidates still pass, refine `generated/tb.v` with stronger checks, better sequencing, or additional corner cases.
8. Stop after at most 5 iterations, even if some ambiguity remains.

## Operating Principles

- Do not modify RTL candidate files from the benchmark.
- Do not assume the active problem is the comparator example preserved under `examples/`.
- Prefer deterministic, self-checking testbenches with explicit pass/fail messages.
- Use the visible problem statement and evaluation evidence together.
- Preserve the separation between this repo and the benchmark repo.

## Output Expectations

- Save the active generated testbench as `generated/tb.v`.
- Keep experiment summaries in `reports/`.
- Use `workspace/` for temporary local notes or intermediate artifacts when helpful.
- If a result is inconclusive, explain why in the summary rather than pretending the discrimination problem is solved.
