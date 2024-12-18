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

let%expect_test "HTML" =
  let greet nm =
    let open HTML in
    p [id "greet-%s" nm] [txt "Hello, %s!" nm]
  in
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
  html_node |> to_string |> print_endline;
  [%expect
    {|
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <title>Dream_html Test</title>
      </head>
      <body id="test-content">
        <main spellcheck="true" colspan="1">
          <article id="article-1" class="story">
            <p data-hx-get="/p1?a%20b" data-hx-target="closest article > p">Test para 1.</p>
            <p>Test para 2.</p>
            <a href="/a?b=cd:efg/hij">cd:efg/hij</a>
            <a href="/foo?a=1&amp;b=2%203&amp;c=4%3C5&amp;d=6%3E5">Test</a>
            <a href="/%F0%9F%98%89">wink</a>
            <math style=""></math>
          </article>
          <input type="text" autocomplete="name" onblur="if (1 > 0) alert(this.value)">
          <!-- oops --&gt;&lt;script&gt;alert('lol')&lt;/script&gt; -->
          <dialog open title="&quot;hello&quot;">
            <div></div>
          </dialog>
          <template id="idtmpl">
            <p>Template</p>
          </template>
          <div translate="no">
            <p translate="yes"></p>
          </div>
          <textarea required data-hx-trigger="keyup[target.value.trim() != '']" autocapitalize="words">'super'</textarea>
          <hr class="super">
          <p id="greet-Bob">Hello, Bob!</p>
        </main>
      </body>
    </html>
    |}]

let%expect_test "HTML pretty print corner cases" =
  let open HTML in
  (* test empty tags don't break line *)
  let empty_tag = div [] [p [translate `yes] []] in
  empty_tag |> to_string |> print_endline;
  [%expect {|
    <div>
      <p translate="yes"></p>
    </div>
    |}];
  (* test null tag spacing *)
  let null_tag = div [] [null [p [translate `yes] []]] in
  null_tag |> to_string |> print_endline;
  [%expect {|
    <div>
      <p translate="yes"></p>
    </div>
    |}];
  (* test children containing text is not broken *)
  let children_with_text =
    div []
      [ p []
          [ b [] [txt "Hello,"];
            txt " World.";
            br [];
            txt "This text should not be on the next line." ] ]
  in
  children_with_text |> to_string |> print_endline;
  [%expect
    {|
    <div>
      <p><b>Hello,</b> World.<br>This text should not be on the next line.</p>
    </div>
    |}];
  (* text combining text with (possibly nested) null *)
  let null_combining_text =
    let open HTML in
    div []
      [ comment "this is a comment";
        p []
          [ null [txt "Hello,"];
            txt " World.";
            null [br []; txt "This text should not be on the next line."] ] ]
  in
  null_combining_text |> to_string |> print_endline;
  [%expect
    {|
    <div>
      <!-- this is a comment -->
      <p>Hello, World.<br>This text should not be on the next line.</p>
    </div>
    |}]

let%expect_test "SVG" =
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
  svg_node |> to_xml ~header:true |> print_endline;
  [%expect
    {|
    <?xml version="1.0" encoding="UTF-8"?>
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewbox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 10.5L12 3m0 0l7.5 7.5M12 3v18" />
    </svg>
    |}]
