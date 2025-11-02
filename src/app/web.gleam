import wisp

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
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use req <- wisp.csrf_known_header_protection(req)
  use <- wisp.serve_static(req, "/assets", ctx.assets_directory)
  use <- wisp.serve_static(req, "/styles", ctx.styles_directory)
  use <- wisp.serve_static(req, "/", ctx.hypertext_directory)

  handle_request(req)
}
