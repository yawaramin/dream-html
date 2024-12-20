open Lwt.Syntax

let spf = Printf.sprintf

let debug resp =
  let* b = Dream.body resp in
  let st = Dream.status resp
  and headers =
    resp
    |> Dream.all_headers
    |> List.map (fun (k, v) -> spf "%s: %s\n" k v)
    |> String.concat ""
  in
  Lwt_io.printlf "%d %s\n%s\n%s\n" (Dream.status_to_int st)
    (Dream.status_to_string st)
    headers b

let v2_header prev req =
  let open Lwt.Syntax in
  let+ resp = prev req in
  Dream.add_header resp "X-Api-Version" "2";
  resp

let get_account_version =
  Dream_html.Route.get "/accounts/%s/versions/%d" (fun _req acc ver ->
      Dream.html (spf "Account: %s, version: %d" acc ver))

let get_order = Dream_html.Route.get "/orders/%s" (fun _ id -> Dream.html id)

let post_order =
  Dream_html.Route.post "/orders/%s" (fun _ id ->
      Dream.html ~status:`Created id)

let put_order = Dream_html.Route.put "/orders/%s" (fun _ id -> Dream.html id)
let opt_slash = Dream_html.Route.make "/foo%%" "/foo" (fun _ -> Dream.empty `OK)

module R = Dream_html.Route

let test ?method_ msg route target =
  Lwt_main.run
    (let* () = Lwt_io.printlf "🔎 %s" msg in
     let* resp = R.handler route (Dream.request ?method_ ~target "") in
     debug resp)

let () =
  test "Path params of different types" get_account_version
    "/accounts/yxzefac/versions/2";
  test "Route search with fallthrough"
    R.(get_order || get_account_version)
    "/accounts/yxzefac/versions/2";
  test "Route not found"
    R.(get_order || get_account_version)
    "/v2/orders/yzlkjh";
  test "Empty target" get_order "";
  let rest_hdlr _ _ s = Dream.html s in
  test "Rest param entire non-empty path" (R.make "%*s" "" rest_hdlr) "/foo";
  test "Rest param entire empty path" (R.make "%*s" "" rest_hdlr) "";
  test "Rest param after /"
    (R.make "/%*s" "" (fun _ _ s -> Dream.html s))
    "/abc";
  test "Optional slash at end" opt_slash "/foo/";
  test "Optional slash missing at end" opt_slash "/foo";
  test ~method_:`POST "Recover from method not allowed"
    R.(get_order || put_order || post_order)
    "/orders/foo";
  test ~method_:`POST "Fail with method not allowed"
    R.(get_account_version || get_order)
    "/orders/foo";
  let scoped_v2 = R.(scope "/v2" "/v2" v2_header get_order) in
  test "Scoped middleware" scoped_v2 "/v2/orders/yzlkjh";
  test "Scoped middleware no match" scoped_v2 "/v1/orders/yzlkjh"
