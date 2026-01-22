#!/bin/bash
# PhD25001_Part_D_shell.sh
# Scaling analysis with corrected process aggregation
# Measures time using: /usr/bin/time (as required)
# Plots include cpu + mem + io curves

set -e

OUTPUT_CSV="${1:-PhD25001_Part_D_CSV.csv}"
echo "Program,Worker,Count,CPU%,Mem%,IO_KB/s,Time_s" > "$OUTPUT_CSV"

NUM_CPUS=$(nproc)

run_d_scaling() {
    local prog=$1
    local bin=$2
    local work=$3
    local cnt=$4

    # Pin to exactly 'cnt' CPUs (0 to cnt-1) for proper scaling analysis
    # This ensures each process/thread gets its own dedicated CPU core
    # Cap at available CPUs to avoid errors
    local max_pin=$((cnt - 1))
    if [ $max_pin -ge $NUM_CPUS ]; then
        max_pin=$((NUM_CPUS - 1))
    fi
    local cpu_range="0-${max_pin}"
    local cmd="taskset -c $cpu_range $bin $work $cnt"
    
    echo "  -> Pinning to CPUs: $cpu_range (${cnt} workers on $((max_pin + 1)) cores)"

    echo "Scaling $prog ($work) count=$cnt..."

    # Start iostat logging
    local iostat_log=$(mktemp)
    iostat -dx 1 > "$iostat_log" 2>&1 &
    local io_pid=$!

    # Time log
    local time_log=$(mktemp)

    # Run with time in background
    /usr/bin/time -p -o "$time_log" $cmd &
    local time_pid=$!

  
    # time_pid is PID of /usr/bin/time, not the actual program.
    # We must find the real program PID (taskset -> program)
    local main_pid=""
    for _ in {1..20}; do
        main_pid=$(pgrep -P $time_pid 2>/dev/null | head -n 1)
        [ -n "$main_pid" ] && break
        sleep 0.05
    done

    # fallback (avoid crash)
    if [ -z "$main_pid" ]; then
        main_pid=$time_pid
    fi

    local sum_cpu=0
    local sum_mem=0
    local samples=0

    while kill -0 $time_pid 2>/dev/null; do
        # children of real program PID
        local pids=$(pgrep -P $main_pid 2>/dev/null)
        pids="$main_pid $pids"

        local cur_cpu=0
        local cur_mem=0

        for p in $pids; do
            local out=$(top -b -n 1 -p $p 2>/dev/null | tail -1)
            local c=$(echo "$out" | awk '{print $9}')
            local m=$(echo "$out" | awk '{print $10}')

            [[ "$c" =~ ^[0-9] ]] && cur_cpu=$(echo "$cur_cpu + $c" | bc -l)
            [[ "$m" =~ ^[0-9] ]] && cur_mem=$(echo "$cur_mem + $m" | bc -l)
        done

        sum_cpu=$(echo "$sum_cpu + $cur_cpu" | bc -l)
        sum_mem=$(echo "$sum_mem + $cur_mem" | bc -l)
        samples=$((samples+1))

        sleep 0.5
    done

    # Wait for completion
    wait $time_pid 2>/dev/null

    # Stop iostat safely
    kill $io_pid 2>/dev/null
    wait $io_pid 2>/dev/null || true

    # Average CPU and Mem
    local avg_cpu=0
    local avg_mem=0
    if [ $samples -gt 0 ]; then
        avg_cpu=$(echo "scale=2; $sum_cpu / $samples" | bc -l)
        avg_mem=$(echo "scale=2; $sum_mem / $samples" | bc -l)
    fi

    # Average IO
    local avg_io=0
    if [ -s "$iostat_log" ]; then
        avg_io=$(grep -E "^[a-z]" "$iostat_log" | awk '{s+=$6+$7} END {if (NR>0) print s/NR; else print 0}')
    fi

    # Extract real time from time output
    local dur=$(awk '/^real/ {print $2}' "$time_log")

    echo "$prog,$work,$cnt,$avg_cpu,$avg_mem,$avg_io,$dur" >> "$OUTPUT_CSV"

    rm -f "$iostat_log" "$time_log"
}

# Run experiments for scaling
for w in cpu mem io; do
    for c in 2 3 4 5; do
        run_d_scaling "A" "./program_a" "$w" "$c"
    done
    for c in 2 3 4 5 6 7 8; do
        run_d_scaling "B" "./program_b" "$w" "$c"
    done
done

# Generate Plots using Gnuplot
echo "Generating plots..."

for metric in 4 5 6 7; do
    case $metric in
        4) type="CPU";  title="CPU Utilization";      file="CPU";;
        5) type="Mem";  title="Memory Utilization";   file="Memory";;
        6) type="IO";   title="IO Activity";          file="IO";;
        7) type="Time"; title="Execution Time";       file="Time";;
    esac

    awk -F, -v m=$metric '$1=="A" && $2=="cpu" {print $3, $m}' "$OUTPUT_CSV" > A_cpu.dat
    awk -F, -v m=$metric '$1=="B" && $2=="cpu" {print $3, $m}' "$OUTPUT_CSV" > B_cpu.dat

    awk -F, -v m=$metric '$1=="A" && $2=="mem" {print $3, $m}' "$OUTPUT_CSV" > A_mem.dat
    awk -F, -v m=$metric '$1=="B" && $2=="mem" {print $3, $m}' "$OUTPUT_CSV" > B_mem.dat

    awk -F, -v m=$metric '$1=="A" && $2=="io"  {print $3, $m}' "$OUTPUT_CSV" > A_io.dat
    awk -F, -v m=$metric '$1=="B" && $2=="io"  {print $3, $m}' "$OUTPUT_CSV" > B_io.dat

    gnuplot -e "set terminal pngcairo size 900,600; set output 'PhD25001_Part_D_${file}_Plot.png'; \
    set title '$title'; set xlabel 'Count'; set ylabel '$type'; set grid; set key outside right top; \
    plot 'A_cpu.dat' w lp t 'A+cpu', 'B_cpu.dat' w lp t 'B+cpu', \
         'A_mem.dat' w lp t 'A+mem', 'B_mem.dat' w lp t 'B+mem', \
         'A_io.dat'  w lp t 'A+io',  'B_io.dat'  w lp t 'B+io'"
done

rm -f *.dat
echo "Done. Results saved in $OUTPUT_CSV and plots generated."