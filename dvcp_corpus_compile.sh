#!/bin/bash

# AFL DVCP Compilation and Seed Corpus Generation Script
# Author: AFL automation script for DVCP
# This script compiles DVCP with AFL instrumentation and creates seed corpus

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
DVCP_DIR="Damn_Vulnerable_C_Program"
BUILD_DIR="build"
CORPUS_DIR="corpus/seeds"
AFL_OUTPUT_DIR="afl_output"
INSTRUMENTED_BINARY="dvcp_afl"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if AFL++ is installed
check_afl() {
    print_message $YELLOW "[*] Checking for AFL++ installation..."
    
    # Check for AFL++ compilers
    if command -v afl-clang-fast &> /dev/null; then
        AFL_COMPILER="afl-clang-fast"
        AFL_COMPILER_PLUS="afl-clang-fast++"
        print_message $GREEN "[+] Found AFL++ with afl-clang-fast at: $(which afl-clang-fast)"
    elif command -v afl-gcc-fast &> /dev/null; then
        AFL_COMPILER="afl-gcc-fast"
        AFL_COMPILER_PLUS="afl-g++-fast"
        print_message $GREEN "[+] Found AFL++ with afl-gcc-fast at: $(which afl-gcc-fast)"
    elif command -v afl-cc &> /dev/null; then
        AFL_COMPILER="afl-cc"
        AFL_COMPILER_PLUS="afl-c++"
        print_message $GREEN "[+] Found AFL++ with afl-cc at: $(which afl-cc)"
    else
        print_message $RED "[!] AFL++ not found. Please install AFL++ first."
        print_message $YELLOW "[*] You can install AFL++ with:"
        echo "    git clone https://github.com/AFLplusplus/AFLplusplus"
        echo "    cd AFLplusplus && make && sudo make install"
        exit 1
    fi
    
    # Export for use in compile function
    export AFL_COMPILER
    export AFL_COMPILER_PLUS
}

# Function to clone or update DVCP repository
setup_dvcp() {
    print_message $YELLOW "[*] Setting up DVCP repository..."
    
    if [ -d "$DVCP_DIR" ]; then
        print_message $YELLOW "[*] DVCP directory exists. Updating..."
        cd "$DVCP_DIR"
        git pull
        cd ..
    else
        print_message $YELLOW "[*] Cloning DVCP repository..."
        git clone https://github.com/hardik05/Damn_Vulnerable_C_Program.git
    fi
    
    print_message $GREEN "[+] DVCP repository ready"
}

# Function to create build directory
create_build_dir() {
    print_message $YELLOW "[*] Creating build directory..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR"
    print_message $GREEN "[+] Build directory created"
}

# Function to compile DVCP with AFL++ instrumentation

# compile_with_afl() {
#     print_message $YELLOW "[*] Compiling DVCP with AFL++ instrumentation..."
    
#     # Copy source file to build directory
#     cp "$DVCP_DIR/dvcp.c" "$BUILD_DIR/"
    
#     cd "$BUILD_DIR"
    
#     # --- ADD THIS SECTION ---
#     print_message $YELLOW "[*] Compiling uninstrumented version..."
#     if command -v gcc &> /dev/null; then
#         gcc -o "${INSTRUMENTED_BINARY}_uninstrumented" dvcp.c
#         print_message $GREEN "[+] Created uninstrumented binary: ${INSTRUMENTED_BINARY}_uninstrumented"
#     else
#         print_message $RED "[!] 'gcc' not found. Cannot create uninstrumented binary."
#         exit 1
#     fi
#     # --- END OF ADDED SECTION ---

#     print_message $YELLOW "[*] Using AFL++ compiler: $AFL_COMPILER"
    
#     # Compile with different options
#     # Standard AFL++ instrumentation
#     $AFL_COMPILER -o "$INSTRUMENTED_BINARY" dvcp.c
    
#     # (The rest of the function remains the same)
#     # ...
    
#     cd ..
    
#     print_message $GREEN "[+] Compilation successful"
#     print_message $GREEN "[+] Binaries created:"
#     ls -la "$BUILD_DIR"/${INSTRUMENTED_BINARY}*
# }

compile_with_afl() {
    print_message $YELLOW "[*] Compiling DVCP with AFL++ instrumentation..."
    
    # Copy source file to build directory
    cp "$DVCP_DIR/dvcp.c" "$BUILD_DIR/"
    
    cd "$BUILD_DIR"
    
    # --- ADD THIS SECTION ---
    print_message $YELLOW "[*] Compiling uninstrumented version..."
    if command -v gcc &> /dev/null; then
        gcc -o "${INSTRUMENTED_BINARY}_uninstrumented" dvcp.c
        print_message $GREEN "[+] Created uninstrumented binary: ${INSTRUMENTED_BINARY}_uninstrumented"
    else
        print_message $RED "[!] 'gcc' not found. Cannot create uninstrumented binary."
        exit 1
    fi
    # --- END OF ADDED SECTION ---

    print_message $YELLOW "[*] Using AFL++ compiler: $AFL_COMPILER"
    
    # Compile with different options
    # Standard AFL++ instrumentation
    $AFL_COMPILER -o "$INSTRUMENTED_BINARY" dvcp.c
    
    # (The rest of the function remains the same)
    # ...
    
    cd ..
    
    print_message $GREEN "[+] Compilation successful"
    print_message $GREEN "[+] Binaries created:"
    ls -la "$BUILD_DIR"/${INSTRUMENTED_BINARY}*
}


# Function to create seed corpus
create_seed_corpus() {
    print_message $YELLOW "[*] Creating seed corpus for DVCP..."
    
    if [ -d "$CORPUS_DIR" ]; then
        rm -rf "$CORPUS_DIR"
    fi
    
    mkdir -p "$CORPUS_DIR"
    
    # Create various test cases based on the Image structure
    # struct Image { char header[4]; int width; int height; char data[10]; };
    # Total size: 4 + 4 + 4 + 10 = 22 bytes
    
    # Helper function to create binary files
    create_image_file() {
        local filename=$1
        local header=$2
        local width=$3
        local height=$4
        local data=$5
        
        # Create binary file with proper structure
        {
            # Header (4 bytes)
            printf "%s" "$header" | head -c 4 | tr '\0' ' '
            # Width (4 bytes, little-endian)
            printf "%b" "\\x$(printf "%02x" $((width & 0xFF)))"
            printf "%b" "\\x$(printf "%02x" $(((width >> 8) & 0xFF)))"
            printf "%b" "\\x$(printf "%02x" $(((width >> 16) & 0xFF)))"
            printf "%b" "\\x$(printf "%02x" $(((width >> 24) & 0xFF)))"
            # Height (4 bytes, little-endian)
            printf "%b" "\\x$(printf "%02x" $((height & 0xFF)))"
            printf "%b" "\\x$(printf "%02x" $(((height >> 8) & 0xFF)))"
            printf "%b" "\\x$(printf "%02x" $(((height >> 16) & 0xFF)))"
            printf "%b" "\\x$(printf "%02x" $(((height >> 24) & 0xFF)))"
            # Data (10 bytes)
            printf "%-10s" "$data" | head -c 10
        } > "$CORPUS_DIR/$filename"
    }
    
    # Test case 1: Valid IMG file
    create_image_file "valid_img.img" "IMG" 100 100 "validdata"
    
    # Test case 2: Small dimensions
    create_image_file "small.img" "IMG" 1 1 "smallimg"
    
    # Test case 3: Large dimensions (potential integer overflow)
    create_image_file "large.img" "IMG" 2147483647 2147483647 "overflow"
    
    # Test case 4: Zero dimensions
    create_image_file "zero.img" "IMG" 0 0 "zerosize"
    
    # Test case 5: Negative dimensions (using two's complement)
    create_image_file "negative.img" "IMG" -1 -1 "negative"
    
    # Test case 6: Width + Height = 123456 (special value in code)
    # 123456 = 0x1E240, split between width and height
    create_image_file "special_123456.img" "IMG" 61728 61728 "special"
    
    # Test case 7: Division by zero trigger (height = 0)
    create_image_file "div_zero.img" "IMG" 100 0 "divbyzero"
    
    # Test case 8: Integer overflow in size1 = width + height
    # 0x7FFFFFFF + 1 causes overflow
    create_image_file "int_overflow.img" "IMG" 2147483647 1 "intover"
    
    # Test case 9: Integer underflow in size2 = width - height + 100
    create_image_file "int_underflow.img" "IMG" 1 2147483647 "underflow"
    
    # Test case 10: Different headers
    create_image_file "png_header.img" "PNG" 50 50 "pngdata"
    create_image_file "jpg_header.img" "JPG" 50 50 "jpgdata"
    create_image_file "bmp_header.img" "BMP" 50 50 "bmpdata"
    
    # Test case 11: Multiple image structures in one file
    {
        # First image
        printf "IMG\x00"
        printf "%b" "\\x64\\x00\\x00\\x00"  # width = 100
        printf "%b" "\\x64\\x00\\x00\\x00"  # height = 100
        printf "data1data1"
        # Second image
        printf "IMG\x00"
        printf "%b" "\\x32\\x00\\x00\\x00"  # width = 50
        printf "%b" "\\x32\\x00\\x00\\x00"  # height = 50
        printf "data2data2"
    } > "$CORPUS_DIR/multiple_images.img"
    
    # Test case 12: Edge cases for malloc
    create_image_file "malloc_edge1.img" "IMG" 1073741824 1073741824 "bigmalloc"
    create_image_file "malloc_edge2.img" "IMG" -2147483648 100 "negmalloc"
    
    # Test case 13: Even/odd size for conditional logic
    create_image_file "even_size.img" "IMG" 50 50 "evensize"  # size1 = 100 (even)
    create_image_file "odd_size.img" "IMG" 50 51 "oddsize"    # size1 = 101 (odd)
    
    # Test case 14: Corrupted header
    create_image_file "corrupt_header.img" "\x00\x00\x00\x00" 100 100 "corrupt"
    
    # Test case 15: Minimal valid file (22 bytes exactly)
    {
        printf "IMG\x00"
        printf "%b" "\\x01\\x00\\x00\\x00"  # width = 1
        printf "%b" "\\x01\\x00\\x00\\x00"  # height = 1
        printf "0123456789"
    } > "$CORPUS_DIR/minimal.img"
    
    # Test case 16: Empty file
    touch "$CORPUS_DIR/empty.img"
    
    # Test case 17: Truncated files (less than 22 bytes)
    printf "IMG" > "$CORPUS_DIR/truncated_header.img"
    printf "IMG\x00\x01\x00\x00\x00" > "$CORPUS_DIR/truncated_width.img"
    printf "IMG\x00\x01\x00\x00\x00\x01\x00\x00\x00" > "$CORPUS_DIR/truncated_height.img"
    
    # Test case 18: Random binary data
    dd if=/dev/urandom of="$CORPUS_DIR/random.img" bs=22 count=5 2>/dev/null
    
    # Test case 19: All zeros
    dd if=/dev/zero of="$CORPUS_DIR/zeros.img" bs=22 count=1 2>/dev/null
    
    # Test case 20: All ones (0xFF)
    yes '\xFF' | tr -d '\n' | head -c 22 > "$CORPUS_DIR/ones.img"

    print_message $GREEN "[+] Created $(ls -1 $CORPUS_DIR | wc -l) seed files in $CORPUS_DIR"
    print_message $YELLOW "[*] Seed corpus files:"
    ls -la "$CORPUS_DIR"
}

# Function to create AFL output directory
create_afl_output_dir() {
    print_message $YELLOW "[*] Creating AFL output directory..."
    
    if [ -d "$AFL_OUTPUT_DIR" ]; then
        print_message $YELLOW "[*] AFL output directory exists. Backing up..."
        mv "$AFL_OUTPUT_DIR" "${AFL_OUTPUT_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    mkdir -p "$AFL_OUTPUT_DIR"
    print_message $GREEN "[+] AFL output directory created"
}

# Function to display fuzzing instructions
show_fuzzing_instructions() {
    print_message $GREEN "\n[+] AFL++ compilation completed successfully!"
    print_message $GREEN "[+] Instrumented binary path: $(pwd)/$BUILD_DIR/$INSTRUMENTED_BINARY"
    
    echo -e "\n${YELLOW}To start fuzzing, run:${NC}"
    echo -e "${GREEN}afl-fuzz -i $CORPUS_DIR -o $AFL_OUTPUT_DIR -- $(pwd)/$BUILD_DIR/$INSTRUMENTED_BINARY @@${NC}"
    
    echo -e "\n${YELLOW}Additional AFL++ fuzzing options:${NC}"
    
    echo "1. With ASAN (if compiled):"
    echo -e "   ${GREEN}AFL_USE_ASAN=1 afl-fuzz -i $CORPUS_DIR -o ${AFL_OUTPUT_DIR}_asan -m none -- $(pwd)/$BUILD_DIR/${INSTRUMENTED_BINARY}_asan @@${NC}"
    
    echo -e "\n2. With CMPLOG (improved coverage):"
    echo -e "   ${GREEN}afl-fuzz -c $(pwd)/$BUILD_DIR/${INSTRUMENTED_BINARY}_cmplog -i $CORPUS_DIR -o $AFL_OUTPUT_DIR -- $(pwd)/$BUILD_DIR/$INSTRUMENTED_BINARY @@${NC}"
    
    echo -e "\n3. With LTO mode (if compiled):"
    echo -e "   ${GREEN}afl-fuzz -i $CORPUS_DIR -o ${AFL_OUTPUT_DIR}_lto -- $(pwd)/$BUILD_DIR/${INSTRUMENTED_BINARY}_lto @@${NC}"
    
    echo -e "\n4. Parallel fuzzing (Main):"
    echo -e "   ${GREEN}afl-fuzz -M main -i $CORPUS_DIR -o $AFL_OUTPUT_DIR -- $(pwd)/$BUILD_DIR/$INSTRUMENTED_BINARY @@${NC}"
    
    echo -e "\n5. Parallel fuzzing (Secondary):"
    echo -e "   ${GREEN}afl-fuzz -S secondary1 -i $CORPUS_DIR -o $AFL_OUTPUT_DIR -- $(pwd)/$BUILD_DIR/$INSTRUMENTED_BINARY @@${NC}"
    
    echo -e "\n6. With MOpt mutator (AFL++ feature):"
    echo -e "   ${GREEN}afl-fuzz -L 0 -i $CORPUS_DIR -o $AFL_OUTPUT_DIR -- $(pwd)/$BUILD_DIR/$INSTRUMENTED_BINARY @@${NC}"
    
    echo -e "\n${YELLOW}Corpus minimization:${NC}"
    echo -e "${GREEN}afl-cmin -i $CORPUS_DIR -o ${CORPUS_DIR}_min -- $(pwd)/$BUILD_DIR/$INSTRUMENTED_BINARY @@${NC}"
    
    echo -e "\n${YELLOW}Test a specific crash:${NC}"
    echo -e "${GREEN}$(pwd)/$BUILD_DIR/$INSTRUMENTED_BINARY <crash_file>${NC}"
    
    echo -e "\n${YELLOW}View fuzzing stats:${NC}"
    echo -e "${GREEN}afl-whatsup $AFL_OUTPUT_DIR${NC}"
    
    echo -e "\n${YELLOW}Triage crashes:${NC}"
    echo -e "${GREEN}afl-tmin -i <crash_file> -o <minimized_crash> -- $(pwd)/$BUILD_DIR/$INSTRUMENTED_BINARY @@${NC}"
}

# Main execution
main() {
    print_message $GREEN "=== AFL++ DVCP Compilation and Setup Script ==="
    
    # Check for AFL++ installation
    check_afl
    
    # Setup DVCP repository
    setup_dvcp
    
    # Create build directory
    create_build_dir
    
    # Compile with AFL++
    compile_with_afl
    
    # Create seed corpus
    create_seed_corpus
    
    # Create AFL output directory
    create_afl_output_dir
    
    # Show fuzzing instructions
    show_fuzzing_instructions

# Echo the instrumented binary path as requested
    echo -e "\n${GREEN}[INSTRUMENTED BINARY PATH]${NC} $(pwd)/$BUILD_DIR/$INSTRUMENTED_BINARY"
    echo -e "\n${GREEN}[INSTRUMENTED BINARY PATH]${NC} $(pwd)/$BUILD_DIR/$INSTRUMENTED_BINARY"_uninstrumented
}

# Run main function
main