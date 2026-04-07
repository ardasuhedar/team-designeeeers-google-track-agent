#!/usr/bin/env python3

"""Generate local testbench outputs for one or more external benchmark problems."""

from __future__ import annotations

import argparse
from pathlib import Path

from agent import generate_testbench
import constants


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate tb.v files for visible Google Track problems into a local output folder."
    )
    parser.add_argument(
        "--problems-folder",
        required=True,
        help="Path to a benchmark visible_problems directory or a single problem directory.",
    )
    parser.add_argument(
        "--output-root",
        default=constants.DEFAULT_GENERATED_ROOT,
        help="Local root where generated per-problem tb.v files will be written.",
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


def main() -> int:
    args = parse_args()
    problems_folder = Path(args.problems_folder).resolve()
    output_root = Path(args.output_root).resolve()

    if not problems_folder.exists():
        raise SystemExit(f"Problems folder does not exist: {problems_folder}")

    problem_dirs = iter_problem_dirs(problems_folder)
    if not problem_dirs:
        raise SystemExit(f"No problem directories found under: {problems_folder}")

    for problem_dir in problem_dirs:
        file_name_to_content: dict[str, str] = {}
        for file_path in sorted(problem_dir.iterdir()):
            if file_path.is_file():
                file_name_to_content[file_path.name] = file_path.read_text(encoding="utf-8")

        tb_text = generate_testbench(file_name_to_content)
        out_dir = output_root / problem_dir.name
        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / constants.TESTBENCH_FILE_NAME).write_text(tb_text, encoding="utf-8")
        print(f"Generated {out_dir / constants.TESTBENCH_FILE_NAME}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
