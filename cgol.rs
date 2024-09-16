#!/usr/bin/env cargo script

//! ```cargo
//! [dependencies]
//! rand = "0.8"
//! ```

#![allow(unused)]
extern crate rand;

use rand::Rng;
use std::thread::sleep;
use std::time::Duration;

const WIDTH: usize = 50;
const HEIGHT: usize = 30;
const DENSITY: f64 = 0.2; // Probability a cell is alive

fn initialize_grid() -> Vec<Vec<bool>> {
    let mut rng = rand::thread_rng();
    let mut grid = vec![vec![false; WIDTH]; HEIGHT];
    for row in grid.iter_mut() {
        for cell in row.iter_mut() {
            *cell = rng.gen::<f64>() < DENSITY;
        }
    }
    grid
}

fn count_neighbors(grid: &Vec<Vec<bool>>, x: usize, y: usize) -> usize {
    let mut count = 0;
    for dx in [WIDTH - 1, 0, 1].iter().cloned() {
        for dy in [HEIGHT - 1, 0, 1].iter().cloned() {
            if dx == 0 && dy == 0 { continue; }
            let nx = (x + dx) % WIDTH;
            let ny = (y + dy) % HEIGHT;
            if grid[ny][nx] { count += 1; }
        }
    }
    count
}

fn compute_next_state(grid: &Vec<Vec<bool>>) -> Vec<Vec<bool>> {
    let mut new_grid = vec![vec![false; WIDTH]; HEIGHT];
    for y in 0..HEIGHT {
        for x in 0..WIDTH {
            let alive = grid[y][x];
            let neighbors = count_neighbors(grid, x, y);
            new_grid[y][x] = match (alive, neighbors) {
                (true, 2) | (_, 3) => true,
                _ => false,
            };
        }
    }
    new_grid
}

fn print_grid(grid: &Vec<Vec<bool>>) {
    for row in grid {
        for &cell in row {
            print!("{}", if cell { "█" } else { " " });
        }
        println!();
    }
}

fn main() {
    let mut grid = initialize_grid();
    loop {
        print_grid(&grid);
        grid = compute_next_state(&grid);
        sleep(Duration::from_millis(100));
        println!("\x1B[2J\x1B[1;1H"); // Clear screen
    }
}
