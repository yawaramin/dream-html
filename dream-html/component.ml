open Pure_html
open HTML

let combo_box = std_tag "combo-box"

let combo_box ~id ~list ~label ~placeholder =
  combo_box
    [HTML.id "%s" id; HTML.list "%s" list; class_ "field is-horizontal"]
    [ div
        [class_ "field-label"]
        [HTML.label [class_ "label"; for_ "%s-input" id] [txt "%s" label]];
      div
        [class_ "field-body"]
        [ div
            [class_ "dropdown field"]
            [ div
                [class_ "dropdown-trigger"]
                [ p
                    [class_ "control"]
                    [ input
                        [ HTML.id "%s-input" id;
                          class_ "input";
                          HTML.placeholder "%s" placeholder;
                          Aria.haspopup `true_;
                          Aria.controls "%s-menu" id ] ] ];
              div
                [class_ "dropdown-menu"; HTML.id "%s-menu" id; role `menu]
                [ div
                    [class_ "dropdown-content"]
                    [ a
                        [ href "#";
                          class_ "clear dropdown-item has-background-light" ]
                        [ span [] [txt "Clear"];
                          span
                            [class_ "icon is-small"; Aria.hidden true]
                            [txt "🚫"] ];
                      hr [class_ "dropdown-divider"] ] ] ] ] ]

let combo_box_js =
  script []
    {|
customElements.define('combo-box', class extends HTMLElement {
  connectedCallback() {
    const dropdown = this.querySelector('.dropdown');
    const inp = this.querySelector('input');
    const itemContainer = this.querySelector('.dropdown-content');
    const listId = this.getAttribute('list');

    for (const opt of document.querySelectorAll(`#${listId} > option`)) {
      const item = document.createElement('a');

      item.setAttribute('href', '#');
      item.classList.add('dropdown-item');
      item.innerText = opt.innerText == '' ? opt.getAttribute('value') : opt.innerText;

      item.addEventListener('click', () => {
        this.querySelector('.dropdown-item.is-active')?.classList.remove('is-active');
        item.classList.add('is-active');
        inp.value = item.innerText;
        dropdown.classList.remove('is-active');
      });

      itemContainer.appendChild(item);
    }

    inp.addEventListener('focus', () => {
      dropdown.classList.add('is-active');
    });

    const items = this.querySelectorAll('.dropdown-item:not(.clear)');

    this.querySelector('.dropdown-item.clear').addEventListener('click', () => {
      inp.value = '';
      dropdown.classList.remove('is-active');
      this.querySelector('.dropdown-item.is-active')?.classList.remove('is-active');

      for (const item of items) {
        item.classList.remove('is-hidden');
      }
    });

    inp.addEventListener('keyup', () => {
      const qryStr = inp.value.toLocaleLowerCase();

      for (const item of items) {
        if (qryStr == '' || item.textContent.toLocaleLowerCase().startsWith(qryStr)) {
          item.classList.remove('is-hidden');
        } else {
          item.classList.add('is-hidden');
        }
      }
    });
  }
});
                          |}
