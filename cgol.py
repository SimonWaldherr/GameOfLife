#!/usr/bin/env python3

import random
import time
import os

width, height = 50, 30
density = 0.2

def initialize_grid():
	return [[random.random() < density for _ in range(width)] for _ in range(height)]

def count_neighbors(grid, x, y):
	count = 0
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			nx, ny = (x + dx) % width, (y + dy) % height
			if grid[ny][nx]:
				count += 1
	return count

def compute_next_state(grid):
	return [[(grid[y][x] and count_neighbors(grid, x, y) in [2]) or count_neighbors(grid, x, y) == 3
			for x in range(width)] for y in range(height)]
			
def print_grid(grid):
	for row in grid:
		print("".join("█" if cell else " " for cell in row))
		
def main():
	grid = initialize_grid()
	while True:
		os.system('cls' if os.name == 'nt' else 'clear')
		print_grid(grid)
		grid = compute_next_state(grid)
		time.sleep(0.1)  # 100 ms delay
		
if __name__ == "__main__":
	main()