# given matrices A and B of size N x N (where N=5), store product in C
# $a0 -> base address of matrix A
# $a1 -> base address of matrix B
# $a2 -> base address of matrix C
# $a3 -> N (size of matrix = 5)

# c logic (optimized for register accumulation)
# void matrix_mult(int* A, int* B, int* C, int n) {
#     for (int i = 0; i < n; i++) {           // $t0
#         int i_n = i * n;                    // $t4
#         for (int j = 0; j < n; j++) {       // $t1
#             int sum = 0;                    // $t3
#             for (int k = 0; k < n; k++) {   // $t2
#                 sum += A * B;
#             }
#             C = sum;
#         }
#     }
# }

.data
    # 5x5 matrix A (25 words = 100 bytes)
    mat_a: .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    
    # 5x5 matrix B (25 words = 100 bytes)
    mat_b: .word 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
    
    # 5x5 matrix C (25 words = 100 bytes)
    mat_c: .space 100

.text
.globl main

main:
    # setup base addresses in argument registers
    lui  $a0, 0x1001
    ori  $a0, $a0, 0x0000      # $a0 = base of mat_a
    
    addi $a1, $a0, 100         # $a1 = base of mat_b (a + 100 bytes)
    addi $a2, $a1, 100         # $a2 = base of mat_c (b + 100 bytes)
    
    # pass n = 5 as the 4th argument
    addi $a3, $zero, 5

    # call the function
    jal  matrix_mult

    # exit
    addi $v0, $zero, 10
    syscall

matrix_mult:
    # leaf function (no stack frame required)
    add  $t0, $zero, $zero    # i = 0

i_loop:
    # calculate i * n once per outer loop
    mult $t0, $a3             
    mflo $t4                  # t4 = i * n

    add  $t1, $zero, $zero    # j = 0

j_loop:
    add  $t3, $zero, $zero    # sum = 0
    add  $t2, $zero, $zero    # k = 0

k_loop:
    # load A
    # offset = i * n + k
    add  $t5, $t4, $t2        # t5 = (i * n) + k
    sll  $t5, $t5, 2          # t5 = offset * 4 bytes
    add  $t6, $a0, $t5        # t6 = base_a + byte_offset
    lw   $t7, 0($t6)          # t7 = A

    # load B
    # offset = k * n + j
    mult $t2, $a3             
    mflo $t5                  # t5 = k * n
    add  $t5, $t5, $t1        # t5 = (k * n) + j
    sll  $t5, $t5, 2          # t5 = offset * 4 bytes
    add  $t8, $a1, $t5        # t8 = base_b + byte_offset
    lw   $t9, 0($t8)          # t9 = B

    # compute and accumulate
    mult $t7, $t9             
    mflo $t5                  # t5 = A * B
    add  $t3, $t3, $t5        # sum = sum + (A * B)

    # k loop rotation
    addi $t2, $t2, 1          # k++
    slt  $t5, $t2, $a3        # (k < n) ? 1 : 0
    bne  $t5, $zero, k_loop   # if true, loop k

    # store C
    # offset = i * n + j
    add  $t5, $t4, $t1        # t5 = (i * n) + j
    sll  $t5, $t5, 2          # t5 = offset * 4 bytes
    add  $t6, $a2, $t5        # t6 = base_c + byte_offset
    sw   $t3, 0($t6)          # C = sum

    # j loop rotation
    addi $t1, $t1, 1          # j++
    slt  $t5, $t1, $a3        # (j < n) ? 1 : 0
    bne  $t5, $zero, j_loop   # if true, loop j

    # i loop rotation
    addi $t0, $t0, 1          # i++
    slt  $t5, $t0, $a3        # (i < n) ? 1 : 0
    bne  $t5, $zero, i_loop   # if true, loop i

    # return to caller
    jr   $ra