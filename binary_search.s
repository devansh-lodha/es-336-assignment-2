# given a sorted array a
# $a0 -> base address of array a
# $a1 -> target value
# $a2 -> n (size of array)
# $v0 -> returns index of target, or -1 if not found

# c logic
# int binary_search(int* a, int target, int n) {
#     int low = 0;                  // $t0
#     int high = n - 1;             // $t1
#     
#     while (low <= high) {
#         int mid = (low + high) / 2; // $t2 (using shift right)
#         int mid_val = a;       // $t3
#         
#         if (mid_val == target) {
#             return mid;
#         }
#         if (mid_val < target) {
#             low = mid + 1;
#         } else {
#             high = mid - 1;
#         }
#     }
#     return -1;
# }

.data
    # 10 sorted elements
    array_a: .word 10, 20, 30, 40, 50, 60, 70, 80, 90, 100

.text
.globl main

main:
    # load base address of array a
    lui  $a0, 0x1001
    ori  $a0, $a0, 0x0000
    
    # pass size n = 10
    addi $a2, $zero, 10

    # test 1: search for existing element (70)
    addi $a1, $zero, 70
    jal  binary_search
    # copy result to $s0
    add  $s0, $v0, $zero      

    # test 2: search for non-existing element (75)
    addi $a1, $zero, 75
    jal  binary_search
    # copy result to $s1
    add  $s1, $v0, $zero      

    # exit
    addi $v0, $zero, 10
    syscall

binary_search:
    # leaf Function (no stack frame required)
    # initialize low = 0, high = n - 1
    add  $t0, $zero, $zero    # low = 0
    addi $t1, $a2, -1         # high = n - 1

bs_loop:
    # loop guard: while (low <= high)
    # mathematically equivalent to: if (high < low) break
    slt  $t4, $t1, $t0        # t4 = (high < low) ? 1 : 0
    bne  $t4, $zero, bs_not_found

    # calculate mid = (low + high) / 2
    add  $t2, $t0, $t1        # t2 = low + high
    sra  $t2, $t2, 1          # t2 = (low + high) >> 1 (shift right arithmetic)

    # calculate absolute address of a
    sll  $t4, $t2, 2          # t4 = mid * 4 bytes
    add  $t4, $a0, $t4        # t4 = base + (mid * 4)
    
    # load mid_val
    lw   $t3, 0($t4)          # mid_val = a

    # check 1: if (mid_val == target) return mid
    beq  $t3, $a1, bs_found

    # check 2: if (mid_val < target) go right, else go left
    slt  $t4, $t3, $a1        # t4 = (mid_val < target) ? 1 : 0
    beq  $t4, $zero, bs_go_left

bs_go_right:
    # low = mid + 1
    addi $t0, $t2, 1
    j    bs_loop              # jump unconditionally back to loop start

bs_go_left:
    # high = mid - 1
    addi $t1, $t2, -1
    j    bs_loop              # jump unconditionally back to loop start

bs_not_found:
    # return -1
    addi $v0, $zero, -1       
    jr   $ra

bs_found:
    # return mid index
    add  $v0, $t2, $zero      
    jr   $ra