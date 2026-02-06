# pylint: disable=C0103,R0903,R0902,W0212,E0401
"""
Ansible Callback Plugin: Clean Progress
Displays a beautiful, minimalist progress output with spinners and colors.
"""

from __future__ import absolute_import, division, print_function

__metaclass__ = type

import sys
from datetime import datetime

try:
    from ansible.plugins.callback import CallbackBase
except ImportError:
    # pylint: disable=too-few-public-methods
    class CallbackBase:
        """Mock class for pylint when ansible is not installed"""

        CALLBACK_VERSION = 2.0
        CALLBACK_TYPE = "stdout"
        CALLBACK_NAME = "clean_progress"


DOCUMENTATION = """
    name: clean_progress
    type: stdout
    short_description: Beautiful progress output with spinners and colors
    description:
        - Custom callback plugin for VPS RDP Workstation setup
        - Displays unicode spinners, checkmarks, and colored output
        - Provides clean, professional installation progress
    version_added: "3.0.0"
"""


# ANSI Color codes
class Colors:
    """ANSI color codes"""

    HEADER = "\033[95m"
    BLUE = "\033[94m"
    CYAN = "\033[96m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    RESET = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


# Unicode symbols
class Symbols:
    """Unicode symbols for output"""

    CHECK = "✓"
    CROSS = "✗"
    WARNING = "⚠"
    INFO = "ℹ"
    ARROW = "→"
    SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    ROCKET = "🚀"
    SPARKLES = "✨"
    LOCK = "🔒"
    PACKAGE = "📦"
    GEAR = "⚙"


class CallbackModule(CallbackBase):
    """
    Custom callback plugin for beautiful VPS RDP Workstation output
    """

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "stdout"
    CALLBACK_NAME = "clean_progress"
    CALLBACK_NEEDS_WHITELIST = False

    def __init__(self):
        super().__init__()
        self.start_time = None
        self.current_task = None
        self.task_count = 0
        self.ok_count = 0
        self.changed_count = 0
        self.failed_count = 0
        self.skipped_count = 0
        self.spinner_idx = 0

    def _print(self, msg, color=None):
        """Print with optional color"""
        if color:
            sys.stdout.write(f"{color}{msg}{Colors.RESET}\n")
        else:
            sys.stdout.write(f"{msg}\n")
        sys.stdout.flush()

    def _print_header(self):
        """Display installation header"""
        header = f"""
{Colors.CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.RESET}
{Colors.BOLD} {Symbols.ROCKET} VPS Developer Workstation Setup v3.0.0{Colors.RESET}
{Colors.CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.RESET}
"""
        sys.stdout.write(header)
        sys.stdout.flush()

    def _print_footer(self, stats):  # pylint: disable=unused-argument
        """Display installation summary"""
        elapsed = ""
        if self.start_time:
            elapsed = str(datetime.now() - self.start_time).split(".", maxsplit=1)[0]

        footer = f"""
{Colors.CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.RESET}
{Colors.BOLD} {Symbols.SPARKLES} Installation Complete!{Colors.RESET}
{Colors.CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.RESET}

 {Colors.GREEN}{Symbols.CHECK} OK:{Colors.RESET} {self.ok_count}  \
{Colors.YELLOW}Changed:{Colors.RESET} {self.changed_count}  \
{Colors.RED}{Symbols.CROSS} Failed:{Colors.RESET} {self.failed_count}  \
Skipped: {self.skipped_count}
 {Symbols.GEAR} Duration: {elapsed}

{Colors.CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.RESET}
"""
        sys.stdout.write(footer)
        sys.stdout.flush()

    def v2_playbook_on_start(self, playbook):  # pylint: disable=unused-argument
        """Called when playbook starts"""
        self.start_time = datetime.now()
        self._print_header()

    def v2_playbook_on_play_start(self, play):
        """Called when a play starts"""
        name = play.get_name().strip()
        if name:
            self._print(f"\n {Symbols.PACKAGE} {name}", Colors.BOLD)

    def v2_playbook_on_task_start(self, task, is_conditional):  # pylint: disable=unused-argument
        """Called when a task starts"""
        self.current_task = task.get_name()
        self.task_count += 1
        # Show spinner
        spinner = Symbols.SPINNER[self.spinner_idx % len(Symbols.SPINNER)]
        self.spinner_idx += 1
        sys.stdout.write(f"\r {spinner} {self.current_task}...")
        sys.stdout.flush()

    def v2_runner_on_ok(self, result):
        """Called when a task succeeds"""
        self.ok_count += 1
        changed = result._result.get("changed", False)
        if changed:
            self.changed_count += 1
            sys.stdout.write(
                f"\r {Colors.YELLOW}{Symbols.CHECK}{Colors.RESET} {self.current_task} (changed)\n"
            )
        else:
            sys.stdout.write(
                f"\r {Colors.GREEN}{Symbols.CHECK}{Colors.RESET} {self.current_task}\n"
            )
        sys.stdout.flush()

    def v2_runner_on_failed(self, result, ignore_errors=False):
        """Called when a task fails"""
        self.failed_count += 1
        if ignore_errors:
            sys.stdout.write(
                f"\r {Colors.YELLOW}{Symbols.WARNING}{Colors.RESET} {self.current_task} (ignored)\n"
            )
        else:
            sys.stdout.write(
                f"\r {Colors.RED}{Symbols.CROSS}{Colors.RESET} {self.current_task}\n"
            )
            # Show error details
            msg = result._result.get("msg", "")
            if msg:
                self._print(f"   {Colors.RED}{Symbols.ARROW} {msg}{Colors.RESET}")
        sys.stdout.flush()

    def v2_runner_on_skipped(self, result):  # pylint: disable=unused-argument
        """Called when a task is skipped"""
        self.skipped_count += 1
        sys.stdout.write(
            f"\r {Colors.BLUE}-{Colors.RESET} {self.current_task} (skipped)\n"
        )
        sys.stdout.flush()

    def v2_playbook_on_stats(self, stats):
        """Called at the end with statistics"""
        self._print_footer(stats)

    def v2_on_any(self, *args, **kwargs):
        """Catch-all for debugging"""
