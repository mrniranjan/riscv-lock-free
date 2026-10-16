	.option norelax
	# SBI Extension constants

	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXTG_DBCN, 0x4442434E
	.equ SBI_DBCN_WRITE, 0

	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.align 3

flag_var:
	.word 0

var1:
	.word 25
var2:
	.word 32
value:
	.word 0

	.section .text
	.globl _start
_start:
	mv s0, a0
	bnez s0, hart1_entry

hart0_entry:
	# Wake up Hart 1
	li a0, 1
	la a1, _start
	li a2, 0
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START
	ecall

	##========= subtracting two variables ===========

	la t0, var1		# store address of var1 in t0
	lw t1, 0(t0)		# store value from address in t1
	la t0, var2		# store address of var1 in t0
	lw t2, 0(t0)		# store value from address in t2
	sub t2, t2, t1	 	# subtract values stored in t1 and t2
	la t0, value		# store address of value in t0
	sw t2, 0(t0)		# store the subtracted value in value
	la t0, flag_var		# store address flag_var in t3
	li t1, 1		# store value 1 in t1
flag_loop:
	lr.w.aq t2, (t0)	# load the value store in flag and set reservation
	bnez t2, flag_loop	# if it's not zero we wait
	sc.w.rl t3, t1, (t0)	# set the value 1 and release reservation
	bnez t3, flag_loop
	j park

hart1_entry:
	#=========== read the value ====================

	la t0, flag_var
loop:
	lw t1, (t0)
	beqz t1, loop

	#==================
	la t2, value
	lw t3, 0(t2)

	li t4, 10
	div t1, t3, t4
	rem t2, t3, t4

	addi a0, t1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

	addi a0, t2, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

park:
	wfi
	j park
	
	
