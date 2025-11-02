import app/web.{type Context}
import gleam/bytes_tree
import gleam/http.{Get, Post}
import gleam/io
import gleam/list
import gleam/result
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use _ <- web.middleware(req, ctx)

  io.println("path: " <> req.path)

  case req.path {
    "/" -> wisp.permanent_redirect("/index.html")
    "/favicon.ico" -> wisp.permanent_redirect("/assets/images/favicon.ico")
    _ -> wisp.redirect("/404.html")
  }
}
