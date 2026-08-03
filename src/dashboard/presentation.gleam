import data/services.{type Status, Checking, Offline, Online}
import gleam/string

const selfhst_icon_base = "https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/"

pub type IconSource {
  RemoteIcon(String)
  TextIcon(String)
}

pub fn icon_source(value: String) -> IconSource {
  let icon = string.trim(value)

  case string.starts_with(icon, "sh:") {
    True -> {
      let reference =
        icon
        |> string.drop_start(3)
        |> string.trim

      case reference {
        "" -> TextIcon("?")
        _ -> RemoteIcon(selfhst_icon_base <> reference <> ".webp")
      }
    }

    False ->
      case is_remote_icon(icon) {
        True -> RemoteIcon(icon)
        False -> TextIcon(icon)
      }
  }
}

fn is_remote_icon(value: String) -> Bool {
  string.starts_with(value, "https://") || string.starts_with(value, "http://")
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
