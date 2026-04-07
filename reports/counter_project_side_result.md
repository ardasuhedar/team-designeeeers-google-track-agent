# Counter Experiment Summary

Benchmark problem: `counter`

This experiment was run from the project-side repository using the local workflow in this repo. The professor-provided benchmark repository was used only as an external dataset for the visible `counter` problem and its mutant RTL files. The generated testbench was produced in this repository at `generated/tb.v`.

The evaluation logic in this project was aligned with the benchmark-side Google Track behavior so that a mutant is counted as passing only when the simulation prints `TESTS PASSED`. After aligning both the evaluator and the project-side testbench behavior, the final result was:

- 31 evaluated
- 1 passed
- 30 failed
- 0 compile failures
- passing mutant: `mutant_11.v`

This result matters because it shows the project-side workflow can now reproduce the benchmark-style visible-problem evaluation behavior while keeping the benchmark repository separate from the main project repo. It also demonstrates that the generated testbench is meaningfully discriminative rather than accepting many incorrect mutants.
