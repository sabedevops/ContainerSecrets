ARG IMAGE_VERSION=latest
FROM ubuntu:${IMAGE_VERSION}

# This Containerfile is a noop because systemd-creds.sh tests are
# currently skipped in CI due to environmental requirements.
# See .github/workflows/ci.yml SKIP_LIST.
