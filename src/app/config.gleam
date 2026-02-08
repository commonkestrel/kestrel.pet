import app/time
import gleam/dict
import gleam/list
import gleam/option
import tom
import wisp

pub type Config {
  Config(
    buttons: List(Button),
    blinkies: List(Blinkie),
    updates: List(time.Timed(String)),
  )
}

pub fn parse(toml: dict.Dict(String, tom.Toml)) -> Config {
  let buttons = case tom.get_array(toml, ["button"]) {
    Ok(unmapped) -> {
      list.filter_map(unmapped, tom.as_table)
      |> list.filter_map(fn(button) {
        let href = case tom.get_string(button, ["href"]) {
          Ok(href) -> option.Some(href)
          _ -> option.None
        }

        let alt = case tom.get_string(button, ["alt"]) {
          Ok(alt) -> option.Some(alt)
          _ -> {
            wisp.log_warning("button found without alt")
            option.None
          }
        }

        case tom.get_string(button, ["file"]), tom.get_string(button, ["src"]) {
          Ok(file), Error(_) -> Ok(Local(file, alt, href))
          Error(_), Ok(src) -> Ok(Web(src, alt, href))
          _, _ -> {
            wisp.log_error("button found without file or src")
            Error(0)
          }
        }
      })
    }
    _ -> []
  }

  let blinkies = case tom.get_array(toml, ["blinkie"]) {
    Ok(unmapped) -> {
      list.filter_map(unmapped, tom.as_table)
      |> list.filter_map(fn(button) {
        let alt = case tom.get_string(button, ["alt"]) {
          Ok(alt) -> option.Some(alt)
          _ -> {
            wisp.log_warning("blinkie found without alt")
            option.None
          }
        }

        case tom.get_string(button, ["file"]) {
          Ok(file) -> Ok(Blinkie(file, option.unwrap(alt, "")))
          _ -> {
            wisp.log_error("blinkie found without file")
            Error(0)
          }
        }
      })
    }
    _ -> []
  }

  let updates = case tom.get_array(toml, ["update"]) {
    Ok(unmapped) -> {
      list.filter_map(unmapped, tom.as_table)
      |> list.filter_map(fn(update) {
        case tom.get_string(update, ["content"]) {
          Ok(content) ->
            case tom.get_timestamp(update, ["timestamp"]) {
              Ok(timestamp) -> Ok(time.Timed(content, timestamp))
              _ -> {
                wisp.log_error("update found without timestamp")
                Error(0)
              }
            }
          _ -> {
            wisp.log_error("update found without content")
            Error(0)
          }
        }
      })
    }
    _ -> {
      wisp.log_warning("updates not found in Config.toml")
      []
    }
  }

  Config(buttons, blinkies, updates)
}

pub type Blinkie {
  Blinkie(file: String, alt: String)
}

pub type Button {
  Local(file: String, alt: option.Option(String), href: option.Option(String))
  Web(src: String, alt: option.Option(String), href: option.Option(String))
}

pub fn is_local(button: Button) -> Bool {
  case button {
    Local(_, _, _) -> True
    _ -> False
  }
}

pub fn source(button: Button) -> String {
  case button {
    Local(file, _, _) -> file
    Web(src, _, _) -> src
  }
}

pub fn has_alt(button: Button) -> Bool {
  case button {
    Local(_, alt, _) -> option.is_some(alt)
    Web(_, alt, _) -> option.is_some(alt)
  }
}

pub fn alt(button: Button) -> String {
  case button {
    Local(_, alt, _) -> option.unwrap(alt, "")
    Web(_, alt, _) -> option.unwrap(alt, "")
  }
}

pub fn has_href(button: Button) -> Bool {
  case button {
    Local(_, _, href) -> option.is_some(href)
    Web(_, _, href) -> option.is_some(href)
  }
}

pub fn href(button: Button) -> String {
  case button {
    Local(_, _, href) -> option.unwrap(href, "")
    Web(_, _, href) -> option.unwrap(href, "")
  }
}
