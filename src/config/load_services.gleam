//// Reading and decoding for config/services.toml.

import data/services.{type ServiceConfig, ServiceConfig}
import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string
import simplifile
import tom.{type Toml}

const config_path = "config/services.toml"

/// Read and decode all configured services.
///
/// The configuration path is fixed inside this module so callers do not need
/// to pass or duplicate it.
pub fn load() -> List(ServiceConfig) {
  config_path
  |> read_config
  |> decode_or_panic
}

/// Read the raw services configuration source.
///
/// Most callers should use `load`.
pub fn read_source() -> String {
  read_config(config_path)
}

/// Decode services from TOML source.
///
/// This is useful for tests and build tools that already have TOML content.
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

fn read_config(path: String) -> String {
  case simplifile.read(from: path) {
    Ok(source) -> source

    Error(error) -> {
      let message =
        "Could not read " <> path <> ": " <> simplifile.describe_error(error)

      panic as message
    }
  }
}

fn decode_or_panic(source: String) -> List(ServiceConfig) {
  case decode(source) {
    Ok(services) -> services

    Error(reason) -> {
      let message = "Invalid " <> config_path <> ": " <> reason
      panic as message
    }
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
    Ok(tom.String(value)) ->
      case string.trim(value) {
        "" -> Error("Field `" <> field <> "` must not be empty")
        _ -> Ok(value)
      }

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
  "Could not parse " <> config_path <> ": " <> string.inspect(error)
}
