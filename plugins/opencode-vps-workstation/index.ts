/**
 * OpenCode Plugin: VPS RDP Developer Workstation
 *
 * Provides tools for managing a Debian 13 VPS setup with Ansible automation.
 * Transforms fresh VPS into security-hardened RDP developer workstation.
 */

import { type Plugin, tool } from "@opencode-ai/plugin";
import { $ } from "bun";

const PROGRESS_FILE = "/var/lib/vps-setup/progress.json";
const LOG_FILE = "/var/log/vps-setup.log";

export const VPSWorkstationPlugin: Plugin = async ({ directory, client }) => {
  const runCommand = async (cmd: string, cwd?: string) => {
    try {
      const result = await $`bash -c ${cmd}`.cwd(cwd || directory).quiet();
      return {
        success: true,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
        exitCode: result.exitCode,
      };
    } catch (error: any) {
      return {
        success: false,
        stdout: error.stdout?.toString() || "",
        stderr: error.stderr?.toString() || error.message,
        exitCode: error.exitCode || 1,
      };
    }
  };

  const getProgress = async () => {
    const result = await runCommand(
      `cat ${PROGRESS_FILE} 2>/dev/null || echo '{}'`,
    );
    try {
      return JSON.parse(result.stdout);
    } catch {
      return { status: "not_started" };
    }
  };

  const vpsSetup = tool({
    description: `Run the VPS RDP Workstation setup. Transforms a fresh Debian 13 VPS into a fully-configured RDP developer workstation with KDE Plasma, security hardening, and 50+ dev tools.

Modes:
- full: Complete installation (default)
- dry-run: Preview changes without applying
- ci: Non-interactive CI/CD mode

The setup executes 25 Ansible roles in strict order:
1. common → 2. security → 3. fonts → 4. desktop → 5. xrdp → ... → 25 roles total

IMPORTANT: Use setup.sh wrapper, never run ansible-playbook directly.`,
    args: {
      mode: tool.schema
        .string()
        .describe(
          "Setup mode: 'full' (complete install), 'dry-run' (preview only), or 'ci' (non-interactive)",
        )
        .default("full")
        .optional(),
      tags: tool.schema
        .string()
        .describe(
          "Comma-separated role tags to run specific phases (e.g., 'security,desktop')",
        )
        .optional(),
      verbose: tool.schema
        .boolean()
        .describe("Enable verbose output")
        .default(false)
        .optional(),
    },
    async execute(args, context) {
      let cmd = "./setup.sh";

      if (args.mode === "dry-run") {
        cmd += " --dry-run";
      } else if (args.mode === "ci") {
        cmd += " --ci";
      }

      if (args.verbose) {
        cmd += " --verbose";
      }

      if (args.tags) {
        cmd += ` -- --tags ${args.tags}`;
      }

      client.app.log({
        body: {
          service: "vps-workstation",
          level: "info",
          message: `Starting setup with mode: ${args.mode || "full"}`,
        },
      });

      const result = await runCommand(cmd, directory);

      if (result.success) {
        return `## ✅ VPS Setup Completed

\`\`\`
${result.stdout.slice(-2000)}
\`\`\`

**Next Steps:**
1. Connect via RDP to port 3389
2. Login with configured username/password
3. Enjoy your Nordic-themed KDE Plasma desktop!`;
      } else {
        return `## ❌ VPS Setup Failed

\`\`\`
${result.stderr.slice(-2000)}
\`\`\`

**Troubleshooting:**
- Check logs at \`/var/log/vps-setup.log\`
- Run with \`--verbose\` for detailed output
- Use \`vps-status\` to check progress`;
      }
    },
  });

  const vpsValidate = tool({
    description: `Run validation tests against the VPS workstation installation. Checks 30+ criteria including:

- Firewall configuration (UFW)
- SSH hardening
- RDP accessibility
- Desktop environment
- Development tools
- Security settings

Returns a detailed report of all validation checks.`,
    args: {
      category: tool.schema
        .string()
        .describe(
          "Validation category: 'all', 'security', 'desktop', 'tools', or 'quick'",
        )
        .default("all")
        .optional(),
    },
    async execute(args, context) {
      const result = await runCommand(
        `./tests/validate.sh ${args.category || ""}`,
        directory,
      );

      return `## VPS Validation Report

\`\`\`
${result.stdout || result.stderr}
\`\`\`

${result.success ? "✅ All validation checks passed" : "⚠️ Some validation checks failed"}`;
    },
  });

  const vpsStatus = tool({
    description: `Check the current installation progress and status of the VPS workstation.

Returns:
- Current installation phase
- Completed roles
- Failed roles (if any)
- Timestamps
- System information`,
    args: {},
    async execute(args, context) {
      const progress = await getProgress();

      const systemInfo = await runCommand(`
echo "=== System Info ==="
hostnamectl 2>/dev/null | head -5 || cat /etc/os-release | head -3
echo ""
echo "=== Memory ==="
free -h | head -2
echo ""
echo "=== Disk ==="
df -h / | head -2
echo ""
echo "=== Services ==="
systemctl is-active ufw ssh xrdp 2>/dev/null | paste -sd ' ' -
      `);

      return `## VPS Workstation Status

### Installation Progress
\`\`\`json
${JSON.stringify(progress, null, 2)}
\`\`\`

### System Information
\`\`\`
${systemInfo.stdout}
\`\`\`

### Recent Log Entries
\`\`\`
${(await runCommand(`tail -20 ${LOG_FILE} 2>/dev/null || echo "No log file found"`)).stdout}
\`\`\``;
    },
  });

  const vpsRollback = tool({
    description: `Rollback VPS workstation changes.

WARNING: This is destructive. Removes:
- Desktop environment (KDE Plasma)
- User configurations
- Installed packages
- Configurations files

Use with caution on production systems.`,
    args: {
      confirm: tool.schema
        .boolean()
        .describe("Must be true to execute rollback (safety check)")
        .default(false),
    },
    async execute(args, context) {
      if (!args.confirm) {
        return `## ⚠️ Rollback Not Executed

Set \`confirm: true\` to execute rollback.

**WARNING:** This will:
- Remove all installed packages
- Delete user configurations
- Restore system to pre-installation state`;
      }

      const result = await runCommand("./setup.sh --rollback", directory);

      return `## Rollback ${result.success ? "Completed" : "Failed"}

\`\`\`
${result.success ? result.stdout.slice(-1000) : result.stderr.slice(-1000)}
\`\`\``;
    },
  });

  const vpsRoleRun = tool({
    description: `Run specific Ansible roles by name. Useful for:
- Re-running failed roles
- Updating specific components
- Testing individual roles

Available roles:
- common, security, fonts
- desktop, xrdp, kde-optimization, kde-apps, whitesur-theme
- terminal, tmux, shell-styling, zsh-enhancements
- development, docker, editors
- tui-tools, network-tools, system-performance, text-processing
- file-management, dev-debugging, code-quality, productivity
- log-visualization, ai-devtools, cloud-native, monitoring`,
    args: {
      roles: tool.schema
        .string()
        .describe(
          "Comma-separated role names to run (e.g., 'security,desktop')",
        ),
    },
    async execute(args, context) {
      const tags = args.roles
        .split(",")
        .map((r) => r.trim())
        .join(",");
      const result = await runCommand(
        `ansible-playbook playbooks/main.yml --tags "${tags}" -v`,
        directory,
      );

      return `## Role Execution: ${args.roles}

\`\`\`
${result.success ? result.stdout.slice(-2000) : result.stderr.slice(-2000)}
\`\`\``;
    },
  });

  const vpsMoleculeTest = tool({
    description: `Run Molecule tests for Ansible roles. Tests run in Docker containers with systemd support.

Usage:
- Run all tests: leave role empty
- Run specific role: provide role name
- Run specific scenario: provide role and scenario

Test scenarios are located in \`molecule/<role>/\` directories.`,
    args: {
      role: tool.schema
        .string()
        .describe("Role name to test (empty for all roles)")
        .optional(),
      scenario: tool.schema
        .string()
        .describe("Specific test scenario (default: 'default')")
        .optional(),
    },
    async execute(args, context) {
      let cmd = "molecule test";

      if (args.role) {
        cmd += ` -s ${args.role}`;
      }

      if (args.scenario) {
        cmd += ` --scenario-name ${args.scenario}`;
      }

      client.app.log({
        body: {
          service: "vps-workstation",
          level: "info",
          message: `Running Molecule tests: ${args.role || "all"}`,
        },
      });

      const result = await runCommand(cmd, directory);

      return `## Molecule Test Results

\`\`\`
${result.stdout || result.stderr}
\`\`\`

${result.success ? "✅ Tests passed" : "❌ Tests failed"}`;
    },
  });

  return {
    tools: {
      "vps-setup": vpsSetup,
      "vps-validate": vpsValidate,
      "vps-status": vpsStatus,
      "vps-rollback": vpsRollback,
      "vps-role-run": vpsRoleRun,
      "vps-molecule-test": vpsMoleculeTest,
    },
    hooks: {
      "tool.execute.after": async (input, output) => {
        // Add consistent title to tool outputs
        const toolNames: Record<string, string> = {
          "vps-setup": "🖥️ VPS Workstation Setup",
          "vps-validate": "✅ VPS Validation",
          "vps-status": "📊 VPS Status",
          "vps-rollback": "↩️ VPS Rollback",
          "vps-role-run": "🚀 VPS Role Execution",
          "vps-molecule-test": "🧪 Molecule Tests",
        };

        if (toolNames[input.tool]) {
          output.title = toolNames[input.tool];
        }
      },
    },
  };
};

export default VPSWorkstationPlugin;
