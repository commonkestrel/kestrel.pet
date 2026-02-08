import gleam/option

pub type Config {
  Config(buttons: List(Button))
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
