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

module R = Dream_html.Route

let account_version = [%route_path "/accounts/%s/versions/%d"]
let order = [%route_path "/orders/%s"]

let get_account_version =
  R.get account_version (fun _req acc ver ->
      Dream.html (spf "Account: %s, version: %d" acc ver))

let get_order = R.get order (fun _ id -> Dream.html id)
let post_order = R.post order (fun _ id -> Dream.html ~status:`Created id)
let put_order = R.put order (fun _ id -> Dream.html id)
let opt_slash = R.make [%route_path "/foo%%"] (fun _ -> Dream.empty `OK)

let test ?method_ msg route target =
  Lwt_main.run
    (let* () = Lwt_io.printlf "🔎 %s" msg in
     let* resp = R.handler route (Dream.request ?method_ ~target "") in
     debug resp)

let () =
  test "Path params of different types" get_account_version
    "/accounts/yxzefac/versions/2";
  test "Route search with fallthrough"
    R.(get_order >> get_account_version)
    "/accounts/yxzefac/versions/2";
  test "Route not found"
    R.(get_order >> get_account_version)
    "/v2/orders/yzlkjh";
  test "Empty target" get_order "";
  let rest_hdlr _ _ s = Dream.html s in
  test "Rest param entire non-empty path"
    (R.make [%route_path "%*s"] rest_hdlr)
    "/foo";
  test "Rest param entire empty path" (R.make [%route_path "%*s"] rest_hdlr) "";
  test "Rest param after /"
    (R.make [%route_path "/%*s"] (fun _ _ s -> Dream.html s))
    "/abc";
  test "Optional slash at end" opt_slash "/foo/";
  test "Optional slash missing at end" opt_slash "/foo";
  test ~method_:`POST "Recover from method not allowed"
    R.(get_order >> put_order >> post_order)
    "/orders/foo";
  test ~method_:`POST "Fail with method not allowed"
    R.(get_account_version >> get_order)
    "/orders/foo";
  let scoped_v2 = R.(with_ v2_header get_order) in
  test "Middleware" scoped_v2 "/orders/yzlkjh"
