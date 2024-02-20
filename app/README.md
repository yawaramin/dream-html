# Todo App with dream-html, htmx, and PicoCSS

![Demo todo app built with dream-html and
htmx](https://pbs.twimg.com/media/GGvsiMdWoAA5W3t?format=jpg&name=4096x4096)

This is an example dream-html webapp that shows a modular, composeable
architecture using htmx for interactivity and PicoCSS for styling.

The idea behind the architecture of this app comes from the Remix folks, who
attribute it to Ember.js:

> One of the foundational concepts in Remix's routing system is the use of
> nested routes, an approach that traces its roots back to Ember.js. With nested
> routes, segments of the URL are coupled to both data dependencies and the UI's
> component hierarchy. A URL like /sales/invoices/102000 not only reveals a
> clear path in the application but also delineates the relationships and
> dependencies for different components.

Source: https://remix.run/docs/en/main/discussion/routes

## Routes

The sample app you see here has four routes:

1. `GET /todos`: render all todos
2. `POST /todos`: add a todo
3. `GET /todos/:id`: render a single todo in the nested view
4. `POST /todos/:id`: update the todo in the nested view (either toggle its
   status or change its description)

The nesting comes from the fact that the `GET /todos` route renders a page
listing the todos, but a portion (half) of the page is reserved for what Remix
calls the 'outlet' ie the nested view that will be rendered once a todo is
selected.

## Nesting

Selecting a todo makes a call to eg `/todos/1`. htmx sends this call, gets an
HTML partial response, and plugs it into the outlet that was rendered before for
the `/todos` view. Thus we achieve (one level of) nesting. As you can imagine,
this nesting would work both above and below this level. Eg we could have
`/all/todos/1`, `/completed/todos/1`, `/incomplete/todos/1` above (if we had a
filtering feature in the app), or `/todos/1/people` (if we imagine a new feature
where we can tag multiple people in a todo).

## Targeting

One very convenient simplification that arises from this design is the fact that
we can always know what our routes are and we don't need to type them manually.
Eg, we render the `/todos` view in response to a `GET /todos` request. When we
are rendering the response, we have access to the request and can get its path,
which is obviously guaranteed to be `/todos`. So when we render an 'add a todo'
form, we don't need to manually type out the action: `form [action "/todos"]`.
We can instead just pass in the target: `form [action "%s" trgt]` where `let
trgt = Dream.target req`.

We make extensive use of the request target path to simplify the implementation
of the views and make them more flexible (eg will automatically work if they are
used elsewhere in the path hierarchy in the future, like `/incomplete/todos`).

## Modularization and composeability

The design also easily lends itself to composeability and modularization. Each
segment of a route naturally decomposes into a separate module. So we have
modules:

1. `Page` to represent the `/` route and view (which just redirects to `/todos`)
1. `Todos` to represent the `/todos` route and view
1. `Todo` to represent the `/todos/:id` route and view

The ordering of the modules is meaningful: they are in ascending order from
highest (outermost) level to lowest (innermost). Modules defined earlier can't
reference anything inside modules defined later, and similarly the views inside
the earlier modules mostly don't know anything about the views in the later
modules (we are cheating a bit by assuming that `/todos` and `/:id` are supposed
to be concatenated).

Each module has very similar components. At a high level:

```ocaml
module Page = struct
  let path = "/"
  let render ... outlet = ...
  let get req = ...
end

module Todos = struct
  let path = "todos"
  let render ... outlet = ...
  let get req = ...
  let post req = ...
end

module Todo = struct
  let path = ":id"
  let render ... = ...
  let get req = ...
  let post req = ...
end
```

And the router is just made by composing together the paths in the modules in
the correct order:

```ocaml
router [
  get Page.path Page.get;
  get (Page.path / Todos.path) Todos.get;
  post (Page.path / Todos.path) Todos.post;
  get (Page.path / Todos.path / Todo.path) Todo.get;
  post (Page.path / Todos.path / Todo.path) Todo.post;
]
```

(I redefined the `/` operator to do path concatenation in this app.)

Notice that the component modules are fairly uniform. They define their path
segment, how to render their views, and the GET and POST (optional) request
handlers needed for interactivity. This is quite similar to Remix's app
architecture (though I think simpler and more flexible since we don't have to
rely on file-based routing and we don't need to load a separate script and data
for each view, htmx loads them both in a single call).

By the way, the app works fine without JavaScript. All route handlers are
designed to check whether the requests are coming from htmx or not, and render
partial or full pages correspondingly. Because inner (more nested) views are in
modules defined later, it's simple for them to render a full page by calling the
render functions of progressively higher (outer) views:

```ocaml
let get req =
  let trgt = Dream.target req in
  let todo = Repo.find (Dream.param req id_param) in
  let rendered = render todo trgt in
  if is_htmx req then
    respond (null [rendered; Page.titl todo.desc])
  else
    respond
      (Page.render todo.desc
         (Todos.render (Repo.list ()) (Filename.dirname trgt) rendered))
```

Note that for htmx requests, we return an updated title as part of the response
fragment, but we don't explicitly mark it as an out-of-band swap. htmx has
special support for the `<title>` tag and will automatically swap it if found.
Of course, you can still do an OOB swap for the title if you want, but it's
redundant.

