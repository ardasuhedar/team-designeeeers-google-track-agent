# Project Refactor Migration Note

This repository started as a toy comparator prototype.
It has now been refactored into the main mini-project repo for Topic 2: Google Track.

Migration summary:

- Preserved the comparator prototype under `examples/comparator/` instead of treating it as the main workflow.
- Reframed the repository around an external benchmark dataset rather than local toy RTL files.
- Generalized `run_eval.py` so it can evaluate any generated testbench against a user-specified RTL directory.
- Updated `run_pipeline.sh` to accept an external visible problem path through `GOOGLE_TRACK_PROBLEM_DIR` or `RTL_DIR`.
- Replaced the hardcoded comparator spec at the repo root with a reusable active-problem brief template.
- Updated documentation and agent instructions to reflect the real Google Track experiment loop.

Next steps:

- Select a visible benchmark problem.
- Fill in `specs/problem.txt` with the real problem statement and interface details.
- Generate `generated/tb.v` with Codex.
- Run the evaluator and iterate on discrimination quality.
