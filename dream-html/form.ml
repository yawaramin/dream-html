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

let error_expected_bool = "error.expected.bool"
let error_expected_char = "error.expected.char"
let error_expected_single = "error.expected.single"
let error_expected_int = "error.expected.int"
let error_expected_int32 = "error.expected.int32"
let error_expected_int64 = "error.expected.int64"
let error_expected_number = "error.expected.number"
let error_required = "error.required"
let error name msg = Error [name, msg]

let ensure message condition field name ty values =
  match field name ty values with
  | Ok v as ok -> if condition v then ok else error name message
  | Error _ as error -> error

let rec all ty result = function
  | [] -> result
  | x :: xs -> (
    match ty x, result with
    | Ok t, Ok r -> all ty (Ok (t :: r)) xs
    | (Error _ as e), _ -> e
    | _, (Error _ as e) -> e)

let all ty = all ty (Ok [])

let list name ty values =
  match all ty (Hashtbl.find_all values name) with
  | Ok _ as ok -> ok
  | Error msg -> error name msg

let optional name ty values =
  match Hashtbl.find_opt values name with
  | None -> Ok None
  | Some s -> (
    match ty s with
    | Ok v -> Ok (Some v)
    | Error msg -> error name msg)

let required name ty values =
  match Hashtbl.find_opt values name with
  | None -> error name error_required
  | Some s -> (
    match ty s with
    | Ok v -> Ok v
    | Error msg -> error name msg)

let string s = Ok s

let int s =
  try Ok (int_of_string s) with Failure _ -> Error error_expected_int

let int32 s =
  try Ok (Int32.of_string s) with Failure _ -> Error error_expected_int32

let int64 s =
  try Ok (Int64.of_string s) with Failure _ -> Error error_expected_int64

let char s =
  if String.length s = 1 then
    Ok s.[0]
  else
    Error error_expected_char

let float s =
  try Ok (float_of_string s) with Failure _ -> Error error_expected_number

let bool = function
  | "true" -> Ok true
  | "false" -> Ok false
  | _ -> Error error_expected_bool

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

let ( or ) decoder1 decoder2 values =
  match decoder1 values with
  | Ok _ as ok -> ok
  | Error _ -> decoder2 values

let validate form values =
  let htbl = Hashtbl.create 10 in
  List.iter (fun (name, value) -> Hashtbl.add htbl name value) values;
  form htbl

let pp_error =
  let open Fmt in
  brackets (list ~sep:semi (pair ~sep:comma string string))
