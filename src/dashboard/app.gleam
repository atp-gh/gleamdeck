//// Elm-style Lustre application for the self-hosted services dashboard.

import dashboard/presentation
import dashboard/runtime
import data/service_collection
import data/services.{
  type Service, type ServiceConfig, type Status, Checking, Offline, Online,
}

import effect/clock
import effect/health
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute as attr
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type LoadState {
  Loading
  Loaded
  LoadFailed(String)
}

pub type Model {
  Model(
    services: List(Service),
    load_state: LoadState,
    query: String,
    active_category: Option(String),
    now: Float,
    refreshed_at: Float,
  )
}

pub type Msg {
  ServicesLoaded(Result(List(ServiceConfig), String))
  SetQuery(String)
  SelectCategory(Option(String))
  RefreshAll
  HealthResult(String, Bool)
  Tick(Float)
}

pub fn init(_args) -> #(Model, Effect(Msg)) {
  let now = clock.now_ms()
  let model =
    Model(
      services: [],
      load_state: Loading,
      query: "",
      active_category: None,
      now:,
      refreshed_at: now,
    )
  #(model, effect.batch([tick(), load_services()]))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ServicesLoaded(Ok(configs)) -> {
      let services = list.map(configs, services.from_config)

      #(
        Model(
          ..model,
          services:,
          load_state: Loaded,
          refreshed_at: clock.now_ms(),
        ),
        refresh_all(services),
      )
    }

    ServicesLoaded(Error(reason)) -> #(
      Model(..model, load_state: LoadFailed(reason)),
      effect.none(),
    )

    SetQuery(query) -> #(Model(..model, query:), effect.none())
    SelectCategory(category) -> #(
      Model(..model, active_category: category),
      effect.none(),
    )
    RefreshAll -> {
      let services = list.map(model.services, services.with_checking_status)
      #(
        Model(..model, services:, refreshed_at: clock.now_ms()),
        refresh_all(services),
      )
    }
    HealthResult(id, is_online) -> {
      let services =
        list.map(model.services, fn(item) {
          case services.id(item) == id {
            True -> services.with_health_result(item, is_online, clock.now_ms())

            False -> item
          }
        })
      #(Model(..model, services:), effect.none())
    }
    Tick(time) -> #(Model(..model, now: time), tick())
  }
}

fn load_services() -> Effect(Msg) {
  runtime.load_services_json(ServicesLoaded)
}

fn tick() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ = health.set_timeout(1000, fn() { dispatch(Tick(clock.now_ms())) })
    Nil
  })
}

fn refresh_all(items: List(Service)) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    list.each(items, fn(item) {
      health.health_check(services.health_url(item), 6000, fn(ok) {
        dispatch(HealthResult(services.id(item), ok))
      })
    })
    Nil
  })
}

pub fn view(model: Model) -> Element(Msg) {
  let categories = service_collection.categories(model.services)
  let counts = service_collection.status_counts(model.services)
  let online = count_of(counts, Online)
  let total = list.length(model.services)
  let visible =
    service_collection.filter(
      model.services,
      model.query,
      model.active_category,
    )
  html.main([attr.id("app-root")], [
    animated_background(),
    html.div([attr.class("wrap")], [
      header(model, total, online, counts),
      controls(model, categories),
      case model.load_state {
        Loading -> notice("Loading services…", "notice loading")
        LoadFailed(reason) ->
          notice("Could not load services: " <> reason, "notice error")
        Loaded ->
          html.section(
            [attr.class("grid"), attr.attribute("aria-label", "services")],
            list.index_map(visible, render_card),
          )
      },
      footer(model),
    ]),
  ])
}

fn notice(message: String, classes: String) -> Element(Msg) {
  html.div([attr.class(classes), attr.attribute("role", "status")], [
    html.text(message),
  ])
}

fn header(
  model: Model,
  total: Int,
  online: Int,
  counts: Dict(Status, Int),
) -> Element(Msg) {
  html.header([attr.class("header")], [
    html.div([attr.class("brand")], [
      html.div([attr.class("logo")], [html.text("◈")]),
      html.div([attr.class("brand-text")], [
        html.h1([attr.class("title")], [html.text("Gleam Deck")]),
        html.p([attr.class("subtitle")], [
          html.text("self-hosted panel"),
        ]),
      ]),
    ]),
    html.div([attr.class("clock")], [
      html.span([attr.class("clock-time")], [
        html.text(clock.format_time(model.now)),
      ]),
      html.span([attr.class("clock-date")], [
        html.text(clock.format_date(model.now)),
      ]),
    ]),
    html.div([attr.class("stats")], [
      stat_card("total", int.to_string(total), "services"),
      stat_card("online", int.to_string(online), "reachable"),
      stat_card(
        "checking",
        int.to_string(count_of(counts, Checking)),
        "probing",
      ),
      stat_card("offline", int.to_string(count_of(counts, Offline)), "down"),
    ]),
  ])
}

fn stat_card(accent: String, value: String, label: String) -> Element(Msg) {
  html.div([attr.class("stat " <> accent)], [
    html.span([attr.class("stat-value")], [html.text(value)]),
    html.span([attr.class("stat-label")], [html.text(label)]),
  ])
}

fn controls(model: Model, categories: List(String)) -> Element(Msg) {
  html.div([attr.class("controls")], [
    html.div([attr.class("search")], [
      html.span([attr.class("search-icon")], [html.text("⌕")]),
      html.input([
        attr.type_("search"),
        attr.placeholder("search services…"),
        attr.value(model.query),
        attr.class("search-input"),
        event.on_input(SetQuery),
      ]),
    ]),
    html.div([attr.class("pills")], [
      pill(model.active_category == None, "All", SelectCategory(None)),
      ..list.map(categories, fn(category) {
        pill(
          model.active_category == Some(category),
          category,
          SelectCategory(Some(category)),
        )
      })
    ]),
    html.button(
      [
        attr.class("refresh"),
        event.on_click(RefreshAll),
        attr.title("Re-check all services"),
      ],
      [html.text("↻ Refresh")],
    ),
  ])
}

fn pill(active: Bool, label: String, msg: Msg) -> Element(Msg) {
  let classes = case active {
    True -> "pill active"
    False -> "pill"
  }
  html.button([attr.class(classes), event.on_click(msg)], [html.text(label)])
}

fn render_card(item: Service, index: Int) -> Element(Msg) {
  let config = item.config
  let word = presentation.status_class(item.status)
  html.a(
    [
      attr.class("card " <> word),
      attr.href(config.url),
      attr.target("_blank"),
      attr.rel("noopener noreferrer"),
      attr.style("animation-delay", int.to_string(index * 35) <> "ms"),
    ],
    [
      html.div([attr.class("card-glow")], []),
      html.div([attr.class("card-top")], [
        html.span([attr.class("card-icon")], [html.text(config.icon)]),
        html.span([attr.class("card-status " <> word)], [
          html.span([attr.class("dot")], []),
          html.text(presentation.status_label(item.status)),
        ]),
      ]),
      html.div([attr.class("card-body")], [
        html.h3([attr.class("card-name")], [html.text(config.name)]),
        html.p([attr.class("card-desc")], [html.text(config.description)]),
      ]),
      html.div([attr.class("card-foot")], [
        html.span([attr.class("card-host")], [
          html.text(presentation.host_of(config.url)),
        ]),
        case config.port {
          0 -> html.span([], [])
          port ->
            html.span([attr.class("card-port")], [
              html.text(":" <> int.to_string(port)),
            ])
        },
      ]),
    ],
  )
}

fn footer(model: Model) -> Element(Msg) {
  let seconds_ago = float.round({ model.now -. model.refreshed_at } /. 1000.0)
  let label = case seconds_ago {
    0 -> "just now"
    n -> int.to_string(n) <> "s ago"
  }
  html.footer([attr.class("footer")], [
    html.span([], [html.text("built with Gleam + Lustre · ")]),
    html.span([attr.class("refreshed")], [html.text("last refresh " <> label)]),
  ])
}

fn animated_background() -> Element(Msg) {
  html.div([attr.class("bg"), attr.attribute("aria-hidden", "true")], [
    html.div([attr.class("blob blob-1")], []),
    html.div([attr.class("blob blob-2")], []),
    html.div([attr.class("blob blob-3")], []),
    html.div([attr.class("grid-overlay")], []),
  ])
}

fn count_of(counts: Dict(Status, Int), status: Status) -> Int {
  case dict.get(counts, status) {
    Ok(n) -> n
    Error(_) -> 0
  }
}

pub fn app() -> lustre.App(Nil, Model, Msg) {
  lustre.application(init, update, view)
}
