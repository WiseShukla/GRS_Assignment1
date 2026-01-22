# PA01: Processes and Threads
## Graduate Systems (CSE638)

**Author:** Adarsh Singh  
**Roll Number:** PhD25001  
**Institute:** IIIT Delhi  
**Date:** January 23, 2026

---

## Overview

This assignment implements and analyzes process-based (fork) and thread-based (pthread) parallelism with three types of workloads: CPU-intensive, Memory-intensive, and I/O-intensive.

## Directory Structure

```
PhD25001_PA01/
├── PhD25001_Part_A_Program_A.c    # Process-based implementation (fork)
├── PhD25001_Part_B_Program_B.c    # Thread-based implementation (pthread)
├── PhD25001_Part_C_shell.sh       # Measurement script for Part C
├── PhD25001_Part_D_shell.sh       # Scaling analysis script for Part D
├── Makefile                        # Build automation
├── PhD25001_Part_C_CSV.csv        # Part C results
├── PhD25001_Part_D_CSV.csv        # Part D results
├── PhD25001_Part_D_CPU_Plot.png   # CPU utilization plot
├── PhD25001_Part_D_Memory_Plot.png # Memory utilization plot
├── PhD25001_Part_D_IO_Plot.png    # I/O activity plot
├── PhD25001_Part_D_Time_Plot.png  # Execution time plot
├── PhD25001_PA01_Report.docx      # Comprehensive report
└── README.md                       # This file
```

## Compilation

```bash
# Compile both programs
make all

# Or compile individually
make program_a
make program_b
```

## Usage

### Program A (Processes)
```bash
./program_a <worker_type> [num_processes]
# Examples:
./program_a cpu 4      # Run CPU worker with 4 processes
./program_a mem 2      # Run memory worker with 2 processes
./program_a io 3       # Run I/O worker with 3 processes
```

### Program B (Threads)
```bash
./program_b <worker_type> [num_threads]
# Examples:
./program_b cpu 8      # Run CPU worker with 8 threads
./program_b mem 4      # Run memory worker with 4 threads
./program_b io 2       # Run I/O worker with 2 threads
```

### Worker Types
- `cpu` - CPU-intensive (mathematical calculations)
- `mem` - Memory-intensive (large array with random access)
- `io` - I/O-intensive (file writes with fsync)

## Running Experiments

### Part C: Basic Measurement
```bash
make run_c
# Or directly:
chmod +x PhD25001_Part_C_shell.sh
./PhD25001_Part_C_shell.sh
```
Output: `PhD25001_Part_C_CSV.csv`

### Part D: Scaling Analysis
```bash
make run_d
# Or directly:
chmod +x PhD25001_Part_D_shell.sh
./PhD25001_Part_D_shell.sh
```
Output: `PhD25001_Part_D_CSV.csv` and 4 PNG plots

## Dependencies

- GCC compiler
- POSIX threads library (pthread)
- Math library (libm)
- GNU coreutils (top, time, taskset)
- sysstat package (iostat)
- gnuplot (for plot generation)
- bc (for calculations in shell scripts)

### Install dependencies (Ubuntu/Debian):
```bash
sudo apt-get install build-essential sysstat gnuplot bc
```

## Configuration

### Loop Counts
- `BASE_LOOP_COUNT = 1000` (derived from roll number: last digit 1 × 10³)
- `CPU_LOOP_COUNT = 100000000` (100M iterations for visibility)
- `MEM_ARRAY_SIZE = 10000000` (~40MB per process/thread)
- `IO_FILE_SIZE = 1024` (1KB buffer)

## Results Summary

### Part C (2 processes/threads, pinned to CPU 0)
| Variant | CPU% | Mem% | IO |
|---------|------|------|-----|
| A+cpu | 100.00 | 0 | 15.9 |
| B+cpu | 102.23 | 0 | 15.9 |
| A+mem | 70.00 | 0.15 | 15.9 |
| B+mem | 66.66 | 0.13 | 15.9 |
| A+io | 1.91 | 0 | 4.54 |
| B+io | 1.21 | 0 | 3.98 |

### Part D (Scaling)
- CPU workers: Linear scaling up to available cores
- Memory workers: Sub-linear scaling due to memory bandwidth
- I/O workers: No scaling (disk bottleneck)

## Cleaning Up

```bash
make clean
```

## AI Usage Declaration

AI (Claude by Anthropic) was used for:
- Code structure and implementation assistance
- Debugging shell scripts

All code has been understood and verified by the author.

## GitHub Repository

 https://github.com/WiseShukla/GRS_Assignment1

---

## License

This project is submitted as part of academic coursework at IIIT Delhi.
