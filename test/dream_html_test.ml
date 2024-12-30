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

type user =
  { name : string;
    age : int option;
    accept_tos : bool;
    permissions : string list
  }

let pp_user =
  let open Fmt in
  braces
    (record ~sep:semi
       [ field "name" (fun u -> u.name) string;
         field "age" (fun u -> u.age) (option int);
         field "accept_tos" (fun u -> u.accept_tos) bool;
         field "permissions"
           (fun u -> u.permissions)
           (brackets (list ~sep:semi string)) ])

type item =
  { id : string;
    qty : int;
    discount : int
  }

let pp_item =
  let open Fmt in
  braces
    (record ~sep:semi
       [ field "id" (fun item -> item.id) string;
         field "qty" (fun item -> item.qty) int;
         field "discount" (fun item -> item.discount) int ])

type invoice =
  { item_count : int;
    items : item list
  }

let pp_invoice =
  let open Fmt in
  braces
    (record ~sep:semi
       [ field "item_count" (fun invoice -> invoice.item_count) int;
         field "items"
           (fun invoice -> invoice.items)
           (brackets (list ~sep:semi pp_item)) ])

let pp_form pp fmt = function
  | Ok user -> pp fmt user
  | Error e -> Dream_html.Form.pp_error fmt e

open Dream_html.Form

let user_form =
  let* accept_tos = required ~default:false bool "accept-tos" in
  let+ permissions =
    list
      ~max_length:(if accept_tos then 3 else 0)
      (string ~min_length:1) "permissions"
  and+ name = ensure "Must not be empty" (( <> ) "") required string "name"
  and+ age = optional (int ~min:16) "age" in
  { name; age; accept_tos; permissions }

let item n =
  let nth name = "item[" ^ string_of_int n ^ "]." ^ name in
  let+ id = required string (nth "id")
  and+ qty = required int (nth "qty")
  and+ discount = required ~default:0 int (nth "discount") in
  { id; qty; discount }

let invoice =
  let* item_count = required int "item-count" in
  let+ items = multiple item_count item in
  { item_count; items }

let test_handler handler target =
  Lwt_main.run
    (let open Lwt.Syntax in
     let* resp = handler (Dream.request ~target "") in
     let+ b = Dream.body resp in
     let st = Dream.status resp in
     Format.printf "%d %s\n\n%s\n" (Dream.status_to_int st)
       (Dream.status_to_string st)
       b)

let test msg output =
  Printf.printf "\n\n🔎 %s\n%!" msg;
  output ()

let test_form msg form pp data =
  test msg @@ fun () -> Format.printf "%a%!" pp (validate form data)

let pp_user = pp_form pp_user
let pp_invoice = pp_form pp_invoice

let () =
  test_form "OK with age" user_form pp_user
    ["accept-tos", "true"; "age", "42"; "name", "Bob"; "permissions", "r"];
  test_form "OK without age" user_form pp_user
    ["accept-tos", "true"; "name", "Bob"; "permissions", "r"];
  test_form "Error without name" user_form pp_user
    ["accept-tos", "true"; "age", "42"; "permissions", "r"];
  test_form "Error with too low age and empty name" user_form pp_user
    ["accept-tos", "true"; "age", "1"; "name", ""; "permissions", "r"];
  test_form "Error too many permissions" user_form pp_user
    [ "accept-tos", "true";
      "age", "42";
      "name", "Bob";
      "permissions", "r";
      "permissions", "w";
      "permissions", "x";
      "permissions", "" ];
  test_form "Error can't have permissions if not accept TOS" user_form pp_user
    ["name", "Bob"; "permissions", "r"];
  test_form "OK multiple nested values inside form" invoice pp_invoice
    [ "item[0].id", "abc";
      "item[0].qty", "1";
      "item[1].id", "def";
      "item[1].qty", "10";
      "item[1].discount", "25";
      "item-count", "2" ];
  test_form "Error missing required fields of nested values" invoice pp_invoice
    [ "item[0].qty", "1";
      "item[1].id", "def";
      "item[1].discount", "25";
      "item-count", "2" ]

let () =
  test "Indent CSRF tag correctly" @@ fun () ->
  let handler =
    Dream.memory_sessions (fun req ->
        let open Dream_html in
        let open HTML in
        respond
          (form
             [method_ `POST; action "/"]
             [ csrf_tag req -@ "value" +@ value "token-value";
               input [name "id"];
               button [type_ "submit"] [txt "Add"] ]))
  in
  test_handler handler "/"
