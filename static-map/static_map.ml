let ( / ) = Filename.concat

let fname =
  String.map (function
    | ('A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_') as c -> c
    | _ -> '_')

let modname name =
  name
  |> String.capitalize_ascii
  |> String.map (function
       | '/' -> '.'
       | ('A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_') as c -> c
       | _ -> '_')

let modjoin modpath modname =
  match modpath with
  | "" -> modname
  | _ -> modpath ^ "." ^ modname

let paths = Hashtbl.create 10

let rec write_paths ?(nested = true) p ~path ~modpath filename =
  let fullname = path / filename in

  if Sys.is_directory fullname then (
    let filenames = Sys.readdir fullname in
    Array.sort compare filenames;

    let mname = modname (if nested then filename else path) in
    let modpath = modjoin modpath mname in
    if nested then (
      p "\n\nmodule ";
      p mname;
      p " = struct\n");
    Array.iter (write_paths ~nested:true p ~path:fullname ~modpath) filenames;
    if nested then p "\nend\n\n")
  else
    let fname = fname filename in
    p "let ";
    p fname;
    p {| = Dream_html.path "/|};
    p fullname;
    p {|" "/|};
    p fullname;
    p "?rev=";
    p (fullname |> Digest.file |> Digest.to_hex);
    p {|"|};
    Hashtbl.replace paths (modjoin modpath fname) fullname

let write_routes p =
  p "let routes = Dream_html.use [] [\n";
  paths
  |> Hashtbl.iter (fun path filename ->
         p "Dream_html.static_file ";
         p path;
         p {| "|};
         p filename;
         p {|";|};
         p "\n");
  p "]\n"

let () =
  let dirname = Sys.argv.(1) in
  Out_channel.with_open_bin (dirname ^ ".ml") (fun outc ->
      let p = Out_channel.output_string outc in
      write_paths ~nested:false p ~path:dirname ~modpath:"" "";
      write_routes p)
