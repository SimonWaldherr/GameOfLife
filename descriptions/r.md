# Conway's Game of Life in R

## What is R?

R is a **statistical computing and graphics language** created in 1993 by Ross Ihaka and Robert Gentleman at the University of Auckland, inspired by the S language from Bell Labs. Its primary purpose is data analysis, statistical modelling, and visualisation. R is the dominant language in academic statistics, biostatistics, and data science — it has a package ecosystem (CRAN) of over 20,000 packages covering every statistical method known to science.

R's computational model is built around **vectorised operations on matrices and data frames**. Where other languages iterate over elements explicitly, R applies functions to entire arrays at once: `sqrt(x)` takes the square root of every element in the vector `x`, and `x[x > 5]` filters to elements greater than 5 — no loops required. This design makes statistical computations concise and fast when operations are vectorised, but it can produce surprising performance when code falls back to explicit loops.

R is not a general-purpose programming language in the tradition of Python or Java. It does not have a rich standard library for systems programming, networking, or terminal control. It was designed for interactive data analysis sessions, not for building applications.

---

## How the Implementation Works

### Initialisation with `matrix()` and `runif()`

R's matrix type is a first-class citizen of the language. The grid is initialised in one expression:

```r
width   <- 50
height  <- 30
density <- 0.2

initializeGrid <- function() {
    matrix(runif(width * height) < density, nrow = height, ncol = width)
}
```

`runif(n)` generates `n` uniform random numbers in [0, 1). Comparing the vector against `density` produces a logical vector of `TRUE`/`FALSE` values. `matrix(…, nrow=height, ncol=width)` reshapes it into a 2D matrix. The entire operation is three function calls with no explicit loop — this is idiomatic R.

The matrix is stored as **logical** (`TRUE`/`FALSE`) rather than integer (1/0), which is more natural in R but requires slight care in `printGrid` and `computeNextState` when treating live cells as numbers.

### Neighbour Counting with `expand.grid()`

R's `expand.grid()` generates the Cartesian product of its arguments as a data frame. The implementation uses it to enumerate the eight neighbour offsets:

```r
countNeighbors <- function(grid, x, y) {
    shifts <- expand.grid(dx = -1:1, dy = -1:1)
    shifts <- shifts[!(shifts$dx == 0 & shifts$dy == 0), ]   # remove (0,0)

    count <- 0
    for (i in 1:nrow(shifts)) {
        nx <- (x + shifts$dx[i] - 1) %% width  + 1   # 1-based toroidal wrap
        ny <- (y + shifts$dy[i] - 1) %% height + 1
        if (grid[ny, nx]) count <- count + 1
    }
    return(count)
}
```

`expand.grid(dx = -1:1, dy = -1:1)` produces a 9-row data frame with all `(dx, dy)` pairs in `{-1, 0, 1}²`. Removing the row where both are zero leaves the eight true neighbours. The wrap-around uses R's `%%` operator, with the `(x - 1) %% width + 1` pattern to convert between 0-based modular arithmetic and R's 1-based indexing.

Although `expand.grid` is elegant for generating the offset table, the inner loop over `nrow(shifts)` still iterates eight times per cell. A fully vectorised implementation would eliminate this loop, but this version prioritises readability.

### Rule Application in `computeNextState()`

```r
computeNextState <- function(grid) {
    newGrid <- matrix(FALSE, nrow = height, ncol = width)

    for (y in 1:height) {
        for (x in 1:width) {
            alive     <- grid[y, x]
            neighbors <- countNeighbors(grid, x, y)

            # (alive && 2 neighbours) OR (3 neighbours) → live
            newGrid[y, x] <- (alive && neighbors == 2) || neighbors == 3
        }
    }
    return(newGrid)
}
```

The rule `(alive && neighbors == 2) || neighbors == 3` is a compact boolean expression of Conway's rules:
- A live cell with exactly 2 neighbours survives (`alive && neighbors == 2`).
- Any cell (live or dead) with exactly 3 neighbours is alive (`neighbors == 3`), which covers both survival-with-3 and birth-with-3 in one clause.

This is correct but relies on understanding that `neighbors == 3` already covers the live-with-3-neighbours survival case. It is concise and idiomatic R.

### Rendering and Terminal Control

```r
printGrid <- function(grid) {
    for (y in 1:height) {
        for (x in 1:width) {
            cat(if (grid[y, x]) "█" else " ")
        }
        cat("\n")
    }
}
```

R uses `cat()` for raw output (no quoting or newline appended by default). The display loop iterates over every cell, printing a block character for live cells and a space for dead cells.

The animation loop uses `Sys.sleep()` (R's standard sleep function) and ANSI escape sequences for screen clearing:

```r
grid <- initializeGrid()
repeat {
    printGrid(grid)
    grid <- computeNextState(grid)
    Sys.sleep(0.1)
    cat("\033[H\033[2J")   # move cursor to top-left and clear screen
}
```

`repeat { … }` is R's infinite loop construct. The `cat("\033[H\033[2J")` sequence is the standard ANSI clear-screen command. R has no built-in terminal cursor-control library, so raw escape codes are the only portable option.

---

## Is R Good, Bad, or Ugly for Game of Life?

### 🟡 Verdict: A Missed Opportunity — Good Primitives, Underused

R has everything needed to write Game of Life efficiently — matrices, vectorised operations, logical indexing — but the implementation does not fully exploit them, falling back to explicit nested loops for the core computation. The result is idiomatic in some places and un-idiomatic in others.

**Why it falls short:**

- **Nested loops are slow in R.** R is an interpreted language with significant per-operation overhead when iterating element-by-element in R code. Calling `countNeighbors` 1,500 times per generation, each making 8 individual `grid[ny, nx]` accesses, is far slower than a vectorised operation. A fully vectorised version using matrix shifts and `Reduce` would run 10–100× faster.
- **No terminal graphics library.** R has no built-in support for ANSI escape sequences, cursor control, or terminal animation. The raw `cat("\033[…]")` calls work but are fragile and non-portable to non-ANSI terminals (e.g., Windows Command Prompt).
- **`Sys.sleep()` granularity.** On some platforms R's sleep is not highly precise at sub-100ms intervals, which can cause the animation to stutter.
- **Designed for interactive use.** Running R in a non-interactive terminal script (`Rscript`) works, but R's real home is an interactive session (RStudio, Jupyter). The simulation loop never returns control to the REPL — it just runs forever.

**Why it works and has good bones:**

- **Matrix initialisation** (`matrix(runif(n) < density, …)`) is a single vectorised expression — exactly how R should be used.
- **`expand.grid()`** for generating the neighbour offset table is clever and idiomatic. It is the kind of trick that R programmers reach for naturally.
- **Logical matrix indexing** means the `TRUE`/`FALSE` cell states can participate directly in boolean expressions without explicit conversion.
- The **rule expression** `(alive && neighbors == 2) || neighbors == 3` is compact and reads clearly.

**What a fully idiomatic R version would look like:**

The standard vectorised approach uses eight shifted copies of the matrix (one per neighbour direction), applies wrap-around with `rbind`/`cbind`, sums them to get a neighbour-count matrix, and computes the next generation with a single logical expression — no loops at all. That version would run in milliseconds per generation, but it would be less legible to someone learning R for the first time.

---

## Typical Use Cases for R

R excels when:

- The task is **statistical analysis** — hypothesis testing, regression, Bayesian inference.
- The data fits in **memory as matrices or data frames**.
- **Visualisation** is a goal — R's `ggplot2` and base graphics are among the best data visualisation tools available.
- The audience includes **statisticians and domain scientists** who know R but may not know Python or Java.
- **Reproducible research** is required — R Markdown and Quarto produce literate documents combining code, output, and narrative.

**Classic R use cases:**

| Domain | Example |
|--------|---------|
| Statistics | Linear models, mixed-effects models, survival analysis, ANOVA |
| Bioinformatics | Gene expression analysis (Bioconductor), phylogenetics, sequence analysis |
| Social science | Survey analysis, econometrics, psychometrics |
| Data visualisation | Publication-quality charts and plots with `ggplot2` |
| Machine learning | `caret`, `tidymodels`, and `mlr3` for model training and evaluation |
| Actuarial science | Risk modelling, premium calculation, claims analysis |
| Epidemiology | Disease modelling (R was heavily used for COVID-19 modelling), survival curves |

What R is **not** well-suited for: systems programming, applications with user interfaces, long-running server processes, or anything requiring tight control of performance. Game of Life falls awkwardly into R's domain — it involves matrix operations (R's strength) but also real-time animation and iteration (R's weakness). The implementation works, but it is not the showcase of R's capabilities that a vectorised solution would be.

---

## Further Reading

- [R for Data Science (2nd ed.)](https://r4ds.hadley.nz/) — Hadley Wickham's authoritative introduction to data analysis in R
- [Advanced R](https://adv-r.hadley.nz/) — deep dive into R's internals, performance, and metaprogramming
- [The Art of R Programming](https://nostarch.com/artofr.htm) — Norman Matloff's introduction to R as a programming language
- [Bioconductor](https://bioconductor.org/) — R packages for bioinformatics, one of R's flagship ecosystems
- [Efficient R Programming](https://csgillespie.github.io/efficientR/) — practical guide to making R code fast, including vectorisation techniques relevant to a Game of Life implementation
