import app/time.{type Timed}
import gleam/dict
import gleam/int
import gleam/list
import gleam/string
import simplifile
import templates/about
import templates/home
import wisp

pub type Context {
  Context(
    assets_directory: String,
    styles_directory: String,
    hypertext_directory: String,
    passerine_directory: String,
    updates: List(Timed(String)),
  )
}

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_404: fn(wisp.Request, Context, fn() -> wisp.Response) -> wisp.Response,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use req <- wisp.csrf_known_header_protection(req)
  use <- handle_visitors(req, ctx)
  use <- handle_404(req, ctx)
  use <- handle_hypertext(req, ctx)
  use <- wisp.serve_static(req, "/", ctx.hypertext_directory)
  use <- handle_statics(req, ctx)
  use <- wisp.serve_static(req, "/assets", ctx.assets_directory)

  handle_request(req)
}

fn handle_statics(
  req: wisp.Request,
  ctx: Context,
  next: fn() -> wisp.Response,
) -> wisp.Response {
  wisp.set_header(
    wisp.serve_static(req, "/styles", ctx.styles_directory, next),
    "Cache-control",
    "max-age=3600",
  )
}

fn handle_hypertext(
  req: wisp.Request,
  ctx: Context,
  next: fn() -> wisp.Response,
) -> wisp.Response {
  let abouts = [["Hello 11", "Hello 12"], ["Hello 21", "Hello 22"]]

  case req.path {
    "/about.html" -> wisp.html_response(about.render(abouts), 200)
    "/home.html" -> wisp.html_response(home.render(ctx.updates), 200)
    _ -> next()
  }
}

fn handle_visitors(
  req: wisp.Request,
  ctx: Context,
  next: fn() -> wisp.Response,
) -> wisp.Response {
  case req.path {
    "/home.html" -> {
      let visitor = case
        req.headers |> dict.from_list |> dict.get("x-forwarded-for")
      {
        Ok(v) -> v
        _ -> ""
      }

      let visitors_path = ctx.passerine_directory <> "/visitors.txt"
      let visits_path = ctx.passerine_directory <> "/visits.txt"
      let assert Ok(visitors) = simplifile.read(visitors_path)
      let visitors = list.map(string.split(visitors, on: "\n"), string.trim)

      let assert Ok(_) = case list.contains(visitors, visitor) {
        False -> {
          wisp.log_debug("New visitor: " <> visitor)
          let assert Ok(_) =
            { visitor <> "\n" } |> simplifile.append(to: visitors_path)
          let visits = list.length(visitors)
          wisp.log_info(string.inspect(req.headers))
          wisp.log_info(string.inspect(req.body))
          let assert Ok(_) =
            int.to_string(visits) |> simplifile.write(to: visits_path)
        }
        True -> Ok(Nil)
      }

      next()
    }
    _ -> next()
  }
}
