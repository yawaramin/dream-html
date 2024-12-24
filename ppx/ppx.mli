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

(** This PPX provides an extension point to create route paths.

    You can add it to your [dune] file in the usual way:
    [(preprocess (pps dream-html.ppx))].

    Then create a path: [let orders = [%path "/orders"]].

    And use it in a route: [Dream_html.get orders (fun req -> ...)].

    The PPX expands the above path to:

    {[let orders = Dream_html.path "/orders" "/orders"]}

    Ie, it just duplicates the path string to use as two separate format strings
    with different types for parsing and printing. If you need to actually have a
    different format string for printing (eg if you need to print the path with
    query parameters), you can use the underlying {!Dream_html.path} function
    directly: [path "/orders/%s" "/orders/%s?utm_src=%s&utm_campaign=%s"].

    The PPX also has the benefit that it checks that the path is well-formed at
    compile time. If you pass in an invalid path you get a compile error:

    {[
    File "example.ml", line 1, characters 10-23:
    1 | let bad = [%path "foo"]
                  ^^^^^^^^^^^^^
    Error: Invalid path: 'foo'. Paths must start with a '/' character
    ]}

    @since v3.9.0 *)
