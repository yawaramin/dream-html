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

let node = html[lang"en"][
  head[][
    Tag.title[][txt"Dream_html Test"]];
  body[id"test-content"][
    main[][
      article[id"article-1"; class_"story"][
        p[][txt"Test para 1."];
        p[][txt"Test para 2."]];
      Tag.null[
        comment"embedded HTML comment";
        hr[if true then class_"super" else null];
        hr[if false then autofocus else null]]]]]

let () = node |> to_string |> print_endline
