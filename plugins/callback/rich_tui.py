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
from typing import Any, TYPE_CHECKING, cast, List, Dict, Optional, Set

try:
    from rich.console import Console, Group
    from rich.live import Live
    from rich.layout import Layout
    from rich.table import Table
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn
    from rich.text import Text
    from rich import box
    from rich.rule import Rule
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False
    # Define dummy classes to satisfy static analysis
    class Dummy:
        """Dummy class for missing rich dependencies."""
        def __init__(self, *args, **kwargs): pass
        def __getattr__(self, name): return self
        def __call__(self, *args, **kwargs): return self
        def __getitem__(self, key): return self
        def split(self, *args, **kwargs): pass
        def update(self, *args, **kwargs): pass
        def start(self): pass
        def stop(self): pass
        def add_task(self, *args, **kwargs): pass
        def append(self, *args, **kwargs): pass
        def add_row(self, *args, **kwargs): pass
        def add_column(self, *args, **kwargs): pass
        @classmethod
        def grid(cls, *args, **kwargs): return cls()
        @classmethod
        def from_markup(cls, *args, **kwargs): return cls()

    Console = Group = Live = Layout = Table = Panel = Progress = SpinnerColumn = TextColumn = BarColumn = TimeElapsedColumn = Text = Rule = cast(Any, Dummy)
    box = cast(Any, Dummy)

if TYPE_CHECKING:
    from ansible.plugins.callback import CallbackBase
else:
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
        - Live Header with Stats
        - Milestone tracking
    requirements:
        - rich>=13.0.0 (pip install rich)
    version_added: "3.1.0"
"""

# Milestone Definitions
ROLE_PHASE_MAP = {
    'common': 'Phase 1: System Foundation',
    'security': 'Phase 2: Security Hardening',
    'desktop': 'Phase 3: Desktop Environment',
    'xrdp': 'Phase 3: Desktop Environment',
    'kde-optimization': 'Phase 3: Desktop Environment',
    'kde-apps': 'Phase 3: Desktop Environment',
    'fonts': 'Phase 4: Visual Foundation',
    'catppuccin-theme': 'Phase 4: Visual Foundation',
    'terminal': 'Phase 4: Visual Foundation',
    'shell-styling': 'Phase 4: Visual Foundation',
    'zsh-enhancements': 'Phase 4: Visual Foundation',
    'development': 'Phase 5: Dev Languages',
    'docker': 'Phase 6: Containers',
    'editors': 'Phase 7: Code Editors',
    'tui-tools': 'Phase 8: Dev Tools',
    'network-tools': 'Phase 8: Dev Tools',
    'system-performance': 'Phase 8: Dev Tools',
    'text-processing': 'Phase 8: Dev Tools',
    'file-management': 'Phase 8: Dev Tools',
    'dev-debugging': 'Phase 8: Dev Tools',
    'code-quality': 'Phase 8: Dev Tools',
    'productivity': 'Phase 8: Dev Tools',
    'log-visualization': 'Phase 8: Dev Tools',
    'ai-devtools': 'Phase 8: Dev Tools',
    'cloud-native': 'Phase 9: Cloud Native'
}

PHASE_ORDER = sorted(list(set(ROLE_PHASE_MAP.values())))

class CallbackModule(CallbackBase):
    """
    Rich TUI Callback Plugin for beautiful Ansible output.
    """

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "stdout"
    CALLBACK_NAME = "rich_tui"
    CALLBACK_NEEDS_WHITELIST = False

    def __init__(self):
        super(CallbackModule, self).__init__()
        self.console = Console(force_terminal=True, color_system="truecolor") if RICH_AVAILABLE else None
        
        # State Tracking
        self.start_time = None # type: float | None
        self.current_play = None # type: str | None
        self.current_task = None # type: str | None
        self.current_role = None # type: str | None
        self.current_task_start = None # type: float | None
        self.log_level = os.environ.get("VPS_LOG_LEVEL", "minimal").lower()
        self.is_navigator = "ansible-navigator" in os.environ.get("ansible_cmdline", "") or os.environ.get("ANSIBLE_NAVIGATOR_MODE")

        # Statistics
        self.task_count = 0
        self.ok_count = 0
        self.changed_count = 0
        self.failed_count = 0
        self.skipped_count = 0

        # UI Components
        self.live = None # type: Live | None
        self.layout = None # type: Layout | None
        self.job_progress = None # type: Progress | None
        self.task_id = None
        # Phase Tracking
        self.current_phase = None # type: str | None
        self.completed_phases = set() # type: Set[str]

    def v2_playbook_on_start(self, playbook):
        """Called when playbook starts."""
        self.start_time = time.time()

        if not RICH_AVAILABLE:
            print("\\n🚀 VPS Developer Workstation Setup v3.1.0\\n")
            return

        if self.is_navigator:
            # Navigator mode: Print static banner, NO live display
            self._print_static_header()
        else:
            # Interactive mode: Full TUI
            self._init_layout()
            self._init_progress()
            self._start_live_display()

    def _print_static_header(self):
        """Print static banner for log-based outputs."""
        if not self.console: return
        
        banner_text = """
[bold cyan]╦  ╦╔═╗╔═╗  ╦═╗╔╦╗╔═╗  ╦ ╦╔═╗╦═╗╦╔═╔═╗╔╦╗╔═╗╔╦╗╦╔═╗╔╗╔
╚╗╔╝╠═╝╚═╗  ╠╦╝ ║║╠═╝  ║║║║ ║╠╦╝╠╩╗╚═╗ ║ ╠═╣ ║ ║║ ║║║║
 ╚╝ ╩  ╚═╝  ╩╚══╩╝╩    ╚╩╝╚═╝╩╚═╩ ╩╚═╝ ╩ ╩ ╩ ╩ ╩╚═╝╝╚╝[/bold cyan]
 """
        self.console.print(banner_text)
        self.console.print(f"[dim]Version {self.CALLBACK_VERSION} | Log Level: {self.log_level.upper()}[/dim]")
        self.console.print(Rule(style="cyan"))

    def _init_layout(self):
        """Initialize the Layout structure."""
        self.layout = Layout()
        self.layout.split(
            Layout(name="header", size=6),
            Layout(name="body"),
            Layout(name="footer", size=3)
        )
        self.layout["header"].update(self._create_header_table())
        self.layout["footer"].update(self._create_footer())

    def _init_progress(self):
        """Initialize the Progress bar."""
        self.job_progress = Progress(
            SpinnerColumn(spinner_name="dots"),
            TextColumn("[bold blue]{task.description}"),
            expand=True
        )
        self.task_id = self.job_progress.add_task("Initializing...", total=None)

    def _start_live_display(self):
        """Start the Live context manager."""
        self.live = Live(self.layout, refresh_per_second=12, console=self.console)
        self.live.start()

    def v2_playbook_on_task_start(self, task, is_conditional):
        """Called when a task starts."""
        self.current_task = task.get_name()
        self.task_count += 1
        self.current_task_start = time.time()

        # Role & Phase Tracking
        if hasattr(task, '_role') and task._role:
            role_name = task._role.get_name()
            self._update_role_and_phase(role_name)

        # Update Spinner
        if self.job_progress and self.task_id is not None:
            self.job_progress.update(self.task_id, description=f"Running: {self.current_task}")

        self._update_ui()

    def _update_role_and_phase(self, role_name):
        """Update current role and phase, marking previous as complete."""
        if role_name == self.current_role:
            return

        # If switching roles, check phase transition
        if self.current_phase:
            prev_phase = ROLE_PHASE_MAP.get(self.current_role)
            new_phase = ROLE_PHASE_MAP.get(role_name)
            
            # If we are moving to a new phase (or just finished the last one for that phase)
            # Logic: If the new role belongs to a DIFFERENT phase, mark the OLD phase as complete.
            if prev_phase and prev_phase != new_phase:
                self.completed_phases.add(prev_phase)

        self.current_role = role_name
        self.current_phase = ROLE_PHASE_MAP.get(role_name, "Unknown Phase")

    def _update_ui(self):
        """Refresh the UI layout."""
        if not self.live or not self.layout:
            return

        # 1. Header (Static + Stats)
        self.layout["header"].update(self._create_header_table())

        # 2. Body (Milestones + Content)
        body_elements = []
        body_elements.append(self._create_milestones_panel())

        if self.job_progress:
            body_elements.append(
                Panel(self.job_progress, box=box.SIMPLE, border_style="dim")
            )

        self.layout["body"].update(Panel(Group(*body_elements), box=box.SQUARE))

        # 3. Footer (Static)
        self.layout["footer"].update(self._create_footer())

    def _create_header_table(self):
        """Create the header with ASCII banner and stats."""
        grid = Table.grid(expand=True)
        grid.add_column(justify="center", ratio=1)

        banner_text = """
[bold cyan]╦  ╦╔═╗╔═╗  ╦═╗╔╦╗╔═╗  ╦ ╦╔═╗╦═╗╦╔═╔═╗╔╦╗╔═╗╔╦╗╦╔═╗╔╗╔
╚╗╔╝╠═╝╚═╗  ╠╦╝ ║║╠═╝  ║║║║ ║╠╦╝╠╩╗╚═╗ ║ ╠═╣ ║ ║║ ║║║║
 ╚╝ ╩  ╚═╝  ╩╚══╩╝╩    ╚╩╝╚═╝╩╚═╩ ╩╚═╝ ╩ ╩ ╩ ╩ ╩╚═╝╝╚╝[/bold cyan]
 """
        grid.add_row(banner_text)
        
        stats = Text()
        stats.append(f"LOG LEVEL: {self.log_level.upper()}  |  ", style="dim")
        stats.append(f"OK: {self.ok_count} ", style="green")
        stats.append(f"CHANGED: {self.changed_count} ", style="yellow")
        stats.append(f"FAILED: {self.failed_count} ", style="red")
        stats.append(f"SKIPPED: {self.skipped_count}", style="dim")
        
        grid.add_row(Panel(stats, box=box.ROUNDED, style="white on black"))
        return Panel(grid, style="white on black", box=box.HEAVY)

    def _create_milestones_panel(self):
        """Create horizontal phase tracker."""
        if not self.current_phase:
            return Text("Initializing...", style="dim")

        status_row = []
        for phase in PHASE_ORDER:
            if phase in self.completed_phases:
                icon = "[green]●[/green]"
            elif phase == self.current_phase:
                icon = "[blue]◉[/blue]"
            else:
                icon = "[dim]○[/dim]"
            status_row.append(icon)

        dots = "".join(status_row)
        display = Text.from_markup(f"{dots}  [bold white]{self.current_phase}[/bold white]")
        return Panel(display, box=box.SIMPLE, padding=(0, 1), style="on black")

    def _create_footer(self):
        """Create the footer."""
        credit_text = Text(justify="center")
        credit_text.append("CREDITS: ", style="bold magenta")
        credit_text.append("VPS RDP Workstation Automation ", style="cyan")
        credit_text.append("| ", style="dim")
        credit_text.append("Designed for Developers", style="italic white")
        return Panel(credit_text, box=box.ROUNDED, style="white on black")

    def _get_duration(self, start_time):
        if not start_time: return "0.0s"
        return f"{time.time() - start_time:.1f}s"

    def _handle_task_result(self, status, result, ignore_errors=False):
        """Generic handler for task results."""
        duration = self._get_duration(self.current_task_start)
        
        if status == "ok":
            self.ok_count += 1
            if result._result.get("changed", False):
                status = "changed"
                self.changed_count += 1
        elif status == "failed":
            self.failed_count += 1
        elif status == "skipped":
            self.skipped_count += 1
        
        self._print_task_result(status, self.current_task, duration, result._result.get("msg", ""))

    def _print_task_result(self, status, task_name, duration, message=""):
        """Add formatted result to logs."""
        if not self.console: return

        # In navigator mode, print linear logs without TUI updates
        if self.is_navigator:
            self._print_log_line(status, task_name, duration, message)
            return

        if not self.live: return

        icons = {
            "ok": "[green]✓[/green]",
            "changed": "[yellow]⟳[/yellow]",
            "failed": "[red]✗[/red]",
            "skipped": "[dim]⊘[/dim]",
        }
        icon = icons.get(status, "•")

        # Skip display in minimal mode for non-failures
        if self.log_level == "minimal" and status in ["ok", "skipped"]:
            self._update_ui()
            return

        log_line = f"{icon} {task_name} [dim]({duration})[/dim]"
        renderable = None
        if status == "failed":
            renderable = Text.from_markup(f"{log_line}\n[red]{message}[/red]")
        else:
            style = "dim" if status == "skipped" else ""
            renderable = Text.from_markup(log_line, style=style)
        
        self.live.console.print(renderable)

    def _print_log_line(self, status, task_name, duration, message=""):
        """Print a static log line for non-interactive mode."""
        if not self.console: return

        icons = {
            "ok": "[bold green]OK[/bold green]",
            "changed": "[bold yellow]CHANGED[/bold yellow]",
            "failed": "[bold red]FAILED[/bold red]",
            "skipped": "[dim]SKIPPED[/dim]",
        }
        status_label = icons.get(status, status.upper())
        
        # Format: [STATUS] Task Name (Duration)
        line = f"{status_label:<10} {task_name} [dim]({duration})[/dim]"
        
        if status == "failed":
            line += f"\n[red]  ERROR: {message}[/red]"
            
        self.console.print(line)

    def _print_footer(self):
        if self.console:
            self.console.print("[bold green]✓ Execution Completed[/bold green]")

    # --- Ansible Callback Hooks ---

    def v2_runner_on_ok(self, result):
        self._handle_task_result("ok", result)

    def v2_runner_on_failed(self, result, ignore_errors=False):
        status = "skipped" if ignore_errors else "failed"
        self._handle_task_result(status, result, ignore_errors)

    def v2_runner_on_skipped(self, result):
        self._handle_task_result("skipped", result)

    def v2_runner_on_unreachable(self, result):
        self._handle_task_result("failed", result)

    def v2_playbook_on_stats(self, stats):
        if self.live:
            self.live.stop()
        self._print_footer()
