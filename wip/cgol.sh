#!/usr/bin/env bash

# Constants for the grid size and density of alive cells
WIDTH=50
HEIGHT=30
DENSITY=20  # Percentage of cells that start alive

# Initialize the grid with random alive or dead cells
initialize_grid() {
  for ((y = 0; y < HEIGHT; y++)); do
    for ((x = 0; x < WIDTH; x++)); do
      # Generate a random number between 0 and 99
      local rand=$((RANDOM % 100))
      if ((rand < DENSITY)); then
        grid[$y,$x]=1
      else
        grid[$y,$x]=0
      fi
    done
  done
}

# Count the number of alive neighbors around a given cell
count_neighbors() {
  local x="$1"
  local y="$2"
  local count=0

  for dx in -1 0 1; do
    for dy in -1 0 1; do
      if [[ $dx -eq 0 && $dy -eq 0 ]]; then
        continue  # Skip the current cell
      fi

      # Calculate neighbor coordinates with wrapping
      local nx=$(((x + dx + WIDTH) % WIDTH))
      local ny=$(((y + dy + HEIGHT) % HEIGHT))

      # Check if the neighbor is alive
      if [[ ${grid[$ny,$nx]} -eq 1 ]]; then
        ((count++))
      fi
    done
  done

  echo "$count"
}

# Compute the next state of the grid based on the Game of Life rules
compute_next_state() {
  # Create a new grid to store the next state
  declare -A new_grid

  for ((y = 0; y < HEIGHT; y++)); do
    for ((x = 0; x < WIDTH; x++)); do
      local alive="${grid[$y,$x]}"
      local neighbors
      neighbors=$(count_neighbors "$x" "$y")

      # Apply Game of Life rules
      if [[ $alive -eq 1 && ( $neighbors -eq 2 || $neighbors -eq 3 ) || $alive -eq 0 && $neighbors -eq 3 ]]; then
        new_grid[$y,$x]=1
      else
        new_grid[$y,$x]=0
      fi
    done
  done

  # Copy new grid back to original grid array
  for ((y = 0; y < HEIGHT; y++)); do
    for ((x = 0; x < WIDTH; x++)); do
      grid[$y,$x]=${new_grid[$y,$x]}
    done
  done
}

# Print the grid to the console
print_grid() {
  clear
  for ((y = 0; y < HEIGHT; y++)); do
    for ((x = 0; x < WIDTH; x++)); do
      if [[ ${grid[$y,$x]} -eq 1 ]]; then
        printf "█"
      else
        printf " "
      fi
    done
    echo
  done
}

# Main execution block
declare -A grid
initialize_grid

while true; do
  print_grid
  compute_next_state
  #sleep 0.1
done
