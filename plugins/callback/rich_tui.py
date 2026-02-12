# pylint: disable=C0103,R0903,R0902,W0212,E0401
"""
Ansible Callback Plugin: Rich TUI
Beautiful TUI output with progress bars, tables, and live updates.
Uses the Rich library for terminal rendering.
"""

from __future__ import absolute_import, division, print_function

__metaclass__ = type

import time
import os
from datetime import datetime

try:
    from rich.console import Console, Group
    from rich.live import Live
    from rich.layout import Layout
    from rich.table import Table
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn
    from rich.text import Text
    from rich import box
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False
    class Dummy:
        pass

    Console = Group = Live = Layout = Table = Panel = Progress = SpinnerColumn = TextColumn = BarColumn = TimeElapsedColumn = Text = Dummy
    
    class Box:
        HEAVY_HEAD = None
        SIMPLE = None
        ROUNDED = None
    box = Box

try:
    from ansible.plugins.callback import CallbackBase
except ImportError:
    class CallbackBase:
        """Mock class for pylint when ansible is not installed"""
        CALLBACK_VERSION = 2.0
        CALLBACK_TYPE = "stdout"
        CALLBACK_NAME = "rich_tui"


DOCUMENTATION = """
    name: rich_tui
    type: stdout
    short_description: Beautiful TUI output with Rich library
    description:
        - Modern TUI callback plugin using Rich library
        - Live progress bars with ETA
        - Colored tables for task summary
        - Tree view for role hierarchy
        - Error panels with context
    requirements:
        - rich>=13.0.0 (pip install rich)
    version_added: "3.1.0"
"""


class CallbackModule(CallbackBase):
    """
    Rich TUI Callback Plugin for beautiful Ansible output.
    """

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "stdout"
    CALLBACK_NAME = "rich_tui"
    CALLBACK_NEEDS_WHITELIST = False

    def __init__(self):
        super().__init__()
        self.console = Console() if RICH_AVAILABLE else None
        self.start_time = None
        self.current_play = None
        self.current_task = None
        self.current_role = None
        self.current_task_start = None

        # Configuration
        self.log_level = os.environ.get("VPS_LOG_LEVEL", "full").lower()

        # Statistics
        self.task_count = 0
        self.ok_count = 0
        self.changed_count = 0
        self.failed_count = 0
        self.skipped_count = 0

        # UI Components
        self.live = None
        self.layout = None
        self.job_progress = None
        self.task_id = None
        self.log_messages = []  # Store recent logs for display

    def _get_duration(self, start_time):
        """Calculate duration string."""
        if not start_time: return "0.0s"
        return f"{time.time() - start_time:.1f}s"

    def _print_footer(self):
        """Print final stats."""
        if not RICH_AVAILABLE or not self.console:
            return

        summary = Text()
        summary.append("\nExecution Summary\n", style="bold underline")
        summary.append(f"OK: {self.ok_count}  ", style="green")
        summary.append(f"Changed: {self.changed_count}  ", style="yellow")
        summary.append(f"Failed: {self.failed_count}  ", style="red")
        summary.append(f"Skipped: {self.skipped_count}", style="dim")
        
        self.console.print(Panel(summary, border_style="cyan", box=box.ROUNDED))

    def v2_playbook_on_start(self, playbook):
        """Called when playbook starts."""
        self.start_time = time.time()
        
        if not RICH_AVAILABLE:
            print("\n🚀 VPS Developer Workstation Setup v3.1.0\n")
            return

        # Initialize Layout
        self.layout = Layout()
        self.layout.split(
            Layout(name="header", size=3),
            Layout(name="body"),
            Layout(name="footer", size=3)
        )
        
        # Header
        header_text = Text()
        header_text.append("🚀 ", style="bold")
        header_text.append("VPS Developer Workstation Setup", style="bold cyan")
        header_text.append(" v3.1.0", style="dim")
        self.layout["header"].update(Panel(header_text, border_style="cyan", box=box.HEAVY_HEAD))

        # Footer (Progress)
        self.job_progress = Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(bar_width=None),
            TimeElapsedColumn(),
            expand=True
        )
        self.task_id = self.job_progress.add_task("Initializing...", total=None)
        self.layout["footer"].update(Panel(self.job_progress, border_style="blue", box=box.SIMPLE))

        # Start Live Display
        self.live = Live(self.layout, refresh_per_second=10, console=self.console)
        self.live.start()

    def _update_body(self, renderable):
        """Update the body section with new logs."""
        if not self.live: return

        self.log_messages.append(renderable)
        # Keep last 20 messages to prevent overflow visual clutter
        visible_logs = self.log_messages[-15:] if self.log_level == "minimal" else self.log_messages[-30:]
        self.layout["body"].update(Panel(Group(*visible_logs), title="Activity Log", border_style="white", box=box.ROUNDED))

    def v2_playbook_on_play_start(self, play):
        """Called when a play starts."""
        self.current_play = play.get_name().strip()
        if self.job_progress:
            self.job_progress.update(self.task_id, description=f"Play: {self.current_play}")

    def v2_playbook_on_task_start(self, task, is_conditional):
        """Called when a task starts."""
        self.current_task = task.get_name()
        self.task_count += 1
        self.current_task_start = time.time()
        
        if self.job_progress:
            self.job_progress.update(self.task_id, description=f"Running: {self.current_task}")

    def _print_task_result(self, status, task_name, duration, message=None):
        """Print task result to body."""
        if not self.live: return

        icons = {
            "ok": "[green]✓[/green]",
            "changed": "[yellow]⟳[/yellow]",
            "failed": "[red]✗[/red]",
            "skipped": "[dim]⊘[/dim]",
        }
        icon = icons.get(status, "•")
        
        # Minimal Mode: Only show changed/failed
        if self.log_level == "minimal" and status in ["ok", "skipped"]:
            return

        log_line = f"{icon} {task_name} [dim]({duration})[/dim]"
        if status == "failed":
            self._update_body(Text.from_markup(f"{log_line}\n[red]{message}[/red]"))
        else:
            style = "dim" if status == "skipped" else ""
            self._update_body(Text.from_markup(log_line, style=style))

    def v2_runner_on_ok(self, result):
        """Called when a task succeeds."""
        self.ok_count += 1
        changed = result._result.get("changed", False)
        duration = self._get_duration(self.current_task_start)

        if changed:
            self.changed_count += 1
            self._print_task_result("changed", self.current_task, duration)
        else:
            self._print_task_result("ok", self.current_task, duration)

    def v2_runner_on_failed(self, result, ignore_errors=False):
        """Called when a task fails."""
        self.failed_count += 1
        duration = self._get_duration(self.current_task_start)
        message = result._result.get("msg", "")

        if ignore_errors:
            self._print_task_result("skipped", f"{self.current_task} (ignored)", duration)
        else:
            self._print_task_result("failed", self.current_task, duration, message)

    def v2_runner_on_skipped(self, result):
        """Called when a task is skipped."""
        self.skipped_count += 1
        duration = self._get_duration(self.current_task_start)
        self._print_task_result("skipped", self.current_task, duration)

    def v2_runner_on_unreachable(self, result):
        """Called when host is unreachable."""
        self.failed_count += 1
        duration = self._get_duration(self.current_task_start)
        message = result._result.get("msg", "Host unreachable")
        self._print_task_result("failed", f"{self.current_task} (unreachable)", duration, message)

    def v2_playbook_on_stats(self, stats):
        """Called at the end with statistics."""
        if self.live:
            self.live.stop()
        self._print_footer()

    def v2_on_any(self, *args, **kwargs):
        """Catch-all for debugging."""
        pass
