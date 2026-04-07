#!/usr/bin/env python3

import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List


ROOT = Path(__file__).resolve().parent
TESTBENCH_MODULE_NAME = "tb"
TEST_PASS_STRING = "TESTS PASSED"
TIMEOUT_SECONDS = 10


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Evaluate a generated Verilog testbench against a directory of RTL candidates."
    )
    parser.add_argument(
        "--tb",
        default=str(ROOT / "generated" / "tb.v"),
        help="Path to the generated testbench.",
    )
    parser.add_argument(
        "--rtl-dir",
        default=os.environ.get("RTL_DIR") or os.environ.get("GOOGLE_TRACK_RTL_DIR"),
        help="Path to the RTL candidate directory. Usually points into the external benchmark repo.",
    )
    parser.add_argument(
        "--spec",
        default=str(ROOT / "specs" / "problem.txt"),
        help="Path to the active natural language problem description.",
    )
    parser.add_argument(
        "--logs-dir",
        default=str(ROOT / "logs"),
        help="Directory for compiled outputs and raw logs.",
    )
    parser.add_argument(
        "--results-path",
        default=str(ROOT / "logs" / "eval_results.json"),
        help="Path for detailed evaluation results JSON.",
    )
    parser.add_argument(
        "--summary-path",
        default=str(ROOT / "reports" / "summary.json"),
        help="Path for compact summary JSON.",
    )
    return parser.parse_args()


def display_path(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return str(path.resolve())


def ensure_parent_directories(paths: List[Path]) -> None:
    for path in paths:
        path.parent.mkdir(parents=True, exist_ok=True)


def check_tools() -> List[str]:
    missing = []
    for tool in ("iverilog", "vvp"):
        if shutil.which(tool) is None:
            missing.append(tool)
    return missing


def discover_rtl_files(rtl_dir: Path) -> List[Path]:
    if not rtl_dir.exists():
        return []

    mutant_files = sorted(
        path for path in rtl_dir.glob("mutant_*.v") if path.is_file()
    )
    if mutant_files:
        return mutant_files

    return sorted(path for path in rtl_dir.glob("*.v") if path.is_file())


def detect_status(sim_stdout: str, sim_returncode: int) -> str:
    if TEST_PASS_STRING in sim_stdout:
        return "pass"
    return "fail"


def run_candidate(tb_path: Path, rtl_file: Path, logs_dir: Path) -> Dict[str, Any]:
    stem = rtl_file.stem
    binary_path = logs_dir / f"{stem}.out"
    compile_cmd = [
        "iverilog",
        "-g2012",
        "-o",
        str(binary_path),
        "-s",
        TESTBENCH_MODULE_NAME,
        str(tb_path),
        str(rtl_file),
    ]
    try:
        compile_proc = subprocess.run(
            compile_cmd,
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as exc:
        return {
            "rtl_file": display_path(rtl_file),
            "compile": {
                "returncode": None,
                "stdout": exc.stdout or "",
                "stderr": (exc.stderr or "") + f"\nCompilation timed out after {TIMEOUT_SECONDS} seconds",
                "command": compile_cmd,
            },
            "simulation": None,
            "status": "compile_failed",
        }

    result: Dict[str, Any] = {
        "rtl_file": display_path(rtl_file),
        "compile": {
            "returncode": compile_proc.returncode,
            "stdout": compile_proc.stdout,
            "stderr": compile_proc.stderr,
            "command": compile_cmd,
        },
        "simulation": None,
        "status": "compile_failed",
    }

    if compile_proc.returncode != 0:
        return result

    sim_cmd = ["vvp", str(binary_path)]
    try:
        sim_proc = subprocess.run(
            sim_cmd,
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as exc:
        result["simulation"] = {
            "returncode": None,
            "stdout": exc.stdout or "",
            "stderr": (exc.stderr or "") + f"\nExecution timed out after {TIMEOUT_SECONDS} seconds",
            "command": sim_cmd,
        }
        result["status"] = "fail"
        return result

    result["simulation"] = {
        "returncode": sim_proc.returncode,
        "stdout": sim_proc.stdout,
        "stderr": sim_proc.stderr,
        "command": sim_cmd,
    }
    result["status"] = detect_status(sim_proc.stdout or "", sim_proc.returncode)
    return result


def build_explanation(results: List[Dict[str, Any]]) -> str:
    pass_count = sum(1 for result in results if result["status"] == "pass")
    fail_count = sum(1 for result in results if result["status"] == "fail")
    compile_fail_count = sum(
        1 for result in results if result["status"] == "compile_failed"
    )

    if not results:
        return (
            "No RTL candidates were found. Point the evaluator at the visible problem's "
            "external rtl directory and rerun the experiment."
        )
    if pass_count == 1 and fail_count >= 1:
        return (
            "The current testbench discriminates between candidates: one implementation "
            "passes and at least one alternative fails."
        )
    if pass_count > 1:
        return (
            "Multiple RTL candidates still pass. The testbench should be refined with "
            "additional behavioral checks, corner cases, or protocol assertions."
        )
    if pass_count >= 1 and compile_fail_count == 0 and fail_count == 0:
        return (
            "All evaluated RTL candidates were classified as passing. This usually means "
            "the testbench is not yet discriminative enough."
        )
    if pass_count == 0 and compile_fail_count == 0:
        return (
            "No RTL candidate passed the current testbench. Recheck the problem "
            "understanding, module interface, timing assumptions, and expected outputs."
        )
    return (
        "The evaluation completed, but at least one candidate failed to compile or the "
        "result set is mixed. Inspect the raw logs for details."
    )


def build_summary(
    tb_path: Path,
    rtl_dir: Path,
    spec_path: Path,
    results: List[Dict[str, Any]],
) -> Dict[str, Any]:
    status_counts = {"pass": 0, "fail": 0, "compile_failed": 0}
    for result in results:
        status = result["status"]
        status_counts[status] = status_counts.get(status, 0) + 1

    return {
        "generated_testbench": display_path(tb_path),
        "rtl_dir": display_path(rtl_dir),
        "problem_spec": display_path(spec_path),
        "evaluated_candidates": len(results),
        "status_counts": status_counts,
        "explanation": build_explanation(results),
        "passing_candidates": [
            result["rtl_file"] for result in results if result["status"] == "pass"
        ],
        "failing_candidates": [
            result["rtl_file"] for result in results if result["status"] == "fail"
        ],
        "compile_failed_candidates": [
            result["rtl_file"]
            for result in results
            if result["status"] == "compile_failed"
        ],
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
    }


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()

    tb_path = Path(args.tb).resolve()
    rtl_dir = Path(args.rtl_dir).resolve() if args.rtl_dir else None
    spec_path = Path(args.spec).resolve()
    logs_dir = Path(args.logs_dir).resolve()
    results_path = Path(args.results_path).resolve()
    summary_path = Path(args.summary_path).resolve()

    logs_dir.mkdir(parents=True, exist_ok=True)
    ensure_parent_directories([results_path, summary_path])

    if not tb_path.exists():
        error = {
            "error": "Missing generated testbench",
            "required_file": display_path(tb_path),
        }
        write_json(results_path, error)
        write_json(
            summary_path,
            {
                "evaluated_candidates": 0,
                "status_counts": {"pass": 0, "fail": 0, "compile_failed": 0},
                "error": error["error"],
                "generated_testbench": display_path(tb_path),
                "explanation": "Evaluation could not run because the generated testbench is missing.",
            },
        )
        print(f"Error: {error['error']}: {error['required_file']}", file=sys.stderr)
        return 1

    if rtl_dir is None:
        error = {
            "error": "Missing RTL directory",
            "hint": "Pass --rtl-dir or set RTL_DIR / GOOGLE_TRACK_RTL_DIR.",
        }
        write_json(results_path, error)
        write_json(
            summary_path,
            {
                "evaluated_candidates": 0,
                "status_counts": {"pass": 0, "fail": 0, "compile_failed": 0},
                "error": error["error"],
                "generated_testbench": display_path(tb_path),
                "problem_spec": display_path(spec_path),
                "explanation": error["hint"],
            },
        )
        print(f"Error: {error['error']}. {error['hint']}", file=sys.stderr)
        return 1

    missing_tools = check_tools()
    if missing_tools:
        error = {
            "error": "Missing required external tools",
            "missing_tools": missing_tools,
        }
        write_json(results_path, error)
        write_json(
            summary_path,
            {
                "evaluated_candidates": 0,
                "status_counts": {"pass": 0, "fail": 0, "compile_failed": 0},
                "error": error["error"],
                "missing_tools": missing_tools,
                "generated_testbench": display_path(tb_path),
                "rtl_dir": display_path(rtl_dir),
                "problem_spec": display_path(spec_path),
                "explanation": "Evaluation could not run because required external Verilog tools are unavailable.",
            },
        )
        print(
            "Error: Missing required external tools: "
            + ", ".join(missing_tools),
            file=sys.stderr,
        )
        return 1

    rtl_files = discover_rtl_files(rtl_dir)
    if not rtl_files:
        empty_results: List[Dict[str, Any]] = []
        summary = build_summary(tb_path, rtl_dir, spec_path, empty_results)
        write_json(results_path, empty_results)
        write_json(summary_path, summary)
        print(
            f"Warning: No RTL candidates found in {display_path(rtl_dir)}",
            file=sys.stderr,
        )
        return 0

    results = [run_candidate(tb_path, rtl_file, logs_dir) for rtl_file in rtl_files]
    summary = build_summary(tb_path, rtl_dir, spec_path, results)
    write_json(results_path, results)
    write_json(summary_path, summary)

    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
