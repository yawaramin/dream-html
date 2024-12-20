(** This PPX provides convenience functions to create routes.

    You can add it to your [dune] file in the usual way:
    [(preprocess (pps ppx_dream_html))].

    The following functions are provided as wrappers for the
    [Dream_html.Route.make] function:

    [Dream_html.Route.get "..." handler]

    [Dream_html.Route.post "..." handler]

    And so on for each of the methods supported by Dream.

    Also,

    [Dream_html.Route.prefix "..." middleware handler]

    Is provided as a wrapper for the [Dream_html.Route.scope] function.

    These convenience functions save the developer from having to type the format
    strings two separate times, by just duplicating the format string literal
    argument. However, this naturally means that both the route parser and
    attribute printer format strings are identical. If you need different
    formatting for the two, you can use the underlying [make] and [scope]
    functions. *)
