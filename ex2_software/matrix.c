#include <stdio.h>
#include <pmsis.h>

// N=192 in L2 is about 432 KiB
#define N 195
#define PRINT_LIMIT 8 // print limit

PI_L2 int matA[N * N];
PI_L2 int matB[N * N];
PI_L2 int matC[N * N];

void print_matrix_info(const char* name, int* mat) {
    printf("\n>>> Matrix %s", name);
    printf("\n    Physical Address: %p", (void*)mat);
    printf("\n    Dimension: %dx%d (Visualize only %dx%d)\n", N, N, PRINT_LIMIT, PRINT_LIMIT);

    for (int i = 0; i < PRINT_LIMIT; i++) {
        printf(" | ");
        for (int j = 0; j < PRINT_LIMIT; j++) {
            printf("%4d ", mat[i * N + j]);
        }
        printf("... |\n");
    }
    printf(" | ...  (other %d rows) ... |\n", N - PRINT_LIMIT);
}

void matrix_init() {
    for (int i = 0; i < N * N; i++) {
        matA[i] = i % 5;
        matB[i] = 1;
        matC[i] = 0;
    }
}

void matrix_mul() {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            int sum = 0;
            for (int k = 0; k < N; k++) {
                sum += matA[i * N + k] * matB[k * N + j];
            }
            matC[i * N + j] = sum;
        }
    }
}

void test_entry() {
    float used_kib = (3.0 * N * N * sizeof(int)) / 1024.0;

    printf("\n====================================================\n");
    printf("TASK: 2D Matrix Multiplication on PULP architecture\n");
    printf("Free L2 space: 512.00 kiB\n");
    printf("Used L2 space: %.2f kiB\n", used_kib);
    printf("====================================================\n");

    matrix_init();

    print_matrix_info("A (Input)", matA);
    print_matrix_info("B (Input)", matB);

    printf("\nCalculation...");
    matrix_mul();
    printf(" Completed.\n");

    print_matrix_info("C (Result)", matC);

    printf("\nTask succesfully done.\n");
    pmsis_exit(0);
}

int main() {
    return pmsis_kickoff((void *)test_entry);
}
