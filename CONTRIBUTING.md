# Contributing to ContainerSecrets

Thank you for your interest in contributing! This project aims to provide a collection of useful shell drivers for container secrets.

## Adding a New Driver

1.  **Implement the Driver:** Create a new shell script in the `drivers/` directory. Ensure it follows the [containers/common](https://github.com/containers/common/blob/main/pkg/secrets/shelldriver/shelldriver.go) shell driver interface (implementing `list`, `lookup`, `store`, and `delete`).
2.  **Use POSIX Shell:** To ensure maximum compatibility, please write your scripts in POSIX-compliant shell (`#!/bin/sh`).
3.  **Handle Dependencies:** Add a `_check_dependencies` function to verify that required CLI tools are installed.
4.  **License:** Include the SPDX license identifier and copyright header at the top of your script.

## Testing Your Driver

Before submitting a pull request, you **must** test your driver using the provided test script.

To ensure clean and reproducible tests, each driver must have a corresponding `.Containerfile` in the `tests/drivers/` directory (e.g., `tests/drivers/your-driver.sh.Containerfile`). This Containerfile defines the environment needed to run the tests. You should use an `IMAGE_VERSION` build argument to allow CI to test against different OS versions.

```dockerfile
# Example tests/drivers/your-driver.sh.Containerfile
ARG IMAGE_VERSION=latest
FROM ubuntu:${IMAGE_VERSION}
RUN apt-get update && apt-get install -y [your-dependencies]
WORKDIR /workspace
```

You can then run the tests locally using Docker or Podman:

```bash
# Build the test environment
podman build -f tests/drivers/your-driver.sh.Containerfile -t test-your-driver .

# Run the test script inside the container
podman run --rm -v "$PWD:/workspace" test-your-driver /workspace/tests/test_driver.sh /workspace/drivers/your-driver.sh
```

The test script will perform a full CRUD (Create, Read, Update/List, Delete) cycle and check for robustness (e.g., handling missing environment variables or empty stdin).

### CI Skip List

Some drivers may require specific hardware (e.g., TPM), account or cloud access, or environment configurations that are not available in the standard GitHub Actions CI runner. These drivers are added to the `SKIP_LIST` in `.github/workflows/ci.yml`.

If your driver cannot be tested in CI:
1.  Add it to the `SKIP_LIST` in `.github/workflows/ci.yml`.
2.  Provide a corresponding `.Containerfile` in `tests/drivers/`. This file can be a "no-op" but must include a comment explaining why it is skipped (refer to `tests/drivers/systemd-creds.sh.Containerfile`).
3.  You are still responsible for verifying the driver manually in a suitable environment.
4.  Attach the output of `tests/test_drivers.sh` to your PR. Make sure the sha256sum of the driver script you submit in the PR matches the output.
5.  Your commits must be signed and verified.

## Documentation

- **README.md:** We strongly encourage you to add your driver to the "Drivers" section and provide an "Install Example" and configuration snippet in the `README.md`.
- **Comments:** Provide helpful comments at the top of your script explaining any required environment variables or setup steps.

## Submitting a Pull Request

1.  Fork the repository.
2.  Create a new branch for your driver.
3.  Commit your changes, including the driver script and any documentation updates.
4.  Open a Pull Request! A GitHub Action will automatically run the tests for your driver.
