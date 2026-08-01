# GleamDeck

A lightweight, configuration-driven dashboard for self-hosted services, built with [gleam](https://gleam.run/) and [lustre](https://hexdocs.pm/lustre/).

GleamDeck turns a simple `services.toml` file into a responsive static dashboard. It provides service shortcuts, categories, search, live reachability checks, and service status summaries without requiring a backend or database.

[![License](https://img.shields.io/badge/LICENSE-MIT-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Stable-green.svg)](https://github.com/atp-gh/gleamdeck/deployments)
[![Lastest Tag](https://img.shields.io/github/v/tag/atp-gh/gleamdeck)](https://github.com/atp-gh/gleamdeck/tags)
[![Gleam](https://img.shields.io/badge/Gleam-ffaff3?logo=gleam&labelColor=292d3e&color=ffaff3)](https://gleam.run)

![](https://github.com/atp-gh/gleamdeck/raw/main/docs/screenshots/gleamdeck-view.png)

## Features

- Built with Gleam and Lustre
- Pure static output with no application server required
- Service configuration through `services.toml`
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

1. `services.toml` is parsed by a purpose-built Gleam configuration parser.
2. The service definitions are converted into `dist/services.json`.
3. The Lustre application is compiled to JavaScript.
4. Bun bundles the compiled application and its dependencies into `dist/app.mjs`.
5. CSS and static assets are copied into `dist/`.
6. The finished `dist/` directory can be hosted by any static web server.

At runtime, the browser loads `services.json`, renders the Lustre application, and performs reachability checks for the configured services.

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

```
gleam build
gleam run -m build/pipeline
bunx serve dist
```

visit `http://localhost:3000` in browser.

##

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

Edit `services.toml` in the project root:

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

### 4. Build the dashboard

```sh
gleam run -m build/pipeline
```

The generated site will be written to `dist`.

### 5. Preview locally

Because GleamDeck loads `services.json` through an HTTP request, open it through a local web server instead of opening `index.html` directly with a `file://` URL.

Using Bun:

```sh
bunx serve dist
```

Then open:

```text
http://localhost:8000
```

## Configuration

Services are configured using repeated `[[service]]` blocks.

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

### Available fields

| Field         | Required | Default        | Description                                   |
| ------------- | -------: | -------------- | --------------------------------------------- |
| `name`        |      Yes | None           | Human-readable service name                   |
| `url`         |      Yes | None           | Destination opened when the card is selected  |
| `id`          |       No | Value of `url` | Stable identifier used for status updates     |
| `health_url`  |       No | Value of `url` | URL used for browser-side reachability checks |
| `icon`        |       No | `▣`            | Text or emoji shown on the service card       |
| `description` |       No | Empty string   | Short service description                     |
| `category`    |       No | `Other`        | Category used by the filter controls          |
| `port`        |       No | `0`            | Displayed service port; `0` hides the port    |

### Minimal configuration

Only `name` and `url` are required:

```toml
[[service]]
name = "Home Assistant"
url = "https://home.example.com"
```

This produces the equivalent defaults:

```toml
id = "https://home.example.com"
health_url = "https://home.example.com"
icon = "▣"
description = ""
category = "Other"
port = 0
```

### Separate destination and health URLs

The page users visit does not need to be the same URL used for reachability checks:

```toml
[[service]]
id = "paperless"
name = "Paperless-ngx"
url = "https://docs.example.com"
health_url = "https://docs.example.com/api/status/"
icon = "📄"
description = "Document management and searchable archive."
category = "Productivity"
port = 8000
```

Using a lightweight public health endpoint can make checks faster and more reliable.

## Configuration Parser Limitations

The current parser is intentionally small and is designed specifically for GleamDeck service blocks. It is not a complete TOML implementation.

Currently supported:

- Repeated `[[service]]` blocks
- `key = value` assignments
- Quoted string values
- Integer ports
- Line comments beginning with `#`
- Blank lines

Keep each assignment on one line:

```toml
name = "Forgejo"
```

Avoid advanced TOML syntax such as:

- Multiline strings
- Arrays
- Inline tables
- Escaped TOML string sequences
- Nested tables
- Values containing unescaped `#` characters
- Values containing additional `=` characters

Invalid or incomplete service blocks cause the build to stop with an explanatory error.

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

### Run the build pipeline

```sh
gleam run -m build/pipeline
```

The pipeline performs the following operations:

- Parses `services.toml`
- Clears and recreates `dist/`
- Bundles the browser application with Bun
- Copies CSS files from `src/css/`
- Copies files from `static/`, when present
- Generates `services.json`
- Generates `index.html`

### Check the project

```sh
gleam check
```

### Format the source code

```sh
gleam format
```

### Run tests

```sh
gleam test
```

## Project Structure

```text
gleamdeck/
├── gleam.toml
├── services.toml
├── src/
│ ├── build/
│ │ ├── config.gleam
│ │ ├── generate.gleam
│ │ └── pipeline.gleam
│ ├── dashboard/
│ │ ├── app.gleam
│ │ ├── runtime.gleam
│ │ └── service.gleam
│ ├── effect/
│ │ ├── clock.gleam
│ │ └── health.gleam
│ ├── ffi/
│ │ ├── clock.mjs
│ │ ├── health.mjs
│ │ └── shell.ffi.mjs
│ ├── css/
│ │ └── app.css
│ └── dashboard.gleam
├── static/
└── dist/
```

### Main modules

- `build/config.gleam` parses the service configuration.
- `build/generate.gleam` generates JSON and the HTML entry document.
- `build/pipeline.gleam` controls the complete static build.
- `dashboard/app.gleam` contains the Lustre model, messages, update logic, and view.
- `dashboard/service.gleam` defines service types and collection helpers.
- `dashboard/runtime.gleam` loads the generated service data.
- `effect/health.gleam` exposes browser health-check effects.
- `effect/clock.gleam` exposes browser clock functions.

## Architecture

GleamDeck follows an Elm-style architecture through Lustre.

### Model

The model stores:

- Loaded services
- Configuration loading state
- Search query
- Active category
- Current timestamp
- Last refresh timestamp

### Messages

The application responds to messages such as:

- `ServicesLoaded`
- `SetQuery`
- `SelectCategory`
- `RefreshAll`
- `HealthResult`
- `Tick`

### Effects

Side effects are kept outside the pure update and view logic:

- Service configuration is loaded through `rsvp`
- Health checks are exposed through a small JavaScript FFI
- Clock functions are exposed through a small JavaScript FFI
- Bundling commands are executed by the build-only shell FFI

## Deployment

Deploy the contents of `dist/` to any static hosting service.

### Generic web server

Configure the document root to point to the generated `dist/` directory.

Example with Caddy:

```caddyfile
gleamdeck.example.com {
root * /srv/gleamdeck/dist
file_server
}
```

Example with Nginx:

```nginx
server {
listen 80;
server_name gleamdeck.example.com;

root /srv/gleamdeck/dist;
index index.html;

location / {
try_files $uri $uri/ /index.html;
}
}
```

## Security Notes

GleamDeck is a client-side navigation and reachability dashboard. It does not provide authentication, authorization, proxying, or access control.

Keep the following in mind:

- Everything in `services.json` is visible to dashboard visitors.
- Do not place credentials or secrets in `services.toml`.
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
