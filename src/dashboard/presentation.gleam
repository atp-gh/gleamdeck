import data/services.{type Status, Checking, Offline, Online}
import gleam/string

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
