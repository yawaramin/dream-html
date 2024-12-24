<p align="center">
  <a href="https://yawaramin.github.io/dream-html/dream-html/Dream_html/">API Reference</a>
</p>

## dream-html - build robust and maintainable OCaml Dream webapps

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

This project started as a simple HTML library; it has evolved into something more
over time. Here are the highlights:

- Closely integrated with the [Dream](https://aantron.github.io/dream/) web
  framework for OCaml
- Generate HTML using type-safe functions and values
- MathML and SVG support
- Support for htmx attributes
- Type-safe HTML form and query decoding
- Type-safe path parameter parsing and printing

> [!NOTE]
> If you're not using Dream, you can still use the HTML/SVG/MathML/htmx
> generation features using the `pure-html` package.

## First look

```ocaml
let greeting = [%path "/%s"]

let hello _request who =
  let open Dream_html in
  let open HTML in
  respond (
    html [lang "en"] [
      head [] [
        title [] "dream-html first look";
      ];
      body [] [
        h1 [] [txt "Hello, %s!" who];
        p [] [
          txt "This page is at: ";
          a [href (Path.link greeting) who] [txt "this URL"];
          txt ".";
        ];
      ];
    ]
  )

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream_html.get greeting hello;
  ]
```

<img width="343" alt="Screenshot 2024-12-23 at 23 55 33" src="https://github.com/user-attachments/assets/84cd1f1e-46c3-4fe1-aeb2-724542fc987c">

Rendered HTML:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>dream-html first look</title>
  </head>
  <body>
    <h1>Hello, me!</h1>
    <p>This page is at: <a href="/me">this URL</a>.</p>
  </body>
</html>
```

## Security (HTML escaping)

Attribute and text values are escaped using rules very similar to standards-
compliant web browsers:

```
utop # open Dream_html;;
utop # open HTML;;

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
opam install dream-html # or pure-html if you don't want the Dream integration
```

Alternatively, to install the latest commit that may not have been released yet,
you have two options. If you need _only_ the HTML generation:

```
opam pin add pure-html git+https://github.com/yawaramin/dream-html
```

If you _also_ need the Dream integration:

```
opam pin add pure-html git+https://github.com/yawaramin/dream-html
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

You can do string interpolation of text nodes using `txt` and any attribute which
takes a string value:

```ocaml
let greet name = p [id "greet-%s" name] [txt "Hello, %s!" name]
```

You can conditionally render an attribute, and
[void elements](https://developer.mozilla.org/en-US/docs/Glossary/Void_element)
are statically enforced as childless:

```ocaml
let entry =
  input [
    if should_focus then autofocus else null_;
    id "email";
    name "email";
    value "Email address";
  ]
```

You can also embed HTML comments in the generated document:

```ocaml
div [] [comment "TODO: xyz."; p [] [txt "Hello!"]]
(* <div><!-- TODO: xyz. -->Hello!</div> *)
```

You have precise control over whitespace in the rendered HTML; dream-html does
not insert any whitespace by itself–all whitespace must be inserted inside text
nodes explicitly:

```ocaml
p [] [txt "hello, "; txt "world!"];;
(* <p>hello, world!</p> *)
```

You can also conveniently hot-reload the webapp in the browser using the
`Dream_html.Livereload` module. See the API reference for details.

## Form validation

There is also a module with helpers for request form and query validation; see
[`Dream_html.Form`](https://yawaramin.github.io/dream-html/dream-html/Dream_html/Form/index.html)
for details. See also the convenience helpers `Dream_html.form` and
`Dream_html.query`.

## Type-safe path parameter parsing and printing

Type-safe wrappers for Dream routing functionality are provided; details are
shown in the
[`Dream_html`](https://yawaramin.github.io/dream-html/dream-html/Dream_html/#type-safe-routing) page.

See also the
[PPX](https://yawaramin.github.io/dream-html/dream-html/Ppx/index.html)
documentation for setup and usage instructions.

## Import HTML

One issue that you may come across is that the syntax of HTML is different from
the syntax of dream-html markup. To ease this problem, you may use the
translation webapp in the [landing page](https://yawaramin.github.io/dream-html/).

Note that the dream-html code is not formatted nicely, because the expectation is
that you will use ocamlformat to fix the formatting.

Also note that the translation done by this bookmarklet is on a best-effort
basis. Many web pages don't strictly conform to the rules of correct HTML
markup, so you will likely need to fix those issues for your build to work.

## Test

Run the test and print out diff if it fails:

    dune test # Will also exit 1 on failure

Set the new version of the output as correct:

    dune promote

## Prior art/design notes

Surface design obviously lifted straight from
[elm-html](https://package.elm-lang.org/packages/elm/html/latest/).

Implementation inspired by both elm-html and
[ScalaTags](https://com-lihaoyi.github.io/scalatags/).

Many languages and libraries have similar HTML embedded DSLs:

- [Phlex](https://www.phlex.fun/) - Ruby
- [Arbre](https://activeadmin.github.io/arbre/) - Ruby
- [hiccl](https://github.com/garlic0x1/hiccl) - Common Lisp
- [scribble-html-lib](https://docs.racket-lang.org/scribble-pp/html-html.html) -
  Racket
- [hiccup](https://github.com/weavejester/hiccup) - Clojure
- [std/htmlgen](https://nim-lang.org/docs/htmlgen.html) - Nim
- [Falco.Markup](https://github.com/pimbrouwers/Falco.Markup) - F#
- [htpy](https://htpy.dev/) - Python
- [HTML::Tiny](https://metacpan.org/pod/HTML::Tiny) - Perl
- [j2html](https://j2html.com/) - Java
- [Lucid](https://github.com/chrisdone/lucid) - Haskell

