# Google Track Verification Agent

Team DesignEEErs

Codex-based Verilog testbench generation and evaluation for visible Google Track verification problems.

## Team

Team DesignEEErs

This is a group project for Topic 2: AI for Design Verification (Google Track).

### Members

- Arda Suhedar
- Mertkan Riza Yulu

This repository is the project repository of Team DesignEEErs for Topic 2: AI for Design Verification (Google Track).
Its purpose is to drive a Codex-based workflow that reads a natural language hardware problem, generates a Verilog testbench, and evaluates that testbench against RTL candidates from the professor-provided benchmark repository.

The benchmark repository is treated as an external dataset.
This repo should contain the agent workflow, prompts, local experiment artifacts, and notes.
It should not become a copy of the benchmark itself.

## Project Goal

For each visible Google Track problem, we want to:

1. Read the visible problem statement and capture the active task in `specs/problem.txt`.
2. Inspect the corresponding RTL candidates from the external benchmark repository.
3. Generate a discriminative Verilog testbench at `generated/tb.v`.
4. Evaluate the testbench across the candidate RTL implementations.
5. Refine the testbench until it separates the correct RTL from incorrect candidates as well as possible.

## Requirements

- macOS
- Python 3
- Icarus Verilog (`iverilog` and `vvp`)
- Codex

## Recommended Structure

- `AGENTS.md`: instructions for Codex or another coding agent
- `specs/problem.txt`: the active problem brief for the current experiment
- `generated/`: generated outputs for the current run, including `tb.v`
- `logs/`: raw compile and simulation results
- `reports/`: experiment summaries, plans, and notes
- `workspace/`: scratch space for local problem-specific working files
- `external/`: documentation for connecting this repo to the separate benchmark repo
- `examples/comparator/`: preserved toy prototype example for reference only
- `run_eval.py`: generic evaluator for a generated testbench and an RTL directory
- `run_pipeline.sh`: wrapper script for running a local experiment

## External Benchmark Workflow

Keep the benchmark in a separate location, for example:

```bash
/path/to/google-track-benchmark
```

In this project, use a portable environment variable such as:

```bash
export BENCHMARK_ROOT=/path/to/Google-Verification-ICLAD25-Hackathon
```

Then use this repository to run experiments against one visible problem at a time.
The simplest workflow is:

1. Copy or summarize the visible problem statement into `specs/problem.txt`.
2. Generate `generated/tb.v`.
3. Point the evaluator at the external RTL directory.
4. Review `logs/eval_results.json` and `reports/summary.json`.

Example:

```bash
export GOOGLE_TRACK_PROBLEM_DIR=$BENCHMARK_ROOT/visible_problems/problem_x
./run_pipeline.sh
```

You can also set `RTL_DIR` directly if you want to evaluate a specific RTL folder:

```bash
RTL_DIR=$BENCHMARK_ROOT/visible_problems/problem_x ./run_pipeline.sh
```

Do not modify files in the benchmark repository. Treat it as an external dataset and keep all generated testbenches, logs, and reports in this repository.

## Current Workflow

1. Update `specs/problem.txt` with the active visible problem.
2. Ask Codex to inspect the external RTL candidates and generate `generated/tb.v`.
3. Run:

```bash
./run_pipeline.sh
```

4. If multiple candidates still pass, refine the testbench and rerun the evaluator.

## Concrete Example: `counter`

Visible problem path:

```bash
$BENCHMARK_ROOT/visible_problems/counter
```

Exact command used:

```bash
export BENCHMARK_ROOT=/path/to/Google-Verification-ICLAD25-Hackathon
GOOGLE_TRACK_PROBLEM_DIR=$BENCHMARK_ROOT/visible_problems/counter ./run_pipeline.sh
```

Outputs are written to:

- `generated/tb.v`
- `logs/eval_results.json`
- `reports/summary.json`
- `reports/counter_project_side_result.md`

Observed result for the aligned `counter` experiment:

- 31 evaluated
- 1 passed
- 30 failed
- 0 compile failures
- passing mutant: `mutant_11.v`

## Experiment Coverage

The project-side workflow has been exercised on multiple visible Google Track problems rather than only a single toy example.

Problems covered so far:

- `counter`: produced a successful discriminative result with the project-side workflow aligned to the benchmark-side evaluation behavior
- `enc_bin2gray`: was also tested using the same workflow, with a problem-specific combinational testbench generated in this repository
- `fifo_flops`: was tested as a harder stateful FIFO and handshake benchmark, requiring problem-specific checks for reset, buffering, bypass behavior, and status signals

The file `generated/tb.v` is problem-specific and reflects only the current active experiment.
This repository does not rely on one fixed reusable testbench across all Google Track problems.
Instead, the workflow regenerates a new Verilog testbench for each selected problem based on the active brief in `specs/problem.txt` and the corresponding external benchmark reference.

## Notes

- The files in `examples/comparator/` are preserved from the initial toy prototype.
- The evaluator no longer assumes a specific comparator design or a fixed toy RTL layout.
- `reports/project_refactor_plan.md` records the migration from the prototype to this main project repo.
