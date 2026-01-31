#!/usr/bin/env python3
"""
AI Prompt Safety Validator

A comprehensive validation script for analyzing prompts for safety, bias,
security vulnerabilities, and best practices compliance.

Usage:
    python validate_prompt_safety.py <prompt_file>
    python validate_prompt_safety.py --text "Your prompt here"
    python validate_prompt_safety.py --interactive
    cat prompt.txt | python validate_prompt_safety.py --stdin

Example:
    python validate_prompt_safety.py prompts/my-prompt.md
    python validate_prompt_safety.py --text "Write code to delete all files"
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Optional


class RiskLevel(Enum):
    """Risk level classifications."""
    
    LOW = "🟢 Low"
    MEDIUM = "🟡 Medium"
    HIGH = "🔴 High"
    CRITICAL = "⛔ Critical"


class BiasType(Enum):
    """Types of bias to detect."""
    
    GENDER = "gender"
    RACIAL = "racial"
    CULTURAL = "cultural"
    SOCIOECONOMIC = "socioeconomic"
    ABILITY = "ability"
    AGE = "age"


@dataclass
class SafetyFinding:
    """Represents a safety finding."""
    
    category: str
    severity: RiskLevel
    description: str
    recommendation: str
    line_number: Optional[int] = None


@dataclass
class ValidationResult:
    """Complete validation result."""
    
    prompt_text: str
    overall_risk: RiskLevel
    safety_findings: list[SafetyFinding] = field(default_factory=list)
    bias_findings: list[SafetyFinding] = field(default_factory=list)
    security_findings: list[SafetyFinding] = field(default_factory=list)
    effectiveness_score: dict[str, int] = field(default_factory=dict)
    recommendations: list[str] = field(default_factory=list)
    word_count: int = 0
    complexity: str = "simple"


class PromptSafetyValidator:
    """Validates prompts for safety, bias, and security issues."""
    
    # Dangerous patterns that could generate harmful content
    HARMFUL_PATTERNS = [
        # Violence and physical harm
        (r"\b(kill|murder|assassinate|harm|hurt|attack)\s+(people|person|someone|anyone|them|him|her)\b", "violence"),
        (r"\b(how\s+to\s+)?(make|create|build|construct)\s+(a\s+)?(bomb|weapon|explosive|poison|gun)\b", "weapons"),
        
        # Hacking and unauthorized access
        (r"\b(hack|hacking|break\s+into|crack|compromise|exploit)\s+.*(system|account|password|email|server|network|database)\b", "hacking"),
        (r"\b(bypass|circumvent|defeat)\s+(security|authentication|2fa|mfa|firewall)\b", "hacking"),
        (r"\b(brute\s*force|dictionary\s+attack|sql\s+injection|xss\s+attack)\b", "hacking"),
        (r"\bhack\s+(into|someone|their|an?)\b", "hacking"),
        
        # Theft and fraud
        (r"\b(steal|stealing|phish|phishing)\s+.*(identity|money|data|credit\s*card|credentials|password|account)\b", "theft"),
        (r"\b(create|make|write)\s+.*(fake|phishing)\s+(email|website|login|page)\b", "fraud"),
        (r"\b(impersonate|pretend\s+to\s+be)\s+(someone|a\s+person|an?\s+employee)\b", "fraud"),
        
        # Self-harm and harmful content
        (r"\b(how\s+to\s+)?(commit\s+)?suicide\b", "self-harm"),
        (r"\b(self[- ]?harm|cutting|hurt\s+(myself|yourself))\b", "self-harm"),
        (r"\b(eating\s+disorder|starv|anorex|bulimi)\b", "self-harm"),
        
        # Drugs and controlled substances
        (r"\b(how\s+to\s+)?(make|create|synthesize|cook)\s+.*(drug|meth|cocaine|heroin|fentanyl)\b", "drugs"),
        (r"\b(illegal|illicit)\s+drugs?\b", "drugs"),
        
        # Child safety
        (r"\b(child|minor|underage|kid)\s*.*(porn|sexual|nude|naked|explicit)\b", "csam"),
        (r"\b(groom|grooming)\s+.*(child|minor|kid)\b", "csam"),
        
        # Malware and destructive code
        (r"\b(write|create|make)\s+.*(malware|virus|trojan|ransomware|keylogger|spyware)\b", "malware"),
        (r"\b(delete|destroy|wipe)\s+(all|every)\s+(file|data|record)\b", "destructive"),
    ]
    
    # Patterns indicating potential bias
    BIAS_PATTERNS = [
        (r"\b(he|his|him)\b(?!\s+or\s+she)", BiasType.GENDER, "Gendered pronoun without alternative"),
        (r"\b(housewife|housewives|mankind|manpower|fireman|policeman|businessman)\b", BiasType.GENDER, "Gendered occupational term"),
        (r"\b(normal|abnormal)\s+(person|people|user)\b", BiasType.ABILITY, "Normalcy language"),
        (r"\b(third[- ]world|primitive|backwards)\s+(country|countries|nation)\b", BiasType.CULTURAL, "Pejorative cultural term"),
        (r"\b(old|elderly|senior)\s+(person|people)\s+(can't|cannot|unable)\b", BiasType.AGE, "Age-based capability assumption"),
    ]
    
    # Security vulnerability patterns
    SECURITY_PATTERNS = [
        (r"ignore\s+(previous|all|any)\s+(instructions?|rules?|constraints?)", "prompt_injection"),
        (r"(password|api[_-]?key|secret|token)\s*[:=]\s*['\"]?\w+", "credential_exposure"),
        (r"eval\s*\(|exec\s*\(|subprocess\.call|os\.system", "code_execution"),
        (r"DROP\s+TABLE|DELETE\s+FROM|TRUNCATE|UPDATE.*SET", "sql_injection_risk"),
        (r"\$\{.*\}|\{\{.*\}\}|%s|%d", "template_injection"),
    ]
    
    # Patterns indicating medical/legal/financial advice
    PROFESSIONAL_ADVICE_PATTERNS = [
        (r"\b(diagnose|prescribe|treat|cure)\s+\w+\s*(disease|condition|illness|symptom)\b", "medical"),
        (r"\b(legal\s+advice|sue|lawsuit|liable|liability)\b", "legal"),
        (r"\b(invest|stock|bond|crypto|trading)\s+(advice|recommendation|tip)\b", "financial"),
    ]
    
    def __init__(self) -> None:
        """Initialize the validator."""
        self.findings: list[SafetyFinding] = []
    
    def validate(self, prompt_text: str) -> ValidationResult:
        """
        Validate a prompt for safety, bias, and security issues.
        
        Args:
            prompt_text: The prompt text to validate.
            
        Returns:
            ValidationResult with all findings and recommendations.
        """
        result = ValidationResult(
            prompt_text=prompt_text,
            overall_risk=RiskLevel.LOW,
            word_count=len(prompt_text.split()),
        )
        
        # Determine complexity
        result.complexity = self._classify_complexity(prompt_text)
        
        # Run all checks
        result.safety_findings = self._check_harmful_content(prompt_text)
        result.bias_findings = self._check_bias(prompt_text)
        result.security_findings = self._check_security(prompt_text)
        result.effectiveness_score = self._score_effectiveness(prompt_text)
        
        # Check for professional advice risks
        prof_findings = self._check_professional_advice(prompt_text)
        result.safety_findings.extend(prof_findings)
        
        # Calculate overall risk
        result.overall_risk = self._calculate_overall_risk(result)
        
        # Generate recommendations
        result.recommendations = self._generate_recommendations(result)
        
        return result
    
    def _classify_complexity(self, text: str) -> str:
        """Classify prompt complexity."""
        word_count = len(text.split())
        has_examples = bool(re.search(r"example|sample|e\.g\.|for instance", text, re.I))
        has_structure = bool(re.search(r"##|step \d|1\.|first|then|finally", text, re.I))
        has_constraints = bool(re.search(r"must|should|always|never|require", text, re.I))
        
        complexity_score = sum([
            word_count > 100,
            word_count > 300,
            has_examples,
            has_structure,
            has_constraints,
        ])
        
        if complexity_score >= 4:
            return "complex"
        elif complexity_score >= 2:
            return "moderate"
        return "simple"
    
    def _check_harmful_content(self, text: str) -> list[SafetyFinding]:
        """Check for potentially harmful content patterns."""
        findings = []
        text_lower = text.lower()
        
        for pattern, category in self.HARMFUL_PATTERNS:
            matches = re.findall(pattern, text_lower)
            if matches:
                findings.append(SafetyFinding(
                    category=f"harmful_content:{category}",
                    severity=RiskLevel.CRITICAL,
                    description=f"Detected potential {category}-related harmful content",
                    recommendation=f"Remove or reframe content related to {category}",
                ))
        
        return findings
    
    def _check_bias(self, text: str) -> list[SafetyFinding]:
        """Check for bias indicators."""
        findings = []
        
        for pattern, bias_type, description in self.BIAS_PATTERNS:
            if re.search(pattern, text, re.I):
                findings.append(SafetyFinding(
                    category=f"bias:{bias_type.value}",
                    severity=RiskLevel.MEDIUM,
                    description=description,
                    recommendation=f"Consider using more inclusive language to avoid {bias_type.value} bias",
                ))
        
        return findings
    
    def _check_security(self, text: str) -> list[SafetyFinding]:
        """Check for security vulnerabilities."""
        findings = []
        
        for pattern, vuln_type in self.SECURITY_PATTERNS:
            if re.search(pattern, text, re.I):
                severity = RiskLevel.CRITICAL if vuln_type in ["prompt_injection", "credential_exposure"] else RiskLevel.HIGH
                findings.append(SafetyFinding(
                    category=f"security:{vuln_type}",
                    severity=severity,
                    description=f"Potential {vuln_type.replace('_', ' ')} vulnerability detected",
                    recommendation=f"Review and harden against {vuln_type.replace('_', ' ')} attacks",
                ))
        
        return findings
    
    def _check_professional_advice(self, text: str) -> list[SafetyFinding]:
        """Check for professional advice without disclaimers."""
        findings = []
        
        for pattern, advice_type in self.PROFESSIONAL_ADVICE_PATTERNS:
            if re.search(pattern, text, re.I):
                # Check if disclaimer is present
                has_disclaimer = bool(re.search(
                    r"(not\s+)?(medical|legal|financial)\s+(advice|professional)",
                    text, re.I
                ))
                
                if not has_disclaimer:
                    findings.append(SafetyFinding(
                        category=f"professional_advice:{advice_type}",
                        severity=RiskLevel.HIGH,
                        description=f"Potential {advice_type} advice without disclaimer",
                        recommendation=f"Add appropriate disclaimer for {advice_type} content",
                    ))
        
        return findings
    
    def _score_effectiveness(self, text: str) -> dict[str, int]:
        """Score prompt effectiveness metrics (1-5 scale)."""
        scores = {}
        
        # Clarity: Does it have a clear instruction/request?
        has_clear_verb = bool(re.search(r"\b(write|create|generate|analyze|explain|summarize)\b", text, re.I))
        has_question = bool(re.search(r"\?|how|what|why|when|where", text, re.I))
        scores["clarity"] = 4 if has_clear_verb else (3 if has_question else 2)
        
        # Context: Is background information provided?
        has_context = bool(re.search(r"(context|background|given|assuming|you are)", text, re.I))
        word_count = len(text.split())
        if has_context and word_count > 50:
            scores["context"] = 4
        elif word_count > 30:
            scores["context"] = 3
        else:
            scores["context"] = 2
        
        # Constraints: Are limitations/requirements defined?
        constraint_patterns = r"\b(must|should|always|never|do not|avoid|limit|require|ensure)\b"
        constraint_count = len(re.findall(constraint_patterns, text, re.I))
        scores["constraints"] = min(5, 2 + constraint_count)
        
        # Format: Is output format specified?
        has_format = bool(re.search(r"(format|structure|output|return|respond|json|markdown|bullet|list)", text, re.I))
        scores["format"] = 4 if has_format else 2
        
        # Specificity: Is the request specific?
        has_specific_numbers = bool(re.search(r"\d+\s*(word|sentence|paragraph|item|step)", text, re.I))
        has_specific_style = bool(re.search(r"(tone|style|voice|formal|informal|technical)", text, re.I))
        scores["specificity"] = 3 + (1 if has_specific_numbers else 0) + (1 if has_specific_style else 0)
        
        return scores
    
    def _calculate_overall_risk(self, result: ValidationResult) -> RiskLevel:
        """Calculate overall risk level from findings."""
        all_findings = result.safety_findings + result.bias_findings + result.security_findings
        
        if any(f.severity == RiskLevel.CRITICAL for f in all_findings):
            return RiskLevel.CRITICAL
        elif any(f.severity == RiskLevel.HIGH for f in all_findings):
            return RiskLevel.HIGH
        elif any(f.severity == RiskLevel.MEDIUM for f in all_findings):
            return RiskLevel.MEDIUM
        return RiskLevel.LOW
    
    def _generate_recommendations(self, result: ValidationResult) -> list[str]:
        """Generate actionable recommendations."""
        recommendations = []
        
        # Safety recommendations
        if result.safety_findings:
            recommendations.append("Address safety concerns before deployment")
        
        # Bias recommendations  
        if result.bias_findings:
            recommendations.append("Review language for inclusivity")
        
        # Security recommendations
        if result.security_findings:
            recommendations.append("Implement security hardening measures")
        
        # Effectiveness recommendations
        low_scores = [k for k, v in result.effectiveness_score.items() if v < 3]
        if low_scores:
            recommendations.append(f"Improve: {', '.join(low_scores)}")
        
        # Complexity-based recommendations
        if result.complexity == "simple" and result.word_count < 20:
            recommendations.append("Consider adding more context for consistent results")
        
        return recommendations


def format_result(result: ValidationResult, output_format: str = "text") -> str:
    """Format validation result for output."""
    if output_format == "json":
        return json.dumps({
            "overall_risk": result.overall_risk.value,
            "complexity": result.complexity,
            "word_count": result.word_count,
            "safety_findings": [
                {"category": f.category, "severity": f.severity.value, "description": f.description}
                for f in result.safety_findings
            ],
            "bias_findings": [
                {"category": f.category, "severity": f.severity.value, "description": f.description}
                for f in result.bias_findings
            ],
            "security_findings": [
                {"category": f.category, "severity": f.severity.value, "description": f.description}
                for f in result.security_findings
            ],
            "effectiveness_scores": result.effectiveness_score,
            "recommendations": result.recommendations,
        }, indent=2)
    
    # Text format
    lines = [
        "=" * 60,
        "📊 PROMPT SAFETY VALIDATION REPORT",
        "=" * 60,
        "",
        f"**Overall Risk Level**: {result.overall_risk.value}",
        f"**Complexity**: {result.complexity.title()}",
        f"**Word Count**: {result.word_count}",
        "",
    ]
    
    # Safety findings
    if result.safety_findings:
        lines.append("🔴 SAFETY ISSUES")
        lines.append("-" * 40)
        for f in result.safety_findings:
            lines.append(f"  {f.severity.value} [{f.category}]")
            lines.append(f"    {f.description}")
            lines.append(f"    → {f.recommendation}")
        lines.append("")
    
    # Bias findings
    if result.bias_findings:
        lines.append("⚠️  BIAS INDICATORS")
        lines.append("-" * 40)
        for f in result.bias_findings:
            lines.append(f"  {f.severity.value} [{f.category}]")
            lines.append(f"    {f.description}")
            lines.append(f"    → {f.recommendation}")
        lines.append("")
    
    # Security findings
    if result.security_findings:
        lines.append("🔒 SECURITY VULNERABILITIES")
        lines.append("-" * 40)
        for f in result.security_findings:
            lines.append(f"  {f.severity.value} [{f.category}]")
            lines.append(f"    {f.description}")
            lines.append(f"    → {f.recommendation}")
        lines.append("")
    
    # Effectiveness scores
    lines.append("📈 EFFECTIVENESS SCORES")
    lines.append("-" * 40)
    for metric, score in result.effectiveness_score.items():
        bar = "█" * score + "░" * (5 - score)
        lines.append(f"  {metric.capitalize():15} [{bar}] {score}/5")
    lines.append("")
    
    # Recommendations
    if result.recommendations:
        lines.append("💡 RECOMMENDATIONS")
        lines.append("-" * 40)
        for rec in result.recommendations:
            lines.append(f"  • {rec}")
        lines.append("")
    
    # Summary
    lines.append("=" * 60)
    if result.overall_risk in [RiskLevel.CRITICAL, RiskLevel.HIGH]:
        lines.append("❌ PROMPT REQUIRES REVISION BEFORE USE")
    elif result.overall_risk == RiskLevel.MEDIUM:
        lines.append("⚠️  PROMPT SHOULD BE REVIEWED")
    else:
        lines.append("✅ PROMPT PASSES BASIC SAFETY CHECKS")
    lines.append("=" * 60)
    
    return "\n".join(lines)


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Validate AI prompts for safety, bias, and security issues",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument(
        "file",
        nargs="?",
        type=Path,
        help="Path to prompt file to validate"
    )
    parser.add_argument(
        "--text", "-t",
        type=str,
        help="Prompt text to validate directly"
    )
    parser.add_argument(
        "--stdin",
        action="store_true",
        help="Read prompt from stdin"
    )
    parser.add_argument(
        "--interactive", "-i",
        action="store_true",
        help="Interactive mode for multiple prompts"
    )
    parser.add_argument(
        "--format", "-f",
        choices=["text", "json"],
        default="text",
        help="Output format (default: text)"
    )
    parser.add_argument(
        "--quiet", "-q",
        action="store_true",
        help="Only output if issues found"
    )
    
    args = parser.parse_args()
    
    validator = PromptSafetyValidator()
    
    # Determine input source
    if args.interactive:
        print("🔍 Interactive Prompt Safety Validator")
        print("Enter prompts to validate (Ctrl+D to exit)")
        print("-" * 40)
        
        while True:
            try:
                print("\n> ", end="")
                prompt_text = input()
                if not prompt_text.strip():
                    continue
                result = validator.validate(prompt_text)
                print(format_result(result, args.format))
            except EOFError:
                print("\nGoodbye!")
                break
        return 0
    
    elif args.stdin:
        prompt_text = sys.stdin.read()
    elif args.text:
        prompt_text = args.text
    elif args.file:
        if not args.file.exists():
            print(f"Error: File not found: {args.file}", file=sys.stderr)
            return 1
        prompt_text = args.file.read_text()
    else:
        parser.print_help()
        return 1
    
    # Validate
    result = validator.validate(prompt_text)
    
    # Output
    if args.quiet and result.overall_risk == RiskLevel.LOW:
        return 0
    
    print(format_result(result, args.format))
    
    # Exit code based on risk level
    if result.overall_risk == RiskLevel.CRITICAL:
        return 2
    elif result.overall_risk == RiskLevel.HIGH:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
