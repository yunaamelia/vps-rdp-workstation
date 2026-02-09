# KDE Optimization Learnings

## Configuration
- KDE configuration files are standard INI files (`~/.config/*rc`).
- `community.general.ini_file` is reliable for these edits.
- Baloo requires both service disabling (`balooctl disable`) and config update (`Indexing-Enabled=false`) to persist effectively.

## Performance
- Disabling Blur and Animations in KWin drastically improves RDP latency.
- ForceLowestLatency policy is essential for remote sessions.

## Automation
- `kpackagetool6` is needed for installing KWin scripts like Polonium (if manually installing), but we stuck to standard tools for this pass.
