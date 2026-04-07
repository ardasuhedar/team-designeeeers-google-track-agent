#!/usr/bin/env bash

set -euo pipefail

mkdir -p generated logs reports workspace/current_problem

TB_PATH="${TB_PATH:-generated/tb.v}"
SPEC_PATH="${SPEC_PATH:-specs/problem.txt}"
PROBLEM_DIR="${1:-${GOOGLE_TRACK_PROBLEM_DIR:-}}"
RTL_DIR="${RTL_DIR:-${GOOGLE_TRACK_RTL_DIR:-}}"

if [[ -z "${RTL_DIR}" && -n "${PROBLEM_DIR}" ]]; then
  if [[ -d "${PROBLEM_DIR}/rtl" ]]; then
    RTL_DIR="${PROBLEM_DIR}/rtl"
  else
    RTL_DIR="${PROBLEM_DIR}"
  fi
fi

if [[ -z "${RTL_DIR}" ]]; then
  echo "Error: set RTL_DIR or GOOGLE_TRACK_PROBLEM_DIR to the visible benchmark problem directory." >&2
  exit 1
fi

python3 run_eval.py \
  --tb "${TB_PATH}" \
  --rtl-dir "${RTL_DIR}" \
  --spec "${SPEC_PATH}" \
  --logs-dir logs \
  --results-path logs/eval_results.json \
  --summary-path reports/summary.json
