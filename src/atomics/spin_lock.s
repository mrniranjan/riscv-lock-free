	.option norelax

	# SBI Extension constants
	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_DBCN, 0x4442434E
	.equ SBI_DBCN_WEITE, 0

	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.align 3
	
lock_var:
	.word 0
var1:
	.word 10
var2:
	.word 20
sum:
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

	########## Writer Side ################

	la t0, lock_var
	la t1, var1
	la t2, var2
	li t3, 1	
writer_lock_loop:
	lr.w t4, (t0)			# read current lock value
	bnez t4, writer_lock_loop	# spin-wait if lock != 0
	sc.w.aq t6, t3, (t0)		# Try to write 1 to acquire 
	bnez t6, writer_lock_loop

	#----------critical section--------#
	lw t6, (t1)			# Read var1 (10)
	lw a3, (t2)			# Read var2 (20)
	add a4, t6, a3			# 10 + 20 = 30
	la t6, sum
	sw a4, (t6)			# store 30 in to sum

	#----------reset the lock---------#
	fence w, w
	sw x0, 0(t0)
	j park
	
	########### Reader section ###############
hart1_entry:
	la t0, lock_var
	la t1, sum
	li t3, 1
reader_lock_loop:
	# to read sum safely, th ereader should also acquire the lock

	lr.w t2, (t0)
	bnez t2, reader_lock_loop
	sc.w.aq t4, t3, (t0) # attemp to lock
	bnez t4, reader_lock_loop

	lw t5, (t1)
	fence r, w
	sw x0, 0(t0)

	### print the sum
	li t6, 10
	div t1, t5, t6
	rem t2, t5, t6

	addi a0, t1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

	addi a0, t2, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

park:
	wfi
	j park
	
	
	
	
