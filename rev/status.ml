let to_reason s =
  match (s :> Piaf.Status.t) with
  | #Piaf.Status.standard -> Some (Piaf.Status.default_reason_phrase s)
  | _ -> None
