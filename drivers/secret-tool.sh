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
    secret-tool lookup \
        COLLECTION_ID "$COLLECTION_ID" \
        APP_ID "$APP_ID" \
        SECRET_ID "$SECRET_ID"
}

store() {
    secret-tool store \
        --collection="$COLLECTION" \
        --label="$APP_ID ($SECRET_ID)" \
        COLLECTION_ID "$COLLECTION_ID" \
        APP_ID "$APP_ID" \
        SECRET_ID "$SECRET_ID"
}

delete() {
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
