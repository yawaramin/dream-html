module Static = Map.Make (String)

type handler = Piaf.Request.t -> Piaf.Response.t

type methods =
  { get : handler;
    post : handler;
    put : handler;
    delete : handler;
    patch : handler;
    options : handler;
    head : handler;
    trace : handler;
    connect : handler
  }

let methods_add meth handler m =
  match meth with
  | `GET -> { m with get = handler }
  | `POST -> { m with post = handler }
  | `PUT -> { m with put = handler }
  | `DELETE -> { m with delete = handler }
  | `Other "PATCH" -> { m with patch = handler }
  | `OPTIONS -> { m with options = handler }
  | `HEAD -> { m with head = handler }
  | `TRACE -> { m with trace = handler }
  | `CONNECT -> { m with connect = handler }
  | _ -> failwith "unknown HTTP method"

let methods_new ~not_allowed meth handler =
  let m =
    { get = not_allowed;
      post = not_allowed;
      put = not_allowed;
      delete = not_allowed;
      patch = not_allowed;
      options = not_allowed;
      head = not_allowed;
      trace = not_allowed;
      connect = not_allowed
    }
  in
  methods_add meth handler m

type handlers =
  | Any of handler
  | Methods of methods

let handlers_new ~not_allowed meth handler =
  match meth with
  | `ANY -> Any handler
  | _ -> Methods (methods_new ~not_allowed meth handler)

let handlers_add meth handler = function
  | Any _ -> failwith "cannot add a handler when 'any' handler is set"
  | Methods m -> Methods (methods_add meth handler m)

let handlers_find ~not_allowed meth h =
  match meth, h with
  | _, Any h -> h
  | `GET, Methods m -> m.get
  | `POST, Methods m -> m.post
  | `PUT, Methods m -> m.put
  | `DELETE, Methods m -> m.delete
  | `Other "PATCH", Methods m -> m.patch
  | `OPTIONS, Methods m -> m.options
  | `HEAD, Methods m -> m.head
  | `TRACE, Methods m -> m.trace
  | `CONNECT, Methods m -> m.connect
  | _ -> not_allowed

type segment =
  { handlers : handlers option;
    statics : t Static.t;
    param : t option
  }

and t =
  | Segment of segment
  | Rest of handlers

let get path handler = `GET, path, Path.handler path.Path.rfmt handler
let post path handler = `POST, path, Path.handler path.Path.rfmt handler
let put path handler = `PUT, path, Path.handler path.Path.rfmt handler
let delete path handler = `DELETE, path, Path.handler path.Path.rfmt handler

let patch path handler =
  `Other "PATCH", path, Path.handler path.Path.rfmt handler

let options path handler = `OPTIONS, path, Path.handler path.Path.rfmt handler
let head path handler = `HEAD, path, Path.handler path.Path.rfmt handler
let trace path handler = `TRACE, path, Path.handler path.Path.rfmt handler
let connect path handler = `CONNECT, path, Path.handler path.Path.rfmt handler
let any path handler = `ANY, path, Path.handler path.Path.rfmt handler
let root = Segment { handlers = None; statics = Static.empty; param = None }
let fail_rest () = failwith "rest parameter must be last segment of path"

let router ?(not_found = fun _ -> Response.empty `Not_found)
    ?(not_allowed = fun _ -> Response.empty `Method_not_allowed) routes =
  let rec add_route router path_segments meth handler =
    match path_segments with
    | [""] | [""; ""] ->
      Segment
        { handlers = Some (handlers_new ~not_allowed meth handler);
          statics = Static.empty;
          param = None
        }
    | "" :: path_segments -> add_route router path_segments meth handler
    | ["%*s"] -> Rest (handlers_new ~not_allowed meth handler)
    | "%*s" :: _ -> fail_rest ()
    | ( "%s"
      | "%c"
      | "%d"
      | "%i"
      | "%x"
      | "%X"
      | "%o"
      | "%ld"
      | "%Ld"
      | "%f"
      | "%B" )
      :: path_segments -> (
      match router with
      | Rest _ -> fail_rest ()
      | Segment { param = Some _; _ } -> failwith "duplicate parameter segment"
      | Segment ({ param = None; _ } as s) ->
        Segment
          { s with param = Some (add_route router path_segments meth handler) })
    | static :: path_segments -> (
      match router with
      | Rest _ -> fail_rest ()
      | Segment s ->
        let static_router = add_route router path_segments meth handler in
        Segment { s with statics = Static.add static static_router s.statics })
    | [] -> (
      match router with
      | Rest _ -> router
      | Segment ({ handlers = None; _ } as s) ->
        Segment
          { s with handlers = Some (handlers_new ~not_allowed meth handler) }
      | Segment ({ handlers = Some h; _ } as s) ->
        Segment { s with handlers = Some (handlers_add meth handler h) })
  in
  let router =
    routes
    |> ListLabels.fold_left ~init:root ~f:(fun router (meth, path, handler) ->
           add_route router
             (path.Path.rfmt |> string_of_format |> String.split_on_char '/')
             meth handler)
  in
  let rec find meth path_segments router =
    match path_segments, router with
    | _, Rest handlers -> handlers_find ~not_allowed meth handlers
    | path_segment :: path_segments, Segment { statics; param; handlers = _ }
      -> (
      match Static.find_opt path_segment statics with
      | Some router -> find meth path_segments router
      | None -> (
        match param with
        | Some router -> find meth path_segments router
        | None -> not_found))
    | [], Segment { handlers = Some h; _ } -> handlers_find ~not_allowed meth h
    | [], Segment { handlers = None; _ } -> not_found
  in
  fun req ->
    find (Piaf.Request.meth req)
      (req |> Piaf.Request.target |> String.split_on_char '/')
      router req
