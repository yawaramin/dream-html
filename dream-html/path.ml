type ('r, 'p) t =
  { rfmt : ('r, unit, Dream.response Dream.promise) format;
    afmt : ('p, unit, string, Pure_html.attr) format4
  }

let make rfmt afmt = { rfmt; afmt }
let link { afmt; _ } = afmt
let nf path = Dream.respond ~status:`Not_Found path
let sub = StringLabels.sub

let pos_field =
  Dream.new_field ~name:"dream-html-route-pos" ~show_value:string_of_int ()

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
    ?pos:int ->
    len:int ->
    string ->
    (r, _, _, _, _, Dream.response Dream.promise) CamlinternalFormatBasics.fmt ->
    r ->
    Dream.response Dream.promise =
 fun ?(pos = 0) ~len path fmt hdlr ->
  match fmt with
  | CamlinternalFormatBasics.Char fmt ->
    if pos < len then
      handler' ~pos:(succ pos) ~len path fmt (hdlr path.[pos])
    else
      nf path
  | String (Arg_padding Right, End_of_format) ->
    let remaining_len = len - pos in
    let rest =
      if remaining_len > 0 then sub path ~pos ~len:remaining_len else ""
    in
    handler' ~pos:len ~len path End_of_format (hdlr len rest)
  | String (No_padding, fmt) -> (
    match parse_string ~pos ~len path with
    | Some (s, pos) -> handler' ~pos ~len path fmt (hdlr s)
    | None -> nf path)
  | Int (Int_d, No_padding, No_precision, fmt) -> (
    match parse_int ~pos ~len path with
    | Some (i, pos) -> handler' ~pos ~len path fmt (hdlr i)
    | None -> nf path)
  | String_literal (lit, fmt) ->
    handler' ~pos:(pos + String.length lit) ~len path fmt hdlr
  | Char_literal ('/', String (Arg_padding Right, End_of_format)) ->
    let remaining_len = len - pos in
    if remaining_len > 0 && path.[pos] = '/' then
      let len = remaining_len - 1 in
      handler' ~pos:len ~len path End_of_format
        (hdlr len (sub path ~pos:(pos + 1) ~len))
    else
      nf path
  | Char_literal (_, fmt) -> handler' ~pos:(succ pos) ~len path fmt hdlr
  | End_of_format -> hdlr
  | _ -> nf path

let handler rfmt hdlr req =
  match rfmt with
  | CamlinternalFormatBasics.Format (fmt, _) ->
    let path = Dream.target req in
    let len = String.length path
    and pos = Dream.field req pos_field in
    handler' ?pos ~len path fmt (hdlr req)

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
