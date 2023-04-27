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
open Tag
open Attr

let greet name = p[id "greet-%s" name][txt "Hello, %s!" name]

let node = html[lang "en"][
  head[][
    Tag.title[] "Dream_html Test"];
  body[id "test-content"][
    main[spellcheck true][
      article[id "article-1"; class_ "story"][
        p[Hx.get "/p1"][txt "Test para 1."];
        p[][txt "Test para 2."]];
      input[type_ "text"; onblur "if (1 > 0) alert(this.value)"];
      Tag.null[
        comment "oops --><script>alert('lol')</script>";
        textarea[
          required;
          Hx.trigger "keyup[target.value.trim() != '']";
          autocapitalize `words]
          "super";
        hr[if true then class_ "super" else null];
        greet "Bob"]]]]

let () = node |> to_string |> print_endline
