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

  const suffixAttrs = {
    'cite': 1, 'class': 1, 'data': 1, 'for': 1, 'form': 1, 'label': 1,
    'method': 1, 'object': 1, 'open': 1, 'slot': 1, 'span': 1, 'style': 1,
    'title': 1, 'type': 1,
  };
  const ariaAttrs = {
    'aria-activedescendant': 1, 'aria-atomic': 1, 'aria-autocomplete': 1,
    'aria-braillelabel': 1, 'aria-brailleroledescription': 1, 'aria-busy': 1,
    'aria-checked': 1, 'aria-colcount': 1, 'aria-colindextext': 1,
    'aria-colspan': 1, 'aria-controls': 1, 'aria-current': 1,
    'aria-describedby': 1, 'aria-description': 1, 'aria-details': 1,
    'aria-disabled': 1, 'aria-errormessage': 1, 'aria-expanded': 1,
    'aria-flowto': 1, 'aria-haspopup': 1, 'aria-hidden': 1, 'aria-invalid': 1,
    'aria-keyshortcuts': 1, 'aria-label': 1, 'aria-labelledby': 1,
    'aria-level': 1, 'aria-live': 1, 'aria-modal': 1, 'aria-multiline': 1,
    'aria-multiselectable': 1, 'aria-orientation': 1, 'aria-owns': 1,
    'aria-placeholder': 1, 'aria-posinset': 1, 'aria-pressed': 1,
    'aria-readonly': 1, 'aria-relevant': 1, 'aria-required': 1,
    'aria-roledescription': 1, 'aria-rowcount': 1, 'aria-rowindex': 1,
    'aria-rowindextext': 1, 'aria-rowspan': 1, 'aria-selected': 1,
    'aria-setsize': 1, 'aria-sort': 1, 'aria-valuemax': 1, 'aria-valuemin': 1,
    'aria-valuenow': 1, 'aria-valuetext': 1,
  };
  const hxAttrs = {
    'hx-boost': 1, 'hx-confirm': 1, 'hx-delete': 1, 'hx-disable': 1,
    'hx-disinherit': 1, 'hx-encoding': 1, 'hx-ext': 1, 'hx-get': 1,
    'hx-headers': 1, 'hx-history': 1, 'hx-history-elt': 1, 'hx-include': 1,
    'hx-indicator': 1, 'hx-on': 1, 'hx-params': 1, 'hx-patch': 1, 'hx-post': 1,
    'hx-preload': 1, 'hx-preserve': 1, 'hx-prompt': 1, 'hx-push-url': 1,
    'hx-put': 1, 'hx-replace-url': 1, 'hx-request': 1, 'hx-select': 1,
    'hx-select-oob': 1, 'hx-sse-connect': 1, 'hx-sse-swap': 1, 'hx-swap': 1,
    'hx-swap-oob': 1, 'hx-sync': 1, 'hx-target': 1, 'hx-trigger': 1,
    'hx-validate': 1, 'hx-vals': 1, 'hx-ws-connect': 1, 'hx-ws-send': 1,
  };
  const polyVarAttrs = {
    'autocapitalize': 1, 'autocomplete': 1, 'capture': 1, 'crossorigin': 1,
    'decoding': 1, 'dir': 1, 'enctype': 1, 'fetchpriority': 1, 'formenctype': 1,
    'formmethod': 1, 'hidden': 1, 'http_equiv': 1, 'inputmode': 1, 'kind': 1,
    'low': 1, 'method': 1, 'preload': 1, 'referrerpolicy': 1, 'role': 1,
    'translate': 1, 'wrap': 1,
    'aria-autocomplete': 1, 'aria-checked': 1, 'aria-current': 1,
    'aria-haspopup': 1, 'aria-invalid': 1, 'aria-live': 1, 'aria-orientation': 1,
    'aria-pressed': 1, 'aria-relevant': 1, 'aria-sort': 1,
  };
  const numAttrs = {
    'cols': 1, 'colspan': 1, 'high': 1, 'low': 1, 'maxlength': 1, 'minlength': 1,
    'optimum': 1, 'rows': 1, 'rowspan': 1, 'span': 1, 'start': 1, 'tabindex': 1,
    'aria-valuemax': 1, 'aria-valuemin': 1, 'aria-valuenow': 1,
  };
  const boolAttrs = {
    'async': 1, 'autofocus': 1, 'autoplay': 1, 'checked': 1, 'controls': 1,
    'default': 1, 'defer': 1, 'disabled': 1, 'draggable': 1, 'formnovalidate': 1,
    'ismap': 1, 'loop': 1, 'multiple': 1, 'muted': 1, 'novalidate': 1, 'open': 1,
    'playsinline': 1, 'readonly': 1, 'required': 1, 'reversed': 1, 'selected': 1,
    'aria-atomic': 1, 'aria-busy': 1, 'aria-disabled': 1, 'aria-modal': 1,
    'aria-multiline': 1, 'aria-multiselectable': 1, 'aria-readonly': 1,
    'aria-required': 1,
    'hx-disable': 1, 'data-hx-disable': 1, 'hx-history-elt': 1,
    'data-hx-history-elt': 1, 'hx-preload': 1, 'data-hx-preload': 1,
    'hx-preserve': 1, 'data-hx-preserve': 1, 'hx-validate': 1,
    'data-hx-validate': 1, 'hx-ws-send': 1, 'data-hx-ws-send': 1,
  };
  const voidTags = {
    'area': 1, 'base': 1, 'br': 1, 'col': 1, 'embed': 1, 'hr': 1, 'img': 1,
    'input': 1, 'link': 1, 'meta': 1, 'source': 1, 'track': 1, 'wbr': 1,
  };
  const textTags = {
    'option': 1, 'script': 1, 'style': 1, 'textarea': 1, 'title': 1
  };

  const attr = name => {
    if (suffixAttrs[name]) return name + '_';
    if (ariaAttrs[name]) return 'Aria.' + name.slice(5);
    if (hxAttrs[name]) return 'Hx.' + name.slice(3).replaceAll('-', '_');

    if (
      name.length >= 9 &&
      name.startsWith('data-hx-') &&
      hxAttrs[name.slice(5)] > -1
    ) return 'Hx.' + name.slice(8).replaceAll('-', '_');

    if (name.indexOf('-') > -1) return 'string_attr "' + name + '"';
    return name;
  };

  const polyvar = v => {
    let v2 = v;

    switch (v2) {
      case 'get':
      case 'post':
        v2 = v2.toUpperCase();
        break;
      case 'true':
      case 'false':
        v2 += '_';
        break;
      default:
        v2 = v2.replaceAll('-', '_');
    }

    return '`' + v2;
  };

  const stringify = (v, nm = '') => {
    if (v == null) return '';
    if (polyVarAttrs[nm]) return polyvar(v);
    if (numAttrs[nm]) return v;
    if (boolAttrs[nm]) return '';
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

        if (voidTags[name]) {
          /* do nothing */
        } else if (textTags[name]) {
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
