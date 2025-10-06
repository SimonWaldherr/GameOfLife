const std = @import("std");

const DENSITY = 0.2; // Wahrscheinlichkeit, dass eine Zelle zu Beginn lebt

var allocator = std.heap.page_allocator;

const WIDTH = 50;  // Anzahl der Spalten (Breite)
const HEIGHT = 30; // Anzahl der Zeilen (Höhe)

pub fn main() !void {
    var grid = try Grid.init(HEIGHT, WIDTH);
    defer grid.deinit();
    
    grid.print();
    
    while (true) {
        std.time.sleep(100 * std.time.ns_per_ms);
        std.debug.print("\x1B[H\x1B[2J", .{});
        grid.print();
        grid.update();
    }
}


const Grid = struct {
    height: usize, // Anzahl der Zeilen
    width: usize,  // Anzahl der Spalten
    cells: [][]bool,  // Dynamisches 2D-Array für den aktuellen Zustand
    buffer: [][]bool, // Zweites Array für den nächsten Zustand

    pub fn init(height: usize, width: usize) !Grid {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch |err| {
            std.debug.print("Failed to get random seed: {}\n", .{err});
            return error.RandomSeedFailed;
        };

        var prng = std.Random.DefaultPrng.init(seed);
        var rand = prng.random();

        var cells = try allocator.alloc([]bool, height);
        var buffer = try allocator.alloc([]bool, height);

        for (0..height) |y| {
            cells[y] = try allocator.alloc(bool, width);
            buffer[y] = try allocator.alloc(bool, width);

            for (0..width) |x| {
                cells[y][x] = rand.float(f64) < DENSITY;
                buffer[y][x] = false;
            }
        }

        return Grid{ .height = height, .width = width, .cells = cells, .buffer = buffer };
    }

    pub fn deinit(self: *Grid) void {
        for (0..self.height) |y| {
            allocator.free(self.cells[y]);
            allocator.free(self.buffer[y]);
        }
        allocator.free(self.cells);
        allocator.free(self.buffer);
    }

    pub fn update(self: *Grid) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const alive_neighbors = self.countNeighbors(x, y);
                self.buffer[y][x] = switch (alive_neighbors) {
                    3 => true,  // Eine tote Zelle mit genau 3 Nachbarn wird lebendig
                    2 => self.cells[y][x], // Eine lebende Zelle mit 2 Nachbarn bleibt am Leben
                    else => false, // Alle anderen sterben
                };
            }
        }

        // Speichert den neuen Zustand ins Hauptarray
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                self.cells[y][x] = self.buffer[y][x];
            }
        }
    }

    fn countNeighbors(self: *const Grid, x: usize, y: usize) usize {
        var count: usize = 0;
        const offsets = [_]i32{ -1, 0, 1 };

        for (offsets) |dy| {
            for (offsets) |dx| {
                if (dx == 0 and dy == 0) continue;

                const nx = wrapIndex(x, dx, self.width);
                const ny = wrapIndex(y, dy, self.height);

                if (self.cells[ny][nx]) {
                    count += 1;
                }
            }
        }

        return count;
    }

    fn wrapIndex(pos: usize, delta: i32, limit: usize) usize {
        const new_pos: isize = @as(isize, @intCast(pos)) + delta;

        if (new_pos < 0) {
            return limit - 1;
        }

        const new_pos_usize: usize = @as(usize, @intCast(new_pos));

        if (new_pos_usize >= limit) {
            return 0;
        }

        return new_pos_usize;
    }

    pub fn print(self: *const Grid) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                std.debug.print("{s}", .{if (self.cells[y][x]) "█" else " "});
            }
            std.debug.print("\n", .{});
        }
    }
    
};
