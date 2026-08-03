# GleamDeck

A lightweight, configuration-driven dashboard for self-hosted services, built with [gleam](https://gleam.run/) and [lustre](https://hexdocs.pm/lustre/).

GleamDeck turns a simple `config/services.toml` file into a responsive static dashboard. It provides service shortcuts, categories, search, live reachability checks, and service status summaries without requiring a backend or database.

[![License](https://img.shields.io/badge/LICENSE-MIT-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Stable-green.svg)](https://github.com/atp-gh/gleamdeck/deployments)
[![Lastest Tag](https://img.shields.io/github/v/tag/atp-gh/gleamdeck)](https://github.com/atp-gh/gleamdeck/tags)
[![Gleam](https://img.shields.io/badge/Gleam-ffaff3?logo=gleam&labelColor=292d3e&color=ffaff3)](https://gleam.run)

![](https://github.com/atp-gh/gleamdeck/raw/main/docs/screenshots/gleamdeck-view.png)

## Features

- Built with Gleam and Lustre
- Pure static output with no application server required
- Service configuration through `config/services.toml`
- Browser-side service reachability checks
- Search across service names, descriptions, and categories
- Category-based filtering
- Online, offline, and checking status summaries
- Responsive glass-style interface
- Live local clock and refresh timestamps
- Reduced-motion accessibility support
- Bundled into a single minified browser ESM file
- Deployable to any static hosting provider

## Preview

GleamDeck presents your self-hosted applications as a searchable collection of service cards.

Each card can display:

- Service name
- Description
- Icon
- Category
- Hostname
- Port
- Current reachability status

The dashboard also includes aggregate counts for total, reachable, probing, and unavailable services.

## How It Works

GleamDeck uses a small static build pipeline:

1. `config/services.toml` and `config/config.toml` are parsed by a purpose-built Gleam configuration parser.
2. The service definitions are converted into `dist/services.json` and `dist/config.json`.
3. The Lustre application is compiled to JavaScript.
4. Bun bundles the compiled application and its dependencies into `dist/app.mjs`.
5. CSS files under `src/css/` are minified and inlined into the generated `index.html`.
6. Static assets from `static/` are copied into `dist/`.
7. The finished `dist/` directory can be hosted by any static web server.

At runtime, the browser loads `services.json` and `config.json`, renders the Lustre application, and performs reachability checks for the configured services.

> 📐 For an in-depth look at the model, messages, effects, build pipeline, and module responsibilities, see [docs/architecture.md](docs/architecture.md).

## Requirements

Install the following tools before building GleamDeck:

- https://gleam.run/getting-started/installing/
- https://bun.sh/

Verify the installation:

```sh
gleam --version
bun --version
```

## Quickly start

```sh
gleam build
bun run build
bun run dev
```

visit `http://localhost:3333` in browser.

---

## Getting Started

### 1. Clone the repository

```sh
git clone https://github.com/atp-gh/gleamdeck.git
cd gleamdeck
```

### 2. Download dependencies

```sh
gleam build
```

### 3. Configure your services

Edit `config/services.toml`:

```toml
[[service]]
id = "jellyfin"
name = "Jellyfin"
url = "https://jellyfin.example.com"
health_url = "https://jellyfin.example.com"
icon = "🎬"
description = "Streaming media server for movies, shows and music."
category = "Media"
port = 8096
```

### 4. Configure site and metadata

Edit `config/config.toml` to customize the dashboard title, description, and timezone:

```toml
[meta]
title = "Gleam Deck"
description = "Self-hosted services dashboard"
favicon = "images/gleamdeck.avif"
language = "en"

[site]
title = "My Gleam Deck"
subtitle = "My Self-hosted services"
timezone = "UTC"
```

### 5. Build the dashboard

```sh
bun run build
```

The generated site will be written to `dist/`.

### 6. Preview locally

Because GleamDeck loads `services.json` through an HTTP request, open it through a local web server.

Using Bun:

```sh
bun run dev
```

Then open:

```text
http://localhost:3333
```

## Configuration

GleamDeck is configured through two TOML files:

- `config/config.toml` — site metadata, language, favicon, and timezone
- `config/services.toml` — repeated `[[service]]` blocks describing each entry

A minimal service block looks like this:

```toml
[[service]]
id = "service-id"
name = "Service Name"
url = "https://service.example.com"
health_url = "https://service.example.com/health"
icon = "◈"
description = "A short description of the service."
category = "Infrastructure"
port = 443
```

Site metadata is split into `[meta]` (document-level) and `[site]` (dashboard-level) tables:

```toml
[meta]
title = "Gleam Deck"
description = "Self-hosted services dashboard"
favicon = "images/gleamdeck.avif"
language = "en"

[site]
title = "My Gleam Deck"
subtitle = "My Self-hosted services"
timezone = "UTC"
```

> 📘 For the complete field reference, default values, parser limitations, and examples, see [docs/configuration.md](docs/configuration.md).

## Architecture

GleamDeck follows an Elm-style architecture through Lustre.

- **Model** stores loaded services, configuration loading state, search query, active category, and timestamps.
- **Messages** such as `ServicesLoaded`, `SetQuery`, `SelectCategory`, `RefreshAll`, `HealthResult`, and `Tick` drive the update loop.
- **Effects** are kept outside the pure update and view logic: service configuration is loaded through `rsvp`, while health checks, clock functions, and build-time shell commands are exposed through small JavaScript FFIs.

> 📐 For the full architecture walkthrough — model, messages, effects, build pipeline, and module map — see [docs/architecture.md](docs/architecture.md).

## Health Checks

GleamDeck checks service reachability directly from the visitor's browser.

Each request:

- Uses the configured `health_url`
- Has a six-second timeout
- Disables browser caching
- Follows redirects
- Uses `no-cors` request mode

A fulfilled request is treated as reachable. A network error, blocked connection, DNS failure, or timeout is treated as offline.

### Important limitations

The status indicator represents browser-level reachability, not full application health.

Because the requests use `no-cors`, GleamDeck cannot inspect the response body or HTTP status code. A service may therefore appear online even if it returns an application error page.

Results can also be affected by:

- Browser mixed-content protection
- DNS resolution
- Firewalls
- VPN connectivity
- Reverse proxy configuration
- TLS certificate errors
- Content security policies
- Private network restrictions
- Ad blockers and browser extensions

For public dashboards, avoid exposing private hostnames, internal addresses, tokens, credentials, or sensitive health endpoints.

## Development

GleamDeck is developed with Gleam and Bun. Common commands:

```sh
gleam build      # download and compile dependencies
bun run build    # run the full static build pipeline
bun run dev      # live development server with auto-reload
bun run check    # gleam check && gleam test
bun run test     # run Gleam tests
gleam format     # format the source code
```

The build pipeline parses configuration, clears and recreates `dist/`, bundles the Lustre SPA with Bun, inlines CSS, copies static assets, and generates `services.json`, `config.json`, and `index.html`.

> 🛠️ For the full development guide — project structure, module responsibilities, build pipeline internals, testing, and live reload — see [docs/development.md](docs/development.md).

## Deployment

Deploy the contents of `dist/` to any static hosting service.

### Generic web server

Configure the document root to point to the generated `dist/` directory.

## Security Notes

GleamDeck is a client-side navigation and reachability dashboard. It does not provide authentication, authorization, proxying, or access control.

Keep the following in mind:

- Everything in `services.json` and `config.json` is visible to dashboard visitors.
- Do not place credentials or secrets in `config/services.toml` or `config/config.toml`.
- Do not include authenticated URLs containing access tokens.
- Protect the deployed dashboard separately if it contains private infrastructure details.
- Prefer HTTPS for both GleamDeck and all configured services.
- A dashboard link does not replace authentication on the target service.

## Roadmap

Possible future improvements include:

- Full TOML parsing
- Config System
- Custom SVG or image icons
- Theme selection
- Service sorting
- Favorite and pinned services
- Automatic refresh intervals
- Progressive Web App support
- Keyboard navigation improvements
- Configurable health-check timeouts
- Optional build-time service validation
- Tests for configuration parsing and service filtering

## Contributing

Contributions are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Make and format your changes.
4. Run the checks and tests.
5. Open a pull request.

```sh
git checkout -b feature/my-change
gleam format
gleam check
gleam test
```

Please keep the project focused on a lightweight, static, and configuration-driven dashboard.

## License

This project is available under the MIT License.

See [LICENSE](LICENSE) for details.

## Acknowledgements

Special thanks to [Arata](https://github.com/yonzilch/arata) for the inspiration and architectural reference behind this project.

GleamDeck is also made possible by the [gleam](https://gleam.run) language and its welcoming, creative community. Thanks to everyone building tools, libraries, documentation, and ideas across the Gleam ecosystem.
