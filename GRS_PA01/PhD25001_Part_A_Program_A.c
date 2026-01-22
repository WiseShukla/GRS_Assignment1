/*
 * PhD25001_Part_A_Program_A.c
 * Program A: Creates child processes using fork()
 * * Logic:
 * - Loop count base = 1 (last digit of roll) * 1000 = 1000
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <math.h>
#include <time.h>
#include <fcntl.h>

/* Constants */
#define BASE_LOOP_COUNT 1000
// Increased to 100 Million to ensure the burst lasts several seconds for 'top' to catch it
#define CPU_LOOP_COUNT 100000000   
#define MEM_ARRAY_SIZE 10000000   /* ~40MB per process */
#define IO_FILE_SIZE 1024         

void cpu_worker(void) {
    volatile double result = 0.0;
    // CPU-intensive: Complex math loop
    for (long i = 0; i < CPU_LOOP_COUNT; i++) {
        result += sin((double)i) * cos((double)i);
        if (i % 1000 == 0) result *= 1.000001; // Prevent optimization
    }
    if (result < -1e20) printf("Unreachable\n");
}

void mem_worker(void) {
    int *large_array = (int *)malloc(MEM_ARRAY_SIZE * sizeof(int));
    if (!large_array) return;
    
    // Initialize
    for (int i = 0; i < MEM_ARRAY_SIZE; i++) large_array[i] = i;
    
    volatile long sum = 0;
    unsigned int seed = (unsigned int)time(NULL) ^ getpid();
    
    // Random access to stress memory controller
    for (int iter = 0; iter < BASE_LOOP_COUNT * 50; iter++) { // Increased iter for visibility
        for (int k = 0; k < 1000; k++) {
            int idx = rand_r(&seed) % MEM_ARRAY_SIZE;
            sum += large_array[idx];
            large_array[idx] = sum;
        }
    }
    free(large_array);
}

void io_worker(void) {
    char filename[64];
    char buffer[IO_FILE_SIZE];
    snprintf(filename, sizeof(filename), "/tmp/io_test_%d.tmp", getpid());
    memset(buffer, 'A', IO_FILE_SIZE);
    
    for (int iter = 0; iter < BASE_LOOP_COUNT; iter++) {
        int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd >= 0) {
            for(int k=0; k<10; k++) { // Small burst of writes
                if(write(fd, buffer, IO_FILE_SIZE) < 0) perror("write");
                fsync(fd); // Force disk I/O
            }
            close(fd);
        }
    }
    unlink(filename);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <worker_type> [num_processes]\n", argv[0]);
        return EXIT_FAILURE;
    }
    
    const char *worker_type = argv[1];
    int num_processes = (argc >= 3) ? atoi(argv[2]) : 2; // Default 2 processes
    
    for (int i = 0; i < num_processes; i++) {
        pid_t pid = fork();
        if (pid == 0) {
            if (strcmp(worker_type, "cpu") == 0) cpu_worker();
            else if (strcmp(worker_type, "mem") == 0) mem_worker();
            else if (strcmp(worker_type, "io") == 0) io_worker();
            exit(0);
        }
    }
    
    // Parent waits for all children
    for (int i = 0; i < num_processes; i++) wait(NULL);
    
    return EXIT_SUCCESS;
}