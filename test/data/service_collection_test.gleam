import data/service_collection
import data/services.{
  type Service, type Status, Checking, Offline, Online, Service, ServiceConfig,
}
import gleam/dict
import gleam/option.{None, Some}

fn service(
  id: String,
  name: String,
  description: String,
  category: String,
  url: String,
  status: Status,
) -> Service {
  Service(
    config: ServiceConfig(
      id: id,
      name: name,
      url: url,
      health_url: url <> "/health",
      icon: "◈",
      description: description,
      category: category,
      port: 0,
    ),
    status: status,
    last_checked: 0.0,
  )
}

fn fixtures() -> List(Service) {
  [
    service(
      "grafana",
      "Grafana",
      "Metrics dashboard",
      "Monitoring",
      "https://grafana.example.com",
      Online,
    ),
    service(
      "prometheus",
      "Prometheus",
      "Metrics database",
      "Monitoring",
      "https://prometheus.example.com",
      Checking,
    ),
    service(
      "gitea",
      "Gitea",
      "Git hosting",
      "Development",
      "https://git.example.com",
      Offline,
    ),
  ]
}

pub fn categories_are_unique_and_keep_first_seen_order_test() {
  let categories = service_collection.categories(fixtures())

  assert categories == ["Monitoring", "Development"]
}

pub fn status_counts_counts_each_status_test() {
  let counts = service_collection.status_counts(fixtures())

  assert dict.get(counts, Online) == Ok(1)
  assert dict.get(counts, Checking) == Ok(1)
  assert dict.get(counts, Offline) == Ok(1)
}

pub fn empty_status_counts_has_no_entries_test() {
  let counts = service_collection.status_counts([])

  assert dict.get(counts, Online) == Error(Nil)
  assert dict.get(counts, Checking) == Error(Nil)
  assert dict.get(counts, Offline) == Error(Nil)
}

pub fn empty_query_returns_all_services_test() {
  let result = service_collection.filter(fixtures(), "", None)

  assert result == fixtures()
}

pub fn whitespace_query_returns_all_services_test() {
  let result = service_collection.filter(fixtures(), "   ", None)

  assert result == fixtures()
}

pub fn filter_matches_name_case_insensitively_test() {
  let result = service_collection.filter(fixtures(), "gRaFaNa", None)

  let assert [matched] = result

  assert matched.config.id == "grafana"
}

pub fn filter_matches_description_test() {
  let result = service_collection.filter(fixtures(), "git hosting", None)

  let assert [matched] = result

  assert matched.config.id == "gitea"
}

pub fn filter_matches_category_test() {
  let result = service_collection.filter(fixtures(), "development", None)

  let assert [matched] = result

  assert matched.config.id == "gitea"
}

pub fn filter_matches_url_test() {
  let result =
    service_collection.filter(fixtures(), "prometheus.example.com", None)

  let assert [matched] = result

  assert matched.config.id == "prometheus"
}

pub fn category_filter_limits_results_test() {
  let result = service_collection.filter(fixtures(), "", Some("Monitoring"))

  assert result
    == [
      service(
        "grafana",
        "Grafana",
        "Metrics dashboard",
        "Monitoring",
        "https://grafana.example.com",
        Online,
      ),
      service(
        "prometheus",
        "Prometheus",
        "Metrics database",
        "Monitoring",
        "https://prometheus.example.com",
        Checking,
      ),
    ]
}

pub fn query_and_category_must_both_match_test() {
  let result =
    service_collection.filter(fixtures(), "grafana", Some("Development"))

  assert result == []
}

pub fn category_matching_is_case_sensitive_test() {
  let result = service_collection.filter(fixtures(), "", Some("monitoring"))

  assert result == []
}
