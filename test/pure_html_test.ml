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

open Pure_html

let test msg output =
  Printf.printf "\n\n🔎 %s\n%!" msg;
  output ()

let () =
  test "HTML" @@ fun () ->
  let greet nm =
    let open HTML in
    p [id "greet-%s" nm] [txt "Hello, %s!" nm]
  in
  let html_node =
    let open HTML in
    html
      [lang "en"]
      [ head []
          [ title [] "Dream_html Test";
            link [rel "preload"; as_ "style"; href "/app.css"] ];
        body
          [id "test-content"]
          [ main
              [spellcheck true; colspan 1]
              [ article
                  [id "article-1"; class_ "story"]
                  [ p
                      [Hx.get "/p1?a b"; Hx.target "closest article > p"]
                      [txt "Test para 1."];
                    p [] [txt "Test para 2."];
                    a [href "/a?b=cd:efg/hij"] [txt "cd:efg/hij"];
                    a [href "/foo?a=1&b=2 3&c=4<5&d=6>5"] [txt "Test"];
                    a [href "/😉"] [txt "wink"];
                    MathML.math [style_ ""] [] ];
                input
                  [ type_ "text";
                    autocomplete `name;
                    onblur "if (1 > 0) alert(this.value)" ];
                null
                  [ comment "oops --><script>alert('lol')</script>";
                    dialog [open_; title_ {|"hello"|}] [div [] []];
                    template [id "idtmpl"] [p [] [txt "Template"]];
                    div [translate `no] [p [translate `yes] []];
                    textarea
                      [ required;
                        Hx.trigger "keyup[target.value.trim() != '']";
                        autocapitalize `words ]
                      "'super'";
                    hr [(if true then class_ "super" else null_)];
                    greet "Bob" ] ] ] ]
  in
  html_node |> to_string |> print_endline

let () =
  test "HTML pretty print corner cases" @@ fun () ->
  let open HTML in
  (* test empty tags don't break line *)
  let empty_tag = div [] [p [translate `yes] []] in
  empty_tag |> to_string |> print_endline

let () =
  test "SVG" @@ fun () ->
  let svg_node =
    let open SVG in
    svg
      [ xmlns;
        fill "none";
        viewbox ~min_x:0 ~min_y:0 ~width:24 ~height:24;
        stroke_width "1.5";
        stroke "currentColor";
        HTML.class_ "w-6 h-6" ]
      [ path
          [ stroke_linecap `round;
            stroke_linejoin `round;
            d "M4.5 10.5L12 3m0 0l7.5 7.5M12 3v18" ]
          [] ]
  in
  svg_node |> to_xml ~header:true |> print_endline

let () =
  test "MathML" @@ fun () ->
  let mathml_node =
    let open HTML in
    let open MathML in
    p []
      [ math
          [style_ ""]
          [ mtable []
              [ mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow []
                              [ mrow []
                                  [ mrow []
                                      [ mi [] [txt "a"];
                                        mo [] [txt "⁢"];
                                        msup []
                                          [mi [] [txt "x"]; mn [] [txt "2"]] ];
                                    mo [] [txt "+"];
                                    mi [] [txt "b"];
                                    mo [] [txt "⁢"];
                                    mi [] [txt "x"] ];
                                mo [] [txt "+"];
                                mi [] [txt "c"] ] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd [] [mn [] [txt "0"]] ];
                mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow []
                              [ mi [] [txt "a"];
                                mo [] [txt "⁢"];
                                msup [] [mi [] [txt "x"]; mn [] [txt "2"]] ];
                            mo [] [txt "+"];
                            mi [] [txt "b"];
                            mo [] [txt "⁢"];
                            mi [] [txt "x"] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd [] [mo [] [txt "−"]; mi [] [txt "c"]] ];
                mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow [] [msup [] [mi [] [txt "x"]; mn [] [txt "2"]]];
                            mo [] [txt "+"];
                            mfrac [] [mi [] [txt "b"]; mi [] [txt "a"]];
                            mo [] [txt "⁤"];
                            mi [] [txt "x"] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ mfrac []
                          [ mrow [] [mo [] [txt "−"]; mi [] [txt "c"]];
                            mi [] [txt "a"] ] ];
                    mtd []
                      [ mrow []
                          [ mtext
                              [style_ "color: red; font-size: 10pt;"]
                              [txt "Divide out leading coefficient."] ] ] ];
                mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow []
                              [ mrow []
                                  [msup [] [mi [] [txt "x"]; mn [] [txt "2"]]];
                                mo [] [txt "+"];
                                mfrac []
                                  [mrow [] [mi [] [txt "b"]]; mi [] [txt "a"]];
                                mo [] [txt "⁤"];
                                mi [] [txt "x"];
                                mo [] [txt "+"];
                                msup []
                                  [ mrow []
                                      [ mo [] [txt "("];
                                        mfrac []
                                          [ mrow [] [mi [] [txt "b"]];
                                            mrow []
                                              [mn [] [txt "2"]; mi [] [txt "a"]]
                                          ];
                                        mo [] [txt ")"] ];
                                    mn [] [txt "2"] ] ] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ mrow []
                          [ mfrac []
                              [ mrow []
                                  [ mo [] [txt "−"];
                                    mi [] [txt "c"];
                                    mo [] [txt "("];
                                    mn [] [txt "4"];
                                    mi [] [txt "a"];
                                    mo [] [txt ")"] ];
                                mrow []
                                  [ mi [] [txt "a"];
                                    mo [] [txt "("];
                                    mn [] [txt "4"];
                                    mi [] [txt "a"];
                                    mo [] [txt ")"] ] ];
                            mo [] [txt "+"];
                            mfrac []
                              [ mrow []
                                  [msup [] [mi [] [txt "b"]; mn [] [txt "2"]]];
                                mrow []
                                  [ mn [] [txt "4"];
                                    msup [] [mi [] [txt "a"]; mn [] [txt "2"]]
                                  ] ] ] ];
                    mtd []
                      [ mrow []
                          [ mtext
                              [style_ "color: red; font-size: 10pt;"]
                              [txt "Complete the square."] ] ] ];
                mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow []
                              [ mo [] [txt "("];
                                mi [] [txt "x"];
                                mo [] [txt "+"];
                                mfrac []
                                  [ mrow [] [mi [] [txt "b"]];
                                    mrow [] [mn [] [txt "2"]; mi [] [txt "a"]]
                                  ];
                                mo [] [txt ")"];
                                mo [] [txt "("];
                                mi [] [txt "x"];
                                mo [] [txt "+"];
                                mfrac []
                                  [ mrow [] [mi [] [txt "b"]];
                                    mrow [] [mn [] [txt "2"]; mi [] [txt "a"]]
                                  ];
                                mo [] [txt ")"] ] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ mfrac []
                          [ mrow []
                              [ msup [] [mi [] [txt "b"]; mn [] [txt "2"]];
                                mo [] [txt "−"];
                                mn [] [txt "4"];
                                mi [] [txt "a"];
                                mi [] [txt "c"] ];
                            mrow []
                              [ mn [] [txt "4"];
                                msup [] [mi [] [txt "a"]; mn [] [txt "2"]] ] ]
                      ];
                    mtd []
                      [ mrow []
                          [ mtext
                              [style_ "color: red; font-size: 10pt;"]
                              [txt "Discriminant revealed."] ] ] ];
                mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow []
                              [ msup []
                                  [ mrow []
                                      [ mo [] [txt "("];
                                        mi [] [txt "x"];
                                        mo [] [txt "+"];
                                        mfrac []
                                          [ mrow [] [mi [] [txt "b"]];
                                            mrow []
                                              [mn [] [txt "2"]; mi [] [txt "a"]]
                                          ];
                                        mo [] [txt ")"] ];
                                    mn [] [txt "2"] ] ] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ mfrac []
                          [ mrow []
                              [ msup [] [mi [] [txt "b"]; mn [] [txt "2"]];
                                mo [] [txt "−"];
                                mn [] [txt "4"];
                                mi [] [txt "a"];
                                mi [] [txt "c"] ];
                            mrow []
                              [ mn [] [txt "4"];
                                msup [] [mi [] [txt "a"]; mn [] [txt "2"]] ] ]
                      ];
                    mtd []
                      [ mrow []
                          [mtext [style_ "color: red; font-size: 10pt;"] []] ]
                  ];
                mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow []
                              [ mrow []
                                  [ mi [] [txt "x"];
                                    mo [] [txt "+"];
                                    mfrac []
                                      [ mrow [] [mi [] [txt "b"]];
                                        mrow []
                                          [mn [] [txt "2"]; mi [] [txt "a"]] ]
                                  ] ] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ msqrt []
                          [ mfrac []
                              [ mrow []
                                  [ msup [] [mi [] [txt "b"]; mn [] [txt "2"]];
                                    mo [] [txt "−"];
                                    mn [] [txt "4"];
                                    mi [] [txt "a"];
                                    mi [] [txt "c"] ];
                                mrow []
                                  [ mn [] [txt "4"];
                                    msup [] [mi [] [txt "a"]; mn [] [txt "2"]]
                                  ] ] ] ];
                    mtd []
                      [ mrow []
                          [mtext [style_ "color: red; font-size: 10pt;"] []] ]
                  ];
                mtr []
                  [ mtd [] [mi [] [txt "x"]];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ mfrac []
                          [ mrow [] [mo [] [txt "−"]; mi [] [txt "b"]];
                            mrow [] [mn [] [txt "2"]; mi [] [txt "a"]] ];
                        mo [] [txt "±"];
                        mrow []
                          [mo [] [txt "{"]; mi [] [txt "C"]; mo [] [txt "}"]];
                        msqrt []
                          [ mfrac []
                              [ mrow []
                                  [ msup [] [mi [] [txt "b"]; mn [] [txt "2"]];
                                    mo [] [txt "−"];
                                    mn [] [txt "4"];
                                    mi [] [txt "a"];
                                    mi [] [txt "c"] ];
                                mrow []
                                  [ mn [] [txt "4"];
                                    msup [] [mi [] [txt "a"]; mn [] [txt "2"]]
                                  ] ] ] ];
                    mtd []
                      [ mrow []
                          [ mtext
                              [style_ "color: red; font-size: 10pt;"]
                              [txt "There's the vertex formula."] ] ] ];
                mtr []
                  [ mtd [] [mi [] [txt "x"]];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ mfrac []
                          [ mrow []
                              [ mo [] [txt "−"];
                                mi [] [txt "b"];
                                mo [] [txt "±"];
                                mrow []
                                  [ mo [] [txt "{"];
                                    mi [] [txt "C"];
                                    mo [] [txt "}"] ];
                                msqrt []
                                  [ msup [] [mi [] [txt "b"]; mn [] [txt "2"]];
                                    mo [] [txt "−"];
                                    mn [] [txt "4"];
                                    mi [] [txt "a"];
                                    mi [] [txt "c"] ] ];
                            mrow [] [mn [] [txt "2"]; mi [] [txt "a"]] ] ];
                    mtd []
                      [ mrow []
                          [mtext [style_ "color: red; font-size: 10pt;"] []] ]
                  ] ] ] ]
  in
  mathml_node |> to_xml |> print_endline
