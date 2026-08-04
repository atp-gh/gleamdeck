# Roadmap

This document outlines the development plan and version milestones for GleamDeck.

## v0.1.0 - Base System Completion

**Status: Done**

The core functionality of GleamDeck is complete, providing a lightweight, static, backend-free dashboard for self-hosted services.

- [x] Elm-architecture SPA built with Gleam and Lustre
- [x] Configuration driven by `config/services.toml` and `config/config.toml`
- [x] Purpose-built basic TOML parser (supports strings, integers, comments)
- [x] Browser-side service health checks (using `no-cors` and timeout mechanisms)
- [x] Fuzzy search across service names, descriptions, and categories
- [x] Category-based filtering pills
- [x] Live local clock and refresh timestamps
- [x] CSS minification and inlining, bundled into a pure static ESM output
- [x] Responsive glass-style UI with accessibility support

## v0.2.0 - Configuration System Refactor

**Status: Done**

The current TOML parser is intentionally minimal to meet initial needs. This version will refactor the configuration system to be more robust and fully compliant with the TOML spec, alongside better build-time validation.

- [x] Replace the simple parser with a fully featured TOML parsing library (e.g., upgrading the `tom` dependency)
- [x] Support advanced TOML syntax (multiline strings, arrays, inline tables, escaped characters)
- [x] Introduce config schema validation to catch invalid configurations at build time with clear error reporting
- [x] Add unit tests specifically for configuration parsing and validation

## v0.3.0 - Custom Service Icons

**Status: Done**

Currently, service cards only support a single Emoji or text character as an icon. This version will expand the icon system to allow custom vector graphics or images, making the dashboard more personalized.

- [x] Support [selfh.st](https://selfh.st/icons/), [Simple Icons](https://simpleicons.org/), [home lab icons](https://github.com/homarr-labs/dashboard-icons) and [Material Design Icons](https://pictogrammers.com/library/mdi/) icon URL integration for fetching standardized service logos
- [x] Support images URL integration for icon
- [x] Support relative paths in the `icon` field to reference local SVG/PNG assets (e.g., `static/icons/jellyfin.svg`)
- [x] Build pipeline optimization: automatically detect and copy referenced custom icon assets into the `dist/` directory
- [x] Update the frontend rendering logic to dynamically render an Emoji or an `<img>` tag based on the `icon` value
- [x] Ensure proper browser caching for image assets to maintain fast dashboard load times

## v0.4.0 - Configuration System Refactor

**Status: Doing / Current**

Complete the configuration system refactor by introducing explicit optional-field semantics across service and dashboard configuration.

- [x] Refactor `config/services.toml` to model optional service fields with `Option` while keeping essential fields required
- [ ] Refactor `config/config.toml` to model optional dashboard settings with `Option` and provide sensible fallback behavior
- [ ] Add `health` Add an optional `health_check` boolean setting to `config/config.toml` to enable or disable service health checks
