//// Complete static-site build pipeline.
////
//// Responsibilities:
//// - Read services.toml
//// - Decode service configuration through config/load_services
//// - Reset the output directory
//// - Bundle the Lustre SPA
//// - Copy static assets
//// - Add inner css
//// - Generate services.json and index.html
////
//// Run with:
////
////   gleam run -m build/pipeline

import config/load_config
import config/load_services
import data/config.{type BuildConfig, type MetaConfig, type SiteConfig} as app_config
import data/services.{type ServiceConfig}
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/string
import simplifile

const dist_dir = "dist"

const static_dir = "static"

const css_dir = "src/css"

const css_entry_path = "src/css/.gleamdeck-entry.css"

const bundled_css_path = "dist/.gleamdeck-bundle.css"

pub fn main() -> Nil {
  let config = load_build_config()
  let services = load_services.load()
  let css_files = discover_css_files()

  reset_dist()
  bundle_spa()
  let css = bundle_css(css_files)
  copy_directory_contents(static_dir, dist_dir)

  write_file(dist_dir <> "/config.json", site_config_json(config.site))

  write_file(dist_dir <> "/services.json", services_json(services))

  write_file(dist_dir <> "/index.html", index_html(config.meta, css))

  io.println(
    "✓ built "
    <> dist_dir
    <> "/ ("
    <> int.to_string(list.length(services))
    <> " services, "
    <> int.to_string(list.length(css_files))
    <> " CSS files inlined, timezone "
    <> config.site.timezone
    <> ", pure ESM)",
  )
}

fn reset_dist() -> Nil {
  case simplifile.delete_all([dist_dir]) {
    Ok(_) -> Nil

    Error(error) -> panic_file_error("Could not remove " <> dist_dir, error)
  }

  case simplifile.create_directory_all(dist_dir) {
    Ok(_) -> Nil

    Error(error) -> panic_file_error("Could not create " <> dist_dir, error)
  }
}

fn bundle_spa() -> Nil {
  let shim = "import { main } from \"./dashboard.mjs\";\n" <> "main();\n"

  let shim_path = "build/dev/javascript/gleamdeck/entry.mjs"

  case simplifile.write(to: shim_path, contents: shim) {
    Error(error) -> panic_file_error("Could not write SPA entry shim", error)

    Ok(_) -> {
      let command =
        "bun build "
        <> shim_path
        <> " --outfile "
        <> dist_dir
        <> "/app.mjs"
        <> " --target browser"
        <> " --format esm"
        <> " --minify"
        <> " --sourcemap=none"

      case run_command(command) {
        0 -> Nil

        exit_code -> {
          let message =
            "Could not bundle SPA with Bun. Command exited with code "
            <> int.to_string(exit_code)
            <> ": "
            <> command

          panic as message
        }
      }
    }
  }
}

/// Bundle, minify, and return all discovered CSS.
///
/// A temporary entry file is created inside `src/css`, allowing every import
/// path to remain relative to the original CSS directory. Bun parses and
/// minifies the complete stylesheet while preserving the deterministic order
/// supplied by `discover_css_files`.
fn bundle_css(css_files: List(String)) -> String {
  case css_files {
    [] -> ""

    _ -> {
      let entry_css =
        css_files
        |> list.map(css_import_rule)
        |> string.join("")

      write_file(css_entry_path, entry_css)

      let command =
        "bun build "
        <> css_entry_path
        <> " --outfile "
        <> bundled_css_path
        <> " --target browser"
        <> " --minify"
        <> " --sourcemap=none"

      case run_command(command) {
        0 -> {
          let bundled_css = case simplifile.read(from: bundled_css_path) {
            Ok(css) ->
              css
              |> sanitize_style_text
              |> string.trim

            Error(error) ->
              panic_file_error(
                "Could not read bundled CSS from " <> bundled_css_path,
                error,
              )
          }

          delete_temporary_css_files()

          bundled_css
        }

        exit_code -> {
          delete_temporary_css_files()

          let message =
            "Could not bundle CSS with Bun. Command exited with code "
            <> int.to_string(exit_code)
            <> ": "
            <> command

          panic as message
        }
      }
    }
  }
}

@external(javascript, "../ffi/shell.ffi.mjs", "run_command")
fn run_command(command: String) -> Int

// fn copy_css_files() -> Nil {
//   case simplifile.is_directory(css_dir) {
//     Ok(True) -> copy_directory(css_dir, dist_dir <> "/css")
//
//     Ok(False) -> Nil
//
//     Error(error) ->
//       panic_file_error("Could not inspect directory " <> css_dir, error)
//   }
// }

/// Copy the contents of a directory directly into another directory.
///
/// `simplifile.copy_directory` copies a directory as a single entry. Static
/// assets need to appear directly under `dist/`, so every top-level entry is
/// copied separately.
fn copy_directory_contents(source: String, destination: String) -> Nil {
  case simplifile.read_directory(source) {
    Ok(entries) ->
      list.each(entries, fn(entry) {
        let source_path = source <> "/" <> entry
        let destination_path = destination <> "/" <> entry

        copy_path(source_path, destination_path)
      })

    Error(error) ->
      io.println(
        "Warning: could not read "
        <> source
        <> ": "
        <> simplifile.describe_error(error),
      )
  }
}

fn copy_path(source: String, destination: String) -> Nil {
  case simplifile.is_directory(source) {
    Ok(True) -> copy_directory(source, destination)

    Ok(False) -> copy_file(source, destination)

    Error(error) -> panic_file_error("Could not inspect " <> source, error)
  }
}

fn copy_directory(source: String, destination: String) -> Nil {
  case simplifile.create_directory_all(destination) {
    Ok(_) -> Nil

    Error(error) ->
      panic_file_error("Could not create directory " <> destination, error)
  }

  case simplifile.get_files(source) {
    Ok(files) ->
      list.each(files, fn(source_path) {
        let relative_path = remove_directory_prefix(source_path, source)

        let destination_path = destination <> "/" <> relative_path

        create_parent_directory(destination_path)
        copy_file(source_path, destination_path)
      })

    Error(error) ->
      panic_file_error("Could not read directory " <> source, error)
  }
}

fn copy_file(source: String, destination: String) -> Nil {
  create_parent_directory(destination)

  case simplifile.copy_file(at: source, to: destination) {
    Ok(_) -> Nil

    Error(error) ->
      panic_file_error(
        "Could not copy " <> source <> " to " <> destination,
        error,
      )
  }
}

fn remove_directory_prefix(path: String, directory: String) -> String {
  let prefix = directory <> "/"

  case string.starts_with(path, prefix) {
    True -> string.drop_start(path, string.length(prefix))

    False -> path
  }
}

fn create_parent_directory(path: String) -> Nil {
  let segments = string.split(path, "/")
  let parent_count = list.length(segments) - 1

  case list.take(segments, parent_count) {
    [] -> Nil

    parents -> {
      let directory = string.join(parents, "/")

      case simplifile.create_directory_all(directory) {
        Ok(_) -> Nil

        Error(error) ->
          panic_file_error("Could not create directory " <> directory, error)
      }
    }
  }
}

fn write_file(path: String, content: String) -> Nil {
  create_parent_directory(path)

  case simplifile.write(to: path, contents: content) {
    Ok(_) -> Nil

    Error(error) -> panic_file_error("Could not write " <> path, error)
  }
}

fn load_build_config() -> BuildConfig {
  case load_config.load() {
    Ok(config) -> config

    Error(reason) -> {
      io.println(
        "Warning: could not load config/config.toml: "
        <> reason
        <> ". Using default configuration.",
      )

      app_config.default_build()
    }
  }
}

fn site_config_json(config: SiteConfig) -> String {
  json.object([
    #("title", json.string(config.title)),
    #("subtitle", json.string(config.subtitle)),
    #("timezone", json.string(config.timezone)),
  ])
  |> json.to_string
  |> string.append("\n")
}

fn services_json(services: List(ServiceConfig)) -> String {
  services
  |> json.array(of: service_json)
  |> json.to_string
  |> string.append("\n")
}

fn service_json(service: ServiceConfig) -> json.Json {
  json.object([
    #("id", json.string(service.id)),
    #("name", json.string(service.name)),
    #("url", json.string(service.url)),
    #("health_url", json.string(service.health_url)),
    #("icon", json.string(service.icon)),
    #("description", json.string(service.description)),
    #("category", json.string(service.category)),
    #("port", json.int(service.port)),
  ])
}

/// Discover every CSS file under `src/css`.
///
/// `simplifile.get_files` recursively returns files from nested directories.
/// Sorting ensures that the CSS cascade order is deterministic across builds.
fn discover_css_files() -> List(String) {
  case simplifile.is_directory(css_dir) {
    Ok(True) ->
      case simplifile.get_files(css_dir) {
        Ok(files) ->
          files
          |> list.filter(fn(path) {
            string.ends_with(path, ".css") && path != css_entry_path
          })
          |> list.sort(fn(first, second) { string.compare(first, second) })

        Error(error) ->
          panic_file_error(
            "Could not discover CSS files under " <> css_dir,
            error,
          )
      }

    Ok(False) -> []

    Error(error) ->
      panic_file_error("Could not inspect CSS directory " <> css_dir, error)
  }
}

fn css_import_rule(path: String) -> String {
  let relative_path = remove_directory_prefix(path, css_dir)

  let quoted_path =
    json.string("./" <> relative_path)
    |> json.to_string

  "@import " <> quoted_path <> ";\n"
}

fn delete_temporary_css_files() -> Nil {
  case simplifile.delete_all([css_entry_path, bundled_css_path]) {
    Ok(_) -> Nil

    Error(error) ->
      io.println(
        "Warning: could not remove temporary CSS build files: "
        <> simplifile.describe_error(error),
      )
  }
}

/// Prevent CSS content from terminating the generated inline style element.
fn sanitize_style_text(css: String) -> String {
  css
  |> string.replace("</style", "<\\/style")
}

fn index_html(meta: MetaConfig, css: String) -> String {
  "<!doctype html>"
  <> "<html lang=\""
  <> meta.language
  <> "\">"
  <> "<head>"
  <> "<meta charset=\"UTF-8\">"
  <> "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
  <> "<meta name=\"color-scheme\" content=\"dark\">"
  <> "<title>"
  <> meta.title
  <> "</title>"
  <> "<meta name='description' content='"
  <> meta.description
  <> "'>"
  <> "<link rel=\"icon\" type=\"image/x-icon\" href=\""
  <> meta.favicon
  <> "\">"
  <> "<style id=\"gleamdeck-css\">"
  <> css
  <> "</style>"
  <> "</head>"
  <> "<body>"
  <> "<div id=\"app\"></div>"
  <> "<script type=\"module\" src=\"app.mjs\"></script>"
  <> "</body>"
  <> "</html>"
}

fn panic_file_error(operation: String, error: simplifile.FileError) -> return {
  let message = operation <> ": " <> simplifile.describe_error(error)

  panic as message
}
