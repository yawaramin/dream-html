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

type attr = string * string

type tag =
  { name : string;
    attrs : attr list;
    children : node list option
  }

and node =
  | Tag of tag
  | Txt of string
  | Comment of string

type 'a to_attr = 'a -> attr
type 'a string_attr = ('a, unit, string, attr) format4 -> 'a
type std_tag = attr list -> node list -> node
type void_tag = attr list -> node
type 'a text_tag = attr list -> ('a, unit, string, node) format4 -> 'a

let write_attr p = function
  | "", _ -> ()
  | name, "" ->
    p " ";
    p name
  | name, value ->
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
    List.iter (write_attr p) attrs;
    p ">"
  | Tag ({ name; children = Some children; _ } as non_void) ->
    if name = "html" then p "<!DOCTYPE html>\n";
    write_tag p (Tag { non_void with children = None });
    List.iter (write_tag p) children;
    p "</";
    p name;
    p ">\n"
  | Txt str -> p str
  | Comment str ->
    p "<!-- ";
    p str;
    p " -->\n"

let to_string node =
  let buf = Buffer.create 256 in
  write_tag (Buffer.add_string buf) node;
  Buffer.contents buf

let pp ppf node = node |> to_string |> Format.pp_print_string ppf

let respond ?status ?code ?headers node =
  Dream.html ?status ?code ?headers (to_string node)

let send ?text_or_binary ?end_of_message websocket node =
  Dream.send ?text_or_binary ?end_of_message websocket (to_string node)

let set_body resp node =
  Dream.set_body resp (to_string node);
  Dream.set_header resp "Content-Type" "text/html"

let write stream node = Dream.write stream (to_string node)

let txt_escape buffer = function
  | '&' -> Buffer.add_string buffer "&amp;"
  | '<' -> Buffer.add_string buffer "&lt;"
  | '>' -> Buffer.add_string buffer "&gt;"
  | c -> Buffer.add_char buffer c

let txt_escape raw s =
  if raw then
    s
  else
    let buffer = Buffer.create (String.length s * 2) in
    String.iter (txt_escape buffer) s;
    Buffer.contents buffer

let attr_escape buffer = function
  | '"' -> Buffer.add_string buffer "&quot;"
  | c -> Buffer.add_char buffer c

let attr_escape raw s =
  if raw then
    s
  else
    let buffer = Buffer.create (String.length s * 2) in
    String.iter (attr_escape buffer) s;
    Buffer.contents buffer

let attr name = name, ""

let string_attr name ?(raw = false) fmt =
  Printf.ksprintf (fun s -> name, attr_escape raw s) fmt

let uri_attr name fmt =
  Printf.ksprintf (fun s -> name, s |> Uri.of_string |> Uri.to_string) fmt

let bool_attr name value = name, string_of_bool value
let float_attr name value = name, Printf.sprintf "%f" value
let int_attr name value = name, string_of_int value
let std_tag name attrs children = Tag { name; attrs; children = Some children }
let void_tag name attrs = Tag { name; attrs; children = None }

let text_tag name ?(raw = false) attrs fmt =
  Printf.ksprintf
    (fun s -> Tag { name; attrs; children = Some [Txt (txt_escape raw s)] })
    fmt

let txt ?(raw = false) fmt =
  Printf.ksprintf (fun s -> Txt (txt_escape raw s)) fmt

let csrf_tag req = req |> Dream.csrf_tag |> txt ~raw:true "%s"
let comment str = Comment (txt_escape false str)

let ( +@ ) node attr =
  match node with
  | Tag t -> Tag { t with attrs = attr :: t.attrs }
  | _ -> invalid_arg "cannot add attribute to non-tag node"

let ( -@ ) node attr =
  match node with
  | Tag t ->
    Tag { t with attrs = List.filter (fun (k, _) -> k <> attr) t.attrs }
  | _ -> invalid_arg "cannot remove attribute from non-tag node"

let ( .@[] ) node attr =
  match node with
  | Tag { attrs; _ } -> List.assoc attr attrs
  | _ -> invalid_arg "cannot get value of attribute from non-tag node"

let is_null = function
  | Tag { name = ""; _ } -> true
  | _ -> false

let is_null_ (name, _) = name = ""

module HTML = struct
  (* Attributes *)

  type method_ =
    [ `GET
    | `POST
    | `dialog ]

  type enctype =
    [ `urlencoded
    | `formdata
    | `text_plain ]

  let enctype_string = function
    | `urlencoded -> "application/x-www-form-urlencoded"
    | `formdata -> "multipart/form-data"
    | `text_plain -> "text/plain"

  let null_ = string_attr "" ""
  let accept fmt = string_attr "accept" fmt
  let accept_charset fmt = string_attr "accept-charset" fmt
  let accesskey fmt = string_attr "accesskey" fmt
  let action fmt = uri_attr "action" fmt
  let align fmt = string_attr "align" fmt
  let allow fmt = string_attr "allow" fmt
  let alt fmt = string_attr "alt" fmt
  let async = attr "async"

  let autocapitalize value =
    ( "autocapitalize",
      match value with
      | `off -> "off"
      | `none -> "none"
      | `on -> "on"
      | `sentences -> "sentences"
      | `words -> "words"
      | `characters -> "characters" )

  let autocomplete value =
    ( "autocomplete",
      match value with
      | `off -> "off"
      | `on -> "on"
      | `name -> "name"
      | `honorific_prefix -> "honorific-prefix"
      | `given_name -> "given-name"
      | `additional_name -> "additional-name"
      | `honorific_suffix -> "honorific-suffix"
      | `nickname -> "nickname"
      | `email -> "email"
      | `username -> "username"
      | `new_password -> "new-password"
      | `current_password -> "current-password"
      | `one_time_code -> "one-time-code"
      | `organization_title -> "organization-title"
      | `organization -> "organization"
      | `street_address -> "street-address"
      | `address_line1 -> "address-line1"
      | `address_line2 -> "address-line2"
      | `address_line3 -> "address-line3"
      | `address_level4 -> "address-level4"
      | `address_level3 -> "address-level3"
      | `address_level2 -> "address-level2"
      | `address_level1 -> "address-level1"
      | `country -> "country"
      | `country_name -> "country-name"
      | `postal_code -> "postal-code"
      | `cc_name -> "cc-name"
      | `cc_given_name -> "cc-given-name"
      | `cc_additional_name -> "cc-additional-name"
      | `cc_family_name -> "cc-family-name"
      | `cc_number -> "cc-number"
      | `cc_exp -> "cc-exp"
      | `cc_exp_month -> "cc-exp-month"
      | `cc_exp_year -> "cc-exp-year"
      | `cc_csc -> "cc-csc"
      | `cc_type -> "cc-type"
      | `transaction_currency -> "transaction-currency"
      | `transaction_amount -> "transaction-amount"
      | `language -> "language"
      | `bday -> "bday"
      | `bday_day -> "bday-day"
      | `bday_month -> "bday-month"
      | `bday_year -> "bday-year"
      | `sex -> "sex"
      | `tel -> "tel"
      | `tel_country_code -> "tel-country-code"
      | `tel_national -> "tel-national"
      | `tel_area_code -> "tel-area-code"
      | `tel_local -> "tel-local"
      | `tel_extension -> "tel-extension"
      | `impp -> "impp"
      | `url -> "url"
      | `photo -> "photo"
      | `webauthn -> "webauthn" )

  let autofocus = attr "autofocus"
  let autoplay = attr "autoplay"
  let buffered fmt = string_attr "buffered" fmt

  let capture value =
    ( "capture",
      match value with
      | `user -> "user"
      | `environment -> "environment" )

  let charset fmt = string_attr "charset" fmt
  let checked = attr "checked"
  let cite_ fmt = uri_attr "cite" fmt
  let class_ fmt = string_attr "class" fmt
  let color fmt = string_attr "color" fmt
  let cols = int_attr "cols"
  let colspan = int_attr "colspan"
  let content fmt = string_attr "content" fmt
  let contenteditable = bool_attr "contenteditable"
  let contextmenu fmt = string_attr "contextmenu" fmt
  let controls = attr "controls"
  let coords fmt = string_attr "coords" fmt

  let crossorigin value =
    ( "crossorigin",
      match value with
      | `anonymous -> "anonymous"
      | `use_credentials -> "use-credentials" )

  let data_ fmt = uri_attr "data" fmt
  let datetime fmt = string_attr "datetime" fmt

  let decoding value =
    ( "decoding",
      match value with
      | `sync -> "sync"
      | `async -> "async"
      | `auto -> "auto" )

  let default = attr "default"
  let defer = attr "defer"

  let dir value =
    ( "dir",
      match value with
      | `ltr -> "ltr"
      | `rtl -> "rtl"
      | `auto -> "auto" )

  let dirname fmt = string_attr "dirname" fmt
  let disabled = attr "disabled"
  let download fmt = string_attr "download" fmt
  let draggable = attr "draggable"
  let enctype value = "enctype", enctype_string value

  let fetchpriority value =
    ( "fetchpriority",
      match value with
      | `high -> "high"
      | `low -> "low"
      | `auto -> "auto" )

  let for_ fmt = string_attr "for" fmt
  let form_ fmt = string_attr "form" fmt
  let formaction fmt = string_attr "formaction" fmt
  let formenctype value = "formenctype", enctype_string value

  let method_to_string = function
    | `GET -> "get"
    | `POST -> "post"
    | `dialog -> "dialog"

  let formmethod value = "formmethod", method_to_string value
  let formnovalidate = attr "formnovalidate"
  let formtarget fmt = string_attr "formtarget" fmt
  let headers fmt = string_attr "headers" fmt
  let height fmt = string_attr "height" fmt

  let hidden value =
    ( "hidden",
      match value with
      | `hidden -> "hidden"
      | `until_found -> "until-found" )

  let high = float_attr "high"
  let href fmt = uri_attr "href" fmt
  let hreflang fmt = string_attr "hreflang" fmt

  let http_equiv value =
    ( "http-equiv",
      match value with
      | `content_security_policy -> "content-security-policy"
      | `content_type -> "content-type"
      | `default_style -> "default-style"
      | `x_ua_compatible -> "x-ua-compatible"
      | `refresh -> "refresh" )

  let id fmt = string_attr "id" fmt
  let integrity fmt = string_attr "integrity" fmt

  let inputmode value =
    ( "inputmode",
      match value with
      | `none -> "none"
      | `text -> "text"
      | `decimal -> "decimal"
      | `numeric -> "numeric"
      | `tel -> "tel"
      | `search -> "search"
      | `email -> "email"
      | `url -> "url" )

  let ismap = attr "ismap"
  let itemprop fmt = string_attr "itemprop" fmt

  let kind value =
    ( "kind",
      match value with
      | `subtitles -> "subtitles"
      | `captions -> "captions"
      | `descriptions -> "descriptions"
      | `chapters -> "chapters"
      | `metadata -> "metadata" )

  let label_ fmt = string_attr "label" fmt
  let lang fmt = string_attr "lang" fmt
  let list fmt = string_attr "list" fmt
  let loading_lazy = string_attr "loading" "lazy"
  let loop = attr "loop"
  let low = float_attr "low"
  let max fmt = string_attr "max" fmt
  let maxlength = int_attr "maxlength"
  let media fmt = string_attr "media" fmt
  let method_ value = "method", method_to_string value
  let min fmt = string_attr "min" fmt
  let minlength = int_attr "minlength"
  let multiple = attr "multiple"
  let muted = attr "muted"
  let name fmt = string_attr "name" fmt
  let novalidate = attr "novalidate"
  let onblur fmt = string_attr "onblur" ~raw:true fmt
  let onclick fmt = string_attr "onclick" ~raw:true fmt
  let open_ = attr "open"
  let optimum = float_attr "optimum"
  let pattern fmt = string_attr "pattern" fmt
  let ping fmt = string_attr "ping" fmt
  let placeholder fmt = string_attr "placeholder" fmt
  let playsinline = attr "playsinline"
  let poster fmt = uri_attr "poster" fmt

  let preload value =
    ( "preload",
      match value with
      | `none -> "none"
      | `metadata -> "metadata"
      | `auto -> "auto" )

  let readonly = attr "readonly"

  let referrerpolicy value =
    ( "referrerpolicy",
      match value with
      | `no_referrer -> "no-referrer"
      | `no_referrer_when_downgrade -> "no-referrer-when-downgrade"
      | `origin -> "origin"
      | `origin_when_cross_origin -> "origin-when-cross-origin"
      | `same_origin -> "same-origin"
      | `strict_origin -> "strict-origin"
      | `strict_origin_when_cross_origin -> "strict-origin-when-cross-origin"
      | `unsafe_url -> "unsafe-url" )

  let rel fmt = string_attr "rel" fmt
  let required = attr "required"
  let reversed = attr "reversed"

  let role value =
    ( "role",
      match value with
      | `alert -> "alert"
      | `alertdialog -> "alertdialog"
      | `application -> "application"
      | `article -> "article"
      | `banner -> "banner"
      | `button -> "button"
      | `cell -> "cell"
      | `checkbox -> "checkbox"
      | `columnheader -> "columnheader"
      | `combobox -> "combobox"
      | `comment -> "comment"
      | `complementary -> "complementary"
      | `contentinfo -> "contentinfo"
      | `definition -> "definition"
      | `dialog -> "dialog"
      | `document -> "document"
      | `feed -> "feed"
      | `figure -> "figure"
      | `form -> "form"
      | `generic -> "generic"
      | `grid -> "grid"
      | `gridcell -> "gridcell"
      | `group -> "group"
      | `heading -> "heading"
      | `img -> "img"
      | `link -> "link"
      | `list -> "list"
      | `listbox -> "listbox"
      | `listitem -> "listitem"
      | `log -> "log"
      | `main -> "main"
      | `mark -> "mark"
      | `marquee -> "marquee"
      | `math -> "math"
      | `menu -> "menu"
      | `menubar -> "menubar"
      | `menuitem -> "menuitem"
      | `menuitemcheckbox -> "menuitemcheckbox"
      | `menuitemradio -> "menuitemradio"
      | `meter -> "meter"
      | `navigation -> "navigation"
      | `none -> "none"
      | `note -> "note"
      | `option -> "option"
      | `presentation -> "presentation"
      | `progressbar -> "progressbar"
      | `radio -> "radio"
      | `radiogroup -> "radiogroup"
      | `region -> "region"
      | `row -> "row"
      | `rowgroup -> "rowgroup"
      | `rowheader -> "rowheader"
      | `scrollbar -> "scrollbar"
      | `search -> "search"
      | `searchbox -> "searchbox"
      | `separator -> "separator"
      | `slider -> "slider"
      | `spinbutton -> "spinbutton"
      | `status -> "status"
      | `suggestion -> "suggestion"
      | `switch -> "switch"
      | `tab -> "tab"
      | `table -> "table"
      | `tablist -> "tablist"
      | `tabpanel -> "tabpanel"
      | `term -> "term"
      | `textbox -> "textbox"
      | `timer -> "timer"
      | `toolbar -> "toolbar"
      | `tooltip -> "tooltip"
      | `tree -> "tree"
      | `treegrid -> "treegrid"
      | `treeitem -> "treeitem" )

  let rows = int_attr "rows"
  let rowspan = int_attr "rowspan"
  let sandbox fmt = string_attr "sandbox" fmt
  let scope fmt = string_attr "scope" fmt
  let selected = attr "selected"
  let shape fmt = string_attr "shape" fmt
  let size fmt = string_attr "size" fmt
  let sizes fmt = string_attr "sizes" fmt
  let slot_ fmt = string_attr "slot" fmt
  let span_ = int_attr "span"
  let spellcheck = bool_attr "spellcheck"
  let src fmt = uri_attr "src" fmt
  let srcdoc fmt = string_attr "srcdoc" fmt
  let srclang fmt = string_attr "srclang" fmt
  let srcset fmt = string_attr "srcset" fmt
  let start = int_attr "start"
  let step fmt = string_attr "step" fmt
  let style_ fmt = string_attr ~raw:true "style" fmt
  let tabindex = int_attr "tabindex"
  let target fmt = string_attr "target" fmt
  let title_ fmt = string_attr "title" fmt

  let translate value =
    ( "translate",
      match value with
      | `yes -> "yes"
      | `no -> "no" )

  let type_ fmt = string_attr "type" fmt
  let usemap fmt = string_attr "usemap" fmt
  let value fmt = string_attr "value" fmt
  let width fmt = string_attr "width" fmt

  let wrap value =
    ( "wrap",
      match value with
      | `hard -> "hard"
      | `soft -> "soft" )

  (* Tags *)

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

module SVG = struct
  (* Attributes *)
  let d fmt = string_attr "d" fmt
  let fill fmt = string_attr "fill" fmt
  let stroke fmt = string_attr "stroke" fmt

  let stroke_linecap value =
    ( "stroke-linecap",
      match value with
      | `butt -> "butt"
      | `round -> "round"
      | `square -> "square" )

  let stroke_linejoin value =
    ( "stroke-linejoin",
      match value with
      | `arcs -> "arcs"
      | `bevel -> "bevel"
      | `miter -> "miter"
      | `miter_clip -> "miter-clip"
      | `round -> "round" )

  let stroke_width fmt = string_attr "stroke-width" fmt

  let viewbox ~min_x ~min_y ~width ~height =
    "viewbox", Printf.sprintf "%d %d %d %d" min_x min_y width height

  let xmlns = string_attr "xmlns" "http://www.w3.org/2000/svg"

  (* Tags *)
  let path = std_tag "path"
  let svg = std_tag "svg"
end

module Aria = struct
  let activedescendant fmt = string_attr "aria-activedescendant" fmt
  let atomic = attr "aria-atomic"

  let autocomplete value =
    ( "aria-autocomplete",
      match value with
      | `inline -> "inline"
      | `list -> "list"
      | `both -> "both" )

  let braillelabel fmt = string_attr "aria-braillelabel" fmt
  let brailleroledescription fmt = string_attr "aria-brailleroledescription" fmt
  let busy = attr "aria-busy"

  let checked value =
    ( "aria-checked",
      match value with
      | `false_ -> "false"
      | `true_ -> "true"
      | `mixed -> "mixed" )

  let colcount = int_attr "aria-colcount"
  let colindextext fmt = string_attr "aria-colindextext" fmt
  let colspan = int_attr "aria-colspan"
  let controls fmt = string_attr "aria-controls" fmt

  let current value =
    ( "aria-current",
      match value with
      | `page -> "page"
      | `step -> "step"
      | `location -> "location"
      | `date -> "date"
      | `time -> "time"
      | `true_ -> "true" )

  let describedby fmt = string_attr "aria-describedby" fmt
  let description fmt = string_attr "aria-description" fmt
  let details fmt = string_attr "aria-details" fmt
  let disabled = attr "aria-disabled"
  let errormessage fmt = string_attr "aria-errormessage" fmt
  let expanded = bool_attr "aria-expanded"
  let flowto fmt = string_attr "aria-flowto" fmt

  let haspopup value =
    ( "aria-haspopup",
      match value with
      | `true_ -> "true"
      | `menu -> "menu"
      | `listbox -> "listbox"
      | `tree -> "tree"
      | `grid -> "grid"
      | `dialog -> "dialog" )

  let hidden = bool_attr "aria-hidden"

  let invalid value =
    ( "aria-invalid",
      match value with
      | `grammar -> "grammar"
      | `spelling -> "spelling"
      | `true_ -> "true" )

  let keyshortcuts fmt = string_attr "aria-keyshortcuts" fmt
  let label fmt = string_attr "aria-label" fmt
  let labelledby fmt = string_attr "aria-labelledby" fmt
  let level = int_attr "aria-level"

  let live value =
    ( "aria-live",
      match value with
      | `assertive -> "assertive"
      | `polite -> "polite" )

  let modal = attr "aria-modal"
  let multiline = attr "aria-multiline"
  let multiselectable = attr "aria-multiselectable"

  let orientation value =
    ( "aria-orientation",
      match value with
      | `horizontal -> "horizontal"
      | `vertical -> "vertical" )

  let owns fmt = string_attr "aria-owns" fmt
  let placeholder fmt = string_attr "aria-placeholder" fmt
  let posinset = int_attr "aria-posinset"

  let pressed value =
    ( "aria-pressed",
      match value with
      | `false_ -> "false"
      | `mixed -> "mixed"
      | `true_ -> "true" )

  let readonly = attr "aria-readonly"

  let relevant value =
    ( "aria-relevant",
      match value with
      | `additions -> "additions"
      | `all -> "all"
      | `removals -> "removals"
      | `text -> "text" )

  let required = attr "aria-required"
  let roledescription fmt = string_attr "aria-roledescription" fmt
  let rowcount = int_attr "aria-rowcount"
  let rowindex = int_attr "aria-rowindex"
  let rowindextext fmt = string_attr "aria-rowindextext" fmt
  let rowspan = int_attr "aria-rowspan"
  let selected = bool_attr "aria-selected"
  let setsize = int_attr "aria-setsize"

  let sort value =
    ( "aria-sort",
      match value with
      | `ascending -> "ascending"
      | `descending -> "descending"
      | `other -> "other" )

  let valuemax = float_attr "aria-valuemax"
  let valuemin = float_attr "aria-valuemin"
  let valuenow = float_attr "aria-valuenow"
  let valuetext fmt = string_attr "aria-valuetext" fmt
end

module Hx = struct
  let __ fmt = string_attr ~raw:true "_" fmt

  (* This is a boolean because it can be selectively switched off in some parts
     of the page. *)
  let boost = bool_attr "data-hx-boost"
  let confirm fmt = string_attr "data-hx-confirm" fmt
  let delete fmt = uri_attr "data-hx-delete" fmt
  let disable = attr "data-hx-disable"
  let disinherit fmt = string_attr "data-hx-disinherit" fmt
  let encoding_formdata = "data-hx-encoding", "multipart/form-data"
  let ext fmt = string_attr "data-hx-ext" fmt
  let get fmt = uri_attr "data-hx-get" fmt
  let headers fmt = string_attr "data-hx-headers" fmt
  let history_false = bool_attr "data-hx-history" false
  let history_elt = attr "data-hx-history-elt"
  let include_ fmt = string_attr "data-hx-include" fmt
  let indicator fmt = string_attr ~raw:true "data-hx-indicator" fmt
  let on fmt = string_attr "data-hx-on" ~raw:true fmt
  let on_ ~event fmt = string_attr ("data-hx-on:" ^ event) ~raw:true fmt
  let params fmt = string_attr "data-hx-params" fmt
  let patch fmt = uri_attr "data-hx-patch" fmt
  let post fmt = uri_attr "data-hx-post" fmt
  let preload = attr "preload"
  let preserve = attr "data-hx-preserve"
  let prompt fmt = string_attr "data-hx-prompt" fmt
  let push_url fmt = uri_attr "data-hx-push-url" fmt
  let put fmt = uri_attr "data-hx-put" fmt
  let replace_url fmt = string_attr "data-hx-replace-url" fmt
  let request fmt = string_attr "data-hx-request" fmt
  let select fmt = string_attr ~raw:true "data-hx-select" fmt
  let select_oob fmt = string_attr ~raw:true "data-hx-select-oob" fmt
  let sse_connect fmt = string_attr "data-sse-connect" fmt
  let sse_swap fmt = string_attr "data-sse-swap" fmt
  let swap fmt = string_attr ~raw:true "data-hx-swap" fmt
  let swap_oob fmt = string_attr ~raw:true "data-hx-swap-oob" fmt
  let sync fmt = string_attr "data-hx-sync" fmt
  let target fmt = string_attr ~raw:true "data-hx-target" fmt
  let trigger fmt = string_attr "data-hx-trigger" ~raw:true fmt
  let validate = attr "data-hx-validate"
  let vals fmt = string_attr "data-hx-vals" fmt
  let ws_connect fmt = string_attr "data-ws-connect" fmt
  let ws_send = attr "data-ws-send"
end

module MathML = struct
  (* Attributes *)
  let accent = bool_attr "accent"
  let accentunder = bool_attr "accentunder"
  let columnspan = int_attr "columnspan"
  let depth fmt = string_attr "depth" fmt

  let dir value =
    ( "dir",
      match value with
      | `rtl -> "rtl"
      | `ltr -> "ltr" )

  let display_block = string_attr "display" "block"
  let displaystyle = bool_attr "displaystyle"
  let fence = bool_attr "fence"
  let height fmt = string_attr "height" fmt
  let largeop = bool_attr "largeop"
  let linethickness fmt = string_attr "linethickness" fmt
  let lspace fmt = string_attr "lspace" fmt
  let mathvariant fmt = string_attr "mathvariant" fmt
  let maxsize fmt = string_attr "maxsize" fmt
  let minsize fmt = string_attr "minsize" fmt
  let movablelimits = bool_attr "movablelimits"
  let rowspan = int_attr "rowspan"
  let rspace fmt = string_attr "rspace" fmt
  let scriptlevel fmt = string_attr "scriptlevel" fmt
  let separator = bool_attr "separator"
  let stretchy = bool_attr "stretchy"
  let symmetric = bool_attr "symmetric"
  let voffset fmt = string_attr "voffset" fmt
  let xmlns = string_attr "xmlns" "http://www.w3.1998/Math/MathML"

  (* Tags *)
  let annotation = std_tag "annotation"
  let annotation_xml = std_tag "annotation-xml"
  let math = std_tag "math"
  let merror = std_tag "merror"
  let mfrac = std_tag "mfrac"
  let mi = std_tag "mi"
  let mmultiscripts = std_tag "mmultiscripts"
  let mn = std_tag "mn"
  let mo = std_tag "mo"
  let mover = std_tag "mover"
  let mpadded = std_tag "mpadded"
  let mphantom = std_tag "mphantom"
  let mroot = std_tag "mroot"
  let mrow = std_tag "mrow"
  let ms = std_tag "ms"
  let mspace = std_tag "mspace"
  let msqrt = std_tag "msqrt"
  let mstyle = std_tag "mstyle"
  let msub = std_tag "msub"
  let msubsup = std_tag "msubsup"
  let msup = std_tag "msup"
  let mtable = std_tag "mtable"
  let mtd = std_tag "mtd"
  let mtext = std_tag "mtext"
  let mtr = std_tag "mtr"
  let munder = std_tag "munder"
  let munderover = std_tag "munderover"
  let semantics = std_tag "semantics"
end
