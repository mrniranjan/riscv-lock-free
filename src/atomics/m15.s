	#Goal: Chain Release → → Acquire across three independent harts in a ring (0→1→2)

	.option norelax
	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START,0

	.section .data
	.balign 64
baton: .word 0
	.balign 64
accum:	.word 10
	.balign 64
total_harts:	.word 3
	
	.section .text
	.globl _start
	
_start:
	mv s0, a0		# save the current hart-ID to s0
	beq s0, hart0_entry
decide_hart:
	li t0, 1
	beq s0, t0, har1_entry
	j hart2_entry

hart0_entry:
	# wake up hart1
	li a0, 1
	la a1, _start
	li a2, 1
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START
	ecall

	# wake up hart2
	li a0, 2
	la a1, _start
	li a2, 2
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START
	ecall
	
	# we want to update accum but first check the baton (lock)
	# we can fetch baton only if baton is free i.e baton == 0
	# we check if baton is 0 otherwise we wait

	# initialize registers
	la t0, baton
	la t1, accum

check_baton_0:
	# we are following test and test-and-set lock (TTAS)
	lw t2, (t0)			# Get the current value of baton in to t2
	bnez t2, check_baton_0		# if t2 !=0, we wait

spin_lock_0:
	lr.w.aq t2, (t0)		# load the value baton and set reservation 
	bnez t2, check_baton_0		# if still t2 is not zero, we wait again 
	li t3, 1			# we got the baton, now set to 1
	sc.w t4, t3, (t0)		# store the value to baton,
	bnez t4, spin_lock_0		# if the reservation is not valid we try again 

	lw t2, (t1)			# Get the current value of accum in to t2
	addi t2, t2, 5			# add 5 to the current value 
	sw t2, (t1)			# store the result back to accum

	# we completed updating the accum, now to denote completed we reduce the
	# total harts by 1

	la t0, total_harts		# Get address of total_harts address
	lw t1, (t0)			# Get the value stored 
	addi t1, t1, -1			# decrement by 1
	sw t1, (t0)			# save the updated value to total_harts

	# Release the lock
	la t0, baton
release_lock_0:
	lr.w t2, (t0)			# Get the current value and set reservation
	li t2, 1			# update the value to 1
	sc.w.rl t3, t2, (t0)		# write back the updated value to baton
	bnez t3, release_lock_0		# if reservation is not valid we wait
	j park
	
hart1_entry:
	# initialize
	la t0, baton
	li t1, 1
	# similar to hart0,  we do TTAS
check_lock_1:
	lw t2, (t0)			# Get the current value of baton in to t1
	bne t2, t1, check_lock_1	# if t2 !=1 we wait

	lw t2, (t1)			# Get the current value of accum
	slli t2, t2, 1			# multiply by 2
	sw t2, (t1)			# save the value back to accum

	# decrement total harts to signify we are done updating the accum
	la t0, total_harts		# Get the address of total_harts
	lw t1 , (t0)			# Get the current value 
	addi t1, t1, -1			# Decrement by 1
	sw t1, (t0)			# save the value back to total_harts

	# release the lock
	la t0, baton
release_lock_0:			
	lr.w t2, (t0)			# Get the current value and set reservation
	li t2, 2			# update the value to 1
	sc.w.rl t3, t2, (t0)		# write back the updated value to baton
	bnez t3, release_lock_0		# if reservation is not valid we wait
	j park	

hart2_entry:
	#initialize
	la t0, baton
	li t1, 2

check_lock_2:
	lw t2, (t0)
	bne t2, t1, check_lock_2

	la t1, accum
	lw t2, (t1)
	addi t2, t2, 5
	sw t2, (t1)

print:
	li t3, 10
	div t4, t2, t3,
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
