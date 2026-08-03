//// Reading and decoding for config/config.toml.

import data/config.{type AppConfig, AppConfig}
import gleam/dict.{type Dict}
import gleam/result
import gleam/string
import simplifile
import tom.{type Toml}

const config_path = "config/config.toml"

/// Read and decode the application configuration.
///
/// The configuration path is intentionally fixed inside this module so callers
/// do not need to know where the configuration file is stored.
pub fn load() -> AppConfig {
  config_path
  |> read_config
  |> decode_app_config
}

/// Read the raw application configuration source.
///
/// Most callers should use `load`. This function is public for build-time code
/// that needs access to the original TOML source.
pub fn read_source() -> String {
  read_config(config_path)
}

/// Decode application configuration from TOML source.
///
/// This remains public so tests and tools can decode in-memory configuration
/// without accessing the filesystem.
pub fn decode_app_config(source: String) -> AppConfig {
  case decode(source) {
    Ok(config) -> config

    Error(reason) -> {
      let message = "Invalid " <> config_path <> ": " <> reason
      panic as message
    }
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

fn decode(source: String) -> Result(AppConfig, String) {
  use document <- result.try(
    tom.parse(source)
    |> result.map_error(format_parse_error),
  )

  use site <- result.try(required_table(document, "site"))

  use title <- result.try(required_string(site, "title"))
  use description <- result.try(required_string(site, "description"))
  use language <- result.try(required_string(site, "language"))
  use timezone <- result.try(required_string(site, "timezone"))
  use favicon <- result.try(required_string(site, "favicon"))

  Ok(AppConfig(title:, description:, language:, timezone:, favicon:))
}

fn required_table(
  document: Dict(String, Toml),
  field: String,
) -> Result(Dict(String, Toml), String) {
  case dict.get(document, field) {
    Ok(tom.Table(table)) -> Ok(table)

    Ok(value) ->
      Error(
        "Field `"
        <> field
        <> "` must be a table, but got "
        <> string.inspect(value),
      )

    Error(_) -> Error("Missing required table `[" <> field <> "]`")
  }
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

fn format_parse_error(error: tom.ParseError) -> String {
  "Could not parse " <> config_path <> ": " <> string.inspect(error)
}
