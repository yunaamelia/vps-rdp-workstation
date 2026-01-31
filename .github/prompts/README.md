# AI Prompt Safety Review Suite

A comprehensive toolkit for analyzing and improving AI prompts for safety, bias, security, and effectiveness.

## 📁 Files Overview

| File | Purpose |
|------|---------|
| `ai-prompt-safety-review.prompt.md` | **Main prompt** - General purpose safety review with few-shot examples |
| `ai-prompt-safety-review-code.prompt.md` | **Code-specific** - Security-focused review for code generation prompts |
| `ai-prompt-safety-review-creative.prompt.md` | **Creative/Marketing** - Brand safety and bias review for content prompts |
| `../scripts/validate_prompt_safety.py` | **Validation script** - Automated pattern-based safety checking |

## 🚀 Quick Start

### Using the Prompts

1. **General Safety Review**: Use `ai-prompt-safety-review.prompt.md` for any prompt
2. **Code Prompts**: Use `ai-prompt-safety-review-code.prompt.md` for code generation
3. **Marketing/Creative**: Use `ai-prompt-safety-review-creative.prompt.md` for content

### Using the Validation Script

```bash
# Validate a prompt from text
python .github/scripts/validate_prompt_safety.py --text "Your prompt here"

# Validate a prompt file
python .github/scripts/validate_prompt_safety.py path/to/prompt.md

# Interactive mode for multiple prompts
python .github/scripts/validate_prompt_safety.py --interactive

# JSON output for CI/CD integration
python .github/scripts/validate_prompt_safety.py --format json --text "prompt"

# Quiet mode (exit code only)
python .github/scripts/validate_prompt_safety.py --quiet --text "prompt"
```

## 📊 Analysis Framework

### Safety Assessment (All Prompts)
- Harmful Content Risk
- Hate Speech & Discrimination
- Misinformation Risk
- Illegal Activities

### Bias Detection
- Gender bias (pronouns, stereotypes)
- Racial/Cultural bias
- Socioeconomic assumptions
- Ability-based stereotypes

### Security Assessment
- Prompt injection vulnerabilities
- Credential exposure
- Data leakage risks
- Access control issues

### Effectiveness Scoring (1-5)
- Clarity
- Context adequacy
- Constraint definition
- Format specification
- Specificity

## 🔍 Few-Shot Examples Included

### Main Prompt (`ai-prompt-safety-review.prompt.md`)
1. **Simple prompt analysis** - Basic summarization task
2. **Biased prompt detection** - Gender bias in job description
3. **Security vulnerability** - Prompt injection risk
4. **Critical safety issue** - Medical advice without disclaimers

### Code Prompt (`ai-prompt-safety-review-code.prompt.md`)
1. **SQL Injection risk** - Database query without parameterization
2. **Credential exposure** - AWS credentials in code
3. **Shell injection** - Unsafe variable expansion
4. **API key logging** - Sensitive data in logs

### Creative Prompt (`ai-prompt-safety-review-creative.prompt.md`)
1. **Marketing stereotypes** - Gender bias in targeting
2. **Health claims** - FDA compliance issues
3. **Fake reviews** - FTC violations
4. **Political content** - Brand safety risks

## 📋 Risk Levels

| Level | Symbol | Meaning | Action |
|-------|--------|---------|--------|
| Low | 🟢 | No significant issues | Approve |
| Medium | 🟡 | Minor concerns | Review |
| High | 🔴 | Significant issues | Revise |
| Critical | ⛔ | Severe safety/legal | Reject |

## 🔧 CI/CD Integration

### GitHub Actions Example

```yaml
name: Prompt Safety Check
on: [push, pull_request]

jobs:
  validate-prompts:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Validate prompts
        run: |
          for file in .github/prompts/*.md; do
            python .github/scripts/validate_prompt_safety.py --quiet "$file"
          done
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Low risk - passes |
| 1 | High risk - requires review |
| 2 | Critical risk - fails |

## 🎓 Educational Value

Each analysis includes:
- **Principle Applied**: What prompt engineering principle was used
- **Why It Matters**: Explanation of the improvement
- **Common Pitfalls**: What mistakes to avoid

## 📖 Best Practices

1. **Always prioritize safety** over functionality
2. **Use tiered analysis** - Simple prompts don't need full review
3. **Include disclaimers** for professional advice (medical, legal, financial)
4. **Test edge cases** - Consider misuse scenarios
5. **Document improvements** - Track what was changed and why

## 🤝 Contributing

When adding new prompts:
1. Run through the validation script first
2. Address any issues identified
3. Include appropriate few-shot examples
4. Document the use case and limitations

---

*Created as part of the AI Prompt Engineering Safety Review system.*
