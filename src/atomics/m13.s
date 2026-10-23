	#Exercise 2: Spinlock Acquisition and Release
	.option norelax

	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.balign 64
lock_var: .word 0
	.balign 64
counter:  .word 10
	.balign 64
total_harts: .word 2

	.section .text
	.globl _start
_start:	
	mv s0, a0
	bnez s0, hart1_entry

hart0_entry:
	# wake up hart 1
	li a0, 1
	la a1, _start
	li a2, 1
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START
	ecall

	la t0, lock_var
	la t1, counter
	
spin_lock_0:	
	lr.w.aq t2, (t0)
	bnez t2, spin_lock_0
	li t3, 1
	sc.w t4, t3, (t0)
	bnez t4, spin_lock_0
	
	la t1, counter
	lw t2,(t1)
	addi t2, t2, 1
	sw t2, (t1)

	# update the completed hart
	
	la t0, total_harts
	lw t1, (t0)
	addi t1, t1, -1
	sw t1, (t0)
	
	la t0, lock_var
release_lock_0:
	lr.w t2, (t0)
	li t2, 0
	sc.w.rl t3, t2, (t0)
	bnez t3, release_lock_0

	j park

hart1_entry:
	la t0, lock_var
	la t1, counter

spin_lock_1:	
	lr.w.aq t2, (t0)
	bnez t2, spin_lock_1
	li t3, 1
	sc.w t4, t3, (t0)
	bnez t4, spin_lock_1
	
	la t1, counter
	lw t2, (t1)
	addi t2, t2, 1
	sw t2, (t1)

	la t0, total_harts
	lw t1, (t0)
	addi t1, t1, -1
	sw t1, (t0)
	
	la t0, lock_var
	
release_lock_1:
	lr.w t2, (t0)
	li t2, 0
	sc.w.rl t3, t2, (t0)
	bnez t3, release_lock_1
	# also check no one is still holding the lock_var before printing

	la t4, total_harts
check_lock_before_printing:
	lw t6, (t4)
	bnez t6, check_lock_before_printing

	xor t5, t6, t6
	
	la t1, counter
	lw t2, (t1)
	add t2, t2, t5
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
