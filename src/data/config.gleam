//// Build-time and runtime dashboard configuration.

import gleam/option.{type Option, None}

pub type MetaConfig {
  MetaConfig(
    title: String,
    description: String,
    language: String,
    favicon: String,
  )
}

pub type SiteConfig {
  SiteConfig(
    title: String,
    subtitle: String,
    timezone: Option(String),
    health_check: Bool,
  )
}

pub type BuildConfig {
  BuildConfig(meta: MetaConfig, site: SiteConfig)
}

pub fn default_build() -> BuildConfig {
  BuildConfig(meta: default_meta(), site: default_site())
}

pub fn default_meta() -> MetaConfig {
  MetaConfig(
    title: "Gleam Deck",
    description: "Self-hosted services dashboard",
    language: "en",
    favicon: "images/gleamdeck.avif",
  )
}

/// Runtime configuration used before config.json has loaded.
///
/// `None` timezone means using the browser timezone.
/// `None` health_check means health checks are enabled by default.
pub fn default_site() -> SiteConfig {
  SiteConfig(
    title: "Gleam Deck",
    subtitle: "Self-hosted services dashboard",
    timezone: None,
    health_check: True,
  )
}
