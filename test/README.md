## Snapshot tests

> [!WARNING]
> The tests are using purely dune's file diffing and promotion feature as that
> does not require any library dependencies. We tried using ppx_expect tests but
> the problem is they are _inline_ tests that must be defined in a `library`
> component, not a `test` component like the tests we have now. And `library`
> components need opam packages to be installed _without_ the `with-test`
> annotation, meaning that using ppx_expect would pull in _all_ the Jane Street
> libraries as dependencies of both pure-html and dream-html. So, we are back now
> to dune's diffing and promotion for tests, which require _no_ dependencies.
