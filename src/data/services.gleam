//// Domain types and basic operations for services.

pub type Status {
  Checking
  Online
  Offline
}

pub type ServiceConfig {
  ServiceConfig(
    id: String,
    name: String,
    url: String,
    health_url: String,
    icon: String,
    description: String,
    category: String,
    port: Int,
  )
}

pub type Service {
  Service(config: ServiceConfig, status: Status, last_checked: Float)
}

pub fn from_config(config: ServiceConfig) -> Service {
  Service(config:, status: Checking, last_checked: 0.0)
}

pub fn id(service: Service) -> String {
  service.config.id
}

pub fn url(service: Service) -> String {
  service.config.url
}

pub fn health_url(service: Service) -> String {
  service.config.health_url
}

pub fn with_checking_status(service: Service) -> Service {
  Service(..service, status: Checking)
}

pub fn with_health_result(
  service: Service,
  is_online: Bool,
  checked_at: Float,
) -> Service {
  let status = case is_online {
    True -> Online
    False -> Offline
  }

  Service(..service, status:, last_checked: checked_at)
}
