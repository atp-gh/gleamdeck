# Architecture

GleamDeck is a configuration-driven, static-site dashboard for self-hosted services. This document describes the runtime architecture, the build pipeline, and the module layout.

## High-Level Overview

GleamDeck is split into two halves:

1. **Build time** — a Gleam program (`src/build/pipeline.gleam`) reads TOML configuration, bundles the Lustre SPA with Bun, inlines CSS, copies static assets, and emits `dist/index.html`, `dist/services.json`, and `dist/config.json`.
2. **Runtime** — the browser loads `index.html`, fetches `services.json` and `config.json`, boots the Lustre application, and runs reachability checks against each configured `health_url`.

No application server is required. The output of `dist/` is fully static.

```text
┌──────────────────────────────────────────────────────────────────┐
│                            Build time                            │
│                                                                  │
│   config/services.toml ───┐                                      │
│   config/config.toml  ────┤                                      │
│                           ↓                                      │
│                  src/build/pipeline.gleam                        │
│                           │                                      │
│         ┌─────────────────┼─────────────────┐                    │
│         ↓                 ↓                 ↓                    │
│   dist/services.json  dist/config.json  dist/app.mjs (Bun bundle)│
│                           │                                      │
│                           ↓                                      │
│                    dist/index.html                               │
│              (CSS inlined, ESM module script)                    │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                             Runtime                              │
│                                                                  │
│   Browser                                                        │
│     │                                                            │
│     ↓                                                            │
│   index.html -> app.mjs (Lustre SPA)                             │
│     │                                                            │
│     ├-> fetch("./config.json") -> SiteConfig                     │
│     ├-> fetch("./services.json") -> List(ServiceConfig)          │
│     │                                                            │
│     ├-> effect/clock  (Intl.DateTimeFormat via FFI)              │
│     └-> effect/health (fetch + AbortController via FFI)          │
└──────────────────────────────────────────────────────────────────┘
```

## Elm-Style Application

GleamDeck uses [Lustre](https://hexdocs.pm/lustre/), which applies the Elm architecture to Gleam. The application is defined in `src/dashboard/app.gleam`.

### Model

```gleam
pub type Model {
  Model(
    config: SiteConfig,
    config_error: Option(String),
    services: List(Service),
    load_state: LoadState,
    query: String,
    active_category: Option(String),
    now: Float,
    refreshed_at: Float,
  )
}
```

The model stores everything the view needs:

- The decoded `SiteConfig` (title, subtitle, timezone)
- Any configuration loading error
- The list of `Service` entries (config + runtime status)
- The current load state (`Loading`, `Loaded`, `LoadFailed`)
- The current search query
- The active category filter
- The current timestamp (`now`)
- The last refresh timestamp (`refreshed_at`)

### Messages

```gleam
pub type Msg {
  ConfigLoaded(Result(SiteConfig, String))
  ServicesLoaded(Result(List(ServiceConfig), String))
  SetQuery(String)
  SelectCategory(Option(String))
  RefreshAll
  HealthResult(String, Bool)
  Tick(Float)
}
```

| Message          | Triggered by                        | Effect                                                |
| ---------------- | ----------------------------------- | ----------------------------------------------------- |
| `ConfigLoaded`   | `rsvp` response for `config.json`   | Stores config or error                                |
| `ServicesLoaded` | `rsvp` response for `services.json` | Converts configs to services, kicks off `refresh_all` |
| `SetQuery`       | Search input                        | Updates `query`                                       |
| `SelectCategory` | Category pill click                 | Updates `active_category`                             |
| `RefreshAll`     | Refresh button                      | Sets all services to `Checking`, runs health checks   |
| `HealthResult`   | `effect/health` FFI callback        | Updates a single service's status and `last_checked`  |
| `Tick`           | `effect/health.set_timeout`         | Updates `now`, schedules the next tick (1 s)          |

### Init

`init` constructs the initial model with sensible defaults and batches three effects:

```gleam
#(
  model,
  effect.batch([
    tick(),
    load_config(),
    load_services(),
  ]),
)
```

### Update

`update` is a pure function from `(Model, Msg)` to `#(Model, Effect(Msg))`. All side effects are produced as `Effect(Msg)` values, never executed inline.

### View

`view` renders the dashboard as a Lustre `Element(Msg)`:

- `animated_background` — decorative blobs and grid overlay
- `header` — brand, live clock, and stat cards (total / online / checking / offline)
- `controls` — search input, category pills, refresh button
- `config_notice` — error notice if `config.json` failed to load
- `services_content` — loading, error, or the visible service grid
- `footer` — build attribution and last refresh timestamp

## Effects and FFI

Side effects are isolated in `src/effect/` and implemented through JavaScript FFIs in `src/ffi/`.

### `effect/clock.gleam`

Wraps `src/ffi/clock.mjs`:

- `now_ms()` — `Date.now()`
- `format_time(ms, timezone)` — `Intl.DateTimeFormat` with `hour:minute:second`, `h23`
- `format_date(ms, timezone)` — `Intl.DateTimeFormat` year-month-day

The FFI validates the timezone and falls back to `UTC` if it is invalid.

### `effect/health.gleam`

Wraps `src/ffi/health.mjs`:

- `health_check(url, timeout_ms, callback)` — `fetch` in `no-cors` mode with an `AbortController`-based timeout. Resolves to a `Bool`.
- `set_timeout(delay_ms, callback)` — `setTimeout` wrapper used for the 1-second `Tick` loop.

### Build-only shell FFI

`src/build/pipeline.gleam` calls `src/ffi/shell.ffi.mjs` to run the Bun bundler:

```gleam
@external(javascript, "../ffi/shell.ffi.mjs", "run_command")
fn run_command(command: String) -> Int
```

The shell FFI uses `Bun.spawnSync` when available, otherwise falls back to Node's `execSync`.

## Build Pipeline

`src/build/pipeline.gleam` orchestrates the full static build:

1. **Load configuration**
   - `config/load_config.load()` reads `config/config.toml` and decodes `[meta]` and `[site]` tables.
   - `config/load_services.load()` reads `config/services.toml` and decodes `[[service]]` blocks.
   - If `config/config.toml` is missing or invalid, a default `BuildConfig` is used and a warning is printed. `services.toml` failures are fatal.

2. **Reset `dist/`**
   - `simplifile.delete_all(["dist"])` followed by `create_directory_all("dist")`.

3. **Bundle the SPA**
   - Writes a tiny ESM entry shim to `build/dev/javascript/gleamdeck/entry.mjs`.
   - Runs `bun build <shim> --outfile dist/app.mjs --target browser --format esm --minify --sourcemap=none`.

4. **Copy static assets**
   - Walks `static/` recursively and copies every entry into `dist/`.

5. **Emit JSON**
   - `dist/config.json` — `SiteConfig` (title, subtitle, timezone)
   - `dist/services.json` — array of `ServiceConfig`

6. **Inline CSS and generate `index.html`**
   - Discovers every `*.css` file under `src/css/`.
   - Sorts paths alphabetically so the CSS cascade is deterministic.
   - Minifies each file (strips comments, collapses whitespace, trims spaces around tokens).
   - Sanitizes `</style` sequences to prevent breaking out of the inline `<style>`.
   - Concatenates all CSS into a single `<style id="gleamdeck-css">` block in `index.html`.

7. **Report**
   - Prints a summary line with service count, inlined CSS count, and timezone.

## Module Map

```text
src/
├── build/
│   └── pipeline.gleam            # Build orchestrator
├── config/
│   ├── load_config.gleam         # Reads & decodes config/config.toml
│   └── load_services.gleam       # Reads & decodes config/services.toml
├── data/
│   ├── config.gleam              # MetaConfig, SiteConfig, BuildConfig types & defaults
│   ├── services.gleam            # Service, ServiceConfig, Status types & helpers
│   └── service_collection.gleam  # Pure list ops: categories, counts, filter
├── dashboard/
│   ├── app.gleam                 # Lustre app: model, messages, update, view
│   ├── presentation.gleam        # Pure presentation helpers (status labels, host parsing)
│   └── runtime.gleam             # Loads config.json & services.json via rsvp
├── effect/
│   ├── clock.gleam               # Clock FFI bindings
│   └── health.gleam              # Health check & set_timeout FFI bindings
├── ffi/
│   ├── clock.mjs                 # Intl.DateTimeFormat wrappers
│   ├── health.mjs                # fetch + AbortController health checks
│   └── shell.ffi.mjs             # Bun/Node command runner (build only)
├── css/                          # CSS modules, inlined at build time
└── dashboard.gleam               # Browser entry point; boots Lustre onto #app
```

### Module responsibilities

| Module                            | Responsibility                                                    |
| --------------------------------- | ----------------------------------------------------------------- |
| `build/pipeline`                  | Orchestrates the entire build                                     |
| `config/load_config`              | Parses `config/config.toml` into `BuildConfig`                    |
| `config/load_services`            | Parses `config/services.toml` into `List(ServiceConfig)`          |
| `data/config`                     | Defines `MetaConfig`, `SiteConfig`, `BuildConfig` and defaults    |
| `data/services`                   | Defines `Service`, `ServiceConfig`, `Status` and basic operations |
| `data/service_collection`         | Pure operations on service lists: dedup, counts, filtering        |
| `dashboard/app`                   | Lustre `init`, `update`, `view`, and `app`                        |
| `dashboard/presentation`          | Status labels/classes and URL host extraction                     |
| `dashboard/runtime`               | Loads JSON files at runtime through `rsvp`                        |
| `dashboard` (entry)               | Calls `lustre.start` with the application                         |
| `effect/clock`, `effect/health`   | Pure Gleam bindings to the FFI modules                            |
| `ffi/clock.mjs`, `ffi/health.mjs` | Browser-side JavaScript implementations                           |
| `ffi/shell.ffi.mjs`               | Build-time subprocess runner                                      |

## Data Flow

```text
config/services.toml
        │
        ↓  (load_services)
List(ServiceConfig)
        │
        ↓  (build pipeline → JSON)
dist/services.json
        │
        ↓  (runtime.load_services_json via rsvp)
List(ServiceConfig)
        │
        ↓  (services.from_config)
List(Service)   ── Service(config, status: Checking, last_checked: 0.0)
        │
        ↓  (refresh_all → effect/health)
HealthResult(id, is_online)
        │
        ↓  (services.with_health_result)
Service(config, status: Online | Offline, last_checked: now)
        │
        ↓  (service_collection.filter)
visible: List(Service)
        │
        ↓  (view)
HTML cards
```

## Configuration Loading

`config/load_config.gleam` and `config/load_services.gleam` both use the `tom` library to parse TOML, then walk the resulting document with explicit `required_table`, `required_string`, and `required_int` helpers. Missing fields, wrong types, and empty strings produce descriptive `Result(Error, String)` values that surface as build errors.

See [docs/configuration.md](configuration.md) for the full field reference.
