import dashboard/presentation
import data/services.{Checking, Offline, Online}

pub fn checking_status_class_test() {
  assert presentation.status_class(Checking) == "checking"
}

pub fn online_status_class_test() {
  assert presentation.status_class(Online) == "online"
}

pub fn offline_status_class_test() {
  assert presentation.status_class(Offline) == "offline"
}

pub fn checking_status_label_test() {
  assert presentation.status_label(Checking) == "checking"
}

pub fn online_status_label_test() {
  assert presentation.status_label(Online) == "online"
}

pub fn offline_status_label_test() {
  assert presentation.status_label(Offline) == "offline"
}

pub fn host_of_https_url_test() {
  assert presentation.host_of("https://grafana.example.com/dashboards/home")
    == "grafana.example.com"
}

pub fn host_of_http_url_with_port_test() {
  assert presentation.host_of("http://localhost:3000/api/health")
    == "localhost:3000"
}

pub fn host_of_url_without_path_test() {
  assert presentation.host_of("https://example.com") == "example.com"
}

pub fn host_of_url_without_scheme_test() {
  assert presentation.host_of("example.com/dashboard") == "example.com"
}

pub fn host_of_localhost_test() {
  assert presentation.host_of("localhost:8080") == "localhost:8080"
}
