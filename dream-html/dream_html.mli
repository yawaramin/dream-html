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

(** Typed, extensible HTML form decoder with error reporting for form field
    validation failures. Powerful chained decoding functionality–the validation
    of one field can depend on the values of other decoded fields.

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

  val unix_tm : ?min:Unix.tm -> ?max:Unix.tm -> Unix.tm ty
  (** This can parse strings with the formats [2024-01-01] or
      [2024-01-01T00:00:00] into a timestamp.

      Note that this is {i not} timezone-aware.

      @since 3.8.0 *)

  (** {2 Forms and fields} *)

  type 'a t
  (** The type of a form (a form field by itself is also considered a form)
      which can decode values of type ['a] or fail with a list of error message
      keys. *)

  val ok : 'a -> 'a t
  (** [ok value] is a form field that always successfully returns [value].

      @since 3.8.0 *)

  val error : string -> string -> 'a t
  (** [error name message] is a form field that always errors the field [name]
      with the [message].

      These allow adding adding further checks to the entire form using all
      decoded field values and then attaching more errors to specific fields (or
      not).

      @since 3.8.0 *)

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

  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t
  (** [let* start_date = required unix_tm "start-date"] decodes a form field and
      allows accessing it in the subsequent decoders. Eg:

      {[
      let* start_date = required unix_tm "start-date" in
      let+ end_date = required (unix_tm ~min:start_date) "end-date" in
      ...
      ]}

      However, note that [let*] uses a 'fail-fast' decoding strategy. If there is
      a decoding error, it immediately returns the error without decoding the
      subsequent fields. (Which makes sense if you think about the example above.)
      So, in order to ensure complete error reporting for all fields, you would
      need to use [let+] and [and+].

      @since 3.8.0 *)

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
  [@@ocaml.toplevel_printer]
  (** [pp_error] is a helper pretty-printer for debugging/troubleshooting form
      validation errors. *)

  (** {2 Error keys}

      When errors are reported, the following keys are used instead of English
      strings. These keys can be used for localizing the error messages. The
      suggested default English translations are given below.

      These keys are modelled after
      {{:https://github.com/playframework/playframework/blob/6f5129e6e3b9c784948b56d486d1ef1e5efef163/core/play/src/main/resources/messages.default}
       Play Framework}. *)

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

  val error_expected_time : string
  (** Please enter a valid date or date-time. *)

  val error_length : string
  (** Please enter a value of the expected length. *)

  val error_range : string
  (** Please enter a value in the expected range. *)

  val error_required : string
  (** Please enter a value. *)

  (** {2 Examples}

      Basic complete example:

      {[
      type user = { name : string; age : int option }

      open Dream_html.Form

      let user_form =
        let+ name = required string "name"
        and+ age = optional (int ~min:16) "age" in
        (* Thanks, Australia! *)
        { name; age }

      let dream_form = ["age", "42"; "name", "Bob"]
      let user_result = validate user_form dream_form
      ]}

      Result: [Ok { name = "Bob"; age = Some 42 }]

      Sad path:

      {[validate user_form ["age", "none"]]}

      Result:
      [Error [("age", "error.expected.int"); ("name", "error.required")]]

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

      Complex validation rules with multiple fields:

      {[
      type req = {
        id : string;
        years : int option;
        months : int option;
        weeks : int option;
        days : int option;
      }

      let req_form =
        let+ id = required string "id" (* Both id... *)
        and+ days, weeks, months, years = (* ...and period are required *)
          let* days = optional int "days" in
          let* weeks = optional int "weeks" in
          let* months = optional int "months" in
          let* years = optional int "years" in
          match days, weeks, months, years with
          | None, None, None, None -> error "years" "Please enter a period"
          (* Only one period component is required *)
          | _ -> ok (days, weeks, months, years)
        in
        { id; days; weeks; months; years }

      validate req []
      ]}

      Result: [Error [("years", "Please enter a period"); ("id", "error.required")]]
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
    equivalent of [Dream.csrf_tag].

    {[
    form [action "/foo"] [
      csrf_tag req;
      input [name "bar"];
      input [type_ "submit"];
    ]
    ]} *)

(** {2 Type-safe routing}

    Bidirectional paths with type-safe path segment parsing and printing using
    OCaml's built-in format strings, and fully plug-and-play compatible with
    Dream routes. *)

type (_, _) path
(** A path that can be used for routing and can also be printed as an attribute value.

    @since 3.9.0 *)

type ('r, 'p) route = ('r, 'p) path -> (Dream.request -> 'r) -> Dream.route
(** Wrapper for a Dream route that represents the ability to parse path
    parameters and pass them to the handler function with the correct types.

    @since 3.9.0 *)

val path :
  ('r, unit, Dream.response Dream.promise) format ->
  ('p, unit, string, attr) format4 ->
  ('r, 'p) path
(** [path request_fmt attr_fmt] is a router path. The [dream-html.ppx] provides
    a more convenient way.

    Without PPX: [let order = path "/orders/%s" "/orders/%s"]

    With PPX: [let%path order = "/orders/%s"]

    Refer to {{!Ppx} the PPX documentation} for instructions on using it.

    ⚠️ Due to the way Dream's router works, all parameter captures happens
    between [/] characters and the end of the path (or the [?] character,
    whichever comes first). Eg, [/foo/%s/bar/%d] is valid, but [/foo/%s.%s] (note
    the dot character) is not a valid capture.

    ⚠️ If a route is matched but the data type does not match, a [400 Bad Request]
    response will be returned. The following type conversion specs are supported:

    [%s] capture a [string] and pass it to the handler

    [%*s] capture the rest of the path and pass the captured length and string to
    the handler

    [%c] capture a [char]

    [%d] or [%i] capture an [int]

    [%x] capture a hexadecimal [int]

    [%X] capture an uppercase hexadecimal [int]

    [%o] capture an octal [int]

    [%ld] capture an [int32]

    [%Ld] capture an [int64]

    [%f] capture a [float]

    [%B] capture a [bool]

    ⚠️ We are actually using Dream's built-in router, not our own, and Dream's
    router doesn't distinguish between parameter types. So, to Dream both [/%s]
    and [/%d] are the same path. It will route the request to whichever happens
    to be first in the route list, and that one will succeed or fail depending on
    its type and the request target.

    @since 3.9.0 *)

val path_attr : 'p string_attr -> (_, 'p) path -> 'p
(** [path_attr attr path] is an HTML attribute with the path parameters filled in
    from the given values. Eg,

    {[
    let%path order = "/orders/%s"

    open Dream_html
    open HTML

    a [path_attr href order "yzxyzc"] [txt "My Order"]
    ]}

    Renders: [<a href="/orders/yzxyzc">My Order</a>]

    Use this instead of hard-coding your route URLs throughout your app, to make
    it easy to refactor routes with minimal effort.

    @since 3.9.0 *)

val pp_path : (_, _) path Fmt.t
[@@ocaml.toplevel_printer]
(** [pp_path] is a pretty-printer for path values. For a path like
    [path "/foo" "/foo"], it will print out [/foo].

    @since 3.9.0 *)

val get : (_, _) route
(** Type-safe wrappers for [Dream.get] and so on. Using the PPX, eg:

    {[
    let%path order = "/orders/%s"

    let get_order = get order (fun request order_id ->
      ...
      a [path_attr href order order_id] [txt "Your order"]
      ...
    )
    ]}

    @since 3.9.0 *)

val post : (_, _) route
(** @since 3.9.0 *)

val put : (_, _) route
(** @since 3.9.0 *)

val delete : (_, _) route
(** @since 3.9.0 *)

val head : (_, _) route
(** @since 3.9.0 *)

val connect : (_, _) route
(** @since 3.9.0 *)

val options : (_, _) route
(** @since 3.9.0 *)

val trace : (_, _) route
(** @since 3.9.0 *)

val patch : (_, _) route
(** @since 3.9.0 *)

val any : (_, _) route
(** @since 3.9.0 *)

val use : Dream.middleware list -> Dream.route list -> Dream.route
(** [use middlewares routes] is a route that is composed of all the given [routes]
    with the [middlewares] attached to them.

    @since 3.9.0 *)

val static_asset : (Dream.response Dream.promise, _) path -> Dream.route
(** [static_asset path] is a route that handles serving the static file at the
    [path]. Importantly, it sets an immutable cache header which remains valid
    for a year.

    ⚠️ Be sure that the resource has a unique identifier because it will be
    cached immutably. The [dreamwork] CLI tool automates this for you. See
    {!dreamwork}.

    @since 3.9.2 *)

(** {2 Dreamwork}

    [dreamwork] is a CLI tool that helps set up and manage static file paths and
    routes with proper content-based version hashes. The static files will live
    inside a dune component called [static] and in the [static/assets]
    subdirectory. Suppose you have the following directory tree:

    {[
    static/
      dune
      assets/
        css/
          app.css
        js/
          app.js
    ]}

    The [dune] file defines a [library] component that will make the following
    module available:

    {[
    module Static : sig
      val routes : Dream.route
      (** This route will serve all of the following paths. *)

      module Assets : sig
        module Css : sig
          val app_css : (Dream.response Dream.promise, attr) Dream_html.path
        end

        module Js : sig
          val app_js : (Dream.response Dream.promise, attr) Dream_html.path
        end
      end
    end
    ]}

    So, you can just stick [Static.routes] in your router and it will correctly
    serve the files from the filesystem with an immutable cache of 1 year; and
    you can use [Static.Assets.Css.app_css] and so on in your dream-html markup
    code and it will correctly render with a [?rev=...] query parameter that
    uniquely identifies this revision of the file with a content-based hash for
    cache-busting purposes:

    {[
    link [rel "stylesheet"; path_attr href Static.Assets.Css.app_css
    (*
    <link
      rel="stylesheet"
      href="/static/assets/css/app.css?rev=17fb8161afc85df86156ea1f3744c8a2"
    >
    *)
    ]}

    {[
    script [path_attr src Static.Assets.Js.app_js] ""
    (*
    <script src="/static/assets/js/app.js?rev=677645e5ac37d683c5039a85c41c339f">
    </script>
    *)
    ]}

    You control the directory subtree under [assets]; the [dreamwork] CLI just
    helps you define the [dune] component that generates the above module
    structure. The module structure mirrors the directory tree structure.

    The entry point to [dreamwork] is the [dreamwork setup] command, which
    creates [static/], [assets/], and [dune]. In the [dune] file it defines a
    code generation rule which uses the [dreamwork static] command to generate
    the OCaml code.
    
    So, you just need to run [dreamwork setup] to initialize the directory
    structure and code generation. After that, you can add and remove any files
    inside [assets/] as you want and on the next dune build the [Static] module
    structure will be updated accordingly.

    @since 3.9.2 *)

(** {2 Live reload support} *)

(** Live reload script injection and handling. Adapted from [Dream.livereload]
    middleware. This version is not a middleware so it's not as plug-and-play as
    that, but on the other hand it's much simpler to implement because it uses
    type-safe dream-html nodes rather than parsing and printing raw HTML. See
    below for the 3-step process to use it.

    This module is adapted from Dream, released under the MIT license. For
    details, visit {:https://github.com/aantron/dream}.

    Copyright 2021-2023 Thibaut Mattio, Anton Bachin.

    @since 3.4.0. *)
module Livereload : sig
  val route : Dream.route
  (** (1) Put this in your top-level router:

      {[
      let () =
        Dream.run
        @@ Dream.logger
        @@ Dream.router [
          Dream_html.Livereload.route;
          (* ...other routes... *)
        ]
      ]} *)

  val script : node
  (** (2) Put this inside your [head]:

      {[head [] [Livereload.script (* ... *)]]} *)

  (** (3) And run the server with environment variable [LIVERELOAD=1].

      {b ⚠️ If this env var is not set, then livereload is turned off.} This
      means that the [route] will respond with [404] status and the script will
      be omitted from the rendered HTML. *)
end
