# asc CircleCI Orb

[![CircleCI Build Status](https://circleci.com/gh/rudrankriyam/asc-orb.svg?style=shield)](https://circleci.com/gh/rudrankriyam/asc-orb)
[![CircleCI Orb Version](https://badges.circleci.com/orbs/rudrankriyam/asc.svg)](https://circleci.com/developer/orbs/orb/rudrankriyam/asc)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

Official CircleCI Orb for `asc` (App Store Connect CLI), published as
`rudrankriyam/asc`.

Use this orb to install `asc`, configure secure App Store Connect API
authentication, and automate iOS/TestFlight release workflows in CircleCI.

## Why use this orb

- Optimized installer for `asc` release binaries (`latest` or pinned version)
- Secure auth setup using CircleCI `env_var_name` parameters
- Reusable commands for App Store Connect automation in CI/CD
- Works in Linux and macOS CircleCI executors

## Quick start

```yaml
version: 2.1

orbs:
  asc: rudrankriyam/asc@x.y.z

jobs:
  appstore-check:
    docker:
      - image: cimg/base:stable
    steps:
      - asc/install:
          version: latest
      - asc/run:
          command: asc --help

workflows:
  main:
    jobs:
      - appstore-check
```

## Commands and jobs

- `install`: Install `asc` from GitHub release assets
- `setup-auth`: Export `asc` authentication environment variables
- `run`: Execute a provided `asc` command string
- `smoke` job: Install `asc` and run no-side-effect smoke checks

## Security model

- Sensitive values are passed by env var name, not inline secrets
- `setup-auth` writes exported values to `BASH_ENV` for subsequent steps
- Optional checksum verification is supported in `install`

## Usage examples

- [Install only](./src/examples/install.yml)
- [Setup auth + run command](./src/examples/setup-and-run.yml)
- [End-to-end smoke workflow](./src/examples/end-to-end.yml)
- [macOS executor example](./src/examples/macos-install.yml)

## Resources

- Orb Registry: https://circleci.com/developer/orbs/orb/rudrankriyam/asc
- CircleCI orb docs: https://circleci.com/docs/orbs/author/orb-concepts
- asc CLI: https://github.com/rudrankriyam/App-Store-Connect-CLI

## Local development

Prerequisite: CircleCI CLI

```bash
circleci config pack src > orb.yml
circleci orb validate orb.yml
```

## Publishing

- Dev orb publishes from non-`main` branches
- Production publishes only on semver tags (`vX.Y.Z`)
- CircleCI context `circleci-orb-publishing` must provide publishing token
