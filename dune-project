(lang dune 2.8)

(name dream-html)

(generate_opam_files true)

(license GPL-3.0-or-later)

(authors "Yawar Amin <yawar.amin@gmail.com>")

(maintainers "Yawar Amin <yawar.amin@gmail.com>")

(source
 (github yawaramin/dream-html))

(package
 (name pure-html)
 (version v3.8.1)
 (synopsis "HTML generator eDSL")
 (description
  "Write HTML directly in your OCaml source files with editor support.")
 (documentation "https://yawaramin.github.io/dream-html/")
 (tags (org:yawaramin))
 (depends
  (uri
   (and
    (>= 4.4.0)
    (< 5.0.0)))
  (ppx_expect :with-test)))

(package
 (name dream-html)
 (version v3.9.0)
 (synopsis "HTML generator eDSL for Dream")
 (description
  "Write HTML directly in your OCaml source files with editor support.")
 (documentation "https://yawaramin.github.io/dream-html/")
 (tags (org:yawaramin))
 (depends
  (pure-html
   (= 3.8.1))
  ; %{version:pure-html} not working
  (dream
   (>= 1.0.0~alpha3))
  (fmt :with-test)
  (ppx_expect :with-test)))
