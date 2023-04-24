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

type attr = { name : string; value : string }
type tag = { name : string; attrs : attr list; children : node list option }
and node = Tag of tag | Txt of string | Comment of string

type 'a to_attr = 'a -> attr
type 'a string_attr = ('a, unit, string, attr) format4 -> 'a
type std_tag = attr list -> node list -> node
type void_tag = attr list -> node

(* Loosely based on https://www.w3.org/TR/DOM-Parsing/ *)
let rec to_buffer buf =
  let p = Buffer.add_string buf in
  function
  | Tag { name = ""; children = Some children; _ } ->
    List.iter (to_buffer buf) children
  | Tag { name; attrs; children = None } ->
    p "<";
    p name;
    begin match attrs with
    | [] ->
      ()
    | _ ->
      List.iter (function
        | { name = ""; value = _ } ->
          ()
        | { name; value } ->
          p " ";
          p name;
          p {|="|};
          p value;
          p {|"|}) attrs;
    end;
    p ">"
  | Tag ({ name; children = Some children; _ } as non_void) ->
    (if name = "html" then p "<!DOCTYPE html>\n");
    to_buffer buf (Tag { non_void with children = None });
    List.iter (to_buffer buf) children;
    p "</"; p name; p ">\n"
  | Txt str ->
    p str
  | Comment str ->
    p "<!-- "; p str; p " -->\n"

let to_string node =
  let buf = Buffer.create 256 in
  to_buffer buf node;
  Buffer.contents buf

let pp ppf node = node |> to_string |> Format.pp_print_string ppf

let respond ?status ?code ?headers node =
  Dream.html ?status ?code ?headers @@ to_string node

let string_attr name fmt =
  Printf.ksprintf (fun s -> { name; value = Dream.html_escape s }) fmt

let bool_attr name value = { name; value = string_of_bool value }
let float_attr name value = { name; value = Printf.sprintf "%f" value }
let int_attr name value = { name; value = string_of_int value }

let tag name attrs children = Tag { name; attrs; children = Some children }
let void_tag name attrs = Tag { name; attrs; children = None }

let txt fmt = Printf.ksprintf (fun s -> Txt (Dream.html_escape s)) fmt

let comment str = Comment str
let raw str = Txt str

module Attr = struct
  let null = string_attr "" ""

  let accept fmt = string_attr "accept" fmt
  let action fmt = string_attr "action" fmt
  let alt fmt = string_attr "alt" fmt
  let autocomplete fmt = string_attr "autocomplete" fmt
  let autofocus = bool_attr "autofocus" true
  let capture fmt = string_attr "capture" fmt
  let charset fmt = string_attr "charset" fmt
  let checked = bool_attr "checked" true
  let class_ fmt = string_attr "class" fmt
  let color fmt = string_attr "color" fmt
  let content fmt = string_attr "content" fmt
  let dirname fmt = string_attr "dirname" fmt
  let disabled = bool_attr "disabled" true
  let for_ fmt = string_attr "for" fmt
  let height fmt = string_attr "height" fmt
  let high = float_attr"high"
  let href fmt = string_attr "href" fmt
  let id fmt = string_attr "id" fmt
  let lang fmt = string_attr "lang" fmt
  let list fmt = string_attr "list" fmt
  let low = float_attr"low"
  let max fmt = string_attr "max" fmt
  let maxlength = int_attr"maxlength"
  let method_ value = { name = "method"; value = Dream.method_to_string value }
  let min fmt = string_attr "min" fmt
  let minlength = int_attr"minlength"
  let multiple = bool_attr "multiple" true
  let name fmt = string_attr "name" fmt
  let onblur fmt = string_attr "onblur" fmt
  let onclick fmt = string_attr "onclick" fmt
  let optimum = float_attr"optimum"
  let pattern fmt = string_attr "pattern" fmt
  let placeholder fmt = string_attr "placeholder" fmt
  let readonly = bool_attr "readonly" true
  let required = bool_attr "required" true
  let rel fmt = string_attr "rel" fmt
  let rows = int_attr"rows"
  let size fmt = string_attr "size" fmt
  let sizes fmt = string_attr "sizes" fmt
  let src fmt = string_attr "src" fmt
  let step fmt = string_attr "step" fmt
  let style fmt = string_attr "style" fmt
  let tabindex = int_attr"tabindex"
  let title fmt = string_attr "title" fmt
  let type_ fmt = string_attr "type" fmt
  let value fmt = string_attr "value" fmt
  let width fmt = string_attr "width" fmt
end

module Tag = struct
  let null = tag "" []

  let a = tag"a"
  let area = void_tag"area"
  let abbr = tag"abbr"
  let article = tag"article"
  let b = tag"b"
  let base = void_tag"base"
  let br = void_tag"br"
  let body = tag"body"
  let button = tag"button"
  let col = void_tag"col"
  let datalist = tag"datalist"
  let details = tag"details"
  let del = tag"del"
  let div = tag"div"
  let embed = void_tag"embed"
  let form = tag"form"
  let h1 = tag"h1"
  let h2 = tag"h2"
  let h3 = tag"h3"
  let h4 = tag"h4"
  let head = tag"head"
  let header = tag"header"
  let hr = void_tag"hr"
  let html = tag"html"
  let img = void_tag"img"
  let input = void_tag"input"
  let label = tag"label"
  let li = tag"li"
  let link = void_tag"link"
  let main = tag"main"
  let meta = void_tag"meta"
  let meter = tag"meter"
  let option = tag"option"
  let p = tag"p"
  let progress = tag"progress"
  let script = tag"script"
  let source = void_tag"source"
  let span = tag"span"
  let summary = tag"summary"
  let textarea = tag"textarea"
  let track = void_tag"track"
  let title = tag"title"
  let ul = tag"ul"
  let wbr = void_tag"wbr"
end

module Hx = struct
  (* This is a boolean because it can be selectively switched off in some parts
     of the page. *)
  let boost = bool_attr"data-hx-boost"

  let confirm fmt = string_attr "data-hx-confirm" fmt
  let delete fmt = string_attr "data-hx-delete" fmt
  let get fmt = string_attr "data-hx-get" fmt
  let on fmt = string_attr "data-hx-on" fmt
  let post fmt = string_attr "data-hx-post" fmt
  let push_url fmt = string_attr "data-hx-push-url" fmt
  let select fmt = string_attr "data-hx-select" fmt
  let select_oob fmt = string_attr "data-hx-select-oob" fmt
  let swap fmt = string_attr "data-hx-swap" fmt
  let swap_oob fmt = string_attr "data-hx-swap-oob" fmt
  let target fmt = string_attr "data-hx-target" fmt
  let trigger fmt = string_attr "data-hx-trigger" fmt
  let vals fmt = string_attr "data-hx-vals" fmt
end
