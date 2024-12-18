module R = Dream_html.Route
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

let test msg route target =
  Lwt_main.run
    (let* () = Lwt_io.printlf "🔎 %s" msg in
     let* resp = R.handler route (Dream.request ~target "") in
     debug resp)

let v2_header prev req =
  let open Lwt.Syntax in
  let+ resp = prev req in
  Dream.add_header resp "X-Api-Version" "2";
  resp

let get_account_version () =
  R.make ~meth:`GET "/accounts/%s/versions/%d" "/accounts/%s/versions/%d"
    (fun _req acc ver -> Dream.html (spf "Account: %s, version: %d" acc ver))

let get_order () =
  R.make ~meth:`GET "/orders/%s" "/orders/%s" (fun _ id -> Dream.html id)

let () =
  let gav = get_account_version ()
  and go = get_order () in
  test "Path params of different types" gav "/accounts/yxzefac/versions/2";
  test "Route search with fallthrough"
    R.(go || gav)
    "/accounts/yxzefac/versions/2";
  test "Route not found" R.(go || gav) "/v2/orders/yzlkjh";
  let scoped_v2 = R.(scope "/v2" v2_header go) in
  test "Scoped middleware" scoped_v2 "/v2/orders/yzlkjh";
  test "Scoped middleware no match" scoped_v2 "/v1/orders/yzlkjh"
