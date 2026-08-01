@external(javascript, "../ffi/health.mjs", "health_check")
pub fn health_check(
  url: String,
  timeout_ms: Int,
  callback: fn(Bool) -> Nil,
) -> Nil

@external(javascript, "../ffi/health.mjs", "set_timeout")
pub fn set_timeout(delay_ms: Int, callback: fn() -> Nil) -> Float
