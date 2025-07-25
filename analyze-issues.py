#!/usr/bin/env python3
"""
S-Quote Issue Analysis Tool
Automatically identifies potential issues, bugs, and improvements in the codebase
"""

import os
import re
import json
import subprocess
from pathlib import Path
from typing import List, Dict, Any
from dataclasses import dataclass
from datetime import datetime

@dataclass
class Issue:
    type: str
    severity: str  # 'critical', 'high', 'medium', 'low'
    file: str
    line: int
    description: str
    suggestion: str
    category: str

class CodeAnalyzer:
    def __init__(self, project_path: str):
        self.project_path = Path(project_path)
        self.issues: List[Issue] = []
        
    def analyze(self) -> List[Issue]:
        """Run all analysis methods"""
        print("🔍 Analyzing S-Quote codebase...")
        
        self.check_project_structure()
        self.analyze_swift_files()
        self.check_build_configuration()
        self.check_dependencies()
        self.check_security_issues()
        self.check_performance_issues()
        self.check_ui_issues()
        self.check_data_persistence()
        
        return self.issues
    
    def add_issue(self, issue: Issue):
        """Add an issue to the list"""
        self.issues.append(issue)
    
    def check_project_structure(self):
        """Check for project structure issues"""
        print("  📁 Checking project structure...")
        
        required_files = [
            "S Quote.xcodeproj/project.pbxproj",
            "S Quote/S_QuoteApp.swift",
            "S Quote/ContentView.swift",
            "README.md"
        ]
        
        for file_path in required_files:
            if not (self.project_path / file_path).exists():
                self.add_issue(Issue(
                    type="missing_file",
                    severity="high",
                    file=file_path,
                    line=0,
                    description=f"Required file missing: {file_path}",
                    suggestion="Create the missing file or check project structure",
                    category="project_structure"
                ))
        
        # Check for proper folder organization
        expected_folders = ["Models", "Views", "ViewModels", "Services"]
        source_path = self.project_path / "S Quote"
        
        for folder in expected_folders:
            if not (source_path / folder).exists():
                self.add_issue(Issue(
                    type="missing_folder",
                    severity="medium",
                    file=f"S Quote/{folder}",
                    line=0,
                    description=f"Recommended folder missing: {folder}",
                    suggestion=f"Create {folder} folder for better code organization",
                    category="project_structure"
                ))
    
    def analyze_swift_files(self):
        """Analyze Swift source files for common issues"""
        print("  🦉 Analyzing Swift files...")
        
        swift_files = list(self.project_path.rglob("*.swift"))
        
        for file_path in swift_files:
            if "DerivedData" in str(file_path) or "build" in str(file_path):
                continue
                
            self.analyze_swift_file(file_path)
    
    def analyze_swift_file(self, file_path: Path):
        """Analyze individual Swift file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
        except Exception as e:
            self.add_issue(Issue(
                type="file_read_error",
                severity="medium",
                file=str(file_path.relative_to(self.project_path)),
                line=0,
                description=f"Could not read file: {e}",
                suggestion="Check file encoding and permissions",
                category="file_system"
            ))
            return
        
        # Check for common Swift issues
        self.check_force_unwrapping(file_path, lines)
        self.check_retain_cycles(file_path, lines)
        self.check_hardcoded_strings(file_path, lines)
        self.check_long_functions(file_path, lines)
        self.check_missing_documentation(file_path, lines)
        self.check_deprecated_apis(file_path, lines)
        self.check_memory_leaks(file_path, lines)
    
    def check_force_unwrapping(self, file_path: Path, lines: List[str]):
        """Check for force unwrapping (!) which can cause crashes"""
        for i, line in enumerate(lines, 1):
            # Look for force unwrapping patterns
            if re.search(r'!\s*(?![=!])', line) and not line.strip().startswith('//'):
                # Exclude common safe patterns
                if not any(pattern in line for pattern in ['fatalError', 'precondition', '!!', 'Bundle.main']):
                    self.add_issue(Issue(
                        type="force_unwrapping",
                        severity="high",
                        file=str(file_path.relative_to(self.project_path)),
                        line=i,
                        description="Force unwrapping detected - potential crash risk",
                        suggestion="Use optional binding (if let) or nil coalescing (??)",
                        category="safety"
                    ))
    
    def check_retain_cycles(self, file_path: Path, lines: List[str]):
        """Check for potential retain cycles"""
        for i, line in enumerate(lines, 1):
            # Look for closures without weak/unowned self
            if 'self.' in line and any(keyword in line for keyword in ['{', 'completion', 'handler']):
                if 'weak' not in line and 'unowned' not in line:
                    self.add_issue(Issue(
                        type="potential_retain_cycle",
                        severity="medium",
                        file=str(file_path.relative_to(self.project_path)),
                        line=i,
                        description="Potential retain cycle in closure",
                        suggestion="Use [weak self] or [unowned self] in closure capture list",
                        category="memory"
                    ))
    
    def check_hardcoded_strings(self, file_path: Path, lines: List[str]):
        """Check for hardcoded strings that should be localized"""
        for i, line in enumerate(lines, 1):
            # Look for Text() with hardcoded strings
            text_match = re.search(r'Text\s*\(\s*"([^"]+)"\s*\)', line)
            if text_match and not line.strip().startswith('//'):
                text_content = text_match.group(1)
                # Skip system strings and single characters
                if len(text_content) > 3 and not text_content.startswith('system'):
                    self.add_issue(Issue(
                        type="hardcoded_string",
                        severity="low",
                        file=str(file_path.relative_to(self.project_path)),
                        line=i,
                        description=f"Hardcoded string: '{text_content}'",
                        suggestion="Consider using localized strings for better internationalization",
                        category="localization"
                    ))
    
    def check_long_functions(self, file_path: Path, lines: List[str]):
        """Check for overly long functions"""
        in_function = False
        function_start = 0
        brace_count = 0
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            
            # Function start
            if re.match(r'\s*func\s+\w+', line) or re.match(r'\s*var\s+\w+.*\{', line):
                in_function = True
                function_start = i
                brace_count = 0
            
            if in_function:
                brace_count += line.count('{') - line.count('}')
                
                # Function end
                if brace_count == 0 and function_start > 0:
                    function_length = i - function_start
                    if function_length > 50:  # Arbitrary threshold
                        self.add_issue(Issue(
                            type="long_function",
                            severity="medium",
                            file=str(file_path.relative_to(self.project_path)),
                            line=function_start,
                            description=f"Function is {function_length} lines long",
                            suggestion="Consider breaking down into smaller functions",
                            category="maintainability"
                        ))
                    in_function = False
                    function_start = 0
    
    def check_missing_documentation(self, file_path: Path, lines: List[str]):
        """Check for missing documentation"""
        for i, line in enumerate(lines, 1):
            # Check for public functions without documentation
            if re.match(r'\s*public\s+func\s+\w+', line) or re.match(r'\s*func\s+\w+', line):
                # Check if previous line has documentation
                if i > 1:
                    prev_line = lines[i-2].strip()
                    if not prev_line.startswith('///') and not prev_line.startswith('/**'):
                        self.add_issue(Issue(
                            type="missing_documentation",
                            severity="low",
                            file=str(file_path.relative_to(self.project_path)),
                            line=i,
                            description="Public function missing documentation",
                            suggestion="Add /// documentation comments",
                            category="documentation"
                        ))
    
    def check_deprecated_apis(self, file_path: Path, lines: List[str]):
        """Check for deprecated API usage"""
        deprecated_patterns = [
            (r'UIApplication\.shared\.keyWindow', 'Use scene-based window access'),
            (r'NSUserDefaults\.standard', 'Consider using UserDefaults.standard'),
        ]
        
        for i, line in enumerate(lines, 1):
            for pattern, suggestion in deprecated_patterns:
                if re.search(pattern, line):
                    self.add_issue(Issue(
                        type="deprecated_api",
                        severity="medium",
                        file=str(file_path.relative_to(self.project_path)),
                        line=i,
                        description=f"Deprecated API usage: {pattern}",
                        suggestion=suggestion,
                        category="compatibility"
                    ))
    
    def check_memory_leaks(self, file_path: Path, lines: List[str]):
        """Check for potential memory leaks"""
        for i, line in enumerate(lines, 1):
            # Check for Timer without invalidation
            if 'Timer.scheduledTimer' in line and 'invalidate' not in ''.join(lines[max(0, i-5):i+5]):
                self.add_issue(Issue(
                    type="potential_memory_leak",
                    severity="medium",
                    file=str(file_path.relative_to(self.project_path)),
                    line=i,
                    description="Timer created without visible invalidation",
                    suggestion="Ensure timer is invalidated in deinit or appropriate lifecycle method",
                    category="memory"
                ))
    
    def check_build_configuration(self):
        """Check build configuration issues"""
        print("  ⚙️ Checking build configuration...")
        
        pbxproj_path = self.project_path / "S Quote.xcodeproj" / "project.pbxproj"
        if pbxproj_path.exists():
            try:
                with open(pbxproj_path, 'r') as f:
                    content = f.read()
                
                # Check for hardcoded team IDs
                if 'DEVELOPMENT_TEAM' in content:
                    team_matches = re.findall(r'DEVELOPMENT_TEAM = ([^;]+);', content)
                    if team_matches:
                        self.add_issue(Issue(
                            type="hardcoded_team_id",
                            severity="low",
                            file="S Quote.xcodeproj/project.pbxproj",
                            line=0,
                            description="Hardcoded development team ID found",
                            suggestion="Use automatic code signing or environment variables",
                            category="build_config"
                        ))
                
                # Check deployment target
                if 'MACOSX_DEPLOYMENT_TARGET' in content:
                    target_matches = re.findall(r'MACOSX_DEPLOYMENT_TARGET = ([^;]+);', content)
                    for target in target_matches:
                        target_version = target.strip()
                        if target_version < "15.5":
                            self.add_issue(Issue(
                                type="old_deployment_target",
                                severity="medium",
                                file="S Quote.xcodeproj/project.pbxproj",
                                line=0,
                                description=f"Deployment target {target_version} is below recommended 15.5",
                                suggestion="Update deployment target to support latest features",
                                category="build_config"
                            ))
                            
            except Exception as e:
                self.add_issue(Issue(
                    type="build_config_error",
                    severity="medium",
                    file="S Quote.xcodeproj/project.pbxproj",
                    line=0,
                    description=f"Could not analyze build configuration: {e}",
                    suggestion="Check project file integrity",
                    category="build_config"
                ))
    
    def check_dependencies(self):
        """Check for dependency issues"""
        print("  📦 Checking dependencies...")
        
        # Check for Package.swift or Podfile
        package_swift = self.project_path / "Package.swift"
        podfile = self.project_path / "Podfile"
        
        if not package_swift.exists() and not podfile.exists():
            self.add_issue(Issue(
                type="no_dependency_manager",
                severity="low",
                file=".",
                line=0,
                description="No dependency manager configuration found",
                suggestion="Consider using Swift Package Manager for third-party dependencies",
                category="dependencies"
            ))
    
    def check_security_issues(self):
        """Check for security-related issues"""
        print("  🔒 Checking security issues...")
        
        # Check entitlements file
        entitlements_path = self.project_path / "S Quote" / "S_Quote.entitlements"
        if entitlements_path.exists():
            try:
                with open(entitlements_path, 'r') as f:
                    content = f.read()
                
                # Check for overly broad entitlements
                if 'com.apple.security.network.client' in content:
                    self.add_issue(Issue(
                        type="broad_network_entitlement",
                        severity="low",
                        file="S Quote/S_Quote.entitlements",
                        line=0,
                        description="Broad network client entitlement enabled",
                        suggestion="Review if network access is necessary for app functionality",
                        category="security"
                    ))
                        
            except Exception as e:
                self.add_issue(Issue(
                    type="entitlements_error",
                    severity="low",
                    file="S Quote/S_Quote.entitlements",
                    line=0,
                    description=f"Could not analyze entitlements: {e}",
                    suggestion="Check entitlements file format",
                    category="security"
                ))
    
    def check_performance_issues(self):
        """Check for performance-related issues"""
        print("  ⚡ Checking performance issues...")
        
        swift_files = list(self.project_path.rglob("*.swift"))
        
        for file_path in swift_files:
            if "DerivedData" in str(file_path) or "build" in str(file_path):
                continue
            
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                
                for i, line in enumerate(lines, 1):
                    # Check for synchronous operations on main thread
                    if any(pattern in line for pattern in ['URLSession.shared.dataTask', 'Data(contentsOf:']):
                        if 'DispatchQueue' not in ''.join(lines[max(0, i-3):i+3]):
                            self.add_issue(Issue(
                                type="main_thread_blocking",
                                severity="high",
                                file=str(file_path.relative_to(self.project_path)),
                                line=i,
                                description="Potentially blocking operation on main thread",
                                suggestion="Move to background queue using DispatchQueue",
                                category="performance"
                            ))
                    
                    # Check for inefficient string concatenation
                    if '+=' in line and 'String' in line:
                        self.add_issue(Issue(
                            type="inefficient_string_concat",
                            severity="low",
                            file=str(file_path.relative_to(self.project_path)),
                            line=i,
                            description="Inefficient string concatenation",
                            suggestion="Consider using String interpolation or StringBuilder",
                            category="performance"
                        ))
                        
            except Exception:
                continue
    
    def check_ui_issues(self):
        """Check for UI-related issues"""
        print("  🎨 Checking UI issues...")
        
        swift_files = list(self.project_path.rglob("*.swift"))
        
        for file_path in swift_files:
            if "DerivedData" in str(file_path) or "build" in str(file_path):
                continue
            
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                
                for i, line in enumerate(lines, 1):
                    # Check for hardcoded colors
                    if re.search(r'Color\.(red|blue|green|yellow)', line):
                        self.add_issue(Issue(
                            type="hardcoded_color",
                            severity="low",
                            file=str(file_path.relative_to(self.project_path)),
                            line=i,
                            description="Hardcoded color usage",
                            suggestion="Use semantic colors or asset catalog colors",
                            category="ui"
                        ))
                    
                    # Check for missing accessibility
                    if 'Button(' in line and 'accessibilityLabel' not in ''.join(lines[i:i+5]):
                        self.add_issue(Issue(
                            type="missing_accessibility",
                            severity="medium",
                            file=str(file_path.relative_to(self.project_path)),
                            line=i,
                            description="Button missing accessibility label",
                            suggestion="Add .accessibilityLabel() modifier",
                            category="accessibility"
                        ))
                        
            except Exception:
                continue
    
    def check_data_persistence(self):
        """Check data persistence implementation"""
        print("  💾 Checking data persistence...")
        
        swift_files = list(self.project_path.rglob("*.swift"))
        uses_userdefaults = False
        uses_coredata = False
        
        for file_path in swift_files:
            if "DerivedData" in str(file_path) or "build" in str(file_path):
                continue
            
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if 'UserDefaults' in content:
                    uses_userdefaults = True
                
                if 'CoreData' in content or 'NSManagedObject' in content:
                    uses_coredata = True
                    
            except Exception:
                continue
        
        if uses_userdefaults and not uses_coredata:
            self.add_issue(Issue(
                type="userdefaults_for_complex_data",
                severity="medium",
                file="Data Persistence",
                line=0,
                description="Using UserDefaults for complex data storage",
                suggestion="Consider Core Data or SQLite for complex data relationships",
                category="data_persistence"
            ))

def generate_report(issues: List[Issue], output_path: str):
    """Generate comprehensive issue report"""
    
    # Group issues by severity and category
    by_severity = {}
    by_category = {}
    
    for issue in issues:
        if issue.severity not in by_severity:
            by_severity[issue.severity] = []
        by_severity[issue.severity].append(issue)
        
        if issue.category not in by_category:
            by_category[issue.category] = []
        by_category[issue.category].append(issue)
    
    # Generate markdown report
    report = f"""# S-Quote Code Analysis Report

Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Summary

Total Issues Found: **{len(issues)}**

### By Severity
"""
    
    severity_order = ['critical', 'high', 'medium', 'low']
    for severity in severity_order:
        count = len(by_severity.get(severity, []))
        if count > 0:
            report += f"- **{severity.title()}**: {count} issues\n"
    
    report += "\n### By Category\n"
    for category, category_issues in sorted(by_category.items()):
        report += f"- **{category.replace('_', ' ').title()}**: {len(category_issues)} issues\n"
    
    report += "\n## Detailed Issues\n\n"
    
    # Group by severity for detailed listing
    for severity in severity_order:
        severity_issues = by_severity.get(severity, [])
        if not severity_issues:
            continue
            
        report += f"### {severity.title()} Priority Issues\n\n"
        
        for issue in severity_issues:
            report += f"#### {issue.type.replace('_', ' ').title()}\n"
            report += f"- **File**: `{issue.file}`\n"
            if issue.line > 0:
                report += f"- **Line**: {issue.line}\n"
            report += f"- **Category**: {issue.category.replace('_', ' ').title()}\n"
            report += f"- **Description**: {issue.description}\n"
            report += f"- **Suggestion**: {issue.suggestion}\n\n"
    
    # Add action items
    report += """## Recommended Actions

### Immediate (Critical/High Priority)
1. Fix all force unwrapping issues to prevent crashes
2. Address main thread blocking operations
3. Resolve build configuration problems

### Short Term (Medium Priority)
1. Add missing accessibility labels
2. Fix potential retain cycles
3. Update deployment targets
4. Improve error handling

### Long Term (Low Priority)
1. Add localization support
2. Improve code documentation
3. Optimize string operations
4. Consider Core Data migration

## Development Best Practices

### Code Quality
- Use optional binding instead of force unwrapping
- Add comprehensive error handling
- Write unit tests for critical functionality
- Use SwiftLint for consistent code style

### Performance
- Move heavy operations to background queues
- Use lazy loading for large data sets
- Optimize image and asset sizes
- Profile with Instruments regularly

### Accessibility
- Add accessibility labels to all interactive elements
- Test with VoiceOver enabled
- Ensure proper contrast ratios
- Support Dynamic Type

### Security
- Validate all user inputs
- Use secure storage for sensitive data
- Implement proper authentication
- Regular security audits

## Next Steps

1. **Prioritize Critical Issues**: Address all critical and high-priority issues first
2. **Set Up Continuous Integration**: Implement automated testing and analysis
3. **Code Review Process**: Establish peer review for all changes
4. **Documentation**: Improve inline documentation and user guides
5. **Testing**: Increase test coverage, especially for business logic

---

*This report was generated automatically. Review each issue carefully and test thoroughly after making changes.*
"""
    
    # Write report to file
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(report)
    
    # Also generate JSON for programmatic access
    json_data = {
        'generated_at': datetime.now().isoformat(),
        'total_issues': len(issues),
        'by_severity': {k: len(v) for k, v in by_severity.items()},
        'by_category': {k: len(v) for k, v in by_category.items()},
        'issues': [
            {
                'type': issue.type,
                'severity': issue.severity,
                'file': issue.file,
                'line': issue.line,
                'description': issue.description,
                'suggestion': issue.suggestion,
                'category': issue.category
            }
            for issue in issues
        ]
    }
    
    json_path = output_path.replace('.md', '.json')
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(json_data, f, indent=2)
    
    return report

def main():
    """Main execution function"""
    project_path = "."
    
    print("🚀 S-Quote Automated Issue Analysis")
    print("=" * 50)
    
    analyzer = CodeAnalyzer(project_path)
    issues = analyzer.analyze()
    
    print(f"\n📊 Analysis Complete!")
    print(f"Found {len(issues)} potential issues")
    
    # Generate report
    report_path = "ANALYSIS_REPORT.md"
    generate_report(issues, report_path)
    
    print(f"📄 Detailed report saved to: {report_path}")
    print(f"📄 JSON data saved to: ANALYSIS_REPORT.json")
    
    # Print summary
    by_severity = {}
    for issue in issues:
        if issue.severity not in by_severity:
            by_severity[issue.severity] = 0
        by_severity[issue.severity] += 1
    
    print("\n📈 Issue Summary:")
    for severity in ['critical', 'high', 'medium', 'low']:
        count = by_severity.get(severity, 0)
        if count > 0:
            print(f"  {severity.title()}: {count}")
    
    print("\n🎯 Next Steps:")
    print("1. Review ANALYSIS_REPORT.md for detailed findings")
    print("2. Address critical and high-priority issues first")
    print("3. Run this analysis regularly during development")
    print("4. Consider integrating into CI/CD pipeline")

if __name__ == "__main__":
    main()