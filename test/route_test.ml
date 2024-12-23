(* Copyright 2024 Yawar Amin

   This file is part of dream-html.

   dream-html is free software: you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation, either version 3 of the License, or (at your option) any
   later version.

   dream-html is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
   details.

   You should have received a copy of the GNU General Public License along with
   dream-html. If not, see <https://www.gnu.org/licenses/>. *)

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

let handle_int _ i = Dream.html (string_of_int i)

let () =
  test "Root path" [Dream_html.get [%path "/"] (fun _ -> Dream.html "ok")] "/";
  test "Parse a character"
    [ Dream_html.get [%path "/foo/%c/bar"] (fun _ ch ->
          Dream.html (String.make 1 ch)) ]
    "/foo/z/bar";
  test "Parse a hex integer"
    [Dream_html.get [%path "/%x"] handle_int]
    "/0xdeadbeef";
  test "Parse an octal integer"
    [Dream_html.get [%path "/%o"] handle_int]
    "/0o644";
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
    "/abc/def";
  test "Use middleware list"
    [ Dream_html.use [v2_header]
        [Dream_html.get [%path "/v2/orders/%s"] (fun _ id -> Dream.html id)] ]
    "/v2/orders/o1"
