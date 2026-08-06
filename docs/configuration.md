# Configuration

GleamDeck is configured through two TOML files in the `config/` directory:

| File                   | Purpose                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------- |
| `config/config.toml`   | Document metadata, language, favicon, dashboard headings, timezone, and health-check behavior |
| `config/services.toml` | Repeated `[[service]]` blocks describing each dashboard entry                                 |

Both files are parsed at build time by Gleam decoders and emitted as JSON for the browser to consume.

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
subtitle = "My self-hosted services"
timezone = "UTC"
health_check = true
```

### `[meta]`: document-level build configuration

| Field         | Type   | Required | Description                                                      |
| ------------- | ------ | -------- | ---------------------------------------------------------------- |
| `title`       | String | Yes      | Content of the HTML `<title>` element                            |
| `description` | String | Yes      | Content of `<meta name="description">` for SEO and link previews |
| `favicon`     | String | Yes      | Path to the favicon, relative to `dist/`                         |
| `language`    | String | Yes      | Value of the HTML `lang` attribute, such as `en` or `zh`         |

### `[site]`: dashboard runtime configuration

| Field          | Type    | Required | Description                                                                                                 |
| -------------- | ------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `title`        | String  | Yes      | Main dashboard heading shown in the header                                                                  |
| `subtitle`     | String  | Yes      | Subtitle shown beneath the title                                                                            |
| `timezone`     | String  | No       | IANA timezone used by the live clock. If omitted or empty, the browser timezone is used                     |
| `health_check` | Boolean | Yes      | Enables or disables service reachability checks, status indicators, status statistics, and refresh controls |

### Timezone handling

When `timezone` is omitted or set to an empty string, GleamDeck uses the browser's current timezone:

```toml
[site]
title = "My Gleam Deck"
subtitle = "My self-hosted services"
health_check = true
```

You can also specify an IANA timezone explicitly:

```toml
timezone = "Asia/Shanghai"
```

The configured timezone is validated at runtime in `src/ffi/clock.mjs`. Invalid timezone identifiers log a warning and fall back to `UTC`:

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

Common IANA timezone identifiers include:

- `UTC`
- `Asia/Shanghai`
- `America/New_York`
- `Europe/London`

### Health checks

The `health_check` field controls whether the browser probes configured services.

```toml
health_check = true
```

When `health_check = true`:

- Each service is checked after both configuration files have loaded.
- A service's `health_url` is checked when provided.
- If `health_url` is omitted, the service's main `url` is checked instead.
- Cards show `checking`, `online`, or `offline` status.
- The header shows reachable, probing, and down counts.
- The refresh button and last-refresh timestamp are displayed.

When `health_check = false`:

- No automatic or manual health requests are sent.
- Service cards do not show health status.
- Health-related statistics and the refresh button are hidden.
- The footer does not show the last-refresh timestamp.

`health_check` is currently required in `config/config.toml`. If the application falls back to its built-in site configuration, health checks are enabled by default.

### Defaults

If `config/config.toml` cannot be read or decoded and the build uses the defaults from `data/config.gleam`, the following values apply:

| Field               | Default value                      |
| ------------------- | ---------------------------------- |
| `meta.title`        | `"Gleam Deck"`                     |
| `meta.description`  | `"Self-hosted services dashboard"` |
| `meta.favicon`      | `"images/gleamdeck.avif"`          |
| `meta.language`     | `"en"`                             |
| `site.title`        | `"Gleam Deck"`                     |
| `site.subtitle`     | `"Self-hosted services dashboard"` |
| `site.timezone`     | Browser timezone                   |
| `site.health_check` | `true`                             |

## `config/services.toml`

Services are defined as repeated `[[service]]` blocks. The order of the blocks is preserved in the generated `services.json`.

Only `id`, `name`, and `url` are required. All display metadata and the dedicated health-check URL are optional.

```toml
[[service]]
id = "jellyfin"
name = "Jellyfin"
url = "https://jellyfin.example.com"
health_url = "https://jellyfin.example.com"
icon = "sh:jellyfin"
description = "Streaming media server for movies, shows and music."
category = "Media"
port = 8096
```

A minimal service entry is also valid:

```toml
[[service]]
id = "jellyfin"
name = "Jellyfin"
url = "https://jellyfin.example.com"
```

### Service fields

| Field         | Type    | Required | Description                                                                                                          |
| ------------- | ------- | -------- | -------------------------------------------------------------------------------------------------------------------- |
| `id`          | String  | Yes      | Stable identifier used by the dashboard. It should be unique                                                         |
| `name`        | String  | Yes      | Display name shown on the card                                                                                       |
| `url`         | String  | Yes      | URL opened in a new tab when the card is selected                                                                    |
| `health_url`  | String  | No       | URL used for reachability checks. Falls back to `url` when omitted or empty                                          |
| `icon`        | String  | No       | Text, emoji, local image, remote image, or icon-provider reference. A `?` placeholder is shown when omitted or empty |
| `description` | String  | No       | Short description shown beneath the service name. Hidden when omitted or empty                                       |
| `category`    | String  | No       | Category used to generate filter pills. Uncategorized services still appear under `All`                              |
| `port`        | Integer | No       | Port displayed on the card. Values from `1` to `65535` are shown. Omit it or use `0` to hide it                      |

Empty optional string values are treated as absent:

```toml
health_url = ""
icon = ""
description = ""
category = ""
```

### Health-check URL fallback

If `health_url` is omitted, the dashboard checks `url` instead:

```toml
[[service]]
id = "forgejo"
name = "Forgejo"
url = "https://git.example.com"
```

This fallback is only used when `[site].health_check` is `true`.

### Icons

The optional `icon` field supports:

- Emoji or text
- Local image paths
- Remote image URLs
- Icon-provider references

If `icon` is omitted or empty, the dashboard displays `?` as a text placeholder.

#### Emoji or text

```toml
icon = "🎬"
icon = "Hi"
```

#### Local image paths

```toml
icon = "icons/jellyfin.webp"
# or
icon = "static/icons/jellyfin.webp"
```

Place the corresponding file in `static/icons/`. During the build it will be available as:

```text
dist/icons/jellyfin.webp
```

Supported local image extensions are:

- `.svg`
- `.png`
- `.webp`
- `.avif`
- `.jpg`
- `.jpeg`
- `.gif`
- `.ico`

#### Remote image URLs

```toml
icon = "https://example.com/icon.svg"
```

Both `https://` and `http://` image URLs are recognized. Prefer HTTPS to avoid mixed-content blocking when the dashboard is served over HTTPS.

#### Icon providers

GleamDeck supports four icon providers:

- `sh:`: [selfh.st icons](https://selfh.st/icons/)
- `si:`: [Simple Icons](https://simpleicons.org/)
- `hl:`: [Homarr Dashboard Icons](https://github.com/homarr-labs/dashboard-icons)
- `mdi:`: [Material Design Icons](https://pictogrammers.com/library/mdi/)

Examples:

```toml
icon = "sh:jellyfin"
icon = "si:github"
icon = "hl:home-assistant"
icon = "mdi:server"
```

### Descriptions

The `description` field is optional. When it is omitted or empty, the card does not render a description paragraph.

```toml
[[service]]
id = "router"
name = "Router"
url = "https://router.example.com"
icon = "mdi:router-wireless"
category = "Infrastructure"
```

### Categories

Categories are derived automatically from non-empty `category` values across all services. There is no separate category registry. Every distinct category becomes a filter pill in the UI.

Services without a category:

- Remain visible under the `All` filter.
- Do not create an empty category pill.
- Are hidden when a specific category filter is active.

Category matching is exact and case-sensitive. For example, `Media` and `media` create separate categories.

### Hiding the port

Omit `port` or set it to `0` to hide the port badge:

```toml
[[service]]
id = "external-link"
name = "External Link"
url = "https://example.com"
icon = "🔗"
description = "A link without a port."
category = "Misc"
port = 0
```

Valid port values range from `0` through `65535`. Internally, `0` is normalized to an absent port.

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
category = "Infrastructure"

[[service]]
id = "external-docs"
name = "Documentation"
url = "https://example.com/docs"
```

## Generated output

The build pipeline emits two JSON files consumed by the browser.

### `dist/config.json`

With an explicit timezone:

```json
{
  "title": "My Gleam Deck",
  "subtitle": "My self-hosted services",
  "timezone": "UTC",
  "health_check": true
}
```

When `timezone` is omitted, its optional value is emitted as `null`:

```json
{
  "title": "My Gleam Deck",
  "subtitle": "My self-hosted services",
  "timezone": null,
  "health_check": false
}
```

The browser decoder accepts either a string or `null` for `timezone`.

### `dist/services.json`

Optional service fields may be emitted as `null` when they are absent:

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
  },
  {
    "id": "external-docs",
    "name": "Documentation",
    "url": "https://example.com/docs",
    "health_url": null,
    "icon": null,
    "description": null,
    "category": null,
    "port": null
  }
]
```

The browser decoder accepts either the expected value or `null` for `health_url`, `icon`, `description`, `category`, and `port`.

## Parser limitations

The configuration parser uses the [`tom`](https://hexdocs.pm/tom/) library, while the GleamDeck schema accepts only the structures documented above.

### Supported by the GleamDeck schema

- Repeated `[[service]]` blocks
- `[meta]` and `[site]` tables
- String values
- Boolean values for `health_check`
- Integer values for `port`
- Optional service fields
- An optional `timezone` field

### Not supported by the GleamDeck schema

Avoid configuration structures that are not represented by the decoders, including:

- Additional nested configuration tables
- Arrays where a scalar string, boolean, or integer is expected
- Inline tables where a scalar value is expected
- Non-string values for string fields
- Non-boolean values for `health_check`
- Non-integer values for `port`

Keep each assignment on a single line for readability:

```toml
name = "Forgejo"
```

## Error handling

Invalid or incomplete configuration produces an explanatory message. Examples include:

- `Missing required field 'id'`
- `Missing required field 'health_check'`
- `Field 'health_check' must be a boolean, but got ...`
- `Field 'port' must be an integer, but got ...`
- `Field 'port' must be between 0 and 65535`
- `Field 'name' must not be empty`
- `services.toml does not contain any [[service]] entries`
- `Expected [[service]] entries, but 'service' has value ...`

For `config/config.toml`, the surrounding build pipeline may fall back to `data/config.gleam` defaults when loading or decoding fails. For `config/services.toml`, `load()` treats read and decode failures as fatal.

## Validation tips

- Use stable, unique, lowercase `id` values because they identify services during health-check updates.
- Keep `url` and `health_url` reachable from the browser. Internal IP addresses, self-signed certificates, and HTTP endpoints used from an HTTPS dashboard may be blocked by browser security rules.
- Omit `health_url` when the service's main `url` is suitable for health checks.
- Set `health_check = false` if the dashboard should behave only as a launcher and must not probe service URLs.
- Avoid exposing private hostnames, internal addresses, tokens, or credentials. Everything emitted to `config.json` and `services.json` is visible to dashboard visitors.
- Prefer HTTPS for service links, health-check URLs, and remote icons to avoid mixed-content blocking.
- Use consistent category capitalization because category matching is exact and case-sensitive.
