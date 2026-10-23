	# using acquire/release annotations
	.option norelax

	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.balign 64
counter: .word 10
	.balign 64
active_workers:	.word 0
	.section .text
	.globl _start

_start:
	mv s0, a0		# save hartID
	bnez s0, worker_entry	# if not hart0, we need to move to other harts
	li s2, 1		# start with hart 1
	la s3, active_workers	# s3 = address of active workers

spawn_harts:
	# Pre increment active workers before waking up
1:	lr.w t2, (s3)		# Get the current value of active_workers in t2 , which would be 0 
	addi t2, t2, 1		# increment t2 by 1
	sc.w t3, t2, (s3)	# store the increment back to active_workers
	bnez t3, 1b

	# Wake up hart 1
	mv a0, s2			# we now move hart1 to a0
	la a1, _start			# store address of _start in a1
	li a2, 0			# a2 = 1 , opaque value
	li a7, SBI_EXT_HSM		# 
	li a6, SBI_HSM_HART_START	# move Hart1 to RUNNING STATE
	ecall				# call OpenSBI
	beqz a0, next_hart		# if success , then a0 = 0 we move to increment next hart 

	# if ecall failed and a0 is not zero, that means no more harts to increment
2:	lr.w t2, (s3)			# Get active workers value (Which should be last hart incremented)
	addi t2, t2, -1			# decrement
	sc.w t3, t2, (s3)		# store the decrement back to active_workers
	bnez t3, 2b			
	j hart0_work 			# start instructions in hart0_work

next_hart:
	addi s2, s2, 1			# increment , move to next hart
	j spawn_harts			# j to spawn the harts 

hart0_work:
	la t0, counter			# Get the address of counter
	la t1, active_workers		# Get address of active workers
atomic_inc0:
	lr.w t2, (t0)			# Get the value stored in counter in t2 and set reservation
	addi t2, t2, 1			# increment the value
	sc.w t3, t2, (t0)		# store the value back to counter, if reservation is valid
	bnez t3, 1b			# if reservation is not valid we retry

	# we need to wait for active workers to complete before we read the counter
	# lr.w.aq attaches the acquire annotation directly in to the load queue
	# so that younger loads (like reading the counter below) cannot be executed
	# speculatively before all harts have completed their increment of counter

spin_loop:
	lr.w.aq t4, (t1)		# Get the value of active workers and add aq tag
	bnez t4, spin_loop		# we wait till it's zero

	# now read the counter

	la t0, counter			# Get the address of counter and store in t0
	lw t1, (t0) 			# Get the value stored in t1

print:
	li t3, 10			# we need to divide the value by 10
	div t2, t1, t3			# Use div and get quotient
	rem s1, t1, t3			# use rem to get reminder

	addi a0, t2, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

	addi a0, s1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

park:
	wfi
	j park

worker_entry:
	la t0, counter			# Get the latest counter

atomic_inc:
	lr.w t1, (t0)			# Read the latest value of counter and set reservation
	addi t1, t1, 1			# increment the value
	sc.w t2, t1, (t0)		# store the value back to counter if reservation is valid
	bnez t2, atomic_inc		# if reservation is not valid we try again

	la t3, active_workers
decrement_loop:
	lr.w t4, (t3)
	addi t4, t4, -1
	# we want to make sure everything before this is comitted before we write back to active_Workers
	sc.w.rl t5, t4, (t3)
	bnez t5, decrement_loop
	j park
