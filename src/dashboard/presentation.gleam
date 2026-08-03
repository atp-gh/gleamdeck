import data/services.{type Status, Checking, Offline, Online}
import gleam/string

const selfhst_icon_base = "https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/"

pub type IconSource {
  ImageIcon(String)
  TextIcon(String)
}

pub fn icon_source(value: String) -> IconSource {
  let icon = string.trim(value)

  case icon {
    "" -> TextIcon("?")

    _ ->
      case string.starts_with(icon, "sh:") {
        True -> selfhst_icon(icon)

        False ->
          case is_remote_icon(icon) {
            True -> ImageIcon(icon)

            False ->
              case is_local_icon(icon) {
                True -> ImageIcon(local_icon_url(icon))
                False -> TextIcon(icon)
              }
          }
      }
  }
}

fn selfhst_icon(icon: String) -> IconSource {
  let reference =
    icon
    |> string.drop_start(3)
    |> string.trim

  case reference {
    "" -> TextIcon("?")
    _ -> ImageIcon(selfhst_icon_base <> reference <> ".webp")
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
