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
  handle_404: fn(wisp.Request, Context, fn() -> wisp.Response) -> wisp.Response,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use req <- wisp.csrf_known_header_protection(req)
  use <- handle_404(req, ctx)
  use <- wisp.serve_static(req, "/", ctx.hypertext_directory)
  use <- handle_statics(req, ctx)
  use <- wisp.serve_static(req, "/assets", ctx.assets_directory)

  handle_request(req)
}

fn handle_statics(req: wisp.Request, ctx: Context, next: fn() -> wisp.Response) -> wisp.Response {
    wisp.set_header(wisp.serve_static(req, "/styles", ctx.styles_directory, next), "Cache-control", "max-age=3600")
}
