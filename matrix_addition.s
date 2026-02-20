# given matrices A and B of size N x N (where N=4), store result in C
# $a0 -> base address of matrix A
# $a1 -> base address of matrix B
# $a2 -> base address of matrix C
# $a3 -> N (size of matrix)

# c logic
# void matrix_add(int* A, int* B, int* C, int n) {
#     int total_elements = n * n;             // $t0
#     int* end_A = A + total_elements;        // $t0 (base_A + total_bytes)
#     
#     do {
#         *C = *A + *B;
#         A++; B++; C++;
#     } while (A < end_A);
# }

.data
    # initialize 4x4 matrix a (16 words = 64 bytes)
    mat_a: .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    
    # initialize 4x4 matrix b (16 words = 64 bytes)
    mat_b: .word 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
    
    # allocate space for 4x4 matrix c (16 words = 64 bytes)
    mat_c: .space 64

.text
.globl main

main:
    # setup base addresses in argument registers
    # assuming data segment starts at 0x10010000 on your simulator
    lui  $a0, 0x1001
    ori  $a0, $a0, 0x0000      # $a0 = base of mat_a
    
    addi $a1, $a0, 64          # $a1 = base of mat_b (a + 64 bytes)
    addi $a2, $a1, 64          # $a2 = base of mat_c (b + 64 bytes)
    
    # pass n = 4 as the 4th argument
    addi $a3, $zero, 4

    # call the function
    jal  matrix_add

    # exit
    addi $v0, $zero, 10
    syscall

matrix_add:
    # prologue
    # allocate 8 bytes for $fp and $ra
    addi $sp, $sp, -8
    sw   $ra, 4($sp)
    sw   $fp, 0($sp)
    add  $fp, $sp, $zero

    # calculate total elements (n * n)
    mult $a3, $a3              
    mflo $t0                   # $t0 = 16
    
    # convert elements to bytes (n^2 * 4)
    sll  $t0, $t0, 2           # $t0 = 64 bytes
    
    # calculate loop termination address (end_a = base_a + total_bytes)
    add  $t0, $a0, $t0         # $t0 = end of mat_a

matrix_add_loop:
    # load elements
    lw   $t1, 0($a0)           # load a
    lw   $t2, 0($a1)           # load b
    
    # add and store
    add  $t3, $t1, $t2         # temp = a + b
    sw   $t3, 0($a2)           # store in c
    
    # increment pointers by 4 bytes (1 word)
    addi $a0, $a0, 4           # ptr_a++
    addi $a1, $a1, 4           # ptr_b++
    addi $a2, $a2, 4           # ptr_c++
    
    # loop rotation guard
    slt  $t4, $a0, $t0         # ptr_a < end_a ? 1 : 0
    bne  $t4, $zero, matrix_add_loop

    # epilogue
    add  $sp, $fp, $zero
    lw   $fp, 0($sp)
    lw   $ra, 4($sp)
    addi $sp, $sp, 8

    jr   $ra