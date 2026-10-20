	#### Exercise 1: The Multi-Value Producer-Consumer (Array Streaming)
	.option norelax
	# SBI Extension constants

	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_DBCN, 0x4442434E
	.equ SBI_DBCN_WRITE, 0

	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.align 3

flag:		.word 0
data_arr:	.word 10, 20, 30
sum_val:	.word 0
	.section .text
	.globl _start
_start:
	mv s0, a0
	bnez s0, hart1_entry

hart0_entry:
	# wake up  hart1
	li a0, 1
	la a1, _start
	li a2, 0
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START
	ecall

	###===========add array variables========#
	la t0, data_arr		# load the current address of data_arr in t0
	la t1, sum_val
	lw t2, 0(t1)
	li t3, 0		# index
	li t4, 3		# max index
add_loop:
	beq t3, t4, exit	# if t1 is equal to t2 the exit
	lw t5, 0(t0)		# load the first value of t0 to t3
	add t2, t2, t5		# add the sum 
	addi t0, t0, 4		# mv t0 ahead
	addi t3, t3, 1		# increment index
	j add_loop
	
exit:
	sw t2, 0(t1)		# store the result in sum_vl
	fence w, w
	la t0, flag		# get flag address
	li t3, 1		# set t3 to 1
	sw t3, 0(t0)		# store 1 in flag
	j park
	
hart1_entry:
	la t0, flag		# get flag address
loop:
	lw t1, (t0)		# read the value of flag
	beqz t1, loop		# if equal to zero we loop and wait
	fence r, rw		# barrier 
	la t2, sum_val		# get the value of sum_val
	lw t3, 0(t2)		# load the value in to t3

	li t4, 10		# Divide by 10 to get units and 10's place
	div t1, t3, t4
	rem s1, t3, t4

	addi a0, t1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

	addi a0, s1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

park:
	wfi
	j park	
