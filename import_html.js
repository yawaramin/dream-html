javascript: (async () => {
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

  const suffixAttrs = [
    'cite', 'class', 'data', 'for', 'form', 'label', 'method', 'object', 'open',
    'slot', 'span', 'style', 'title', 'type',
  ];
  const polyVarAttrs = [
    'autocapitalize', 'autocomplete', 'capture', 'crossorigin', 'decoding', 'dir',
    'enctype', 'fetchpriority', 'formenctype', 'formmethod', 'hidden',
    'http_equiv', 'inputmode', 'kind', 'low', 'method', 'preload',
    'referrerpolicy', 'translate', 'wrap',
  ];
  const intAttrs = [
    'cols', 'colspan', 'maxlength', 'minlength', 'rows', 'rowspan', 'span',
    'start', 'tabindex',
  ];
  const boolAttrs = [
    'async', 'autofocus', 'autoplay', 'checked', 'controls', 'default', 'defer',
    'disabled', 'draggable', 'formnovalidate', 'ismap', 'loop', 'multiple',
    'muted', 'novalidate', 'open', 'playsinline', 'readonly', 'required',
    'reversed', 'selected',
  ];
  const voidTags = [
    'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta',
    'source', 'track', 'wbr',
  ];
  const textTags = ['option', 'script', 'style', 'textarea', 'title'];

  const attr = name => {
    if (suffixAttrs.indexOf(name) > -1) return name + '_';
    if (name.indexOf('-') > -1) return 'string_attr "' + name + '"';
    return name;
  };

  const polyvar = v =>
    '`' + (v == 'get' || v == 'post' ? v.toUpperCase() : v).replaceAll('-', '_');

  const stringify = (v, nm = '') => {
    if (v == null) return '';
    if (polyVarAttrs.indexOf(nm) > -1) return polyvar(v);
    if (intAttrs.indexOf(nm) > -1) return v;
    if (boolAttrs.indexOf(nm) > -1) return '';
    if (v.indexOf('"') > -1) return '{|' + v + '|}';
    return '"' + v + '"';
  };

  let res = '';

  const writeTag = t => {
    switch (t.nodeType) {
      case Node.COMMENT_NODE:
        res += 'comment ';
        res += stringify(t.data);
        break;

      case Node.TEXT_NODE:
        res += 'txt ';
        res += stringify(t.data);
        break;

      case Node.ELEMENT_NODE:
        const name = t.tagName.toLowerCase();
        res += name;

        res += ' [';
        for (const a of t.attributes) {
          res += attr(a.name);
          res += ' ';
          res += stringify(a.value, a.name);
          res += '; ';
        }
        res += '] ';

        if (voidTags.indexOf(name) > -1) {
          /* do nothing */
        } else if (textTags.indexOf(name) > -1) {
          res += stringify(t.innerText);
        } else {
          res += '[';
          for (const child of t.childNodes) {
            res += '\n';
            writeTag(child);
            res += ';';
          }
          res += ']';
        }
        break;

      default:
        console.warn(t.nodeType);
    }
  };

  writeTag(document.querySelector('html'));
  await navigator.clipboard.writeText(res);
})()
