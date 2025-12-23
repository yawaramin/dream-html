(* Copyright 2025 Yawar Amin

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
let error_expected_time = "error.expected.time"
let error_length = "error.length"
let error_range = "error.range"
let error_required = "error.required"
let error name msg = Error [name, msg]

let ensure message condition field ty name values =
  match field ty name values with
  | Ok v as ok -> if condition v then ok else error name message
  | Error _ as error -> error

let rec all ~min_length ~max_length ~len ty result = function
  | [] ->
    if len < min_length then
      Error error_length
    else
      result
  | x :: xs -> (
    let new_len = succ len in
    if new_len > max_length then
      Error error_length
    else
      match ty x, result with
      | Ok t, Ok r ->
        all ~min_length ~max_length ~len:new_len ty (Ok (t :: r)) xs
      | (Error _ as e), _ -> e
      | _, (Error _ as e) -> e)

let all ~min_length ~max_length ty =
  all ~min_length ~max_length ~len:0 ty (Ok [])

let list ?(min_length = 0) ?(max_length = Int.max_int) ty name values =
  match all ~min_length ~max_length ty (Hashtbl.find_all values name) with
  | Ok _ as ok -> ok
  | Error msg -> error name msg

let optional ty name values =
  match Hashtbl.find_opt values name with
  | None -> Ok None
  | Some s -> (
    match ty s with
    | Ok v -> Ok (Some v)
    | Error msg -> error name msg)

let required ?default ty name values =
  match Hashtbl.find_opt values name, default with
  | None, None -> error name error_required
  | None, Some v -> Ok v
  | Some s, _ -> (
    match ty s with
    | Ok v -> Ok v
    | Error msg -> error name msg)

let ok value _ = Ok value
let error name message _ = error name message

let ( let* ) form f values =
  match form values with
  | Ok v -> f v values
  | Error _ as e -> e

let ( let+ ) form f = ( let* ) form (fun v _ -> Ok (f v))

let ( and+ ) form1 form2 values =
  match form1 values, form2 values with
  | Ok v1, Ok v2 -> Ok (v1, v2)
  | Ok _, Error e2 -> Error e2
  | Error e1, Ok _ -> Error e1
  | Error e1, Error e2 -> Error (e2 @ e1)

let rec multiple n form =
  match n with
  | 0 -> ok []
  | _ ->
    let+ v = form (n - 1)
    and+ vs = multiple (n - 1) form in
    v :: vs

let string ?(min_length = 0) ?(max_length = Sys.max_string_length) s =
  let len = String.length s in
  if min_length <= len && len <= max_length then Ok s else Error error_length

let int ?(min = Int.min_int) ?(max = Int.max_int) s =
  match int_of_string s with
  | i when min <= i && i <= max -> Ok i
  | _ -> Error error_range
  | exception Failure _ -> Error error_expected_int

let int32 ?(min = Int32.min_int) ?(max = Int32.max_int) s =
  match Int32.of_string s with
  | i32 when Int32.compare min i32 <= 0 && Int32.compare i32 max <= 0 -> Ok i32
  | _ -> Error error_range
  | exception Failure _ -> Error error_expected_int

let int64 ?(min = Int64.min_int) ?(max = Int64.max_int) s =
  match Int64.of_string s with
  | i64 when Int64.compare min i64 <= 0 && Int64.compare i64 max <= 0 -> Ok i64
  | _ -> Error error_range
  | exception Failure _ -> Error error_expected_int

let min_char = Char.chr 0
let max_char = Char.chr 255

let char ?(min = min_char) ?(max = max_char) s =
  if String.length s = 1 then
    let c = s.[0] in
    if min <= c && c <= max then Ok c else Error error_range
  else
    Error error_expected_char

let float ?(min = -.Float.min_float) ?(max = Float.max_float) s =
  match float_of_string s with
  | i when min <= i && i <= max -> Ok i
  | _ -> Error error_range
  | exception Failure _ -> Error error_expected_int

let bool = function
  | "true" -> Ok true
  | "false" -> Ok false
  | _ -> Error error_expected_bool

let make_tm ?min ?max ?(hour = 0) ?(minute = 0) ?(second = 0) year month day =
  let tm =
    { Unix.tm_year = year - 1900;
      tm_mon = month - 1;
      tm_mday = day;
      tm_hour = hour;
      tm_min = minute;
      tm_sec = second;
      tm_wday = 0;
      tm_yday = 0;
      tm_isdst = false
    }
  in
  let f, tm = Unix.mktime tm in
  match min, max with
  | Some min, Some max ->
    let fmin, _ = Unix.mktime min
    and fmax, _ = Unix.mktime max in
    if fmin <= f && f <= fmax then Ok tm else Error error_range
  | Some min, None ->
    let fmin, _ = Unix.mktime min in
    if fmin <= f then Ok tm else Error error_range
  | None, Some max ->
    let fmax, _ = Unix.mktime max in
    if f <= fmax then Ok tm else Error error_range
  | None, None -> Ok tm

let unix_tm ?min ?max s =
  try
    Scanf.sscanf s "%4d-%2d-%d" (fun year month day ->
        make_tm ?min ?max year month day)
  with End_of_file -> (
    try
      Scanf.sscanf s "%4d-%d-%dT%2d:%2d:%2d"
        (fun year month day hour minute second ->
          make_tm ?min ?max ~hour ~minute ~second year month day)
    with End_of_file -> Error error_expected_time)

let ( or ) form1 form2 values =
  match form1 values with
  | Ok _ as ok -> ok
  | Error _ -> form2 values

let validate form values =
  let htbl = Hashtbl.create 10 in
  List.iter (fun (name, value) -> Hashtbl.add htbl name value) values;
  form htbl

let pp_error = Fmt.Dump.(list (pair string string))
