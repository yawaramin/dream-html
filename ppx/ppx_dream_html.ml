open Ppxlib
open Ast_builder.Default

let method_rule m =
  Context_free.Rule.special_function'
    (Astlib.Longident.parse ("Dream_html.Route." ^ m))
    (function
      | { pexp_desc =
            Pexp_apply
              ( _,
                [ (( Nolabel,
                     { pexp_desc = Pexp_constant (Pconst_string (_, _, _)); _ }
                   ) as fmt_arg);
                  ((Nolabel, _) as hdlr_arg) ] );
          pexp_loc;
          _
        } ->
        Some
          (pexp_apply ~loc:pexp_loc
             (evar ~loc:pexp_loc "Dream_html.Route.make")
             [ ( Labelled "meth",
                 pexp_variant ~loc:pexp_loc (String.uppercase_ascii m) None );
               fmt_arg;
               fmt_arg;
               hdlr_arg ])
      | _ -> None)

let scope_rule =
  Context_free.Rule.special_function'
    (Astlib.Longident.parse "Dream_html.Route.prefix") (function
    | { pexp_desc =
          Pexp_apply
            ( _,
              [ (( Nolabel,
                   { pexp_desc = Pexp_constant (Pconst_string (_, _, _)); _ } )
                 as fmt_arg);
                ((Nolabel, _) as mware_arg);
                ((Nolabel, _) as route_arg) ] );
        pexp_loc;
        _
      } ->
      Some
        (pexp_apply ~loc:pexp_loc
           (evar ~loc:pexp_loc "Dream_html.Route.scope")
           [fmt_arg; fmt_arg; mware_arg; route_arg])
    | _ -> None)

let () =
  Driver.register_transformation
    ~rules:
      [ method_rule "get";
        method_rule "post";
        method_rule "put";
        method_rule "delete";
        method_rule "head";
        method_rule "connect";
        method_rule "options";
        method_rule "trace";
        method_rule "patch";
        scope_rule ]
    "ppx_dream_html"
