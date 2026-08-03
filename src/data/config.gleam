//// Build-time and runtime dashboard configuration.

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
    timezone: String,
  )
}

pub type BuildConfig {
  BuildConfig(
    meta: MetaConfig,
    site: SiteConfig,
  )
}

/// Runtime configuration used before config.json has loaded.
pub fn default_site() -> SiteConfig {
  SiteConfig(
    title: "Gleam Deck",
    subtitle: "Self-hosted services dashboard",
    timezone: "UTC",
  )
}
