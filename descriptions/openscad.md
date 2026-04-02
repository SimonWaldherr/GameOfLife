# Conway's Game of Life in OpenSCAD

## What is OpenSCAD?

OpenSCAD is a **script-based 3D CAD modelling language** designed for creating solid geometry. Unlike interactive modelling tools (Blender, FreeCAD), OpenSCAD is a *programmer's CAD tool*: you describe geometry with code, and the engine compiles that description into a 3D solid. It is the language of choice whenever a 3D object must be parametric — gears with adjustable tooth count, enclosures that adapt to PCB dimensions, brackets that scale with a single variable.

OpenSCAD's computational model is essentially **functional and declarative**: there are no mutable variables, no loops with side-effects, and no I/O. The language provides list-comprehensions, recursion, and module calls, all evaluated at compile time to produce a static scene. It was never designed to simulate anything.

---

## How the Implementation Works

### Files

| File | Purpose |
|------|---------|
| `cgol.scad` | Core simulation logic — computes any generation from the hard-coded seed and renders it as 3D cubes |
| `cgol_animation.scad` | Preview-friendly variant that uses OpenSCAD's built-in `$t` animation variable to cycle through generations inside the GUI |
| `cgol.scad.sh` | Bash driver script that calls `openscad` once per generation, collects PNG frames, and stitches them into an animated GIF with ImageMagick |

### The Functional Core (`cgol.scad`)

The entire simulation is expressed as a chain of **pure functions** operating on immutable 2D arrays:

```openscad
// Count the 8 neighbours of cell (x, y) with toroidal wrap-around
function count_neighbors(grid, x, y) =
    grid[(y-1 + height) % height][(x-1 + width) % width] + ...;

// Apply Conway's rules to every cell and return a new grid
function next_grid(grid) =
    [ for (y = [0:height-1]) [
        for (x = [0:width-1]) (
            (grid[y][x] == 1 && (count_neighbors(grid, x, y) == 2 ||
                                  count_neighbors(grid, x, y) == 3)) ||
            (grid[y][x] == 0 && count_neighbors(grid, x, y) == 3) ? 1 : 0
        )
    ]];

// Recursively advance n generations
function compute_generation(grid, n) =
    n == 0 ? grid : compute_generation(next_grid(grid), n-1);
```

Because OpenSCAD has no runtime loop, the only way to reach generation *N* is to call `compute_generation` *N* times recursively. OpenSCAD evaluates this at **compile time**; the entire call stack for `gen=25` is resolved before a single pixel is drawn.

### Overriding the Generation at the Command Line

The variable `gen` is declared at the top of the file and can be overridden with `-D`:

```bash
openscad -o gen07.png -Dgen=7 cgol.scad
```

This is the hook the shell script exploits to render a sequence of frames without modifying the source file.

### Rendering

Once `current_grid` is computed, the `render_grid` module walks every cell and, for each live cell, places a unit cube:

```openscad
module render_grid(g) {
    for (y = [0:height-1])
        for (x = [0:width-1])
            if (g[y][x] == 1)
                translate([x, y, 0]) cube([1,1,1], center=false);
}
```

The result is a flat 3D landscape of standing cubes — a Game of Life generation viewed from above. Exported as a PNG via OpenSCAD's headless renderer, each frame looks like a top-down pixel art image.

### The Animation Loop (`cgol.scad.sh`)

The shell script is the only place a real loop exists:

```bash
for ((gen=0; gen<=GEN_MAX; gen++)); do
    openscad -o "frames/gen$(printf '%03d' $gen).png" -Dgen="$gen" cgol.scad
done
convert -delay 20 -loop 0 frames/gen*.png cgol.gif
```

Each invocation of `openscad` computes the full call chain from generation 0 to the requested generation. Generation 25 therefore recomputes generations 0–24 as intermediate results; there is no caching between invocations.

### `cgol_animation.scad` — The GUI Preview Variant

OpenSCAD's GUI has a built-in animation feature driven by the special variable `$t`, which sweeps from 0.0 to 1.0 over a configurable number of steps. `cgol_animation.scad` maps `$t` to a generation index:

```openscad
gen_idx = floor($t * fps) % max_steps;
current  = gen_at(gen0, gen_idx);
```

This lets you watch the simulation evolve inside the OpenSCAD preview window without any external tooling — at the cost of re-evaluating every previous generation on every frame refresh.

---

## Is OpenSCAD Good, Bad, or Ugly for Game of Life?

### 🟡 Verdict: Wonderfully Ugly

OpenSCAD is a spectacular mismatch for a simulation task, yet it works — which is precisely what makes it fascinating.

**Why it is ugly:**

- **No loops, no mutable state.** Every generation must be computed by recursive function calls resolved at compile time. OpenSCAD is not Turing-complete at runtime; it is a geometry compiler.
- **Exponential re-computation.** Computing generation *N* re-evaluates all *N* predecessor generations. This is not a quirk you can optimize away; it is the only model OpenSCAD offers.
- **No terminal output.** The "display" is a PNG exported by a headless CAD renderer. Viewing the animation requires either an external GIF assembler or the GUI's animation mode.
- **Grid hardcoded as a literal.** Because OpenSCAD has no file I/O and no runtime randomness, the initial state must be a literal 2D array written directly in the source. There is no way to seed it randomly at runtime.

**Why it works anyway:**

- OpenSCAD's **list comprehensions** and **recursive functions** are genuinely expressive for this kind of grid transformation. The code is surprisingly readable.
- The `for`-in-comprehension syntax maps almost 1:1 onto the mathematical definition of Conway's rules.
- The `-D` override mechanism provides a clean way to parameterise frames without any runtime I/O.
- The output — 3D cubes on a flat plane — is visually striking and unique among all implementations in this repository.

**What is actually good:**

The `cgol.scad` source demonstrates an important property of OpenSCAD: **pure functional programming over arrays**. For generating parametric geometry driven by mathematical rules (Penrose tiling, fractal structures, space-filling curves), OpenSCAD's model is elegant. Game of Life just happens to map cleanly onto that model as well.

---

## Typical Use Cases for OpenSCAD

OpenSCAD excels at problems where:

- The geometry must be **parametric** — adjust one constant and the whole model updates.
- The design must be **reproducible and version-controlled** as source code.
- The output is a **3D solid** for 3D printing, CNC milling, or laser cutting.

**Classic OpenSCAD projects:**

| Domain | Example |
|--------|---------|
| 3D printing | Custom enclosures, brackets, and mounts parameterised by measured dimensions |
| Mechanical parts | Gears, pulleys, and threaded inserts with adjustable pitch and tooth count |
| Electronics | PCB standoffs, DIN-rail clips, and panel cutouts driven by datasheet specs |
| Mathematical art | Voronoi diagrams, Lissajous curves, polyhedra, and space-filling solids |
| Maker/DIY | Phone stands, cable organisers, drawer dividers generated from user-supplied measurements |

What OpenSCAD is **not** designed for: animation, simulation, data processing, user interaction, or anything requiring I/O at runtime. Game of Life stretches it into all of these areas simultaneously — which is why it is one of the most memorable implementations in this repository.

---

## Further Reading

- [OpenSCAD User Manual](https://openscad.org/documentation.html)
- [OpenSCAD Cheat Sheet](https://openscad.org/cheatsheet/)
- [The OpenSCAD Language Reference](https://openscad.org/documentation.html#language-reference)
- [Thingiverse — OpenSCAD tag](https://www.thingiverse.com/tag:openscad) for real-world parametric designs
