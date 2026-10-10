"""Exercise the bundled verifier's permission, dependency and evidence boundaries."""
import importlib.machinery
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import Mock, patch


TEMPLATE = Path(__file__).resolve().parents[1] / "icarus-scaffold-core/src/main/resources/templates/project/harness/verify.py.ftl"
loader = importlib.machinery.SourceFileLoader("generated_harness", str(TEMPLATE))
spec = importlib.util.spec_from_loader(loader.name, loader)
harness = importlib.util.module_from_spec(spec)
loader.exec_module(harness)


class GeneratedHarnessTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        (self.root / "harness").mkdir()
        (self.root / "AGENTS.md").write_text("Guide", encoding="utf-8")
        self.task = {"goal": "Verify the approved scope", "nextAction": "Inspect the result", "operationMode": "IMPLEMENT_AND_VERIFY", "allowedEffects": ["local-build-artifacts", "local-evidence-records"], "context": ["AGENTS.md"], "requiredAnswers": [], "steps": [{"id": "first", "status": "pending", "acceptance": "Relevant case passes"}]}
        self.save()

    def save(self):
        (self.root / "harness/task.json").write_text(json.dumps(self.task), encoding="utf-8")

    def verify(self, build=False):
        with patch.object(harness, "git_identity", return_value={"commit": "UNAVAILABLE", "tree": "unavailable"}):
            return harness.verify(self.root, build)

    def test_unanswered_required_question_blocks_build_and_keeps_task(self):
        self.task["requiredAnswers"] = [{"question": "Which output is intended?", "answer": None, "minutesElapsed": 1}]
        self.save()
        original = (self.root / "harness/task.json").read_bytes()
        with patch.object(harness, "maven_command", side_effect=AssertionError("must not build")):
            result, code = self.verify(True)
        self.assertEqual(2, code)
        self.assertEqual("WAITING_FOR_REQUIRED_ANSWER", result["status"])
        self.assertEqual("NOT_RUN", result["sourceBuild"])
        self.assertEqual(original, (self.root / "harness/task.json").read_bytes())

    def test_read_only_and_plan_modes_block_build(self):
        for mode in ("READ_ONLY_REVIEW", "PLAN_ONLY"):
            self.task["operationMode"] = mode
            self.save()
            with patch.object(harness, "maven_command", side_effect=AssertionError("must not build")):
                result, code = self.verify(True)
            self.assertEqual(2, code)
            self.assertEqual("BUILD_NOT_AUTHORIZED_BY_TASK", result["status"])

    def test_passing_build_does_not_complete_scope_or_promote_other_evidence(self):
        with patch.object(harness, "maven_command", return_value=["mvn", "-B", "-ntp", "verify"]), patch.object(harness, "run_build", return_value=0):
            result, code = self.verify(True)
        self.assertEqual(0, code)
        self.assertEqual("PASS", result["sourceBuild"])
        self.assertEqual("PENDING", result["scope"])
        self.assertTrue(all(result[k] == "NOT_RUN" for k in ("runtime", "acceptance", "release")))
        self.assertEqual("pending", json.loads((self.root / "harness/task.json").read_bytes())["steps"][0]["status"])

    def test_recorded_done_is_not_independent_acceptance(self):
        self.task["steps"][0]["status"] = "done"
        self.save()
        result, code = self.verify()
        self.assertEqual(0, code)
        self.assertEqual("RECORDED_COMPLETE_PENDING_REVIEW", result["scope"])
        self.assertEqual("NOT_RUN", result["acceptance"])

    def test_invalid_context_and_task_types_fail_before_build(self):
        for context in (["../outside"], ["missing.md"], [None]):
            self.task["context"] = context
            self.save()
            with patch.object(harness, "maven_command", side_effect=AssertionError("must not build")):
                result, code = self.verify(True)
            self.assertEqual(1, code)
            self.assertEqual("FAIL", result["preflight"])
        (self.root / "harness/task.json").write_text("[]", encoding="utf-8")
        self.assertEqual(1, self.verify()[1])

    def test_build_effect_and_valid_steps_are_required(self):
        self.task["allowedEffects"] = []
        self.save()
        self.assertEqual("BUILD_NOT_AUTHORIZED_BY_TASK", self.verify(True)[0]["status"])
        self.task["steps"] = []
        self.save()
        self.assertEqual("FAIL", self.verify()[0]["preflight"])

    def test_task_supplied_command_does_not_reach_process_execution(self):
        self.task["command"] = "untrusted-task-command"
        self.save()
        fixed = ["mvn", "-B", "-ntp", "verify"]
        with patch.object(harness, "maven_command", return_value=fixed), patch.object(harness, "run_build", return_value=0) as run:
            self.verify(True)
            self.assertEqual(fixed, run.call_args.args[0])

    def test_windows_timeout_cleans_only_the_owned_process_tree(self):
        process = Mock(pid=777)
        process.wait.side_effect = [subprocess.TimeoutExpired(["mvn"], 1), -9]
        with patch.object(harness.os, "name", "nt"), patch.object(harness.subprocess, "Popen", return_value=process), patch.object(harness.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as cleanup:
            with self.assertRaises(subprocess.TimeoutExpired):
                harness.run_build(["mvn"], self.root, timeout=1)
        self.assertEqual(["taskkill", "/PID", "777", "/T", "/F"], cleanup.call_args.args[0])
        process.wait.assert_called_with(timeout=5)

    def test_cleanup_failure_is_not_reported_as_confirmed_timeout(self):
        process = Mock(pid=777)
        process.poll.return_value = None
        process.wait.side_effect = subprocess.TimeoutExpired(["mvn"], 1)
        with patch.object(harness.os, "name", "nt"), patch.object(harness.subprocess, "Popen", return_value=process), patch.object(harness.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)):
            with self.assertRaises(harness.BuildCleanupError):
                harness.run_build(["mvn"], self.root, timeout=1)
        process.kill.assert_called_once()
        with patch.object(harness, "maven_command", return_value=["mvn"]), patch.object(harness, "run_build", side_effect=harness.BuildCleanupError):
            result, code = self.verify(True)
        self.assertEqual(1, code)
        self.assertEqual("CHECK_TIMEOUT_CLEANUP_UNCONFIRMED", result["status"])
        self.assertEqual("FAIL", result["sourceBuild"])

    def test_actual_timeout_stops_child_writes_and_preserves_unrelated_process(self):
        child_source = "from pathlib import Path; import time\np=Path('heartbeat')\nwhile True:\n p.write_text(str(time.time())); time.sleep(0.03)"
        parent_source = "import subprocess, sys, time\nsubprocess.Popen([sys.executable, '-c', " + repr(child_source) + "])\ntime.sleep(60)"
        unrelated = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(60)"])
        self.addCleanup(lambda: unrelated.poll() is None and unrelated.kill())
        try:
            with self.assertRaises(subprocess.TimeoutExpired):
                harness.run_build([sys.executable, "-c", parent_source], self.root, timeout=1.5)
            heartbeat = self.root / "heartbeat"
            self.assertTrue(heartbeat.is_file(), "child must have started before the timeout")
            original = heartbeat.read_bytes()
            time.sleep(0.2)
            self.assertEqual(original, heartbeat.read_bytes(), "child must stop writing after timeout cleanup")
            self.assertIsNone(unrelated.poll(), "unrelated process must remain running")
        finally:
            unrelated.kill()
            unrelated.wait(timeout=5)

    def test_parent_git_checkout_is_not_generated_project_identity(self):
        with patch.object(harness.subprocess, "check_output", return_value=str(self.root.parent)) as call:
            result = harness.git_identity(self.root)
            self.assertEqual("UNAVAILABLE", result["commit"])
            self.assertEqual(1, call.call_count)

    def test_recording_keeps_prior_evidence_and_respects_read_only(self):
        script = self.root / "harness/verify.py"
        script.write_text(TEMPLATE.read_text(encoding="utf-8"), encoding="utf-8")
        with patch.object(harness, "__file__", str(script)), patch.object(harness.sys, "argv", [str(script), "--record"]), patch.object(harness, "git_identity", return_value={"commit": "UNAVAILABLE", "tree": "unavailable"}), patch("builtins.print"):
            self.assertEqual(0, harness.main())
            first = {p.name: p.read_bytes() for p in (self.root / "harness/results").glob("*.json")}
            self.assertEqual(0, harness.main())
            files = list((self.root / "harness/results").glob("*.json"))
            self.assertEqual(2, len(files))
            self.assertTrue(all((self.root / "harness/results" / p).read_bytes() == data for p, data in first.items()))
            self.task["operationMode"] = "READ_ONLY_REVIEW"
            self.save()
            self.assertEqual(2, harness.main())
            self.assertEqual(2, len(list((self.root / "harness/results").glob("*.json"))))


if __name__ == "__main__":
    unittest.main()
