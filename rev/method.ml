let equal m1 m2 = Piaf.Method.to_string m1 = Piaf.Method.to_string m2

let normalize = function
  | `Other s -> Piaf.Method.of_string s
  | m -> m
