About
=====

Simple container secret `shell` drivers.

The drivers implement [secrets/shelldriver/shelldriver.go](https://github.com/containers/container-libs/blob/8af78737e8bb95d411d0020f83dce9b678590141/common/pkg/secrets/shelldriver/shelldriver.go). See `man podman-secret-create` for more details.

Drivers
=======

* `secret-tool` => uses the session keyring to store container secrets for rootless containers
* `skate` => uses [charmbracelet/skate](https://github.com/charmbracelet/skate) and `gpg` to store encrypted secrets locally (respects XDG standards)
* `systemd-creds` => uses `systemd-creds` to store encrypted secrets locally backed by TPM 2.0 or host keys

Install Example:
================

```bash
git clone https://github.com/sabedevops/ContainerSecrets.git
cd ContainerSecrets

# For secret-tool
cp ./drivers/secret-tool.sh $HOME/.local/bin/container-secrets-driver-secret-tool.sh

# For skate
cp ./drivers/skate.sh $HOME/.local/bin/container-secrets-driver-skate.sh

# For systemd-creds
cp ./drivers/systemd-creds.sh $HOME/.local/bin/container-secrets-driver-systemd-creds.sh
```

Add to `$XDG_CONFIG_HOME/containers/containers.conf`:

Example for `secret-tool`
-------------------------
```ini
[secrets]
driver = "shell"

[secrets.opts]
list = "$HOME/.local/bin/container-secrets-driver-secret-tool.sh list"
lookup = "$HOME/.local/bin/container-secrets-driver-secret-tool.sh lookup"
store = "$HOME/.local/bin/container-secrets-driver-secret-tool.sh store"
delete = "$HOME/.local/bin/container-secrets-driver-secret-tool.sh delete"
```

Running with `podman`
=====================

```bash
# Option 1: Reading from file
printf 'mysecret' > ./secret.txt
podman secret create --driver shell 'SECRET_NAME' ./secret.txt

# Option 2: Reading from stdin
printf  'mysecret' | podman secret create --driver shell 'SECRET_NAME' -

# - OR -

echo -n 'mysecret' | podman secret create --driver shell 'SECRET_NAME' -
```

Contributing
============

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to add and test new drivers.
