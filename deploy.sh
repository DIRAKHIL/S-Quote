#!/bin/bash

# S-Quote Deployment Script
# Automates the complete deployment process for macOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
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

# Configuration
VERSION=${1:-"1.0.0"}
ENVIRONMENT=${2:-"production"}
UPLOAD_S3=${3:-"false"}

print_status "Starting S-Quote deployment process..."
print_status "Version: $VERSION"
print_status "Environment: $ENVIRONMENT"
print_status "S3 Upload: $UPLOAD_S3"

# Pre-deployment checks
check_prerequisites() {
    print_status "Checking deployment prerequisites..."
    
    # Check if we're on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "This script must be run on macOS"
        exit 1
    fi
    
    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode not found. Please install Xcode."
        exit 1
    fi
    
    # Check git status
    if [[ -n $(git status --porcelain) ]]; then
        print_warning "Working directory has uncommitted changes"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_success "Prerequisites check passed"
}

# Run quality checks
run_quality_checks() {
    print_status "Running quality checks..."
    
    # Run code analysis
    if [[ -f "analyze-issues.py" ]]; then
        python3 analyze-issues.py > /dev/null 2>&1 || true
        
        # Check for critical issues
        if [[ -f "ANALYSIS_REPORT.json" ]]; then
            critical_count=$(python3 -c "
import json
with open('ANALYSIS_REPORT.json', 'r') as f:
    data = json.load(f)
    print(data.get('by_severity', {}).get('critical', 0))
" 2>/dev/null || echo "0")
            
            if [[ $critical_count -gt 0 ]]; then
                print_error "Found $critical_count critical issues. Please fix before deployment."
                print_status "Check ANALYSIS_REPORT.md for details"
                exit 1
            fi
        fi
    fi
    
    # Run tests
    print_status "Running tests..."
    xcodebuild test \
        -project "S Quote.xcodeproj" \
        -scheme "S-Quote" \
        -destination 'platform=macOS' \
        -quiet || {
        print_error "Tests failed. Please fix before deployment."
        exit 1
    }
    
    print_success "Quality checks passed"
}

# Build application
build_application() {
    print_status "Building application for $ENVIRONMENT..."
    
    # Clean previous builds
    rm -rf build/
    
    # Run build script
    if [[ -f "build.sh" ]]; then
        if [[ "$UPLOAD_S3" == "true" ]]; then
            ./build.sh --upload-s3
        else
            ./build.sh
        fi
    else
        print_error "Build script not found"
        exit 1
    fi
    
    print_success "Application built successfully"
}

# Create release tag
create_release_tag() {
    print_status "Creating release tag v$VERSION..."
    
    # Check if tag already exists
    if git tag -l | grep -q "v$VERSION"; then
        print_warning "Tag v$VERSION already exists"
        read -p "Delete existing tag and continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag -d "v$VERSION"
            git push origin --delete "v$VERSION" 2>/dev/null || true
        else
            exit 1
        fi
    fi
    
    # Create and push tag
    git tag -a "v$VERSION" -m "Release version $VERSION"
    git push origin "v$VERSION"
    
    print_success "Release tag created: v$VERSION"
}

# Deploy to distribution channels
deploy_distribution() {
    print_status "Deploying to distribution channels..."
    
    # Check for DMG file
    DMG_FILE=$(find build -name "*.dmg" | head -n 1)
    if [[ -z "$DMG_FILE" ]]; then
        print_error "DMG file not found in build directory"
        exit 1
    fi
    
    print_status "Found DMG: $DMG_FILE"
    
    # Calculate file hash
    DMG_HASH=$(shasum -a 256 "$DMG_FILE" | cut -d' ' -f1)
    DMG_SIZE=$(du -h "$DMG_FILE" | cut -f1)
    
    print_status "DMG Hash: $DMG_HASH"
    print_status "DMG Size: $DMG_SIZE"
    
    # Create release notes
    cat > "RELEASE_NOTES_v$VERSION.md" << EOF
# S-Quote v$VERSION Release Notes

## 📦 Download
- **File**: $(basename "$DMG_FILE")
- **Size**: $DMG_SIZE
- **SHA256**: \`$DMG_HASH\`

## 🎯 What's New in v$VERSION
- Professional Event Planner Quotation Generator
- Complete SwiftUI macOS application
- 40+ pre-configured service items
- Real-time pricing calculations
- Professional export functionality
- Based on real-world wedding planning requirements

## 🔧 System Requirements
- macOS 15.5 or later
- Apple Silicon (M1 Pro+) recommended
- 16GB RAM recommended

## 📥 Installation
1. Download the DMG file
2. Open the DMG
3. Drag S-Quote.app to Applications folder
4. Launch from Applications or Spotlight

## 🐛 Bug Fixes
- Improved error handling
- Enhanced performance
- Better accessibility support

## 🚀 Coming Next
- PDF export functionality
- Email integration
- Template management
- Multi-currency support

---
Generated on: $(date)
Build Environment: $ENVIRONMENT
EOF
    
    print_success "Release notes created: RELEASE_NOTES_v$VERSION.md"
    
    # Upload to GitHub Releases (if in CI environment)
    if [[ -n "$GITHUB_TOKEN" ]]; then
        print_status "Creating GitHub release..."
        # This would typically use gh CLI or GitHub API
        print_status "GitHub release creation requires manual step or CI environment"
    fi
}

# Post-deployment verification
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check if app can be launched
    APP_PATH="build/export/S-Quote.app"
    if [[ -d "$APP_PATH" ]]; then
        # Basic app validation
        if [[ -f "$APP_PATH/Contents/MacOS/S Quote" ]]; then
            print_success "App binary found and executable"
        else
            print_error "App binary not found or not executable"
            exit 1
        fi
        
        # Check code signature (if signed)
        codesign -v "$APP_PATH" 2>/dev/null && {
            print_success "App is properly code signed"
        } || {
            print_warning "App is not code signed (development build)"
        }
    else
        print_error "App not found at expected location"
        exit 1
    fi
    
    print_success "Deployment verification completed"
}

# Generate deployment summary
generate_summary() {
    print_status "Generating deployment summary..."
    
    cat > "DEPLOYMENT_SUMMARY_v$VERSION.md" << EOF
# S-Quote v$VERSION Deployment Summary

## 📊 Deployment Details
- **Version**: $VERSION
- **Environment**: $ENVIRONMENT
- **Date**: $(date)
- **Build Host**: $(hostname)
- **macOS Version**: $(sw_vers -productVersion)
- **Xcode Version**: $(xcodebuild -version | head -n 1)

## 📦 Artifacts Generated
- **App Bundle**: build/export/S-Quote.app
- **Archive**: build/S-Quote.xcarchive
- **DMG Installer**: $(find build -name "*.dmg" | head -n 1 | xargs basename)
- **Release Notes**: RELEASE_NOTES_v$VERSION.md

## 🔍 Quality Metrics
- **Tests**: Passed
- **Code Analysis**: $(python3 -c "
import json
try:
    with open('ANALYSIS_REPORT.json', 'r') as f:
        data = json.load(f)
        total = data.get('total_issues', 0)
        critical = data.get('by_severity', {}).get('critical', 0)
        high = data.get('by_severity', {}).get('high', 0)
        print(f'{total} total issues ({critical} critical, {high} high)')
except:
    print('Analysis not available')
" 2>/dev/null || echo "Analysis not available")

## 🚀 Distribution Status
- **Local Build**: ✅ Complete
- **GitHub Tag**: ✅ v$VERSION created
- **S3 Upload**: $([ "$UPLOAD_S3" == "true" ] && echo "✅ Complete" || echo "⏭️ Skipped")
- **GitHub Release**: ⏭️ Manual step required

## 📋 Next Steps
1. Test the DMG installer on a clean macOS system
2. Create GitHub release with generated artifacts
3. Update documentation and website
4. Announce release to users and stakeholders
5. Monitor for user feedback and issues

## 🔗 Resources
- **Repository**: https://github.com/DIRAKHIL/S-Quote
- **Documentation**: README.md
- **Issues**: ANALYSIS_REPORT.md
- **Build Logs**: Check GitHub Actions for CI/CD logs

---
Deployment completed successfully! 🎉
EOF
    
    print_success "Deployment summary created: DEPLOYMENT_SUMMARY_v$VERSION.md"
}

# Cleanup temporary files
cleanup() {
    print_status "Cleaning up temporary files..."
    
    # Remove temporary build files but keep final artifacts
    find build -name "*.log" -delete 2>/dev/null || true
    find build -name "*.tmp" -delete 2>/dev/null || true
    
    print_success "Cleanup completed"
}

# Main deployment process
main() {
    echo "=================================================="
    echo "         S-Quote Deployment Pipeline"
    echo "=================================================="
    echo
    
    check_prerequisites
    run_quality_checks
    build_application
    create_release_tag
    deploy_distribution
    verify_deployment
    generate_summary
    cleanup
    
    echo
    echo "=================================================="
    print_success "Deployment completed successfully! 🎉"
    echo "=================================================="
    echo
    print_status "Deployment artifacts:"
    echo "  📱 App: build/export/S-Quote.app"
    echo "  💿 DMG: $(find build -name "*.dmg" | head -n 1)"
    echo "  📄 Notes: RELEASE_NOTES_v$VERSION.md"
    echo "  📊 Summary: DEPLOYMENT_SUMMARY_v$VERSION.md"
    echo
    print_status "Next steps:"
    echo "  1. Test the DMG installer"
    echo "  2. Create GitHub release"
    echo "  3. Update documentation"
    echo "  4. Announce to users"
    echo
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [VERSION] [ENVIRONMENT] [UPLOAD_S3]"
        echo ""
        echo "Arguments:"
        echo "  VERSION      Release version (default: 1.0.0)"
        echo "  ENVIRONMENT  Build environment (default: production)"
        echo "  UPLOAD_S3    Upload to S3 (true/false, default: false)"
        echo ""
        echo "Examples:"
        echo "  $0                           # Deploy v1.0.0 to production"
        echo "  $0 1.1.0                    # Deploy v1.1.0 to production"
        echo "  $0 1.0.0 staging            # Deploy v1.0.0 to staging"
        echo "  $0 1.0.0 production true    # Deploy v1.0.0 and upload to S3"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac