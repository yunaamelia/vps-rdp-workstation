# pylint: disable=C0103,R0903,R0902,W0212,E0401
# pyright: reportMissingImports=false, reportUnusedImport=false, reportUnknownParameterType=false, reportMissingParameterType=false, reportUnknownMemberType=false, reportUnknownArgumentType=false, reportUnknownVariableType=false, reportTypeCommentUsage=false, reportMissingTypeStubs=false, reportUnusedCallResult=false
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
    rich_available = True
except ImportError:
    rich_available = False
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

RICH_AVAILABLE = rich_available

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

# Colors (Catppuccin Mocha)
C_ROSEWATER = "#f5e0dc"
C_FLAMINGO  = "#f2cdcd"
C_PINK      = "#f5c2e7"
C_MAUVE     = "#cba6f7"
C_RED       = "#f38ba8"
C_MAROON    = "#eba0ac"
C_PEACH     = "#fab387"
C_YELLOW    = "#f9e2af"
C_GREEN     = "#a6e3a1"
C_TEAL      = "#94e2d5"
C_SKY       = "#89dceb"
C_SAPPHIRE  = "#74c7ec"
C_BLUE      = "#89b4fa"
C_LAVENDER  = "#b4befe"
C_TEXT      = "#cdd6f4"
C_SUBTEXT1  = "#bac2de"
C_SUBTEXT0  = "#a6adc8"
C_OVERLAY2  = "#9399b2"
C_OVERLAY1  = "#7f849c"
C_OVERLAY0  = "#6c7086"
C_SURFACE2  = "#585b70"
C_SURFACE1  = "#45475a"
C_SURFACE0  = "#313244"
C_BASE      = "#1e1e2e"
C_MANTLE    = "#181825"
C_CRUST     = "#11111b"

# Icons
ICON_OS    = "" # U+E63F (or similar distro icon)
SEP_R      = "" # U+E0B4

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
        force_tui = os.environ.get("VPS_FORCE_TUI") == "true"
        terminal = force_tui or os.isatty(1)
        self.console = Console(
            force_terminal=terminal,
            color_system="truecolor"
        ) if RICH_AVAILABLE else None
        
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
        self.live = None # type: Any
        self.layout = None # type: Any
        self.job_progress = None # type: Any
        self.task_id = None
        self.overall_progress = None # type: Any
        self.overall_task_id = None
        # Phase Tracking
        self.current_phase = None # type: str | None
        self.completed_phases = set() # type: Set[str]
        
        # Layout State
        self.is_narrow = False
        
        # Log History for Pure TUI
        self.log_history = [] # type: List[Dict[str, str]]
        self.max_log_items = 12 # Keep last N items to fit in panel

    def v2_playbook_on_start(self, playbook):
        """Called when playbook starts."""
        self.start_time = time.time()

        if not RICH_AVAILABLE:
            print("\\n🚀 VPS Developer Workstation Setup v3.1.0\\n")
            return

        force_tui = os.environ.get("VPS_FORCE_TUI") == "true"
        force_static = os.environ.get("VPS_FORCE_STATIC_LOGS") == "true"
        if force_static or not self.console or not self.console.is_terminal:
             self._print_static_header()
             return

        if self.is_navigator and not force_tui:
             self._print_static_header()
             return

        # Banner is part of the Layout for Live mode
        # self._print_static_header()

        self._init_layout()
        self._init_progress()
        self._start_live_display()

    def _print_static_header(self):
        """Print static banner for log-based outputs using Starship styling."""
        if not self.console: return
        
        # Banner from setup.sh
        banner_ascii = """
[bold cyan]╦  ╦╔═╗╔═╗  ╦═╗╔╦╗╔═╗  ╦ ╦╔═╗╦═╗╦╔═╔═╗╔╦╗╔═╗╔╦╗╦╔═╗╔╗╔
╚╗╔╝╠═╝╚═╗  ╠╦╝ ║║╠═╝  ║║║║ ║╠╦╝╠╩╗╚═╗ ║ ╠═╣ ║ ║║ ║║║║
 ╚╝ ╩  ╚═╝  ╩╚══╩╝╩    ╚╩╝╚═╝╩╚═╩ ╩╚═╝ ╩ ╩ ╩ ╩ ╩╚═╝╝╚╝[/bold cyan]"""
        
        self.console.print(Panel(banner_ascii, box=box.ROUNDED, border_style=C_SURFACE0, expand=False, padding=(0, 2)))
        
        # Segment 1: Icon (Mauve on Surface0)
        seg1 = Text(f" {ICON_OS} ", style=f"bold {C_MAUVE} on {C_SURFACE0}")
        sep1 = Text(SEP_R, style=f"{C_SURFACE0} on {C_SURFACE1}")
        
        # Segment 2: Title (Blue on Surface1)
        seg2 = Text(" VPS RDP WORKSTATION ", style=f"bold {C_BLUE} on {C_SURFACE1}")
        sep2 = Text(SEP_R, style=f"{C_SURFACE1} on {C_SURFACE2}")
        
        # Segment 3: Stats (Text on Surface2)
        seg3 = Text(f" v{self.CALLBACK_VERSION} ", style=f"{C_TEXT} on {C_SURFACE2}")
        sep3 = Text(SEP_R, style=f"{C_SURFACE2} on default")
        
        # Combine
        header_bar = Text.assemble(seg1, sep1, seg2, sep2, seg3, sep3)
        
        self.console.print(header_bar)
        self.console.print()

    def _create_header_panel(self):
        """Create the header panel with ASCII banner and stats."""
        # Banner from setup.sh
        banner_ascii = """
[bold cyan]╦  ╦╔═╗╔═╗  ╦═╗╔╦╗╔═╗  ╦ ╦╔═╗╦═╗╦╔═╔═╗╔╦╗╔═╗╔╦╗╦╔═╗╔╗╔
╚╗╔╝╠═╝╚═╗  ╠╦╝ ║║╠═╝  ║║║║ ║╠╦╝╠╩╗╚═╗ ║ ╠═╣ ║ ║║ ║║║║
 ╚╝ ╩  ╚═╝  ╩╚══╩╝╩    ╚╩╝╚═╝╩╚═╩ ╩╚═╝ ╩ ╩ ╩ ╩ ╩╚═╝╝╚╝[/bold cyan]"""
        
        banner_panel = Panel(banner_ascii, box=box.ROUNDED, border_style=C_SURFACE0, expand=False, padding=(0, 2))
        
        # Segment 1: Icon (Mauve on Surface0)
        seg1 = Text(f" {ICON_OS} ", style=f"bold {C_MAUVE} on {C_SURFACE0}")
        sep1 = Text(SEP_R, style=f"{C_SURFACE0} on {C_SURFACE1}")
        
        # Segment 2: Title (Blue on Surface1)
        seg2 = Text(" VPS RDP WORKSTATION ", style=f"bold {C_BLUE} on {C_SURFACE1}")
        sep2 = Text(SEP_R, style=f"{C_SURFACE1} on {C_SURFACE2}")
        
        # Segment 3: Stats (Text on Surface2)
        seg3 = Text(f" v{self.CALLBACK_VERSION} ", style=f"{C_TEXT} on {C_SURFACE2}")
        sep3 = Text(SEP_R, style=f"{C_SURFACE2} on default")
        
        # Combine
        header_bar = Text.assemble(seg1, sep1, seg2, sep2, seg3, sep3)
        
        return Group(banner_panel, header_bar)

    def _init_layout(self):
        """Initialize the Layout structure with Header, Body (Split), and Footer."""
        self.layout = Layout()
        
        # Main vertical split: Header, Body, Footer
        self.layout.split(
            Layout(name="header", size=7),
            Layout(name="body", ratio=1),
            Layout(name="footer", size=3)
        )
        
        # Responsive Body Split
        # If terminal width is small (< 100), stack panels vertically
        self.is_narrow = self.console and self.console.width < 100
        if self.is_narrow:
            self.layout["body"].split_column(
                Layout(name="right", size=14), # Progress/Stats on top
                Layout(name="left", ratio=1)   # Logs below
            )
        else:
            # Standard horizontal split
            self.layout["body"].split_row(
                Layout(name="left", ratio=2),
                Layout(name="right", ratio=3)
            )
        
        self.layout["header"].update(self._create_header_panel())
        self.layout["footer"].update(self._create_footer())

    def _init_progress(self):
        """Initialize Progress bars for Current Task and Overall."""
        # 1. Job Progress (Current Task)
        self.job_progress = Progress(
            SpinnerColumn(spinner_name="dots"),
            TextColumn(f"[bold {C_BLUE}]{{task.description}}"),
            BarColumn(bar_width=None),
            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
            expand=True
        )
        self.task_id = self.job_progress.add_task("Initializing...", total=None)

        # 2. Overall Progress
        self.overall_progress = Progress(
            TextColumn(f"[{C_SUBTEXT1}]Overall[/]"),
            BarColumn(bar_width=None, complete_style=C_GREEN, finished_style=C_GREEN),
            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
            TimeElapsedColumn(),
            expand=True
        )
        # Estimate total tasks (can be updated dynamically if needed)
        self.overall_task_id = self.overall_progress.add_task("All Tasks", total=100) # Placeholder total

    def _start_live_display(self):
        """Start the Live context manager."""
        refresh_rate_env = os.environ.get("VPS_TUI_FPS", "4")
        try:
            refresh_rate = max(1, int(refresh_rate_env))
        except ValueError:
            refresh_rate = 4
        
        # When running in navigator/piped mode, auto_refresh can cause deadlocks if the buffer fills up.
        # We'll disable auto_refresh and rely on manual refreshes in the callback hooks.
        auto_refresh = not self.is_navigator
        
        # Prevent Rich from capturing streams which causes deadlocks in Ansible Navigator
        redirect = not self.is_navigator

        self.live = Live(
            self.layout,
            refresh_per_second=refresh_rate,
            console=self.console,
            auto_refresh=auto_refresh,
            redirect_stderr=redirect,
            redirect_stdout=redirect
        )
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

        # Update Spinner & Overall Progress
        if self.job_progress and self.task_id is not None:
            self.job_progress.update(self.task_id, description=f"Running: {self.current_task}")
        
        if self.overall_progress and self.overall_task_id is not None:
            # Simple increment for now - accurate % requires knowing total tasks beforehand
            self.overall_progress.advance(self.overall_task_id, 1)

        # Force a manual refresh to ensure the screen updates even if the Live thread is contending
        if self.live:
            # In navigator mode, we disabled auto-refresh to prevent deadlocks.
            # We must manually trigger the refresh here.
            # We use _update_ui() to ensure the layout content is fresh before refreshing the screen.
            self._update_ui()
            # Only refresh if NOT using navigator, or rely on auto-refresh if enabled?
            # Actually, with Pure TUI, we should just refresh.
            self.live.refresh()

    def _update_role_and_phase(self, role_name):
        """Update current role and phase, marking previous as complete."""
        if role_name == self.current_role:
            return

        # If switching roles, check phase transition
        if self.current_phase and self.current_role:
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

        # Dynamic Responsiveness
        if self.console:
            is_narrow = self.console.width < 100
            if is_narrow != self.is_narrow:
                self.is_narrow = is_narrow
                if is_narrow:
                    self.layout["body"].split_column(
                        Layout(name="right", size=14),
                        Layout(name="left", ratio=1)
                    )
                else:
                    self.layout["body"].split_row(
                        Layout(name="left", ratio=2),
                        Layout(name="right", ratio=3)
                    )

        self.layout["left"].update(self._create_left_panel())
        self.layout["right"].update(self._create_right_panel())
        self.layout["footer"].update(self._create_footer())

    def _create_left_panel(self):
        """Create left panel with milestones and log history."""
        # 1. Milestones
        milestones = self._create_milestones_panel()
        
        # 2. Log History
        log_table = Table.grid(expand=True, padding=(0, 1))
        log_table.add_column(justify="center", width=3) # Icon
        log_table.add_column(ratio=1) # Task
        log_table.add_column(justify="right", width=8) # Duration
        
        if not self.log_history:
            log_table.add_row("", "[dim]Waiting for tasks...[/dim]", "")
        else:
            for entry in self.log_history:
                icon = f"[{entry['color']}]{entry['icon']}[/]"
                task = f"[{entry['color']}]{entry['task']}[/]"
                if entry['status'] == 'skipped':
                    task = f"[dim]{entry['task']}[/dim]"
                
                duration = f"[dim]{entry['duration']}[/dim]"
                log_table.add_row(icon, task, duration)
                
                # Show error details on next row if failed
                if entry['status'] == 'failed' and entry['message']:
                    log_table.add_row("", f"[red]{entry['message']}[/red]", "")

        log_panel = Panel(
            log_table,
            title="[bold blue]Recent Activity[/]",
            border_style="blue",
            box=box.ROUNDED,
            padding=(0, 0)
        )
        
        return Group(milestones, log_panel)

    def _create_right_panel(self):
        """Build the right column with progress and a compact summary table."""
        # Progress Grid
        progress_grid = Table.grid(expand=True)
        progress_grid.add_row(
            Panel(
                self.overall_progress,
                title=f"[bold {C_GREEN}]Overall Progress[/]",
                border_style=C_GREEN,
                box=box.ROUNDED,
                padding=(1, 2)
            )
        )
        progress_grid.add_row(
            Panel(
                self.job_progress,
                title=f"[bold {C_MAUVE}]Current Task[/]",
                border_style=C_MAUVE,
                box=box.ROUNDED,
                padding=(1, 2)
            )
        )

        # Live Stats Summary
        summary = Table(box=box.ROUNDED, show_header=True, header_style=f"bold {C_LAVENDER}", expand=True)
        summary.add_column("Metric", justify="right")
        summary.add_column("Count", justify="left")
        
        summary.add_row("OK", f"[{C_GREEN}]{self.ok_count}[/]")
        summary.add_row("Changed", f"[{C_YELLOW}]{self.changed_count}[/]")
        summary.add_row("Failed", f"[{C_RED}]{self.failed_count}[/]")
        summary.add_row("Skipped", f"[{C_OVERLAY0}]{self.skipped_count}[/]")

        content = Group(progress_grid, summary)
        return Panel(content, box=box.ROUNDED, border_style=C_SURFACE0, padding=(1, 1))

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
        return Panel(grid, style="white on black", box=box.ROUNDED)

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
        return Panel(display, box=box.ROUNDED, padding=(0, 1), style="on black")

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
        """Add formatted result to internal log history instead of printing."""
        if not self.console: return
        
        # In navigator mode with Pure TUI, we never print to stream directly
        # if self.is_navigator: ... (disabled)

        if not self.live: return

        # Icons and Colors
        icons = {
            "ok": "", # Nerd Font check
            "changed": "", # Nerd Font refresh
            "failed": "", # Nerd Font cross
            "skipped": "", # Nerd Font skip
        }
        colors = {
            "ok": "green",
            "changed": "yellow",
            "failed": "red",
            "skipped": "dim",
        }
        
        icon = icons.get(status, "•")
        color = colors.get(status, "white")
        
        # Format the log entry
        log_entry = {
            "icon": icon,
            "status": status,
            "color": color,
            "task": task_name,
            "duration": duration,
            "message": message
        }
        
        # Add to history
        self.log_history.append(log_entry)
        if len(self.log_history) > self.max_log_items:
            self.log_history.pop(0)
            
        # Update the UI to show the new log
        self._update_ui()

    def _print_log_line(self, status, task_name, duration, message=""):
        """Print a static log line for non-interactive mode."""
        if not self.console: return

        # Icons and Colors
        icons = {
            "ok": "",
            "changed": "",
            "failed": "",
            "skipped": "",
        }
        # Map statuses to new palette
        colors = {
            "ok": C_GREEN,
            "changed": C_YELLOW,
            "failed": C_RED,
            "skipped": C_OVERLAY0,
        }
        
        status_color = colors.get(status, C_TEXT)
        icon = icons.get(status, "•")
        
        # Determine Phase
        phase = self.current_phase or "Init"
        
        # Create a Grid for alignment
        grid = Table.grid(expand=True)
        grid.add_column(justify="left", width=12)  # Status
        grid.add_column(justify="left", ratio=1)   # Task Name
        grid.add_column(justify="right", width=20) # Phase
        grid.add_column(justify="right", width=10) # Duration

        # Status Pill
        status_text = Text(f"{icon} {status.upper()}", style=f"bold {status_color}")
        
        # Task Name (Plain)
        task_text = Text(task_name, style=C_TEXT)
        
        # Phase Pill (Lavender on Surface0)
        phase_text = Text(f" {phase} ", style=f"{C_LAVENDER} on {C_SURFACE0}")
        
        # Duration Pill (Overlay1 on Mantle)
        duration_text = Text(f" {duration} ", style=f"{C_OVERLAY1} on {C_MANTLE}")

        grid.add_row(status_text, task_text, phase_text, duration_text)
        
        # Error Message Panel
        if status == "failed":
            error_panel = Panel(
                Text(message, style=C_RED),
                title=f"[bold {C_RED}]Error Details[/]",
                border_style=C_RED,
                box=box.ROUNDED,
                expand=True
            )
            self.console.print(grid)
            self.console.print(error_panel)
        else:
            self.console.print(grid)

    def _print_footer(self):
        if self.console:
            # Summary Table
            summary = Table(box=box.ROUNDED, show_header=True, header_style=f"bold {C_LAVENDER}")
            summary.add_column("Metric", justify="right")
            summary.add_column("Count", justify="left")
            
            summary.add_row("OK", f"[{C_GREEN}]{self.ok_count}[/]")
            summary.add_row("Changed", f"[{C_YELLOW}]{self.changed_count}[/]")
            summary.add_row("Failed", f"[{C_RED}]{self.failed_count}[/]")
            summary.add_row("Skipped", f"[{C_OVERLAY0}]{self.skipped_count}[/]")
            
            total_time = self._get_duration(self.start_time)
            
            # Starship Footer Style
            panel = Panel(
                summary,
                title=f"[bold {C_BLUE}]Execution Completed in {total_time}[/]",
                border_style=C_SURFACE0,
                box=box.ROUNDED,
                expand=False
            )
            self.console.print(panel)

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
