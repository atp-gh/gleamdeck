import data/services.{
  type ServiceConfig, Checking, Offline, Online, Service, ServiceConfig,
}

fn config() -> ServiceConfig {
  ServiceConfig(
    id: "grafana",
    name: "Grafana",
    url: "https://grafana.example.com",
    health_url: "https://grafana.example.com/api/health",
    icon: "📊",
    description: "Metrics dashboard",
    category: "Monitoring",
    port: 3000,
  )
}

pub fn from_config_starts_in_checking_state_test() {
  let service = services.from_config(config())

  let assert Service(
    config: created_config,
    status: Checking,
    last_checked: 0.0,
  ) = service

  assert created_config.id == "grafana"
}

pub fn id_returns_config_id_test() {
  let service = services.from_config(config())

  assert services.id(service) == "grafana"
}

pub fn url_returns_service_url_test() {
  let service = services.from_config(config())

  assert services.url(service) == "https://grafana.example.com"
}

pub fn health_url_returns_health_endpoint_test() {
  let service = services.from_config(config())

  assert services.health_url(service)
    == "https://grafana.example.com/api/health"
}

pub fn with_checking_status_preserves_other_fields_test() {
  let service = Service(config: config(), status: Online, last_checked: 1000.0)

  let updated = services.with_checking_status(service)

  let assert Service(
    config: updated_config,
    status: Checking,
    last_checked: 1000.0,
  ) = updated

  assert updated_config.id == "grafana"
}

pub fn successful_health_result_sets_online_test() {
  let service = services.from_config(config())

  let updated = services.with_health_result(service, True, 1234.0)

  let assert Service(status: Online, last_checked: 1234.0, ..) = updated
}

pub fn failed_health_result_sets_offline_test() {
  let service = services.from_config(config())

  let updated = services.with_health_result(service, False, 5678.0)

  let assert Service(status: Offline, last_checked: 5678.0, ..) = updated
}
