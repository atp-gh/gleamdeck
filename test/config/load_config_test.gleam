import config/load_config
import data/config.{BuildConfig, MetaConfig, SiteConfig}
import gleam/option.{None, Some}
import gleam/string

const complete_config = "
[meta]
title = \"Custom Dashboard\"
description = \"My service dashboard\"
language = \"zh-CN\"
favicon = \"images/custom.png\"

[site]
title = \"Home Lab\"
subtitle = \"Private services\"
timezone = \"Asia/Shanghai\"
health_check = true
"

pub fn complete_config_decodes_test() {
  let result = load_config.decode(complete_config)

  assert result
    == Ok(BuildConfig(
      meta: MetaConfig(
        title: "Custom Dashboard",
        description: "My service dashboard",
        language: "zh-CN",
        favicon: "images/custom.png",
      ),
      site: SiteConfig(
        title: "Home Lab",
        subtitle: "Private services",
        timezone: Some("Asia/Shanghai"),
        health_check: True,
      ),
    ))
}

pub fn missing_timezone_decodes_as_none_test() {
  let result =
    load_config.decode(
      "
[meta]
title = \"Dashboard\"
description = \"Services\"
language = \"en\"
favicon = \"favicon.ico\"

[site]
title = \"Home Lab\"
subtitle = \"Private services\"
health_check = true
",
    )

  assert result
    == Ok(BuildConfig(
      meta: MetaConfig(
        title: "Dashboard",
        description: "Services",
        language: "en",
        favicon: "favicon.ico",
      ),
      site: SiteConfig(
        title: "Home Lab",
        subtitle: "Private services",
        timezone: None,
        health_check: True,
      ),
    ))
}

pub fn empty_timezone_decodes_as_none_test() {
  let result =
    load_config.decode(
      "
[meta]
title = \"Dashboard\"
description = \"Services\"
language = \"en\"
favicon = \"favicon.ico\"

[site]
title = \"Home Lab\"
subtitle = \"Private services\"
timezone = \"   \"
health_check = true
",
    )

  let assert Ok(config) = result

  assert config.site.timezone == None
}

pub fn timezone_whitespace_is_trimmed_test() {
  let result =
    load_config.decode(
      "
[meta]
title = \"Dashboard\"
description = \"Services\"
language = \"en\"
favicon = \"favicon.ico\"

[site]
title = \"Home Lab\"
subtitle = \"Private services\"
timezone = \"  Asia/Shanghai  \"
health_check = true
",
    )

  let assert Ok(config) = result

  assert config.site.timezone == Some("Asia/Shanghai")
}

pub fn timezone_must_be_string_test() {
  let result =
    load_config.decode(
      "
[meta]
title = \"Dashboard\"
description = \"Services\"
language = \"en\"
favicon = \"favicon.ico\"

[site]
title = \"Home Lab\"
subtitle = \"Private services\"
timezone = 123
health_check = true
",
    )

  let assert Error(reason) = result

  assert string.contains(reason, "Field `timezone` must be a string")
}

pub fn malformed_toml_returns_parse_error_test() {
  let result =
    load_config.decode(
      "
[meta
title = \"Broken\"
",
    )

  let assert Error(reason) = result

  assert string.starts_with(reason, "Could not parse config/config.toml:")
}

pub fn missing_meta_table_returns_error_test() {
  let result =
    load_config.decode(
      "
[site]
title = \"Home Lab\"
subtitle = \"Private services\"
timezone = \"UTC\"
",
    )

  assert result == Error("Missing required table `[meta]`")
}

pub fn missing_site_table_returns_error_test() {
  let result =
    load_config.decode(
      "
[meta]
title = \"Dashboard\"
description = \"Services\"
language = \"en\"
favicon = \"favicon.ico\"
",
    )

  assert result == Error("Missing required table `[site]`")
}

pub fn meta_must_be_table_test() {
  let result =
    load_config.decode(
      "
meta = \"invalid\"

[site]
title = \"Home Lab\"
subtitle = \"Private services\"
timezone = \"UTC\"
",
    )

  let assert Error(reason) = result

  assert string.contains(reason, "Field `meta` must be a table")
}

pub fn missing_meta_field_returns_error_test() {
  let result =
    load_config.decode(
      "
[meta]
title = \"Dashboard\"
description = \"Services\"
language = \"en\"

[site]
title = \"Home Lab\"
subtitle = \"Private services\"
timezone = \"UTC\"
",
    )

  assert result == Error("Missing required field `favicon`")
}

pub fn empty_string_field_returns_error_test() {
  let result =
    load_config.decode(
      "
[meta]
title = \"   \"
description = \"Services\"
language = \"en\"
favicon = \"favicon.ico\"

[site]
title = \"Home Lab\"
subtitle = \"Private services\"
timezone = \"UTC\"
",
    )

  assert result == Error("Field `title` must not be empty")
}

pub fn wrong_string_field_type_returns_error_test() {
  let result =
    load_config.decode(
      "
[meta]
title = 123
description = \"Services\"
language = \"en\"
favicon = \"favicon.ico\"

[site]
title = \"Home Lab\"
subtitle = \"Private services\"
timezone = \"UTC\"
",
    )

  let assert Error(reason) = result

  assert string.contains(reason, "Field `title` must be a string")
}

pub fn escaped_characters_are_decoded_test() {
  let result =
    load_config.decode(
      "
[meta]
title = \"Gleam\\tDeck\"
description = \"Line one\\nLine two\"
language = \"en\"
favicon = \"images/icon.png\"

[site]
title = \"My \\\"Gleam\\\" Deck\"
subtitle = \"Services\\\\Dashboard\"
timezone = \"UTC\"
health_check = true
",
    )

  let assert Ok(config) = result

  assert config.meta.title == "Gleam\tDeck"
  assert config.meta.description == "Line one\nLine two"
  assert config.site.title == "My \"Gleam\" Deck"
  assert config.site.subtitle == "Services\\Dashboard"
  assert config.site.timezone == Some("UTC")
}

pub fn multiline_basic_strings_are_supported_test() {
  let result =
    load_config.decode(
      "
[meta]
title = \"Dashboard\"
description = \"\"\"A dashboard
for self-hosted
services\"\"\"
language = \"en\"
favicon = \"favicon.ico\"

[site]
title = \"Home Lab\"
subtitle = \"Services\"
timezone = \"UTC\"
health_check = true
",
    )

  let assert Ok(config) = result

  assert config.meta.description == "A dashboard\nfor self-hosted\nservices"
  assert config.site.timezone == Some("UTC")
}

pub fn multiline_literal_strings_are_supported_test() {
  let result =
    load_config.decode(
      "
[meta]
title = \"Dashboard\"
description = '''C:\\\\Users\\\\example
No escaping required'''
language = \"en\"
favicon = \"favicon.ico\"

[site]
title = \"Home Lab\"
subtitle = \"Services\"
timezone = \"UTC\"
health_check = true
",
    )

  let assert Ok(config) = result

  assert config.meta.description == "C:\\\\Users\\\\example\nNo escaping required"
  assert config.site.timezone == Some("UTC")
}

pub fn comments_are_supported_test() {
  let result =
    load_config.decode(
      "
# Metadata configuration
[meta]
title = \"Dashboard\" # Browser title
description = \"Services\"
language = \"en\"
favicon = \"favicon.ico\"

# Runtime configuration
[site]
title = \"Home Lab\"
subtitle = \"Private services\"
timezone = \"UTC\"
health_check = true
",
    )

  let assert Ok(config) = result

  assert config.meta.title == "Dashboard"
  assert config.site.timezone == Some("UTC")
}
