type t =
  { id : int;
    desc : string;
    completed : bool
  }

val list : unit -> t list
val find : int -> t
val add : string -> t
val toggle : int -> t
val edit : int -> string -> t