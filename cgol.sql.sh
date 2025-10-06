#!/bin/sh
# gameoflife.sh -- A self-contained SQLite Game of Life simulation.
#
# Usage:
#   chmod +x gameoflife.sh
#   ./gameoflife.sh
#
# This script creates a temporary SQLite database, initializes a 50x30 grid
# with ~40% live cells, and then repeatedly displays and updates the board.

# Create a temporary SQLite database file.
DB_FILE=$(mktemp /tmp/gameoflife.db.XXXXXX)

# Initialize the database.
sqlite3 "$DB_FILE" <<'EOF'
-- Drop any existing table.
DROP TABLE IF EXISTS cells;

-- Create the grid table: each cell is a row.
CREATE TABLE cells (
  x INTEGER,    -- X-coordinate (0 to 49)
  y INTEGER,    -- Y-coordinate (0 to 29)
  alive INTEGER,  -- 1 if alive, 0 if dead
  PRIMARY KEY (x, y)
);

-- Generate initial random state with 40% live cells.
WITH RECURSIVE numbers(n) AS (
  SELECT 0
  UNION ALL
  SELECT n + 1 FROM numbers WHERE n < 49
),
ynumbers(m) AS (
  SELECT 0
  UNION ALL
  SELECT m + 1 FROM ynumbers WHERE m < 29
)
INSERT INTO cells (x, y, alive)
SELECT n, m, CASE WHEN abs(random()) % 100 < 40 THEN 1 ELSE 0 END
FROM numbers, ynumbers;

-- Create a view to compute the number of alive neighbors per cell.
DROP VIEW IF EXISTS neighbor_counts;
CREATE VIEW neighbor_counts AS
WITH neighbor_data AS (
  SELECT
    ((c.x + dx + 50) % 50) AS nx,  -- Wrap around horizontally
    ((c.y + dy + 30) % 30) AS ny,  -- Wrap around vertically
    c.alive
  FROM cells c,
       (SELECT -1 AS dx UNION SELECT 0 UNION SELECT 1) AS dxs,
       (SELECT -1 AS dy UNION SELECT 0 UNION SELECT 1) AS dys
  WHERE NOT (dx = 0 AND dy = 0)  -- Exclude self
)
SELECT nx AS x, ny AS y, SUM(alive) AS neighbor_count
FROM neighbor_data
GROUP BY nx, ny;

-- Create a view for the next generation:
-- A live cell survives if it has 2 or 3 neighbors.
-- A dead cell becomes alive if it has exactly 3 neighbors.
DROP VIEW IF EXISTS next_generation;
CREATE VIEW next_generation AS
SELECT
  c.x,
  c.y,
  CASE
    WHEN c.alive = 1 AND (nc.neighbor_count = 2 OR nc.neighbor_count = 3) THEN 1
    WHEN c.alive = 0 AND nc.neighbor_count = 3 THEN 1
    ELSE 0
  END AS next_alive
FROM cells c
LEFT JOIN neighbor_counts nc ON c.x = nc.x AND c.y = nc.y;
EOF

# Clear the terminal before starting the loop.
clear

# Main loop: display and update the board every 0.1 seconds.
while true; do
  # Display the grid.
  sqlite3 "$DB_FILE" <<'EOF'
.mode list
.separator ""
WITH grid_rows AS (
  SELECT y,
         group_concat(CASE WHEN alive = 1 THEN '█' ELSE ' ' END, '') AS row_display
  FROM cells
  GROUP BY y
  ORDER BY y
)
SELECT row_display FROM grid_rows;
EOF

  # Advance one generation using a temporary table.
  sqlite3 "$DB_FILE" <<'EOF'
CREATE TEMP TABLE new_cells AS
  SELECT x, y, next_alive AS alive FROM next_generation;

DELETE FROM cells;
INSERT INTO cells SELECT * FROM new_cells;

DROP TABLE new_cells;
EOF

  sleep 0.1
  clear
done
