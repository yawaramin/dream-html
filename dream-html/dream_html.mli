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

(** {2 Input} *)

(** Typed, extensible HTML form decoder with error reporting for {i all} form
    field validation failures.

    See the bottom of the page for complete examples.

    @since 3.7.0. *)
module Form : sig
  (** {2 Basic type decoders} *)

  type 'a ty = string -> ('a, string) result
  (** The type of a decoder for a single form field value of type ['a] which can
      successfully decode the field value or fail with an error message key. *)

  (** In the following type decoders, the minimum and maximum values are all
      {i inclusive}. *)

  val bool : bool ty
  val char : ?min:char -> ?max:char -> char ty
  val float : ?min:float -> ?max:float -> float ty
  val int : ?min:int -> ?max:int -> int ty
  val int32 : ?min:int32 -> ?max:int32 -> int32 ty
  val int64 : ?min:int64 -> ?max:int64 -> int64 ty
  val string : ?min_length:int -> ?max_length:int -> string ty

  (** {2 Forms and fields} *)

  type 'a t
  (** The type of a form (a form field by itself is also considered a form) which
      can decode values of type ['a] or fail with a list of error message keys. *)

  val list : ?min_length:int -> ?max_length:int -> 'a ty -> string -> 'a list t
  (** [list ?min_length ?max_length ty name] is a form field which can decode a
      list of values which can each be decoded by [ty]. The list must have at
      least [min_length] and at most [max_length] (inclusive). *)

  val optional : 'a ty -> string -> 'a option t
  (** [optional ty name] is a form field which can decode an optional value from
      the form. *)

  val required : ?default:'a -> 'a ty -> string -> 'a t
  (** [required ?default ty name] is a form field which can decode a required
      value from the form. If at least one value corresponding to the given
      [name] does not appear in the form, and if a [default] value is not
      specified, the decoding fails with an error. *)

  val ensure :
    string ->
    ('b -> bool) ->
    ('a ty -> string -> 'b t) ->
    'a ty ->
    string ->
    'b t
  (** [ensure message condition field ty name] is a form field which imposes an
      additional [condition] on top of the existing [field]. If the condition
      fails, the result is an error [message]. It is suggested that the [message]
      be a translation key so that the application can be localized to different
      languages. *)

  (** {2 Form decoders} *)

  val ( let+ ) : 'a t -> ('a -> 'b) -> 'b t
  (** [let+ email = required string "email"] decodes a form field named [email]
      as a [string]. *)

  val ( and+ ) : 'a t -> 'b t -> ('a * 'b) t
  (** [and+ password = required string "password"] continues decoding in an
      existing form declaration and decodes a form field [password] as a [string]. *)

  val ( or ) : 'a t -> 'a t -> 'a t
  (** [form1 or form2] is [form1] if it succeeds, else [form2]. *)

  val validate :
    'a t -> (string * string) list -> ('a, (string * string) list) result
  (** [validate form values] is a result of validating the given [form]'s
      [values]. It may be either some value of type ['a] or a list of form field
      names and the corresponding error message keys. *)

  val pp_error : (string * string) list Fmt.t
  (** [pp_error] is a helper pretty-printer for debugging/troubleshooting form
      validation errors. *)

  (** {2 Error keys}

      When errors are reported, the following keys are used instead of English
      strings. These keys can be used for localizing the error messages. The
      suggested default English translations are given below.

      These keys are modelled after
      {{: https://github.com/playframework/playframework/blob/6f5129e6e3b9c784948b56d486d1ef1e5efef163/core/play/src/main/resources/messages.default} Play Framework}. *)

  val error_expected_bool : string
  (** Please enter [true] or [false]. *)

  val error_expected_char : string
  (** Please enter a single character. *)

  val error_expected_single : string
  (** Please enter a single value. *)

  val error_expected_int : string
  (** Please enter a valid integer. *)

  val error_expected_int32 : string
  (** Please enter a valid 32-bit integer. *)

  val error_expected_int64 : string
  (** Please enter a valid 64-bit integer. *)

  val error_expected_number : string
  (** Please enter a valid number. *)

  val error_length : string
  (** Please enter a value of the expected length. *)

  val error_range : string
  (** Please enter a value in the expected range. *)

  val error_required : string
  (** Please enter a value. *)

  (** {2 Examples}

  Basic complete example:

  {[
  type user = { name : string; age : int option}

  open Dream_html.Form

  let user_form =
    let+ name = required string "name"
    and+ age = optional (int ~min:16) "age" in (* Thanks, Australia! *)
    { name; age }

  let dream_form = ["age", "42"; "name", "Bob"]
  let user_result = validate user_form dream_form
  ]}

  Result: [Ok { name = "Bob"; age = Some 42 }]

  Sad path:

  {[validate user_form ["age", "none"]]}

  Result: [Error [("age", "error.expected.int"); ("name", "error.required")]]

  Notice that validation errors for {i all} fields are reported. This is a
  critical design decision that differentiates this module from others available
  in OCaml.

  Decode list of values from form:

  {[
  type plan = { id : string; features : string list }

  let plan_form =
    let+ id = required string "id"
    and+ features = list string "features" in
    { id; features }

  validate plan_form ["id", "foo"]
  ]}

  Result: [Ok {id = "foo"; features = []}]

  {[validate plan_form ["id", "foo"; "features", "f1"; "features", "f2"]]}

  Result: [Ok {id = "foo"; features = ["f1"; "f2"]}]

  Note that the names can be anything, eg ["features[]"] if you prefer.

  Add further requirements to field values:

  {[
  let plan_form =
    let+ id = ensure "error.expected.nonempty" (( <> ) "") required string "id"
    and+ features = list string "features" in
    { id; features }

  validate plan_form ["id", ""]
  ]}

  Result: [Error [("id", "error.expected.nonempty")]]
  *)
end

val form :
  'a Form.t ->
  ?csrf:bool ->
  Dream.request ->
  [> 'a Dream.form_result | `Invalid of (string * string) list] Dream.promise
(** Type-safe wrapper for [Dream.form]. Similarly to that, you can match on the
    result:

    {[
    type new_user = { name : string; email : string }
    let new_user =
      let open Dream_html.Form in
      let+ name = required string "name"
      and+ email = required string "email" in
      { name; email }

    (* POST /users *)
    let post_users req =
      match%lwt Dream_html.form new_user req with
      | `Ok { name; email } -> (* ... *)
      | `Invalid errors -> Dream.json ~code:422 ( (* ...render errors... *) )
      | _ -> Dream.empty `Bad_Request
    ]}

    @since 3.8.0 *)

val query :
  'a Form.t ->
  Dream.request ->
  [> `Ok of 'a | `Invalid of (string * string) list]
(** Type-safe wrapper for [Dream.all_queries]. Can be used to decode the query
    parameters into a typed value.

    @since 3.8.0 *)

(** {2 Output} *)

include module type of Pure_html

val respond :
  ?status:[< Dream.status] ->
  ?code:int ->
  ?headers:(string * string) list ->
  node ->
  Dream.response Dream.promise

val send :
  ?text_or_binary:[< Dream.text_or_binary] ->
  ?end_of_message:[< Dream.end_of_message] ->
  Dream.websocket ->
  node ->
  unit Dream.promise
(** Type-safe wrapper for [Dream.send].

    @since 3.2.0. *)

val set_body : Dream.response -> node -> unit
(** Type-safe wrapper for [Dream.set_body]. Sets the body to the given [node] and
    sets the [Content-Type] header to [text/html]. *)

val write : Dream.stream -> node -> unit Dream.promise
(** Type-safe wrapper for [Dream.write]. *)

val csrf_tag : Dream.request -> node
(** Convenience to add a CSRF token generated by Dream into your form. Type-safe
    wrapper for [Dream.csrf_tag].

    {[form
        [action "/foo"]
        [csrf_tag req; input [name "bar"]; input [type_ "submit"]]]} *)

(** {2 Live reload support} *)

(** Live reload script injection and handling. Adapted from [Dream.livereload]
    middleware. This version is not a middleware so it's not as plug-and-play as
    that, but on the other hand it's much simpler to implement because it uses
    type-safe dream-html nodes rather than parsing and printing raw HTML. See
    below for the 3-step process to use it.

    This module is adapted from Dream, released under the MIT license. For
    details, visit {{: https://github.com/aantron/dream}}.

    Copyright 2021-2023 Thibaut Mattio, Anton Bachin.

    @since 3.4.0. *)
module Livereload : sig
  val route : Dream.route
  (** (1) Put this in your top-level router:

      {[let () = Dream.run
        @@ Dream.logger
        @@ Dream.router [
          Dream_html.Livereload.route;
          (* ...other routes... *)
      ]]} *)

  val script : node
  (** (2) Put this inside your [head]:

      {[head [] [
        Livereload.script;
        (* ... *)
      ]]} *)

  (** (3) And run the server with environment variable [LIVERELOAD=1].

      {b ⚠️ If this env var is not set, then livereload is turned off.} This means
      that the [route] will respond with [404] status and the script will be
      omitted from the rendered HTML. *)
end
