#!/usr/bin/env python3
"""
Rich CLI Wrapper for setup.sh
Provides beautiful TUI output for Bash scripts using the Rich library.
"""
import sys
import subprocess
import argparse
from typing import Optional

# UI Palette
COLORS = {
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
    "overlay0": "#6c7086",
    "surface0": "#313244",
}

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.text import Text
    from rich.progress import Progress, SpinnerColumn, TextColumn
    from rich import box
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

def get_console():
    if RICH_AVAILABLE:
        return Console(highlight=False)
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
        console.print(f"[{COLORS['blue']}]ℹ[/]  {msg}")
    elif level == "success":
        console.print(f"[{COLORS['green']}]✓[/]  {msg}")
    elif level == "warn":
        console.print(f"[{COLORS['yellow']}]⚠[/]  {msg}")
    elif level == "error":
        console.print(f"[{COLORS['red']}]✗[/]  {msg}")
    else:
        console.print(msg)

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

    with Progress(
        SpinnerColumn(style=COLORS["mauve"]),
        TextColumn("[bold blue]{task.description}"),
        transient=True,
        console=console
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
            console.print(f"[{COLORS['green']}]✓[/]  {msg}")
        else:
            console.print(f"[{COLORS['red']}]✗[/]  {msg}")
            console.print(Panel(stderr.strip(), title="Error Details", border_style="red"))
            sys.exit(process.returncode)

def print_banner(version: str):
    """Print the application banner."""
    if not RICH_AVAILABLE:
        print(f"VPS RDP WORKSTATION v{version}")
        return

    console = get_console()
    if not console:
        return

    # ASCII Art
    art = """
[bold cyan]╦  ╦╔═╗╔═╗  ╦═╗╔╦╗╔═╗  ╦ ╦╔═╗╦═╗╦╔═╔═╗╔╦╗╔═╗╔╦╗╦╔═╗╔╗╔
╚╗╔╝╠═╝╚═╗  ╠╦╝ ║║╠═╝  ║║║║ ║╠╦╝╠╩╗╚═╗ ║ ╠═╣ ║ ║║ ║║║║
 ╚╝ ╩  ╚═╝  ╩╚══╩╝╩    ╚╩╝╚═╝╩╚═╩ ╩╚═╝ ╩ ╩ ╩ ╩ ╩╚═╝╝╚╝[/]
    """

    panel = Panel(
        Text.from_markup(art.strip() + f"\n\n[dim]Version {version} | Security-Hardened | Debian 13[/]"),
        box=box.ROUNDED,
        border_style=COLORS["blue"],
        expand=False,
        padding=(1, 2)
    )
    console.print(panel)

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
