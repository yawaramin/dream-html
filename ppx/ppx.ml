(* Copyright 2024 Yawar Amin

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

open Ppxlib
open Ast_builder.Default

let is_valid path = String.length path > 0 && path.[0] = '/'

let expansion ~loc s =
  pexp_apply ~loc
    (evar ~loc "Dream_html.path")
    [Nolabel, estring ~loc s; Nolabel, estring ~loc s]

let err ~loc path =
  Location.error_extensionf ~loc
    "Invalid path: '%s'. Paths must start with a '/' character" path

let binding_extender =
  Extension.V3.declare "path" Extension.Context.structure_item
    Ast_pattern.(
      pstr
        (pstr_value drop (value_binding ~pat:__ ~expr:(estring __) ^:: nil)
        ^:: nil))
    (fun ~ctxt pat s ->
      let loc = Expansion_context.Extension.extension_point_loc ctxt in
      if is_valid s then
        pstr_value ~loc Nonrecursive
          [value_binding ~loc ~pat ~expr:(expansion ~loc s)]
      else
        pstr_extension ~loc (err ~loc s) [])

let expr_extender =
  Extension.V3.declare "path" Extension.Context.expression
    Ast_pattern.(single_expr_payload (estring __))
    (fun ~ctxt s ->
      let loc = Expansion_context.Extension.extension_point_loc ctxt in
      if is_valid s then
        expansion ~loc s
      else
        pexp_extension ~loc (err ~loc s))

let path_binding = Context_free.Rule.extension binding_extender
let path_expr = Context_free.Rule.extension expr_extender

let () =
  Driver.register_transformation ~rules:[path_binding; path_expr]
    "dream-html.ppx"
