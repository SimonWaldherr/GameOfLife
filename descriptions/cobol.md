# Conway's Game of Life in COBOL

## What is COBOL?

COBOL (Common Business-Oriented Language) is one of the **oldest surviving programming languages**, designed in 1959 by a committee chaired by Grace Hopper. Its explicit design goal was to read like English — to be legible to business managers, not just programmers. It has been the backbone of banking, insurance, government, and payroll systems for over 60 years.

COBOL's design philosophy is strikingly different from every other language in this repository:

- **Verbose by intention.** `MOVE 1 TO CELLS-A(F)` rather than `cells[f] = 1`. Every operation is spelled out in full English words.
- **Column-sensitive syntax.** Traditional COBOL source code is laid out in fixed columns inherited from the punched-card era: columns 1–6 are the sequence number field, column 7 is the indicator (for comments and continuation), columns 8–11 are Area A (divisions, sections, paragraph names), columns 12–72 are Area B (statements).
- **Strictly procedural.** COBOL has no functions in the modern sense — only named **paragraphs** called with `PERFORM`. There are no closures, no lambdas, no recursion in standard COBOL.
- **WORKING-STORAGE for everything.** All variables are declared in a central `DATA DIVISION` with fixed types and sizes. There are no local variables, no stack frames in the traditional sense.
- **Still in production.** An estimated 800 billion lines of COBOL are running in production today, processing the majority of the world's financial transactions.

---

## How the Implementation Works

### Program Structure

COBOL programs are divided into four mandatory **Divisions**:

```cobol
IDENTIFICATION DIVISION.  → Program metadata (name, author, date)
ENVIRONMENT DIVISION.     → (omitted here) Platform and file bindings
DATA DIVISION.            → All variable declarations
PROCEDURE DIVISION.       → All executable code
```

The Game of Life implementation uses `IDENTIFICATION DIVISION` (program name), `DATA DIVISION` (all variables), and `PROCEDURE DIVISION` (all logic).

### Variable Declarations in `WORKING-STORAGE`

Every variable is declared with a **level number**, a name, a `PIC` (Picture) clause that defines its type and size, and optionally a `VALUE`:

```cobol
01 WIDTH   PIC 9(3) VALUE 50.    -- 3-digit decimal integer, initial value 50
01 HEIGHT  PIC 9(2) VALUE 30.    -- 2-digit decimal integer, initial value 30
01 CELLS-TABLE.
    05 CELLS-A PIC 9 OCCURS 5000 TIMES.  -- array of 5000 single digits
    05 CELLS-B PIC 9 OCCURS 5000 TIMES.  -- second buffer (same size)
```

`PIC 9(3)` means "three decimal digits, numeric". `PIC X` means "one character, alphanumeric". `OCCURS n TIMES` is COBOL's array declaration. The level numbers (`01`, `05`) create a hierarchy: `01` is a top-level group item; `05` is a subordinate element. The two arrays `CELLS-A` and `CELLS-B` live inside the `01 CELLS-TABLE` group, allocated together in memory.

Note that the arrays are sized for 5000 elements even though the grid is only 50 × 30 = 1500 cells. This is conservative over-allocation — common in COBOL, where you often size for the maximum you might ever need.

### Pseudo-Random Number Generation by Hand

COBOL's standard `FUNCTION RANDOM` does not produce unique values in a tight loop in all implementations. This code uses a **linear congruential generator** written manually:

```cobol
COMPUTE SEED = SEED * 4848 + 1
COMPUTE RAND = FUNCTION MOD(SEED, 90) + 2
IF RAND > 50
    MOVE 1 TO CELLS-A(F)
ELSE
    MOVE 0 TO CELLS-A(F)
END-IF
```

The seed starts at 24680 and is updated on every iteration by multiplying by 4848 and adding 1. The result modulo 90, offset by 2, gives a value in 2–91; values above 50 yield a live cell. This gives approximately 45 % live cells at start — close to the target density.

### Paragraphs as Subroutines

COBOL has no functions. Logic is split into named **paragraphs** called with `PERFORM`:

```cobol
MAIN-PROCESS.
    PERFORM INITIALIZE-BOARD.
    PERFORM RUN-GAME UNTIL 1 = 2.   *> Infinite loop
    STOP RUN.

RUN-GAME.
    PERFORM DISPLAY-BOARD
    CONTINUE AFTER 0.1 SECONDS
    DISPLAY ESC "[30A" WITH NO ADVANCING
    PERFORM COPY-BOARD
    PERFORM UPDATE-BOARD.
```

`PERFORM paragraph-name` is a `GOSUB`-style call: execution jumps to the paragraph, runs to the end of it, and returns to the next statement. `PERFORM UNTIL 1 = 2` is idiomatic COBOL for an infinite loop — the condition `1 = 2` is always false, so it loops forever.

`CONTINUE AFTER 0.1 SECONDS` is a COBOL-2014 standard sleep statement — cleaner than AWK's `system("sleep")` workaround, though availability varies by compiler. GnuCOBOL supports it.

### Double-Buffering with Two Arrays

Because COBOL has no concept of swapping pointers, the implementation uses two statically declared arrays: `CELLS-A` (the current generation) and `CELLS-B` (a snapshot used during update computation). The `COPY-BOARD` paragraph duplicates `CELLS-A` into `CELLS-B` before the update step, so `UPDATE-BOARD` reads from `CELLS-B` (the unmodified previous state) and writes into `CELLS-A`:

```cobol
COPY-BOARD.
    PERFORM VARYING G FROM 1 BY 1 UNTIL G > BOARD-SIZE
        MOVE CELLS-A(G) TO CELLS-B(G)
    END-PERFORM.
```

This is the explicit manual version of what Python or Go would do with a list copy or a buffer swap.

### Neighbour Counting via `PERFORM VARYING`

The neighbour-counting paragraph (`COMPUTE-ADJACENT`) uses two nested `PERFORM VARYING` loops over the `(K, L)` offset pairs, implementing toroidal wrap-around with explicit `IF` branches rather than modulo arithmetic:

```cobol
COMPUTE N = I + K - 1
IF N = 0
    MOVE HEIGHT TO N    *> wrap: row 0 → row HEIGHT
END-IF
IF N > HEIGHT
    MOVE 1 TO N         *> wrap: row HEIGHT+1 → row 1
END-IF
```

COBOL uses 1-based indexing, and the wrap condition is `> HEIGHT` (not `>= HEIGHT`) because valid row indices are 1..HEIGHT.

### Rule Application

Conway's rules are expressed as nested `IF` statements without an `ELSE IF` chain — standard pre-COBOL-85 style:

```cobol
APPLY-RULES.
    IF CELL = 1
        IF ADJ < 2
            MOVE 0 TO CELL
        END-IF
        IF ADJ > 3
            MOVE 0 TO CELL
        END-IF
    ELSE
        IF ADJ = 3
            MOVE 1 TO CELL
        END-IF
    END-IF.
```

Survival (2–3 neighbours) is implemented as the absence of the two death conditions (fewer than 2, more than 3), rather than a positive test. This is logically equivalent but reflects COBOL's tendency towards explicit enumeration over compact boolean expressions.

---

## Is COBOL Good, Bad, or Ugly for Game of Life?

### 🔴 Verdict: Ugly in the Best Possible Way

COBOL is the most verbosely inappropriate language in this repository. It is not designed for algorithms, mathematical computation, or anything without a business record attached to it. The implementation works — and that is remarkable.

**Why it is ugly:**

- **Extreme verbosity.** Every operation that a modern language expresses in one token requires a full English sentence. The 135-line implementation contains less actual logic than the 30-line Python version.
- **No local variables.** All state is global working storage. The variables `N`, `M`, `K`, `L`, `I`, `J`, `RESULT`, `CELL`, `ADJ` all coexist in one flat namespace and are shared across every paragraph — a source of subtle bugs in real programs.
- **No modulo for wrapping.** COBOL's `FUNCTION MOD` exists, but the implementation uses explicit bounds checks instead, making the wrap logic four lines instead of one.
- **Manual PRNG.** The hand-rolled linear congruential generator is a necessary workaround for COBOL's limited standard library.
- **1-based indexing.** Everything is offset by one compared to every other language in this repository.
- **`PERFORM UNTIL 1 = 2`.** This is the canonical COBOL infinite loop. It speaks for itself.

**Why it works:**

- COBOL's `PERFORM VARYING … UNTIL` loop is perfectly capable of iterating over a grid.
- The flat array model (`CELLS-A(F)`) works for linearised 2D storage.
- COBOL can write to the terminal and perform delays — the ingredients for animation are all present.
- The two-buffer design (`CELLS-A` / `CELLS-B`) is a standard COBOL pattern for record processing, just applied to cells instead of payroll entries.

**What is actually good:**

The paragraph-based structure enforces a clean separation of concerns: `INITIALIZE-BOARD`, `DISPLAY-BOARD`, `COPY-BOARD`, `UPDATE-BOARD`, `COMPUTE-ADJACENT`, `APPLY-RULES`. Each paragraph does exactly one thing, and the `MAIN-PROCESS` paragraph reads almost like pseudocode. COBOL's verbosity is a feature in contexts where the code must be auditable by non-programmers — a Game of Life written for a bank regulator's review would be comprehensible to everyone in the room.

---

## Typical Use Cases for COBOL

COBOL was designed for, and remains dominant in:

| Domain | Example |
|--------|---------|
| Banking | Core banking systems processing deposits, withdrawals, and interest calculations |
| Insurance | Policy management, actuarial calculations, claims processing |
| Government | Tax processing (the US IRS runs COBOL), social security, pension administration |
| Payroll | Large-scale payroll systems processing millions of employee records |
| Mainframe batch processing | Nightly batch jobs sorting, merging, and updating master files |
| Retail | Legacy inventory and point-of-sale systems at large retailers |

COBOL's strengths — decimal arithmetic without floating-point rounding, strict field layout for fixed-format records, and industrial-strength batch processing — are irrelevant to Game of Life. Its weaknesses — verbosity, no modern data structures, no first-class functions — are painfully visible in the implementation.

The language remains critical infrastructure for the global economy. It just has no business simulating cellular automata.

---

## Further Reading

- [GnuCOBOL Programmer's Guide](https://gnucobol.sourceforge.io/HTML/gnucobpg.html) — the open-source COBOL compiler used to run this implementation
- [COBOL Programming – Course Notes (IBM)](https://github.com/openmainframeproject/cobol-programming-course) — a free modern COBOL curriculum
- [The COBOL report (original 1960 document)](https://archive.org/details/bitsavers_coboldataSOMTECHNICAL_42070849) — the founding specification on the Internet Archive
- ["COBOL is everywhere. Who will maintain it?" — IEEE Spectrum](https://spectrum.ieee.org/cobol-everywhere) — on the longevity and hidden ubiquity of COBOL
