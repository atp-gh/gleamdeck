//// Pure collection operations for service lists.

import data/services.{type Service, type Status}
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub fn categories(items: List(Service)) -> List(String) {
  items
  |> list.filter_map(fn(service) {
    case service.config.category {
      Some(category) ->
        case string.trim(category) {
          "" -> Error(Nil)
          _ -> Ok(category)
        }

      None -> Error(Nil)
    }
  })
  |> dedup([])
}

fn dedup(input: List(String), acc: List(String)) -> List(String) {
  case input {
    [] -> list.reverse(acc)

    [head, ..tail] ->
      case list.contains(acc, head) {
        True -> dedup(tail, acc)
        False -> dedup(tail, [head, ..acc])
      }
  }
}

pub fn status_counts(items: List(Service)) -> Dict(Status, Int) {
  list.fold(items, dict.new(), fn(counts, service) {
    dict.upsert(counts, service.status, fn(previous) {
      case previous {
        Some(n) -> n + 1
        None -> 1
      }
    })
  })
}

pub fn filter(
  items: List(Service),
  query: String,
  active_category: Option(String),
) -> List(Service) {
  let normalized_query =
    query
    |> string.trim
    |> string.lowercase

  list.filter(items, fn(service) {
    let config = service.config

    let matches_text =
      normalized_query == ""
      || contains_case_insensitive(config.name, normalized_query)
      || optional_contains_case_insensitive(config.description, normalized_query)
      || optional_contains_case_insensitive(config.category, normalized_query)
      || contains_case_insensitive(config.url, normalized_query)

    let matches_category = case active_category, config.category {
      None, _ -> True
      Some(selected), Some(category) -> category == selected
      Some(_), None -> False
    }

    matches_text && matches_category
  })
}

fn contains_case_insensitive(value: String, query: String) -> Bool {
  value
  |> string.lowercase
  |> string.contains(query)
}

fn optional_contains_case_insensitive(
  value: Option(String),
  query: String,
) -> Bool {
  case value {
    Some(value) -> contains_case_insensitive(value, query)
    None -> False
  }
}
