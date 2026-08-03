# Configuration

GleamDeck is configured entirely through two TOML files in the `config/` directory:

| File                   | Purpose                                                       |
| ---------------------- | ------------------------------------------------------------- |
| `config/config.toml`   | Document metadata, language, favicon, and dashboard headings  |
| `config/services.toml` | Repeated `[[service]]` blocks describing each dashboard entry |

Both files are parsed at build time by small Gleam decoders and emitted as JSON for the browser to consume.

## `config/config.toml`

This file contains two tables: `[meta]` and `[site]`.

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

### `[meta]` — document-level metadata on build time

| Field         | Type   | Required | Description                                           |
| ------------- | ------ | -------- | ----------------------------------------------------- |
| `title`       | String | Yes      | HTML `<title>` element content                        |
| `description` | String | Yes      | `<meta name="description">` for SEO and link previews |
| `favicon`     | String | Yes      | Path to favicon, relative to `dist/`                  |
| `language`    | String | Yes      | HTML `lang` attribute (e.g. `en`, `zh`)               |

### `[site]` — dashboard-level configuration on runtime

| Field      | Type   | Required | Description                                                        |
| ---------- | ------ | -------- | ------------------------------------------------------------------ |
| `title`    | String | Yes      | Main dashboard heading shown in the header                         |
| `subtitle` | String | Yes      | Subtitle shown beneath the title                                   |
| `timezone` | String | Yes      | IANA timezone used by the live clock (e.g. `UTC`, `Asia/Shanghai`) |

### Timezone handling

`timezone` is validated at runtime in `src/ffi/clock.mjs`. Invalid timezones log a warning and fall back to `UTC`:

```javascript
function valid_timezone(timezone) {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: timezone }).format();
    return timezone;
  } catch {
    console.warn(`Invalid timezone "${timezone}", falling back to UTC.`);
    return "UTC";
  }
}
```

Use any IANA timezone identifier, for example:

- `UTC`
- `Asia/Shanghai`
- `America/New_York`
- `Europe/London`

### Defaults

If `config/config.toml` cannot be read or decoded, the build emits a warning and uses defaults from `data/config.gleam`:

| Field              | Default value                      |
| ------------------ | ---------------------------------- |
| `meta.title`       | `"Gleam Deck"`                     |
| `meta.description` | `"Self-hosted services dashboard"` |
| `meta.favicon`     | `"images/gleamdeck.avif"`          |
| `meta.language`    | `"en"`                             |
| `site.title`       | `"Gleam Deck"`                     |
| `site.subtitle`    | `"Self-hosted services dashboard"` |
| `site.timezone`    | `"UTC"`                            |

## `config/services.toml`

Services are defined as repeated `[[service]]` blocks. The order of blocks is preserved in the generated `services.json`.

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

### Service fields

| Field         | Type    | Required | Description                                                    |
| ------------- | ------- | -------- | -------------------------------------------------------------- |
| `id`          | String  | Yes      | Stable identifier used by the dashboard; must be unique        |
| `name`        | String  | Yes      | Display name shown on the card                                 |
| `url`         | String  | Yes      | URL the card links to (opened in a new tab)                    |
| `health_url`  | String  | Yes      | URL fetched to determine reachability (uses `no-cors`)         |
| `icon`        | String  | Yes      | Icon shown on the card; typically an emoji or single character |
| `description` | String  | Yes      | Short description shown beneath the name                       |
| `category`    | String  | Yes      | Used for category pills and filtering                          |
| `port`        | Integer | Yes      | Service port displayed on the card; use `0` to hide            |

### Categories

Categories are derived automatically from the `category` field across all services. There is no separate category registry — every distinct value becomes a filter pill in the UI.

### Hiding the port

Set `port = 0` to omit the port badge from the card:

```toml
[[service]]
id = "external-link"
name = "External Link"
url = "https://example.com"
health_url = "https://example.com"
icon = "🔗"
description = "A link without a port."
category = "Misc"
port = 0
```

### Example: multiple services

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

[[service]]
id = "forgejo"
name = "Forgejo"
url = "https://git.example.com"
health_url = "https://git.example.com"
icon = "🐙"
description = "Self-hosted Git service with CI and packages."
category = "Development"
port = 3000

[[service]]
id = "pihole"
name = "Pi-hole"
url = "https://pihole.example.com/admin"
health_url = "https://pihole.example.com"
icon = "🕳️"
description = "Network-wide ad blocking DNS sinkhole."
category = "Infrastructure"
port = 80
```

## Generated Output

The build pipeline emits two JSON files consumed by the browser.

### `dist/config.json`

```json
{
  "title": "My Gleam Deck",
  "subtitle": "My Self-hosted services",
  "timezone": "UTC"
}
```

### `dist/services.json`

```json
[
  {
    "id": "jellyfin",
    "name": "Jellyfin",
    "url": "https://jellyfin.example.com",
    "health_url": "https://jellyfin.example.com",
    "icon": "🎬",
    "description": "Streaming media server for movies, shows and music.",
    "category": "Media",
    "port": 8096
  }
]
```

## Parser Limitations

The configuration parser is intentionally small and tuned for GleamDeck's needs. It uses the [`tom`](https://hexdocs.pm/tom/) library, but the schema is restricted.

### Supported

- Repeated `[[service]]` blocks
- `[table]` sections (`[meta]`, `[site]`)
- `key = value` assignments
- Quoted string values (`"..."`)
- Integer values for `port`
- Line comments beginning with `#`
- Blank lines

### Not supported

Avoid the following TOML features:

- Multiline strings (`"""..."""`)
- Arrays of values
- Inline tables (`{ a = 1, b = 2 }`)
- Escaped TOML string sequences (e.g. `"line\nbreak"`)
- Nested tables beyond the two-level `[meta]` / `[site]` / `[[service]]` structure
- Values containing unescaped `#` characters
- Values containing additional `=` characters

### Formatting rules

Keep each assignment on a single line:

```toml
name = "Forgejo"
```

Do not write:

```toml
name = """
Forgejo
"""
```

### Error handling

Invalid or incomplete configuration causes the build to stop with an explanatory message. Examples:

- `Missing required field 'id'`
- `Field 'port' must be an integer, but got ...`
- `Field 'name' must not be empty`
- `services.toml does not contain any [[service]] entries`
- `Expected [[service]] entries, but 'service' has value ...`

For `config/config.toml` specifically, parse failures fall back to the default configuration and emit a warning so the build can still complete. For `config/services.toml`, parse failures are fatal.

## Validation Tips

- Use stable, lowercase `id` values — they are used as keys during health-check updates.
- Keep `health_url` reachable from a browser context. Internal IPs, self-signed certificates, and HTTP endpoints on HTTPS dashboards will be blocked by the browser.
- Avoid exposing private hostnames, internal addresses, tokens, or credentials — everything in `services.json` is visible to dashboard visitors.
- Prefer HTTPS for both `url` and `health_url` to avoid mixed-content blocking.
