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

    This provides a convenient way to create route paths and reuse them
    throughout your app. The way it works is by just duplicating the format
    string literal argument. However, this naturally means that both the route
    parser and attribute printer format strings are identical. If you need
    different formatting for the two, you can use the underlying
    [Dream_html.Path.make] function.

    @since v3.9.0 *)
