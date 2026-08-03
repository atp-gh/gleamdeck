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
import data/config.{type AppConfig}
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

pub fn main() -> Nil {
  let config = load_config.load()
  let services = load_services.load()
  let css_files = discover_css_files()

  reset_dist()
  bundle_spa()
  copy_directory_contents(static_dir, dist_dir)

  write_file(dist_dir <> "/services.json", services_json(services))
  write_file(dist_dir <> "/index.html", index_html(config, css_files))

  io.println(
    "✓ built "
    <> dist_dir
    <> "/ ("
    <> int.to_string(list.length(services))
    <> " services, "
    <> int.to_string(list.length(css_files))
    <> " CSS files inlined, timezone "
    <> config.timezone
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
          |> list.filter(fn(path) { string.ends_with(path, ".css") })
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

/// Read, minify, sanitize, and concatenate discovered CSS files.
///
/// CSS paths are supplied by `discover_css_files`, which ensures a stable
/// alphabetical cascade order.
fn inline_css(css_files: List(String)) -> String {
  css_files
  |> list.map(fn(path) {
    case simplifile.read(from: path) {
      Ok(css) ->
        css
        |> minify_css
        |> sanitize_style_text

      Error(error) ->
        panic_file_error("Could not read CSS file " <> path, error)
    }
  })
  |> string.join("")
}

/// Prevent CSS content from terminating the generated inline style element.
fn sanitize_style_text(css: String) -> String {
  css
  |> string.replace("</style", "<\\/style")
}

type CssScanState {
  CssOutside
  CssComment
  CssString(quote: String, escaped: Bool)
}

/// Minify CSS while preserving quoted strings.
fn minify_css(css: String) -> String {
  css
  |> strip_css_comments
  |> collapse_css_whitespace
  |> trim_css_spaces_around_tokens
  |> string.trim
}

fn strip_css_comments(css: String) -> String {
  css
  |> string.to_graphemes
  |> strip_css_comments_loop(CssOutside, [])
  |> list.reverse
  |> string.join("")
}

fn strip_css_comments_loop(
  chars: List(String),
  state: CssScanState,
  acc: List(String),
) -> List(String) {
  case chars {
    [] -> acc

    [char, ..rest] ->
      case state {
        CssOutside ->
          case char {
            "/" ->
              case rest {
                ["*", ..tail] -> strip_css_comments_loop(tail, CssComment, acc)

                _ -> strip_css_comments_loop(rest, CssOutside, [char, ..acc])
              }

            "\"" ->
              strip_css_comments_loop(rest, CssString("\"", False), [
                char,
                ..acc
              ])

            "'" ->
              strip_css_comments_loop(rest, CssString("'", False), [char, ..acc])

            _ -> strip_css_comments_loop(rest, CssOutside, [char, ..acc])
          }

        CssComment ->
          case char {
            "*" ->
              case rest {
                ["/", ..tail] -> strip_css_comments_loop(tail, CssOutside, acc)

                _ -> strip_css_comments_loop(rest, CssComment, acc)
              }

            _ -> strip_css_comments_loop(rest, CssComment, acc)
          }

        CssString(quote, escaped) -> {
          let next_state = case escaped {
            True -> CssString(quote, False)

            False ->
              case char {
                "\\" -> CssString(quote, True)

                _ ->
                  case char == quote {
                    True -> CssOutside
                    False -> CssString(quote, False)
                  }
              }
          }

          strip_css_comments_loop(rest, next_state, [char, ..acc])
        }
      }
  }
}

fn collapse_css_whitespace(css: String) -> String {
  css
  |> string.replace("\r\n", "\n")
  |> string.replace("\r", "\n")
  |> string.replace("\n", " ")
  |> string.replace("\t", " ")
  |> collapse_repeated_spaces
}

fn collapse_repeated_spaces(css: String) -> String {
  let compacted = string.replace(css, "  ", " ")

  case compacted == css {
    True -> compacted

    False -> collapse_repeated_spaces(compacted)
  }
}

fn trim_css_spaces_around_tokens(css: String) -> String {
  css
  |> string.replace(" {", "{")
  |> string.replace("{ ", "{")
  |> string.replace(" }", "}")
  |> string.replace("} ", "}")
  |> string.replace(" :", ":")
  |> string.replace(": ", ":")
  |> string.replace(" ;", ";")
  |> string.replace("; ", ";")
  |> string.replace(" ,", ",")
  |> string.replace(", ", ",")
  |> string.replace(" >", ">")
  |> string.replace("> ", ">")
  |> string.replace("( ", "(")
  |> string.replace(" )", ")")
}

fn index_html(config: AppConfig, css_files: List(String)) -> String {
  let css = inline_css(css_files)
  "<!doctype html>"
  <> "<html lang=\""
  <> config.language
  <> "\">"
  <> "<head>"
  <> "<meta charset=\"UTF-8\">"
  <> "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
  <> "<meta name=\"color-scheme\" content=\"dark\">"
  <> "<title>"
  <> config.title
  <> "</title>"
  <> "<meta name='description' content='"
  <> config.description
  <> "'>"
  <> "<link rel=\"icon\" type=\"image/x-icon\" href=\""
  <> config.favicon
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
