(() => {
  /**
   * @param {string} msg
   * @returns {never}
   */
  function typeError(msg) {
    throw new TypeError(msg);
  }

  customElements.define('combo-box', class extends HTMLElement {
    connectedCallback() {
      const dropdown = this.querySelector('.dropdown');
      if (dropdown == null) {
        typeError('dropdown is null');
      }

      const inp = this.querySelector('input');
      if (inp == null) {
        typeError('input is null');
      }

      const itemContainer = this.querySelector('.dropdown-content');
      if (itemContainer == null) {
        typeError('items container is null');
      }

      const listId = this.getAttribute('list');
      const items = [];

      for (const opt of document.querySelectorAll(`#${listId} > option`)) {
        if (!(opt instanceof HTMLOptionElement)) {
          typeError('option');
        }

        const item = document.createElement('a');

        item.setAttribute('href', '#');
        item.classList.add('dropdown-item');
        item.innerText = opt.innerText ||
          opt.getAttribute('value') ||
          typeError('expected option to have text or value');

        item.addEventListener('click', () => {
          this.querySelector('.dropdown-item.is-active')?.classList.remove('is-active');
          item.classList.add('is-active');
          inp.value = item.innerText;
          dropdown.classList.remove('is-active');
        });

        itemContainer.appendChild(item);
        items.push(item);
      }

      inp.addEventListener('focus', () => {
        dropdown.classList.add('is-active');
      });

      this.querySelector('.dropdown-trigger > button')?.addEventListener('click', () => {
        dropdown.classList.toggle('is-active');
        inp.focus();
      });

      document.addEventListener('click', evt => {
        if (evt.target instanceof Node && !this.contains(evt.target)) {
          dropdown.classList.remove('is-active');
        }
      });

      inp.addEventListener('keyup', evt => {
        if (evt.key == 'Escape') {
          dropdown.classList.remove('is-active');
          return;
        }

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
})();
