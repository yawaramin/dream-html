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

type ('r, 'p) t =
  { rfmt : ('r, unit, Dream.response Dream.promise) format;
    afmt : ('p, unit, string, Pure_html.attr) format4
  }

let make rfmt afmt = { rfmt; afmt }
let link { afmt; _ } = afmt
let sub = StringLabels.sub

let rec parse_string' ~pos ~len str buf =
  if pos < len then (
    match str.[pos] with
    | '/' -> pos
    | ch ->
      Buffer.add_char buf ch;
      parse_string' ~pos:(succ pos) ~len str buf)
  else
    pos

let parse_string ~pos ~len str =
  let buf = Buffer.create 8 in
  let new_pos = parse_string' ~pos ~len str buf in
  Buffer.contents buf, new_pos

let rec handler' :
    type r.
    ?pos:int ->
    len:int ->
    string ->
    (r, _, _, _, _, Dream.response Dream.promise) CamlinternalFormatBasics.fmt ->
    r ->
    Dream.response Dream.promise =
 fun ?(pos = 0) ~len path fmt hdlr ->
  match fmt with
  | CamlinternalFormatBasics.Char fmt ->
    (* %c *)
    handler' ~pos:(pos + 2) ~len path fmt (hdlr path.[pos])
  | String (Arg_padding Right, End_of_format) ->
    let remaining_len = len - pos in
    let rest =
      if remaining_len > 0 then sub path ~pos ~len:remaining_len else ""
    in
    handler' ~pos:len ~len path End_of_format (hdlr len rest)
  | String (No_padding, fmt) ->
    let s, pos = parse_string ~pos ~len path in
    handler' ~pos ~len path fmt (hdlr s)
  | Int (Int_d, No_padding, No_precision, fmt) -> (
    let s, pos = parse_string ~pos ~len path in
    match int_of_string_opt s with
    | Some i -> handler' ~pos ~len path fmt (hdlr i)
    | None -> Dream.respond ~status:`Bad_Request path)
  | Int32 (Int_d, No_padding, No_precision, fmt) -> (
    let s, pos = parse_string ~pos ~len path in
    match Int32.of_string_opt s with
    | Some i -> handler' ~pos ~len path fmt (hdlr i)
    | None -> Dream.respond ~status:`Bad_Request path)
  | Int64 (Int_d, No_padding, No_precision, fmt) -> (
    let s, pos = parse_string ~pos ~len path in
    match Int64.of_string_opt s with
    | Some i -> handler' ~pos ~len path fmt (hdlr i)
    | None -> Dream.respond ~status:`Bad_Request path)
  | Float ((Float_flag_, Float_f), No_padding, No_precision, fmt) -> (
    let s, pos = parse_string ~pos ~len path in
    match Float.of_string_opt s with
    | Some f -> handler' ~pos ~len path fmt (hdlr f)
    | None -> Dream.respond ~status:`Bad_Request path)
  | Bool (No_padding, fmt) -> (
    let s, pos = parse_string ~pos ~len path in
    match bool_of_string_opt s with
    | Some b -> handler' ~pos ~len path fmt (hdlr b)
    | None -> Dream.respond ~status:`Bad_Request path)
  | String_literal (lit, fmt) ->
    handler' ~pos:(pos + String.length lit) ~len path fmt hdlr
  | Char_literal ('/', String (Arg_padding Right, End_of_format)) ->
    let remaining_len = len - pos - 1 in
    handler' ~pos:len ~len path End_of_format
      (hdlr remaining_len (sub path ~pos:(pos + 1) ~len:remaining_len))
  | Char_literal (_, fmt) -> handler' ~pos:(succ pos) ~len path fmt hdlr
  | End_of_format -> hdlr
  | _ -> Dream.respond ~status:`Not_Found path

let handler (CamlinternalFormatBasics.Format (fmt, _)) hdlr req =
  let path = Dream.target req in
  handler' ~len:(String.length path) path fmt (hdlr req)

let to_dream rfmt =
  rfmt
  |> string_of_format
  |> String.split_on_char '/'
  |> List.mapi (fun i s ->
         if s = "%*s" then
           "**"
         else if String.starts_with ~prefix:"%" s then
           Printf.sprintf ":param%d" i
         else
           s)
  |> String.concat "/"
