type t =
  { id : int;
    desc : string;
    completed : bool
  }

let dir = "todos"
let dir_todo id = Filename.concat dir (string_of_int id)

let () =
  if not (Sys.file_exists dir && Sys.is_directory dir) then Sys.mkdir dir 0o755

let parse filename =
  In_channel.with_open_bin filename (fun inc ->
      Scanf.bscanf (Scanf.Scanning.from_channel inc) "%d %B %s"
        (fun id completed desc ->
          { id; completed; desc = Dream.from_percent_encoded desc }))

let list () =
  let todos = Sys.readdir dir in
  Array.sort compare todos;
  todos
  |> Array.to_list
  |> List.map (fun todo -> parse (Filename.concat dir todo))

let key ?id () =
  try
    let st =
      Unix.stat
        (match id with
        | Some i -> dir_todo i
        | None -> dir)
    in
    `Weak (string_of_float st.st_mtime)
  with Unix.Unix_error (ENOENT, _, _) -> `None

let find id = parse (dir_todo id)

let write ({ id; completed; desc } as todo) =
  let tmpname = Filename.temp_file ~temp_dir:dir (string_of_int id) "" in
  Out_channel.with_open_bin tmpname (fun outc ->
      Printf.fprintf outc "%d %B %s" id completed
        (Dream.to_percent_encoded desc));
  Sys.rename tmpname (dir_todo id);
  todo

let add desc =
  let all = Sys.readdir dir in
  let id =
    if all = [||] then
      1
    else (
      Array.sort (fun name1 name2 -> compare name2 name1) all;
      1 + int_of_string all.(0))
  in
  write { id; desc; completed = false }

let toggle id =
  let todo = find id in
  write { todo with completed = not todo.completed }

let edit id desc =
  let todo = find id in
  write { todo with desc }
