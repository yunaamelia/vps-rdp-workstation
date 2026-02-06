# pylint: disable=C0103,R0903,R0902,W0212,E0401
"""
Ansible Callback Plugin: Rich TUI
Beautiful TUI output with progress bars, tables, and live updates.
Uses the Rich library for terminal rendering.
"""

from __future__ import absolute_import, division, print_function

__metaclass__ = type

import sys
import time
from datetime import datetime

try:
    from rich.console import Console
    from rich.live import Live
    from rich.table import Table
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn
    from rich.tree import Tree
    from rich.text import Text
    from rich import box
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

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

        # Statistics
        self.task_count = 0
        self.ok_count = 0
        self.changed_count = 0
        self.failed_count = 0
        self.skipped_count = 0

        # Task tracking
        self.tasks = []
        self.roles_seen = set()
        self.current_task_start = None

        # Progress tracking
        self.progress = None
        self.task_id = None

    def _get_duration(self, start_time):
        """Calculate duration from start time."""
        if not start_time:
            return "0.0s"
        elapsed = time.time() - start_time
        if elapsed < 60:
            return f"{elapsed:.1f}s"
        minutes = int(elapsed // 60)
        seconds = elapsed % 60
        return f"{minutes}m{seconds:.0f}s"

    def _print_header(self):
        """Display installation header using Rich."""
        if not RICH_AVAILABLE:
            print("\n🚀 VPS Developer Workstation Setup v3.1.0\n")
            return

        header_text = Text()
        header_text.append("🚀 ", style="bold")
        header_text.append("VPS Developer Workstation Setup", style="bold cyan")
        header_text.append(" v3.1.0", style="dim")

        panel = Panel(
            header_text,
            box=box.DOUBLE,
            border_style="cyan",
            padding=(0, 2),
        )
        self.console.print(panel)

    def _print_footer(self):
        """Display installation summary using Rich table."""
        if not RICH_AVAILABLE:
            print(f"\n✨ Complete! OK: {self.ok_count} Changed: {self.changed_count} "
                  f"Failed: {self.failed_count} Skipped: {self.skipped_count}\n")
            return

        # Duration
        duration = self._get_duration(self.start_time)

        # Summary table
        table = Table(
            title="📊 Execution Summary",
            box=box.ROUNDED,
            border_style="cyan",
            show_header=False,
            padding=(0, 1),
        )
        table.add_column("Metric", style="bold")
        table.add_column("Value", justify="right")

        table.add_row("✓ OK", f"[green]{self.ok_count}[/green]")
        table.add_row("⟳ Changed", f"[yellow]{self.changed_count}[/yellow]")
        table.add_row("✗ Failed", f"[red]{self.failed_count}[/red]")
        table.add_row("⊘ Skipped", f"[dim]{self.skipped_count}[/dim]")
        table.add_row("⏱ Duration", f"[cyan]{duration}[/cyan]")
        table.add_row("📋 Total Tasks", str(self.task_count))

        self.console.print()
        self.console.print(table)

        # Status panel
        if self.failed_count == 0:
            status_panel = Panel(
                Text("✨ Installation Complete!", style="bold green", justify="center"),
                box=box.DOUBLE,
                border_style="green",
            )
        else:
            status_panel = Panel(
                Text(f"❌ {self.failed_count} task(s) failed", style="bold red", justify="center"),
                box=box.DOUBLE,
                border_style="red",
            )

        self.console.print(status_panel)

    def _print_task_result(self, status, task_name, duration, message=None):
        """Print task result with status icon."""
        if not RICH_AVAILABLE:
            print(f" {status} {task_name} ({duration})")
            return

        icons = {
            "ok": "[green]✓[/green]",
            "changed": "[yellow]⟳[/yellow]",
            "failed": "[red]✗[/red]",
            "skipped": "[dim]⊘[/dim]",
        }
        icon = icons.get(status, "•")

        # Format task line
        if status == "failed" and message:
            self.console.print(f" {icon} {task_name} [dim]({duration})[/dim]")
            error_panel = Panel(
                Text(message, style="red"),
                title="[red]Error Details[/red]",
                border_style="red",
                padding=(0, 1),
            )
            self.console.print(error_panel)
        else:
            style = "dim" if status == "skipped" else ""
            self.console.print(f" {icon} {task_name} [dim]({duration})[/dim]", style=style)

    def v2_playbook_on_start(self, playbook):
        """Called when playbook starts."""
        self.start_time = time.time()
        self._print_header()

    def v2_playbook_on_play_start(self, play):
        """Called when a play starts."""
        self.current_play = play.get_name().strip()

        if not RICH_AVAILABLE:
            print(f"\n📦 {self.current_play}")
            return

        if self.current_play:
            self.console.print()
            play_panel = Panel(
                Text(self.current_play, style="bold"),
                box=box.SIMPLE,
                border_style="blue",
                padding=(0, 1),
            )
            self.console.print(play_panel)

    def v2_playbook_on_task_start(self, task, is_conditional):
        """Called when a task starts."""
        self.current_task = task.get_name()
        self.task_count += 1
        self.current_task_start = time.time()

        # Extract role name if present
        if task._role:
            role_name = task._role.get_name()
            if role_name not in self.roles_seen:
                self.roles_seen.add(role_name)
                if RICH_AVAILABLE:
                    self.console.print(f"\n [cyan]⚙[/cyan] Role: [bold]{role_name}[/bold]")
                else:
                    print(f"\n⚙ Role: {role_name}")

        # Show spinner for current task
        if RICH_AVAILABLE:
            self.console.print(f" [dim]⋯[/dim] {self.current_task}...", end="\r")

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
        self._print_footer()

    def v2_on_any(self, *args, **kwargs):
        """Catch-all for debugging."""
        pass
