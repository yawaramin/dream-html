## dream-html - generate HTML markup from your Dream backend server

Copyright 2023 Yawar Amin

This file is part of dream-html.

dream-html is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

dream-html is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
dream-html. If not, see <https://www.gnu.org/licenses/>.

## What

An HTML library that is closely integrated with
[Dream](https://aantron.github.io/dream). Most HTML elements and attributes from
the
[Mozilla Developer Network references](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference)
are now implemented. I have deliberately left out almost all non-standard or
deprecated tags/attributes. Also, supporting CSS is out of scope for this library.
However, I have included the [htmx](https://htmx.org/) attributes as I am
personally using them.

## Why

- TyXML is a bit too complex.
- Dream's built-in eml (Embedded ML) has some drawbacks like no editor support,
  quirky syntax that can be hard to debug, and manual dune rule setup for each
  view file. Also in general string-based HTML templating is
  [suboptimal](https://www.devever.net/~hl/stringtemplates).
- Daniel Buenzli's `Webs_html` is most similar but I wanted to fine-tune a few
  things and take advantage of close Dream integration.

## First look

```ocaml
let page req =
  let open Dream_html in
  let open HTML in
  html [lang "en"] [
    head [] [
      title [] "Dream-html" ];
    body [] [
      h1 [] [txt "Dream-html"];
      p [] [txt "Is cool!"];
      form [method_ `POST; action "/feedback"] [
        (* Integrated with Dream's CSRF token generation *)
        csrf_tag req;

        label [for_ "what-you-think"] [txt "Tell us what you think!"];
        input [name "what-you-think"; id "what-you-think"];
        input [type_ "submit"; value "Send"] ] ] ]

(* Integrated with Dream response *)
let handler req = Dream_html.respond (page req)
```

## Details

Attribute and text values are escaped using
[`Dream.html_escape`](https://aantron.github.io/dream/#val-html_escape):

```
utop # open Dream_html;;
utop # let user_input = "<script>alert('You have been pwned')</script>";;
utop # open HTML;;
utop # let safe = p [] [txt "%s" user_input];;
utop # to_string safe;;
- : string =
"<p>&lt;script&gt;alert(&#x27;You have been pwned&#x27;)&lt;/script&gt;</p>"
```

## How to install

```
opam install dream-html
```

## Usage

A convenience is provided to respond with an HTML node from a handler:

```ocaml
Dream_html.respond greeting
```

You can compose multiple HTML nodes together into a single node without an extra
DOM node, like [React fragments](https://react.dev/reference/react/Fragment):

```ocaml
let view = null [p [] [txt "Hello"]; p [] [txt "World"]]
```

You can do string interpolation using the `txt` node constructor and of any
attribute which takes a string value:

```ocaml
let greet name = p [id "greet-%s" name] [txt "Hello, %s!" name]
```

You can conditionally render an attribute, and
[void elements](https://developer.mozilla.org/en-US/docs/Glossary/Void_element)
are statically enforced as childless:

```ocaml
let entry =
  input
    [ (if should_focus then autofocus else null_);
      id "email";
      name "email";
      value "Email address" ]
```

You can also embed HTML comments in the generated document:

```ocaml
div [] [comment "TODO: xyz."; p [] [txt "Hello!"]]
```

## Explore in the REPL

```
$ utop
utop # #require "dream-html";;
utop # open Dream_html;;
utop # open HTML;;
utop # #install_printer pp;;
utop # p [class_ "hello"] [txt "world"];;
- : node = <p class="hello">world</p>
```

## Test

Run the test and print out diff if it fails:

    dune runtest # Will also exit 1 on failure

Set the new version of the output as correct:

    dune promote

## Prior art/design notes

Surface design obviously lifted straight from
[elm-html](https://package.elm-lang.org/packages/elm/html/latest/).

Similar to [Webs](https://erratique.ch/software/webs/doc/Webs_html/index.html) as
mentioned earlier (it turns out there are only a limited number of ways to do
this kind of library).

Implementation inspired by both elm-html and
[Scalatags](https://com-lihaoyi.github.io/scalatags/).
