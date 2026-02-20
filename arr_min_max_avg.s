# given array A[100]
# $gp -> base of array A
# max value -> $v0
# max value index -> $v1
# min value -> $s0
# min value index -> $s1
# average -> $s2

# c logic
# void array_stats(int* A) {
#     int max_idx = 0;           // $v1
#     int min_idx = 0;           // $s1
#     int i = 1;                 // $t2
#     
#     int max_val = A;        // $v0
#     int min_val = A;        // $s0
#     unsigned int sum = A;   // $t4 (unsigned to prevent overflow trap)
#     
#     int* ptr = A + 1;          // $t0
#     int* end_ptr = A + 100;    // $t1
#     
#     if (ptr < end_ptr) {
#         do {
#             int val = *ptr;    // $t3
#             sum += val;
#             
#             if (val > max_val) {
#                 max_val = val;
#                 max_idx = i;
#             }
#             if (val < min_val) {
#                 min_val = val;
#                 min_idx = i;
#             }
#             ptr++;
#             i++;
#         } while (ptr < end_ptr);
#     }
#     int avg = sum / 100;       // $s2
# }

.data
    array_a: 
        .word 10, 25, -15, 40, 80
        .space 380

.text
.globl main

main:
    # setup base address in $gp
    lui  $gp, 0x1001
    ori  $gp, $gp, 0x0000

    # call the function
    jal compute_array_stats

    # copy $v0 to $t8 so syscall doesn't hide the max_val in simulator
    add  $t8, $v0, $zero  

    # exit
    addi $v0, $zero, 10
    syscall

compute_array_stats:
    # prologue
    # allocate 8 bytes for $fp and $ra.
    # we do not save/restore $s0, $s1, $s2 here because the problem requires us to use them as output variables.
    addi $sp, $sp, -8
    sw   $ra, 4($sp)
    sw   $fp, 0($sp)
    add  $fp, $sp, $zero

    # setup indices and counter
    add  $v1, $zero, $zero    # max_idx = 0
    add  $s1, $zero, $zero    # min_idx = 0
    addi $t2, $zero, 1        # i = 1

    # setup values
    lw   $t3, 0($gp)          # fetch a
    add  $v0, $t3, $zero      # max_val = a
    add  $s0, $t3, $zero      # min_val = a
    add  $t4, $t3, $zero      # sum = a

    addi $t0, $gp, 4          # ptr = a + 1
    addi $t1, $gp, 400        # end_ptr = a + 100

compute_loop:
    lw   $t3, 0($t0) # val          
    addu $t4, $t4, $t3 # sum = sum + val   

    # compare val and max_val
    slt  $t5, $v0, $t3        
    beq  $t5, $zero, skip_max 
    add  $v0, $t3, $zero      
    add  $v1, $t2, $zero      
    
skip_max:

    # compare val and min_val
    slt  $t5, $t3, $s0        
    beq  $t5, $zero, skip_min 
    add  $s0, $t3, $zero      
    add  $s1, $t2, $zero      
    
skip_min:

    addi $t0, $t0, 4          # ptr++
    addi $t2, $t2, 1          # i++

    # check if we wanna loop
    slt  $t5, $t0, $t1        
    bne  $t5, $zero, compute_loop

compute_done:
    addi $t5, $zero, 100      
    div  $t4, $t5             # hi = sum % 100, lo = sum / 100
    mflo $s2                  # avg = lo

    # epilogue
    add  $sp, $fp, $zero
    lw   $fp, 0($sp)
    lw   $ra, 4($sp)
    addi $sp, $sp, 8

    jr   $ra