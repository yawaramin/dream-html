/* Copyright 2024 Yawar Amin

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
   dream-html. If not, see <https://www.gnu.org/licenses/>. */

document.addEventListener('htmx:responseError', evt => {
  const toast = document.getElementById('#toast');

  if (toast == null) return;
  toast.outerHTML = `<span id="toast" class="error">${evt.detail.xhr.responseText}</span>`;
});

document.querySelectorAll('input').forEach(inp => {
  inp.addEventListener('blur', () => {
    if (inp.validity.valid) {
      inp.removeAttribute('aria-invalid');
    } else {
      inp.setAttribute('aria-invalid', 'true');
    }
  });
});
