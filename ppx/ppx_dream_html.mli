(** This PPX provides an extension point to create route paths.

    You can add it to your [dune] file in the usual way:
    [(preprocess (pps ppx_dream_html))].

    Then create a path: [let orders = [%route_path "/orders"]].

    And use it in a route: [Route.get orders (fun req -> ...)].

    This provides a convenient way to create route paths and reuse them
    throughout your app.  The way it works is by just duplicating the format
    string literal argument. However, this naturally means that both the route
    parser and attribute printer format strings are identical. If you need
    different formatting for the two, you can use the underlying [path] function. *)
