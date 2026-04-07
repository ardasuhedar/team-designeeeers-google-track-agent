# Harness Migration Notes

This repository now supports two complementary workflows:

- the existing project-side workflow centered on `specs/problem.txt`, `generated/tb.v`, `run_pipeline.sh`, and `run_eval.py`
- a new benchmark-style workflow under `test_harness/` and `scripts/`

What was added:

- `test_harness/agent.py`: local testbench generation entry point with `generate_testbench(file_name_to_content)`
- `test_harness/constants.py`: shared harness constants such as `tb.v`, `tb`, and `TESTS PASSED`
- `test_harness/generate_testbenches.py`: generates local per-problem `tb.v` files for external visible problems
- `test_harness/run_evaluation.py`: evaluates generated testbenches against `mutant_*.v` files and reports pass/fail counts
- `scripts/run_pipeline.sh`: single entry point for the new harness workflow
- `scripts/compile_smoke_test.sh`: quick compile check for one generated harness testbench

Design intent:

- Keep this repository as the main Team DesignEEErs project repo.
- Treat the professor-provided benchmark repository as an external dataset.
- Preserve current reports, logs, and the original project-side workflow.
- Support reusable benchmark-style experiments for at least `counter`, `enc_bin2gray`, and `fifo_flops`.
