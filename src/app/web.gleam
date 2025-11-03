import gleam/int
import wisp
import simplifile
import gleam/string
import gleam/list

pub type Context {
  Context(
    assets_directory: String,
    styles_directory: String,
    hypertext_directory: String,
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
  use <- handle_visitors(req)
  use <- handle_404(req, ctx)
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

fn handle_visitors(
    req: wisp.Request,
    next: fn() -> wisp.Response,
) -> wisp.Response {
  case req.path {
    "/home.html" -> {
      let visitors_path = "~/.passerine/visitors.txt"  
      let visits_path = "~/.passerine/visits.txt"
      let assert Ok(visitors) = simplifile.read(visitors_path)
      let visitors = list.map(string.split(visitors, on: "\n"), string.trim)

      let assert Ok(_) = case list.contains(visitors, req.host) {
        False -> {
          wisp.log_debug("New visitor: " <> req.host)
          let assert Ok(_) = {"\n" <> req.host} |> simplifile.append(to: visitors_path)
          let visits = list.length(visitors) + 1
          let assert Ok(_) = int.to_string(visits) |> simplifile.write(to: visits_path)
        }
        True -> Ok(Nil)
      }
      
      next()
    }
    _ -> next()
  }
}
