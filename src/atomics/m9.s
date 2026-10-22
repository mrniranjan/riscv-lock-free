	# Using load-reserved/store condition, 2 harts writing to gether using flag_var

	.option norelax
	# SBI Extension constants

	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.align 3

counter:	.word 10
flag_var:	.word 0
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

	#======increment===========#
	la t0, counter
	la t1, flag_var
atomic_inc0:
	lr.w t2, (t0)
	addi t2, t2, 1
	sc.w t3, t2, (t0)
	bnez t3, atomic_inc0

	fence w, w
	li t4, 1
	sw t4, (t1)
	j park
	
	#=========increment=========#
hart1_entry:
	la t0, counter
	la t1, flag_var
atomic_inc1:
	lr.w t2, (t0)
	addi t2, t2, 1
	sc.w t3, t2, (t0)
	bnez t3, atomic_inc1
	
hart1_loop:
	lw t4, (t1)
	beqz t4, hart1_loop
	fence r, r

	# Get the latest value from counter
	
	la t0, counter
	lw t2, (t0)

print:
	li t6, 10
	div t1, t2, t6
	rem s1, t2, t6

	addi a0, t1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

	addi a0, s1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall
park:
	wfi
	j park
	
