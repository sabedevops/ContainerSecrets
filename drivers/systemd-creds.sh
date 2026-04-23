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
    for cmd in systemd-creds awk mkdir; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: Required command '$cmd' not found" >&2
            exit 1
        fi
    done
}

_check_dependencies

# Configuration
#
# You MAY specify the directory to store encrypted credentials:
# export CONTAINER_SECRETS_SYSTEMD_CREDS_DIR="$XDG_DATA_HOME/ContainerSecrets/systemd-creds"
#
# You MAY specify the encryption key type (host, tpm2, host+tpm2, auto):
# export CONTAINER_SECRETS_SYSTEMD_CREDS_KEY="auto"

# Set default directory and export it as CREDENTIALS_DIRECTORY for systemd-creds
DIR="${CONTAINER_SECRETS_SYSTEMD_CREDS_DIR:-${CREDENTIALS_DIRECTORY:-$XDG_DATA_HOME/ContainerSecrets/systemd-creds}}"
export CREDENTIALS_DIRECTORY="$DIR"

KEY="${CONTAINER_SECRETS_SYSTEMD_CREDS_KEY:-auto}"

# Ensure the credentials directory exists
if [ ! -d "$CREDENTIALS_DIRECTORY" ]; then
    mkdir -p "$CREDENTIALS_DIRECTORY"
fi

_ensure_secret_id() {
    if [ -z "${SECRET_ID:-}" ]; then
        echo "Error: SECRET_ID must be set" >&2
        exit 1
    fi
}

list() {
    systemd-creds list --no-legend --no-pager 2>/dev/null | awk '{print $1}'
}

lookup() {
    _ensure_secret_id
    # systemd-creds decrypt displays the decrypted content
    # We use --newline=no to avoid adding an extra newline to the secret
    systemd-creds decrypt --newline=no "$CREDENTIALS_DIRECTORY/$SECRET_ID"
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

    printf "%s" "$CONTENT" | systemd-creds encrypt --with-key="$KEY" --name="$SECRET_ID" - "$CREDENTIALS_DIRECTORY/$SECRET_ID"
}

delete() {
    _ensure_secret_id
    rm -f "$CREDENTIALS_DIRECTORY/$SECRET_ID"
}

case "$1" in
    list) list ;;
    lookup) lookup ;;
    store) store ;;
    delete) delete ;;
    *) usage ;;
esac
