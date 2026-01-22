/*
 * PhD25001_Part_B_Program_B.c
 * Program B: Creates threads using pthread
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <math.h>
#include <time.h>
#include <unistd.h>
#include <fcntl.h>

#define BASE_LOOP_COUNT 1000
#define CPU_LOOP_COUNT 100000000
#define MEM_ARRAY_SIZE 10000000
#define IO_FILE_SIZE 1024

typedef struct {
    int id;
    const char *type;
} thread_arg_t;

void *worker_func(void *arg) {
    thread_arg_t *args = (thread_arg_t *)arg;
    const char *type = args->type;
    
    if (strcmp(type, "cpu") == 0) {
        volatile double result = 0.0;
        for (long i = 0; i < CPU_LOOP_COUNT; i++) {
            result += sin((double)i) * cos((double)i);
            if (i % 1000 == 0) result *= 1.000001;
        }
    } else if (strcmp(type, "mem") == 0) {
        int *arr = (int *)malloc(MEM_ARRAY_SIZE * sizeof(int));
        if (arr) {
            for(int i=0; i<MEM_ARRAY_SIZE; i++) arr[i] = i;
            volatile long sum = 0;
            unsigned int seed = time(NULL) ^ (long)pthread_self();
            for (int iter = 0; iter < BASE_LOOP_COUNT * 50; iter++) {
                 for (int k = 0; k < 1000; k++) {
                    int idx = rand_r(&seed) % MEM_ARRAY_SIZE;
                    sum += arr[idx];
                    arr[idx] = sum;
                 }
            }
            free(arr);
        }
    } else if (strcmp(type, "io") == 0) {
        char fn[64], buf[IO_FILE_SIZE];
        snprintf(fn, sizeof(fn), "/tmp/io_thread_%lx.tmp", (long)pthread_self());
        memset(buf, 'B', IO_FILE_SIZE);
        for (int iter = 0; iter < BASE_LOOP_COUNT; iter++) {
            int fd = open(fn, O_WRONLY | O_CREAT | O_TRUNC, 0644);
            if (fd >= 0) {
                for(int k=0; k<10; k++) {
                    if(write(fd, buf, IO_FILE_SIZE) < 0) perror("write");
                    fsync(fd);
                }
                close(fd);
            }
        }
        unlink(fn);
    }
    return NULL;
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <worker_type> [num_threads]\n", argv[0]);
        return EXIT_FAILURE;
    }
    
    const char *worker_type = argv[1];
    int num_threads = (argc >= 3) ? atoi(argv[2]) : 2; // Default 2 threads [cite: 15]
    
    pthread_t *threads = malloc(num_threads * sizeof(pthread_t));
    thread_arg_t *t_args = malloc(num_threads * sizeof(thread_arg_t));
    
    for (int i = 0; i < num_threads; i++) {
        t_args[i].id = i;
        t_args[i].type = worker_type;
        pthread_create(&threads[i], NULL, worker_func, &t_args[i]);
    }
    
    for (int i = 0; i < num_threads; i++) pthread_join(threads[i], NULL);
    
    free(threads);
    free(t_args);
    return EXIT_SUCCESS;
}