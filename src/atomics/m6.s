	# To way ping-pong handshake

	.option norelax
	# SBI Extension constants

	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXTG_DBCN, 0x4442434E
	.equ SBI_DBCN_WRITE, 0

	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.align 3

flag_1:	.word 0
flag_2:	.word 0
data:	.word 0
result:	.word 0

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

	#==========ping=========#
	la t0, data		# load address data in to t0
	la t1, flag_1		# load address of flag_1 into t1
	li t6, 10
	sw t6, 0(t0)		# store 10 in data and send it to hart1
	fence w, w		# add the barrier
	li t2, 1
	sw t2, 0(t1)		# set the flag
	la t3, flag_2
hart0_loop:
	lw t4, 0(t3)		# Get the current value of flag_2
	beqz t4, hart0_loop	# we wait till flag_2 is 1
	fence r, rw
	la t2, result
	lw t3, 0(t2)

	li t5, 10
	div t1, t3, t5
	rem s1, t3, t5

	addi a0, t1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall
	addi a0, s1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall
park:
	wfi
	j  park
	
	
hart1_entry:
	la t0, data
	la t1, flag_1
	la t2, flag_2
	la t3, result
	
hart1_loop:
	lw t4, (t1)			#
	beqz t4, hart1_loop
	fence r, rw
	lw t4, (t0)
	li t5, 1
	sllw t6, t4, t5
	sw t6, 0(t3)
	fence w, w
	li t5, 1
	sw t5, 0(t2)
	j park
