# Conway's Game of Life in LuaLaTeX

## What is LuaLaTeX?

LaTeX is a **document preparation system** built on top of TeX, Donald Knuth's typesetting engine from 1978. Its purpose is to produce publication-quality PDFs: academic papers, books, dissertations, mathematical formulae, and technical reports. You write structured markup describing content and formatting, and LaTeX compiles it into a precisely typeset document. It is the standard authoring tool for mathematics, physics, and computer science publications.

**LuaLaTeX** is a modern LaTeX engine that embeds a full Lua interpreter inside the TeX compilation process. This means you can write Lua code directly in a `.tex` source file — and that Lua code runs during compilation, with the ability to emit LaTeX commands on the fly. LuaLaTeX was designed for tasks like generating complex tables, processing font metrics, and dynamically constructing mathematical structures. It was not designed for simulating cellular automata.

**TikZ** (`\usepackage{tikz}`) is a LaTeX package for programmatic vector graphics. It can draw lines, rectangles, circles, and filled regions directly on a PDF page, described in coordinates. It is what the Game of Life implementation uses to draw the grid.

---

## How the Implementation Works

### The Core Idea: A PDF Flip-Book

Each page of the generated PDF is one generation of the Game of Life. Page 1 is generation 0, page 2 is generation 1, …, page 51 is generation 50. Flipping through the PDF rapidly produces an animation — a digital flip-book.

```
┌───────┐  ┌───────┐  ┌───────┐
│ Gen 0 │  │ Gen 1 │  │ Gen 2 │  ...
│       │  │       │  │       │
└───────┘  └───────┘  └───────┘
  Page 1     Page 2     Page 3
```

### The Lua Layer: Simulation Logic

All simulation logic is written in Lua inside a `\begin{luacode*}…\end{luacode*}` block. LuaLaTeX executes this code at compile time, before any typesetting occurs:

```lua
local rows, cols = 30, 50
math.randomseed(os.time())   -- seed with current time for varied patterns

function init_random(prob)
    local grid = {}
    for i = 1, rows do
        grid[i] = {}
        for j = 1, cols do
            grid[i][j] = (math.random() < prob) and 1 or 0
        end
    end
    return grid
end
```

Unlike jq or OpenSCAD, Lua is a complete general-purpose language with mutable state, genuine loops, real random numbers, and a standard library. The Game of Life logic (`evolve`, `get_cell`) is entirely standard Lua — clean, readable, and idiomatic:

```lua
function get_cell(state, i, j)
    local i_wrapped = ((i - 1) % rows) + 1    -- 1-based toroidal wrap
    local j_wrapped = ((j - 1) % cols) + 1
    return state[i_wrapped][j_wrapped]
end

function evolve(state)
    local new_state = {}
    for i = 1, rows do
        new_state[i] = {}
        for j = 1, cols do
            local neighbors = 0
            for di = -1, 1 do
                for dj = -1, 1 do
                    if not (di == 0 and dj == 0) then
                        neighbors = neighbors + get_cell(state, i + di, j + dj)
                    end
                end
            end
            if state[i][j] == 1 then
                new_state[i][j] = (neighbors == 2 or neighbors == 3) and 1 or 0
            else
                new_state[i][j] = (neighbors == 3) and 1 or 0
            end
        end
    end
    return new_state
end
```

### The Drawing Function: Emitting TikZ from Lua

The key to LuaLaTeX's power is `tex.sprint()` — a Lua function that injects arbitrary text directly into the TeX input stream. The `draw_gameoflife` function builds a complete TikZ picture as a Lua string and injects it into LaTeX:

```lua
function draw_gameoflife(iter, state)
    if iter > 0 then state = evolve(state) end

    local cellWidth  = paperWidth  / cols * 0.988
    local cellHeight = paperHeight / rows * 0.999

    local code = {}
    table.insert(code, "\\begin{tikzpicture}[x=1pt,y=1pt]")

    for i = 1, rows do
        for j = 1, cols do
            local x = (j - 1) * cellWidth
            local y = (i - 1) * cellHeight
            -- Draw the cell border in grey
            table.insert(code, string.format(
                "\\draw[gray] (%.2f,%.2f) rectangle ++(%.2fpt,%.2fpt);",
                x, y, cellWidth, cellHeight))
            -- Fill live cells black
            if state[i][j] == 1 then
                table.insert(code, string.format(
                    "\\fill[black] (%.2f,%.2f) rectangle ++(%.2fpt,%.2fpt);",
                    x, y, cellWidth, cellHeight))
            end
        end
    end

    table.insert(code, "\\end{tikzpicture}")
    tex.sprint(table.concat(code, ""))
    return state
end
```

The cell size is computed to fill the entire A5 landscape page (210 mm × 148 mm), with slight reduction factors (0.988, 0.999) to prevent the grid from bleeding past the paper edges due to floating-point rounding.

### The LaTeX Layer: Page Generation Loop

The LaTeX `\document` body is minimal — it just initialises the grid and loops over 51 frames:

```latex
\directlua{state = init_random(0.2)}

\foreach \i in {0,...,50}{
    \noindent\directlua{state = draw_gameoflife(\i, state)}
    \newpage
}
```

`\foreach` is provided by the `pgffor` package. `\directlua{…}` executes Lua code inline and allows it to return a LaTeX value or — as here — to call `tex.sprint()` to inject generated markup. The `state` variable persists across `\directlua` calls within the same compilation because it lives in the shared Lua environment.

The result: a 51-page A5 landscape PDF where every page is a rendered generation, and flipping pages advances the simulation.

---

## Is LuaLaTeX Good, Bad, or Ugly for Game of Life?

### 🟡 Verdict: Beautifully Wrong

LuaLaTeX is simultaneously the most absurd and the most charming implementation in this repository. It produces a physically real artefact — a printable document — rather than a terminal animation. That makes it uniquely tangible.

**Why it is wrong:**

- **The output is a PDF.** Game of Life is an animation. PDFs are for reading. The only way to "animate" this is to flip through the pages manually, use a PDF viewer with auto-advance, or convert the pages to a GIF externally.
- **Compilation takes real time.** LaTeX must typeset every page in full — drawing thousands of TikZ rectangles for each of 51 generations. This is far slower than rendering to the terminal.
- **No runtime loop.** Like OpenSCAD, the "animation" is baked into a static document at compile time. There is no interactivity and no way to run it indefinitely.
- **LaTeX's purpose is typography.** Using it to draw 1,500 rectangles per page in a flip-book is a spectacular misuse of a tool that was designed to set beautiful mathematical equations.

**Why it is compelling:**

- **Lua is genuinely good for this.** The simulation logic (in Lua) is clean, idiomatic, and easy to read. Lua was designed as an embedded scripting language for exactly this kind of host-application integration.
- **TikZ is exactly the right tool** for drawing a grid of rectangles at precise coordinates. It is powerful, expressive, and produces pixel-perfect output. For a different rendering problem — say, a Voronoi diagram or a fractal — this approach would be entirely appropriate.
- **The output is beautiful.** A printed Game of Life flip-book, with crisp black cells on a white background in a precise A5 grid, is aesthetically remarkable. No other implementation in this repository produces a physically printable artefact.
- **`tex.sprint()` is a genuinely powerful technique.** Generating LaTeX programmatically from Lua at compile time is the correct way to produce complex documents with dynamic content — tables driven by data files, charts generated from calculations, diagrams derived from input parameters.

**What is actually good:**

The LuaLaTeX approach shines for generating **complex, data-driven documents**: typesetting a table of 10,000 rows from a CSV file, drawing a circuit diagram from a netlist, or producing a mathematical reference book where every formula is computed. Game of Life happens to fit the "programmatic grid of shapes" sub-problem neatly. The implementation demonstrates that LuaLaTeX is a surprisingly capable computation environment hiding inside a document compiler.

---

## Typical Use Cases for LuaLaTeX

LuaLaTeX and TikZ are the right tools when:

- The output is a **high-quality PDF** for printing or publication.
- The document contains **programmatically generated content**: computed tables, algorithmic diagrams, parametric figures.
- **Mathematical typesetting** is required — equations, theorems, proofs, symbols.
- The document must be **reproducible from source** in version control.

**Classic LuaLaTeX / LaTeX use cases:**

| Domain | Example |
|--------|---------|
| Academia | Research papers, theses, and journal articles with mathematical content |
| Books | Textbooks, reference manuals, and technical books with consistent formatting |
| Presentations | Beamer slide decks for academic and technical presentations |
| Data visualisation | PGFPlots for charts and graphs embedded directly in documents |
| Engineering | Circuit diagrams (Circuitikz), timing diagrams, architecture drawings |
| Dynamic documents | Documents where content is generated by Lua from external data files |

What LaTeX is **not** designed for: interactive applications, terminal output, continuous simulation, or anything that runs after the compilation step is complete. The Game of Life PDF is frozen at compile time — change the initial seed, recompile, get a different frozen 51-generation document.

---

## Further Reading

- [LuaLaTeX documentation](https://www.luatex.org/documentation.html) — the official LuaTeX reference
- [The TikZ & PGF Manual](https://tikz.dev/) — the comprehensive guide to programmatic graphics in LaTeX
- [The `luacode` package](https://ctan.org/pkg/luacode) — cleaner interface for embedding Lua in LaTeX
- [The `pgffor` package](https://ctan.org/pkg/pgf) — the `\foreach` loop used for page generation
- [Overleaf LuaLaTeX guide](https://www.overleaf.com/learn/latex/LuaLaTeX) — practical introduction to Lua scripting in LaTeX
- [The generated PDF](https://simonwaldherr.github.io/GameOfLife/cgol.lualatex.pdf) — view the actual flip-book output from this repository
