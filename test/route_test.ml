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

let account_version = [%path "/accounts/%s/versions/%d"]
let order = [%path "/orders/%s"]

let get_account_version =
  Dream_html.get account_version (fun _req acc ver ->
      Dream.html (spf "Account: %s, version: %d" acc ver))

let get_order = Dream_html.get order (fun _ id -> Dream.html id)

let post_order =
  Dream_html.post order (fun _ id -> Dream.html ~status:`Created id)

let put_order = Dream_html.put order (fun _ id -> Dream.html id)

let test ?method_ msg routes target =
  Lwt_main.run
    (let* () = Lwt_io.printlf "🔎 %s" msg in
     let* resp = Dream.router routes (Dream.request ?method_ ~target "") in
     debug resp)

let () =
  test "Root path" [Dream_html.get [%path "/"] (fun _ -> Dream.html "ok")] "/";
  test "Parse a character"
    [ Dream_html.get [%path "/foo/%c/bar"] (fun _ ch ->
          Dream.html (String.make 1 ch)) ]
    "/foo/z/bar";
  test "Parse number fail" [get_account_version] "/accounts/a1/versions/two";
  test "Path params of different types" [get_account_version]
    "/accounts/yxzefac/versions/2";
  test "Route search with fallthrough"
    [get_order; get_account_version]
    "/accounts/yxzefac/versions/2";
  test "Route not found" [get_order; get_account_version] "/v2/orders/yzlkjh";
  test "Empty target" [get_order] "";
  test "Rest param after /"
    [Dream_html.any [%path "/%*s"] (fun _ _ s -> Dream.html s)]
    "/abc/def"
