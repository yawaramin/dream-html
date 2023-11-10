(lang dune 2.7)

(name dream-html)

(version v1.2.0)

(generate_opam_files true)

(license GPL-3.0-or-later)

(authors "Yawar Amin <yawar.amin@gmail.com>")

(maintainers "Yawar Amin <yawar.amin@gmail.com>")

(source
 (github yawaramin/dream-html))

(package
 (name dream-html)
 (synopsis "HTML generator eDSL for Dream")
 (description
  "Write HTML directly in your OCaml source files with editor support.")
 (documentation "https://yawaramin.github.io/dream-html/")
 (depends
  (dream
   (>= 1.0.0~alpha3))))
