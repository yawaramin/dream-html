(* Copyright 2024 Yawar Amin

   This file is part of dream-html.

   dream-html is free software: you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation, either version 3 of the License, or (at your option) any
   later version.

   dream-html is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
   details.

   You should have received a copy of the GNU General Public License along with
   dream-html. If not, see <https://www.gnu.org/licenses/>. *)

let spf = Printf.sprintf
let kspf = Printf.ksprintf
let static = "static"
let assets = "assets"

let fail msg =
  kspf prerr_endline "⚠️ %s" msg;
  exit 1

let filename_valname name =
  name
  |> String.uncapitalize_ascii
  |> String.map (function
       | ('A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_') as c -> c
       | _ -> '_')

let filename_modname name =
  name
  |> String.capitalize_ascii
  |> String.map (function
       | '/' -> '.'
       | ('A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_') as c -> c
       | _ -> '_')

let modjoin modpath modname =
  match modname with
  | "" -> modpath
  | _ -> spf "%s.%s" modpath modname

let paths = Hashtbl.create 10

let rec write_paths p ~path ~modpath filename =
  let fullname = Filename.concat path filename in

  if Sys.is_directory fullname then (
    match Sys.readdir fullname with
    | [||] -> ()
    | filenames ->
      Array.sort compare filenames;

      let mname = filename_modname filename in
      let modpath = modjoin modpath mname in

      p "\n\nmodule ";
      p (if mname = "" then modpath else mname);
      p " = struct\n";
      Array.iter (write_paths p ~path:fullname ~modpath) filenames;
      p "\nend\n\n")
  else
    let fname = filename_valname filename in

    p "let ";
    p fname;
    kspf p {| = Dream_html.path "/%s/|} static;
    p fullname;
    kspf p {|" "/%s/|} static;
    p fullname;
    p "?rev=";
    p (fullname |> Digest.file |> Digest.to_hex);
    p {|"|};
    p "\n";
    Hashtbl.replace paths (modjoin modpath fname) ()

let write_routes p =
  if Hashtbl.length paths = 0 then
    ()
  else (
    p "\n\nlet routes = Dream_html.use [] [\n";
    Hashtbl.iter
      (fun path () ->
        p "  Dream_html.static_asset ";
        p path;
        p ";\n")
      paths;
    p "]\n")

let usage =
  "USAGE:

dreamwork static TARGET-DIR
  Generate the static files' routes and paths hashed by their contents.

dreamwork setup
  Generate the framework integrations needed for features like static assets to
  work correctly. This creates a new dune library component 'static' with main
  module 'Static' in the directory in which it is run.
"

let comment =
  spf
    "(* This file is generated from the static assets in %s/%s/
   An empty file means that the directory is empty. *)\n"
    static assets

let already_setup =
  "dreamwork integration is already set up. You can access static assets in code now."

let setup_msg =
  "✅ dreamwork integration is set up now. After building your project with 'dune
build', you will be able to access static file paths and the static files router
from your project code. Remember to first add the 'static' library as a
dependency in your own dune component."

let dune_content =
  "; Remember to add 'static' as a dependency to your dune component's
; (libraries ...) field to access the static assets from code.

(library
 (name static)
 (libraries dream-html))

(rule
 (deps (glob_files_rec assets/*))
 (target static.ml)
 (action (run dreamwork static)))
"

let setup () =
  if Sys.file_exists static && Sys.is_directory static then fail already_setup;
  Sys.mkdir static 0o755;
  Sys.mkdir (Filename.concat static assets) 0o755;
  Out_channel.with_open_bin (Filename.concat static "dune") (fun dune ->
      Out_channel.output_string dune dune_content);
  print_endline setup_msg

let static () =
  Out_channel.with_open_bin (spf "%s.ml" static) (fun outc ->
      let p = Out_channel.output_string outc in
      p comment;
      write_paths p ~path:assets ~modpath:(filename_modname assets) "";
      write_routes p)

let () =
  if Array.length Sys.argv < 2 then fail usage;
  match Sys.argv.(1) with
  | "setup" -> setup ()
  | "static" -> static ()
  | _ -> fail usage
