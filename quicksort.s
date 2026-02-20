# given an array a
# $a0 -> base address of array a
# $a1 -> left index
# $a2 -> right index

# c logic
# void swap(int v[], int i, int j) {
#     int temp = v;
#     v = v;
#     v = temp;
# }
# 
# void sort(int v[], int left, int right) {
#     int i, last;
#     if (left >= right) return;
#     
#     last = left;    // pivot is v
#     for (i = left + 1; i <= right; i++) {
#         if (v < v) {
#             last++;
#             swap(v, last, i);
#         }
#     }
#     swap(v, left, last);
#     sort(v, left, last - 1);
#     sort(v, last + 1, right);
# }

.data
    # 10 unsorted elements
    array_a: .word 50, 10, 90, 30, 70, 40, 80, 20, 100, 60

.text
.globl main

main:
    # load base address of array a into $a0
    lui  $a0, 0x1001
    ori  $a0, $a0, 0x0000
    
    # setup arguments: left = 0, right = 9
    add  $a1, $zero, $zero
    addi $a2, $zero, 9
    
    # call sort
    jal  sort
    
    # exit
    addi $v0, $zero, 10
    syscall

swap:
    # leaf function (no stack frame required)

    # calculate memory address of v
    sll  $t0, $a1, 2          # t0 = i * 4 bytes
    add  $t0, $a0, $t0        # t0 = v + i*4

    # calculate memory address of v
    sll  $t1, $a2, 2          # t1 = j * 4 bytes
    add  $t1, $a0, $t1        # t1 = v + j*4

    # perform swap
    lw   $t2, 0($t0)          # t2 = v
    lw   $t3, 0($t1)          # t3 = v
    sw   $t3, 0($t0)          # v = t3
    sw   $t2, 0($t1)          # v = t2

    # return to caller
    jr   $ra

sort:
    # prologue
    # we have to calculate exact stack frame size (8-byte aligned)
    # 16 bytes: $a0-$a3 - mandatory per MIPS O32 ABI
    # 28 bytes: $s0-$s4, $fp, $ra
    #  4 bytes: padding for 8-byte alignment
    # total: 48 bytes
    addi $sp, $sp, -48
    sw   $ra, 44($sp)
    sw   $fp, 40($sp)
    sw   $s0, 36($sp)         # s0 = v
    sw   $s1, 32($sp)         # s1 = left
    sw   $s2, 28($sp)         # s2 = right
    sw   $s3, 24($sp)         # s3 = last
    sw   $s4, 20($sp)         # s4 = i
    add  $fp, $sp, $zero

    # save volatile arguments to preserved callee-saved registers
    add  $s0, $a0, $zero
    add  $s1, $a1, $zero
    add  $s2, $a2, $zero

    # if (left >= right) return
    slt  $t0, $s1, $s2        # t0 = (left < right) ? 1 : 0
    beq  $t0, $zero, sort_epilogue

    # initialize pivot index: last = left
    add  $s3, $s1, $zero

    # loop initialization: i = left + 1
    addi $s4, $s1, 1

    # loop bounds check (skip loop entirely if i > right)
    slt  $t0, $s2, $s4        # t0 = (right < i) ? 1 : 0
    bne  $t0, $zero, sort_loop_end

sort_loop:
    # calculate &v and load v
    sll  $t0, $s4, 2
    add  $t0, $s0, $t0
    lw   $t1, 0($t0)          # t1 = v

    # calculate &v and load v
    sll  $t2, $s1, 2
    add  $t2, $s0, $t2
    lw   $t3, 0($t2)          # t3 = v

    # if (v < v)
    slt  $t0, $t1, $t3        # t0 = (v < v) ? 1 : 0
    beq  $t0, $zero, sort_loop_inc

    # last++
    addi $s3, $s3, 1

    # swap(v, last, i)
    add  $a0, $s0, $zero      # arg0 = v
    add  $a1, $s3, $zero      # arg1 = last
    add  $a2, $s4, $zero      # arg2 = i
    jal  swap

sort_loop_inc:
    # i++
    addi $s4, $s4, 1

    # loop rotation check: if (i <= right) continue looping
    # mathematically equivalent to: if !(right < i)
    slt  $t0, $s2, $s4        # t0 = (right < i) ? 1 : 0
    beq  $t0, $zero, sort_loop

sort_loop_end:
    # swap(v, left, last)
    add  $a0, $s0, $zero
    add  $a1, $s1, $zero
    add  $a2, $s3, $zero
    jal  swap

    # sort(v, left, last - 1)
    add  $a0, $s0, $zero
    add  $a1, $s1, $zero
    addi $a2, $s3, -1
    jal  sort

    # sort(v, last + 1, right)
    add  $a0, $s0, $zero
    addi $a1, $s3, 1
    add  $a2, $s2, $zero
    jal  sort

sort_epilogue:
    # epilogue
    # restore registers in reverse order of prologue
    lw   $s4, 20($sp)
    lw   $s3, 24($sp)
    lw   $s2, 28($sp)
    lw   $s1, 32($sp)
    lw   $s0, 36($sp)
    lw   $fp, 40($sp)
    lw   $ra, 44($sp)
    addi $sp, $sp, 48

    jr   $ra