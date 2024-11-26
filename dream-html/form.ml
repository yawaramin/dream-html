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

type 'a ty = string -> ('a, string) result
type 'a t = (string, string) Hashtbl.t -> ('a, (string * string) list) result
type ('a, 'b) field = string -> 'a ty -> 'b t

let error name msg = Error [name, msg]

let ensure message condition cardinality name typ values =
  match cardinality name typ values with
  | Ok v as ok -> if condition v then ok else error name message
  | Error _ as error -> error

let rec all typ result = function
  | [] -> result
  | x :: xs -> (
    match typ x, result with
    | Ok t, Ok r -> all typ (Ok (t :: r)) xs
    | (Error _ as e), _ -> e
    | _, (Error _ as e) -> e)

let all typ = all typ (Ok [])

let list name typ values =
  match all typ (Hashtbl.find_all values name) with
  | Ok _ as ok -> ok
  | Error msg -> error name msg

let optional name typ values =
  match list name typ values with
  | Ok [] -> Ok None
  | Ok [x] -> Ok (Some x)
  | Ok _ -> error name "Please enter only a single value"
  | Error _ as e -> e

let required name typ values =
  match list name typ values with
  | Ok [] -> error name "Please fill out this field"
  | Ok (x :: _) -> Ok x
  | Error _ as e -> e

let string s = Ok s

let int s =
  try Ok (int_of_string s) with Failure _ -> Error "Please enter an integer"

let int32 s =
  try Ok (Int32.of_string s)
  with Failure _ -> Error "Please enter a 32-bit integer"

let int64 s =
  try Ok (Int64.of_string s)
  with Failure _ -> Error "Please enter a 64-bit integer"

let char s =
  if String.length s = 1 then
    Ok s.[0]
  else
    Error "Please enter a single character"

let float s =
  try Ok (float_of_string s) with Failure _ -> Error "Please enter a float"

let bool = function
  | "true" -> Ok true
  | "false" -> Ok false
  | _ -> Error "Please enter 'true' or 'false'"

let ( let+ ) decoder f values =
  match decoder values with
  | Ok v -> Ok (f v)
  | Error e -> Error e

let ( and+ ) decoder1 decoder2 values =
  match decoder1 values, decoder2 values with
  | Ok v1, Ok v2 -> Ok (v1, v2)
  | Ok _, Error e2 -> Error e2
  | Error e1, Ok _ -> Error e1
  | Error e1, Error e2 -> Error (e2 @ e1)

let validate form values =
  let htbl = Hashtbl.create 10 in
  List.iter (fun (name, value) -> Hashtbl.add htbl name value) values;
  form htbl

let pp_error =
  let open Fmt in
  brackets (list ~sep:semi (pair ~sep:comma string string))
