# KDE Research & Optimization Prompt

## Prompt Engineering for Deep KDE Documentation Analysis

### Context

You are an expert in KDE Plasma desktop environment, Linux system administration, and developer productivity tools. You have access to the comprehensive awesome-kde repository documentation that catalogs official and community KDE applications, plugins, themes, and extensions.

### Primary Objective

Analyze the KDE ecosystem documentation to identify and recommend tools, configurations, and best practices specifically optimized for:

1. **Remote Desktop Workstation** (XRDP/RDP access)
2. **Developer Productivity** (multi-language development)
3. **System Performance** (VPS resource optimization)
4. **Security Hardening** (remote access security)
5. **Quality of Life** (automation, workflow efficiency)

---

## Analysis Framework

### Phase 1: Tool Categorization & Prioritization

Analyze all KDE components and categorize them by:

#### 🔴 CRITICAL (Must Install)

Tools essential for core functionality:

- System management & monitoring
- File management & terminal
- Security & authentication
- Remote desktop optimization
- Core development tools

#### 🟡 HIGH PRIORITY (Strongly Recommended)

Tools that significantly enhance productivity:

- Developer utilities & editors
- Version control integration
- Code quality tools
- Performance monitoring
- Workflow automation

#### 🟢 OPTIONAL (Nice to Have)

Enhancement tools based on use case:

- Advanced theming & customization
- Multimedia tools
- Specialized utilities
- Productivity enhancers
- Quality of life improvements

---

### Phase 2: Best Practices Configuration

For each recommended tool, provide:

1. **Installation Method**
   - Package name (official repos vs AUR)
   - Dependencies and plugins
   - Installation order considerations

2. **Configuration Recommendations**
   - Default settings to modify
   - Performance optimization flags
   - Security hardening options
   - Integration with other tools

3. **Resource Impact**
   - Memory footprint
   - CPU usage patterns
   - Disk space requirements
   - Network bandwidth considerations

4. **Remote Desktop Compatibility**
   - XRDP/RDP performance considerations
   - Display protocol optimizations
   - Session persistence settings
   - Multi-user considerations

---

## Specific Analysis Requirements

### System & Core Components

**Research Focus:**

- Which core components are absolutely necessary for XRDP functionality?
- What KIO plugins enhance remote file operations?
- Which system monitors work best over RDP?
- What authentication/security tools integrate with remote sessions?

**Output Expected:**

```yaml
core_components:
  required:
    - package_name: <name>
      reason: <why critical>
      config: <key settings>
      rdp_optimization: <specific tweaks>

  recommended:
    - package_name: <name>
      benefit: <productivity gain>
      tradeoff: <resource cost>
```

---

### Development Tools

**Research Focus:**

- Which KDE native editors work well over remote desktop?
- What debugging tools have low latency over RDP?
- Which git integration plugins are most efficient?
- What code quality tools can run headless or with minimal GUI?

**Analysis Criteria:**

- Remote rendering performance
- Keyboard shortcut responsiveness
- Memory efficiency
- Multi-language support
- LSP integration quality

**Output Expected:**

```yaml
development_tools:
  editors:
    - name: <tool>
      languages: [<supported>]
      rdp_performance: <rating>
      memory_mb: <typical usage>
      plugins: [<essential plugins>]
      alternatives_comparison:
        vs_vscode: <pros/cons>
        vs_vim: <pros/cons>

  utilities:
    - name: <tool>
      use_case: <specific scenario>
      integration: [<works with>]
```

---

### Performance Optimization

**Research Focus:**

- Which KDE components can be safely disabled for VPS usage?
- What compositor effects should be turned off for RDP?
- Which indexing services can be tuned or disabled?
- What background services impact remote desktop performance?

**Optimization Targets:**

1. **Startup Time** - Reduce to < 10 seconds
2. **Memory Usage** - Keep base usage under 2GB
3. **Network Latency** - Minimize protocol overhead
4. **CPU Efficiency** - Avoid unnecessary animation/rendering

**Output Expected:**

```yaml
performance_config:
  disable:
    - component: <name>
      reason: <why disable>
      impact: <functionality lost>
      alternative: <if needed>

  tune:
    - component: <name>
      setting: <parameter>
      default: <value>
      optimized: <value>
      rationale: <why change>

  compositor:
    effects_to_disable: [<list>]
    backend_preference: <OpenGL/software>
    rendering_options:
      vsync: <on/off>
      triple_buffering: <on/off>
```

---

### Security Hardening

**Research Focus:**

- Which KDE components handle authentication/secrets?
- What desktop sharing/remote access tools need hardening?
- Which file managers have security audit trails?
- What clipboard managers are secure for sensitive data?

**Security Priorities:**

1. Secrets management (KWallet configuration)
2. Session locking behavior
3. Clipboard history security
4. Network transparency (KIO)
5. Privilege escalation (polkit/KAuth)

**Output Expected:**

```yaml
security_hardening:
  kwallet:
    encryption: <algorithm>
    auto_lock: <timeout>
    integration: [<apps that use it>]

  session_security:
    lock_on_idle: <minutes>
    screen_locker: <tool>
    password_quality: <requirements>

  network_security:
    kio_protocols: [<allowed>]
    remote_file_access: <policy>
    certificate_management: <tool>
```

---

### Quality of Life Enhancements

**Research Focus:**

- Which automation tools reduce repetitive tasks?
- What clipboard managers enhance productivity?
- Which file management plugins improve workflow?
- What keyboard-driven tools reduce mouse dependency?

**Productivity Metrics:**

- Time saved per day (estimate)
- Learning curve (hours to proficiency)
- Keyboard shortcut coverage
- Integration with existing tools

**Output Expected:**

```yaml
qol_tools:
  automation:
    - tool: <name>
      automates: <task>
      savings: <time per day>
      setup_effort: <hours>

  workflow:
    - tool: <name>
      improves: <workflow>
      keyboard_shortcuts: <count>
      mouse_reduction: <percentage>
```

---

## Integration with Ansible Project

**Context Awareness:**
This analysis is for the vps-rdp-workstation Ansible project which:

- Uses Debian 13 (testing/trixie)
- Installs KDE Plasma via `desktop` role
- Targets remote developers using RDP
- Already includes 50+ dev tools
- Has security hardening in place (UFW, fail2ban, SSH)

**Integration Requirements:**

1. **Package Compatibility**
   - Verify availability in Debian testing repos
   - Note if package requires backports or AUR equivalent
   - Identify Debian-specific package names

2. **Ansible Role Structure**
   - Which existing role should include this tool?
   - Does it need a new dedicated role?
   - What are the dependencies (other roles)?

3. **Idempotency Considerations**
   - How to detect if already installed?
   - How to verify configuration applied?
   - What state should be tracked?

4. **Variable Design**
   - What should be configurable?
   - What are sensible defaults?
   - What requires user input?

**Output Expected:**

```yaml
ansible_integration:
  package_mapping:
    upstream_name: <original>
    debian_name: <package>
    availability: <stable/testing/backports>

  role_placement:
    existing_role: <name>
    new_role: <if needed>
    dependencies: [<roles>]
    order: <sequence number>

  task_template:
    - name: <task description>
      ansible.builtin.apt:
        name: <package>
        state: present
      tags: [<tags>]
      when: <condition>

  variables:
    required:
      - var_name: <name>
        description: <purpose>
        default: <value>
    optional:
      - var_name: <name>
        description: <purpose>
        default: <value>
```

---

## Comparative Analysis

### Tool Comparison Matrix

For major categories, provide comparison tables:

**File Managers:**
| Tool | RDP Performance | Features | Memory | Learning Curve | Recommendation |
|------|----------------|----------|--------|----------------|----------------|
| Dolphin | ⭐⭐⭐⭐⭐ | Advanced | 180MB | Low | ✅ Default choice |
| Krusader | ⭐⭐⭐⭐ | Power user | 220MB | High | Optional for advanced users |

**Terminal Emulators:**
| Tool | RDP Latency | Features | Memory | GPU Acceleration | Recommendation |
|------|-------------|----------|--------|------------------|----------------|
| Konsole | ⭐⭐⭐⭐⭐ | Full-featured | 120MB | Software fallback | ✅ Default |
| Yakuake | ⭐⭐⭐⭐ | Drop-down | 140MB | Software fallback | ✅ Power users |

**Code Editors:**
| Tool | RDP Performance | Languages | Memory | LSP Support | Recommendation |
|------|----------------|-----------|--------|-------------|----------------|
| Kate | ⭐⭐⭐⭐⭐ | 50+ | 200MB | Full | ✅ Primary editor |
| KDevelop | ⭐⭐⭐ | C/C++/Python | 400MB | Full | Optional (resource intensive) |

---

## Output Format

### Final Deliverable Structure

```markdown
# KDE Tools & Configuration Recommendations

# For: VPS RDP Workstation (Debian 13 + KDE Plasma)

## Executive Summary

- Total recommended packages: <count>
- Estimated additional disk space: <GB>
- Estimated additional memory: <MB>
- Implementation effort: <hours>
- Performance impact: <rating>

## Critical Installations (Must Have)

[Detailed list with rationale]

## High Priority Installations (Should Have)

[Detailed list with rationale]

## Optional Installations (Nice to Have)

[Detailed list with rationale]

## Configuration Best Practices

[Detailed configuration guide]

## Ansible Implementation Plan

[Ready-to-use Ansible tasks]

## Testing & Validation

[How to verify installation and configuration]

## Troubleshooting Guide

[Common issues and solutions]

## Performance Benchmarks

[Before/after metrics]

## Security Audit Checklist

[Security verification steps]

## Maintenance Plan

[Update strategy and monitoring]
```

---

## Prompt Execution Instructions

### Step 1: Initial Analysis

```
Analyze the awesome-kde documentation and create a comprehensive inventory of:
1. All official KDE applications (from apps.kde.org)
2. All core components and libraries
3. All third-party extensions and plugins
4. Categorize by functionality (system, development, multimedia, etc.)
```

### Step 2: Filtering & Prioritization

```
Filter the inventory based on:
1. Relevance to remote desktop usage
2. Suitability for developer workflows
3. Resource efficiency (VPS constraints)
4. Security implications
5. Integration with existing tools (in vps-rdp-workstation project)
```

### Step 3: Deep Dive Research

```
For each shortlisted tool:
1. Research Debian package availability
2. Identify dependencies and plugins
3. Document configuration options
4. Test performance considerations
5. Review security implications
6. Verify RDP compatibility
```

### Step 4: Synthesis & Recommendations

```
Compile findings into:
1. Prioritized tool list with justifications
2. Configuration best practices
3. Ansible implementation code
4. Performance optimization guide
5. Security hardening checklist
```

---

## Quality Assurance Criteria

### Recommendations Must Include:

✅ **Justification** - Clear reasoning for each recommendation
✅ **Trade-offs** - Honest assessment of costs/benefits
✅ **Alternatives** - Comparison with other options
✅ **Evidence** - Based on documentation, not assumptions
✅ **Actionable** - Specific steps, not generic advice
✅ **Tested** - Prefer proven solutions over theoretical
✅ **Maintained** - Check package update frequency
✅ **Compatible** - Verify Debian 13 availability

### Red Flags to Avoid:

❌ Recommending AUR-only packages without Debian alternatives
❌ Suggesting resource-intensive tools without justification
❌ Ignoring security implications
❌ Overlooking RDP performance impact
❌ Proposing unmaintained or abandoned projects
❌ Making assumptions without verification
❌ Copying default recommendations without context

---

## Bonus: Future-Proofing Considerations

1. **KDE 6 Migration** - Are recommended tools Plasma 6 compatible?
2. **Wayland Support** - How do tools perform under Wayland vs X11?
3. **Flatpak Integration** - Should some tools be Flatpak instead?
4. **Container Support** - Can tools run in containerized environments?
5. **AI Integration** - Which tools have LLM/AI capabilities (Alpaka, etc.)?

---

## Example Query Pattern

Use this pattern to query the documentation:

```
Based on the awesome-kde documentation, identify the top 5 tools in the
[CATEGORY] category that are:
1. Available in Debian stable/testing repositories
2. Optimized for remote desktop usage
3. Use less than [X]MB of memory
4. Have active development (updated in last 6 months)
5. Integrate well with [EXISTING_TOOLS]

For each tool, provide:
- Package name (Debian)
- Key features relevant to remote development
- Memory/CPU footprint
- RDP performance rating (1-5 stars)
- Configuration recommendations
- Security considerations
- Ansible task template

Then compare against alternatives and justify your recommendation.
```

---

## Success Metrics

This prompt is successful if it produces:

1. ✅ A curated list of 20-30 high-value KDE tools (not 200+)
2. ✅ Detailed configuration guides ready for Ansible implementation
3. ✅ Performance optimization that reduces RDP latency by 20%+
4. ✅ Security hardening that passes audit without breaking functionality
5. ✅ Integration plan that requires < 4 hours implementation time
6. ✅ Documentation clear enough for non-KDE experts to implement

---

## Meta-Learning Loop

After implementation:

1. **Measure Impact** - Track actual performance metrics
2. **Gather Feedback** - User experience with recommended tools
3. **Refine Recommendations** - Update based on real-world data
4. **Document Lessons** - What worked, what didn't
5. **Iterate Prompt** - Improve this prompt based on outcomes

---

## Appendix: Quick Reference

### Essential KDE Documentation Links

- Official Apps: https://apps.kde.org/
- KDE System Settings: https://userbase.kde.org/System_Settings
- KDE Development: https://develop.kde.org/
- KDE Bug Tracker: https://bugs.kde.org/

### Debian-Specific Resources

- Debian KDE Packages: https://packages.debian.org/search?searchon=names&keywords=kde
- Debian Testing Tracker: https://tracker.debian.org/
- Debian Backports: https://backports.debian.org/

### Performance Profiling Tools

- `plasma-systemmonitor` - KDE's built-in resource monitor
- `ksystemstats` - Backend for systemmonitor
- `htop` / `btop` - Terminal-based monitoring

### Security Audit Tools

- `kwalletmanager` - Secrets management
- `polkit-kde-agent` - Privilege escalation
- `plasma-firewall` - Firewall frontend (if not using UFW directly)

---

## Final Checklist Before Submitting Recommendations

- [ ] All packages verified available in Debian testing
- [ ] Memory footprint calculated for recommended tools
- [ ] RDP performance tested or documented from reliable sources
- [ ] Security implications reviewed and mitigation provided
- [ ] Ansible tasks are idempotent and follow project conventions
- [ ] Configuration files use Jinja2 templates with proper variables
- [ ] Dependencies clearly documented and ordered correctly
- [ ] Alternative options compared and decision justified
- [ ] Documentation follows markdown best practices
- [ ] Code samples are syntactically correct and tested
- [ ] No hardcoded secrets or sensitive information
- [ ] Resource requirements clearly stated
- [ ] Rollback procedure documented
- [ ] Validation tests provided
- [ ] Troubleshooting guide included

---

**End of Prompt Engineering Document**

**Usage:** Copy the relevant sections and customize based on specific analysis
needs. This prompt follows best practices from the AI Safety & Prompt Engineering
instructions in `.github/instructions/ai-safety-prompt.instructions.md`.
