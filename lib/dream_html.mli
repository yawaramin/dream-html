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

(** Constructing HTML tags. *)

type attr
(** E.g. [id="toast"]. *)

type 'a to_attr = 'a -> attr

type node
(** Either a tag, a comment, or text data in the markup. *)

type std_tag = attr list -> node list -> node
(** A 'standard' tag with attributes and children. *)

type void_tag = attr list -> node
(** A 'void element':
    https://developer.mozilla.org/en-US/docs/Glossary/Void_element *)

val to_string : node -> string
val pp : Format.formatter -> node -> unit

val respond :
  ?status:[< Dream.status] ->
  ?code:int ->
  ?headers:(string * string) list -> node -> Dream.response Lwt.t

val s : ('a, unit, string) format -> 'a
(** This is just [Stdlib.Printf.sprintf]. Needing to interpolate values in
    strings when building HTML is quite common. *)

val string_attr : string -> string to_attr
val int_attr : string -> int to_attr
val bool_attr : string -> bool to_attr

val tag : string -> std_tag
val void_tag : string -> void_tag

val txt : string -> node
(** A text node inside the DOM e.g. the 'hi' in [<b>hi</b>]. *)

val comment : string -> node
(** A comment that will be embedded in the rendered HTML, i.e. [<!-- comment -->]. *)

val raw : string -> node
[@@alert unsafe "Can lead to HTML injection."]
(** Useful for injecting unsanitized content into the markup. Needless to say, be
    very careful with where you use this! *)

module Attr : sig
  val null : attr
  (** An attribute that will not be rendered in the markup. Useful for conditional
      logic where you sometimes want to render an attribute and sometimes not. *)

  val action : string to_attr
  val autocomplete : string to_attr
  val autofocus : attr
  val charset : string to_attr
  val class_ : string to_attr
  val color : string to_attr
  val content : string to_attr
  val for_ : string to_attr
  val href : string to_attr
  val id : string to_attr
  val lang : string to_attr
  val list : string to_attr
  val max : string to_attr
  val maxlength : int to_attr
  val method_ : [< `GET | `POST] to_attr
  val min : string to_attr
  val minlength : int to_attr
  val name : string to_attr
  val placeholder : string to_attr
  val required : attr
  val rel : string to_attr
  val rows : int to_attr
  val sizes : string to_attr
  val src : string to_attr
  val style : string to_attr
  val tabindex : int to_attr
  val title : string to_attr
  val type_ : string to_attr
  val value : string to_attr
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
  (** A <!doctype html> declaration is automatically prefixed when this tag is
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
  val confirm : string to_attr
  val delete : string to_attr
  val get : string to_attr
  val post : string to_attr
  val swap : string to_attr
  val swap_oob : string to_attr
  val target : string to_attr
  val trigger : string to_attr
end
(** Convenient helpers for building htmx interactions. *)
