	# The 3-Element Array Batch (1 Fence for N Writes)
	.option norelax
	# SBI Extension constants
	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_DBCN, 0x4442434E
	.equ SBI_DBCN_WRITE, 0

	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.align 3

data_var:	.word 0,0,0
flag:		.word 0
	.section .text
	.globl _start
_start:
	mv s0, a0
	bnez s0, hart1_entry

hart0_entry:
	# wake up hart1
	li a0, 1
	la a1, _start
	li a2, 0
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START
	ecall

	#============= Producer ==================#
	la t0, data_var
	li t1, 0		# index
	li t2, 3		# max index
	li t3, 0		# value to be incremented
	
add_loop:
	beq t1, t2, exit		# if reached to the end of the index we exit
	addi t3, t3, 10
	sw t3, (t0)
	addi t0, t0, 4
	addi t1, t1, 1
	j add_loop
exit:
	fence w, w
	la t0, flag
	li t1, 1
	sw t1, 0(t0)
	j park
	#========== consumer =======================#
hart1_entry:
	la t0, flag
	la t1, data_var
	li t4, 0
	li t5, 3
loop:
	lw t3, (t0)
	beqz t3, loop
	fence r, r
	li t0, 0

for_loop:
	beq t4, t5, exit_loop
	lw t6, 0(t1)
	add t0, t0, t6
	add t1, t1, 4
	addi t4, t4, 1
	j for_loop

exit_loop:
	li t4, 10
	div t1, t0, t4
	rem s1, t0, t4

	addi a0, t1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

	addi a0, s1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall
park:
	wfi
	j park
