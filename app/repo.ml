type t =
  { id : int;
    desc : string;
    completed : bool
  }

let hashtbl = Hashtbl.create ~random:true 8

let list () =
  hashtbl
  |> Hashtbl.to_seq_values
  |> List.of_seq
  |> List.sort (fun { id = id1; _ } { id = id2; _ } -> compare id1 id2)

let curr_id = ref 0
let find = Hashtbl.find hashtbl

let add desc =
  incr curr_id;
  let id = !curr_id in
  let todo = { id; desc; completed = false } in
  Hashtbl.replace hashtbl (string_of_int id) todo;
  todo

let toggle id =
  let todo = Hashtbl.find hashtbl id in
  let todo = { todo with completed = not todo.completed } in
  Hashtbl.replace hashtbl id todo;
  todo

let edit id desc =
  let todo = Hashtbl.find hashtbl id in
  let todo = { todo with desc } in
  Hashtbl.replace hashtbl id todo;
  todo
