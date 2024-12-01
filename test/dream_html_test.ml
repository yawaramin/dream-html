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
    age : int option
  }

let pp_user =
  let open Fmt in
  braces
    (record ~sep:semi
       [ field "name" (fun u -> u.name) string;
         field "age" (fun u -> u.age) (option int) ])

open Dream_html.Form

let user_form =
  let+ name = ensure "Must not be empty" (( <> ) "") required string "name"
  and+ age = optional (int ~min:16) "age" in
  { name; age }

let () =
  Format.printf
    "
  OK with age: %a

  OK without age: %a

  Error without name: %a

  Error with too low age and empty name: %a
  "
    pp_user
    (Result.get_ok (validate user_form ["age", "42"; "name", "Bob"]))
    pp_user
    (Result.get_ok (validate user_form ["name", "Bob"]))
    pp_error
    (Result.get_error (validate user_form []))
    pp_error
    (Result.get_error (validate user_form ["age", "10"; "name", ""]))
