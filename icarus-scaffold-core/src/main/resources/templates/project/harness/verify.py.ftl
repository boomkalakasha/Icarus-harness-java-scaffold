#!/usr/bin/env python3
"""Bounded local preflight/build evidence. Does not execute task-provided commands."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import uuid


class BuildCleanupError(RuntimeError):
    """The timed-out build's process-tree cleanup could not be confirmed."""


def run_build(command, root, timeout=600):
    process = subprocess.Popen(command, cwd=root, stdout=sys.stderr, stderr=sys.stderr,
                               start_new_session=os.name != "nt")
    try:
        return process.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        try:
            if os.name == "nt":
                cleanup = subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"],
                                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                         timeout=10, check=False)
                if cleanup.returncode != 0:
                    raise OSError("process-tree cleanup was not confirmed")
            else:
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
            process.wait(timeout=5)
        except (OSError, subprocess.SubprocessError) as error:
            # Stop the direct child as a fallback, without claiming tree cleanup.
            try:
                if process.poll() is None:
                    process.kill()
                process.wait(timeout=5)
            except (OSError, subprocess.SubprocessError):
                pass
            raise BuildCleanupError() from error
        raise


def confined(root, relative):
    path = Path(relative)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError("context paths must be confined project-relative files")
    result = (root / path).resolve()
    if not result.is_relative_to(root) or not result.is_file():
        raise ValueError("context reference is missing or escapes the project")
    return result


def preflight(root, task):
    if not isinstance(task, dict):
        raise ValueError("task must be an object")
    for key in ("goal", "nextAction"):
        if not isinstance(task.get(key), str) or not task[key].strip():
            raise ValueError(key + " must describe the current task")
    if task.get("operationMode") not in {"READ_ONLY_REVIEW", "PLAN_ONLY", "IMPLEMENT_AND_VERIFY"}:
        raise ValueError("unknown operation mode")
    for key in ("allowedEffects", "context", "requiredAnswers", "steps"):
        if not isinstance(task.get(key), list):
            raise ValueError(key + " must be a list")
    if not task["context"] or not task["steps"]:
        raise ValueError("context and complete approved steps are required")
    for ref in task["context"]:
        if not isinstance(ref, str):
            raise ValueError("context references must be strings")
        confined(root, ref)
    if any(not isinstance(effect, str) or not effect.strip() for effect in task["allowedEffects"]):
        raise ValueError("allowed effects must be nonempty strings")
    ids = set()
    for step in task["steps"]:
        if not isinstance(step, dict) or not isinstance(step.get("id"), str) or not step["id"].strip() or step["id"] in ids:
            raise ValueError("steps need unique nonempty IDs")
        ids.add(step["id"])
        if step.get("status") not in {"pending", "in_progress", "done"} or not isinstance(step.get("acceptance"), str) or not step["acceptance"].strip():
            raise ValueError("each step needs a valid state and acceptance criterion")
    pending = []
    for answer in task["requiredAnswers"]:
        if not isinstance(answer, dict) or not isinstance(answer.get("question"), str) or not answer["question"].strip():
            raise ValueError("required answers need a question")
        if not isinstance(answer.get("answer"), str) or not answer["answer"].strip():
            pending.append(answer["question"])
    return pending


def maven_command(root):
    wrapper = root / ("mvnw.cmd" if os.name == "nt" else "mvnw")
    executable = str(wrapper) if wrapper.is_file() else shutil.which("mvn")
    if not executable:
        return None
    if os.name == "nt" and executable.lower().endswith((".cmd", ".bat")):
        return ["cmd", "/d", "/c", executable, "-B", "-ntp", "verify"]
    return (["sh", executable] if wrapper.is_file() and os.name != "nt" else [executable]) + ["-B", "-ntp", "verify"]


def git_identity(root):
    try:
        top = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], cwd=root, stderr=subprocess.DEVNULL, text=True, timeout=10).strip()
        if Path(top).resolve() != root:
            return {"commit": "UNAVAILABLE", "tree": "unavailable"}
        sha = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, stderr=subprocess.DEVNULL, text=True, timeout=10).strip()
        dirty = subprocess.check_output(["git", "status", "--porcelain"], cwd=root, stderr=subprocess.DEVNULL, text=True, timeout=10).strip()
        return {"commit": sha, "tree": "dirty" if dirty else "clean"}
    except (OSError, subprocess.SubprocessError):
        return {"commit": "UNAVAILABLE", "tree": "unavailable"}


def verify(root, build=False):
    root = root.resolve()
    report = {"timestamp": datetime.now(timezone.utc).isoformat(), "preflight": "FAIL", "sourceBuild": "NOT_RUN", "runtime": "NOT_RUN", "acceptance": "NOT_RUN", "release": "NOT_RUN", "scope": "PENDING", "git": git_identity(root)}
    try:
        raw = confined(root, "harness/task.json").read_bytes()
        report["taskSha256"] = hashlib.sha256(raw).hexdigest()
        task = json.loads(raw)
        pending = preflight(root, task)
        report["preflight"] = "PASS"
        report["scope"] = "RECORDED_COMPLETE_PENDING_REVIEW" if all(s["status"] == "done" for s in task["steps"]) else "PENDING"
        if pending:
            report.update(status="WAITING_FOR_REQUIRED_ANSWER", pendingQuestions=pending)
            return report, 2
        if build:
            if task["operationMode"] != "IMPLEMENT_AND_VERIFY" or "local-build-artifacts" not in task["allowedEffects"]:
                report["status"] = "BUILD_NOT_AUTHORIZED_BY_TASK"
                return report, 2
            command = maven_command(root)
            if command is None:
                report["status"] = "BUILD_TOOL_UNAVAILABLE"
                return report, 2
            build_code = run_build(command, root)
            report["sourceBuild"] = "PASS" if build_code == 0 else "FAIL"
            report["buildExitCode"] = build_code
            report["status"] = "LOCAL_CHECKS_PASS" if build_code == 0 else "BUILD_FAILED"
            return report, 0 if build_code == 0 else 1
        report["status"] = "PREFLIGHT_PASS"
        return report, 0
    except BuildCleanupError:
        report.update(status="CHECK_TIMEOUT_CLEANUP_UNCONFIRMED", sourceBuild="FAIL")
        return report, 1
    except subprocess.TimeoutExpired:
        report.update(status="CHECK_TIMEOUT", sourceBuild="FAIL")
        return report, 1
    except (ValueError, TypeError, KeyError, OSError):
        report["status"] = "INVALID_CONTEXT_OR_CHECK_FAILED"
        return report, 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", action="store_true")
    parser.add_argument("--record", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    # Recording is a separate local write; validate permission before it occurs.
    if args.record:
        try:
            task = json.loads(confined(root, "harness/task.json").read_bytes())
            if not isinstance(task, dict):
                raise ValueError("task must be an object")
            if task.get("operationMode") == "READ_ONLY_REVIEW" or "local-evidence-records" not in task.get("allowedEffects", []):
                raise ValueError("recording is outside the declared local effects")
        except (ValueError, TypeError, OSError):
            print(json.dumps({"status": "RECORD_NOT_AUTHORIZED_BY_TASK"}))
            return 2
    report, code = verify(root, args.build)
    if args.record:
        directory = root / "harness" / "results"
        if directory.is_symlink() or not directory.resolve().is_relative_to(root):
            print(json.dumps({"status": "UNSAFE_RECORD_DIRECTORY"}))
            return 1
        directory.mkdir(exist_ok=True)
        destination = directory / (uuid.uuid4().hex + ".json")
        with destination.open("x", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2)
            handle.write("\n")
        report["record"] = destination.relative_to(root).as_posix()
    print(json.dumps(report, indent=2))
    return code


if __name__ == "__main__":
    raise SystemExit(main())
