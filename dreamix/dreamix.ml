module DH = Dream_html

type resource =
  { segment : string;
    headers : (string * string) list;
    get : Dream.request -> DH.node -> DH.node Dream.promise;
    post : Dream.handler;
    middlewares : Dream.middleware list;
    children : resource list
  }

let resource ?(segment = "") ?(headers = [])
    ?(post = fun _ -> Dream.empty `Method_Not_Allowed) ?(middlewares = [])
    ?(children = []) get =
  { segment; headers; get; post; middlewares; children }

let script_htmx =
  let open DH.HTML in
  script
    [ src "https://unpkg.com/htmx.org@1.9.8";
      integrity
        "sha384-rgjA7mptc2ETQqXoYC3/zJvkU7K/aP44Y+z7xQuJiVnB/422P/Ak+F/AqFR7E4Wr";
      crossorigin `anonymous ]
    ""

let head attrs children = DH.HTML.head attrs (script_htmx :: children)
let sl = "/"

let path_id path =
  let with_ = "-" in
  let s1 = Stringext.replace_all path ~pattern:sl ~with_ in
  Stringext.replace_all s1 ~pattern:":" ~with_

let form req attrs children =
  let trgt = Dream.target req in
  let open DH in
  let open HTML in
  form
    (action "%s" trgt
    :: Hx.post "%s" trgt
    :: Hx.target "%s" (path_id (Dream.target req))
    :: Hx.swap "innerHTML"
    :: attrs)
    (csrf_tag req :: children)

let link to_ attrs children =
  let hx_target = path_id (Filename.dirname to_) in
  let open DH in
  let open HTML in
  a
    (href "%s" to_
    :: Hx.get "%s" to_
    :: Hx.target "%s" hx_target
    :: Hx.swap "innerHTML"
    :: attrs)
    children

let hx req =
  match Dream.header req "HX-Request" with
  | Some "true" -> true
  | _ -> false

let rec router path
    { segment; headers = hdrs; get; post; middlewares; children } =
  let get_handler req =
    if hx req then
      let open DH in
      let open HTML in
      let open Lwt.Syntax in
      let* node = get req (div [id "%s" (path_id (Dream.target req))] []) in
      respond ~headers:hdrs node
    else
      Dream.redirect req sl
  and new_path = if path = sl then path ^ segment else path ^ sl ^ segment in
  Dream.scope path middlewares
    (Dream.get sl get_handler
    :: Dream.post sl post
    :: List.map (router new_path) children)

let router resource = router "" resource

let run ?interface ?port ?stop ?error_handler ?tls ?certificate_file ?key_file
    ?builtins ?greeting ?adjust_terminal resource =
  Dream.run ?interface ?port ?stop ?error_handler ?tls ?certificate_file
    ?key_file ?builtins ?greeting ?adjust_terminal
    (Dream.router
       [router resource; Dream.get "/static/**" (Dream.static "static")])
