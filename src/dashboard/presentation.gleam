import data/services.{type Status, Checking, Offline, Online}
import gleam/string

const selfhst_icon_base = "https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/"

const simpleicons_icon_base = "https://cdn.simpleicons.org/"

const homelab_icon_base = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/"

const mdi_icon_base = "https://cdn.jsdelivr.net/npm/@mdi/svg@7.4.47/svg/"

pub type IconSource {
  ImageIcon(String)
  TextIcon(String)
}

pub fn icon_source(value: String) -> IconSource {
  let icon = string.trim(value)

  case icon {
    "" -> TextIcon("?")

    _ ->
      case string.split_once(icon, ":") {
        Ok(#("sh", reference)) -> selfhst_icon(reference)

        Ok(#("si", reference)) -> simpleicons_icon(reference)

        Ok(#("hl", reference)) -> homelab_icon(reference)

        Ok(#("mdi", reference)) -> mdi_icon(reference)

        _ -> fallback_icon(icon)
      }
  }
}

fn fallback_icon(icon: String) -> IconSource {
  case is_remote_icon(icon), is_local_icon(icon) {
    True, _ -> ImageIcon(icon)

    False, True -> ImageIcon(local_icon_url(icon))

    False, False -> TextIcon(icon)
  }
}

fn selfhst_icon(icon: String) -> IconSource {
  let reference =
    icon
    |> string.trim

  case reference {
    "" -> TextIcon("?")
    _ -> ImageIcon(selfhst_icon_base <> reference <> ".webp")
  }
}

fn simpleicons_icon(icon: String) -> IconSource {
  let reference =
    icon
    |> string.trim

  case reference {
    "" -> TextIcon("?")
    _ -> ImageIcon(simpleicons_icon_base <> reference)
  }
}

fn homelab_icon(icon: String) -> IconSource {
  let reference =
    icon
    |> string.trim

  case reference {
    "" -> TextIcon("?")
    _ -> ImageIcon(homelab_icon_base <> reference <> ".webp")
  }
}

fn mdi_icon(icon: String) -> IconSource {
  let reference =
    icon
    |> string.trim

  case reference {
    "" -> TextIcon("?")
    _ -> ImageIcon(mdi_icon_base <> reference <> ".svg")
  }
}

fn is_remote_icon(value: String) -> Bool {
  string.starts_with(value, "https://") || string.starts_with(value, "http://")
}

fn is_local_icon(value: String) -> Bool {
  let path =
    value
    |> remove_query
    |> string.lowercase

  string.ends_with(path, ".svg")
  || string.ends_with(path, ".png")
  || string.ends_with(path, ".webp")
  || string.ends_with(path, ".avif")
  || string.ends_with(path, ".jpg")
  || string.ends_with(path, ".jpeg")
  || string.ends_with(path, ".gif")
  || string.ends_with(path, ".ico")
}

fn local_icon_url(path: String) -> String {
  let normalized = case string.starts_with(path, "static/") {
    True -> string.drop_start(path, string.length("static/"))
    False -> path
  }

  case string.starts_with(normalized, "./") {
    True -> normalized
    False -> "./" <> normalized
  }
}

fn remove_query(value: String) -> String {
  case string.split(value, "?") {
    [path, ..] -> path
    _ -> value
  }
}

pub fn status_class(status: Status) -> String {
  case status {
    Checking -> "checking"
    Online -> "online"
    Offline -> "offline"
  }
}

pub fn status_label(status: Status) -> String {
  case status {
    Checking -> "checking"
    Online -> "online"
    Offline -> "offline"
  }
}

pub fn host_of(url: String) -> String {
  let stripped = case string.split(url, "://") {
    [_, rest] -> rest
    other -> string.join(other, "")
  }

  case string.split(stripped, "/") {
    [host, ..] -> host
    _ -> stripped
  }
}
