export function health_check(url, timeout_ms, callback) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeout_ms);
  fetch(url, {
    mode: "no-cors",
    signal: controller.signal,
    redirect: "follow",
    cache: "no-store",
  })
    .then(() => {
      clearTimeout(timer);
      callback(true);
    })
    .catch(() => {
      clearTimeout(timer);
      callback(false);
    });
}

export function set_timeout(delay_ms, callback) {
  return setTimeout(callback, delay_ms);
}
