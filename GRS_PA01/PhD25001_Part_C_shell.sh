#!/bin/bash
# PhD25001_Part_C_shell.sh
# Automates execution and metric collection for Part C
# Output format: Program+Function CPU% Mem IO
# Uses: top + taskset + iostat + time

set -e

OUTPUT_CSV="${1:-PhD25001_Part_C_CSV.csv}"

# CSV in professor required format
echo "Program+Function,CPU%,Mem%,IO" > "$OUTPUT_CSV"

# Terminal header in professor required format
echo "Program+Function CPU% Mem IO"

run_c_measure() {
    local prog=$1
    local bin=$2
    local work=$3

    # Pin to CPU 0
    local cmd="taskset -c 0 $bin $work"
    local label="${prog}+${work}"

    echo "Measuring $label..." 1>&2

    # iostat log
    local iostat_log=$(mktemp)
    iostat -dx 1 > "$iostat_log" 2>&1 &
    local io_pid=$!

    # time log
    local time_log=$(mktemp)

    # Run program with time in background
    /usr/bin/time -p -o "$time_log" $cmd &
    local time_pid=$!

    # IMPORTANT FIX:
    # time_pid is PID of /usr/bin/time, not the actual program.
    # We must find the real program PID (taskset -> program)
    local main_pid=""
    for _ in {1..20}; do
        main_pid=$(pgrep -P $time_pid 2>/dev/null | head -n 1)
        [ -n "$main_pid" ] && break
        sleep 0.05
    done

    # If still empty, fallback to time_pid (better than crashing)
    if [ -z "$main_pid" ]; then
        main_pid=$time_pid
    fi

    local sum_cpu=0
    local sum_mem=0
    local samples=0

    # Monitor while program runs
    while kill -0 $time_pid 2>/dev/null; do

        # Get children of the REAL program PID (for forked processes)
        local all_pids=$(pgrep -P $main_pid 2>/dev/null)
        all_pids="$main_pid $all_pids"

        local snap_cpu=0
        local snap_mem=0

        for p in $all_pids; do
            local out=$(top -b -n 1 -p $p 2>/dev/null | tail -1)
            local c=$(echo "$out" | awk '{print $9}')
            local m=$(echo "$out" | awk '{print $10}')

            [[ "$c" =~ ^[0-9] ]] && snap_cpu=$(echo "$snap_cpu + $c" | bc -l)
            [[ "$m" =~ ^[0-9] ]] && snap_mem=$(echo "$snap_mem + $m" | bc -l)
        done

        sum_cpu=$(echo "$sum_cpu + $snap_cpu" | bc -l)
        sum_mem=$(echo "$sum_mem + $snap_mem" | bc -l)
        samples=$((samples+1))

        sleep 0.5
    done

    # Wait for program to fully exit
    wait $time_pid 2>/dev/null

    # Stop iostat safely
    kill $io_pid 2>/dev/null
    wait $io_pid 2>/dev/null || true

    # Calculate average CPU and Mem
    local avg_cpu=0
    local avg_mem=0
    if [ $samples -gt 0 ]; then
        avg_cpu=$(echo "scale=2; $sum_cpu / $samples" | bc -l)
        avg_mem=$(echo "scale=2; $sum_mem / $samples" | bc -l)
    fi

    # Average IO (rkB/s + wkB/s)
    local avg_io=0
    if [ -s "$iostat_log" ]; then
        avg_io=$(grep -E "^[a-z]" "$iostat_log" | awk '{s+=$6+$7} END {if (NR>0) print s/NR; else print 0}')
    fi

    # Print professor required format (terminal)
    echo "$label $avg_cpu $avg_mem $avg_io"

    # Save professor required format (CSV)
    echo "$label,$avg_cpu,$avg_mem,$avg_io" >> "$OUTPUT_CSV"

    rm -f "$iostat_log" "$time_log"
}

# Run all 6 variants
for w in cpu mem io; do
    run_c_measure "A" "./program_a" "$w"
    run_c_measure "B" "./program_b" "$w"
done

echo "Part C Complete. Results saved in $OUTPUT_CSV" 1>&2
