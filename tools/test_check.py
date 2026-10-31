import subprocess
import unittest
from unittest.mock import patch

import check


class CheckFailureTest(unittest.TestCase):
    def test_engine_success_code_cannot_hide_errors_or_empty_suites(self):
        for output in ("", "UNIT: 0 passed, 0 failed\n", "UNIT: 1 passed, 1 failed\n",
                       "UNIT: 1 passed, 0 failed\nERROR: broken\n"):
            result = subprocess.CompletedProcess([], 0, stdout=output)
            with self.subTest(output=output), patch("check.subprocess.run", return_value=result), patch("builtins.print"):
                with self.assertRaises(SystemExit):
                    check.run(["fixture"], "UNIT:")

    def test_nonempty_success_summary(self):
        result = subprocess.CompletedProcess([], 0, stdout="UNIT: 2 passed, 0 failed\n")
        with patch("check.subprocess.run", return_value=result), patch("builtins.print"):
            check.run(["fixture"], "UNIT:")
