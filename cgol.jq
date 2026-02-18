#!/usr/bin/env bash
# Conway's Game of Life in jq (toroidal grid)

# Grid dimensions and initial alive-cell density (percentage)
W=50; H=30; D=20

# Generate a random initial grid as a JSON 2D array (H x W).
# Uses a hash of column index and current time to approximate randomness,
# since jq has no built-in per-element random function.
grid=$(jq -n --argjson w $W --argjson h $H --argjson d $D \
  '[range($h) | [range($w) | if ((. * 2654435761 + (now * 999983 | floor)) % 100) < $d then 1 else 0 end]]')

# Hide cursor and clear screen; restore cursor on exit
tput civis; printf '\033[2J'
trap 'tput cnorm' EXIT

while :; do
  # Run one jq invocation per frame: compute render output and next generation.
  # The two results are separated by the ASCII record separator (\u001e / 0x1e)
  # so both can be extracted from a single jq call without a temp file.
  out=$(jq -rn --argjson g "$grid" '
    # Wrap coordinate x into [0, m) (toroidal / modulo addressing)
    def idx($x;$m): ((($x % $m) + $m) % $m);

    # Read cell value at (i, j) with wrap-around on both axes
    def at($gr;$i;$j): $gr[idx($i;$gr|length)][idx($j;$gr[0]|length)];

    # Count the 8 live neighbours of cell (i, j)
    def neighbors($gr;$i;$j):
      reduce ((-1,0,1)) as $di (0;
        reduce ((-1,0,1)) as $dj (.;
          if ($di==0 and $dj==0) then . else . + at($gr;$i+$di;$j+$dj) end));

    # Apply Conway'"'"'s rules to every cell and return the next generation
    def step:
      . as $gr | [range($gr|length) as $i |
        [range($gr[0]|length) as $j |
          neighbors($gr;$i;$j) as $n | at($gr;$i;$j) as $a |
          # Survive with 2-3 neighbours; born with exactly 3 neighbours
          if ($n==3) or ($a==1 and $n==2) then 1 else 0 end]];

    # Render the grid: live cells as solid block, dead cells as space
    def render: map(map(if .==1 then "█" else " " end) | join("")) | join("\n");

    # Output: rendered frame + record separator + next generation as JSON
    $g | "\(render)\u001e\(step | tojson)"
  ')

  # Print the rendered frame (everything before the record separator)
  printf '\033[H%s' "${out%%$'\x1e'*}"

  # Extract the next-generation JSON (everything after the record separator)
  grid="${out#*$'\x1e'}"

  sleep 0.08
done
