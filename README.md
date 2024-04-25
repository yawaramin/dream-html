<p align="center">
  <a href="https://yawaramin.github.io/dream-html/dream-html/Dream_html/">API Reference</a>
</p>

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

An HTML, SVG, and MathML library that is closely integrated with
[Dream](https://aantron.github.io/dream). Most HTML elements and attributes from
the [Mozilla Developer Network
references](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference) are
included. Almost all non-standard or deprecated tags/attributes deliberately
omitted. CSS support is out of scope. [htmx](https://htmx.org/) attributes
supported out of the box.

## Why

- TyXML is a bit too complex.
- Dream's built-in eml (Embedded ML) has some drawbacks like no editor support,
  quirky syntax that can be hard to debug and refactor, and manual dune rule
  setup for each view file
- In general string-based HTML templating is
  [suboptimal](https://www.devever.net/~hl/stringtemplates) and mostly driven by
  [familiarity](https://github.com/tavisrudd/throw_out_your_templates).

## First look

```ocaml
let page req =
  let open Dream_html in
  let open HTML in
  (* automatically injects <!doctype html> *)
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

## Security (HTML escaping)

Attribute and text values are escaped using rules very similar to standards-
compliant web browsers:

```
utop # open Dream_html;;
utop # open HTML;;
utop # #install_printer pp;;

utop # let user_input = "<script>alert('You have been pwned')</script>";;
val user_input : string = "<script>alert('You have been pwned')</script>"

utop # p [] [txt "%s" user_input];;
- : node = <p>&lt;script&gt;alert('You have been pwned')&lt;/script&gt;</p>

utop # div [title_ {|"%s|} user_input] [];;
- : node = <div title="&quot;<script>alert('You have been pwned')</script>"></div>
```

## How to install

Make sure your local copy of the opam repository is up-to-date first:

```
opam update
opam install dream-html
```

Alternatively, to install the latest commit that may not have been released yet:

```
opam pin add dream-html git+https://github.com/yawaramin/dream-html
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

You can do string interpolation of text nodes using `txt` and of any
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
    [ if should_focus then autofocus else null_;
      id "email";
      name "email";
      value "Email address" ]
```

You can also embed HTML comments in the generated document:

```ocaml
div [] [comment "TODO: xyz."; p [] [txt "Hello!"]]
```

You can also conveniently hot-reload the webapp in the browser using the
`Dream_html.Livereload` module. See the API reference for details.

## Import HTML

One issue that you may come across is that the syntax of HTML is different from
the syntax of dream-html markup. To ease this problem, you may use the
bookmarklet `import_html.js` provided in this project. Simply create a new
bookmark in your browser with any name, and set the URL to the content of that
file (make sure it is exactly the given content).

Then, whenever you have a web page open, just click on the bookmarklet to copy
its markup to the clipboard in dream-html format. From there you can simple
paste it into your project.

Note that the dream-html version is not formatted nicely, because the
expectation is that you will use ocamlformat to fix the formatting.

Also note that the translation done by this bookmarklet is on a best-effort
basis. Many web pages don't strictly conform to the rules of correct HTML
markup, so you will likely need to fix those issues for your build to work.

## Test

Run the test and print out diff if it fails:

    dune runtest # Will also exit 1 on failure

Set the new version of the output as correct:

    dune promote

## Prior art/design notes

Surface design obviously lifted straight from
[elm-html](https://package.elm-lang.org/packages/elm/html/latest/).

Implementation inspired by both elm-html and
[Scalatags](https://com-lihaoyi.github.io/scalatags/).

Many languages and libraries have similar HTML embedded DSLs:

- [Phlex](https://www.phlex.fun/) - Ruby
- [hiccl](https://github.com/garlic0x1/hiccl) - Common Lisp
- [scribble-html-lib](https://docs.racket-lang.org/scribble-pp/html-html.html) -
  Racket
- [hiccup](https://github.com/weavejester/hiccup) - Clojure
- [std/htmlgen](https://nim-lang.org/docs/htmlgen.html) - Nim
- [Falco.Markup](https://github.com/pimbrouwers/Falco.Markup) - F#
- [htpy](https://htpy.dev/) - Python
- [Arbre](https://activeadmin.github.io/arbre/) - Ruby

