// renderer.js — Canvas2D rendering with zoom, pan, overlays

export class Renderer {
  constructor(canvas, grid) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.grid = grid;

    // Viewport
    this.cellSize = 10;
    this.offsetX = 0;
    this.offsetY = 0;

    // Options
    this.showGrid = true;
    this.showNeighborCounts = false;
    this.showChanges = true;

    // Changed cells from last step (for highlighting)
    this.changedCells = [];
    this.changeFrames = 0; // countdown frames to show highlights

    // Ghost pattern for placement preview
    this.ghostPattern = null;
    this.ghostX = -1;
    this.ghostY = -1;

    // Hover cell
    this.hoverX = -1;
    this.hoverY = -1;

    // Colors
    this.colors = {
      bg: '#0d1117',
      cell: '#39d353',
      gridLine: '#1e2a1e',
      born: '#00ff88',
      died: '#ff4444',
      ghost: 'rgba(100,200,255,0.4)',
      hoverBg: 'rgba(255,255,255,0.08)',
      neighborText: '#ffffff',
      neighborTextDark: '#88ff88',
    };
  }

  resize() {
    const dpr = window.devicePixelRatio || 1;
    const rect = this.canvas.getBoundingClientRect();
    this.canvas.width = rect.width * dpr;
    this.canvas.height = rect.height * dpr;
    this.ctx.scale(dpr, dpr);
    this.logicalW = rect.width;
    this.logicalH = rect.height;
  }

  fitToView() {
    const scaleX = this.logicalW / this.grid.width;
    const scaleY = this.logicalH / this.grid.height;
    this.cellSize = Math.max(2, Math.floor(Math.min(scaleX, scaleY)));
    this.offsetX = Math.floor((this.logicalW - this.cellSize * this.grid.width) / 2);
    this.offsetY = Math.floor((this.logicalH - this.cellSize * this.grid.height) / 2);
  }

  // Convert screen coords to grid coords
  screenToGrid(sx, sy) {
    const gx = Math.floor((sx - this.offsetX) / this.cellSize);
    const gy = Math.floor((sy - this.offsetY) / this.cellSize);
    return { x: gx, y: gy };
  }

  gridToScreen(gx, gy) {
    return {
      x: this.offsetX + gx * this.cellSize,
      y: this.offsetY + gy * this.cellSize
    };
  }

  zoom(factor, cx, cy) {
    const oldSize = this.cellSize;
    this.cellSize = Math.max(2, Math.min(64, this.cellSize * factor));
    // Zoom toward cursor
    this.offsetX = cx - (cx - this.offsetX) * (this.cellSize / oldSize);
    this.offsetY = cy - (cy - this.offsetY) * (this.cellSize / oldSize);
  }

  pan(dx, dy) {
    this.offsetX += dx;
    this.offsetY += dy;
  }

  setChangedCells(cells) {
    this.changedCells = cells;
    this.changeFrames = 8;
  }

  render() {
    const ctx = this.ctx;
    const w = this.logicalW, h = this.logicalH;

    ctx.fillStyle = this.colors.bg;
    ctx.fillRect(0, 0, w, h);

    const cs = this.cellSize;
    const gw = this.grid.width, gh = this.grid.height;

    // Visible cell range
    const x0 = Math.max(0, Math.floor(-this.offsetX / cs));
    const y0 = Math.max(0, Math.floor(-this.offsetY / cs));
    const x1 = Math.min(gw - 1, Math.ceil((w - this.offsetX) / cs));
    const y1 = Math.min(gh - 1, Math.ceil((h - this.offsetY) / cs));

    // Build change map for fast lookup
    const changeMap = new Map();
    if (this.changeFrames > 0) {
      for (const c of this.changedCells) {
        changeMap.set(c.y * gw + c.x, c);
      }
    }

    // Draw cells
    for (let gy = y0; gy <= y1; gy++) {
      for (let gx = x0; gx <= x1; gx++) {
        const alive = this.grid.get(gx, gy);
        const sx = this.offsetX + gx * cs;
        const sy = this.offsetY + gy * cs;
        const key = gy * gw + gx;
        const change = changeMap.get(key);

        if (alive) {
          if (change && change.prev === 1 && change.next === 0) {
            // dying this frame — shown as alive still (highlight will show it dying)
          }
          ctx.fillStyle = this.colors.cell;
          ctx.fillRect(sx + 0.5, sy + 0.5, cs - 1, cs - 1);
        }

        // Highlight changes
        if (change && this.showChanges && this.changeFrames > 0) {
          const alpha = this.changeFrames / 8;
          if (change.next === 1) {
            // born
            ctx.fillStyle = `rgba(0,255,136,${alpha * 0.7})`;
            ctx.fillRect(sx + 0.5, sy + 0.5, cs - 1, cs - 1);
            if (cs >= 10) {
              ctx.strokeStyle = `rgba(0,255,136,${alpha})`;
              ctx.lineWidth = 1.5;
              ctx.strokeRect(sx + 1, sy + 1, cs - 2, cs - 2);
            }
          } else {
            // died
            ctx.fillStyle = `rgba(255,68,68,${alpha * 0.5})`;
            ctx.fillRect(sx + 0.5, sy + 0.5, cs - 1, cs - 1);
            if (cs >= 10) {
              ctx.strokeStyle = `rgba(255,68,68,${alpha})`;
              ctx.lineWidth = 1.5;
              ctx.strokeRect(sx + 1, sy + 1, cs - 2, cs - 2);
            }
          }
        }
      }
    }

    // Grid lines
    if (this.showGrid && cs >= 6) {
      ctx.strokeStyle = this.colors.gridLine;
      ctx.lineWidth = 0.5;
      ctx.beginPath();
      for (let gx = x0; gx <= x1 + 1; gx++) {
        const sx = this.offsetX + gx * cs;
        ctx.moveTo(sx, this.offsetY + y0 * cs);
        ctx.lineTo(sx, this.offsetY + (y1 + 1) * cs);
      }
      for (let gy = y0; gy <= y1 + 1; gy++) {
        const sy = this.offsetY + gy * cs;
        ctx.moveTo(this.offsetX + x0 * cs, sy);
        ctx.lineTo(this.offsetX + (x1 + 1) * cs, sy);
      }
      ctx.stroke();
    }

    // Neighbor count overlay
    if (this.showNeighborCounts && cs >= 12) {
      ctx.font = `bold ${Math.max(8, cs * 0.45)}px 'Courier New', monospace`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      for (let gy = y0; gy <= y1; gy++) {
        for (let gx = x0; gx <= x1; gx++) {
          const n = this.grid.countNeighbors(gx, gy);
          if (n === 0) continue;
          const sx = this.offsetX + gx * cs + cs / 2;
          const sy = this.offsetY + gy * cs + cs / 2;
          const alive = this.grid.get(gx, gy);
          ctx.fillStyle = alive ? '#003300' : this.colors.neighborTextDark;
          ctx.fillText(n, sx, sy);
        }
      }
    }

    // Hover highlight
    if (this.hoverX >= 0 && this.hoverY >= 0) {
      const sx = this.offsetX + this.hoverX * cs;
      const sy = this.offsetY + this.hoverY * cs;
      ctx.fillStyle = this.colors.hoverBg;
      ctx.fillRect(sx, sy, cs, cs);
      if (cs >= 6) {
        ctx.strokeStyle = 'rgba(255,255,255,0.3)';
        ctx.lineWidth = 1;
        ctx.strokeRect(sx + 0.5, sy + 0.5, cs - 1, cs - 1);
      }
    }

    // Ghost pattern
    if (this.ghostPattern && this.ghostX >= 0) {
      const pg = this.ghostPattern;
      const ph = pg.length, pw = pg[0]?.length || 0;
      const ox = this.ghostX - Math.floor(pw / 2);
      const oy = this.ghostY - Math.floor(ph / 2);
      for (let py = 0; py < ph; py++) {
        for (let px = 0; px < pw; px++) {
          if (!pg[py][px]) continue;
          const gx = ox + px, gy = oy + py;
          const sx = this.offsetX + gx * cs;
          const sy = this.offsetY + gy * cs;
          ctx.fillStyle = this.colors.ghost;
          ctx.fillRect(sx + 0.5, sy + 0.5, cs - 1, cs - 1);
          ctx.strokeStyle = 'rgba(100,200,255,0.8)';
          ctx.lineWidth = 1;
          ctx.strokeRect(sx + 0.5, sy + 0.5, cs - 1, cs - 1);
        }
      }
    }

    // Grid boundary
    ctx.strokeStyle = '#2a4a2a';
    ctx.lineWidth = 1;
    ctx.strokeRect(this.offsetX, this.offsetY, gw * cs, gh * cs);

    if (this.changeFrames > 0) this.changeFrames--;
  }
}
