#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="xcash-cakewallet-builder"
CONTAINER_NAME="xcash-cakewallet-build"

echo "=== XCash CakeWallet Docker Build ==="
echo "Project directory: $PROJECT_DIR"
echo "Using 8 cores for compilation"
echo ""

# Build Docker image
echo "=== Building Docker image ==="
docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"

# Remove old container if exists
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Run build in container
echo ""
echo "=== Starting build container ==="
docker run -it \
    --name "$CONTAINER_NAME" \
    -v "$PROJECT_DIR:/opt/android/cake_wallet" \
    -e THREADS=8 \
    "$IMAGE_NAME" \
    /opt/android/cake_wallet/docker/build_apk.sh

# Copy APK from container output
echo ""
echo "=== Build complete ==="
echo "APK location: $PROJECT_DIR/build/app/outputs/flutter-apk/"
ls -la "$PROJECT_DIR/build/app/outputs/flutter-apk/" 2>/dev/null || echo "Check container for output location"
