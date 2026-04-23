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
    for cmd in skate gpg sed; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: Required command '$cmd' not found" >&2
            exit 1
        fi
    done
}

_check_dependencies

# Configuration
#
# You MUST specify the GPG key ID or email to use for encryption:
# export CONTAINER_SECRETS_SKATE_GPG_KEY="your-key-id"
#
# You MAY specify the skate database name:
# export CONTAINER_SECRETS_SKATE_DB="sontainersecrets"
#
# skate default database location:
# "$XDG_DATA_HOME/charm/kv/${CONTAINER_SECRETS_SKATE_DB,,}"

_ensure_gpg_key() {
    if [ -z "${CONTAINER_SECRETS_SKATE_GPG_KEY:-}" ]; then
        echo "Error: CONTAINER_SECRETS_SKATE_GPG_KEY must be set" >&2
        exit 1
    fi
    export GPG_KEY="$CONTAINER_SECRETS_SKATE_GPG_KEY"
}

_ensure_secret_id() {
    if [ -z "${SECRET_ID:-}" ]; then
        echo "Error: SECRET_ID must be set" >&2
        exit 1
    fi
}

DB="${CONTAINER_SECRETS_SKATE_DB:-containersecrets}"

list() {
    skate list -k "@$DB" | sed "s/@$DB$//"
}

lookup() {
    _ensure_secret_id
    _ensure_gpg_key
    skate get "$SECRET_ID@$DB" | gpg --decrypt --quiet
}

store() {
    _ensure_secret_id
    _ensure_gpg_key
    # Read stdin and ensure it's not empty, preserving trailing newlines
    CONTENT=$(cat; printf 'x')
    CONTENT="${CONTENT%x}"

    if [ -z "$CONTENT" ]; then
        echo "Error: stdin is empty" >&2
        exit 1
    fi
    printf "%s" "$CONTENT" | gpg --encrypt --armor --recipient "$GPG_KEY" | skate set "$SECRET_ID@$DB"
    # Use this instead if you want to set long GPG cache ttl
    # See `man gpg-agent`
    #   --default-cache-ttl
    #   --maximum-cache-ttl
    # printf "%s" "$CONTENT" | gpg --batch --yes --encrypt --armor --recipient "$GPG_KEY" | skate set "$SECRET_ID@$DB"
}

delete() {
    _ensure_secret_id
    skate delete "$SECRET_ID@$DB"
}

case "$1" in
    list) list ;;
    lookup) lookup ;;
    store) store ;;
    delete) delete ;;
    *) usage ;;
esac
