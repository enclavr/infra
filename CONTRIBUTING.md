# Contributing to Enclavr Infra

Thank you for your interest in contributing to Enclavr's infrastructure configuration.

## Getting Started

1. Fork the repository and clone your fork.
2. Copy `.env.example` to `.env` and configure your local environment:
   ```bash
   cp .env.example .env
   ```
3. Never commit `.env` or any files containing secrets.

## Before Submitting a PR

- Validate your Docker Compose configuration:
  ```bash
  docker compose config
  ```
- Ensure no secrets or credentials are included in your changes.
- Test your configuration changes locally with `docker compose up -d`.

## Reporting Issues

Use the GitHub issue templates to report bugs or request features.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
