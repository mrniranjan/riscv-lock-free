	.option norelax
	
	# SBI Extension constants
	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_DBCN, 0x4442434E
	.equ SBI_DBCN_WRITE, 0

	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.align 3
flag_var:
	.word 0
data_var:
	.word 0

	.section .text
	.globl _start
_start:
	mv s0, a0
	bnez s0, hart1_entry

hart0_entry:
	# wake up hart 1
	li a0, 1
	la a1, _start
	li a2, 0
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START
	ecall

	# ======== producer ===========

	la t0, data_var
	li t1, 0x42
	sw t1, 0(t0)


	la t2, flag_var
	li t3, 1
	
flag_publish_loop:
	lr.w t4, (t2)
	sc.w.rl t5, t3, (t2)
	bnez t5, flag_publish_loop
	j park

hart1_entry:
	la t2, flag_var
spin_wait:
	#============ consumer ==============
	lw t3, 0(t2)
	beqz t3, spin_wait

	lr.w.aq t3, (t2)
	

	la t0, data_var
	lw t4, 0(t0)

	fence w, w

	li t5, 10
	div t1, t4, t5
	rem t2, t4, t5

	addi a0, t1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

	addi a0, t2, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall
	
	
park:
	wfi
	j park
	
