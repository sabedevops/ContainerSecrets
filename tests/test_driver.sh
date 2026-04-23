#!/bin/sh

set -o nounset
set -o errexit

# Colors
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ "$#" -ne 1 ]; then
    printf '%bUsage: %s <driver_script>%b\n' "$RED" "$0" "$NC" >&2
    exit 1
fi

# Canonicalize driver path so it can be called accurately from anywhere
DRIVER_DIR=$(cd "$(dirname "$1")" && pwd)
DRIVER_NAME=$(basename "$1")
DRIVER="$DRIVER_DIR/$DRIVER_NAME"

if [ ! -f "$DRIVER" ]; then
    printf '%bError: Driver script '\''%s'\'' not found.%b\n' "$RED" "$DRIVER" "$NC" >&2
    exit 1
fi

if [ ! -x "$DRIVER" ]; then
    printf '%bError: Driver script '\''%s'\'' is not executable.%b\n' "$RED" "$DRIVER" "$NC" >&2
    exit 1
fi

# Temp file for capturing driver stderr
DRIVER_ERR=$(mktemp)

log_info() { printf '%b[INFO]%b %b\n' "$BLUE" "$NC" "$1"; }
log_warn() { printf '%b[WARN]%b ⚠️  %b\n' "$YELLOW" "$NC" "$1"; }
log_task() { printf '%b[INFO]%b %b... ' "$BLUE" "$NC" "$1"; }
log_error() {
    # Ensure we start on a new line if we were mid-task
    printf '\n%b[ERROR]%b %b\n' "$RED" "$NC" "$1" >&2
}
log_pass() { printf '%bok ✅%b\n' "$GREEN" "$NC"; }
log_divider() {
    cols=$(tput cols 2>/dev/null || echo 80)
    printf '%b' "$CYAN"
    awk -v c="$cols" 'BEGIN { for(i=0;i<c;i++) printf "-" }'
    printf '%b\n' "$NC"
}

cleanup() {
    EXIT_CODE=$?
    if [ -n "${SECRET_ID:-}" ]; then
        printf '\n' # Ensure we start on a new line
        log_warn "Cleaning up secret '$SECRET_ID'"
        "$DRIVER" delete >/dev/null 2>&1 || true
    fi
    rm -f "$DRIVER_ERR"
    if [ "$EXIT_CODE" -ne 0 ]; then
        printf '\n%b❌ Tests failed! (╯°□°)╯︵ ┻━┻%b\n' "$RED" "$NC"
    fi
}
trap cleanup EXIT

# --- Test Functions ---

test_store() {
    id="$1"
    value="$2"
    log_task "Storing secret '$id'"
    if ! printf "%s" "$value" | "$DRIVER" store 2>"$DRIVER_ERR"; then
        err_msg=$(cat "$DRIVER_ERR")
        log_error "Store failed: $err_msg"
        exit 1
    fi
    log_pass
}

test_list() {
    id="$1"
    log_task "Listing secrets"
    if ! "$DRIVER" list 2>"$DRIVER_ERR" | grep -q "^$id$"; then
        ERR_MSG=$(cat "$DRIVER_ERR")
        if [ -n "$ERR_MSG" ]; then
            log_error "List failed: $ERR_MSG"
        else
            log_error "Secret '$id' not found in list"
        fi
        exit 1
    fi
    log_pass
}

test_lookup() {
    id="$1"
    expected="$2"
    log_task "Looking up secret '$id'"
    if ! actual=$("$DRIVER" lookup 2>"$DRIVER_ERR"); then
        err_msg=$(cat "$DRIVER_ERR")
        log_error "Lookup failed: $err_msg"
        exit 1
    fi
    if [ "$actual" != "$expected" ]; then
        log_error "Value mismatch"
        printf "Expected (hex): "
        printf "%s" "$expected" | od -An -tx1
        printf "Actual   (hex): "
        printf "%s" "$actual" | od -An -tx1
        exit 1
    fi
    log_pass
}

test_delete() {
    id="$1"
    log_task "Deleting secret '$id'"
    if ! "$DRIVER" delete 2>"$DRIVER_ERR"; then
        err_msg=$(cat "$DRIVER_ERR")
        log_error "Delete failed: $err_msg"
        exit 1
    fi
    log_pass
}

test_verify_deleted() {
    id="$1"
    log_task "Verifying deletion"
    if "$DRIVER" list 2>"$DRIVER_ERR" | grep -q "^$id$"; then
        log_error "Secret '$id' still exists after deletion"
        exit 1
    fi
    log_pass
}

run_full_crud_test() {
    id="$1"
    value="$2"
    label="$3"

    log_divider
    log_info "🚀 Running full CRUD test: $label"

    # Export for the cleanup trap
    export SECRET_ID="$id"

    test_store "$id" "$value"
    test_list "$id"
    test_lookup "$id" "$value"
    test_delete "$id"
    test_verify_deleted "$id"

    unset SECRET_ID
}

# --- Main Test Execution ---

log_info "Testing generic driver: ${CYAN}$DRIVER${NC}"
log_info "Driver SHA256: ${CYAN}$(sha256sum "$DRIVER" | awk '{print $1}')${NC}"

# 1. Robustness Tests
log_divider
log_info "🚀 Running Robustness Tests"

log_task "💥 Missing SECRET_ID"
(
    unset SECRET_ID
    if printf "dummy" | "$DRIVER" store 2>/dev/null; then
        log_error "Driver accepted 'store' without SECRET_ID"
        exit 1
    fi
)
log_pass

log_task "💥 Empty stdin on store"
(
    ROBUSTNESS_ID="test-robustness-$$"
    if printf "" | SECRET_ID="$ROBUSTNESS_ID" "$DRIVER" store 2>/dev/null; then
        log_error "Driver accepted empty stdin on 'store'"
        exit 1
    fi
)
log_pass

# 2. Standard Secret Test
run_full_crud_test "test-std-$$" "test-value-$$" "${CYAN}Standard Secret${NC}"

# 3. Trailing Newline Test
run_full_crud_test "test-nl-$$" "$(printf "line1\nline2\n\n")" "${CYAN}Trailing Newlines${NC}"

# Disable the trap before the final success message
trap - EXIT
rm -f "$DRIVER_ERR"
printf '%b✨ Driver passed all tests successfully! ✨%b\n' "$GREEN" "$NC"
printf '%b  (•‿•)  %b\n' "$CYAN" "$NC"
