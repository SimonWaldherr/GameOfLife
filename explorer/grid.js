// grid.js — core data model with typed arrays, double buffering, RLE support

export class Grid {
  constructor(width, height, wrap = true) {
    this.init(width, height, wrap);
  }

  init(width, height, wrap = true) {
    this.width = width;
    this.height = height;
    this.wrap = wrap;
    this.current = new Uint8Array(width * height);
    this.next = new Uint8Array(width * height);
    this.generation = 0;
    // Birth/Survival rule arrays (default Conway B3/S23)
    this.birthRule = new Uint8Array(9);   // birthRule[n]=1 => birth with n neighbors
    this.surviveRule = new Uint8Array(9); // surviveRule[n]=1 => survive with n neighbors
    this.birthRule[3] = 1;
    this.surviveRule[2] = 1;
    this.surviveRule[3] = 1;
  }

  idx(x, y) {
    return y * this.width + x;
  }

  get(x, y) {
    if (this.wrap) {
      x = ((x % this.width) + this.width) % this.width;
      y = ((y % this.height) + this.height) % this.height;
    } else {
      if (x < 0 || x >= this.width || y < 0 || y >= this.height) return 0;
    }
    return this.current[this.idx(x, y)];
  }

  set(x, y, value) {
    if (x < 0 || x >= this.width || y < 0 || y >= this.height) return;
    this.current[this.idx(x, y)] = value ? 1 : 0;
  }

  toggle(x, y) {
    if (x < 0 || x >= this.width || y < 0 || y >= this.height) return;
    const i = this.idx(x, y);
    this.current[i] ^= 1;
  }

  countNeighbors(x, y) {
    let count = 0;
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        if (dx === 0 && dy === 0) continue;
        let nx = x + dx, ny = y + dy;
        if (this.wrap) {
          nx = ((nx % this.width) + this.width) % this.width;
          ny = ((ny % this.height) + this.height) % this.height;
        } else {
          if (nx < 0 || nx >= this.width || ny < 0 || ny >= this.height) continue;
        }
        count += this.current[this.idx(nx, ny)];
      }
    }
    return count;
  }

  // Returns array of {x, y, prev, next} for changed cells
  step() {
    const changed = [];
    const w = this.width, h = this.height;

    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const i = this.idx(x, y);
        const alive = this.current[i];
        const n = this.countNeighbors(x, y);
        let nextState;
        if (alive) {
          nextState = this.surviveRule[n] ? 1 : 0;
        } else {
          nextState = this.birthRule[n] ? 1 : 0;
        }
        this.next[i] = nextState;
        if (nextState !== alive) {
          changed.push({ x, y, prev: alive, next: nextState, neighbors: n });
        }
      }
    }

    // Swap buffers
    const tmp = this.current;
    this.current = this.next;
    this.next = tmp;
    this.generation++;
    return changed;
  }

  countLive() {
    let count = 0;
    for (let i = 0; i < this.current.length; i++) count += this.current[i];
    return count;
  }

  clear() {
    this.current.fill(0);
    this.generation = 0;
  }

  randomize(density = 0.3) {
    for (let i = 0; i < this.current.length; i++) {
      this.current[i] = Math.random() < density ? 1 : 0;
    }
  }

  // Set rule from B/S notation string like "B3/S23"
  setRule(ruleStr) {
    this.birthRule.fill(0);
    this.surviveRule.fill(0);
    const m = ruleStr.toUpperCase().match(/B([0-8]*)\/S([0-8]*)/);
    if (!m) return;
    for (const c of m[1]) this.birthRule[parseInt(c)] = 1;
    for (const c of m[2]) this.surviveRule[parseInt(c)] = 1;
  }

  getRuleString() {
    let b = '', s = '';
    for (let i = 0; i <= 8; i++) {
      if (this.birthRule[i]) b += i;
      if (this.surviveRule[i]) s += i;
    }
    return `B${b}/S${s}`;
  }

  // Serialize entire grid as RLE
  serializeRLE() {
    const w = this.width, h = this.height;
    let rle = `x = ${w}, y = ${h}, rule = ${this.getRuleString()}\n`;
    let body = '';
    for (let y = 0; y < h; y++) {
      let rowStr = '';
      let run = 0;
      let lastCell = this.current[this.idx(0, y)];
      for (let x = 1; x < w; x++) {
        const c = this.current[this.idx(x, y)];
        if (c === lastCell) {
          run++;
        } else {
          rowStr += encodeRLERun(run + 1, lastCell);
          lastCell = c;
          run = 0;
        }
      }
      rowStr += encodeRLERun(run + 1, lastCell);
      // trim trailing dead cells
      rowStr = rowStr.replace(/\d*b$/, '');
      body += rowStr + (y < h - 1 ? '$' : '!');
    }
    // Trim trailing $
    body = body.replace(/\$+!$/, '!');
    rle += body;
    return rle;
  }

  loadRLE(text) {
    // Parse RLE, place at center
    const lines = text.split('\n').filter(l => !l.startsWith('#'));
    let header = null, bodyLines = [];
    for (const line of lines) {
      if (!header && line.includes('x')) {
        header = line;
      } else {
        bodyLines.push(line);
      }
    }
    const body = bodyLines.join('').replace(/\s/g, '');
    // Parse dimensions
    let pw = this.width, ph = this.height;
    if (header) {
      const mx = header.match(/x\s*=\s*(\d+)/);
      const my = header.match(/y\s*=\s*(\d+)/);
      if (mx) pw = parseInt(mx[1]);
      if (my) ph = parseInt(my[1]);
      const mr = header.match(/rule\s*=\s*([B0-9\/S]+)/i);
      if (mr) this.setRule(mr[1]);
    }
    const cells = decodeRLE(body, pw, ph);
    const ox = Math.floor((this.width - pw) / 2);
    const oy = Math.floor((this.height - ph) / 2);
    for (const {x, y, v} of cells) {
      this.set(x + ox, y + oy, v);
    }
  }

  // Place a pattern (2D array) at position, return bounding box
  placePattern(pattern, cx, cy) {
    const ph = pattern.length;
    const pw = pattern[0]?.length || 0;
    const ox = cx - Math.floor(pw / 2);
    const oy = cy - Math.floor(ph / 2);
    for (let y = 0; y < ph; y++) {
      for (let x = 0; x < pw; x++) {
        if (pattern[y][x]) this.set(ox + x, oy + y, 1);
      }
    }
  }
}

function encodeRLERun(count, cell) {
  const ch = cell ? 'o' : 'b';
  return (count === 1 ? '' : count) + ch;
}

function decodeRLE(body, w, h) {
  const cells = [];
  let x = 0, y = 0, run = '';
  for (const ch of body) {
    if (ch >= '0' && ch <= '9') {
      run += ch;
    } else if (ch === 'b') {
      x += run ? parseInt(run) : 1;
      run = '';
    } else if (ch === 'o') {
      const count = run ? parseInt(run) : 1;
      for (let i = 0; i < count; i++) cells.push({x: x + i, y, v: 1});
      x += count;
      run = '';
    } else if (ch === '$') {
      const count = run ? parseInt(run) : 1;
      y += count;
      x = 0;
      run = '';
    } else if (ch === '!') {
      break;
    }
  }
  return cells;
}
