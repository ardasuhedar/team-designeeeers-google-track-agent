#!/usr/bin/env bash

set -euo pipefail

BENCHMARK_ROOT="${BENCHMARK_ROOT:-}"
PROBLEMS_FOLDER="${PROBLEMS_FOLDER:-}"
GENERATED_ROOT="${GENERATED_ROOT:-workspace/harness_generated}"
REPORT_PATH="${REPORT_PATH:-reports/harness_summary.json}"

if [[ -z "${PROBLEMS_FOLDER}" ]]; then
  if [[ -n "${BENCHMARK_ROOT}" ]]; then
    PROBLEMS_FOLDER="${BENCHMARK_ROOT}/visible_problems"
  else
    echo "Error: set PROBLEMS_FOLDER or BENCHMARK_ROOT for the external benchmark repository." >&2
    exit 1
  fi
fi

mkdir -p "${GENERATED_ROOT}" reports

python3 test_harness/generate_testbenches.py \
  --problems-folder "${PROBLEMS_FOLDER}" \
  --output-root "${GENERATED_ROOT}"

python3 test_harness/run_evaluation.py \
  --problems-folder "${PROBLEMS_FOLDER}" \
  --generated-root "${GENERATED_ROOT}" \
  --report-path "${REPORT_PATH}"
