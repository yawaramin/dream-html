open Pure_html
open HTML

let combo_box = std_tag "combo-box"

let combo_box ~id ~list ~label ~placeholder =
  combo_box
    [ HTML.id "%s" id;
      HTML.list "%s" list;
      class_ "field is-horizontal";
      HTML.placeholder "%s" placeholder ]
    [ div
        [class_ "field-label"]
        [HTML.label [class_ "label"; for_ "%s-input" id] [txt "%s" label]];
      div
        [class_ "field-body"]
        [ div
            [class_ "field has-addons"]
            [ div
                [class_ "control"]
                [ input
                    [ HTML.id "%s-input" id;
                      type_ "search";
                      class_ "input";
                      Aria.haspopup `true_;
                      Aria.controls "%s-menu" id ] ];
              div
                [class_ "control dropdown is-right"]
                [ div
                    [class_ "dropdown-trigger"]
                    [button [class_ "button"; title_ "Search"] [txt "🔎"]];
                  div
                    [class_ "dropdown-menu"; HTML.id "%s-menu" id; role `menu]
                    [div [class_ "dropdown-content"] []] ] ] ] ]
