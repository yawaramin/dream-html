(lang dune 2.7)

(name dream-html)

(version v3.5.1)

(generate_opam_files true)

(license GPL-3.0-or-later)

(authors "Yawar Amin <yawar.amin@gmail.com>")

(maintainers "Yawar Amin <yawar.amin@gmail.com>")

(source
 (github yawaramin/dream-html))

(package
 (name pure-html)
 (synopsis "HTML generator eDSL")
 (description
  "Write HTML directly in your OCaml source files with editor support.")
 (documentation "https://yawaramin.github.io/dream-html/")
 (tags (org:yawaramin))
 (depends
  (uri
   (and
    (>= 4.4.0)
    (< 5.0.0)))))

(package
 (name dream-html)
 (synopsis "HTML generator eDSL for Dream")
 (description
  "Write HTML directly in your OCaml source files with editor support.")
 (documentation "https://yawaramin.github.io/dream-html/")
 (tags (org:yawaramin))
 (depends
  pure-html
  (dream
   (>= 1.0.0~alpha3))))
