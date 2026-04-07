#!/usr/bin/env bash

set -euo pipefail

PROBLEM_DIR="${1:-}"
GENERATED_ROOT="${GENERATED_ROOT:-workspace/harness_generated}"

if [[ -z "${PROBLEM_DIR}" ]]; then
  echo "Usage: scripts/compile_smoke_test.sh /path/to/problem_dir" >&2
  exit 1
fi

PROBLEM_NAME="$(basename "${PROBLEM_DIR}")"
TB_PATH="${GENERATED_ROOT}/${PROBLEM_NAME}/tb.v"
MUTANT_PATH="$(find "${PROBLEM_DIR}" -maxdepth 1 -name 'mutant_*.v' | sort | head -n 1)"

if [[ ! -f "${TB_PATH}" ]]; then
  echo "Error: generated testbench not found at ${TB_PATH}" >&2
  exit 1
fi

if [[ -z "${MUTANT_PATH}" ]]; then
  echo "Error: no mutant_*.v files found in ${PROBLEM_DIR}" >&2
  exit 1
fi

mkdir -p logs
iverilog -g2012 -o "logs/${PROBLEM_NAME}_smoke.out" -s tb "${TB_PATH}" "${MUTANT_PATH}"
echo "Compiled ${TB_PATH} with ${MUTANT_PATH}"
