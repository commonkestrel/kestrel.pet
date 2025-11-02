import app/web.{type Context}
import gleam/http/response
import gleam/option.{None}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use _ <- web.middleware(req, ctx, handle_404)

  case req.path {
    "/" -> wisp.permanent_redirect("/index.html")
    "/favicon.ico" -> wisp.permanent_redirect("/assets/images/favicon.ico")
    _ -> wisp.redirect("/404.html")
  }
}

pub fn handle_404(
  req: Request,
  ctx: Context,
  next: fn() -> Response,
) -> Response {
  case req.path {
    "404.html" ->
      response.Response(
        404,
        [#("content-type", "text/html; charset=utf-8")],
        wisp.File(ctx.hypertext_directory <> "/404.html", 0, None),
      )
    _ -> next()
  }
}
