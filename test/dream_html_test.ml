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

open Dream_html

let greet nm =
  let open HTML in
  p [id "greet-%s" nm] [txt "Hello, %s!" nm]

let html_node =
  let open HTML in
  html
    [lang "en"]
    [ head [] [title [] "Dream_html Test"];
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
                  a [href "/😉"] [txt "wink"] ];
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

let () =
  html_node |> to_string |> print_endline;
  svg_node |> to_string |> print_endline
