# pylint: disable=C0103,R0903,R0902,W0212,E0401
# pyright: reportUnusedImport=false, reportUnknownParameterType=false, reportMissingParameterType=false, reportUnknownMemberType=false, reportUnknownArgumentType=false, reportUnknownVariableType=false, reportTypeCommentUsage=false, reportMissingTypeStubs=false, reportUnusedCallResult=false
"""
Ansible Callback Plugin: Rich TUI
Modern, beautiful TUI output for Ansible using the Rich library.
Features: Catppuccin theme, live layout, progress tracking, and structured logging.
"""

from __future__ import absolute_import, division, print_function

__metaclass__ = type

import os
import time
from datetime import datetime
from typing import Any, Dict, List, Optional, Set, Union, cast, TYPE_CHECKING

try:
    from rich.console import Console, Group
    from rich.live import Live
    from rich.layout import Layout
    from rich.table import Table
    from rich.panel import Panel
    from rich.progress import (
        Progress,
        SpinnerColumn,
        TextColumn,
        BarColumn,
        TimeElapsedColumn,
        TaskID,
    )
    from rich.text import Text
    from rich import box
    from rich.theme import Theme
    from rich.style import Style

    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

    # Define dummy classes to satisfy static analysis
    class Dummy:
        ROUNDED: Any = None
        SQUARE: Any = None
        MINIMAL: Any = None
        
        # Static assemble method for Text
        @staticmethod
        def assemble(*args: Any, **kwargs: Any) -> Any:
            return Dummy()

        # Add start/stop for Live
        def start(self, *args: Any, **kwargs: Any) -> None:
            pass
            
        def stop(self, *args: Any, **kwargs: Any) -> None:
            pass

        def __init__(self, *args: Any, **kwargs: Any) -> None:
            pass

        def __getattr__(self, _: str) -> Any:
            return self

        def __call__(self, *args: Any, **kwargs: Any) -> Any:
            return self

        def __getitem__(self, _: Any) -> Any:
            return self
            
        def __or__(self, other: Any) -> Any:
            return self

        @classmethod
        def grid(cls, *args: Any, **kwargs: Any) -> Any:
            return cls()

        def split(self, *args: Any, **kwargs: Any) -> None:
            pass

        def split_row(self, *args: Any, **kwargs: Any) -> None:
            pass
            
        def update(self, *args: Any, **kwargs: Any) -> None:
            pass
            
        def add_column(self, *args: Any, **kwargs: Any) -> None:
            pass

        def add_row(self, *args: Any, **kwargs: Any) -> None:
            pass

        def add_task(self, *args: Any, **kwargs: Any) -> Any:
            return None
            
        def advance(self, *args: Any, **kwargs: Any) -> None:
            pass
            
        # Add special methods required by Rich protocols
        def __rich_console__(self, console: Any, options: Any) -> Any:
            return []
            
        def __rich__(self) -> Any:
            return str(self)

    # Mock attributes for module-level constants
    Dummy.ROUNDED = Dummy()
    Dummy.SQUARE = Dummy()
    Dummy.MINIMAL = Dummy()
    
    # Allow dummy classes to be used in type unions by registering them
    Console = Group = Live = Layout = Table = Panel = Progress = Theme = Style = Dummy  # type: ignore
    SpinnerColumn = TextColumn = BarColumn = TimeElapsedColumn = TaskID = Text = box = Dummy  # type: ignore



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


# --- Configuration & Constants ---

DOCUMENTATION = """
    name: rich_tui
    type: stdout
    short_description: Modern TUI output with Rich library
    description:
        - Beautiful terminal UI for Ansible execution.
        - Uses Catppuccin Mocha palette.
        - Live progress tracking and layout.
    requirements:
        - rich>=13.0.0
    version_added: "3.2.0"
"""

# Catppuccin Mocha Theme
THEME_COLORS = {
    "rosewater": "#f5e0dc",
    "flamingo": "#f2cdcd",
    "pink": "#f5c2e7",
    "mauve": "#cba6f7",
    "red": "#f38ba8",
    "maroon": "#eba0ac",
    "peach": "#fab387",
    "yellow": "#f9e2af",
    "green": "#a6e3a1",
    "teal": "#94e2d5",
    "sky": "#89dceb",
    "sapphire": "#74c7ec",
    "blue": "#89b4fa",
    "lavender": "#b4befe",
    "text": "#cdd6f4",
    "subtext1": "#bac2de",
    "subtext0": "#a6adc8",
    "overlay2": "#9399b2",
    "overlay1": "#7f849c",
    "overlay0": "#6c7086",
    "surface2": "#585b70",
    "surface1": "#45475a",
    "surface0": "#313244",
    "base": "#1e1e2e",
    "mantle": "#181825",
    "crust": "#11111b",
}

# Role to Phase Mapping (for milestone tracking)
ROLE_PHASE_MAP = {
    "common": "System Foundation",
    "security": "Security Hardening",
    "desktop": "Desktop Environment",
    "xrdp": "Desktop Environment",
    "kde-optimization": "Desktop Environment",
    "kde-apps": "Desktop Environment",
    "fonts": "Visual Foundation",
    "catppuccin-theme": "Visual Foundation",
    "terminal": "Visual Foundation",
    "shell-styling": "Visual Foundation",
    "zsh-enhancements": "Visual Foundation",
    "development": "Dev Languages",
    "docker": "Containers",
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
    "cloud-native": "Cloud Native",
}

PHASE_ORDER = sorted(list(set(ROLE_PHASE_MAP.values())), key=list(ROLE_PHASE_MAP.values()).index)


class RichInterface:
    """Handles all Rich rendering logic."""

    def __init__(self, console: Any):
        self.console = console
        self.log_level = os.environ.get("VPS_LOG_LEVEL", "minimal").lower()
        if RICH_AVAILABLE:
            self.layout = Layout()
        else:
            self.layout = Dummy()
        self.log_messages: List[Dict[str, Any]] = []
        self.max_log_items = 15
        
        # State
        self.current_phase: Optional[str] = None
        self.completed_phases: Set[str] = set()
        self.stats = {"ok": 0, "changed": 0, "failed": 0, "skipped": 0}
        self.start_time = time.time()

        # Progress components
        self.overall_progress: Any = Progress(
            cast(Any, TextColumn("[bold blue]{task.description}")),
            cast(Any, BarColumn(bar_width=None, complete_style="green", finished_style="green")),
            cast(Any, TextColumn("[progress.percentage]{task.percentage:>3.0f}%")),
            cast(Any, TimeElapsedColumn()),
            expand=True,
        )
        self.task_progress: Any = Progress(
            cast(Any, SpinnerColumn(spinner_name="dots", style="mauve")),
            cast(Any, TextColumn("[bold mauve]{task.description}")),
            cast(Any, BarColumn(bar_width=None, style="surface2")),
            cast(Any, TextColumn("[progress.percentage]{task.percentage:>3.0f}%")),
            expand=True,
        )
        
        # Explicit type annotation to satisfy static analysis
        # Using cast to Any to avoid "variable not allowed in type expression"
        self.overall_task_id: Any = cast(Any, self.overall_progress).add_task("Total Progress", total=100)
        self.current_task_id: Any = None

        self._init_layout()

    def _init_layout(self):
        """Define the TUI grid layout."""
        if not hasattr(self.layout, "split"):
             return

        self.layout.split(
            Layout(name="header", size=3),
            Layout(name="main", ratio=1),
            Layout(name="footer", size=3),
        )
        self.layout["main"].split_row(
            Layout(name="logs", ratio=6),
            Layout(name="status", ratio=4),
        )

    def get_renderable(self):
        """Update and return the main layout."""
        # Header
        self.layout["header"].update(self._make_header())
        
        # Logs Panel
        self.layout["logs"].update(self._make_logs_panel())
        
        # Status Panel (Progress + Stats)
        self.layout["status"].update(self._make_status_panel())
        
        # Footer (Milestones)
        self.layout["footer"].update(self._make_footer())
        
        return self.layout

    def _make_header(self):
        """Create the top header bar."""
        grid = Table.grid(expand=True)
        grid.add_column(justify="left", ratio=1)
        grid.add_column(justify="right")
        
        title = Text("  VPS RDP WORKSTATION ", style="bold white on blue")
        version = Text(" v3.0.0 ", style="white on #313244")
        
        grid.add_row(title, version)
        return Panel(grid, style="on #1e1e2e", box=box.SQUARE, padding=(0, 1), border_style="blue")

    def _make_logs_panel(self):
        """Create the scrolling log table."""
        # Use a Group to stack the table and potential error details
        renderables = []
        
        table = Table.grid(expand=True, padding=(0, 1))
        table.add_column(width=3)  # Icon
        table.add_column(ratio=1)  # Message
        table.add_column(width=10, justify="right")  # Duration

        if not self.log_messages:
            table.add_row("", "[dim]Initializing...[/dim]", "")
        
        # Calculate start index to show last N items
        # If we have expanded errors, we might show fewer items to keep layout stable
        visible_msgs = self.log_messages[-self.max_log_items:]
        
        for msg in visible_msgs:
            icon = msg.get("icon", "•")
            text = msg.get("text", "")
            style = msg.get("style", "white")
            duration = msg.get("duration", "")
            
            table.add_row(
                Text(icon, style=style),
                Text(text, style=style),
                Text(duration, style="dim")
            )

        renderables.append(table)

        # If the *last* message is a failure and we are in full mode, show its details
        if self.log_level == "full" and self.log_messages:
            last_msg = self.log_messages[-1]
            if last_msg.get("status") == "failed" and last_msg.get("error_details"):
                error_panel = self._make_error_details(last_msg)
                if error_panel:
                     renderables.append(error_panel)

        return Panel(
            Group(*renderables),
            title="[bold blue]Activity Log[/]",
            border_style="surface0",
            box=box.ROUNDED,
            padding=(0, 0),
        )

    def _make_error_details(self, msg):
        """Create a collapsible panel for error details."""
        if not msg.get("error_details"):
            return None
            
        error_text = Text(msg["error_details"], style="red")
        return Panel(
            error_text,
            title="[bold red]Error Details[/]",
            border_style="red",
            box=box.ROUNDED,
            expand=True
        )

    def _make_status_panel(self):
        """Create the right-side status panel."""
        stats_table = Table.grid(expand=True, padding=(0, 1))
        stats_table.add_column(ratio=1)
        stats_table.add_column(justify="right")
        
        stats_table.add_row("[green]✓ OK[/]", str(self.stats["ok"]))
        stats_table.add_row("[yellow]~ Changed[/]", str(self.stats["changed"]))
        stats_table.add_row("[red]✗ Failed[/]", str(self.stats["failed"]))
        stats_table.add_row("[dim]- Skipped[/]", str(self.stats["skipped"]))

        content = Group(
            Panel(self.overall_progress, box=box.MINIMAL, title="Overall", border_style="blue"),
            Panel(self.task_progress, box=box.MINIMAL, title="Current Task", border_style="mauve"),
            Panel(stats_table, box=box.MINIMAL, title="Statistics", border_style="surface1"),
        )
        
        return Panel(
            content,
            title="[bold mauve]Status[/]",
            border_style="surface0",
            box=box.ROUNDED,
        )

    def _make_footer(self):
        """Create the milestone tracker footer."""
        phases = []
        for phase in PHASE_ORDER:
            if phase in self.completed_phases:
                style = "green"
                icon = "●"
            elif phase == self.current_phase:
                style = "bold blue"
                icon = "◉"
            else:
                style = "dim surface1"
                icon = "○"
            phases.append(Text(f"{icon} {phase}", style=style))
            phases.append(Text("  ")) # Spacer

        return Panel(
            Text.assemble(*phases),
            style="on #1e1e2e",
            box=box.SQUARE,
            padding=(0, 1),
            border_style="surface0"
        )

    def add_log(self, status: str, message: str, duration: float = 0.0):
        """Add a log entry."""
        icons = {
            "ok": "✓",
            "changed": "⟳",
            "failed": "✗",
            "skipped": "−",
            "info": "ℹ"
        }
        styles = {
            "ok": "green",
            "changed": "yellow",
            "failed": "red",
            "skipped": "dim",
            "info": "blue"
        }
        
        dur_str = f"{duration:.1f}s" if duration > 0 else ""
        
        # Only add error details if log level is full
        error_details = None
        if status == "failed" and self.log_level == "full":
             # Extract message from the log string if possible, or pass it separately
             # For now, we assume the message contains the details
             error_details = message

        self.log_messages.append({
            "icon": icons.get(status, "•"),
            "text": message,
            "style": styles.get(status, "white"),
            "duration": dur_str,
            "status": status,
            "error_details": error_details
        })

    def set_phase(self, role_name: str):
        """Update current phase based on role."""
        new_phase = ROLE_PHASE_MAP.get(role_name)
        if new_phase and new_phase != self.current_phase:
            if self.current_phase:
                self.completed_phases.add(self.current_phase)
            self.current_phase = new_phase

    def update_task(self, description: str):
        """Update the current task spinner."""
        if self.current_task_id is None:
            self.current_task_id = self.task_progress.add_task(description, total=None)
        else:
            self.task_progress.update(self.current_task_id, description=description)
        
        # Advance overall progress slightly
        self.overall_progress.advance(self.overall_task_id, 0.5)


class CallbackModule(CallbackBase):
    """
    Ansible callback plugin for Rich TUI.
    """
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "stdout"
    CALLBACK_NAME = "rich_tui"

    def __init__(self):
        super(CallbackModule, self).__init__()
        self.ui: Any = None
        self.live: Any = None
        self.current_task_start = 0.0
        
        # Theme setup
        self.theme = Theme(THEME_COLORS)
        
        # Detect environment
        self.is_tty = os.isatty(1) or os.environ.get("VPS_FORCE_TUI") == "true"
        self.is_navigator = "ansible-navigator" in os.environ.get("ansible_cmdline", "")

    def v2_playbook_on_start(self, playbook):
        if not RICH_AVAILABLE or not self.is_tty:
            return

        # Explicitly cast Theme to Any to bypass type checking against Dummy
        console = Console(theme=cast(Any, self.theme), force_terminal=True)
        self.ui = RichInterface(console)
        
        # Use Live context for automatic refreshing
        # In navigator, we might need to be careful with stdout redirection
        self.live = Live(
            self.ui.get_renderable(),
            console=cast(Any, console),
            refresh_per_second=4,
            auto_refresh=True,
            redirect_stdout=False,
            redirect_stderr=False,
            screen=True # Fullscreen mode
        )
        # Use getattr/call to avoid type checking issues with fallback dummy
        start_method = getattr(self.live, "start", None)
        if callable(start_method):
            start_method()

    def v2_playbook_on_task_start(self, task, is_conditional):
        self.current_task_start = time.time()
        if self.ui:
            # Update Role/Phase
            if hasattr(task, '_role') and task._role:
                self.ui.set_phase(task._role.get_name())
            
            # Update Task Spinner
            self.ui.update_task(task.get_name())
            
            if self.live:
                update_method = getattr(self.live, "update", None)
                if callable(update_method):
                    update_method(self.ui.get_renderable())

    def _handle_result(self, result, status: str):
        if not self.ui:
            return

        duration = time.time() - self.current_task_start
        task_name = result._task.get_name()
        
        # Stats update
        self.ui.stats[status] += 1
        
        # Log update
        msg = task_name
        if status == "failed":
            msg += f" - {result._result.get('msg', 'Unknown Error')}"
            
        self.ui.add_log(status, msg, duration)
        
        if self.live:
             update_method = getattr(self.live, "update", None)
             if callable(update_method):
                update_method(self.ui.get_renderable())

    def v2_runner_on_ok(self, result):
        status = "changed" if result._result.get("changed", False) else "ok"
        self._handle_result(result, status)

    def v2_runner_on_failed(self, result, ignore_errors=False):
        status = "skipped" if ignore_errors else "failed"
        self._handle_result(result, status)

    def v2_runner_on_skipped(self, result):
        self._handle_result(result, "skipped")

    def v2_runner_on_unreachable(self, result):
        self._handle_result(result, "failed")

    def v2_playbook_on_stats(self, stats):
        if self.live:
            stop_method = getattr(self.live, "stop", None)
            if callable(stop_method):
                stop_method()
        
        # Print final summary if needed
        if self.ui and self.ui.console:
            self.ui.console.print(self.ui._make_status_panel())
