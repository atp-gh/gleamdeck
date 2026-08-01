@external(javascript, "../ffi/clock.mjs", "now_ms")
pub fn now_ms() -> Float

@external(javascript, "../ffi/clock.mjs", "format_time")
pub fn format_time(ms: Float) -> String

@external(javascript, "../ffi/clock.mjs", "format_date")
pub fn format_date(ms: Float) -> String
