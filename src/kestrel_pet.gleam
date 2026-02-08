import app/config
import app/router
import app/time.{Timed}
import app/web
import envoy
import gleam/dict
import gleam/erlang/process
import gleam/time/timestamp
import mist
import simplifile
import tom
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

  let config_file = case simplifile.read(priv_directory <> "/Config.toml") {
    Ok(config) -> config
    _ -> ""
  }

  let config_toml = case tom.parse(config_file) {
    Ok(toml) -> toml
    _ -> dict.new()
  }

  let config = config.parse(config_toml)

  web.Context(
    config,
    assets_directory: assets,
    styles_directory: styles,
    hypertext_directory: hypertext,
    passerine_directory: passerine,
    updates: [
      Timed(
        "might have fixed the timestamps for these :p",
        timestamp.from_unix_seconds(1_770_427_013),
      ),
      Timed(
        "i'm finally adding a little status to here :D",
        timestamp.from_unix_seconds(1_749_501_300),
      ),
      Timed(
        "worker bee building a little website :3",
        timestamp.from_unix_seconds(1_749_069_300),
      ),
    ],
  )
}
