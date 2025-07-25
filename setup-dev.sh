#!/bin/bash

# S-Quote Development Setup Script
# This script sets up the development environment and identifies potential issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check system requirements
check_system_requirements() {
    print_status "Checking system requirements..."
    
    # Check macOS version
    macos_version=$(sw_vers -productVersion)
    required_version="15.5"
    
    if [[ "$(printf '%s\n' "$required_version" "$macos_version" | sort -V | head -n1)" = "$required_version" ]]; then
        print_success "macOS version: $macos_version (✓ >= $required_version)"
    else
        print_error "macOS version: $macos_version (✗ < $required_version required)"
        return 1
    fi
    
    # Check architecture
    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        print_success "Architecture: Apple Silicon ($arch)"
    else
        print_warning "Architecture: Intel ($arch) - Apple Silicon recommended"
    fi
    
    # Check memory
    memory_gb=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    if [[ $memory_gb -ge 16 ]]; then
        print_success "Memory: ${memory_gb}GB (✓ >= 16GB)"
    else
        print_warning "Memory: ${memory_gb}GB (⚠ 16GB recommended)"
    fi
}

# Function to check Xcode installation
check_xcode() {
    print_status "Checking Xcode installation..."
    
    # Check if Xcode is installed
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode command line tools not found"
        print_status "Installing Xcode command line tools..."
        xcode-select --install
        print_warning "Please complete Xcode installation and run this script again"
        return 1
    fi
    
    # Check Xcode version
    xcode_version=$(xcodebuild -version | head -n 1 | awk '{print $2}')
    required_xcode="16.4"
    
    if [[ "$(printf '%s\n' "$required_xcode" "$xcode_version" | sort -V | head -n1)" = "$required_xcode" ]]; then
        print_success "Xcode version: $xcode_version (✓ >= $required_xcode)"
    else
        print_error "Xcode version: $xcode_version (✗ < $required_xcode required)"
        print_status "Please update Xcode from the App Store"
        return 1
    fi
    
    # Check if Xcode license is accepted
    if ! xcodebuild -checkFirstLaunchStatus &> /dev/null; then
        print_warning "Xcode license not accepted"
        print_status "Accepting Xcode license..."
        sudo xcodebuild -license accept
    fi
    
    print_success "Xcode setup complete"
}

# Function to validate project structure
validate_project() {
    print_status "Validating project structure..."
    
    # Check if we're in the right directory
    if [[ ! -f "S Quote.xcodeproj/project.pbxproj" ]]; then
        print_error "S Quote.xcodeproj not found. Are you in the correct directory?"
        return 1
    fi
    
    # Check essential files
    essential_files=(
        "S Quote/S_QuoteApp.swift"
        "S Quote/ContentView.swift"
        "S Quote/Models/Event.swift"
        "S Quote/Models/Quote.swift"
        "S Quote/Models/QuoteItem.swift"
        "S Quote/Services/QuoteService.swift"
        "S Quote/ViewModels/QuoteViewModel.swift"
        "S Quote/Views/NewQuoteView.swift"
        "S Quote/Views/QuoteDetailView.swift"
    )
    
    missing_files=()
    for file in "${essential_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        print_success "All essential files present"
    else
        print_error "Missing essential files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi
}

# Function to check project configuration
check_project_config() {
    print_status "Checking project configuration..."
    
    # List available schemes
    schemes=$(xcodebuild -list -project "S Quote.xcodeproj" 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | head -n -1 | xargs)
    
    if [[ "$schemes" == *"S-Quote"* ]]; then
        print_success "S-Quote scheme found"
    else
        print_warning "S-Quote scheme not found. Available schemes: $schemes"
        print_status "You may need to create or rename the scheme in Xcode"
    fi
    
    # Check build settings
    bundle_id=$(xcodebuild -showBuildSettings -project "S Quote.xcodeproj" -target "S Quote" 2>/dev/null | grep PRODUCT_BUNDLE_IDENTIFIER | awk '{print $3}')
    
    if [[ -n "$bundle_id" ]]; then
        print_success "Bundle identifier: $bundle_id"
    else
        print_warning "Could not determine bundle identifier"
    fi
}

# Function to run initial build test
test_build() {
    print_status "Testing initial build..."
    
    # Clean build
    xcodebuild clean -project "S Quote.xcodeproj" -scheme "S-Quote" &> /dev/null || {
        print_warning "Could not clean with S-Quote scheme, trying S Quote scheme..."
        xcodebuild clean -project "S Quote.xcodeproj" -scheme "S Quote" &> /dev/null || {
            print_error "Could not clean project"
            return 1
        }
    }
    
    # Test build
    print_status "Building project (this may take a few minutes)..."
    if xcodebuild build -project "S Quote.xcodeproj" -scheme "S-Quote" -configuration Debug &> build.log; then
        print_success "Build successful"
        rm -f build.log
    elif xcodebuild build -project "S Quote.xcodeproj" -scheme "S Quote" -configuration Debug &> build.log; then
        print_success "Build successful"
        rm -f build.log
    else
        print_error "Build failed. Check build.log for details"
        print_status "Common build issues:"
        echo "  - Missing scheme (create S-Quote scheme in Xcode)"
        echo "  - Code signing issues (check Developer account)"
        echo "  - Missing dependencies (check project settings)"
        return 1
    fi
}

# Function to setup git hooks
setup_git_hooks() {
    print_status "Setting up git hooks..."
    
    if [[ ! -d ".git" ]]; then
        print_warning "Not a git repository, skipping git hooks"
        return 0
    fi
    
    # Create pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for S-Quote

echo "Running pre-commit checks..."

# Check for Swift syntax errors
if command -v swiftlint &> /dev/null; then
    swiftlint
fi

# Run quick build test
if ! xcodebuild build -project "S Quote.xcodeproj" -scheme "S-Quote" -configuration Debug -quiet; then
    echo "Build failed, commit aborted"
    exit 1
fi

echo "Pre-commit checks passed"
EOF
    
    chmod +x .git/hooks/pre-commit
    print_success "Git hooks configured"
}

# Function to create development documentation
create_dev_docs() {
    print_status "Creating development documentation..."
    
    mkdir -p docs
    
    # Create development guide
    cat > docs/DEVELOPMENT.md << 'EOF'
# Development Guide

## Quick Start

1. Open `S Quote.xcodeproj` in Xcode
2. Select the S-Quote scheme
3. Choose your target device (Mac)
4. Press Cmd+R to build and run

## Project Structure

- `Models/`: Data models (Event, Quote, QuoteItem)
- `Views/`: SwiftUI views
- `ViewModels/`: MVVM view models
- `Services/`: Business logic and data management

## Common Tasks

### Adding New Service Items
1. Update `ItemCategory` enum
2. Add items to `createDefaultItems()` in QuoteService
3. Test with new quote creation

### Modifying UI
1. Edit SwiftUI views in `Views/` folder
2. Use Xcode previews for rapid iteration
3. Test on different screen sizes

### Debugging
- Use Xcode debugger and breakpoints
- Check console for print statements
- Use Instruments for performance profiling

## Testing

- Unit tests: `S QuoteTests/`
- UI tests: `S QuoteUITests/`
- Run tests with Cmd+U in Xcode

## Build Issues

### Common Problems
1. **Scheme not found**: Create S-Quote scheme in Xcode
2. **Code signing**: Check Apple Developer account
3. **Build errors**: Clean build folder (Cmd+Shift+K)

### Getting Help
- Check build.log for detailed errors
- Use Xcode's Issue Navigator
- Search Apple Developer documentation
EOF
    
    print_success "Development documentation created in docs/"
}

# Function to identify and log issues
identify_issues() {
    print_status "Identifying potential issues..."
    
    issues=()
    
    # Check for common issues
    if [[ ! -f "S Quote/Assets.xcassets/AppIcon.appiconset/Contents.json" ]]; then
        issues+=("Missing app icon configuration")
    fi
    
    if [[ ! -f ".gitignore" ]]; then
        issues+=("Missing .gitignore file")
    fi
    
    # Check for SwiftLint
    if ! command -v swiftlint &> /dev/null; then
        issues+=("SwiftLint not installed (recommended for code quality)")
    fi
    
    # Check for large files
    large_files=$(find . -type f -size +10M 2>/dev/null | grep -v ".git" | head -5)
    if [[ -n "$large_files" ]]; then
        issues+=("Large files found (may affect repository size)")
    fi
    
    # Log issues
    if [[ ${#issues[@]} -gt 0 ]]; then
        print_warning "Potential issues identified:"
        for issue in "${issues[@]}"; do
            echo "  ⚠ $issue"
        done
        
        # Create issues log
        cat > ISSUES.md << EOF
# Development Issues Log

Generated on: $(date)

## Identified Issues

EOF
        for issue in "${issues[@]}"; do
            echo "- [ ] $issue" >> ISSUES.md
        done
        
        cat >> ISSUES.md << EOF

## Resolution Steps

### Missing App Icon
1. Open Xcode
2. Navigate to Assets.xcassets
3. Add AppIcon set with required sizes

### Missing .gitignore
1. Create .gitignore file
2. Add standard Xcode ignores
3. Commit to repository

### Install SwiftLint
\`\`\`bash
brew install swiftlint
\`\`\`

### Large Files
1. Identify unnecessary large files
2. Use Git LFS for required large assets
3. Remove or optimize files

## Next Steps

1. Address high-priority issues
2. Test build after each fix
3. Update this document as issues are resolved
EOF
        
        print_status "Issues logged to ISSUES.md"
    else
        print_success "No major issues identified"
    fi
}

# Function to create .gitignore if missing
create_gitignore() {
    if [[ ! -f ".gitignore" ]]; then
        print_status "Creating .gitignore file..."
        
        cat > .gitignore << 'EOF'
# Xcode
*.xcodeproj/*
!*.xcodeproj/project.pbxproj
!*.xcodeproj/xcshareddata/
!*.xcodeproj/project.xcworkspace/
*.xcworkspace/*
!*.xcworkspace/contents.xcworkspacedata
!*.xcworkspace/xcshareddata/

# Build
build/
DerivedData/
*.ipa
*.dSYM.zip
*.dSYM

# CocoaPods
Pods/
*.xcworkspace

# Carthage
Carthage/Build/

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Code Injection
iOSInjectionProject/

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk

# Swift Package Manager
.swiftpm/
Package.resolved

# Logs
*.log
build.log

# Temporary files
*.tmp
*.temp
EOF
        
        print_success ".gitignore created"
    fi
}

# Main execution
main() {
    echo "=================================================="
    echo "    S-Quote Development Environment Setup"
    echo "=================================================="
    echo
    
    # Run all checks
    check_system_requirements || exit 1
    check_xcode || exit 1
    validate_project || exit 1
    check_project_config
    create_gitignore
    test_build || exit 1
    setup_git_hooks
    create_dev_docs
    identify_issues
    
    echo
    echo "=================================================="
    print_success "Development environment setup complete!"
    echo "=================================================="
    echo
    print_status "Next steps:"
    echo "1. Open 'S Quote.xcodeproj' in Xcode"
    echo "2. Select the S-Quote scheme"
    echo "3. Build and run with Cmd+R"
    echo "4. Review ISSUES.md for any identified issues"
    echo "5. Check docs/DEVELOPMENT.md for development guide"
    echo
    print_status "Build automation:"
    echo "- Run './build.sh' for automated builds"
    echo "- Use GitHub Actions for CI/CD"
    echo "- Check README.md for detailed instructions"
    echo
}

# Run main function
main "$@"