// app.js — main application entry point

import { Grid } from './grid.js';
import { Renderer } from './renderer.js';
import { PATTERNS, parsePatternGrid } from './patterns.js';
import { saveToURL, decodeState } from './state.js';

const DEFAULT_W = 80, DEFAULT_H = 50;

class App {
  constructor() {
    this.grid = new Grid(DEFAULT_W, DEFAULT_H, true);
    this.canvas = document.getElementById('life-canvas');
    this.renderer = new Renderer(this.canvas, this.grid);

    this.running = false;
    this.speed = 10; // gen/sec
    this.lastStep = 0;
    this.frameCount = 0;
    this.fpsTime = 0;
    this.fps = 0;

    this.selectedPattern = null;
    this.ghostPattern = null;

    // Interaction state
    this.isDragging = false;
    this.isPainting = true; // true=paint, false=erase (shift)
    this.isPanning = false;
    this.lastPanX = 0; this.lastPanY = 0;
    this.lastPaintCell = null;

    // Inspector
    this.inspectedCell = null;

    this.initUI();
    this.initCanvas();
    this.loadFromURL();
    this.renderer.resize();
    this.renderer.fitToView();
    this.loop(0);
  }

  loadFromURL() {
    const state = decodeState(window.location.search);
    if (state.width && state.height) {
      this.grid.init(state.width, state.height, state.wrap ?? true);
      document.getElementById('grid-width').value = state.width;
      document.getElementById('grid-height').value = state.height;
    }
    if (state.rule) {
      this.grid.setRule(state.rule);
      this.updateRuleUI();
    }
    if (state.rle) {
      this.grid.loadRLE(state.rle);
    }
    this.renderer.grid = this.grid;
    this.renderer.fitToView();
  }

  initUI() {
    // Play/Pause
    const btnPlay = document.getElementById('btn-play');
    btnPlay.addEventListener('click', () => {
      this.running = !this.running;
      btnPlay.textContent = this.running ? '⏸ Pause' : '▶ Play';
      btnPlay.classList.toggle('active', this.running);
    });

    // Step
    document.getElementById('btn-step').addEventListener('click', () => {
      this.doStep();
    });

    // Clear
    document.getElementById('btn-clear').addEventListener('click', () => {
      this.grid.clear();
      this.renderer.changedCells = [];
      this.running = false;
      document.getElementById('btn-play').textContent = '▶ Play';
      document.getElementById('btn-play').classList.remove('active');
      this.updateStats();
    });

    // Randomize
    document.getElementById('btn-randomize').addEventListener('click', () => {
      const density = parseInt(document.getElementById('slider-density').value) / 100;
      this.grid.randomize(density);
      this.updateStats();
    });

    // Speed slider
    document.getElementById('slider-speed').addEventListener('input', e => {
      this.speed = parseInt(e.target.value);
      document.getElementById('speed-val').textContent = this.speed;
    });

    // Density slider
    document.getElementById('slider-density').addEventListener('input', e => {
      document.getElementById('density-val').textContent = e.target.value + '%';
    });

    // Toggles
    document.getElementById('toggle-wrap').addEventListener('change', e => {
      this.grid.wrap = e.target.checked;
    });
    document.getElementById('toggle-neighbors').addEventListener('change', e => {
      this.renderer.showNeighborCounts = e.target.checked;
    });
    document.getElementById('toggle-highlights').addEventListener('change', e => {
      this.renderer.showChanges = e.target.checked;
    });
    document.getElementById('toggle-grid').addEventListener('change', e => {
      this.renderer.showGrid = e.target.checked;
    });

    // Grid size
    document.getElementById('btn-resize').addEventListener('click', () => {
      const w = parseInt(document.getElementById('grid-width').value);
      const h = parseInt(document.getElementById('grid-height').value);
      if (w > 0 && h > 0 && w <= 500 && h <= 500) {
        this.grid.init(w, h, this.grid.wrap);
        this.renderer.fitToView();
      }
    });

    // Rule checkboxes
    for (let n = 0; n <= 8; n++) {
      const cb = document.getElementById(`birth-${n}`);
      const cs = document.getElementById(`survive-${n}`);
      if (cb) cb.addEventListener('change', () => this.updateRuleFromUI());
      if (cs) cs.addEventListener('change', () => this.updateRuleFromUI());
    }

    // Preset rules
    document.querySelectorAll('.preset-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        this.grid.setRule(btn.dataset.rule);
        this.updateRuleUI();
        document.querySelectorAll('.preset-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
      });
    });

    // Pattern library
    this.buildPatternLibrary();

    // RLE import/export
    document.getElementById('btn-export-rle').addEventListener('click', () => {
      const rle = this.grid.serializeRLE();
      document.getElementById('rle-textarea').value = rle;
    });
    document.getElementById('btn-import-rle').addEventListener('click', () => {
      const rle = document.getElementById('rle-textarea').value;
      if (rle.trim()) {
        this.grid.clear();
        this.grid.loadRLE(rle);
        this.updateStats();
      }
    });
    document.getElementById('btn-share').addEventListener('click', () => {
      saveToURL(this.grid);
      navigator.clipboard?.writeText(window.location.href).then(() => {
        const btn = document.getElementById('btn-share');
        btn.textContent = '✓ Copied!';
        setTimeout(() => btn.textContent = '🔗 Share URL', 1500);
      });
    });

    // Cancel ghost pattern on Escape
    document.addEventListener('keydown', e => {
      if (e.key === 'Escape') {
        this.selectedPattern = null;
        this.ghostPattern = null;
        this.renderer.ghostPattern = null;
        document.querySelectorAll('.pattern-btn').forEach(b => b.classList.remove('active'));
      }
    });
  }

  buildPatternLibrary() {
    const container = document.getElementById('pattern-list');
    container.innerHTML = '';
    for (const p of PATTERNS) {
      const btn = document.createElement('button');
      btn.className = 'pattern-btn';
      btn.dataset.patternName = p.name;

      const name = document.createElement('span');
      name.className = 'pattern-name';
      name.textContent = p.name;

      const cat = document.createElement('span');
      cat.className = 'pattern-cat';
      cat.textContent = p.category;

      btn.appendChild(name);
      btn.appendChild(cat);
      btn.title = p.description;

      btn.addEventListener('click', () => {
        document.querySelectorAll('.pattern-btn').forEach(b => b.classList.remove('active'));
        if (this.selectedPattern === p) {
          this.selectedPattern = null;
          this.ghostPattern = null;
          this.renderer.ghostPattern = null;
        } else {
          btn.classList.add('active');
          this.selectedPattern = p;
          this.ghostPattern = parsePatternGrid(p);
          this.renderer.ghostPattern = this.ghostPattern;
          document.getElementById('pattern-desc').textContent = p.description;
        }
      });

      container.appendChild(btn);
    }
  }

  updateRuleFromUI() {
    let b = '', s = '';
    for (let n = 0; n <= 8; n++) {
      if (document.getElementById(`birth-${n}`)?.checked) b += n;
      if (document.getElementById(`survive-${n}`)?.checked) s += n;
    }
    const rule = `B${b}/S${s}`;
    this.grid.setRule(rule);
    document.getElementById('rule-display').textContent = rule;
    document.querySelectorAll('.preset-btn').forEach(b => b.classList.remove('active'));
  }

  updateRuleUI() {
    for (let n = 0; n <= 8; n++) {
      const cb = document.getElementById(`birth-${n}`);
      const cs = document.getElementById(`survive-${n}`);
      if (cb) cb.checked = !!this.grid.birthRule[n];
      if (cs) cs.checked = !!this.grid.surviveRule[n];
    }
    document.getElementById('rule-display').textContent = this.grid.getRuleString();
  }

  doStep() {
    const changed = this.grid.step();
    this.renderer.setChangedCells(changed);
    this.updateStats();

    // Update inspector if a cell is selected
    if (this.inspectedCell) {
      const {x, y} = this.inspectedCell;
      this.showInspector(x, y, changed);
    }
  }

  updateStats() {
    document.getElementById('stat-gen').textContent = this.grid.generation;
    document.getElementById('stat-live').textContent = this.grid.countLive();
    document.getElementById('stat-fps').textContent = this.fps.toFixed(1);
  }

  showInspector(x, y, recentChanged = []) {
    this.inspectedCell = {x, y};
    const alive = this.grid.get(x, y);
    const n = this.grid.countNeighbors(x, y);
    const panel = document.getElementById('inspector-panel');

    let rule = '';
    let outcome = '';
    if (alive) {
      if (this.grid.surviveRule[n]) {
        rule = `S${n} — survives`;
        outcome = `<span class="alive-label">Stays alive</span> with ${n} neighbor${n!==1?'s':''} (S${n})`;
      } else {
        rule = `${n} neighbor${n!==1?'s':''} — no survival rule`;
        outcome = `<span class="dead-label">Will die</span> — needs S${n} to survive`;
      }
    } else {
      if (this.grid.birthRule[n]) {
        rule = `B${n} — will be born`;
        outcome = `<span class="alive-label">Will be born</span> with exactly ${n} neighbor${n!==1?'s':''} (B${n})`;
      } else {
        rule = `${n} neighbor${n!==1?'s':''} — no birth rule`;
        outcome = `<span class="dead-label">Stays dead</span> — needs B${n} for birth`;
      }
    }

    // Check recent change
    const change = recentChanged.find(c => c.x === x && c.y === y);
    let changeNote = '';
    if (change) {
      if (change.next === 1) changeNote = `<div class="change-note born">✦ Born this generation (had ${change.neighbors} neighbors)</div>`;
      else changeNote = `<div class="change-note died">✦ Died this generation (had ${change.neighbors} neighbors)</div>`;
    }

    panel.innerHTML = `
      <div class="inspector-title">Cell (${x}, ${y})</div>
      ${changeNote}
      <div class="inspector-row">
        <span class="label">State:</span>
        <span class="${alive ? 'alive-label' : 'dead-label'}">${alive ? '● Alive' : '○ Dead'}</span>
      </div>
      <div class="inspector-row">
        <span class="label">Neighbors:</span>
        <span class="value">${n}</span>
      </div>
      <div class="inspector-row">
        <span class="label">Next step:</span>
        <span>${outcome}</span>
      </div>
      <div class="inspector-rule">${rule}</div>
      <div class="inspector-hint">Press Step to advance</div>
    `;
    panel.style.display = 'block';
  }

  initCanvas() {
    const canvas = this.canvas;

    // Resize observer
    const ro = new ResizeObserver(() => {
      this.renderer.resize();
    });
    ro.observe(canvas);
    this.renderer.resize();

    // Mouse events
    canvas.addEventListener('mousedown', e => this.onMouseDown(e));
    canvas.addEventListener('mousemove', e => this.onMouseMove(e));
    canvas.addEventListener('mouseup', e => this.onMouseUp(e));
    canvas.addEventListener('mouseleave', () => {
      this.isDragging = false;
      this.isPanning = false;
      this.renderer.hoverX = -1;
      this.renderer.hoverY = -1;
    });
    canvas.addEventListener('wheel', e => {
      e.preventDefault();
      const rect = canvas.getBoundingClientRect();
      const cx = e.clientX - rect.left;
      const cy = e.clientY - rect.top;
      const factor = e.deltaY < 0 ? 1.15 : 0.87;
      this.renderer.zoom(factor, cx, cy);
    }, { passive: false });

    // Touch
    let lastTouchDist = 0, lastTouchX = 0, lastTouchY = 0;
    canvas.addEventListener('touchstart', e => {
      if (e.touches.length === 2) {
        lastTouchDist = Math.hypot(
          e.touches[0].clientX - e.touches[1].clientX,
          e.touches[0].clientY - e.touches[1].clientY
        );
        lastTouchX = (e.touches[0].clientX + e.touches[1].clientX) / 2;
        lastTouchY = (e.touches[0].clientY + e.touches[1].clientY) / 2;
      }
    });
    canvas.addEventListener('touchmove', e => {
      e.preventDefault();
      if (e.touches.length === 2) {
        const dist = Math.hypot(
          e.touches[0].clientX - e.touches[1].clientX,
          e.touches[0].clientY - e.touches[1].clientY
        );
        const cx = (e.touches[0].clientX + e.touches[1].clientX) / 2;
        const cy = (e.touches[0].clientY + e.touches[1].clientY) / 2;
        const rect = canvas.getBoundingClientRect();
        this.renderer.zoom(dist / lastTouchDist, cx - rect.left, cy - rect.top);
        this.renderer.pan(cx - lastTouchX, cy - lastTouchY);
        lastTouchDist = dist;
        lastTouchX = cx; lastTouchY = cy;
      }
    }, { passive: false });

    // Context menu suppress
    canvas.addEventListener('contextmenu', e => e.preventDefault());
  }

  getCanvasPos(e) {
    const rect = this.canvas.getBoundingClientRect();
    return { x: e.clientX - rect.left, y: e.clientY - rect.top };
  }

  onMouseDown(e) {
    e.preventDefault();
    const pos = this.getCanvasPos(e);

    if (e.button === 1 || e.button === 2) {
      // Middle or right = pan
      this.isPanning = true;
      this.lastPanX = pos.x;
      this.lastPanY = pos.y;
      return;
    }

    if (this.selectedPattern) {
      // Place pattern
      const cell = this.renderer.screenToGrid(pos.x, pos.y);
      this.grid.placePattern(this.ghostPattern, cell.x, cell.y);
      this.updateStats();
      return;
    }

    this.isDragging = true;
    const cell = this.renderer.screenToGrid(pos.x, pos.y);

    if (e.shiftKey) {
      this.isPainting = false;
    } else {
      // Toggle on click
      const alive = this.grid.get(cell.x, cell.y);
      this.isPainting = !alive;
    }

    this.paintCell(cell.x, cell.y);
    this.showInspector(cell.x, cell.y);
  }

  onMouseMove(e) {
    const pos = this.getCanvasPos(e);
    const cell = this.renderer.screenToGrid(pos.x, pos.y);

    if (this.isPanning) {
      this.renderer.pan(pos.x - this.lastPanX, pos.y - this.lastPanY);
      this.lastPanX = pos.x;
      this.lastPanY = pos.y;
      return;
    }

    // Update hover
    this.renderer.hoverX = cell.x;
    this.renderer.hoverY = cell.y;

    // Update ghost
    if (this.selectedPattern) {
      this.renderer.ghostX = cell.x;
      this.renderer.ghostY = cell.y;
    }

    if (this.isDragging) {
      const key = `${cell.x},${cell.y}`;
      if (!this.lastPaintCell || this.lastPaintCell !== key) {
        this.lastPaintCell = key;
        this.paintCell(cell.x, cell.y);
      }
    }
  }

  onMouseUp(e) {
    this.isDragging = false;
    this.isPanning = false;
    this.lastPaintCell = null;
  }

  paintCell(x, y) {
    if (x < 0 || y < 0 || x >= this.grid.width || y >= this.grid.height) return;
    this.grid.set(x, y, this.isPainting ? 1 : 0);
    this.updateStats();
  }

  loop(ts) {
    requestAnimationFrame(t => this.loop(t));

    // FPS
    this.frameCount++;
    if (ts - this.fpsTime >= 1000) {
      this.fps = this.frameCount * 1000 / (ts - this.fpsTime);
      this.frameCount = 0;
      this.fpsTime = ts;
      document.getElementById('stat-fps').textContent = this.fps.toFixed(1);
    }

    if (this.running) {
      const interval = 1000 / this.speed;
      if (ts - this.lastStep >= interval) {
        this.lastStep = ts;
        this.doStep();
      }
    }

    this.renderer.render();
  }
}

// Single app entry point
const app = new App();
