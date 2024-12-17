type ('r, 'p, 'u) t =
  { meth : Dream.method_ option;
    rfmt : ('r, 'u, Dream.response Dream.promise) format;
    afmt : ('p, unit, string, Pure_html.attr) format4;
    hdlr : Dream.request -> 'r
  }

let make ?meth rfmt afmt hdlr = { meth; rfmt; afmt; hdlr }
let format { rfmt = CamlinternalFormatBasics.Format (_, str); _ } = str
let href route = route.afmt
let nf = Dream.empty `Not_Found

let rec parse_int' ~pos ~len str buf =
  if pos < len then
    match str.[pos] with
    | '0' .. '9' as ch ->
      Buffer.add_char buf ch;
      parse_int' ~pos:(succ pos) ~len str buf
    | _ -> pos
  else
    pos

let parse_int ~pos ~len str =
  let buf = Buffer.create 8 in
  let new_pos = parse_int' ~pos ~len str buf in
  if pos = new_pos then
    None
  else
    Some (int_of_string (Buffer.contents buf), new_pos)

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
  if pos = new_pos then
    None
  else
    Some (Buffer.contents buf, new_pos)

let rec handler' :
    type r.
    pos:int ->
    len:int ->
    string ->
    (r, _, _, _, _, Dream.response Dream.promise) CamlinternalFormatBasics.fmt ->
    r ->
    Dream.response Dream.promise =
 fun ~pos ~len path fmt hdlr ->
  match fmt with
  | CamlinternalFormatBasics.Char fmt ->
    if pos < len then
      handler' ~pos:(succ pos) ~len path fmt (hdlr path.[pos])
    else
      nf
  | String (No_padding, fmt) -> (
    match parse_string ~pos ~len path with
    | Some (s, pos) -> handler' ~pos ~len path fmt (hdlr s)
    | None -> nf)
  | Int (Int_d, No_padding, No_precision, fmt) -> (
    match parse_int ~pos ~len path with
    | Some (i, pos) -> handler' ~pos ~len path fmt (hdlr i)
    | None -> nf)
  | String_literal (lit, fmt) ->
    let lit_len = String.length lit in
    if len - pos >= lit_len && StringLabels.sub path ~pos ~len:lit_len = lit
    then
      handler' ~pos:(pos + lit_len) ~len path fmt hdlr
    else
      nf
  | Char_literal (lit, fmt) ->
    if len - pos >= 1 && path.[pos] = lit then
      handler' ~pos:(succ pos) ~len path fmt hdlr
    else
      nf
  | End_of_format -> hdlr
  | _ -> assert false

let handler { rfmt; hdlr; meth; _ } req =
  match meth with
  | Some m when not (Dream.methods_equal (Dream.method_ req) m) ->
    Dream.empty `Method_Not_Allowed
  | _ -> (
    match rfmt with
    | CamlinternalFormatBasics.Format (fmt, _) ->
      let path = Dream.target req in
      let len = String.length path in
      handler' ~pos:0 ~len (Dream.target req) fmt (hdlr req))

let ( || ) route1 route2 =
  let open Lwt.Syntax in
  let hdlr req =
    let* resp = handler route1 req in
    match Dream.status resp with
    | `Not_Found -> handler route2 req
    | _ -> Lwt.return resp
  in
  make "" "" hdlr
