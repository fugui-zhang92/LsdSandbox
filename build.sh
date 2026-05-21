#!/bin/bash
# ============================================================
# LsdSandbox IPA Build Script
# ============================================================
# This script builds the LsdSandbox IPA from the Xcode project.
#
# Usage:
#   chmod +x build.sh
#   ./build.sh
#
# Prerequisites:
#   - macOS with Xcode installed (15.0+)
#   - Apple Developer account (for code signing)
#   - libxpf.dylib and libchoma.dylib in the Frameworks/ folder
# ============================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="LsdSandbox"
SCHEME="LsdSandbox"
CONFIGURATION="Release"
ARCHIVE_PATH="${PROJECT_DIR}/build/${PROJECT_NAME}.xcarchive"
IPA_PATH="${PROJECT_DIR}/build/${PROJECT_NAME}.ipa"

echo "=========================================="
echo " LsdSandbox IPA Builder"
echo "=========================================="
echo "Project: ${PROJECT_DIR}"
echo ""

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "ERROR: xcodebuild not found. Install Xcode first."
    exit 1
fi

# Check for required frameworks
if [ ! -f "${PROJECT_DIR}/Frameworks/libxpf.dylib" ]; then
    echo "WARNING: libxpf.dylib not found in Frameworks/"
fi
if [ ! -f "${PROJECT_DIR}/Frameworks/libchoma.dylib" ]; then
    echo "WARNING: libchoma.dylib not found in Frameworks/"
fi

# Clean previous builds
echo "Cleaning..."
rm -rf "${PROJECT_DIR}/build"

# Build the archive
echo ""
echo "Building ${CONFIGURATION} configuration..."
echo ""

xcodebuild archive \
    -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -archivePath "${ARCHIVE_PATH}" \
    -destination "generic/platform=iOS" \
    CODE_SIGN_IDENTITY="Apple Development" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="" \
    2>&1 | grep -E '(error:|warning:|BUILD|^$)' || true

BUILD_RESULT=${PIPESTATUS[0]}

if [ ${BUILD_RESULT} -ne 0 ]; then
    echo ""
    echo "=========================================="
    echo " BUILD FAILED"
    echo "=========================================="
    echo ""
    echo "If the build failed, try building in Xcode directly:"
    echo "  1. Open ${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj"
    echo "  2. Select the LsdSandbox scheme"
    echo "  3. Choose Product > Archive"
    echo "  4. From the Organizer, Distribute App > Development"
    exit 1
fi

# Create IPA from archive
echo ""
echo "Creating IPA..."

mkdir -p "${PROJECT_DIR}/build/Payload"
cp -R "${ARCHIVE_PATH}/Products/Applications/${PROJECT_NAME}.app" \
    "${PROJECT_DIR}/build/Payload/"

cd "${PROJECT_DIR}/build"
zip -qr "${IPA_PATH}" Payload/

# Also create a .tar version for easy extraction
# cp -R Payload "${PROJECT_NAME}"
# tar -czf "${PROJECT_NAME}.tar.gz" Payload/

echo ""
echo "=========================================="
echo " BUILD SUCCESSFUL"
echo "=========================================="
echo ""
echo "IPA created at:"
echo "  ${IPA_PATH}"
echo ""
echo "To install on device:"
echo "  1. Transfer IPA to device (e.g. via AirDrop or file manager)"
echo "  2. Install with TrollStore or other sideloading tool"
echo ""