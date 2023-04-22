(lang dune 2.7)

(name dream_html)
(version v0.0.1)
(generate_opam_files true)
(license GPL-3.0-or-later)
(authors "Yawar Amin <yawar.amin@gmail.com>")
(maintainers "Yawar Amin <yawar.amin@gmail.com>")
(source (github yawaramin/dream-html))

(package
  (name dream_html)
  (synopsis "HTML generator eDSL for Dream")
  (description "Write HTML directly in your OCaml source files with editor support.")
  (documentation "https://yawaramin.github.io/dream-html/api")
  (depends
    (alcotest (and (>= 1.5.0) (< 2.0.0) :with-test))
    (ocaml (>= 4.08.0))
    dream))
