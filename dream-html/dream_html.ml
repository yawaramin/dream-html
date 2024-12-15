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
module Component = Component

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
let csrf_tag req = req |> Dream.csrf_tag |> txt ~raw:true "%s"

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
    Dream.get endpoint (fun _ ->
        if enabled then
          Dream.websocket (fun sock ->
              Lwt.bind (Dream.receive sock) (fun _ ->
                  Dream.close_websocket sock))
        else
          Dream.empty `Not_Found)
end
