# Quick Start: Starship Optimization

## Using the AI Prompt

Ask your AI assistant:

```
Using .github/prompts/starship-optimizer.prompt.md, optimize my Starship configuration with:
- theme: catppuccin-mocha
- performance_target: 250ms
- modules: directory, git, nodejs, python, rust, golang, php, character, cmd_duration
- config_path: ~/.config/starship.toml
```

## Manual Backup First

```bash
cp ~/.config/starship.toml ~/.config/starship.toml.backup.$(date +%Y%m%d_%H%M%S)
```

## Test New Configuration

```bash
# Validate syntax
starship config

# Measure performance
time starship prompt

# Reload shell
source ~/.zshrc
```

## Rollback if Needed

```bash
# List backups
ls -la ~/.config/starship.toml.backup.*

# Restore
cp ~/.config/starship.toml.backup.YYYYMMDD_HHMMSS ~/.config/starship.toml
source ~/.zshrc
```

## Available Themes

- `catppuccin-mocha` - Current project theme
- `tokyo-night` - Dark blue aesthetic
- `nord` - Arctic, bluish theme
- `gruvbox` - Retro groove colors
- `dracula` - Purple vampire theme

## Performance Targets

- **Fast**: 100-200ms (minimal modules)
- **Balanced**: 200-300ms (recommended)
- **Full-featured**: 300-500ms (all modules)

## Full Documentation

See [docs/STARSHIP_OPTIMIZATION.md](../docs/STARSHIP_OPTIMIZATION.md) for complete implementation guide including Ansible role creation.
