// state.js — URL encode/decode for sharing

export function encodeState(grid, extraParams = {}) {
  const params = new URLSearchParams();
  params.set('w', grid.width);
  params.set('h', grid.height);
  params.set('rule', grid.getRuleString());
  params.set('wrap', grid.wrap ? '1' : '0');
  const rle = grid.serializeRLE();
  // Only save if not empty
  if (grid.countLive() > 0) {
    params.set('rle', btoa(rle));
  }
  for (const [k, v] of Object.entries(extraParams)) {
    params.set(k, v);
  }
  return params.toString();
}

export function decodeState(search) {
  const params = new URLSearchParams(search);
  const result = {};
  if (params.has('w')) result.width = parseInt(params.get('w'));
  if (params.has('h')) result.height = parseInt(params.get('h'));
  if (params.has('rule')) result.rule = params.get('rule');
  if (params.has('wrap')) result.wrap = params.get('wrap') === '1';
  if (params.has('rle')) {
    try { result.rle = atob(params.get('rle')); } catch(e) {}
  }
  return result;
}

export function saveToURL(grid) {
  const qs = encodeState(grid);
  history.replaceState(null, '', '?' + qs);
}
