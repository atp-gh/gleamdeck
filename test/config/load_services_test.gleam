import config/load_services
import data/services.{ServiceConfig}
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
      health_url: "https://grafana.example.com/api/health",
      icon: "📊",
      description: "Metrics dashboard",
      category: "Monitoring",
      port: 3000,
    ),
    ServiceConfig(
      id: "gitea",
      name: "Gitea",
      url: "https://git.example.com",
      health_url: "https://git.example.com/api/healthz",
      icon: "◈",
      description: "Git hosting",
      category: "Development",
      port: 443,
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

  assert string.starts_with(reason, "Could not parse services.toml:")
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
url = \"https://grafana.example.com\"
health_url = \"https://grafana.example.com/api/health\"
icon = \"📊\"
description = \"Metrics dashboard\"
category = \"Monitoring\"
",
    )

  assert result
    == Error(
      "Invalid [[service]] entry at index 0: Missing required field `port`",
    )
}

pub fn wrong_string_field_type_returns_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = 123
name = \"Grafana\"
url = \"https://grafana.example.com\"
health_url = \"https://grafana.example.com/api/health\"
icon = \"📊\"
description = \"Metrics dashboard\"
category = \"Monitoring\"
port = 3000
",
    )

  let assert Error(reason) = result

  assert string.contains(reason, "Field `id` must be a string")
}

pub fn wrong_port_type_returns_error_test() {
  let result =
    load_services.decode(
      "
[[service]]
id = \"grafana\"
name = \"Grafana\"
url = \"https://grafana.example.com\"
health_url = \"https://grafana.example.com/api/health\"
icon = \"📊\"
description = \"Metrics dashboard\"
category = \"Monitoring\"
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
health_url = \"https://grafana.example.com/api/health\"
icon = \"📊\"
description = \"Metrics dashboard\"
category = \"Monitoring\"
port = 3000

[[service]]
id = \"gitea\"
name = \"Gitea\"
",
    )

  let assert Error(reason) = result

  assert string.contains(reason, "Invalid [[service]] entry at index 1")
}
