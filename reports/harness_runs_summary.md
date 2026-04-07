# Harness Runs Summary

This summary is based on the JSON run outputs under `reports/harness_runs/` and the matching logs under `reports/harness_logs/`.

## Per-Problem Results

### `cdc_fifo_flops_push_credit`

- Generation succeeded: yes
- Evaluation succeeded: yes
- Evaluated candidates: 31
- Passing candidates: 0
- Failing candidates: 31
- Compile failures: 0
- Qualitative label: weak

### `counter`

- Generation succeeded: yes
- Evaluation succeeded: yes
- Evaluated candidates: 31
- Passing candidates: 1
- Failing candidates: 30
- Compile failures: 0
- Qualitative label: strong

### `credit_receiver`

- Generation succeeded: yes
- Evaluation succeeded: yes
- Evaluated candidates: 31
- Passing candidates: 5
- Failing candidates: 26
- Compile failures: 0
- Qualitative label: moderate

### `ecc_sed_encoder`

- Generation succeeded: yes
- Evaluation succeeded: yes
- Evaluated candidates: 31
- Passing candidates: 1
- Failing candidates: 30
- Compile failures: 0
- Qualitative label: strong

### `enc_bin2gray`

- Generation succeeded: yes
- Evaluation succeeded: yes
- Evaluated candidates: 31
- Passing candidates: 1
- Failing candidates: 30
- Compile failures: 0
- Qualitative label: strong

### `enc_bin2onehot`

- Generation succeeded: yes
- Evaluation succeeded: yes
- Evaluated candidates: 31
- Passing candidates: 1
- Failing candidates: 30
- Compile failures: 0
- Qualitative label: strong

### `fifo_flops`

- Generation succeeded: yes
- Evaluation succeeded: yes
- Evaluated candidates: 31
- Passing candidates: 1
- Failing candidates: 30
- Compile failures: 0
- Qualitative label: strong

### `lfsr`

- Generation succeeded: yes
- Evaluation succeeded: yes
- Evaluated candidates: 31
- Passing candidates: 2
- Failing candidates: 29
- Compile failures: 0
- Qualitative label: moderate

### `shift_left`

- Generation succeeded: yes
- Evaluation succeeded: yes
- Evaluated candidates: 31
- Passing candidates: 8
- Failing candidates: 23
- Compile failures: 0
- Qualitative label: weak

### `shift_right`

- Generation succeeded: yes
- Evaluation succeeded: yes
- Evaluated candidates: 31
- Passing candidates: 7
- Failing candidates: 24
- Compile failures: 0
- Qualitative label: weak

## Remaining Unsupported or Problematic Problems

There are no currently unsupported visible problems in the saved harness runs: all ten visible problem families generated a local `tb.v` and completed evaluation without compile failures.

The main remaining problematic cases are about discrimination strength rather than missing support:

- `cdc_fifo_flops_push_credit`: likely over-constrained or mismatched to the intended CDC timing and credit-return behavior, since the current harness rejected all 31 mutants.
- `credit_receiver`: partially discriminative, but still under-constrained because 5 mutants passed; the current checks likely do not fully separate subtle credit-generation variants.
- `lfsr`: close but not fully resolved, with 2 passing mutants; likely needs more targeted state/tap sequences and longer advancement traces.
- `shift_left`: weak discrimination with 8 passing mutants; likely needs stronger symbol-position coverage and more targeted edge cases around legal versus invalid shift amounts.
- `shift_right`: weak discrimination with 7 passing mutants; likely needs stronger coverage of right-shift indexing, fill placement, and invalid-shift behavior.

Overall, the harness now supports all visible problems, and the strongest results are on `counter`, `ecc_sed_encoder`, `enc_bin2gray`, `enc_bin2onehot`, and `fifo_flops`, where the current testbenches isolate a single passing mutant.
