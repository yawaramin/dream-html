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

let test_html msg node = Format.printf "\n\n✔︎ %s\n%a\n" msg pp node

let test_xml ?header msg node =
  Format.printf "\n\n🔎 %s\n%a\n" msg (pp_xml ?header) node

let () =
  test_html "HTML"
  @@
  let open HTML in
  let greet nm = p [id "greet-%s" nm] [txt "Hello, %s!" nm] in
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
                  a [href "/😉"; Hx.headers {|{"foo": 1}|}] [txt "wink"];
                  MathML.math [style_ ""] [] ];
              input
                [ type_ "text";
                  autocomplete `name;
                  title_ "<script>alert('oops')";
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

let () =
  test_html "HTML pretty print corner cases"
  @@
  let open HTML in
  (* test empty tags don't break line *)
  div [] [p [translate `yes] []]

let () =
  let open HTML in
  test_html "Concat HTML - empty list" (concat (txt ", ") []);
  test_html "Concat HTML - singleton list"
    (concat (txt ", ") [a [href "/"] [txt "Home"]]);
  test_html "Concat HTML - list"
    (concat (txt ", ") [a [href "/"] [txt "Home"]; a [href "/a"] [txt "a"]])

let () =
  let open HTML in
  try ignore (div [id "foo"] [] +@ id "bar")
  with Invalid_argument _ ->
    Format.printf "\n\n✔︎ test raise on adding duplicate attribute\n"

let () =
  let open HTML in
  test_html "add class attribute to existing"
    (div [class_ "foo"] [] +@ class_ "bar")

let () =
  let open HTML in
  test_html "add new attribute" (div [id "foo"] [] +@ class_ "bar")

let () =
  let node =
    let open HTML in
    div [class_ "a b c"] [p [class_ "d e f"] []; p [class_ "g h i"] []]
  in
  node
  |> fold
       ~tag:(fun _name attrs classes ->
         match List.find_opt (fun (n, _) -> n = "class") attrs with
         | Some (_name, c) -> classes ^ " " ^ c
         | None -> classes)
       ~txt:(fun _string c -> c)
       ~comment:(fun _string c -> c)
       ""
  |> Printf.printf "\n\n✔︎ fold node: %s\n"

let () =
  test_xml ~header:true "SVG"
  @@
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

let () =
  test_xml "MathML"
  @@
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
                                      msup [] [mi [] [txt "x"]; mn [] [txt "2"]]
                                    ];
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
                                  msup [] [mi [] [txt "a"]; mn [] [txt "2"]] ]
                            ] ] ];
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
                                  mrow [] [mn [] [txt "2"]; mi [] [txt "a"]] ];
                              mo [] [txt ")"];
                              mo [] [txt "("];
                              mi [] [txt "x"];
                              mo [] [txt "+"];
                              mfrac []
                                [ mrow [] [mi [] [txt "b"]];
                                  mrow [] [mn [] [txt "2"]; mi [] [txt "a"]] ];
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
                              msup [] [mi [] [txt "a"]; mn [] [txt "2"]] ] ] ];
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
                              msup [] [mi [] [txt "a"]; mn [] [txt "2"]] ] ] ];
                  mtd []
                    [mrow [] [mtext [style_ "color: red; font-size: 10pt;"] []]]
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
                                      mrow [] [mn [] [txt "2"]; mi [] [txt "a"]]
                                    ] ] ] ] ];
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
                                  msup [] [mi [] [txt "a"]; mn [] [txt "2"]] ]
                            ] ] ];
                  mtd []
                    [mrow [] [mtext [style_ "color: red; font-size: 10pt;"] []]]
                ];
              mtr []
                [ mtd [] [mi [] [txt "x"]];
                  mtd [] [mo [] [txt "="]];
                  mtd []
                    [ mfrac []
                        [ mrow [] [mo [] [txt "−"]; mi [] [txt "b"]];
                          mrow [] [mn [] [txt "2"]; mi [] [txt "a"]] ];
                      mo [] [txt "±"];
                      mrow [] [mo [] [txt "{"]; mi [] [txt "C"]; mo [] [txt "}"]];
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
                                  msup [] [mi [] [txt "a"]; mn [] [txt "2"]] ]
                            ] ] ];
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
                    [mrow [] [mtext [style_ "color: red; font-size: 10pt;"] []]]
                ] ] ] ]

let () =
  test_xml ~header:true "RSS"
  @@
  let open Pure_html in
  let open RSS in
  rss [Atom.xmlns; version_2]
    [ channel []
        [ title [] "NASA Space Station News";
          link [] "http://www.nasa.gov/";
          description []
            "A RSS news feed containing the latest NASA press releases on the International Space Station.";
          language [] "en-us";
          pub_date [] "Tue, 10 Jun 2003 04:00:00 GMT";
          last_build_date [] "Fri, 21 Jul 2023 09:04 EDT";
          docs [] "https://www.rssboard.org/rss-specification";
          generator [] "pure-html";
          managing_editor [] "neil.armstrong@example.com (Neil Armstrong)";
          web_master [] "sally.ride@example.com (Sally Ride)";
          Atom.link
            HTML.
              [ href "https://www.rssboard.org/files/sample-rss-2.xml";
                rel "self";
                type_ "application/rss+xml" ]
            [];
          item []
            [ title []
                "Louisiana Students to Hear from NASA Astronauts Aboard Space Station";
              link []
                "http://www.nasa.gov/press-release/louisiana-students-to-hear-from-nasa-astronauts-aboard-space-station";
              description []
                "As part of the state's first Earth-to-space call, students from Louisiana will have an opportunity soon to hear from NASA astronauts aboard the International Space Station.";
              pub_date [] "Fri, 21 Jul 2023 09:04 EDT";
              guid []
                "http://www.nasa.gov/press-release/louisiana-students-to-hear-from-nasa-astronauts-aboard-space-station"
            ] ] ]
