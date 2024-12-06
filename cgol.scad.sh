#!/usr/bin/env bash

# render_cgol.sh
# Renders OpenSCAD frames for Conway's Game of Life and creates an animated GIF.

# Default Configuration
GEN_MAX_DEFAULT=26           # Default maximum generation to render
OUTPUT_DIR_DEFAULT="frames"  # Default directory to store rendered frames
GIF_NAME_DEFAULT="cgol.gif"  # Default name of the output GIF
SCAD_FILE_DEFAULT="cgol.scad" # Default OpenSCAD script file

# Usage: Print help message
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -g, --generations <num>  Maximum generation to render (default: $GEN_MAX_DEFAULT)"
    echo "  -o, --output-dir <dir>   Output directory for rendered frames (default: $OUTPUT_DIR_DEFAULT)"
    echo "  -f, --gif-name <name>    Name of the output GIF (default: $GIF_NAME_DEFAULT)"
    echo "  -s, --scad-file <file>   OpenSCAD file (default: $SCAD_FILE_DEFAULT)"
    echo "  -c, --cleanup            Remove rendered frames after GIF creation"
    echo "  -h, --help               Show this help message"
    exit 1
}

# Parse command-line arguments
GEN_MAX="$GEN_MAX_DEFAULT"
OUTPUT_DIR="$OUTPUT_DIR_DEFAULT"
GIF_NAME="$GIF_NAME_DEFAULT"
SCAD_FILE="$SCAD_FILE_DEFAULT"
CLEANUP=false

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -g|--generations)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                GEN_MAX="$2"
                shift; shift
            else
                echo "Error: --generations requires a numeric argument."
                usage
            fi
            ;;
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift; shift
            ;;
        -f|--gif-name)
            GIF_NAME="$2"
            shift; shift
            ;;
        -s|--scad-file)
            SCAD_FILE="$2"
            shift; shift
            ;;
        -c|--cleanup)
            CLEANUP=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Function to check dependencies
check_dependencies() {
    echo "Checking required commands..."
    for cmd in openscad convert; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: '$cmd' is not installed or not in PATH."
            exit 1
        fi
    done
    echo "All required commands are available."
}

# Function to validate input files and directories
validate_inputs() {
    if [ ! -f "$SCAD_FILE" ]; then
        echo "Error: SCAD file '$SCAD_FILE' does not exist."
        exit 1
    fi
}

# Function to render each generation
render_generations() {
    echo "Rendering generations 0 to $GEN_MAX..."
    mkdir -p "$OUTPUT_DIR"
    for ((gen=0; gen<=GEN_MAX; gen++)); do
        out_file="$OUTPUT_DIR/gen$(printf '%03d' "$gen").png"
        echo "  Rendering generation $gen -> $out_file"
        if ! openscad -o "$out_file" -Dgen="$gen" "$SCAD_FILE" >/dev/null 2>&1; then
            echo "Error: Failed to render generation $gen."
            exit 1
        fi
    done
    echo "All $((GEN_MAX+1)) generations rendered successfully."
}

# Function to create GIF from rendered frames
create_gif() {
    echo "Creating animated GIF ($GIF_NAME) from frames in '$OUTPUT_DIR'..."
    if ! convert -delay 20 -loop 0 "$OUTPUT_DIR"/gen*.png "$GIF_NAME"; then
        echo "Error: Failed to create GIF."
        exit 1
    fi
    echo "Animated GIF created successfully as '$GIF_NAME'."
}

# Main script execution
check_dependencies
validate_inputs
render_generations
create_gif

# Optional: Cleanup rendered frames
if [ "$CLEANUP" = true ]; then
    echo "Cleaning up rendered frames..."
    rm -rf "$OUTPUT_DIR"
    echo "Rendered frames removed."
fi

echo "Done."
exit 0
