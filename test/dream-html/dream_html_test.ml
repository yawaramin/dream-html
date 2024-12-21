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

let test_handler handler target =
  Lwt_main.run
    (let open Lwt.Syntax in
     let* resp = handler (Dream.request ~target "") in
     let+ b = Dream.body resp in
     let st = Dream.status resp in
     Format.printf "%d %s\n" (Dream.status_to_int st)
       (Dream.status_to_string st);
     Format.printf "%s\n" b)

let pp fmt = function
  | Ok user -> pp_user fmt user
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

let%expect_test "OK with age" =
  Format.printf "%a" pp
    (validate user_form
       ["accept-tos", "true"; "age", "42"; "name", "Bob"; "permissions", "r"]);
  [%expect
    {|
    {name: Bob;
     age: 42;
     accept_tos: true;
     permissions: [r]}
    |}]

let%expect_test "OK without age" =
  Format.printf "%a" pp
    (validate user_form
       ["accept-tos", "true"; "name", "Bob"; "permissions", "r"]);
  [%expect
    {|
    {name: Bob;
     age: ;
     accept_tos: true;
     permissions: [r]}
    |}]

let%expect_test "Error without name" =
  Format.printf "%a" pp
    (validate user_form ["accept-tos", "true"; "age", "42"; "permissions", "r"]);
  [%expect {| [name, error.required] |}]

let%expect_test "Error with too low age and empty name" =
  Format.printf "%a" pp
    (validate user_form
       ["accept-tos", "true"; "age", "1"; "name", ""; "permissions", "r"]);
  [%expect {| [age, error.range; name, Must not be empty] |}]

let%expect_test "Error too many permissions" =
  Format.printf "%a" pp
    (validate user_form
       [ "accept-tos", "true";
         "age", "42";
         "name", "Bob";
         "permissions", "r";
         "permissions", "w";
         "permissions", "x";
         "permissions", "" ]);
  [%expect {| [permissions, error.length] |}]

let%expect_test "Error can't have permissions if not accept TOS" =
  Format.printf "%a" pp (validate user_form ["name", "Bob"; "permissions", "r"]);
  [%expect {| [permissions, error.length] |}]

let%expect_test "Indent CSRF tag correctly" =
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
  test_handler handler "/";
  [%expect {|
    200 OK
    <form method="post" action="/">
      <input value="token-value" name="dream.csrf" type="hidden">
      <input name="id">
      <button type="submit">Add</button>
    </form> |}]
