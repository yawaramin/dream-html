module SM = Map.Make (String)

type handler = Piaf.Request.t -> Piaf.Response.t
type route = Route : Piaf.Method.t * (_, _) Path.t * handler -> route

type methods =
  { get : handler option;
    post : handler option;
    put : handler option;
    delete : handler option;
    patch : handler option;
    options : handler option;
    head : handler option;
    trace : handler option;
    connect : handler option
  }

let methods ?get ?post ?put ?delete ?patch ?options ?head ?trace ?connect () =
  { get; post; put; delete; patch; options; head; trace; connect }

let methods_add meth handler m =
  match meth with
  | `GET -> { m with get = Some handler }
  | `POST -> { m with post = Some handler }
  | `PUT -> { m with put = Some handler }
  | `DELETE -> { m with delete = Some handler }
  | `Other "PATCH" -> { m with patch = Some handler }
  | `OPTIONS -> { m with options = Some handler }
  | `HEAD -> { m with head = Some handler }
  | `TRACE -> { m with trace = Some handler }
  | `CONNECT -> { m with connect = Some handler }
  | _ -> failwith "unknown HTTP method"

type handlers =
  | Any of handler
  | Methods of methods

let handlers_new meth handler =
  match meth with
  | `Other "ANY" -> Any handler
  | _ -> Methods (methods_add meth handler (methods ()))

let handlers_add meth handler = function
  | Any _ -> failwith "cannot add a handler when 'any' handler is set"
  | Methods m -> Methods (methods_add meth handler m)

let ( or ) opt1 opt2 =
  match opt1 with
  | Some _ -> opt1
  | None -> opt2

let or_empty some = function
  | Some _ -> some
  | None -> ""

let handlers_find ~not_allowed meth = function
  | Any handler -> handler
  | Methods m -> (
    match meth, m with
    | `GET, { get = Some h; _ }
    | `POST, { post = Some h; _ }
    | `PUT, { put = Some h; _ }
    | `DELETE, { delete = Some h; _ }
    | `Other "PATCH", { patch = Some h; _ }
    | `OPTIONS, { options = Some h; _ }
    | `HEAD, { head = Some h; _ }
    | `TRACE, { trace = Some h; _ }
    | `CONNECT, { connect = Some h; _ } -> h
    | `HEAD, { get = Some h; _ } ->
      fun req ->
        let rep = h req in
        Response.empty ~headers:(Response.headers rep)
          (Piaf.Response.status rep)
    | `OPTIONS, _ ->
      let allow =
        Printf.sprintf "OPTIONS%s%s%s%s%s%s%s%s" (or_empty ", GET" m.get)
          (or_empty ", POST" m.post) (or_empty ", PUT" m.put)
          (or_empty ", DELETE" m.delete)
          (or_empty ", PATCH" m.patch)
          (or_empty ", HEAD" (m.head or m.get))
          (or_empty ", TRACE" m.trace)
          (or_empty ", CONNECT" m.connect)
      in
      fun _ -> Response.empty ~headers:["Allow", allow] `OK
    | _ -> not_allowed)

type segment =
  { names : t SM.t;
    handlers : handlers option
  }

and t =
  | Segment of segment
  | Rest of handlers

let get path handler = Route (`GET, path, Path.handler path.Path.rfmt handler)
let post path handler = Route (`POST, path, Path.handler path.Path.rfmt handler)
let put path handler = Route (`PUT, path, Path.handler path.Path.rfmt handler)

let delete path handler =
  Route (`DELETE, path, Path.handler path.Path.rfmt handler)

let patch path handler =
  Route (`Other "PATCH", path, Path.handler path.Path.rfmt handler)

let options path handler =
  Route (`OPTIONS, path, Path.handler path.Path.rfmt handler)

let head path handler = Route (`HEAD, path, Path.handler path.Path.rfmt handler)

let trace path handler =
  Route (`TRACE, path, Path.handler path.Path.rfmt handler)

let connect path handler =
  Route (`CONNECT, path, Path.handler path.Path.rfmt handler)

let any path handler =
  Route (`Other "ANY", path, Path.handler path.Path.rfmt handler)

let root = Segment { handlers = None; names = SM.empty }
let fail_rest () = failwith "rest parameter must be last segment of path"

(* If a static segment needs to start with the literal '%' character, escape it
   by using '%%'. *)
let remove_pct str =
  let len = String.length str in
  if len >= 2 && str.[0] = '%' && str.[1] = '%' then
    String.sub str 1 (len - 1)
  else
    str

(* We are guaranteed to not have this be a valid segment name *)
let param_name = "/"

let rec router_add path_segments meth handler router =
  match path_segments with
  | [""] | [""; ""] ->
    Segment { handlers = Some (handlers_new meth handler); names = SM.empty }
  | "" :: path_segments -> router_add path_segments meth handler router
  | ["%*s"] -> Rest (handlers_new meth handler)
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
    | Segment s -> (
      match SM.find_opt param_name s.names with
      | Some _ -> failwith "duplicate parameter segment"
      | None ->
        Segment
          { s with
            names =
              SM.add param_name
                (router_add path_segments meth handler router)
                s.names
          }))
  | static :: path_segments -> (
    let static = remove_pct static in
    match router with
    | Rest _ -> fail_rest ()
    | Segment s ->
      let static_router = router_add path_segments meth handler router in
      Segment { s with names = SM.add static static_router s.names })
  | [] -> (
    match router with
    | Rest _ -> router
    | Segment ({ handlers = None; _ } as s) ->
      Segment { s with handlers = Some (handlers_new meth handler) }
    | Segment ({ handlers = Some h; _ } as s) ->
      Segment { s with handlers = Some (handlers_add meth handler h) })

let rec router_find ~not_allowed ~not_found meth path_segments router =
  match path_segments, router with
  | _, Rest handlers -> handlers_find ~not_allowed meth handlers
  | path_segment :: path_segments, Segment s -> (
    match SM.find_opt path_segment s.names with
    | Some router ->
      router_find ~not_allowed ~not_found meth path_segments router
    | None -> (
      match SM.find_opt param_name s.names with
      | Some router ->
        router_find ~not_allowed ~not_found meth path_segments router
      | None -> not_found))
  | [], Segment { handlers = Some h; _ } -> handlers_find ~not_allowed meth h
  | [], Segment { handlers = None; _ } -> not_found

let router ?(not_found = fun _ -> Response.empty `Not_found)
    ?(not_allowed = fun _ -> Response.empty `Method_not_allowed) routes =
  let router =
    routes
    |> ListLabels.fold_left ~init:root
         ~f:(fun router (Route (meth, path, handler)) ->
           router_add
             (path.Path.rfmt |> string_of_format |> String.split_on_char '/')
             meth handler router)
  in
  fun req ->
    router_find ~not_allowed ~not_found (Piaf.Request.meth req)
      (req |> Piaf.Request.target |> String.split_on_char '/')
      router req
