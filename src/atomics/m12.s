	# Exercise 1: The Relay Flag (Handoff Pipeline)
	.option norelax

	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.balign 64
data_payload:	.word 0
	.balign 64
flag:	.word 0

	.section .text
	.globl _start
_start:
	mv s0, a0		# save Hart ID
	bnez s0, hart1_entry

hart0_entry:
	# wake up hart1
	li a0, 1
	la a1, _start
	li a2, 1
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START
	ecall

	#======== update data_payload =========#
	la t0, data_payload
	la t1, flag
	
	lw t2, (t0)
	li t2, 42
	sw t2, (t0)

update_flag_loop0:	
	lr.w t4, (t1)
	li t4, 1
	sc.w.rl t5, t4, (t1)
	bnez t5, update_flag_loop0
	j park
	
hart1_entry:
	
	la t0, data_payload
	la t1, flag
	li t2, 1

spin_loop:
	lr.w.aq t3, (t1)
	bne t2, t3, spin_loop

	lw t2, (t0)
	addi  t2, t2, 10
print:
	li t3, 10
	div t4, t2, t3
	rem t5, t2, t3

	addi a0, t4, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

	addi a0, t5, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall
	j park

park:
	wfi
	j park
	
