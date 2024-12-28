(* Add an out of band swap attribute to any node *)
let oob node =
  let open Dream_html in
  ignore node.@["id"];
  node +@ Hx.swap_oob "true"

let hx_request = "Hx-Request"
let hx_history_request_request = "Hx-History-Restore-Request"

(* Check for htmx request *)
let is_htmx req =
  Dream.has_header req hx_request
  && not (Dream.has_header req hx_history_request_request)

let vary ~if_fragment ~if_full req =
  let open Lwt.Syntax in
  let+ resp = if is_htmx req then if_fragment () else if_full () in
  Dream.set_header resp "Vary" (hx_request ^ ", " ^ hx_history_request_request);
  resp

(* Middleware to handle errors *)
let dreamcatcher next req =
  Lwt.catch
    (fun () -> next req)
    begin
      fun exn ->
        let status, msg =
          match exn with
          | Not_found -> `Not_Found, "not found"
          | Failure msg | Assert_failure (msg, _, _) -> `Bad_Request, msg
          | Invalid_argument msg -> `Status 422, msg
          | _ -> `Internal_Server_Error, "something went wrong"
        in
        Dream.error (fun log -> log "%s" @@ Printexc.to_string exn);
        Dream.respond ~status msg
    end

module Path = struct
  let%path page = "/"
  let%path todos = "/todos"
  let%path todo = "/todos/%d"
end

module Page = struct
  open Dream_html
  open HTML

  (* Helper to build a title prefixed with the name of the app. *)
  let title_tag str = title [] "todos · %s" str
  let toast_id = "toast"
  let toast msg = span [id "%s" toast_id; Aria.live `polite] [txt "%s" msg]
  let get = get Path.page (fun req -> Dream.redirect req "/todos")

  (* outlet should be a <main> element *)
  let render ~title_str child =
    html
      [lang "en"]
      [ head []
          [ Livereload.script;
            title_tag title_str;
            link
              [ rel "stylesheet";
                href
                  "https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"
              ];
            link [rel "stylesheet"; path_attr href Static.Assets.app_css];
            meta [charset "UTF-8"];
            meta
              [name "viewport"; content "width=device-width, initial-scale=1.0"]
          ];
        body []
          [ header []
              [ a
                  [path_attr href Path.page; style_ "text-decoration:none"]
                  [hgroup [] [h1 [] [txt "todos"]; p [] [txt "get stuff done"]]]
              ];
            child;
            footer []
              [ toast "";
                script [path_attr src Static.Assets.htmx_js] "";
                script [path_attr src Static.Assets.app_js] "" ] ] ]
end

module Todos = struct
  open Dream_html
  open HTML

  let todo = "todo"

  let render_one { Repo.id = todo_id; desc; completed } =
    let msg = txt "%s" desc in
    let msg = if completed then s [] [msg] else msg in
    a
      [ id "todos-%d" todo_id;
        style_ "text-decoration:none";
        path_attr href Path.todo todo_id;
        path_attr Hx.get Path.todo todo_id;
        Hx.target "#%s" todo;
        Hx.push_url "true" ]
      [article [] [msg; footer [] [txt "#%d" todo_id]]]

  let todolist = "todos"

  let render ~todos child =
    main
      [class_ "grid"]
      [ div []
          [ form
              [ method_ `POST;
                path_attr action Path.todos;
                path_attr Hx.post Path.todos;
                Hx.swap "afterbegin settle:5s";
                Hx.target "#%s" todolist ]
              [ label []
                  [ txt "new:";
                    fieldset
                      [role `group]
                      [ input [name "desc"; autofocus; required];
                        input [type_ "submit"; value "add"] ] ] ];
            div [id "%s" todolist] (List.map render_one todos) ];
        div [id "%s" todo] [child] ]

  let get =
    get Path.todos (fun _ ->
        []
        |> null
        |> render ~todos:(Repo.list ())
        |> Page.render ~title_str:"all"
        |> respond)

  let post =
    post Path.todos (fun req ->
        let open Lwt.Syntax in
        let* frm = Dream.form ~csrf:false req in
        match frm with
        | `Ok [("desc", "")] -> invalid_arg "need todo description"
        | `Ok [("desc", desc)] ->
          let todo = Repo.add desc in
          let trgt = Dream.target req in
          vary req
            ~if_fragment:(fun () ->
              respond ~status:`Created
                (null [render_one todo; oob (Page.toast "added todo")]))
            ~if_full:(fun () ->
              todo.id
              |> string_of_int
              |> Filename.concat trgt
              |> Dream.redirect req)
        | _ -> invalid_arg "could not add todo")
end

module Todo = struct
  open Dream_html
  open HTML

  let complete_btn todo =
    let completion =
      if todo.Repo.completed then "un-complete" else "complete"
    in
    input [id "todo-complete"; type_ "submit"; value "%s" completion]

  let todo_desc = "todo-desc"

  let render ~todo =
    let input_id = input [type_ "hidden"; name "id"; value "%d" todo.Repo.id] in
    div
      [style_ "position:sticky;top:0"]
      [ form
          [ method_ `POST;
            path_attr action Path.todo todo.id;
            path_attr Hx.post Path.todo todo.id;
            Hx.swap "outerHTML settle:5s";
            Hx.target "#todos-%d" todo.id;
            style_ "display:inline" ]
          [ input_id;
            label [for_ "%s" todo_desc] [txt "#%d:" todo.id];
            fieldset
              [role `group]
              [ input
                  [ id "%s" todo_desc;
                    name "desc";
                    value "%s" todo.desc;
                    required;
                    autofocus ];
                input [type_ "submit"; value "update"] ] ];
        form
          [ method_ `POST;
            path_attr action Path.todo todo.id;
            path_attr Hx.post Path.todo todo.id;
            Hx.swap "outerHTML settle:5s";
            Hx.target "#todos-%d" todo.id;
            style_ "display:inline" ]
          [input_id; complete_btn todo] ]

  let render_toggled todo =
    let msg = if todo.Repo.completed then "completed" else "un-completed" in
    null [Todos.render_one todo; oob (complete_btn todo); oob (Page.toast msg)]

  let get =
    get Path.todo (fun req id ->
        let todo = Repo.find id in
        let rendered = render ~todo in
        vary req
          ~if_fragment:(fun () ->
            respond (null [rendered; Page.title_tag todo.desc]))
          ~if_full:(fun () ->
            respond
              (Page.render ~title_str:todo.desc
                 (Todos.render ~todos:(Repo.list ()) rendered))))

  let post =
    post Path.todo (fun req _ ->
        let trgt = Dream.target req in
        let open Lwt.Syntax in
        let* frm = Dream.form ~csrf:false req in
        match frm with
        | `Ok [("desc", desc); ("id", idval)] ->
          let todo = Repo.edit idval desc in
          vary req
            ~if_fragment:(fun () ->
              respond
                (null
                   [ Todos.render_one todo;
                     Page.title_tag desc;
                     oob (Page.toast "updated description") ]))
            ~if_full:(fun () -> Dream.redirect req trgt)
        | `Ok [("id", idval)] ->
          let todo = Repo.toggle idval in
          vary req
            ~if_fragment:(fun () -> respond (render_toggled todo))
            ~if_full:(fun () -> Dream.redirect req trgt)
        | _ -> invalid_arg "There was an error")
end

let stop =
  let promise, resolve = Lwt.wait () in
  Sys.set_signal Sys.sigterm
    (Signal_handle (fun _ -> Lwt.wakeup_later resolve ()));
  promise

open Dream

let () =
  run ~stop
  @@ logger
  @@ dreamcatcher
  @@ router
       [ Dream_html.Livereload.route;
         Static.routes;
         Page.get;
         Todos.get;
         Todos.post;
         Todo.get;
         Todo.post ]
