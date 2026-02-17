#!/usr/bin/env python3
"""
Rich CLI Wrapper for setup.sh
Provides beautiful TUI output for Bash scripts using the Rich library.
Aligned with Ansible Rich TUI Callback theme.
"""
import sys
import subprocess
import argparse
from typing import Optional

# Unified Theme Colors (Matches plugins/callback/rich_tui.py)
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

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.text import Text
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn
    from rich.theme import Theme
    from rich.style import Style
    from rich import box
    from rich.layout import Layout
    from rich.table import Table
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

    class Dummy:
        ROUNDED = None

        def __init__(self, *args, **kwargs): pass
        def __getattr__(self, _): return self
        def __call__(self, *args, **kwargs): return self
        def __enter__(self): return self
        def __exit__(self, *args): pass

        @classmethod
        def grid(cls, *args, **kwargs): return cls()

        def add_column(self, *args, **kwargs): pass
        def add_row(self, *args, **kwargs): pass
        def add_task(self, *args, **kwargs): return None

    # Allow dummy classes to be used in type unions by registering them
    Console = Panel = Text = Progress = SpinnerColumn = TextColumn = BarColumn = TimeElapsedColumn = Theme = Style = box = Layout = Table = Dummy # type: ignore

from typing import cast, Any

def get_console():
    if RICH_AVAILABLE:
        theme = Theme(THEME_COLORS)
        return Console(theme=cast(Any, theme), highlight=False)
    return None

def print_log(level: str, msg: str):
    """Print a log message with icon and color."""
    if not RICH_AVAILABLE:
        print(f"[{level.upper()}] {msg}")
        return

    console = get_console()
    if not console:
        return

    if level == "info":
        console.print(f"[blue]ℹ[/]  [text]{msg}[/]")
    elif level == "success":
        console.print(f"[green]✓[/]  [text]{msg}[/]")
    elif level == "warn":
        console.print(f"[yellow]⚠[/]  [text]{msg}[/]")
    elif level == "error":
        console.print(f"[red]✗[/]  [text]{msg}[/]")
    else:
        console.print(f"[text]{msg}[/]")

def run_spinner(msg: str, cmd: str):
    """Run a shell command with a spinner."""
    if not RICH_AVAILABLE:
        print(f"Running: {msg}...")
        ret = subprocess.call(cmd, shell=True)
        if ret == 0:
            print("Done.")
        else:
            print("Failed.")
        sys.exit(ret)

    console = get_console()
    if not console:
        return

    # Using the same spinner style as the Ansible callback
    with Progress(
        cast(Any, SpinnerColumn(spinner_name="dots", style="mauve")),
        cast(Any, TextColumn("[bold blue]{task.description}")),
        transient=True,
        console=cast(Any, console)
    ) as progress:
        task = progress.add_task(msg, total=None)

        # Run command
        process = subprocess.Popen(
            cmd,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        stdout, stderr = process.communicate()

        if process.returncode == 0:
            console.print(f"[green]✓[/]  [text]{msg}[/]")
        else:
            console.print(f"[red]✗[/]  [text]{msg}[/]")

            # Show error output in a clean panel
            error_panel = Panel(
                cast(Any, Text(stderr.strip() or stdout.strip() or "No error output captured.", style="red")),
                title="[bold red]Command Failed[/]",
                border_style="red",
                box=cast(Any, box.ROUNDED),
                expand=True
            )
            console.print(cast(Any, error_panel))
            sys.exit(process.returncode)

def print_banner(version: str):
    """Print the application banner."""
    if not RICH_AVAILABLE:
        print(f"VPS RDP WORKSTATION v{version}")
        return

    console = get_console()
    if not console:
        return

    # Cleaner, more modern ASCII Art
    art = """
   _    __ ___  ___     ___   ___   ___
  | |  / /| _ \\/ __|   | _ \\ |   \\ | _ \\
  | | / / |  _/\\__ \\   |   / | |) ||  _/
  | |/ /  |_|  |___/   |_|_\\ |___/ |_|
  |___/
    """

    # Metadata grid
    grid = Table.grid(expand=True)
    grid.add_column(justify="center", ratio=1)
    grid.add_row(cast(Any, Text(art, style="bold blue")))
    grid.add_row("")
    grid.add_row(cast(Any, Text(f"Workstation Setup v{version}", style="bold white")))
    grid.add_row(cast(Any, Text("Debian 13 (Trixie) | Security-Hardened | Cloud-Native", style="dim text")))

    panel = Panel(
        cast(Any, grid),
        box=cast(Any, box.ROUNDED),
        border_style="blue",
        padding=(1, 2),
        expand=False
    )
    console.print(cast(Any, panel))

def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command")

    # Log command
    log_parser = subparsers.add_parser("log")
    log_parser.add_argument("level", choices=["info", "success", "warn", "error"])
    log_parser.add_argument("msg")

    # Spinner command
    spin_parser = subparsers.add_parser("spinner")
    spin_parser.add_argument("msg")
    spin_parser.add_argument("cmd")

    # Banner command
    banner_parser = subparsers.add_parser("banner")
    banner_parser.add_argument("version")

    args = parser.parse_args()

    if args.command == "log":
        print_log(args.level, args.msg)
    elif args.command == "spinner":
        run_spinner(args.msg, args.cmd)
    elif args.command == "banner":
        print_banner(args.version)

if __name__ == "__main__":
    main()
