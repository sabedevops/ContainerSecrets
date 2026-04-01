About
=====

Simple container secret `shell` drivers.

The drivers implement [secrets/shelldriver/shelldriver.go](https://github.com/containers/container-libs/blob/8af78737e8bb95d411d0020f83dce9b678590141/common/pkg/secrets/shelldriver/shelldriver.go). See `man podman-secret-create` for more details.

Drivers
=======

* `secret-tool` => uses the session keyring to store container secrets for rootless containers

Install Example:
================

```bash
git clone https://github.com/sabedevops/ContainerSecrets.git
cd ContainerSecrets

cp ./drivers/secret-tool.sh $HOME/.local/bin/container-secrets-driver-secret-tool.sh
```

Add to `$XDG_CONFIG_HOME/containers/containers.conf`:

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
echo -n 'mysecret' > ./secret.txt
podman secret create --driver shell 'SECRET_NAME' ./secret.txt

# Option 2: Reading from stdin
echo -n 'mysecret' | podman secret create --driver shell 'SECRET_NAME' -
```
