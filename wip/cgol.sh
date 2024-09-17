#!/usr/bin/env bash

# Constants for the grid size and density of alive cells
WIDTH=50
HEIGHT=30
DENSITY=20  # Percentage of cells that start alive

# Initialize the grid with random alive or dead cells
initialize_grid() {
  for ((i = 0; i < WIDTH * HEIGHT; i++)); do
    grid[i]=$((RANDOM % 100 < DENSITY ? 1 : 0))
  done
}

# Compute the next state of the grid based on the Game of Life rules
compute_next_state() {
  local x y index alive neighbors nx ny nidx count dx dy
  new_grid=()
  
  for ((y = 0; y < HEIGHT; y++)); do
    for ((x = 0; x < WIDTH; x++)); do
      index=$((y * WIDTH + x))
      alive=${grid[index]}
      count=0

      # Inline neighbor counting
      for ((dx = -1; dx <= 1; dx++)); do
        for ((dy = -1; dy <= 1; dy++)); do
          if ((dx == 0 && dy == 0)); then
            continue  # Skip the current cell
          fi
          nx=$(( (x + dx + WIDTH) % WIDTH ))
          ny=$(( (y + dy + HEIGHT) % HEIGHT ))
          nidx=$((ny * WIDTH + nx))
          ((count += grid[nidx]))
        done
      done

      # Apply Game of Life rules
      if ((alive == 1 && (count == 2 || count == 3) || alive == 0 && count == 3)); then
        new_grid[index]=1
      else
        new_grid[index]=0
      fi
    done
  done

  # Swap grids
  grid=("${new_grid[@]}")
}

# Print the grid to the console
print_grid() {
  local x y index output=""
  # Move cursor to top-left without clearing the screen
  printf "\033[H"
  for ((y = 0; y < HEIGHT; y++)); do
    for ((x = 0; x < WIDTH; x++)); do
      index=$((y * WIDTH + x))
      if ((grid[index] == 1)); then
        output+="█"
      else
        output+=" "
      fi
    done
    output+="\n"
  done
  # Print everything at once
  printf "%b" "$output"
}

# Main execution block
grid=()
initialize_grid

# Hide the cursor
printf "\033[?25l"

# Trap to show the cursor again on exit
trap 'printf "\033[?25h"; exit' SIGINT SIGTERM

while true; do
  print_grid
  compute_next_state
done
