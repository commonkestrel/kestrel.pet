import app/web.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use _ <- web.middleware(req, ctx)

  case req.path {
    "/" -> wisp.permanent_redirect("/index.html")
    "/favicon.ico" -> wisp.permanent_redirect("/assets/images/favicon.ico")
    _ -> wisp.redirect("/404.html")
  }
}
