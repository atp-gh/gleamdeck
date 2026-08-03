# Development

This document covers everything you need to contribute to GleamDeck: toolchain setup, common commands, the build pipeline internals, project structure, testing, and live development.

## Toolchain

GleamDeck is developed with [Gleam](https://gleam.run) (compiles to JavaScript) and [Bun](https://bun.sh) (runtime, bundler, and dev server).

Install both tools:

- https://gleam.run/getting-started/installing/
- https://bun.sh/

Verify the installation:

```sh
gleam --version
bun --version
```

## Initial Setup

```sh
git clone https://github.com/atp-gh/gleamdeck.git
cd gleamdeck
gleam build   # downloads and compiles Gleam dependencies
```

Gleam dependencies are declared in `gleam.toml`:

| Dependency     | Purpose                            |
| -------------- | ---------------------------------- |
| `gleam_stdlib` | Standard library                   |
| `lustre`       | Elm-style SPA framework            |
| `simplifile`   | File system operations             |
| `rsvp`         | HTTP requests in the browser       |
| `tom`          | TOML parser                        |
| `gleam_json`   | JSON encoding for generated output |
| `gleeunit`     | Test runner (dev dependency)       |

## npm Scripts

Defined in `package.json`:

| Script    | Command                        | Description                              |
| --------- | ------------------------------ | ---------------------------------------- |
| `build`   | `gleam run -m build/pipeline`  | Run the full static build pipeline       |
| `check`   | `gleam check && gleam test`    | Type-check and run tests                 |
| `clean`   | `rm -rf dist build`            | Remove build artifacts                   |
| `dev`     | `bun run scripts/dev.ts`       | Live development server with auto-reload |
| `preview` | `clean && rebuild && serve`    | Full production preview                  |
| `rebuild` | `rm -rf dist && bun run build` | Clean rebuild                            |
| `serve`   | `bunx serve dist -l 3333`      | Serve `dist/` on port 3333               |
| `test`    | `gleam test`                   | Run Gleam tests                          |

## Build Pipeline

`bun run build` invokes `gleam run -m build/pipeline`, which executes `src/build/pipeline.gleam`. The pipeline performs these steps in order:

1. **Load build configuration**
   - `config/load_config.load()` reads `config/config.toml`.
   - `config/load_services.load()` reads `config/services.toml`.
   - Configuration failures for `config.toml` fall back to defaults; failures for `services.toml` abort the build.

2. **Discover CSS**
   - `simplifile.get_files("src/css")` recursively lists CSS files.
   - Files are filtered to `*.css` and sorted alphabetically for a deterministic cascade.

3. **Reset `dist/`**
   - `simplifile.delete_all(["dist"])`
   - `simplifile.create_directory_all("dist")`

4. **Bundle the SPA**
   - Writes an ESM entry shim to `build/dev/javascript/gleamdeck/entry.mjs`:
     ```javascript
     import { main } from "./dashboard.mjs";
     main();
     ```
   - Runs Bun:
     ```sh
     bun build <shim> \
       --outfile dist/app.mjs \
       --target browser \
       --format esm \
       --minify \
       --sourcemap=none
     ```

5. **Copy static assets**
   - `copy_directory_contents("static", "dist")` walks `static/` and copies every file and subdirectory into `dist/`.

6. **Emit JSON**
   - `dist/config.json` — encoded from `SiteConfig`
   - `dist/services.json` — encoded from `List(ServiceConfig)`

7. **Generate `index.html`**
   - Each CSS file is read, minified, and sanitized:
     - Comments stripped (preserving quoted strings)
     - Whitespace collapsed
     - Spaces around `{`, `}`, `:`, `;`, `,`, `>`, `(`, `)` removed
     - `</style` sequences escaped to prevent breaking out of the inline style element
   - All CSS is concatenated and inlined into a single `<style id="gleamdeck-css">` block.
   - The HTML shell includes `<meta>`, favicon link, the `<div id="app">` mount point, and a `<script type="module" src="app.mjs">` tag.

8. **Print build summary**
   ```
   ✓ built dist/ (12 services, 3 CSS files inlined, timezone UTC, pure ESM)
   ```

## Project Structure

```text
gleamdeck/
├── gleam.toml
├── package.json
├── config/
│   ├── config.toml                  # Site metadata
│   └── services.toml                # Service entries
├── docs/
│   ├── architecture.md
│   ├── configuration.md
│   ├── development.md
│   └── screenshots/
├── scripts/
│   └── dev.ts                        # Live dev server
├── src/
│   ├── build/
│   │   └── pipeline.gleam           # Build orchestrator
│   ├── config/
│   │   ├── load_config.gleam        # config.toml parser & decoder
│   │   └── load_services.gleam      # services.toml parser & decoder
│   ├── data/
│   │   ├── config.gleam             # MetaConfig, SiteConfig, BuildConfig types
│   │   ├── service_collection.gleam # Pure list operations
│   │   └── services.gleam           # Service, ServiceConfig, Status types
│   ├── dashboard/
│   │   ├── app.gleam                 # Lustre init/update/view
│   │   ├── presentation.gleam       # View helpers
│   │   └── runtime.gleam            # Browser-side JSON loading (rsvp)
│   ├── effect/
│   │   ├── clock.gleam              # Clock FFI bindings
│   │   └── health.gleam             # Health check FFI bindings
│   ├── ffi/
│   │   ├── clock.mjs                # Intl.DateTimeFormat wrappers
│   │   ├── health.mjs               # fetch + AbortController health checks
│   │   └── shell.ffi.mjs           # Build-only command runner
│   ├── css/                         # CSS modules, inlined at build time
│   └── dashboard.gleam              # Browser entry; boots Lustre onto #app
├── static/                          # Static assets copied verbatim to dist/
└── dist/                            # Generated build output (gitignored)
```

## Module Responsibilities

### Build

- `src/build/pipeline.gleam` — Top-level orchestrator. Loads config, resets `dist/`, bundles the SPA, copies assets, emits JSON, and generates `index.html`.
- `src/ffi/shell.ffi.mjs` — Synchronous subprocess runner. Prefers `Bun.spawnSync`, falls back to Node's `execSync`.

### Configuration

- `src/config/load_config.gleam` — Reads `config/config.toml`, validates `[meta]` and `[site]` tables, and decodes them into `BuildConfig`.
- `src/config/load_services.gleam` — Reads `config/services.toml`, validates each `[[service]]` block, and decodes them into `List(ServiceConfig)`.

### Domain Types

- `src/data/config.gleam` — Defines `MetaConfig`, `SiteConfig`, `BuildConfig`, and provides default values used when `config.toml` is missing.
- `src/data/services.gleam` — Defines `Status`, `ServiceConfig`, `Service`, and operations like `from_config`, `with_checking_status`, and `with_health_result`.
- `src/data/service_collection.gleam` — Pure functions on `List(Service)`: `categories`, `status_counts`, and `filter`.

### Dashboard (Lustre SPA)

- `src/dashboard.gleam` — Browser entry point. Calls `lustre.start(app(), onto: "#app", with: Nil)`.
- `src/dashboard/app.gleam` — The application: `Model`, `Msg`, `init`, `update`, `view`, and `app`.
- `src/dashboard/presentation.gleam` — Pure helpers: `status_class`, `status_label`, `host_of`.
- `src/dashboard/runtime.gleam` — Loads `config.json` and `services.json` through `rsvp` and decodes them with `gleam/dynamic/decode`.

### Effects and FFI

- `src/effect/clock.gleam` — Bindings to `src/ffi/clock.mjs`: `now_ms`, `format_time`, `format_date`.
- `src/effect/health.gleam` — Bindings to `src/ffi/health.mjs`: `health_check`, `set_timeout`.
- `src/ffi/clock.mjs` — `Date.now()` and `Intl.DateTimeFormat` wrappers with timezone validation.
- `src/ffi/health.mjs` — `fetch` with `AbortController` for health checks, plus `setTimeout` for the 1-second `Tick` loop.

## Live Development

```sh
bun run dev
```

Starts a development server at `http://localhost:3333` that watches for changes in:

- `src/`
- `config/`
- `static/`
- `gleam.toml`

On any change, the project is rebuilt and the browser refreshes automatically.

## Testing

```sh
bun run test
# or
gleam test
```

Tests are written with [`gleeunit`](https://hexdocs.pm/gleeunit/) and live alongside source modules in `test/`.

Recommended areas to cover:

- `config/load_services` — valid blocks, missing fields, wrong types, empty strings
- `config/load_config` — missing tables, invalid types, defaults
- `data/service_collection` — `categories`, `status_counts`, `filter` with queries and categories
- `dashboard/presentation` — `status_class`, `status_label`, `host_of`

## Type Checking and Formatting

```sh
# Type-check the project
gleam check

# Format all Gleam source files
gleam format

# Combined check
bun run check
```

## Common Workflows

### Add a new service

1. Append a `[[service]]` block to `config/services.toml`.
2. Run `bun run dev` (auto-rebuild) or `bun run build` (manual).
3. Refresh the browser.

### Change site metadata

1. Edit `config/config.toml`.
2. Rebuild.

### Add CSS

1. Drop a `.css` file under `src/css/`.
2. Rebuild. Files are applied in alphabetical order, so prefix files (e.g. `00-tokens.css`, `10-base.css`) to control the cascade.

### Add static assets

1. Place files under `static/` (e.g. `static/images/favicon.ico`).
2. Rebuild. Files are copied verbatim to `dist/`.

### Add a browser-side effect

1. Implement the JavaScript in `src/ffi/<name>.mjs`.
2. Add a Gleam binding in `src/effect/<name>.gleam` using `@external(javascript, ...)`.
3. Call the effect from `update` via `effect.from`.

## Debugging Tips

- The browser entry shim is written to `build/dev/javascript/gleamdeck/entry.mjs`. Inspect it if the SPA fails to boot.
- `dist/app.mjs` is minified with no sourcemap. For debugging, temporarily remove `--minify` and `--sourcemap=none` from the `bun build` command in `src/build/pipeline.gleam`.
- Health-check requests use `no-cors`; the browser will not expose response status or body. Use the network tab to confirm requests are being sent.
- Invalid timezones log a warning in the browser console and fall back to `UTC`.

## Contributing

1. Fork the repository.
2. Create a feature branch:
   ```sh
   git checkout -b feature/my-change
   ```
3. Make your changes.
4. Format and validate:
   ```sh
   gleam format
   gleam check
   gleam test
   ```
5. Open a pull request.

Please keep the project focused on a lightweight, static, and configuration-driven dashboard. Avoid features that require an application server, database, or backend service.
