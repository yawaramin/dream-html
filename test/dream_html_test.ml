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
  let+ name = ensure "Must not be empty" (( <> ) "") required "name" string
  and+ age =
    ensure "Must be > 16"
      (Option.fold ~none:true ~some:(( < ) 16))
      optional "age" int
  in
  { name; age }

let () =
  Format.printf "
  %a
  %a
  %a
  %a
  " pp_user
    (Result.get_ok (validate user_form ["age", "42"; "name", "Bob"]))
    pp_user
    (Result.get_ok (validate user_form ["name", "Bob"]))
    pp_error
    (Result.get_error (validate user_form []))
    pp_error
    (Result.get_error (validate user_form ["age", "10"; "name", ""]))
