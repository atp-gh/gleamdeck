//// Parsing and decoding for services.toml.

import data/services.{type ServiceConfig, ServiceConfig}
import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string
import tom.{type Toml}

pub fn decode(source: String) -> Result(List(ServiceConfig), String) {
  use document <- result.try(
    tom.parse(source)
    |> result.map_error(format_parse_error),
  )

  case dict.get(document, "service") {
    Ok(tom.ArrayOfTables(tables)) ->
      tables
      |> list.index_map(fn(table, index) {
        decode_service(table)
        |> result.map_error(fn(reason) {
          "Invalid [[service]] entry at index "
          <> string.inspect(index)
          <> ": "
          <> reason
        })
      })
      |> result.all

    Ok(value) ->
      Error(
        "Expected [[service]] entries, but `service` has value "
        <> string.inspect(value),
      )

    Error(_) -> Error("services.toml does not contain any [[service]] entries")
  }
}

fn decode_service(table: Dict(String, Toml)) -> Result(ServiceConfig, String) {
  use id <- result.try(required_string(table, "id"))
  use name <- result.try(required_string(table, "name"))
  use url <- result.try(required_string(table, "url"))
  use health_url <- result.try(required_string(table, "health_url"))
  use icon <- result.try(required_string(table, "icon"))
  use description <- result.try(required_string(table, "description"))
  use category <- result.try(required_string(table, "category"))
  use port <- result.try(required_int(table, "port"))

  Ok(ServiceConfig(
    id:,
    name:,
    url:,
    health_url:,
    icon:,
    description:,
    category:,
    port:,
  ))
}

fn required_string(
  table: Dict(String, Toml),
  field: String,
) -> Result(String, String) {
  case dict.get(table, field) {
    Ok(tom.String(value)) -> Ok(value)

    Ok(value) ->
      Error(
        "Field `"
        <> field
        <> "` must be a string, but got "
        <> string.inspect(value),
      )

    Error(_) -> Error("Missing required field `" <> field <> "`")
  }
}

fn required_int(
  table: Dict(String, Toml),
  field: String,
) -> Result(Int, String) {
  case dict.get(table, field) {
    Ok(tom.Int(value)) -> Ok(value)

    Ok(value) ->
      Error(
        "Field `"
        <> field
        <> "` must be an integer, but got "
        <> string.inspect(value),
      )

    Error(_) -> Error("Missing required field `" <> field <> "`")
  }
}

fn format_parse_error(error: tom.ParseError) -> String {
  "Could not parse services.toml: " <> string.inspect(error)
}
