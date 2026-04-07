# External Benchmark Repository

This directory documents how this project connects to the professor-provided Google Track benchmark repository.
Do not treat this repository as the benchmark itself.

Recommended setup:

1. Keep the benchmark in a separate checkout outside this repo.
2. Select one visible problem at a time.
3. Copy or summarize the problem statement into `specs/problem.txt`.
4. Point `run_eval.py` or `run_pipeline.sh` at the external problem's `rtl/` directory.

Typical usage:

```bash
export GOOGLE_TRACK_PROBLEM_DIR=/path/to/google-track-benchmark/visible/problem_x
./run_pipeline.sh
```

If needed, you can bypass the problem directory wrapper and point directly at an RTL folder:

```bash
RTL_DIR=/path/to/google-track-benchmark/visible/problem_x/rtl ./run_pipeline.sh
```

The benchmark repository should remain the source of truth for visible problems and candidate RTL files.
