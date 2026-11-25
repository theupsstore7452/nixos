"""Remove only stale Cargo caches, preserving recent and active build output."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import time


def process_references():
    references = []
    compiler_running = False
    for proc in Path("/proc").glob("[0-9]*"):
        try:
            if proc.stat().st_uid != os.getuid():
                continue
            command = (proc / "comm").read_text().strip()
            compiler_running |= command in {"cargo", "rustc", "rustdoc"}
        except (OSError, ValueError):
            continue
        for name in ("cmdline", "environ", "maps"):
            try:
                references.append((proc / name).read_bytes())
            except OSError:
                pass
        try:
            links = [proc / "cwd", proc / "exe", *(proc / "fd").iterdir()]
        except OSError:
            links = [proc / "cwd", proc / "exe"]
        for link in links:
            try:
                references.append(os.fsencode(os.readlink(link)))
            except OSError:
                pass
    return compiler_running, references


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    projects = Path.home() / "Projects"
    if not projects.is_dir():
        return
    compiler_running, references = process_references()
    if compiler_running:
        print("Skipping Cargo cache cleanup: a Rust build is running.")
        return
    cutoff = time.time() - 30 * 86400
    for project in projects.iterdir():
        if project.is_symlink() or not (project / "Cargo.toml").is_file():
            continue
        target = project / "target"
        if target.is_symlink() or not target.is_dir():
            continue
        try:
            marker = (target / "CACHEDIR.TAG").read_text()
        except OSError:
            continue
        if not marker.startswith("Signature: 8a477f597d28d172789f06886806bc55"):
            continue
        encoded = os.fsencode(str(target))
        if any(encoded in reference for reference in references):
            print(f"Keeping active Cargo cache: {target}")
            continue
        # Never remove a target directory if Git tracks files inside it.
        tracked = subprocess.run(
            ["git", "-C", str(project), "ls-files", "--", "target"],
            capture_output=True,
        )
        if tracked.stdout:
            print(f"Keeping Cargo directory containing tracked files: {target}")
            continue
        if tracked.returncode and b"not a git repository" not in tracked.stderr:
            print(f"Keeping Cargo cache after Git inspection error: {target}")
            continue
        try:
            newest = target.stat().st_mtime
            for root, dirs, files in os.walk(target):
                dirs[:] = [d for d in dirs if not (Path(root) / d).is_symlink()]
                newest = max(newest, Path(root).stat().st_mtime)
                for name in files:
                    newest = max(newest, (Path(root) / name).lstat().st_mtime)
            if newest >= cutoff:
                print(f"Keeping Cargo cache used within 30 days: {target}")
                continue
            # Recheck immediately before deletion in case a build just started.
            busy, latest_references = process_references()
            if busy or any(encoded in reference for reference in latest_references):
                print(f"Keeping newly active Cargo cache: {target}")
                continue
            if args.dry_run:
                print(f"Would remove inactive Cargo cache: {target}")
            else:
                shutil.rmtree(target)
                print(f"Removed inactive Cargo cache: {target}")
        except OSError as error:
            print(f"Could not finish Cargo cache cleanup: {target}: {error}")


if __name__ == "__main__":
    main()
