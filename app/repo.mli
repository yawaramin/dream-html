type t =
  { id : int;
    desc : string;
    completed : bool
  }

val list : unit -> t list
val find : string -> t
val add : string -> t
val toggle : string -> t
val edit : string -> string -> t
