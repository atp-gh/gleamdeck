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

**Status: Done / Current**

The current TOML parser is intentionally minimal to meet initial needs. This version will refactor the configuration system to be more robust and fully compliant with the TOML spec, alongside better build-time validation.

- [x] Replace the simple parser with a fully featured TOML parsing library (e.g., upgrading the `tom` dependency)
- [x] Support advanced TOML syntax (multiline strings, arrays, inline tables, escaped characters)
- [x] Introduce config schema validation to catch invalid configurations at build time with clear error reporting
- [x] Allow optional fields in `config.toml` so users can override specific defaults without defining the entire file
- [x] Add unit tests specifically for configuration parsing and validation

## v0.3.0 - Custom Service Icons

**Status: Planned**

Currently, service cards only support a single Emoji or text character as an icon. This version will expand the icon system to allow custom vector graphics or images, making the dashboard more personalized.

- [ ] Support [selfh.st](https://selfh.st/icons/) icon URL integration for fetching standardized service logos
- [ ] Support relative paths in the `icon` field to reference local SVG/PNG assets (e.g., `static/icons/jellyfin.svg`)
- [ ] Build pipeline optimization: automatically detect and copy referenced custom icon assets into the `dist/` directory
- [ ] Update the frontend rendering logic to dynamically render an Emoji or an `<img>` tag based on the `icon` value
- [ ] Support a configurable global fallback icon for services with missing icons or failed image loads
- [ ] Ensure proper browser caching for image assets to maintain fast dashboard load times
