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

let () =
  Format.printf
    "
OK with age:
%a

OK without age:
%a

Error without name:
%a

Error with too low age and empty name:
%a

Error too many permissions:
%a

Error no permissions if not accept TOS:
%a
  "
    pp
    (validate user_form ["age", "42"; "name", "Bob"; "permissions", "r"])
    pp
    (validate user_form ["name", "Bob"])
    pp (validate user_form []) pp
    (validate user_form ["age", "10"; "name", ""])
    pp
    (validate user_form
       [ "age", "42";
         "name", "Bob";
         "permissions", "r";
         "permissions", "w";
         "permissions", "x";
         "permissions", "" ])
    pp
    (validate user_form ["permissions", "r"; "name", "Bob"])
