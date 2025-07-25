#!/bin/bash

# S-Quote Build Script for macOS
# This script automates the build process for the Event Planner Quotation Generator

set -e  # Exit on any error

# Configuration
PROJECT_NAME="S Quote"
SCHEME_NAME="S-Quote"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/S-Quote.xcarchive"
EXPORT_PATH="./build/export"
BUILD_DIR="./build"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Xcode is installed
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode command line tools not found. Please install Xcode."
        exit 1
    fi
    
    # Check macOS version
    macos_version=$(sw_vers -productVersion)
    print_status "macOS version: $macos_version"
    
    # Check Xcode version
    xcode_version=$(xcodebuild -version | head -n 1)
    print_status "$xcode_version"
    
    print_success "Prerequisites check completed"
}

# Function to clean build directory
clean_build() {
    print_status "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    print_success "Build directory cleaned"
}

# Function to build the project
build_project() {
    print_status "Building project..."
    
    # Build for Release configuration
    xcodebuild -project "$PROJECT_NAME.xcodeproj" \
               -scheme "$SCHEME_NAME" \
               -configuration "$CONFIGURATION" \
               -derivedDataPath "$BUILD_DIR/DerivedData" \
               clean build
    
    print_success "Project built successfully"
}

# Function to archive the project
archive_project() {
    print_status "Archiving project..."
    
    xcodebuild -project "$PROJECT_NAME.xcodeproj" \
               -scheme "$SCHEME_NAME" \
               -configuration "$CONFIGURATION" \
               -archivePath "$ARCHIVE_PATH" \
               archive
    
    print_success "Project archived successfully"
}

# Function to export the app
export_app() {
    print_status "Exporting app..."
    
    # Create export options plist
    cat > "$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF
    
    xcodebuild -exportArchive \
               -archivePath "$ARCHIVE_PATH" \
               -exportPath "$EXPORT_PATH" \
               -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"
    
    print_success "App exported successfully"
}

# Function to create DMG
create_dmg() {
    print_status "Creating DMG..."
    
    APP_NAME="S-Quote.app"
    DMG_NAME="S-Quote-Installer.dmg"
    DMG_PATH="$BUILD_DIR/$DMG_NAME"
    
    if [ -d "$EXPORT_PATH/$APP_NAME" ]; then
        # Create temporary DMG directory
        DMG_DIR="$BUILD_DIR/dmg"
        mkdir -p "$DMG_DIR"
        
        # Copy app to DMG directory
        cp -R "$EXPORT_PATH/$APP_NAME" "$DMG_DIR/"
        
        # Create Applications symlink
        ln -s /Applications "$DMG_DIR/Applications"
        
        # Create DMG
        hdiutil create -volname "S-Quote" \
                      -srcfolder "$DMG_DIR" \
                      -ov -format UDZO \
                      "$DMG_PATH"
        
        print_success "DMG created: $DMG_PATH"
    else
        print_warning "App not found, skipping DMG creation"
    fi
}

# Function to run tests
run_tests() {
    print_status "Running tests..."
    
    xcodebuild test \
               -project "$PROJECT_NAME.xcodeproj" \
               -scheme "$SCHEME_NAME" \
               -destination 'platform=macOS'
    
    print_success "Tests completed"
}

# Function to upload to S3 (if configured)
upload_to_s3() {
    if [ -n "$AWS_S3_BUCKET" ] && [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
        print_status "Uploading to S3..."
        
        # Check if AWS CLI is installed
        if command -v aws &> /dev/null; then
            DMG_PATH="$BUILD_DIR/S-Quote-Installer.dmg"
            if [ -f "$DMG_PATH" ]; then
                aws s3 cp "$DMG_PATH" "s3://$AWS_S3_BUCKET/releases/" --region us-east-1
                print_success "Uploaded to S3: s3://$AWS_S3_BUCKET/releases/S-Quote-Installer.dmg"
            else
                print_warning "DMG file not found, skipping S3 upload"
            fi
        else
            print_warning "AWS CLI not installed, skipping S3 upload"
        fi
    else
        print_warning "S3 credentials not configured, skipping upload"
    fi
}

# Function to show build summary
show_summary() {
    print_status "Build Summary:"
    echo "=================================="
    echo "Project: $PROJECT_NAME"
    echo "Configuration: $CONFIGURATION"
    echo "Archive: $ARCHIVE_PATH"
    echo "Export: $EXPORT_PATH"
    
    if [ -f "$BUILD_DIR/S-Quote-Installer.dmg" ]; then
        echo "DMG: $BUILD_DIR/S-Quote-Installer.dmg"
        echo "DMG Size: $(du -h "$BUILD_DIR/S-Quote-Installer.dmg" | cut -f1)"
    fi
    
    echo "=================================="
    print_success "Build completed successfully!"
}

# Main execution
main() {
    print_status "Starting S-Quote build process..."
    
    # Parse command line arguments
    SKIP_TESTS=false
    SKIP_ARCHIVE=false
    UPLOAD_S3=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --skip-archive)
                SKIP_ARCHIVE=true
                shift
                ;;
            --upload-s3)
                UPLOAD_S3=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --skip-tests     Skip running tests"
                echo "  --skip-archive   Skip archiving and exporting"
                echo "  --upload-s3      Upload to S3 (requires AWS credentials)"
                echo "  --help           Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Execute build steps
    check_prerequisites
    clean_build
    
    if [ "$SKIP_TESTS" = false ]; then
        run_tests
    fi
    
    build_project
    
    if [ "$SKIP_ARCHIVE" = false ]; then
        archive_project
        export_app
        create_dmg
    fi
    
    if [ "$UPLOAD_S3" = true ]; then
        upload_to_s3
    fi
    
    show_summary
}

# Run main function with all arguments
main "$@"