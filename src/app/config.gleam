import app/time
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some, then}
import gleam/result.{map_error, try, unwrap}
import gleam/time/calendar
import mork
import simplifile
import tom
import wisp

pub type Config {
  Config(
    address: String,
    port: Int,
    buttons: List(Button),
    blogs: Dict(String, Blog),
    blinkies: List(Blinkie),
    updates: List(time.Timed(String)),
    tags: Dict(String, List(Blog)),
  )
}

pub fn parse(toml: dict.Dict(String, tom.Toml), priv: String) -> Config {
  // Default to the dev port
  let #(address, port) = option.unwrap(parse_server(toml), #("localhost", 8001))

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

  let blogs = case tom.get_array(toml, ["blog"]) {
    Ok(unmapped) -> {
      let mapped =
        list.filter_map(unmapped, fn(blog) {
          tom.as_table(blog)
          |> result.map_error(fn(err) {
            wisp.log_warning("blog not of type `table`; skipping")
            err
          })
        })

      list.filter_map(mapped, fn(blog) {
        use title <- try(
          tom.get_string(blog, ["title"])
          |> map_error(fn(err) {
            wisp.log_warning("blog found without title; skipping")
            err
          }),
        )

        use description <- try(
          tom.get_string(blog, ["description"])
          |> map_error(fn(err) {
            wisp.log_warning("blog found without description; skipping")
            err
          }),
        )

        use image <- try(
          tom.get_string(blog, ["image"])
          |> map_error(fn(err) {
            wisp.log_warning("blog found without image; skipping")
            err
          }),
        )

        let unmapped_tags = tom.get_array(blog, ["tags"]) |> unwrap([])
        let tags =
          list.filter_map(unmapped_tags, fn(tag) {
            tom.as_string(tag)
            |> map_error(fn(err) {
              wisp.log_warning("tag of type other than string; skipping")
              err
            })
          })

        use date <- try(
          tom.get_date(blog, ["date"])
          |> map_error(fn(err) {
            wisp.log_warning("blog found without image; skipping")
            err
          }),
        )

        use file <- try(
          tom.get_string(blog, ["file"])
          |> map_error(fn(err) {
            wisp.log_warning("blog found without file; skipping")
            err
          }),
        )

        // Yes mapping the error like this is stupid but it's `filter_map`, it's not like it cares
        use markdown <- try(
          simplifile.read(priv <> "/blogs/" <> file)
          |> map_error(fn(_) { tom.NotFound(["file"]) }),
        )

        let html =
          mork.parse(markdown)
          |> mork.to_html

        Ok(#(file, Blog(title, description, image, tags, date, html)))
      })
      |> dict.from_list
    }
    _ -> {
      wisp.log_warning("blogs not found in Config.toml")
      dict.new()
    }
  }

  let tags =
    dict.values(blogs)
    |> list.fold(dict.new(), fn(tags, blog) {
      list.fold(blog.tags, tags, fn(tags, tag) {
        dict.upsert(tags, tag, fn(tag_list) {
          case tag_list {
            Some(tag_list) -> list.prepend(tag_list, blog)
            None -> [blog]
          }
        })
      })
    })

  Config(address, port, buttons, blogs, blinkies, updates, tags)
}

fn parse_server(toml: dict.Dict(String, tom.Toml)) -> Option(#(String, Int)) {
  use address <- then(case tom.get_string(toml, ["server", "address"]) {
    Ok(address) -> Some(address)
    Error(_) -> {
      wisp.log_error(
        "address not provided in `Config.toml`; hosting on `localhost:8001`",
      )
      None
    }
  })

  use port <- then(case tom.get_int(toml, ["server", "port"]) {
    Ok(port) -> Some(port)
    Error(_) -> {
      wisp.log_error(
        "port not provided in `Config.toml`; hosting on `localhost:8001`",
      )
      None
    }
  })

  Some(#(address, port))
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

pub type Blog {
  Blog(
    title: String,
    description: String,
    image: String,
    tags: List(String),
    date: calendar.Date,
    html: String,
  )
}
