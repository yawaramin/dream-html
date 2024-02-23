let ( / ) = Filename.concat

(* Add an out of band swap attribute to any node *)
let oob node =
  let open Dream_html in
  ignore node.@["id"];
  node +@ Hx.swap_oob "true"

(* Check for htmx request *)
let is_htmx req =
  match Dream.header req "HX-Request" with
  | Some _ -> true
  | None -> false

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

module Page = struct
  let htmx = "https://unpkg.com/htmx.org@2.0.0-alpha2/dist/htmx.min.js"
  let path = "/"

  open Dream_html
  open HTML

  (* Helper to build a title prefixed with the name of the app. *)
  let titl str = title [] "todos · %s" str
  let toast_id = "toast"
  let toast msg = span [id "%s" toast_id; Aria.live `polite] [txt "%s" msg]

  let render titl_str outlet =
    html
      [lang "en"]
      [ head []
          [ titl titl_str;
            link
              [ rel "stylesheet";
                href
                  "https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"
              ];
            style []
              {|#%s {
  display:none;
  position:fixed;
  bottom:1rem;
  right:1rem;
  transition:display;
  duration:5s;
  padding:1rem;
  border-radius:var(--pico-border-radius);
}

#%s.htmx-added {
  display:block;
  background-color:#E9F2FC;
}

#%s.error {
  display:block;
  background-color:#FFBF00;
}

body {
  padding:1rem;
}
|}
              toast_id toast_id toast_id;
            meta [charset "UTF-8"];
            meta
              [name "viewport"; content "width=device-width, initial-scale=1.0"]
          ];
        body []
          [ outlet;
            toast "";
            script [src "%s" htmx] "";
            script []
              {|document.addEventListener('htmx:responseError', evt => {
  document.getElementById('%s').outerHTML = `<span id="%s" class="error">${evt.detail.xhr.responseText}</span>`;
});|}
              toast_id toast_id ] ]

  let get req = Dream.redirect req "/todos"
end

module Todos = struct
  open Dream_html
  open HTML

  let path = "todos"
  let todo = "todo"

  let render_one trgt { Repo.id = idval; desc; completed } =
    let trgt = trgt / string_of_int idval in
    let msg = txt "%s" desc in
    let msg = if completed then s [] [msg] else msg in
    a
      [ id "todos-%d" idval;
        style_ "text-decoration:none";
        href "%s" trgt;
        Hx.get "%s" trgt;
        Hx.target "#%s" todo;
        Hx.push_url "%s" trgt ]
      [article [] [msg; footer [] [txt "#%d" idval]]]

  let todolist = "todos"

  let render todos trgt outlet =
    null
      [ header []
          [ a
              [href "%s" trgt; style_ "text-decoration:none"]
              [hgroup [] [h1 [] [txt "todos"]; p [] [txt "get stuff done."]]] ];
        main
          [class_ "grid"]
          [ div []
              [ form
                  [ method_ `POST;
                    action "%s" trgt;
                    Hx.post "%s" trgt;
                    Hx.swap "afterbegin settle:5s";
                    Hx.target "#%s" todolist ]
                  [ label []
                      [ txt "new:";
                        fieldset
                          [role `group]
                          [ input [name "desc"; autofocus];
                            input [type_ "submit"; value "add"] ] ] ];
                div [id "%s" todolist] (List.map (render_one trgt) todos) ];
            div [id "%s" todo] [outlet] ] ]

  let get req =
    []
    |> null
    |> render (Repo.list ()) (Dream.target req)
    |> Page.render "all"
    |> respond

  let post req =
    let open Lwt.Syntax in
    let* frm = Dream.form ~csrf:false req in
    match frm with
    | `Ok [("desc", "")] -> invalid_arg "need todo description"
    | `Ok [("desc", desc)] ->
      let todo = Repo.add desc in
      let trgt = Dream.target req in
      if is_htmx req then
        respond ~status:`Created
          (null [render_one trgt todo; oob (Page.toast "added todo")])
      else
        todo.id |> string_of_int |> Filename.concat trgt |> Dream.redirect req
    | _ -> invalid_arg "could not add todo"
end

module Todo = struct
  open Dream_html
  open HTML

  let path = ":id"
  let id_param = "id"

  let complete_btn todo =
    let completion =
      if todo.Repo.completed then "un-complete" else "complete"
    in
    input [id "todo-complete"; type_ "submit"; value "%s" completion]

  let todo_desc = "todo-desc"

  let render todo trgt =
    let input_id =
      input [type_ "hidden"; name "%s" id_param; value "%d" todo.Repo.id]
    in
    div
      [style_ "position:sticky;top:0"]
      [ form
          [ method_ `POST;
            action "%s" trgt;
            Hx.post "%s" trgt;
            Hx.swap "outerHTML settle:5s";
            Hx.target "#todos-%d" todo.id;
            style_ "display:inline" ]
          [ input_id;
            label [for_ "%s" todo_desc] [txt "#%d:" todo.id];
            fieldset
              [role `group]
              [ input [id "%s" todo_desc; name "desc"; value "%s" todo.desc];
                input [type_ "submit"; value "update"] ] ];
        form
          [ method_ `POST;
            action "%s" trgt;
            Hx.post "%s" trgt;
            Hx.swap "outerHTML settle:5s";
            Hx.target "#todos-%d" todo.id;
            style_ "display:inline" ]
          [input_id; complete_btn todo] ]

  let render_toggled trgt todo =
    let msg = if todo.Repo.completed then "completed" else "un-completed" in
    null
      [ Todos.render_one (Filename.dirname trgt) todo;
        oob (complete_btn todo);
        oob (Page.toast msg) ]

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

  let post req =
    let trgt = Dream.target req in
    let open Lwt.Syntax in
    let* frm = Dream.form ~csrf:false req in
    match frm with
    | `Ok [("desc", desc); ("id", idval)] ->
      let todo = Repo.edit idval desc in
      if is_htmx req then
        respond
          (null
             [ Todos.render_one (Filename.dirname trgt) todo;
               Page.titl desc;
               oob (Page.toast "updated description") ])
      else
        Dream.redirect req trgt
    | `Ok [("id", idval)] ->
      let todo = Repo.toggle idval in
      if is_htmx req then
        respond (render_toggled trgt todo)
      else
        Dream.redirect req trgt
    | _ -> invalid_arg "There was an error"
end

open Dream

let () =
  run
  @@ logger
  @@ dreamcatcher
  @@ router
       [ get Page.path Page.get;
         get (Page.path / Todos.path) Todos.get;
         post (Page.path / Todos.path) Todos.post;
         get (Page.path / Todos.path / Todo.path) Todo.get;
         post (Page.path / Todos.path / Todo.path) Todo.post ]
