let headers' = Option.map Piaf.Headers.of_list

let status' status code =
  match status, code with
  | Some s, _ -> s
  | None, Some c -> Piaf.Status.of_code c
  | None, None -> `OK

let headers rep = rep |> Piaf.Response.headers |> Piaf.Headers.to_list

let empty ?headers status =
  Piaf.Response.create ?headers:(headers' headers) status

let string ?status ?code ?headers s =
  Piaf.Response.create ?headers:(headers' headers) ~body:(Piaf.Body.of_string s)
    (status' status code)
