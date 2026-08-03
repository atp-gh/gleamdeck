//// Domain types and defaults for the dashboard configuration.

pub type AppConfig {
  AppConfig(
    title: String,
    description: String,
    language: String,
    timezone: String,
    favicon: String,
  )
}

/// Configuration used before config.json has finished loading.
///
/// Keeping a default configuration allows services.json and config.json to be
/// loaded independently without blocking the application startup.
pub fn default() -> AppConfig {
  AppConfig(
    title: "Gleam Deck",
    description: "Self-hosted services dashboard",
    language: "en",
    timezone: "UTC",
    favicon: "images/gleamdeck.avif",
  )
}
