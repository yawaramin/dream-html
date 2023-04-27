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
type 'a text_tag = attr list -> ('a, unit, string, node) format4 -> 'a

let write_attr p = function
  | { name = ""; value = _ } ->
    ()
  | { name; value } ->
    p " ";
    p name;
    p {|="|};
    p value;
    p {|"|}

(* Loosely based on https://www.w3.org/TR/DOM-Parsing/ *)
let rec write_tag p = function
  | Tag { name = ""; children = Some children; _ } ->
    List.iter (write_tag p) children
  | Tag { name; attrs; children = None } ->
    p "<";
    p name;
    begin match attrs with
    | [] -> ()
    | _ -> List.iter (write_attr p) attrs
    end;
    p ">"
  | Tag ({ name; children = Some children; _ } as non_void) ->
    (if name = "html" then p "<!DOCTYPE html>\n");
    write_tag p (Tag { non_void with children = None });
    List.iter (write_tag p) children;
    p "</"; p name; p ">\n"
  | Txt str ->
    p str
  | Comment str ->
    p "<!-- "; p str; p " -->\n"

let to_string node =
  let buf = Buffer.create 256 in
  write_tag (Buffer.add_string buf) node;
  Buffer.contents buf

let pp ppf node = node |> to_string |> Format.pp_print_string ppf

let respond ?status ?code ?headers node =
  Dream.html ?status ?code ?headers @@ to_string node

let escape raw = if raw then Fun.id else Dream.html_escape

let string_attr name ?(raw=false) fmt =
  Printf.ksprintf (fun s -> { name; value = escape raw s }) fmt

let bool_attr name value = { name; value = string_of_bool value }
let float_attr name value = { name; value = Printf.sprintf "%f" value }
let int_attr name value = { name; value = string_of_int value }

let std_tag name attrs children = Tag { name; attrs; children = Some children }
let void_tag name attrs = Tag { name; attrs; children = None }

let text_tag name ?(raw=false) attrs fmt =
  Printf.ksprintf
  (fun s -> Tag { name; attrs; children = Some [Txt (escape raw s)]})
  fmt

let txt ?(raw=false) fmt = Printf.ksprintf (fun s -> Txt (escape raw s)) fmt
let comment str = Comment (Dream.html_escape str)

module Attr = struct
  type method_ = [`GET | `POST]
  type enctype = [`urlencoded | `formdata | `text_plain]

  let enctype_string = function
    | `urlencoded -> "application/x-www-form-urlencoded"
    | `formdata -> "multipart/form-data"
    | `text_plain -> "text/plain"


  let null = string_attr "" ""

  let accept fmt = string_attr "accept" fmt
  let accept_charset fmt = string_attr "accept-charset" fmt
  let accesskey fmt = string_attr "accesskey" fmt
  let action fmt = string_attr "action" fmt
  let align fmt = string_attr "align" fmt
  let allow fmt = string_attr "allow" fmt
  let alt fmt = string_attr "alt" fmt
  let async = bool_attr "async" true

  let autocapitalize value = {
    name = "autocapitalize";
    value = match value with
      | `off -> "off"
      | `none -> "none"
      | `on -> "on"
      | `sentences -> "sentences"
      | `words -> "words"
      | `characters -> "characters"
  }

  let autocomplete fmt = string_attr "autocomplete" fmt
  let autofocus = bool_attr "autofocus" true
  let autoplay = bool_attr "autoplay" true
  let buffered fmt = string_attr "buffered" fmt
  let capture fmt = string_attr "capture" fmt
  let charset fmt = string_attr "charset" fmt
  let checked = bool_attr "checked" true
  let cite fmt = string_attr "cite" fmt
  let class_ fmt = string_attr "class" fmt
  let color fmt = string_attr "color" fmt
  let cols = int_attr "cols"
  let colspan = int_attr "cols"
  let content fmt = string_attr "content" fmt
  let contenteditable = bool_attr "contenteditable"
  let contextmenu fmt = string_attr "contextmenu" fmt
  let controls = bool_attr "controls" true
  let coords fmt = string_attr "coords" fmt

  let crossorigin value = {
    name = "crossorigin";
    value = match value with
      | `anonymous -> "anonymous"
      | `use_credentials -> "use-credentials"
  }

  let data fmt = string_attr "data" fmt
  let datetime fmt = string_attr "datetime" fmt

  let decoding value = {
    name = "decoding";
    value = match value with
      | `sync -> "sync"
      | `async -> "async"
      | `auto -> "auto"
  }

  let default = bool_attr "default" true
  let defer = bool_attr "defer" true

  let dir value = {
    name = "dir";
    value = match value with
      | `ltr -> "ltr"
      | `rtl -> "rtl"
      | `auto -> "auto"
  }

  let dirname fmt = string_attr "dirname" fmt
  let disabled = bool_attr "disabled" true
  let download fmt = string_attr "download" fmt
  let draggable = bool_attr "draggable" true
  let enctype value = { name = "enctype"; value = enctype_string value }
  let for_ fmt = string_attr "for" fmt
  let form fmt = string_attr "form" fmt
  let formaction fmt = string_attr "formaction" fmt
  let formenctype value = { name = "formenctype"; value = enctype_string value }
  let formmethod value = { name = "formmethod"; value = Dream.method_to_string value }
  let formnovalidate = bool_attr "formnovalidate" true
  let formtarget fmt = string_attr "formtarget" fmt
  let headers fmt = string_attr "headers" fmt
  let height fmt = string_attr "height" fmt

  let hidden value = {
    name = "hidden";
    value = match value with
      | `hidden -> "hidden"
      | `until_found -> "until-found";
  }

  let high = float_attr "high"
  let href fmt = string_attr "href" fmt
  let hreflang fmt = string_attr "hreflang" fmt

  let http_equiv value = {
    name = "http-equiv";
    value = match value with
      | `content_security_policy -> "content-security-policy"
      | `content_type -> "content-type"
      | `default_style -> "default-style"
      | `x_ua_compatible -> "x-ua-compatible"
      | `refresh -> "refresh"
  }

  let id fmt = string_attr "id" fmt
  let integrity fmt = string_attr "integrity" fmt

  let inputmode value = {
    name = "inputmode";
    value = match value with
      | `none -> "none"
      | `text -> "text"
      | `decimal -> "decimal"
      | `numeric -> "numeric"
      | `tel -> "tel"
      | `search -> "search"
      | `email -> "email"
      | `url -> "url"
  }

  let ismap = bool_attr "ismap" true
  let itemprop fmt = string_attr "itemprop" fmt

  let kind value = {
    name = "kind";
    value = match value with
      | `subtitles -> "subtitles"
      | `captions -> "captions"
      | `descriptions -> "descriptions"
      | `chapters -> "chapters"
      | `metadata -> "metadata"
  }

  let label fmt = string_attr "label" fmt
  let lang fmt = string_attr "lang" fmt
  let list fmt = string_attr "list" fmt
  let loop = bool_attr "loop" true
  let low = float_attr "low"
  let max fmt = string_attr "max" fmt
  let maxlength = int_attr "maxlength"
  let media fmt = string_attr "media" fmt
  let method_ value = { name = "method"; value = Dream.method_to_string value }
  let min fmt = string_attr "min" fmt
  let minlength = int_attr "minlength"
  let multiple = bool_attr "multiple" true
  let muted = bool_attr "muted" true
  let name fmt = string_attr "name" fmt
  let novalidate = bool_attr "novalidate" true
  let onblur fmt = string_attr "onblur" ~raw:true fmt
  let onclick fmt = string_attr "onclick" ~raw:true fmt
  let open_ = bool_attr "open" true
  let optimum = float_attr "optimum"
  let pattern fmt = string_attr "pattern" fmt
  let ping fmt = string_attr "ping" fmt
  let placeholder fmt = string_attr "placeholder" fmt
  let playsinline = bool_attr "playsinline" true
  let poster fmt = string_attr "poster" fmt

  let preload value = {
    name = "preload";
    value = match value with
      | `none -> "none"
      | `metadata -> "metadata"
      | `auto -> "auto"
  }

  let readonly = bool_attr "readonly" true
  let referrerpolicy fmt = string_attr "referrerpolicy " fmt
  let rel fmt = string_attr "rel" fmt
  let required = bool_attr "required" true
  let reversed = bool_attr "reversed" true
  let role fmt = string_attr "role" fmt
  let rows = int_attr "rows"
  let rowspan = int_attr "rowspan"
  let sandbox fmt = string_attr "sandbox" fmt
  let scope fmt = string_attr "scope" fmt
  let selected = bool_attr "selected" true
  let shape fmt = string_attr "shape" fmt
  let size fmt = string_attr "size" fmt
  let sizes fmt = string_attr "sizes" fmt
  let slot fmt = string_attr "slot" fmt
  let span = int_attr "span"
  let spellcheck = bool_attr "spellcheck"
  let src fmt = string_attr "src" fmt
  let srcdoc fmt = string_attr "srcdoc" fmt
  let srclang fmt = string_attr "srclang" fmt
  let srcset fmt = string_attr "srcset" fmt
  let start = int_attr "start"
  let step fmt = string_attr "step" fmt
  let style fmt = string_attr "style" fmt
  let tabindex = int_attr "tabindex"
  let target fmt = string_attr "target" fmt
  let title fmt = string_attr "title" fmt

  let translate value = {
    name = "translate";
    value = match value with
      | `yes -> "yes"
      | `no -> "no"
  }

  let type_ fmt = string_attr "type" fmt
  let usemap fmt = string_attr "usemap" fmt
  let value fmt = string_attr "value" fmt
  let width fmt = string_attr "width" fmt

  let wrap value = {
    name = "wrap";
    value = match value with
      | `hard -> "hard"
      | `soft -> "soft"
  }
end

module Tag = struct
  let null = std_tag "" []

  let a = std_tag "a"
  let address = std_tag "address"
  let abbr = std_tag "abbr"
  let area = void_tag "area"
  let article = std_tag "article"
  let aside = std_tag "aside"
  let audio = std_tag "audio"
  let b = std_tag "b"
  let base = void_tag "base"
  let bdi = std_tag "bdi"
  let bdo = std_tag "bdo"
  let blockquote = std_tag "blockquote"
  let br = void_tag "br"
  let body = std_tag "body"
  let button = std_tag "button"
  let canvas = std_tag "canvas"
  let caption = std_tag "caption"
  let cite = std_tag "cite"
  let code = std_tag "code"
  let col = void_tag "col"
  let colgroup = std_tag "colgroup"
  let data = std_tag "data"
  let datalist = std_tag "datalist"
  let dd = std_tag "dd"
  let del = std_tag "del"
  let details = std_tag "details"
  let dfn = std_tag "dfn"
  let dialog = std_tag "dialog"
  let div = std_tag "div"
  let dl = std_tag "dl"
  let dt = std_tag "dt"
  let em = std_tag "em"
  let embed = void_tag "embed"
  let fieldset = std_tag "fieldset"
  let figcaption = std_tag "figcaption"
  let figure = std_tag "figure"
  let footer = std_tag "footer"
  let form = std_tag "form"
  let h1 = std_tag "h1"
  let h2 = std_tag "h2"
  let h3 = std_tag "h3"
  let h4 = std_tag "h4"
  let h5 = std_tag "h5"
  let h6 = std_tag "h6"
  let head = std_tag "head"
  let header = std_tag "header"
  let hgroup = std_tag "hgroup"
  let hr = void_tag "hr"
  let html = std_tag "html"
  let i = std_tag "i"
  let iframe = std_tag "iframe"
  let img = void_tag "img"
  let input = void_tag "input"
  let ins = std_tag "ins"
  let kbd = std_tag "kbd"
  let label = std_tag "label"
  let legend = std_tag "legend"
  let li = std_tag "li"
  let link = void_tag "link"
  let main = std_tag "main"
  let map = std_tag "map"
  let mark = std_tag "mark"
  let menu = std_tag "menu"
  let meta = void_tag "meta"
  let meter = std_tag "meter"
  let nav = std_tag "nav"
  let noscript = std_tag "noscript"
  let object_ = std_tag "object"
  let ol = std_tag "ol"
  let optgroup = std_tag "optgroup"
  let option attrs fmt = text_tag "option" attrs fmt
  let output = std_tag "output"
  let p = std_tag "p"
  let picture = std_tag "picture"
  let pre = std_tag "pre"
  let progress = std_tag "progress"
  let q = std_tag "q"
  let rp = std_tag "rp"
  let rt = std_tag "rt"
  let ruby = std_tag "ruby"
  let s = std_tag "s"
  let samp = std_tag "samp"
  let script attrs fmt = text_tag "script" ~raw:true attrs fmt
  let section = std_tag "section"
  let select = std_tag "select"
  let slot = std_tag "slot"
  let small = std_tag "small"
  let source = void_tag "source"
  let span = std_tag "span"
  let strong = std_tag "strong"
  let style attrs fmt = text_tag "style" ~raw:true attrs fmt
  let sub = std_tag "sub"
  let sup = std_tag "sup"
  let summary = std_tag "summary"
  let table = std_tag "table"
  let tbody = std_tag "tbody"
  let td = std_tag "td"
  let template = std_tag "template"
  let textarea attrs fmt = text_tag "textarea" attrs fmt
  let tfoot = std_tag "tfoot"
  let th = std_tag "th"
  let thead = std_tag "thead"
  let time = std_tag "time"
  let title attrs fmt = text_tag "title" attrs fmt
  let tr = std_tag "tr"
  let track = void_tag "track"
  let u = std_tag "u"
  let ul = std_tag "ul"
  let var = std_tag "var"
  let video = std_tag "video"
  let wbr = void_tag "wbr"
end

module Hx = struct
  (* This is a boolean because it can be selectively switched off in some parts
     of the page. *)
  let boost = bool_attr "data-hx-boost"

  let confirm fmt = string_attr "data-hx-confirm" fmt
  let delete fmt = string_attr "data-hx-delete" fmt
  let get fmt = string_attr "data-hx-get" fmt
  let on fmt = string_attr "data-hx-on" ~raw:true fmt
  let post fmt = string_attr "data-hx-post" fmt
  let push_url fmt = string_attr "data-hx-push-url" fmt
  let select fmt = string_attr "data-hx-select" fmt
  let select_oob fmt = string_attr "data-hx-select-oob" fmt
  let swap fmt = string_attr "data-hx-swap" fmt
  let swap_oob fmt = string_attr "data-hx-swap-oob" fmt
  let target fmt = string_attr "data-hx-target" fmt
  let trigger fmt = string_attr "data-hx-trigger" ~raw:true fmt
  let vals fmt = string_attr "data-hx-vals" fmt
end
