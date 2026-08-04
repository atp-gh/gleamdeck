import config/load_services
import data/services.{ServiceConfig}
import gleam/option.{None, Some}
import gleam/string

const valid_config = "
[[service]]
id = \"grafana\"
name = \"Grafana\"
url = \"https://grafana.example.com\"
health_url = \"https://grafana.example.com/api/health\"
icon = \"📊\"
description = \"Metrics dashboard\"
category = \"Monitoring\"
port = 3000

[[service]]
id = \"gitea\"
name = \"Gitea\"
url = \"https://git.example.com\"
health_url = \"https://git.example.com/api/healthz\"
icon = \"◈\"
description = \"Git hosting\"
category = \"Development\"
port = 443
"

pub fn valid_services_config_decodes_test() {
  let result = load_services.decode(valid_config)

  let assert Ok([
    ServiceConfig(
      id: "grafana",
      name: "Grafana",
      url: "https://grafana.example.com",
      health_url: Some("https://grafana.example.com/api/health"),
      icon: Some("📊"),
      description: Some("Metrics dashboard"),
      category: Some("Monitoring"),
      port: Some(3000),
    ),
    ServiceConfig(
      id: "gitea",
      name: "Gitea",
      url: "https://git.example.com",
      health_url: Some("https://git.example.com/api/healthz"),
      icon: Some("◈"),
      description: Some("Git hosting"),
      category: Some("Development"),
      port: Some(443),
    ),
  ]) = result
}

pub fn minimal_services_config_decodes_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"adguard\"
name = \"AdGuard Home\"
url = \"https://adguard.com/en/welcome.html\"
",
    )

  let assert Ok([
    ServiceConfig(
      id: "adguard",
      name: "AdGuard Home",
      url: "https://adguard.com/en/welcome.html",
      health_url: None,
      icon: None,
      description: None,
      category: None,
      port: None,
    ),
  ]) = result
}

pub fn malformed_toml_returns_parse_error_test() {
  let result =
    load_services.decode(
      "
[[service]
id = \"broken\"
",
    )

  let assert Error(reason) = result

  assert string.starts_with(reason, "Could not parse config/services.toml:")
}

pub fn missing_service_entries_returns_error_test() {
  let result =
    load_services.decode(
      "
title = \"Gleam Deck\"
",
    )

  assert result
    == Error("services.toml does not contain any [[service]] entries")
}

pub fn service_must_be_array_of_tables_test() {
  let result =
    load_services.decode(
      "
service = \"grafana\"
",
    )

  let assert Error(reason) = result

  assert string.contains(reason, "Expected [[service]] entries")
}

pub fn missing_required_field_returns_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
name = \"Grafana\"
",
    )

  assert result
    == Error(
      "Invalid [[service]] entry at index 0: Missing required field `url`",
    )
}

pub fn missing_id_returns_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
name = \"Grafana\"
url = \"https://grafana.example.com\"
",
    )

  assert result
    == Error(
      "Invalid [[service]] entry at index 0: Missing required field `id`",
    )
}

pub fn missing_name_returns_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
url = \"https://grafana.example.com\"
",
    )

  assert result
    == Error(
      "Invalid [[service]] entry at index 0: Missing required field `name`",
    )
}

pub fn wrong_required_string_field_type_returns_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = 123
name = \"Grafana\"
url = \"https://grafana.example.com\"
",
    )

  let assert Error(reason) = result

  assert string.contains(reason, "Field `id` must be a string")
}

pub fn wrong_optional_string_field_type_returns_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
name = \"Grafana\"
url = \"https://grafana.example.com\"
icon = 123
",
    )

  let assert Error(reason) = result

  assert string.contains(reason, "Field `icon` must be a string")
}

pub fn wrong_port_type_returns_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
name = \"Grafana\"
url = \"https://grafana.example.com\"
port = \"3000\"
",
    )

  let assert Error(reason) = result

  assert string.contains(reason, "Field `port` must be an integer")
}

pub fn invalid_second_entry_reports_correct_index_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
name = \"Grafana\"
url = \"https://grafana.example.com\"

[[service]]
id = \"gitea\"
name = \"Gitea\"
",
    )

  let assert Error(reason) = result

  assert string.contains(reason, "Invalid [[service]] entry at index 1")
  assert string.contains(reason, "Missing required field `url`")
}

pub fn multiline_service_description_decodes_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
name = \"Grafana\"
url = \"https://grafana.example.com\"
health_url = \"https://grafana.example.com/api/health\"
icon = \"sh:grafana\"
description = \"\"\"Metrics dashboards
and observability
for the home lab\"\"\"
category = \"Monitoring\"
port = 3000
",
    )

  let assert Ok([service]) = result

  assert service.description
    == Some("Metrics dashboards\nand observability\nfor the home lab")
}

pub fn escaped_service_fields_decode_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"example\"
name = \"My \\\"Service\\\"\"
url = \"https://example.com/path?query=hello%20world\"
health_url = \"https://example.com/health\"
icon = \"icons/example.png\"
description = \"Line one\\nLine two\"
category = \"Home\\\\Lab\"
port = 443
",
    )

  let assert Ok([service]) = result

  assert service.name == "My \"Service\""
  assert service.description == Some("Line one\nLine two")
  assert service.category == Some("Home\\Lab")
}

pub fn unicode_service_fields_decode_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"music\"
name = \"音乐服务\"
url = \"https://music.example.com\"
health_url = \"https://music.example.com/health\"
icon = \"🎵\"
description = \"自托管音乐流媒体服务\"
category = \"媒体\"
port = 4533
",
    )

  let assert Ok([service]) = result

  assert service.name == "音乐服务"
  assert service.icon == Some("🎵")
  assert service.description == Some("自托管音乐流媒体服务")
  assert service.category == Some("媒体")
}

pub fn empty_service_id_returns_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"   \"
name = \"Grafana\"
url = \"https://grafana.example.com\"
",
    )

  assert result
    == Error(
      "Invalid [[service]] entry at index 0: Field `id` must not be empty",
    )
}

pub fn empty_service_name_returns_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
name = \"\"
url = \"https://grafana.example.com\"
",
    )

  assert result
    == Error(
      "Invalid [[service]] entry at index 0: Field `name` must not be empty",
    )
}

pub fn empty_service_url_returns_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
name = \"Grafana\"
url = \"   \"
",
    )

  assert result
    == Error(
      "Invalid [[service]] entry at index 0: Field `url` must not be empty",
    )
}

pub fn empty_optional_fields_decode_as_none_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
name = \"Grafana\"
url = \"https://grafana.example.com\"
health_url = \"\"
icon = \"\"
description = \"\"
category = \"\"
",
    )

  let assert Ok([service]) = result

  assert service.health_url == None
  assert service.icon == None
  assert service.description == None
  assert service.category == None
  assert service.port == None
}

pub fn whitespace_optional_fields_decode_as_none_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
name = \"Grafana\"
url = \"https://grafana.example.com\"
health_url = \"   \"
icon = \"   \"
description = \"   \"
category = \"   \"
",
    )

  let assert Ok([service]) = result

  assert service.health_url == None
  assert service.icon == None
  assert service.description == None
  assert service.category == None
}

pub fn negative_port_returns_validation_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
name = \"Grafana\"
url = \"https://grafana.example.com\"
port = -1
",
    )

  let assert Error(reason) = result

  assert string.contains(reason, "Field `port` must be between 0 and 65535")
}

pub fn port_above_65535_returns_validation_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
name = \"Grafana\"
url = \"https://grafana.example.com\"
port = 65536
",
    )

  let assert Error(reason) = result

  assert string.contains(reason, "Field `port` must be between 0 and 65535")
}

pub fn omitted_port_decodes_as_none_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"external\"
name = \"External Service\"
url = \"https://example.com\"
",
    )

  let assert Ok([service]) = result

  assert service.port == None
}

pub fn zero_port_decodes_as_none_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"external\"
name = \"External Service\"
url = \"https://example.com\"
port = 0
",
    )

  let assert Ok([service]) = result

  assert service.port == None
}

pub fn maximum_port_is_allowed_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"example\"
name = \"Example\"
url = \"https://example.com\"
port = 65535
",
    )

  let assert Ok([service]) = result

  assert service.port == Some(65_535)
}
