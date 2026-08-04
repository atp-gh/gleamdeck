@external(javascript, "../ffi/clock.mjs", "now_ms")
pub fn now_ms() -> Float

@external(javascript, "../ffi/clock.mjs", "format_time")
pub fn format_time(ms: Float, timezone: String) -> String

@external(javascript, "../ffi/clock.mjs", "format_date")
pub fn format_date(ms: Float, timezone: String) -> String

/// Return the browser's IANA timezone, falling back to UTC when unavailable.
@external(javascript, "../ffi/clock.mjs", "browser_timezone")
pub fn browser_timezone() -> String
