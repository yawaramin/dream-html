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
and node = Tag of tag | Txt of string

type string_attr = string -> attr
type int_attr = int -> attr
type std_tag = attr list -> node list -> node
type void_tag = attr list -> node

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
    (if name = "html" then p "<!doctype html>\n");
    to_buffer buf (Tag { non_void with children = None });
    List.iter (to_buffer buf) children;
    p "</"; p name; p ">\n"
  | Txt str ->
    p str

let to_string node =
  let buf = Buffer.create 256 in
  to_buffer buf node;
  Buffer.contents buf

let respond ?status ?code ?headers node =
  Dream.html ?status ?code ?headers @@ to_string node

let s = Printf.sprintf

let string_attr name value = { name; value = Dream.html_escape value }
let int_attr name value = string_attr name (string_of_int value)

let tag name attrs children = Tag { name; attrs; children = Some children }
let void_tag name attrs = Tag { name; attrs; children = None }
let txt str = Txt (Dream.html_escape str)
let raw str = Txt str

module Attr = struct
  let null = string_attr "" ""

  let action = string_attr"action"
  let autocomplete = string_attr"autocomplete"
  let autofocus = string_attr "autofocus" "true"
  let charset = string_attr"charset"
  let class_ = string_attr"class"
  let color = string_attr"color"
  let content = string_attr"content"
  let for_ = string_attr"for"
  let href = string_attr"href"
  let id = string_attr"id"
  let lang = string_attr"lang"
  let list = string_attr"list"
  let max = string_attr"max"
  let maxlength = int_attr"maxlength"
  let method_ = string_attr"method"
  let min = string_attr"min"
  let minlength = int_attr"minlength"
  let name = string_attr"name"
  let placeholder = string_attr"placeholder"
  let required = string_attr "required" "true"
  let rel = string_attr"rel"
  let rows = int_attr"rows"
  let sizes = string_attr"sizes"
  let src = string_attr"src"
  let style = string_attr"style"
  let tabindex = string_attr"tabindex"
  let title = string_attr"title"
  let type_ = string_attr"type"
  let value = string_attr"value"
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
  let option = tag"option"
  let p = tag"p"
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
  let confirm = string_attr"data-hx-confirm"
  let delete = string_attr"data-hx-delete"
  let get = string_attr"data-hx-get"
  let post = string_attr"data-hx-post"
  let swap = string_attr"data-hx-swap"
  let swap_oob = string_attr"data-hx-swap-oob"
  let target = string_attr"data-hx-target"
  let trigger = string_attr"data-hx-trigger"
end
