export function now_ms() {
  return Date.now();
}

function valid_timezone(timezone) {
  try {
    new Intl.DateTimeFormat("en-US", {
      timeZone: timezone,
    }).format();

    return timezone;
  } catch {
    console.warn(`Invalid timezone "${timezone}", falling back to UTC.`);

    return "UTC";
  }
}

export function format_time(ms, timezone) {
  const safe_timezone = valid_timezone(timezone);

  return new Intl.DateTimeFormat("en-GB", {
    timeZone: safe_timezone,
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23",
  }).format(new Date(ms));
}

export function format_date(ms, timezone) {
  const safe_timezone = valid_timezone(timezone);

  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: safe_timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date(ms));

  const year = parts.find((part) => part.type === "year")?.value;
  const month = parts.find((part) => part.type === "month")?.value;
  const day = parts.find((part) => part.type === "day")?.value;

  return `${year}-${month}-${day}`;
}

export function browser_timezone() {
  try {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

    if (typeof timezone === "string" && timezone.trim() !== "") {
      return timezone;
    }
  } catch {
    // Intl may be unavailable in unusual browser environments.
  }

  return "UTC";
}
