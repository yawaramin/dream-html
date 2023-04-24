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

val int_attr : string -> int to_attr
val bool_attr : string -> bool to_attr

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

  val action : _ string_attr
  val autocomplete : _ string_attr
  val autofocus : attr
  val charset : _ string_attr
  val class_ : _ string_attr
  val color : _ string_attr
  val content : _ string_attr
  val for_ : _ string_attr
  val href : _ string_attr
  val id : _ string_attr
  val lang : _ string_attr
  val list : _ string_attr
  val max : _ string_attr
  val maxlength : int to_attr
  val method_ : [< `GET | `POST] to_attr
  val min : _ string_attr
  val minlength : int to_attr
  val name : _ string_attr
  val placeholder : _ string_attr
  val required : attr
  val rel : _ string_attr
  val rows : int to_attr
  val sizes : _ string_attr
  val src : _ string_attr
  val style : _ string_attr
  val tabindex : int to_attr
  val title : _ string_attr

  val type_ : _ string_attr
  (** Note: this can't be restricted to just the allowed values for [<input type>],
      because it's used on other elements e.g. [<link type>]. *)

  val value : _ string_attr
end
(** Where an attribute name conflicts with an OCaml keyword, the name is suffixed
    with [_]. *)

module Tag : sig
  val null : node list -> node
  (** A tag that will not be rendered in the markup. Useful for containing a bunch
      of child nodes inside a single node without having to litter the DOM with an
      actual node. Also may be called 'splicing'. *)

  val a : std_tag
  val area : void_tag
  val abbr : std_tag
  val article : std_tag
  val b : std_tag
  val base : void_tag
  val br : void_tag
  val body : std_tag
  val button : std_tag
  val col : void_tag
  val datalist : std_tag
  val details : std_tag
  val del : std_tag
  val div : std_tag
  val embed : void_tag
  val form : std_tag
  val h1 : std_tag
  val h2 : std_tag
  val h3 : std_tag
  val h4 : std_tag
  val head : std_tag
  val header : std_tag
  val hr : void_tag

  val html : std_tag
  (** A <!DOCTYPE html> declaration is automatically prefixed when this tag is
      printed. *)

  val img : void_tag
  val input : void_tag
  val label : std_tag
  val li : std_tag
  val link : void_tag
  val main : std_tag
  val meta : void_tag
  val option : std_tag
  val p : std_tag
  val script : std_tag
  val source : void_tag
  val span : std_tag
  val summary : std_tag
  val textarea : std_tag
  val track : void_tag
  val title : std_tag
  val ul : std_tag
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
