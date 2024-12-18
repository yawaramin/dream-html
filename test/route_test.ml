open Dream_html.Route

let pf = Printf.printf
let spf = Printf.sprintf

let debug resp =
  let open Lwt.Syntax in
  let+ b = Dream.body resp in
  let st = Dream.status resp
  and headers =
    resp
    |> Dream.all_headers
    |> List.map (fun (k, v) -> spf "%s: %s\n" k v)
    |> String.concat ""
  in
  pf "%d %s\n%s\n%s\n" (Dream.status_to_int st)
    (Dream.status_to_string st)
    headers b

let test route target =
  Dream.request ~target "" |> handler route |> Lwt_main.run |> debug

let addh prev req =
  let open Lwt.Syntax in
  let+ resp = prev req in
  Dream.add_header resp "X-Api-Server" "Dream";
  resp

let get_account_version =
  make ~meth:`GET "/accounts/%s/versions/%d" "/accounts/%s/versions/%d"
    (fun _req acc ver -> Dream.html (spf "Account: %s, version: %d" acc ver))

let get_order =
  make ~meth:`GET "/orders/%s" "/orders/%s" (fun _ id -> Dream.html id)
;;

test get_account_version "/accounts/yxzefac/versions/2";;
test (get_order || get_account_version) "/accounts/yxzefac/versions/2";;
test (get_order || get_account_version) "/v2/orders/yzlkjh"
