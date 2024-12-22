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

let route_path = Context_free.Rule.extension path_extender
let () = Driver.register_transformation ~rules:[route_path] "ppx_dream_html"
