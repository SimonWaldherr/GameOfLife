#!/usr/bin/ruby

$width, $height = 50, 30
$density = 0.2

def initialize_grid
	Array.new($height) { Array.new($width) { rand < $density } }
end

def count_neighbors(grid, x, y)
	count = 0
	[-1, 0, 1].repeated_permutation(2) do |dx, dy|
		next if dx == 0 && dy == 0
		nx, ny = (x + dx) % $width, (y + dy) % $height
		count += 1 if grid[ny][nx]
	end
	count
end

def compute_next_state(grid)
	Array.new($height) do |y|
		Array.new($width) do |x|
			alive = grid[y][x]
			neighbors = count_neighbors(grid, x, y)
			(alive && neighbors == 2) || neighbors == 3
		end
	end
end

def print_grid(grid)
	grid.each do |row|
		puts row.map { |cell| cell ? '█' : ' ' }.join
	end
end

def main
	grid = initialize_grid
	loop do
		system('clear') # or 'cls' on Windows
		print_grid(grid)
		grid = compute_next_state(grid)
		sleep(0.1) # 100 ms delay
	end
end

main