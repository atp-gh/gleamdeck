//// Browser entry point for the Nexus Dashboard SPA.

import dashboard/app
import lustre

pub fn main() -> Nil {
  let _ = lustre.start(app.app(), onto: "#app", with: Nil)
  Nil
}
