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

let path_extender =
  Extension.V3.declare "path" Extension.Context.expression
    Ast_pattern.(single_expr_payload (estring __))
    (fun ~ctxt s ->
      let loc = Expansion_context.Extension.extension_point_loc ctxt in
      pexp_apply ~loc
        (evar ~loc "Dream_html.Path.make")
        [Nolabel, estring ~loc s; Nolabel, estring ~loc s])

let path = Context_free.Rule.extension path_extender
let () = Driver.register_transformation ~rules:[path] "dream-html.ppx"
