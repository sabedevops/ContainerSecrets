#!/bin/sh

set -o nounset
set -o errexit

# Colors for output
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() { printf '%b[INFO]%b %s\n' "$BLUE" "$NC" "$1"; }
log_error() { printf '%b[ERROR]%b %s\n' "$RED" "$NC" "$1" >&2; }

if [ "$#" -ne 1 ]; then
    log_error "Usage: $0 <driver_name> (e.g., skate.sh)"
    exit 1
fi

DRIVER_NAME="$1"

# Find git root
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$GIT_ROOT"

# Ensure DRIVER_NAME has .sh extension for file lookups
case "$DRIVER_NAME" in
    *.sh) ;;
    *) DRIVER_NAME="$DRIVER_NAME.sh" ;;
esac

DRIVER_PATH="drivers/$DRIVER_NAME"
CONTAINERFILE_PATH="tests/drivers/$DRIVER_NAME.Containerfile"
IMAGE_TAG="test-$(printf '%s' "$DRIVER_NAME" | sed 's/\.sh$//' | sed 's/[^a-zA-Z0-9]/-/g')"

if [ ! -f "$DRIVER_PATH" ]; then
    log_error "Driver script '$DRIVER_PATH' not found."
    exit 1
fi

if [ ! -f "$CONTAINERFILE_PATH" ]; then
    log_error "Containerfile '$CONTAINERFILE_PATH' not found."
    exit 1
fi

log_info "Building test environment for $DRIVER_NAME..."
podman build -f "$CONTAINERFILE_PATH" -t "$IMAGE_TAG" .

log_info "Running tests for $DRIVER_NAME inside container..."
podman run --rm \
    -v "$GIT_ROOT:/workspace:z" \
    "$IMAGE_TAG" sh /workspace/tests/test_driver.sh "/workspace/$DRIVER_PATH"

log_info "Tests completed successfully for $DRIVER_NAME!"
