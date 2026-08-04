import dashboard/presentation
import data/services.{Checking, Offline, Online}
import gleam/option.{None, Some}

pub fn checking_status_class_test() {
  assert presentation.status_class(Checking) == "checking"
}

pub fn online_status_class_test() {
  assert presentation.status_class(Online) == "online"
}

pub fn offline_status_class_test() {
  assert presentation.status_class(Offline) == "offline"
}

pub fn checking_status_label_test() {
  assert presentation.status_label(Checking) == "checking"
}

pub fn online_status_label_test() {
  assert presentation.status_label(Online) == "online"
}

pub fn offline_status_label_test() {
  assert presentation.status_label(Offline) == "offline"
}

pub fn host_of_https_url_test() {
  assert presentation.host_of("https://grafana.example.com/dashboards/home")
    == "grafana.example.com"
}

pub fn host_of_http_url_with_port_test() {
  assert presentation.host_of("http://localhost:3000/api/health")
    == "localhost:3000"
}

pub fn host_of_url_without_path_test() {
  assert presentation.host_of("https://example.com") == "example.com"
}

pub fn host_of_url_without_scheme_test() {
  assert presentation.host_of("example.com/dashboard") == "example.com"
}

pub fn host_of_localhost_test() {
  assert presentation.host_of("localhost:8080") == "localhost:8080"
}

pub fn missing_icon_uses_text_fallback_test() {
  assert presentation.icon_source(None) == presentation.TextIcon("?")
}

pub fn empty_icon_uses_text_fallback_test() {
  assert presentation.icon_source(Some("")) == presentation.TextIcon("?")
}

pub fn whitespace_icon_uses_text_fallback_test() {
  assert presentation.icon_source(Some("   ")) == presentation.TextIcon("?")
}

pub fn emoji_icon_is_rendered_as_text_test() {
  assert presentation.icon_source(Some("🎬")) == presentation.TextIcon("🎬")
}

pub fn text_icon_is_rendered_as_text_test() {
  assert presentation.icon_source(Some("GF")) == presentation.TextIcon("GF")
}

pub fn surrounding_icon_whitespace_is_trimmed_test() {
  assert presentation.icon_source(Some("  🎵  ")) == presentation.TextIcon("🎵")
}

pub fn selfhst_icon_reference_becomes_cdn_url_test() {
  assert presentation.icon_source(Some("sh:navidrome"))
    == presentation.ImageIcon(
      "https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/navidrome.webp",
    )
}

pub fn selfhst_icon_reference_is_trimmed_test() {
  assert presentation.icon_source(Some("  sh:navidrome  "))
    == presentation.ImageIcon(
      "https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/navidrome.webp",
    )
}

pub fn empty_selfhst_reference_uses_fallback_test() {
  assert presentation.icon_source(Some("sh:")) == presentation.TextIcon("?")
}

pub fn whitespace_selfhst_reference_uses_fallback_test() {
  assert presentation.icon_source(Some("sh:   ")) == presentation.TextIcon("?")
}

pub fn simpleicons_reference_becomes_cdn_url_test() {
  assert presentation.icon_source(Some("si:vaultwarden"))
    == presentation.ImageIcon("https://cdn.simpleicons.org/vaultwarden")
}

pub fn empty_simpleicons_reference_uses_fallback_test() {
  assert presentation.icon_source(Some("si:")) == presentation.TextIcon("?")
}

pub fn homelab_icon_reference_becomes_cdn_url_test() {
  assert presentation.icon_source(Some("hl:paperless-ngx"))
    == presentation.ImageIcon(
      "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/paperless-ngx.webp",
    )
}

pub fn empty_homelab_reference_uses_fallback_test() {
  assert presentation.icon_source(Some("hl:")) == presentation.TextIcon("?")
}

pub fn mdi_icon_reference_becomes_cdn_url_test() {
  assert presentation.icon_source(Some("mdi:server"))
    == presentation.ImageIcon(
      "https://cdn.jsdelivr.net/npm/@mdi/svg@7.4.47/svg/server.svg",
    )
}

pub fn empty_mdi_reference_uses_fallback_test() {
  assert presentation.icon_source(Some("mdi:")) == presentation.TextIcon("?")
}

pub fn https_icon_url_is_an_image_test() {
  assert presentation.icon_source(Some(
      "https://cdn.example.com/icons/grafana.png",
    ))
    == presentation.ImageIcon("https://cdn.example.com/icons/grafana.png")
}

pub fn http_icon_url_is_an_image_test() {
  assert presentation.icon_source(Some("http://localhost:8080/icon.svg"))
    == presentation.ImageIcon("http://localhost:8080/icon.svg")
}

pub fn remote_url_without_image_extension_is_an_image_test() {
  assert presentation.icon_source(Some(
      "https://example.com/api/icon?id=grafana",
    ))
    == presentation.ImageIcon("https://example.com/api/icon?id=grafana")
}

pub fn static_png_path_is_normalized_test() {
  assert presentation.icon_source(Some("static/icons/grafana.png"))
    == presentation.ImageIcon("./icons/grafana.png")
}

pub fn static_svg_path_is_normalized_test() {
  assert presentation.icon_source(Some("static/icons/grafana.svg"))
    == presentation.ImageIcon("./icons/grafana.svg")
}

pub fn relative_png_path_gets_dot_slash_prefix_test() {
  assert presentation.icon_source(Some("icons/grafana.png"))
    == presentation.ImageIcon("./icons/grafana.png")
}

pub fn existing_relative_prefix_is_preserved_test() {
  assert presentation.icon_source(Some("./icons/grafana.png"))
    == presentation.ImageIcon("./icons/grafana.png")
}

pub fn nested_local_icon_path_is_supported_test() {
  assert presentation.icon_source(Some(
      "static/assets/icons/monitoring/grafana.webp",
    ))
    == presentation.ImageIcon("./assets/icons/monitoring/grafana.webp")
}

pub fn uppercase_image_extension_is_supported_test() {
  assert presentation.icon_source(Some("icons/grafana.PNG"))
    == presentation.ImageIcon("./icons/grafana.PNG")
}

pub fn image_path_with_query_string_is_supported_test() {
  assert presentation.icon_source(Some("icons/grafana.png?v=2026"))
    == presentation.ImageIcon("./icons/grafana.png?v=2026")
}

pub fn svg_path_with_query_string_is_supported_test() {
  assert presentation.icon_source(Some("static/icons/grafana.svg?version=2"))
    == presentation.ImageIcon("./icons/grafana.svg?version=2")
}

pub fn avif_icon_is_supported_test() {
  assert presentation.icon_source(Some("icons/service.avif"))
    == presentation.ImageIcon("./icons/service.avif")
}

pub fn jpeg_icon_is_supported_test() {
  assert presentation.icon_source(Some("icons/service.jpeg"))
    == presentation.ImageIcon("./icons/service.jpeg")
}

pub fn gif_icon_is_supported_test() {
  assert presentation.icon_source(Some("icons/service.gif"))
    == presentation.ImageIcon("./icons/service.gif")
}

pub fn ico_icon_is_supported_test() {
  assert presentation.icon_source(Some("icons/service.ico"))
    == presentation.ImageIcon("./icons/service.ico")
}

pub fn unknown_local_extension_remains_text_test() {
  assert presentation.icon_source(Some("icons/service.txt"))
    == presentation.TextIcon("icons/service.txt")
}

pub fn filename_without_extension_remains_text_test() {
  assert presentation.icon_source(Some("grafana"))
    == presentation.TextIcon("grafana")
}

pub fn javascript_scheme_is_not_rendered_as_image_test() {
  assert presentation.icon_source(Some("javascript:alert(1)"))
    == presentation.TextIcon("javascript:alert(1)")
}

pub fn data_url_is_not_rendered_as_image_test() {
  assert presentation.icon_source(Some("data:image/svg+xml,<svg></svg>"))
    == presentation.TextIcon("data:image/svg+xml,<svg></svg>")
}
