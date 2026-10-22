	# using load-reserved/store conditional , 2 harts writing together
	# using active_harts to check the number of harts
	.option norelax
	
	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.balign 64
counter:	.word 10
	.balign 64
active_workers:	 .word 0
	.section .text
	.globl _start
_start:
	mv s0, a0			# save my hartID
	bnez s0, worker_entry 		# if i am not Hart 0 , we move to worker
	li s2, 1			# s2 = target HartID to wake (start with Hart1)
	la s3, active_workers 		# s3 = address of active_workers

spawn_loop:
	# 1. Pre-Increment active workers before waking
1:	lr.w t2, (s3)
	addi t2, t2, 1
	sc.w t3, t2, (s3)
	bnez t3, 1b

	# 2.  Try to wake up hart1
	mv a0, s2
	la a1, _start
	li a2, 0
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START
	ecall
	beqz a0, next_hart	# if a0 = 0 , move to next hart

	# 3. If ecall failed (no more harts exist)
2:	lr.w t2, (s3)
	addi t2, t2, -1
	sc.w t3, t2, (s3)
	bnez t3, 2b
	j hart0_work

next_hart:
	addi s2, s2, 1	# next hart id
	j spawn_loop
hart0_work:
	la t0, counter
	la t1, active_workers
atomic_inc0:
	lr.w t2, (t0)
	addi t2, t2, 1
	sc.w t3, t2, (t0)
	bnez t3, atomic_inc0
	# wait for other harts to complete

spin_loop:
	lw t4, (t1)
	bnez t4, spin_loop

	fence r, r

	la t0, counter
	lw t1, (t0)
	
print:
	li t3, 10
	div t2, t1, t3
	rem s1, t1, t3

	addi a0, t2, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

	addi a0, s1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall
	j park
	
park:
	wfi
	j park

	
worker_entry:
	la t0, counter

atomic_inc:
	lr.w t1, (t0)
	addi t1, t1, 1
	sc.w t2, t1, (t0)
	bnez t2, atomic_inc

	fence w, w

	la t3, active_workers
decrement_loop:
	lr.w t4, (t3)
	addi t4, t4, -1
	sc.w t5, t4, (t3)
	bnez t5, decrement_loop
	j park
