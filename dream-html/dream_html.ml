(* Copyright 2023 Yawar Amin

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

include Pure_html
module Form = Form

let form f ?csrf req =
  req
  |> Dream.form ?csrf
  |> Lwt.map @@ function
     | `Ok values -> (
       match Form.validate f values with
       | Ok a -> `Ok a
       | Error list -> `Invalid list)
     | `Expired (values, float) -> (
       match Form.validate f values with
       | Ok a -> `Expired (a, float)
       | Error list -> `Invalid list)
     | `Wrong_session values -> (
       match Form.validate f values with
       | Ok a -> `Wrong_session a
       | Error list -> `Invalid list)
     | `Invalid_token values -> (
       match Form.validate f values with
       | Ok a -> `Invalid_token a
       | Error list -> `Invalid list)
     | `Missing_token values -> (
       match Form.validate f values with
       | Ok a -> `Missing_token a
       | Error list -> `Invalid list)
     | `Many_tokens values -> (
       match Form.validate f values with
       | Ok a -> `Many_tokens a
       | Error list -> `Invalid list)
     | `Wrong_content_type -> `Wrong_content_type

let query f req =
  match Form.validate f (Dream.all_queries req) with
  | Ok a -> `Ok a
  | Error list -> `Invalid list

let respond ?status ?code ?headers node =
  Dream.html ?status ?code ?headers (to_string node)

let send ?text_or_binary ?end_of_message websocket node =
  Dream.send ?text_or_binary ?end_of_message websocket (to_string node)

let set_body resp node =
  Dream.set_body resp (to_string node);
  Dream.set_header resp "Content-Type" "text/html"

let write stream node = Dream.write stream (to_string node)

let csrf_tag req =
  let open HTML in
  input [name "dream.csrf"; type_ "hidden"; value "%s" (Dream.csrf_token req)]

let etag str = {|"|} ^ Digest.(str |> string |> to_hex) ^ {|"|}

let etag = function
  | `Strong k -> etag k
  | `Weak k -> "W/" ^ etag k

let max_header_len = 8190

let find_etag et str =
  if String.length str > max_header_len then
    invalid_arg "ETag too long"
  else
    str
    |> String.split_on_char ','
    |> List.find_opt (fun s -> String.trim s = et)

let if_none_match req ~key refresh =
  match key with
  | `None -> Dream.empty `Not_Found
  | (`Strong _ | `Weak _) as k -> (
    let new_etag = etag k in
    let refresh () =
      ()
      |> refresh
      |> Lwt.map (fun resp ->
             Dream.set_header resp "ETag" new_etag;
             resp)
    in
    match Dream.header req "If-None-Match" with
    | Some list -> (
      match find_etag new_etag list with
      | Some _ -> Dream.empty `Not_Modified
      | None -> refresh ())
    | None -> refresh ())

let if_match req ~key save =
  if
    match Dream.header req "If-Match", key with
    | None, _ | _, `None | Some "*", (`Strong _ | `Weak _) -> true
    | Some list, ((`Strong _ | `Weak _) as k) ->
      list |> find_etag (etag k) |> Option.is_some
  then
    save ()
  else
    Dream.empty `Precondition_Failed

module Path = Path

type ('r, 'p) path = ('r, 'p) Path.t
type ('r, 'p) route = ('r, 'p) Path.t -> (Dream.request -> 'r) -> Dream.route

let path rfmt afmt = { Path.rfmt; afmt }
let path_attr attr { Path.afmt; _ } = attr afmt
let pp_path f path = Format.pp_print_string f (string_of_format path.Path.rfmt)

let dream_method meth path func =
  meth (Path.to_dream path.Path.rfmt) (Path.handler path.rfmt func)

let get path = dream_method Dream.get path
let post path = dream_method Dream.post path
let put path = dream_method Dream.put path
let delete path = dream_method Dream.delete path
let head path = dream_method Dream.head path
let connect path = dream_method Dream.connect path
let options path = dream_method Dream.options path
let trace path = dream_method Dream.trace path
let patch path = dream_method Dream.patch path
let any path = dream_method Dream.any path

let redirect ?status ?code ?headers ?flash req (_, location) =
  Option.iter (Dream.add_flash_message req "flash") flash;
  Dream.redirect ?status ?code ?headers req location

let use = Dream.scope "/"

let static_asset path =
  get path (fun req ->
      let pathfmt = string_of_format path.rfmt in
      (* Serve the route [/foo/bar] from the local file [foo/bar]. *)
      let filepath =
        StringLabels.sub pathfmt ~pos:1 ~len:(String.length pathfmt - 1)
      in
      let open Lwt.Syntax in
      let+ resp = Dream.from_filesystem "" filepath req in

      (* We don't want to cache an error response *)
      if Dream.status_codes_equal (Dream.status resp) `OK then
        (* Cache successful response for a year. *)
        Dream.set_header resp "Cache-Control"
          "public, max-age=31536000, immutable";
      resp)

module Livereload = struct
  let enabled =
    match Sys.getenv "LIVERELOAD" with
    | "1" -> true
    | _ | (exception _) -> false

  let endpoint = "/_livereload"

  let script =
    if enabled then
      HTML.script []
        {|
(() => {
  const retryIntervalMs = 500;
  const socketUrl = `ws://${location.host}%s`;
  const s = new WebSocket(socketUrl);

  s.onopen = _evt => {
    console.debug("Live reload: WebSocket connection open");
  };

  s.onclose = _evt => {
    console.debug("Live reload: WebSocket connection closed");

    function reload() {
      const s2 = new WebSocket(socketUrl);

      s2.onerror = _evt => {
        setTimeout(reload, retryIntervalMs);
      };

      s2.onopen = _evt => {
        location.reload();
      };
    };

    reload();
  };

  s.onerror = evt => {
    console.debug("Live reload: WebSocket error:", evt);
  };
})()
  |}
        endpoint
    else
      HTML.null []

  let route =
    if enabled then
      Dream.get endpoint (fun _ ->
          Dream.websocket (fun sock ->
              Lwt.bind (Dream.receive sock) (fun _ ->
                  Dream.close_websocket sock)))
    else
      Dream.no_route
end
