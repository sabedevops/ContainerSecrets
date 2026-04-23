ARG IMAGE_VERSION=latest
FROM ubuntu:${IMAGE_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gpg \
    gpg-agent \
    sed \
    gawk \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list \
    && apt-get update && apt-get install -y --no-install-recommends skate && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Setup a generic GPG key for tests
RUN gpg --batch --passphrase '' --quick-gen-key CI-Test default default

# Wrapper to set the env var and run the command
RUN printf "#!/bin/sh\nexport CONTAINER_SECRETS_SKATE_GPG_KEY=\$(gpg --list-keys --with-colons | awk -F: '/^pub:/ { print \$5; exit }')\nexec \"\$@\"" > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
