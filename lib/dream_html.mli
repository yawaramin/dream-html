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

(** Constructing HTML. *)

(** {2 Core types} *)

type attr
(** E.g. [id="toast"]. *)

type node
(** Either a tag, a comment, or text data in the markup. *)

(** {2 Constructor types} *)

type 'a to_attr = 'a -> attr

type 'a string_attr = ('a, unit, string, attr) format4 -> 'a
(** Special handling for string-value attributes so they can use string
    interpolation. *)

type std_tag = attr list -> node list -> node
(** A 'standard' tag with attributes and children. *)

type void_tag = attr list -> node
(** A 'void element':
    {: https://developer.mozilla.org/en-US/docs/Glossary/Void_element} *)

(** {2 Output} *)

val to_string : node -> string
val pp : Format.formatter -> node -> unit

val respond :
  ?status:[< Dream.status] ->
  ?code:int ->
  ?headers:(string * string) list -> node -> Dream.response Lwt.t

(** {2 Creating nodes, attributes, and interpolations} *)

val string_attr : string -> ('a, unit, string, attr) format4 -> 'a
(** [string_attr name fmt] is a new string-valued attribute which allows
    formatting of the value, and then HTML-escapes it using [Dream.html_escape].
    Note, the [fmt] argument is required due to the value restriction. *)

val bool_attr : string -> bool to_attr
val float_attr : string -> float to_attr
val int_attr : string -> int to_attr

val tag : string -> std_tag
val void_tag : string -> void_tag

val txt : ('a, unit, string, node) format4 -> 'a
(** A text node inside the DOM e.g. the 'hi' in [<b>hi</b>]. Allows string
    interpolation using the same formatting features as [Printf.sprintf]. HTML-
    escapes the text value using [Dream.html_escape]. *)

val comment : string -> node
(** A comment that will be embedded in the rendered HTML, i.e. [<!-- comment -->]. *)

val raw : string -> node
[@@alert unsafe "Can lead to HTML injection."]
(** Useful for injecting unsanitized content into the markup. The text value is
    not HTML-escaped. Needless to say, be very careful with where you use this! *)

module Attr : sig
  val null : attr
  (** An attribute that will not be rendered in the markup. Useful for conditional
      logic where you sometimes want to render an attribute and sometimes not. *)

  val accept : _ string_attr
  val action : _ string_attr
  val alt : _ string_attr
  val autocomplete : _ string_attr
  val autofocus : attr
  val capture : _ string_attr
  val charset : _ string_attr
  val checked : attr
  val class_ : _ string_attr
  val color : _ string_attr
  val content : _ string_attr
  val dirname : _ string_attr
  val disabled : attr
  val for_ : _ string_attr
  val height : _ string_attr
  val high : float to_attr
  val href : _ string_attr
  val id : _ string_attr
  val lang : _ string_attr
  val list : _ string_attr
  val low : float to_attr
  val max : _ string_attr
  val maxlength : int to_attr
  val method_ : [< `GET | `POST] to_attr
  val min : _ string_attr
  val minlength : int to_attr
  val multiple : attr
  val name : _ string_attr
  val onblur : _ string_attr
  val onclick : _ string_attr
  val optimum : float to_attr
  val pattern : _ string_attr
  val placeholder : _ string_attr
  val readonly : attr
  val required : attr
  val rel : _ string_attr
  val rows : int to_attr
  val size : _ string_attr
  val sizes : _ string_attr
  val src : _ string_attr
  val step : _ string_attr
  val style : _ string_attr
  val tabindex : int to_attr
  val title : _ string_attr

  val type_ : _ string_attr
  (** Note: this can't be restricted to just the allowed values for [<input type>],
      because it's used on other elements e.g. [<link type>]. *)

  val value : _ string_attr
  val width : _ string_attr
end
(** Where an attribute name conflicts with an OCaml keyword, the name is suffixed
    with [_]. *)

module Tag : sig
  val null : node list -> node
  (** A tag that will not be rendered in the markup. Useful for containing a bunch
      of child nodes inside a single node without having to litter the DOM with an
      actual node. Also may be called 'splicing'. *)

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
  val option : std_tag
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
  val script : std_tag
  val section : std_tag
  val select : std_tag
  val slot : std_tag
  val small : std_tag
  val source : void_tag
  val span : std_tag
  val strong : std_tag
  val style : std_tag
  val sub : std_tag
  val summary : std_tag
  val sup : std_tag
  val table : std_tag
  val tbody : std_tag
  val td : std_tag
  val template : std_tag
  val textarea : std_tag
  val tfoot : std_tag
  val th : std_tag
  val thead : std_tag
  val time : std_tag
  val tr : std_tag
  val track : void_tag
  val title : std_tag
  val u : std_tag
  val ul : std_tag
  val var : std_tag
  val video : std_tag
  val wbr : void_tag
end

module Hx : sig
  val boost : bool to_attr
  val confirm : _ string_attr
  val delete : _ string_attr
  val get : _ string_attr
  val on : _ string_attr
  val post : _ string_attr
  val push_url : _ string_attr
  val select : _ string_attr
  val select_oob : _ string_attr
  val swap : _ string_attr
  val swap_oob : _ string_attr
  val target : _ string_attr
  val trigger : _ string_attr
  val vals : _ string_attr
end
(** htmx core attributes {: https://htmx.org/reference/#attributes} *)
