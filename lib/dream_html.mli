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

(** Constructing HTML. Detailed explanation in
    {: https://github.com/yawaramin/dream-html}.

    Let's adapt the example from the
    {{: https://aantron.github.io/dream/} Dream home page}:


    {[let hello who =
        let open Dream_html in
        let open HTML in
        html [] [body [] [h1 [] [txt "Hello, %s!" who]]]

      let () =
        Dream.run
        @@ Dream.logger
        @@ Dream.router [Dream.get "/" (fun _ -> Dream_html.respond (hello "world"))]]}

    More examples shown below. *)

(** {2 Core types}

    These are the types of the final values which get rendered. *)

type attr
(** E.g. [id="toast"]. *)

type node
(** Either a tag, a comment, or text data in the markup. *)

(** {2 Output} *)

val to_string : node -> string
val pp : Format.formatter -> node -> unit

val respond :
  ?status:[< Dream.status] ->
  ?code:int ->
  ?headers:(string * string) list ->
  node ->
  Dream.response Dream.promise

val set_body : Dream.response -> node -> unit
(** Type-safe wrapper for [Dream.set_body]. Sets the body to the given [node] and
    sets the [Content-Type] header to [text/html]. *)

val write : Dream.stream -> node -> unit Dream.promise
(** Type-safe wrapper for [Dream.write]. *)

(** {2 Constructing nodes and attributes} *)

type 'a to_attr = 'a -> attr
(** Attributes can be created from typed values. *)

type 'a string_attr = ('a, unit, string, attr) format4 -> 'a
(** Special handling for string-value attributes so they can use format strings
    i.e. string interpolation. *)

type std_tag = attr list -> node list -> node
(** A 'standard' tag with attributes and children. *)

type void_tag = attr list -> node
(** A 'void element':
    {: https://developer.mozilla.org/en-US/docs/Glossary/Void_element} with no
    children. *)

type 'a text_tag = attr list -> ('a, unit, string, node) format4 -> 'a
(** Tags which can have attributes but can contain only text. The text can be
    formatted. *)

val attr : string -> attr
(** [attr name] is a new attribute which does not carry any payload. E.g.

    {[let required = attr "required"]}

    @since 0.1.0. *)

val string_attr : string -> ?raw:bool -> _ string_attr
(** [string_attr name fmt] is a new string-valued attribute which allows
    formatting i.e. string interpolation of the value. Note, the [fmt] argument
    is required due to the value restriction.

    @param raw (default [false]) whether to inject the raw text or to escape it.
      Note that Dream does not support escaping inline JavaScript nor CSS, so
      neither does dream-html:
      {: https://github.com/aantron/dream/tree/master/example/7-template#security}. *)

val uri_attr : string -> _ string_attr
(** Convenience for attributes whose values should be URIs. Takes care of URI-
    encoding.

    {[a [href "/blog?tags=iamsafe\"></a><script>alert('Pwned')</script>"] [txt "Tags: tag1 | tag2"]]}

    Output:

    {[<a href="/blog?tags=iamsafe%22%3E%3C/a%3E%3Cscript%3Ealert('Pwned')%3C/script%3E">Tags: tag1 | tag2</a>]} *)

val bool_attr : string -> bool to_attr
val float_attr : string -> float to_attr
val int_attr : string -> int to_attr
val std_tag : string -> std_tag
val void_tag : string -> void_tag

val text_tag : string -> ?raw:bool -> _ text_tag
(** Build a tag which can contain only text.

    @param raw (default [false]) whether to inject the raw text or to escape it.
      Note that Dream does not support escaping inline JavaScript nor CSS, so
      neither does dream-html:
      {: https://github.com/aantron/dream/tree/master/example/7-template#security}. *)

val txt : ?raw:bool -> ('a, unit, string, node) format4 -> 'a
(** A text node inside the DOM e.g. the 'hi' in [<b>hi</b>]. Allows string
    interpolation using the same formatting features as [Printf.sprintf]:

    {[b [] [txt "Hello, %s!" name]]}

    Or without interpolation:

    {[b [] [txt "Bold of you."]]}

    HTML-escapes the text value using [Dream.html_escape]. You can use the [~raw]
    param to bypass escaping:

    {[let user_input = "<script>alert('I like HTML injection')</script>" in
      txt ~raw:true "%s" user_input]} *)

val comment : string -> node
(** A comment that will be embedded in the rendered HTML, i.e. [<!-- comment -->].
    The text is HTML-escaped. *)

val csrf_tag : Dream.request -> node
(** Convenience to add a CSRF token generated by Dream into your form. Type-safe
    wrapper for [Dream.csrf_tag].

    {[form
        [action "/foo"]
        [csrf_tag req; input [name "bar"]; input [type_ "submit"]]]} *)

(** {2 Accessors for tags} *)

val ( +@ ) : node -> attr -> node
(** Add an attribute to a tag.

    @raise Invalid_argument if the node is not a tag (i.e. if it is a text or
      comment node).
    @since 0.0.3. *)

val ( -@ ) : node -> string -> node
(** Remove an attribute from a tag.

    @raise Invalid_argument if the node is not a tag (i.e. if it is a text or
      comment node).
    @since 0.0.3. *)

val ( .@[] ) : node -> string -> string
(** Get the value of an existing attribute.

    {[let toast = p [id "toast"] [txt "OK."]
      let toast_id = toast.@["id"]]}

    @raise Invalid_argument if the node is not a tag (i.e. if it is a text or
      comment node).
    @raise Not_found if the tag does not have the given attribute.
    @since 0.0.3. *)

(** {2 Standard attributes and tags} *)

(** All standard HTML attributes and tags. Some attributes and tags have the same
    name, e.g. [style]. To disambiguate them, attributes have a [_] (underscore)
    suffix. *)
module HTML : sig
  (** {3 Attributes}

    Standard, most non-deprecated attributes from
    {: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes}. Where an
    attribute name conflicts with an OCaml keyword, the name is suffixed with [_].
    Most attributes are constructed by passing in a value of some type.

    All string-valued attributes allow formatting (interpolation):

    {[div [id "section-%d" section_id] []]}

    Or plain strings:

    {[p [id "toast"] []]}

    Most boolean attributes are plain values and don't need to be constructed
    with function calls:

    {[input [required]]}

    However, boolean attributes which may be inherited and toggled on/off in
    children, are constructed by passing in a value:

    {[div
        [contenteditable true]
        [p [] [txt "Edit me!"]; p [contenteditable false] [txt "Can't edit me!"]]]}

    Enumerated attributes accept specific values:

    {[input [inputmode `tel]]}

    @since 1.0.0. *)

  type enctype =
    [ `urlencoded
    | `formdata
    | `text_plain ]

  type method_ =
    [ `GET
    | `POST ]

  val null_ : attr
  (** An attribute that will not be rendered in the markup. Useful for conditional
      logic where you sometimes want to render an attribute and sometimes not.

      {[p[if should_show then null_ else style_ "display:none"][
          txt "Show and tell"]]} *)

  val accept : _ string_attr
  val accept_charset : _ string_attr
  val accesskey : _ string_attr
  val action : _ string_attr
  val align : _ string_attr
  val allow : _ string_attr
  val alt : _ string_attr
  val async : attr

  val autocapitalize :
    [< `off | `none | `on | `sentences | `words | `characters] to_attr

  val autocomplete :
    [< `off
    | `on
    | `name
    | `honorific_prefix
    | `given_name
    | `additional_name
    | `honorific_suffix
    | `nickname
    | `email
    | `username
    | `new_password
    | `current_password
    | `one_time_code
    | `organization_title
    | `organization
    | `street_address
    | `address_line1
    | `address_line2
    | `address_line3
    | `address_level4
    | `address_level3
    | `address_level2
    | `address_level1
    | `country
    | `country_name
    | `postal_code
    | `cc_name
    | `cc_given_name
    | `cc_additional_name
    | `cc_family_name
    | `cc_number
    | `cc_exp
    | `cc_exp_month
    | `cc_exp_year
    | `cc_csc
    | `cc_type
    | `transaction_currency
    | `transaction_amount
    | `language
    | `bday
    | `bday_day
    | `bday_month
    | `bday_year
    | `sex
    | `tel
    | `tel_country_code
    | `tel_national
    | `tel_area_code
    | `tel_local
    | `tel_extension
    | `impp
    | `url
    | `photo ]
    to_attr

  val autofocus : attr
  val autoplay : attr
  val buffered : _ string_attr
  val capture : _ string_attr
  val charset : _ string_attr
  val checked : attr
  val cite_ : _ string_attr
  val class_ : _ string_attr
  val color : _ string_attr
  val cols : int to_attr
  val colspan : int to_attr
  val content : _ string_attr
  val contenteditable : bool to_attr
  val contextmenu : _ string_attr
  val controls : attr
  val coords : _ string_attr
  val crossorigin : [< `anonymous | `use_credentials] to_attr
  val data_ : _ string_attr
  val datetime : _ string_attr
  val decoding : [< `sync | `async | `auto] to_attr
  val default : attr
  val defer : attr
  val dir : [< `ltr | `rtl | `auto] to_attr
  val dirname : _ string_attr
  val disabled : attr
  val download : _ string_attr
  val draggable : attr
  val enctype : [< enctype] to_attr
  val for_ : _ string_attr
  val form_ : _ string_attr
  val formaction : _ string_attr
  val formenctype : [< enctype] to_attr
  val formmethod : [< method_] to_attr
  val formnovalidate : attr
  val formtarget : _ string_attr
  val headers : _ string_attr
  val height : _ string_attr
  val hidden : [< `hidden | `until_found] to_attr
  val high : float to_attr
  val href : _ string_attr
  val hreflang : _ string_attr

  val http_equiv :
    [< `content_security_policy
    | `content_type
    | `default_style
    | `x_ua_compatible
    | `refresh ]
    to_attr

  val id : _ string_attr
  val integrity : _ string_attr

  val inputmode :
    [< `none | `text | `decimal | `numeric | `tel | `search | `email | `url]
    to_attr

  val ismap : attr
  val itemprop : _ string_attr

  val kind :
    [< `subtitles | `captions | `descriptions | `chapters | `metadata] to_attr

  val label_ : _ string_attr
  val lang : _ string_attr
  val list : _ string_attr
  val loop : attr
  val low : float to_attr
  val max : _ string_attr
  val maxlength : int to_attr
  val media : _ string_attr
  val method_ : [< method_] to_attr
  val min : _ string_attr
  val minlength : int to_attr
  val multiple : attr
  val muted : attr
  val name : _ string_attr
  val novalidate : attr

  val onblur : _ string_attr
  (** Note that the value of this attribute is not escaped. *)

  val onclick : _ string_attr
  (** Note that the value of this attribute is not escaped. *)

  val open_ : attr
  val optimum : float to_attr
  val pattern : _ string_attr
  val ping : _ string_attr
  val placeholder : _ string_attr
  val playsinline : attr
  val poster : _ string_attr
  val preload : [< `none | `metadata | `auto] to_attr
  val readonly : attr

  val referrerpolicy :
    [< `no_referrer
    | `no_referrer_when_downgrade
    | `origin
    | `origin_when_cross_origin
    | `same_origin
    | `strict_origin
    | `strict_origin_when_cross_origin
    | `unsafe_url ]
    to_attr

  val rel : _ string_attr
  val required : attr
  val reversed : attr
  val role : _ string_attr
  val rows : int to_attr
  val rowspan : int to_attr
  val sandbox : _ string_attr
  val scope : _ string_attr
  val selected : attr
  val shape : _ string_attr
  val size : _ string_attr
  val sizes : _ string_attr
  val slot_ : _ string_attr
  val span_ : int to_attr
  val spellcheck : bool to_attr
  val src : _ string_attr
  val srcdoc : _ string_attr
  val srclang : _ string_attr
  val srcset : _ string_attr
  val start : int to_attr
  val step : _ string_attr

  val style_ : _ string_attr
  (** Note that the value of this attribute is not escaped. *)

  val tabindex : int to_attr
  val target : _ string_attr
  val title_ : _ string_attr
  val translate : [< `yes | `no] to_attr

  val type_ : _ string_attr
  (** Note: this can't be restricted to just the allowed values for [<input type>],
      because it's used on other elements e.g. [<link type>]. *)

  val usemap : _ string_attr
  val value : _ string_attr
  val width : _ string_attr
  val wrap : [< `hard | `soft] to_attr

  (** {3 Tags}

      HTML tags. Most (standard tags) are constructed by passing a list of
      attributes and a list of children:

      {[div [id "my-div"] [p [] [txt "Hello"]]]}

      Some (void elements) are constructed only with a list of attributes:

      {[input [required; type_ "email"; name "email-addr"]]}

      Finally, a few (text elements) are constructed with a list of attributes
      and a single text child:

      {[title [] "Document title"

        script [] {|alert('Careful, this is not escaped :-)');|}
      ]} *)

  val null : node list -> node
  (** A tag that will not be rendered in the markup. Useful for containing a bunch
      of child nodes inside a single node without having to litter the DOM with an
      actual node. Also may be called 'splicing'.

      {[null
          [ p [] [txt "This paragraph."];
            p [] [txt "And this paragraph."];
            p []
              [txt "Are spliced directly into the document without a containing node."]
          ]]} *)

  val a : std_tag
  val address : std_tag
  val area : void_tag
  val abbr : std_tag
  val article : std_tag
  val aside : std_tag
  val audio : std_tag
  val b : std_tag
  val base : void_tag
  val bdi : std_tag
  val bdo : std_tag
  val blockquote : std_tag
  val body : std_tag
  val br : void_tag
  val button : std_tag
  val canvas : std_tag
  val caption : std_tag
  val cite : std_tag
  val code : std_tag
  val col : void_tag
  val colgroup : std_tag
  val data : std_tag
  val datalist : std_tag
  val dd : std_tag
  val del : std_tag
  val details : std_tag
  val dfn : std_tag
  val dialog : std_tag
  val div : std_tag
  val dl : std_tag
  val dt : std_tag
  val em : std_tag
  val embed : void_tag
  val fieldset : std_tag
  val figcaption : std_tag
  val figure : std_tag
  val form : std_tag
  val footer : std_tag
  val h1 : std_tag
  val h2 : std_tag
  val h3 : std_tag
  val h4 : std_tag
  val h5 : std_tag
  val h6 : std_tag
  val head : std_tag
  val header : std_tag
  val hgroup : std_tag
  val hr : void_tag

  val html : std_tag
  (** A <!DOCTYPE html> declaration is automatically prefixed when this tag is
      printed. *)

  val i : std_tag
  val iframe : std_tag
  val img : void_tag
  val input : void_tag
  val ins : std_tag
  val kbd : std_tag
  val label : std_tag
  val legend : std_tag
  val li : std_tag
  val link : void_tag
  val main : std_tag
  val map : std_tag
  val mark : std_tag
  val menu : std_tag
  val meta : void_tag
  val meter : std_tag
  val nav : std_tag
  val noscript : std_tag
  val object_ : std_tag
  val ol : std_tag
  val optgroup : std_tag
  val option : _ text_tag
  val output : std_tag
  val p : std_tag
  val picture : std_tag
  val pre : std_tag
  val progress : std_tag
  val q : std_tag
  val rp : std_tag
  val rt : std_tag
  val ruby : std_tag
  val s : std_tag
  val samp : std_tag

  val script : _ text_tag
  (** Note that the content of this tag is not escaped. *)

  val section : std_tag
  val select : std_tag
  val slot : std_tag
  val small : std_tag
  val source : void_tag
  val span : std_tag
  val strong : std_tag

  val style : _ text_tag
  (** Note that the content of this tag is not escaped. *)

  val sub : std_tag
  val summary : std_tag
  val sup : std_tag
  val table : std_tag
  val tbody : std_tag
  val td : std_tag
  val template : std_tag
  val textarea : _ text_tag
  val tfoot : std_tag
  val th : std_tag
  val thead : std_tag
  val time : std_tag
  val title : _ text_tag
  val tr : std_tag
  val track : void_tag
  val u : std_tag
  val ul : std_tag
  val var : std_tag
  val video : std_tag
  val wbr : void_tag
end

(** @since 1.1.0. *)
module SVG : sig
  val d : _ string_attr
  val fill : _ string_attr
  val stroke : _ string_attr
  val stroke_linecap : [< `butt | `round | `square] to_attr

  val stroke_linejoin :
    [< `arcs | `bevel | `miter | `miter_clip | `round] to_attr

  val stroke_width : _ string_attr
  val viewbox : min_x:int -> min_y:int -> width:int -> height:int -> attr
  val xmlns : attr
  val path : std_tag
  val svg : std_tag
end

(** {2 htmx attributes} *)

(** htmx attributes {: https://htmx.org/reference/#attributes} *)
module Hx : sig
  val __ : _ string_attr
  (** This attribute serves as the _ attribute, which is used by Hyperscript.
      Note that the value of this attribute is not escaped.

      @since 0.1.0. *)

  val boost : bool to_attr
  val confirm : _ string_attr
  val delete : _ string_attr
  val disable : attr
  val disinherit : _ string_attr

  val encoding_formdata : attr
  (** Hardcoding of the [hx-encoding] attribute to [multipart/form-data]. *)

  val ext : _ string_attr
  val get : _ string_attr
  val headers : _ string_attr

  val history_false : attr
  (** Hardcoding of the [hx-history] attribute to [false]. *)

  val history_elt : attr
  val include_ : _ string_attr

  val indicator : _ string_attr
  (** Note that the value of this attribute is not escaped as it may include a
      CSS selector. *)

  val on : _ string_attr
  (** Note that the value of this attribute is not escaped. *)

  val params : _ string_attr
  val patch : _ string_attr
  val post : _ string_attr

  val preload : attr
  (** The preload extension: {: https://htmx.org/extensions/preload/} *)

  val preserve : attr
  val prompt : _ string_attr
  val push_url : _ string_attr
  val put : _ string_attr
  val replace_url : _ string_attr
  val request : _ string_attr

  val select : _ string_attr
  (** Note that the value of this attribute is not escaped as it may include a
      CSS selector. *)

  val select_oob : _ string_attr
  (** Note that the value of this attribute is not escaped as it may include a
      CSS selector. *)

  val sse_connect : _ string_attr
  val sse_swap : _ string_attr

  val swap : _ string_attr
  (** Note that the value of this attribute is not escaped as it may include a
      CSS selector. *)

  val swap_oob : _ string_attr
  (** Note that the value of this attribute is not escaped as it may include a
      CSS selector. *)

  val sync : _ string_attr

  val target : _ string_attr
  (** Note that the value of this attribute is not escaped as it may include a
      CSS selector. *)

  val trigger : _ string_attr
  (** Note that the value of this attribute is not escaped. *)

  val validate : attr
  val vals : _ string_attr
  val ws_connect : _ string_attr
  val ws_send : attr
end

(** {2 Interop example–Markdown to HTML}

    In this section we show an extended example of interoperability of dream-html
    with other formats, e.g. the Markdown format defined by the [omd] library:

    {[open Dream_html
      open HTML

      let omd_attr (k, opt_v) =
        string_attr k "%s" @@ Option.fold ~none:"" ~some:Fun.id opt_v

      let rec omd_node elements = elements |> List.map element_node |> null
      and item omd = li [] [omd_node omd]

      and element_node = function
        | Omd.H1 omd -> h1 [] [omd_node omd]
        | H2 omd -> h2 [] [omd_node omd]
        | H3 omd -> h3 [] [omd_node omd]
        | H4 omd -> h4 [] [omd_node omd]
        | H5 omd -> h5 [] [omd_node omd]
        | H6 omd -> h6 [] [omd_node omd]
        | Paragraph omd -> p [] [omd_node omd]
        | Text str -> txt "%s" str
        | Emph omd -> em [] [omd_node omd]
        | Bold omd -> b [] [omd_node omd]
        | Ul omds | Ulp omds -> ul [] @@ List.map item omds
        | Ol omds | Olp omds -> ol [] @@ List.map item omds
        | Code (cls, str) -> code [class_ "%s" cls] [txt "%s" str]
        | Code_block (cls, str) ->
          pre [class_ "%s" cls] [code [class_ "%s" cls] [txt "%s" str]]
        | Br -> br []
        | Hr -> hr []
        | NL -> txt "\n"
        | Url (hre, omd, titl) ->
          a
            [ href "%s" hre;
              target "_blank";
              class_ "after:content-['_↗️']";
              title "%s" titl ]
            [omd_node omd]
        | Html ("details", attrs, omd) ->
          details (List.map omd_attr attrs) [omd_node omd]
        | Html ("summary", attrs, omd) ->
          summary (List.map omd_attr attrs) [omd_node omd]
        | Html_block ("details", attrs, omd) ->
          details (List.map omd_attr attrs) [omd_node omd]
        | Html_block ("summary", attrs, omd) ->
          summary (List.map omd_attr attrs) [omd_node omd]
        | Ref (_, _, _, _)
        | Img_ref (_, _, _, _)
        | Html (_, _, _)
        | Html_block (_, _, _)
        | X _ -> null []
        | Html_comment str -> comment str
        | Raw str -> txt ~raw:true "%s" str
        | Raw_block str -> pre [] [txt ~raw:true "%s" str]
        | Blockquote omd -> blockquote [] [omd_node omd]
        | Img (al, sr, titl) -> img [alt "%s" al; src "%s" sr; title "%s" titl]]}

    The entrypoint of the functionality is the [omd_node] function, which
    converts from the [Omd.t] value which can be obtained by, for example,
    parsing Markdown with the [Omd.of_string] function, to a type-safe [node]
    value.

    In the [element_node] function we traverse the Markdown structure
    and convert it into specific nodes–tags, comments, etc.. Text is escaped as
    appropriate and some specific conversions are handled specially:

    - All hyperlinks are made to open new tabs and suffixed using a Tailwind CSS
      style class.
    - We support the [<details>] and [<summary>] HTML tags, but no others.

    This is just an example, but it shows the idea that we can take various
    formats and interop with them using type-sdfe HTML generated by dream-html. *)
