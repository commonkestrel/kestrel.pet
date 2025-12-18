import app/router
import app/web
import envoy
import gleam/erlang/process
import mist
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let ctx = static_directories()

  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.bind("localhost")
    |> mist.start

  process.sleep_forever()
}

pub fn static_directories() -> web.Context {
  let assert Ok(priv_directory) = wisp.priv_directory("kestrel_pet")
  let assets = priv_directory <> "/assets"
  let styles = priv_directory <> "/styles"
  let hypertext = priv_directory <> "/hypertext"

  let assert Ok(home) = envoy.get("HOME")
  let passerine = home <> "/.passerine"

  web.Context(
    assets_directory: assets,
    styles_directory: styles,
    hypertext_directory: hypertext,
    passerine_directory: passerine,
  )
}
