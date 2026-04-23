ARG IMAGE_VERSION=latest
FROM ubuntu:${IMAGE_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
    libsecret-tools \
    dbus-x11 \
    gnome-keyring \
    coreutils \
    gawk \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Initialize gnome-keyring-daemon headlessly within the dbus session.
# We pipe an empty string to --unlock to initialize/unlock the default keyring without a prompt.
RUN printf "#!/bin/sh\nexport \$(echo '' | gnome-keyring-daemon --unlock --components=secrets)\nexec \"\$@\"" > /entrypoint.sh && chmod +x /entrypoint.sh

# We must run the entrypoint inside dbus-run-session so the daemon can register on the bus.
ENTRYPOINT ["dbus-run-session", "--", "/entrypoint.sh"]
