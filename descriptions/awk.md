# Conway's Game of Life in AWK

## What is AWK?

AWK is a **text-processing programming language** created in 1977 at Bell Labs by Alfred Aho, Peter Weinberger, and Brian Kernighan (the three initials form the name). It was designed to process structured text files by applying *pattern–action rules*: for each line of input that matches a pattern, execute the corresponding action block. The canonical AWK program counts word frequencies, reformats CSV fields, or filters log lines matching a regular expression.

AWK's core data structure is the **associative array** — a hash map with string keys. There are no typed arrays, no structs, and no objects. Input is read line-by-line, split on a field separator, and processed one record at a time. AWK programs tend to be short; a typical real-world AWK script is a one-liner.

It was designed for processing log files and reports, not for simulating cellular automata.

---

## How the Implementation Works

### A `BEGIN`-Only Program

A standard AWK program has the form:

```
/pattern/ { action }   # run action on every matching input line
BEGIN     { action }   # run once before any input is read
END       { action }   # run once after all input is consumed
```

Because Game of Life reads no input file — it generates its own data and loops forever — the entire implementation lives inside the `BEGIN` block. AWK is invoked, it enters `BEGIN`, and it never reads a single line of stdin.

```awk
BEGIN {
    width = 50
    height = 30
    density = 0.2
    srand()
    # ... initialise grid, enter infinite loop
    while (1) {
        print_grid()
        compute_next_state()
        # swap and repeat
    }
}
END {
    printf "\033[?25h"   # restore cursor on exit
}
```

The `END` block is the only other active section — it restores the terminal cursor when the program is interrupted.

### Flattening the 2D Grid into a 1D Associative Array

AWK has no 2D arrays. The grid is stored in a single associative array using a linearised index:

```awk
idx = y * width + x
grid[idx] = (rand() < density) ? 1 : 0
```

This is a classical C-style layout: row `y`, column `x` maps to index `y * width + x`. The same formula is used everywhere — initialisation, display, neighbour counting, and update — so it is consistent even if slightly less readable than a true 2D structure.

### Neighbour Counting with Toroidal Wrap-Around

```awk
function compute_next_state(   x, y, idx, dx, dy, nx, ny, nidx, count) {
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            count = 0
            for (dx = -1; dx <= 1; dx++) {
                for (dy = -1; dy <= 1; dy++) {
                    if (dx == 0 && dy == 0) continue
                    nx = (x + dx + width)  % width
                    ny = (y + dy + height) % height
                    nidx = ny * width + nx
                    count += grid[nidx]
                }
            }
            if ((grid[idx] == 1 && (count == 2 || count == 3)) ||
                (grid[idx] == 0 && count == 3))
                new_grid[idx] = 1
            else
                new_grid[idx] = 0
        }
    }
}
```

The toroidal wrap uses the standard `(x + dx + width) % width` trick. After computing `new_grid`, the main loop copies it back into `grid` with a `for (i in new_grid)` iteration and then calls `delete new_grid` to free it for the next generation.

Note the unusual function signature: AWK has no local variable declarations, so extra function parameters (`x, y, idx, dx, dy, nx, ny, nidx, count`) serve as local variables by convention — they are listed with extra spaces to signal that they are locals, not meaningful parameters.

### Sleeping Without `sleep()`

AWK has no built-in `sleep` function. The implementation shells out:

```awk
system("sleep 0.1")
```

This spawns a child process for every frame — about ten child processes per second. It is inefficient, but it works on every POSIX system without requiring a `gawk`-specific extension. Some AWK dialects (e.g., GNU AWK with `--sandbox` or mawk) would forbid or lack `system()` entirely.

### Rendering

```awk
function print_grid(   output, y, x, idx) {
    output = ""
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            idx = y * width + x
            output = output (grid[idx] == 1 ? "█" : " ")
        }
        output = output "\n"
    }
    printf "%s", output
}
```

String concatenation (`output = output "..."`) builds the entire frame as one string before printing it in a single `printf` call, which reduces the number of write syscalls and avoids flickering.

---

## Is AWK Good, Bad, or Ugly for Game of Life?

### 🟢 Verdict: Surprisingly Adequate

AWK is one of the cleaner implementations in this repository, despite being a text-processing tool. The mismatch between AWK's intended purpose and Game of Life is smaller than it first appears.

**Why it fits reasonably well:**

- **Associative arrays** are flexible enough to represent a grid — the linearisation is a minor inconvenience, not a fundamental obstacle.
- **No type system** means there is no friction around storing integers in the grid array; AWK just stores them.
- AWK **functions** are first-class citizens of the language, making the `print_grid` / `compute_next_state` split clean and idiomatic.
- AWK **already lives in the shell**. Driving animation from AWK feels natural; it is a shell tool by nature.
- The `BEGIN` / `END` structure provides clean initialisation and teardown hooks.

**Where it shows strain:**

- **No 2D arrays** require the `y * width + x` linearisation, which obscures the spatial logic.
- **No `sleep()`** forces the `system("sleep 0.1")` subprocess workaround, spawning a new process on every frame.
- AWK was not designed for long-running programs. Running forever in a `while (1)` loop inside `BEGIN` is technically valid but philosophically wrong — AWK should process a file and exit.
- **No terminal control** beyond what ANSI escape sequences provide. The cursor-hiding trick works but is fragile.

**What is actually good:**

AWK demonstrates that a language built around associative arrays and pattern-action rules can express imperative algorithms with minimal ceremony. The implementation is readable, compact (~90 lines), and does not require any libraries. If you need to write Game of Life in a tool available on every Unix system without installing anything extra, AWK is a solid choice.

---

## Typical Use Cases for AWK

AWK excels when:

- Input arrives as **line-oriented text** with consistent field delimiters.
- The processing is **stateless per line** or needs simple cross-line aggregation.
- The script needs to be **portable** across Unix-like systems without installing interpreters.
- The task is a **one-liner** or a short filter in a shell pipeline.

**Classic AWK use cases:**

| Domain | Example |
|--------|---------|
| Log analysis | Summing response times from web server logs, counting HTTP status codes |
| CSV/TSV processing | Extracting specific columns, reformatting delimited files |
| Report generation | Printing subtotals, formatting tabular output with aligned columns |
| System administration | Parsing `/proc` files, reformatting `ps` or `df` output |
| Build systems | Old-style Makefiles that use AWK to transform source files or generate headers |
| Bioinformatics | Processing FASTA/FASTQ files, parsing GFF annotation tables |

What AWK is **not** designed for: long-running processes, complex data structures, graphics, network I/O, or anything that benefits from object-oriented or functional abstractions. Game of Life stretches it on the "long-running process" axis, but not severely enough to break it.

---

## Further Reading

- [The AWK Programming Language (2nd ed.)](https://awk.dev/) — the definitive book by the language's creators, updated in 2023
- [GNU AWK User's Guide](https://www.gnu.org/software/gawk/manual/gawk.html)
- [AWK one-liners explained](https://catonmat.net/awk-one-liners-explained-part-one) — a practical tour of idiomatic AWK
- [POSIX AWK specification](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/awk.html)
