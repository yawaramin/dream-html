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

This is a set of helper functions I am using to generate HTML markup from inside
my [Dream](https://aantron.github.io/dream) backend. It works pretty well but is
incomplete (there are a lot of attributes and tags in HTML). PRs welcome to add
more!

Caveat: this is very alpha software. I am planning to use it on a side project.
You can use it if you want but a lot of things are still missing.

## Why

Having tried TyXML, I found that too complex. Dream's built-in eml (Embedded ML)
templating system has a few disadvantages, e.g. no editor support, somewhat
quirky syntax that can be hard to debug when it starts erroring, and a rather
large limitation that you need to manually set up a conversion rule in your `dune`
file for each separate template file.

Dream-html is most similar in approach to Daniel Buenzli's
[Webs](https://erratique.ch/software/webs/doc/Webs_html/index.html) HTML library
(in OCaml land, in other languages many people have published similar code-first
approach libraries). The philosophy is to do some minimal type checking and not
dive deep into a typed HTML rabbit hole like TyXML.

Let's compare how the following HTML would look in either of Webs or dream-html:

```html
<p class="text-lg" id="hello">Hello, World!</p>
```

Webs:

```ocaml
open Webs_html
open El
open At

let greeting = p ~at:[class' "text-lg"; id "hello"] [txt "Hello, World!"]
```

Dream-html:

```ocaml
open Dream_html
open Tag
open Attr

let greeting = p[class_"text-lg"; id"hello"][txt"Hello, World!"]
```

Note, this is not meant to be a demonstration of how many characters you're
saving. It's just a different style which I have found we can take advantage of
thanks to OCaml being whitespace-insensitive. Normally you wouldn't format OCaml
code like this, but I feel that the domain justifies it.

## Details

Attribute and text values are escaped using
[`Dream.html_escape`](https://aantron.github.io/dream/#val-html_escape):

```
utop # open Dream_html;;
utop # let user_input = "<script>alert('You have been pwned')</script>";;
utop # open Tag;;
utop # let safe = p[][txt user_input];;
utop # to_string safe;;
- : string =
"<p>&lt;script&gt;alert(&#x27;You have been pwned&#x27;)&lt;/script&gt;</p>"
```

A convenience is provided to respond with an HTML node from a handler:

```ocaml
Dream_html.respond greeting
```

You can compose multiple HTML nodes together into a single node without an extra
DOM node, like [React fragments](https://react.dev/reference/react/Fragment):

```ocaml
let view = Tag.null[
  p[][txt"Hello"];
  p[][txt"World"]]
```

You can conditionally render an attribute, and
[void elements](https://developer.mozilla.org/en-US/docs/Glossary/Void_element)
are statically enforced as childless:

```ocaml
let entry = input[
  if should_focus then autofocus else Attr.null;
  id"email";
  name"email";
  value"Email address"]
```

You can also embed HTML comments in the generated document:

```ocaml
div[][
  comment"TODO: xyz.";
  p[][txt"Hello!"]]
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
)
Implementation inspired by both elm-html and
[Scalatags](https://com-lihaoyi.github.io/scalatags/).
