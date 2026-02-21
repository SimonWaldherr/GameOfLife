# Conway's Game of Life in SQL (SQLite)

## What is SQL?

SQL (Structured Query Language) is the **lingua franca of relational databases**. It was designed in the 1970s at IBM to express operations on sets of rows: filtering, joining, aggregating, and transforming tabular data. SQL is declarative — you describe *what* result you want, not *how* to compute it. The database engine decides how to execute the query.

SQLite is a serverless, file-based relational database engine. Its entire database lives in a single file (or in memory), making it ideal for embedded use cases, local prototypes, and shell scripts that need structured storage without spinning up a server.

SQL was designed to answer questions like "which customers placed orders over $500 last month?" It was absolutely not designed to simulate cellular automata. Yet here we are.

---

## How the Implementation Works

### Architecture

The implementation (`cgol.sql.sh`) is a self-contained Bash script that:

1. Creates a temporary SQLite database file.
2. Initialises the grid as a table.
3. Declares the simulation logic as **SQL views**.
4. Runs an infinite loop: display the current state, advance one generation, sleep, repeat.

```
┌─────────────────────────────┐
│  Bash script (cgol.sql.sh)  │
│                             │
│  ┌───────────────────────┐  │
│  │  SQLite database      │  │
│  │                       │  │
│  │  TABLE cells          │  │
│  │  VIEW neighbor_counts │  │
│  │  VIEW next_generation │  │
│  └───────────────────────┘  │
│                             │
│  Loop:                      │
│    SELECT → display         │
│    CREATE TEMP TABLE →      │
│      swap to next gen       │
└─────────────────────────────┘
```

### The Grid as a Table

Every cell is a row:

```sql
CREATE TABLE cells (
    x       INTEGER,   -- column 0..49
    y       INTEGER,   -- row    0..29
    alive   INTEGER,   -- 1 = alive, 0 = dead
    PRIMARY KEY (x, y)
);
```

This is the most natural representation for SQL: a relation whose key is the cell's coordinates and whose payload is its state. Initialisation uses a **recursive CTE** (Common Table Expression) to generate all (x, y) pairs without procedural loops:

```sql
WITH RECURSIVE numbers(n) AS (
    SELECT 0
    UNION ALL SELECT n + 1 FROM numbers WHERE n < 49
),
ynumbers(m) AS (
    SELECT 0
    UNION ALL SELECT m + 1 FROM ynumbers WHERE m < 29
)
INSERT INTO cells (x, y, alive)
SELECT n, m, CASE WHEN abs(random()) % 100 < 40 THEN 1 ELSE 0 END
FROM numbers, ynumbers;
```

The cross join of `numbers` and `ynumbers` produces all 1,500 cells; the `CASE` expression randomly assigns ~40 % of them as alive.

### Counting Neighbours with a Self-Join View

The most elegant — and most relational — part of the implementation is the neighbour-counting view:

```sql
CREATE VIEW neighbor_counts AS
WITH neighbor_data AS (
    SELECT
        ((c.x + dx + 50) % 50) AS nx,
        ((c.y + dy + 30) % 30) AS ny,
        c.alive
    FROM cells c,
         (SELECT -1 AS dx UNION SELECT 0 UNION SELECT 1) AS dxs,
         (SELECT -1 AS dy UNION SELECT 0 UNION SELECT 1) AS dys
    WHERE NOT (dx = 0 AND dy = 0)
)
SELECT nx AS x, ny AS y, SUM(alive) AS neighbor_count
FROM neighbor_data
GROUP BY nx, ny;
```

The key insight: by crossing `cells` with the nine `(dx, dy)` offsets `{-1, 0, 1}² \ {(0,0)}`, each cell row is replicated eight times — once per neighbour direction. After excluding the `(0,0)` self-offset and applying modular arithmetic for toroidal wrap-around, the `GROUP BY` and `SUM` collapse the expanded rows into a count of live neighbours for each target cell. This is a **self-join** in disguise: the grid is joined against itself via positional offsets.

### Applying Conway's Rules

The next-generation view joins the current cell state with the neighbour counts and applies the rules as a `CASE` expression:

```sql
CREATE VIEW next_generation AS
SELECT
    c.x, c.y,
    CASE
        WHEN c.alive = 1 AND (nc.neighbor_count = 2 OR nc.neighbor_count = 3) THEN 1
        WHEN c.alive = 0 AND nc.neighbor_count = 3                            THEN 1
        ELSE 0
    END AS next_alive
FROM cells c
LEFT JOIN neighbor_counts nc ON c.x = nc.x AND c.y = nc.y;
```

The `LEFT JOIN` handles cells that have zero live neighbours (they would not appear in `neighbor_counts` at all and must stay dead).

### Advancing One Generation

Views in SQL are not materialised; they are re-evaluated on every query. The update step therefore uses a temporary table as a staging buffer to avoid reading and writing `cells` simultaneously:

```sql
CREATE TEMP TABLE new_cells AS
    SELECT x, y, next_alive AS alive FROM next_generation;

DELETE FROM cells;
INSERT INTO cells SELECT * FROM new_cells;

DROP TABLE new_cells;
```

This is the standard **double-buffering** pattern, adapted to SQL: compute the new state into a scratch table, then swap it in atomically.

### Rendering

The display query aggregates each row of the grid into a single string using `group_concat`:

```sql
SELECT group_concat(CASE WHEN alive = 1 THEN '█' ELSE ' ' END, '')
FROM cells
GROUP BY y
ORDER BY y;
```

SQLite's `.mode list` output mode prints one line per group, producing a character-art grid in the terminal.

---

## Is SQL Good, Bad, or Ugly for Game of Life?

### 🔴 Verdict: Genuinely Bad — and Unexpectedly Capable

SQL is a terrible choice for any simulation. It is also oddly well-suited to expressing the *logic* of Game of Life. This contradiction is what makes the implementation interesting.

**Why it is bad:**

- **No native loop.** SQL has no `while` or `for` construct at the statement level. Each generation requires running a new batch of SQL statements from the outside (here: from Bash). The loop lives in the shell, not in the database.
- **No terminal animation.** SQL cannot move the cursor, clear the screen, or do anything interactive. All of that is delegated to the Bash wrapper.
- **Materialisation overhead.** Each generation requires a full scan of all 1,500 rows to count neighbours, a full delete, and a full insert. For a small grid this is fine; for a large one it is expensive.
- **No randomness at view evaluation time.** SQLite's `random()` is called only once per query execution; this is why the random seed is only used at initialisation rather than on every step.
- **Stateful mutation feels unnatural.** SQL's strength is immutable queries over data at rest. The `DELETE FROM cells; INSERT INTO cells …` cycle fights the relational model.

**Why it works anyway:**

- Conway's rules are **set operations**: filter cells that survive, union with cells that are born. This is exactly what SQL was built to do.
- The self-join trick for neighbour counting is **idiomatic SQL**: expressing a spatial relationship as a relational join is more natural than the nested loops you would write in an imperative language.
- The `CASE` expression that encodes the transition rules reads almost like a specification — it is arguably the most self-documenting implementation of Conway's rules in this repository.
- Recursive CTEs make set generation (all coordinates, all offsets) compact and elegant.

**What is actually good:**

The implementation demonstrates that **any transformation of a finite, tabular dataset can be expressed in SQL**, including cellular automaton rules. The neighbour-counting view is a genuine example of SQL's expressive power: a spatial proximity query encoded as a self-join with offset arithmetic. Database engineers use exactly this pattern in geospatial queries, bill-of-materials explosions, and graph traversals.

---

## Typical Use Cases for SQL

SQL and SQLite thrive when:

- Data is **structured and relational** — entities with relationships, foreign keys, and referential integrity matter.
- **Queries** are the primary operation — filtering, sorting, aggregating, and joining large datasets.
- **Persistence and transactions** are required — ACID guarantees protect data integrity.
- The dataset is **too large to fit comfortably in memory** as a plain array.

**Classic SQL / SQLite use cases:**

| Domain | Example |
|--------|---------|
| Web backends | User accounts, sessions, orders, content management — the backbone of virtually every web application |
| Data analysis | Ad-hoc queries, aggregations, and pivot tables over business or scientific data |
| Embedded applications | Mobile apps (SQLite ships in every iOS and Android device), browser storage, desktop software settings |
| ETL pipelines | Loading, transforming, and validating tabular data between systems |
| Reporting | Generating summary statistics, joining fact tables with dimension tables |
| Geospatial queries | Spatial databases (PostGIS) use SQL for proximity, containment, and intersection queries — the same self-join trick used for neighbour counting |

What SQL is **not** designed for: animation, simulation state that changes continuously, free-form text processing, or anything that requires a runtime loop. Game of Life needs all of those things, which is why the implementation depends so heavily on its Bash wrapper.

---

## Further Reading

- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [SQL Window Functions](https://www.sqlite.org/windowfunctions.html) — a powerful SQL feature that could also be used for neighbour counting
- [Common Table Expressions in SQLite](https://www.sqlite.org/lang_with.html)
- [Use The Index, Luke](https://use-the-index-luke.com/) — a practical guide to SQL performance
- [SQL for Data Scientists](https://sqlfordatascientists.com/) by Renée Teate
