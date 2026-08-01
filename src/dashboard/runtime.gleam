//// Browser runtime operations for the dashboard.
////
//// Loads the generated services.json file and decodes its service
//// configuration for the dashboard application.

import data/services.{type ServiceConfig, ServiceConfig}
import gleam/dynamic/decode
import lustre/effect.{type Effect}
import rsvp

pub fn load_services_json(
  to_message: fn(Result(List(ServiceConfig), String)) -> message,
) -> Effect(message) {
  let handler =
    rsvp.expect_json(services_decoder(), fn(response) {
      case response {
        Ok(configs) -> to_message(Ok(configs))

        Error(_) -> to_message(Error("Could not load or decode services.json"))
      }
    })

  rsvp.get("./services.json", handler)
}

fn services_decoder() -> decode.Decoder(List(ServiceConfig)) {
  decode.list(service_decoder())
}

fn service_decoder() -> decode.Decoder(ServiceConfig) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use url <- decode.field("url", decode.string)
  use health_url <- decode.field("health_url", decode.string)
  use icon <- decode.field("icon", decode.string)
  use description <- decode.field("description", decode.string)
  use category <- decode.field("category", decode.string)
  use port <- decode.field("port", decode.int)

  decode.success(ServiceConfig(
    id:,
    name:,
    url:,
    health_url:,
    icon:,
    description:,
    category:,
    port:,
  ))
}
