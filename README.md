# asc-orb

Official CircleCI Orb for `asc` (App Store Connect CLI).

This repository publishes the first-party CircleCI orb as `rudrankriyam/asc`.

## Commands

- `install` - Install `asc` from GitHub releases (`latest` or pinned version).
- `setup-auth` - Export `asc` auth environment from CircleCI `env_var_name`
  parameters (no raw secrets in orb config).
- `run` - Execute a provided `asc` command string.

## Job

- `smoke` - Install `asc` and run smoke checks:
  - `asc --version`
  - `asc --help`
  - `asc version`

## Local development

Prerequisites:

- CircleCI CLI

```bash
circleci config pack src > orb.yml
circleci orb validate orb.yml
```

## Publishing

- Dev orbs are published from non-`main` branches.
- Production orbs are published only on semver tags (`vX.Y.Z`).
- CircleCI context `circleci-orb-publishing` must provide the orb token.
