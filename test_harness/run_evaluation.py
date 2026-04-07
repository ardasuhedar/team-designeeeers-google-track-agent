#!/usr/bin/env python3

"""Evaluate locally generated testbenches against external Google Track mutants."""

from __future__ import annotations

import argparse
import json
import subprocess
import tempfile
from pathlib import Path

import constants


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run benchmark-style evaluation for one or more visible Google Track problems."
    )
    parser.add_argument(
        "--problems-folder",
        required=True,
        help="Path to a benchmark visible_problems directory or a single problem directory.",
    )
    parser.add_argument(
        "--generated-root",
        default=constants.DEFAULT_GENERATED_ROOT,
        help="Local root containing generated per-problem tb.v files.",
    )
    parser.add_argument(
        "--report-path",
        default="reports/harness_summary.json",
        help="Path to write the aggregated harness summary JSON.",
    )
    return parser.parse_args()


def iter_problem_dirs(problems_folder: Path) -> list[Path]:
    if (problems_folder / "specification.md").exists():
        return [problems_folder]
    return sorted(
        path
        for path in problems_folder.iterdir()
        if path.is_dir() and (path / "specification.md").exists()
    )


def run_single(tb_path: Path, mutant_path: Path) -> dict:
    with tempfile.TemporaryDirectory() as temp_dir:
        compiled_path = Path(temp_dir) / "out"
        compile_cmd = [
            "iverilog",
            "-g2012",
            "-o",
            str(compiled_path),
            "-s",
            constants.TESTBENCH_MODULE_NAME,
            str(tb_path),
            str(mutant_path),
        ]
        compile_proc = subprocess.run(
            compile_cmd,
            capture_output=True,
            text=True,
            timeout=constants.DEFAULT_TIMEOUT_SECONDS,
        )
        if compile_proc.returncode != 0:
            return {
                "rtl_file": str(mutant_path),
                "compile": {
                    "returncode": compile_proc.returncode,
                    "stdout": compile_proc.stdout,
                    "stderr": compile_proc.stderr,
                    "command": compile_cmd,
                },
                "simulation": None,
                "status": "compile_failed",
            }

        sim_cmd = ["vvp", str(compiled_path)]
        sim_proc = subprocess.run(
            sim_cmd,
            capture_output=True,
            text=True,
            timeout=constants.DEFAULT_TIMEOUT_SECONDS,
        )
        stdout = sim_proc.stdout or ""
        status = "pass" if constants.TEST_PASS_STRING in stdout else "fail"
        return {
            "rtl_file": str(mutant_path),
            "compile": {
                "returncode": compile_proc.returncode,
                "stdout": compile_proc.stdout,
                "stderr": compile_proc.stderr,
                "command": compile_cmd,
            },
            "simulation": {
                "returncode": sim_proc.returncode,
                "stdout": sim_proc.stdout,
                "stderr": sim_proc.stderr,
                "command": sim_cmd,
            },
            "status": status,
        }


def build_problem_summary(problem_name: str, results: list[dict], tb_path: Path) -> dict:
    counts = {"pass": 0, "fail": 0, "compile_failed": 0}
    for result in results:
        counts[result["status"]] += 1
    return {
        "problem": problem_name,
        "generated_testbench": str(tb_path),
        "evaluated_candidates": len(results),
        "status_counts": counts,
        "passing_candidates": [r["rtl_file"] for r in results if r["status"] == "pass"],
        "failing_candidates": [r["rtl_file"] for r in results if r["status"] == "fail"],
        "compile_failed_candidates": [
            r["rtl_file"] for r in results if r["status"] == "compile_failed"
        ],
    }


def main() -> int:
    args = parse_args()
    problems_folder = Path(args.problems_folder).resolve()
    generated_root = Path(args.generated_root).resolve()
    report_path = Path(args.report_path).resolve()
    report_path.parent.mkdir(parents=True, exist_ok=True)

    if not problems_folder.exists():
        raise SystemExit(f"Problems folder does not exist: {problems_folder}")

    summaries: list[dict] = []
    for problem_dir in iter_problem_dirs(problems_folder):
        tb_path = generated_root / problem_dir.name / constants.TESTBENCH_FILE_NAME
        if not tb_path.exists():
            summaries.append(
                {
                    "problem": problem_dir.name,
                    "generated_testbench": str(tb_path),
                    "evaluated_candidates": 0,
                    "status_counts": {"pass": 0, "fail": 0, "compile_failed": 0},
                    "passing_candidates": [],
                    "failing_candidates": [],
                    "compile_failed_candidates": [],
                    "error": "Missing generated tb.v",
                }
            )
            continue

        mutant_paths = sorted(problem_dir.glob("mutant_*.v"))
        results = [run_single(tb_path, mutant_path) for mutant_path in mutant_paths]
        summaries.append(build_problem_summary(problem_dir.name, results, tb_path))

    aggregate = {
        "problems_evaluated": len(summaries),
        "problems": summaries,
    }
    report_path.write_text(json.dumps(aggregate, indent=2) + "\n", encoding="utf-8")

    for summary in summaries:
        counts = summary["status_counts"]
        print(
            f"{summary['problem']}: pass={counts['pass']} fail={counts['fail']} "
            f"compile_failed={counts['compile_failed']}"
        )
    print(f"Wrote harness summary to {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
