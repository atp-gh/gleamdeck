//// Reading and decoding for config/config.toml.

import data/config.{
  type BuildConfig, type MetaConfig, type SiteConfig, BuildConfig, MetaConfig,
  SiteConfig,
}
import gleam/dict.{type Dict}
import gleam/result
import gleam/string
import simplifile
import tom.{type Toml}

const config_path = "config/config.toml"

pub fn load() -> Result(BuildConfig, String) {
  use source <- result.try(read_config(config_path))
  decode(source)
}

pub fn read_source() -> Result(String, String) {
  read_config(config_path)
}

pub fn decode(source: String) -> Result(BuildConfig, String) {
  use document <- result.try(
    tom.parse(source)
    |> result.map_error(format_parse_error),
  )

  use meta_table <- result.try(required_table(document, "meta"))
  use site_table <- result.try(required_table(document, "site"))

  use meta <- result.try(decode_meta(meta_table))
  use site <- result.try(decode_site(site_table))

  Ok(BuildConfig(meta:, site:))
}

fn decode_meta(table: Dict(String, Toml)) -> Result(MetaConfig, String) {
  use title <- result.try(required_string(table, "title"))
  use description <- result.try(required_string(table, "description"))
  use language <- result.try(required_string(table, "language"))
  use favicon <- result.try(required_string(table, "favicon"))

  Ok(MetaConfig(title:, description:, language:, favicon:))
}

fn decode_site(table: Dict(String, Toml)) -> Result(SiteConfig, String) {
  use title <- result.try(required_string(table, "title"))
  use subtitle <- result.try(required_string(table, "subtitle"))
  use timezone <- result.try(required_string(table, "timezone"))

  Ok(SiteConfig(title:, subtitle:, timezone:))
}

fn read_config(path: String) -> Result(String, String) {
  case simplifile.read(from: path) {
    Ok(source) -> Ok(source)

    Error(error) ->
      Error(
        "Could not read " <> path <> ": " <> simplifile.describe_error(error),
      )
  }
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
