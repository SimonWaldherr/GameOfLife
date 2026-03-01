// patterns.js — built-in pattern library

export const PATTERNS = [
  {
    name: 'Block',
    category: 'Still Life',
    rle: 'x = 2, y = 2\noo$oo!',
    grid: [[1,1],[1,1]],
    description: 'The simplest stable pattern. 4 cells that never change.'
  },
  {
    name: 'Beehive',
    category: 'Still Life',
    rle: 'x = 4, y = 3\nbo2b$o2bo$bo2b!',
    grid: [[0,1,1,0],[1,0,0,1],[0,1,1,0]],
    description: 'A 6-cell stable pattern shaped like a beehive.'
  },
  {
    name: 'Blinker',
    category: 'Oscillator (P2)',
    rle: 'x = 3, y = 1\n3o!',
    grid: [[1,1,1]],
    description: 'Period-2 oscillator. The simplest and most common oscillator.'
  },
  {
    name: 'Toad',
    category: 'Oscillator (P2)',
    rle: 'x = 4, y = 2\nboo$oob!',
    grid: [[0,1,1,0],[0,0,1,1],[1,1,0,0]].slice(0,2),
    description: 'Period-2 oscillator with 6 cells.'
  },
  {
    name: 'Beacon',
    category: 'Oscillator (P2)',
    rle: 'x = 4, y = 4\n2o2b$2o2b$2b2o$2b2o!',
    grid: [[1,1,0,0],[1,1,0,0],[0,0,1,1],[0,0,1,1]],
    description: 'Period-2 oscillator made of two offset blocks.'
  },
  {
    name: 'Glider',
    category: 'Spaceship',
    rle: 'x = 3, y = 3\nbo$2bo$3o!',
    grid: [[0,1,0],[0,0,1],[1,1,1]],
    description: 'The iconic spaceship! Moves diagonally across the grid every 4 generations.'
  },
  {
    name: 'LWSS',
    category: 'Spaceship',
    rle: 'x = 5, y = 4\nbo2bo$4bo$o3bo$b4o!',
    grid: [
      [0,1,0,0,1],
      [1,0,0,0,0],
      [1,0,0,0,1],
      [1,1,1,1,0]
    ],
    description: 'Lightweight Spaceship — moves horizontally across the grid.'
  },
  {
    name: 'Pulsar',
    category: 'Oscillator (P3)',
    rle: 'x = 13, y = 13, rule = B3/S23\n2b3o3b3o2b$4bobobobo$o4boboob4o$o4bobob4o$o4bobob4o$2b3o3b3o2b$7b7b$2b3o3b3o2b$o4bobob4o$o4bobob4o$o4bobob4o$4bobobobo$2b3o3b3o2b!',
    grid: null, // will use RLE
    rleData: `x = 13, y = 13
2b3o3b3o2b$4bobobobo4b$o4boboob4o$o4bobob4o$o4bobob4o$2b3o3b3o2b$7b7b$2b3o3b3o2b$o4bobob4o$o4bobob4o$o4bobob4o$4bobobobo4b$2b3o3b3o2b!`,
    description: 'Period-3 oscillator with 48 cells. One of the most beautiful patterns.'
  },
  {
    name: 'Gosper Glider Gun',
    category: 'Gun',
    rle: null,
    rleData: `x = 36, y = 9, rule = B3/S23
24bo11b$22bobo11b$12b2o6b2o12b2o$11bo3bo4b2o12b2o$2o8bo5bo3b2o14b$2o8bo3bob2o4bobo11b$10bo5bo7bo11b$11bo3bo20b$12b2o!`,
    grid: null,
    description: 'Famous pattern that endlessly generates gliders. First known gun pattern (1970).'
  }
];

// Parse a simple grid array or RLE into a 2D boolean array
export function parsePatternGrid(pattern) {
  if (pattern.grid) return pattern.grid;
  if (pattern.rleData) {
    return parseRLEToGrid(pattern.rleData);
  }
  return [[1]];
}

function parseRLEToGrid(rleText) {
  const lines = rleText.split('\n').filter(l => !l.startsWith('#'));
  let w = 10, h = 10;
  let bodyStart = 0;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes('x')) {
      const mx = lines[i].match(/x\s*=\s*(\d+)/);
      const my = lines[i].match(/y\s*=\s*(\d+)/);
      if (mx) w = parseInt(mx[1]);
      if (my) h = parseInt(my[1]);
      bodyStart = i + 1;
      break;
    }
  }
  const body = lines.slice(bodyStart).join('').replace(/\s/g, '');
  const grid = Array.from({length: h}, () => new Array(w).fill(0));
  let x = 0, y = 0, run = '';
  for (const ch of body) {
    if (ch >= '0' && ch <= '9') { run += ch; }
    else if (ch === 'b') { x += run ? parseInt(run) : 1; run = ''; }
    else if (ch === 'o') {
      const count = run ? parseInt(run) : 1;
      for (let i = 0; i < count; i++) if (y < h && x+i < w) grid[y][x+i] = 1;
      x += count; run = '';
    } else if (ch === '$') {
      y += run ? parseInt(run) : 1; x = 0; run = '';
    } else if (ch === '!') break;
  }
  return grid;
}
