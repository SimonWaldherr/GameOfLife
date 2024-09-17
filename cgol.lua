#!/usr/bin/env lua

-- Constants for the grid size and density of alive cells
local WIDTH = 50
local HEIGHT = 30
local DENSITY = 0.2

-- Initialize the grid with random alive or dead cells
function initialize_grid()
    local grid = {}
    for y = 1, HEIGHT do
        grid[y] = {}
        for x = 1, WIDTH do
            grid[y][x] = math.random() < DENSITY and 1 or 0
        end
    end
    return grid
end

-- Count the number of alive neighbors around a given cell
function count_neighbors(grid, x, y)
    local count = 0
    local directions = {-1, 0, 1}

    for _, dx in ipairs(directions) do
        for _, dy in ipairs(directions) do
            if dx == 0 and dy == 0 then
                -- Skip the cell itself
                goto continue
            end

            -- Calculate neighbor coordinates with wrapping
            local nx = ((x + dx - 1) % WIDTH) + 1
            local ny = ((y + dy - 1) % HEIGHT) + 1

            if grid[ny][nx] == 1 then
                count = count + 1
            end

            ::continue::
        end
    end

    return count
end

-- Compute the next state of the grid based on the Game of Life rules
function compute_next_state(grid)
    local new_grid = initialize_grid()

    for y = 1, HEIGHT do
        for x = 1, WIDTH do
            local alive = grid[y][x]
            local neighbors = count_neighbors(grid, x, y)

            -- Apply Game of Life rules
            if (alive == 1 and (neighbors == 2 or neighbors == 3)) or
               (alive == 0 and neighbors == 3) then
                new_grid[y][x] = 1
            else
                new_grid[y][x] = 0
            end
        end
    end

    return new_grid
end

-- Print the grid to the console
function print_grid(grid)
    os.execute("clear")  -- Clear the console screen
    for y = 1, HEIGHT do
        for x = 1, WIDTH do
            if grid[y][x] == 1 then
                io.write("█")
            else
                io.write(" ")
            end
        end
        io.write("\n")
    end
end

-- Main execution function
function main()
    math.randomseed(os.time())  -- Seed the random number generator
    local grid = initialize_grid()

    while true do
        print_grid(grid)
        grid = compute_next_state(grid)
        os.execute("sleep 0.1")  -- Pause for 100 milliseconds
    end
end

-- Run the main function with error handling to catch interruptions
local status, err = xpcall(main, function(err)
    print("\nSimulation stopped due to error:", err)
end)

-- If xpcall fails, it will print an error message and exit gracefully
if not status then
    print("\nSimulation stopped.")
end
