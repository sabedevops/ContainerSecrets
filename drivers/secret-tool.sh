#!/bin/sh
# Copyright 2026 Steven A. Broderick Elias <sabe@sabedevops.net>
# SPDX-License-Identifier: Apache-2.0

set -o nounset
set -o errexit

usage() {
    echo "Usage: $0 {list|lookup|store|delete}" >&2
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

_check_dependencies() {
    for cmd in secret-tool md5sum awk; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: Required command '$cmd' not found" >&2
            exit 1
        fi
    done
}

_check_dependencies

# You MAY specify the secrets collection with:
#
# export CONTAINER_SECRETS_COLLECTION=/org/freedesktop/secrets/collection/ContainerSecrets
#
# You MUST precreate the collection (e.g. org.gnome.Seahorse, etc.)
# You MUST specify the full D-BUS object path
# You MAY enable automatic unlocking at login


COLLECTION="${CONTAINER_SECRETS_COLLECTION:-default}"
COLLECTION_ID="$(printf "%s" "$COLLECTION" | md5sum | awk '{print $1}')"

APP_ID='ContainerSecrets'

_ensure_secret_id() {
    if [ -z "${SECRET_ID:-}" ]; then
        echo "Error: SECRET_ID must be set" >&2
        exit 1
    fi
}

list() {
    # secret-tool writes attributes to stderr for some reason
    # prevent masking errors while avoiding `set -o pipefail`
    result=$(secret-tool search --all COLLECTION_ID "$COLLECTION_ID" APP_ID "$APP_ID" 2>&1) || {
        status=$?
        printf '%s\n' "$result" >&2
        return "$status"
    }

    printf '%s\n' "$result" | awk '/attribute.SECRET_ID/ {print $NF}'
}

lookup() {
    _ensure_secret_id
    secret-tool lookup \
        COLLECTION_ID "$COLLECTION_ID" \
        APP_ID "$APP_ID" \
        SECRET_ID "$SECRET_ID"
}

store() {
    _ensure_secret_id
    # Read stdin and ensure it's not empty, preserving trailing newlines
    CONTENT=$(cat; printf 'x')
    CONTENT="${CONTENT%x}"

    if [ -z "$CONTENT" ]; then
        echo "Error: stdin is empty" >&2
        exit 1
    fi
    printf "%s" "$CONTENT" | secret-tool store \
        --collection="$COLLECTION" \
        --label="$APP_ID ($SECRET_ID)" \
        COLLECTION_ID "$COLLECTION_ID" \
        APP_ID "$APP_ID" \
        SECRET_ID "$SECRET_ID"
}

delete() {
    _ensure_secret_id
    secret-tool clear \
        COLLECTION_ID "$COLLECTION_ID" \
        APP_ID "$APP_ID" \
        SECRET_ID "$SECRET_ID"
}

case "$1" in
    list) list ;;
    lookup) lookup ;;
    store) store ;;
    delete) delete ;;
    *) usage ;;
esac
