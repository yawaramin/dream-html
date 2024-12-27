# Todo App with dream-html, htmx, and PicoCSS

![Demo todo app built with dream-html and
htmx](https://pbs.twimg.com/media/GGvsiMdWoAA5W3t?format=jpg&name=4096x4096)

Run with: `make app` (macOS)

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
modules (we are cheating a bit by defining the path templates for all resources
that are meaningful in our app, eg `/todos/%s` to represent a specific todo
item).

Each module has very similar components. At a high level:

```ocaml
module Page = struct
  let render ... outlet = ...
  let get = Dream_html.get Path.page (fun req -> ...)
end

module Todos = struct
  let render ... outlet = ...
  let get = ...
  let post = ...
end

module Todo = struct
  let render ... = ...
  let get = ...
  let post = ...
end
```

And the router is just made by listing all the routes from the modules:

```ocaml
router [
  Page.get;
  Todos.get;
  Todos.post;
  Todo.get;
  Todo.post;
]
```

Notice that the component modules are fairly uniform. They define their views,
and the GET and POST (optional) request handlers needed for interactivity. This
is quite similar to Remix's app architecture (though I think simpler and more
flexible since we don't have to rely on file-based routing and we don't need to
load a separate script and data resource for each view, htmx loads them both in
a single call).

## Path attributes

As mentioned earlier, we define all meaningful resources in the app as
dream-html 'paths', which are type-safe objects that can parse and print URL
parameters:

```ocaml
module Path = struct
  let%path page = "/"
  let%path todos = "/todos"
  let%path todo = "/todos/%d"
end
```

Having these paths consolidated in a single module gives us a high-level
overview of all the paths in our app and makes it easy to refactor them. These
paths are used to both parse and extract path parameters, and _also_ to print
them back as HTML attributes, eg:

```ocaml
a [path_attr href Path.todo todo_id] [...]
```

Now, no paths nor assumptions about the paths are hard-coded in the views, making
it a breeze to refactor all the paths in one place.

## Progressive enhancement with htmx

By the way, the app works fine without JavaScript. All route handlers are
designed to check whether the requests are coming from htmx or not, and render
partial or full pages correspondingly. Because inner (more nested) views are in
modules defined later, it's simple for them to render a full page by calling the
render functions of progressively higher (outer) views:

```ocaml
let get = Dream_html.get Routes.todo (fun req id ->
  let todo = Repo.find id in
  let rendered = render ~todo in
  vary req
    ~fragment:(fun () -> respond (null [rendered; Page.title_tag todo.desc]))
    (fun () ->
      respond
        (Page.render ~title_str:todo.desc
            (Todos.render ~todos:(Repo.list ()) rendered))))
```

The `vary` function selects the correct HTML to respond with depending on whether
a partial or a full page is required. It also sets the correct `Vary` response
header so that browsers that locally cache responses will do so correctly.
