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
from typing import Any, TYPE_CHECKING, cast

try:
    from rich.console import Console, Group
    from rich.live import Live
    from rich.layout import Layout
    from rich.table import Table
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn
    from rich.text import Text
    from rich import box
    from rich.tree import Tree
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False
    # Define dummy classes to satisfy static analysis
    class Dummy:
        """Dummy class for missing rich dependencies."""
        def __init__(self, *args, **kwargs): pass
        def __getitem__(self, key): return self
        def __setitem__(self, key, value): pass
        def __call__(self, *args, **kwargs): return self
        def split(self, *args, **kwargs): pass
        def split_column(self, *args, **kwargs): pass
        def split_row(self, *args, **kwargs): pass
        def update(self, *args, **kwargs): pass
        def start(self): pass
        def stop(self): pass
        def add_task(self, *args, **kwargs): pass
        def append(self, *args, **kwargs): pass
        def print(self, *args, **kwargs): pass
        def add(self, *args, **kwargs): pass
        def add_row(self, *args, **kwargs): pass
        def add_column(self, *args, **kwargs): pass
        @classmethod
        def from_markup(cls, *args, **kwargs): return cls()
        @classmethod
        def grid(cls, *args, **kwargs): return cls()

    Console = Group = Live = Layout = Table = Panel = Progress = SpinnerColumn = TextColumn = BarColumn = TimeElapsedColumn = Text = Tree = cast(Any, Dummy)

    class Box:
        HEAVY_HEAD = None
        SIMPLE = None
        ROUNDED = None
        DOUBLE = None
        SQUARE = None
    box = cast(Any, Box)

if TYPE_CHECKING:
    from ansible.plugins.callback import CallbackBase as CallbackBase
else:
    try:
        from ansible.plugins.callback import CallbackBase as CallbackBase
    except ImportError:
        class CallbackBase:
            """Mock class for pylint when ansible is not installed"""
            CALLBACK_VERSION = 2.0
            CALLBACK_TYPE = "stdout"
            CALLBACK_NAME = "rich_tui"
    CallbackBase = cast(Any, CallbackBase)


DOCUMENTATION = """
    name: rich_tui
    type: stdout
    short_description: Beautiful TUI output with Rich library
    description:
        - Modern TUI callback plugin using Rich library
        - Live progress bars with ETA
        - Colored tables for task summary
        - Live Header with Stats
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

        self.log_level = os.environ.get("VPS_LOG_LEVEL", "minimal").lower()

        self.task_count = 0
        self.ok_count = 0
        self.changed_count = 0
        self.failed_count = 0
        self.skipped_count = 0

        self.live = None
        self.layout = None
        self.job_progress = None
        self.task_id = None
        self.log_messages = []

        # Milestone / Phase Tracking
        self.current_phase = None
        self.phases = {
            "System Foundation": "pending",
            "Security Hardening": "pending",
            "Desktop Environment": "pending",
            "Remote Access": "pending",
            "Desktop Tools": "pending",
            "Visual Foundation": "pending",
            "Dev Languages": "pending",
            "Containerization": "pending",
            "Code Editors": "pending",
            "Dev Tools": "pending",
            "Cloud Tools": "pending"
        }
        self.phase_order = list(self.phases.keys())
        
        # Map roles to phases
        self.role_phase_map = {
            "common": "System Foundation",
            "security": "Security Hardening",
            "desktop": "Desktop Environment",
            "xrdp": "Remote Access",
            "kde-optimization": "Desktop Tools",
            "kde-apps": "Desktop Tools",
            "fonts": "Visual Foundation",
            "catppuccin-theme": "Visual Foundation",
            "terminal": "Visual Foundation",
            "shell-styling": "Visual Foundation",
            "zsh-enhancements": "Visual Foundation",
            "development": "Dev Languages",
            "docker": "Containerization",
            "editors": "Code Editors",
            "tui-tools": "Dev Tools",
            "network-tools": "Dev Tools",
            "system-performance": "Dev Tools",
            "text-processing": "Dev Tools",
            "file-management": "Dev Tools",
            "dev-debugging": "Dev Tools",
            "code-quality": "Dev Tools",
            "productivity": "Dev Tools",
            "log-visualization": "Dev Tools",
            "ai-devtools": "Dev Tools",
            "cloud-native": "Cloud Tools"
        }

    def _update_phase_status(self, new_role):
        """Update phase status based on current role."""
        if not new_role or new_role not in self.role_phase_map:
            return

        phase = self.role_phase_map[new_role]
        
        # If we entered a new phase
        if phase != self.current_phase:
            # Mark previous phase as completed (if exists)
            if self.current_phase and self.phases[self.current_phase] == "running":
                self.phases[self.current_phase] = "completed"
            
            # Mark previous phases as completed (catch-up if jumped)
            if phase in self.phase_order:
                idx = self.phase_order.index(phase)
                for i in range(idx):
                    p = self.phase_order[i]
                    if self.phases[p] == "pending":
                        self.phases[p] = "completed"

            # Set new phase to running
            self.current_phase = phase
            self.phases[phase] = "running"

    def _create_milestones_panel(self):
        """Create a compact milestone progress bar."""
        if not self.current_phase:
            return Text("Initializing...", style="dim")

        # Create a compact grid of phases
        grid = Table.grid(padding=(0, 1))
        
        # Simple row of dots/names
        status_row = []
        for phase in self.phase_order:
            status = self.phases[phase]
            if status == "completed":
                icon = "[green]●[/green]"
            elif status == "running":
                icon = "[blue]◉[/blue]"
            else:
                icon = "[dim]○[/dim]"
            
            status_row.append(f"{icon}")

        # Construct the display
        # ● ● ● ◉ ○ ○ ○  [bold blue]Current Phase Name[/bold blue]
        
        dots = "".join(status_row)
        display = Text.from_markup(f"{dots}  [bold white]{self.current_phase}[/bold white]")
        return Panel(display, box=box.SIMPLE, padding=(0,1), style="on black")

    def _get_duration(self, start_time):
        """Calculate duration string."""
        if not start_time: return "0.0s"
        return f"{time.time() - start_time:.1f}s"

    def _print_footer(self):
        """Print final stats."""
        if not RICH_AVAILABLE or not self.console:
            return

        self._update_ui()


    def _create_header_table(self):
        """Create the header with ASCII banner and stats."""
        grid = Table.grid(expand=True)
        grid.add_column(justify="center", ratio=1)

        milestones = self._create_milestones_panel()
        grid.add_row(milestones)
        
        # Stats Row
        stats = Text()
        stats.append(f"LOG LEVEL: {self.log_level.upper()}  |  ", style="dim")
        stats.append(f"OK: {self.ok_count} ", style="green")
        stats.append(f"CHANGED: {self.changed_count} ", style="yellow")
        stats.append(f"FAILED: {self.failed_count} ", style="red")
        stats.append(f"SKIPPED: {self.skipped_count}", style="dim")
        
        grid.add_row(Panel(stats, box=box.ROUNDED, style="white on black"))
        
        return Panel(grid, style="white on black", box=box.HEAVY)

    def _create_footer(self):
        """Create the footer with credits."""
        credit_text = Text(justify="center")
        credit_text.append("CREDITS: ", style="bold magenta")
        credit_text.append("VPS RDP Workstation Automation ", style="cyan")
        credit_text.append("| ", style="dim")
        credit_text.append("Designed for Developers", style="italic white")
        
        return Panel(credit_text, box=box.ROUNDED, style="white on black")

    def _update_ui(self):
        """Update the entire layout."""
        if not self.live: return
        if not self.layout: return

        self.layout["header"].update(self._create_header_table())

        body_elements = []
        
        if self.log_level in ["full", "debug"]:
            visible_logs = self.log_messages[-20:]
            log_panel = Panel(
                Group(*visible_logs), 
                title="[bold]Execution Log[/bold]", 
                border_style="blue", 
                box=box.ROUNDED,
                padding=(0, 1)
            )
            body_elements.append(log_panel)
        elif self.log_level == "minimal":
             body_elements.append(Text("\n" * 5))

        if self.job_progress:
            self.layout["body"].update(
                Panel(
                    Group(
                        *body_elements,
                        Panel(self.job_progress, box=box.SIMPLE, border_style="dim")
                    ),
                    box=box.SQUARE
                )
            )
        
        self.layout["footer"].update(self._create_footer())

    def v2_playbook_on_start(self, playbook):
        """Called when playbook starts."""
        self.start_time = time.time()

        if not RICH_AVAILABLE:
            print("\n🚀 VPS Developer Workstation Setup v3.1.0\n")
            return

        self.layout = Layout()
        self.layout.split(
            Layout(name="header", size=6),
            Layout(name="body"),
            Layout(name="footer", size=3)
        )

        self.layout["header"].update(self._create_header_table())
        self.layout["footer"].update(self._create_footer())

        self.job_progress = Progress(
            SpinnerColumn(spinner_name="dots"),
            TextColumn("[bold blue]{task.description}"),
            BarColumn(bar_width=None),
            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
            TimeElapsedColumn(),
            expand=True
        )
        self.task_id = self.job_progress.add_task("Initializing...", total=None)

        self.live = Live(self.layout, refresh_per_second=12, console=self.console)
        self.live.start()

    def _update_body_log(self, renderable):
        """Add a log message to the list and update UI."""
        self.log_messages.append(renderable)
        self._update_ui()

    def v2_playbook_on_play_start(self, play):
        """Called when a play starts."""
        self.current_play = play.get_name().strip()
        if self.job_progress and self.task_id is not None:
            self.job_progress.update(self.task_id, description=f"Running: {self.current_task}")

        if self.log_level != "minimal":
             pass
        self._update_ui()

    def v2_playbook_on_task_start(self, task, is_conditional):
        """Called when a task starts."""
        self.current_task = task.get_name()
        self.task_count += 1
        self.current_task_start = time.time()

        if hasattr(task, '_role') and task._role:
            role_name = task._role.get_name()
            if role_name != self.current_role:
                self.current_role = role_name
                self._update_phase_status(role_name)

        if self.job_progress and self.task_id is not None:
            self.job_progress.update(self.task_id, description=f"Running: {self.current_task}")

        self._update_ui()

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

        if self.log_level == "minimal" and status in ["ok", "skipped"]:
            self._update_ui()
            return

        log_line = f"{icon} {task_name} [dim]({duration})[/dim]"
        if status == "failed":
            self._update_body_log(Text.from_markup(f"{log_line}\n[red]{message}[/red]"))
        else:
            style = "dim" if status == "skipped" else ""
            self._update_body_log(Text.from_markup(log_line, style=style))

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
