	# Exercise 2: Spinlock acquisition and release
	.option norelax
	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0


	.section .data
	.balign 64
lock_var:	.word 0
	.balign 64
payload:   .word 20
	.balign 64
total_harts: .word 2

	.section .text
	.globl _start
_start:
	mv s0, a0		# save the current hart-ID to s0
	bnez s0, hart1_entry	# if s0!=0, it's hart1

hart0_entry: 	# wakeup hart1
	li a0, 1
	la a1, _start
	li a2, 1
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START
	ecall

	# we want to update the payload, but first need to fetch the lock
	# we can fetch the lock only if lock is free i.e lock_var == 0
	# we check if lock_var is 0 otherwise we wait

	# Initialize registers
	la t0, lock_var
	la t1, payload 
	
check_lock_0:
	# we are following Test and Test-and-set lock (TTAS) 
	lw t2, (t0)			# Get the current value lock_var in to t2 and set reservation 
	bnez t2, check_lock_0		# we check if the t2 is not zero, if it's zero we wait, another hart may be writing to it

spin_lock_0:				# we do the spin lock
	lr.w t2, (t0)			# Get the value of lock (t0) in to t2 and set reservation
	bnez t2, check_lock_0		# if t2 is not zero we loop back to check_lock_0
	li t3, 1			# if we are here that means we can lock 
	sc.w t4, t3, (t0)		# set the lock and release the reservation 
	bnez t4, spin_lock_0		# Verify our reservation is valid 

	la t1, payload			# Get the payload address
	lw t2, (t1)			# Get he current value of t2
	addi t2, t2, 1			# increment the value 
	sw t2, (t1)			# store the value

	# we completed the updating of payload now we need to mark as done using total_harts

	la t0, total_harts		# Get the address of total harts
	lw t1, (t0)			# Get the value in to t1 
	addi t1, t1, -1			# Decrement the value 
	sw t1, (t0)			# store it back to total_harts

	# Now we release the lock
	la t0, lock_var			# Get the address of lock_var
release_lock_0:
	lr.w t2, (t0)			# Get  the current value lock and set reservation
	li t2, 0			# set the value 0 to release the lock
	sc.w.rl t3, t2, (t0)		# write back to lock_var 
	bnez t3, release_lock_0		# try again if reservation failed
	j park				# sleep
	
hart1_entry:

	# initialize
	la t0, lock_var
	la t1, counter

	# similar to hart0, we do Test and Test-and-set lock (TTAS)
check_lock_1:				
	lw t2, (t0)			# Get the current value of lock_var in to t2
	bnez t2, check_lock_1		# check if t2 is not zero, the we wait
spin_lock_1:	
	lr.w.aq t2, (t0)		# Get the value of lock variable and set reservation
	bnez t2, check_lock_1		# if the value is not zero we spin again 
	li t3, 1			# Hold the lock 
	sc.w t4, t3, (t0)		# save the value back to lock_var
	bnez t4, spin_lock_1		# if reservation is not valid then we spin again

	la t1, payload			# Get the current address of payload in to t1
	lw t2, (t1)			# Get the current value
	addi t2, t2, 1			# increment the value
	sw t2, (t1)			# store the value back to payload


	# Decrement the total harts to signify that we are done updating the payload
	la t0, total_harts		# Get the current address of total_harts in to t0
	lw t1, (t0)			# Get the latest value of of total_harts in to t1
	addi t1, t1, -1			# Decrement
	sw t1, (t0)			# save the value back to total_harts

	# Release the lock

	la t0, lock_var			# Get the current address of lock_var
release_lock_1:
	lr.w t1, (t0)			# Get the current value of lock_var and set reservation
	li t2, 0			# store 0 in t2
	sc.w.rl t3, t2, (t0)		# save the value back to lock_var
	bnez t3, release_lock_1

	# lets print the payload but check if all harts are done completing their work
	# here we are hardcoding the harts to 2
	la t0, total_harts		# Get the total harts address
check_before_printing:
	lw t1, (t0)			# Get the latest value of total_harts
	bnez t1, check_before_printing	# if it's not zero , which means still there are harts that have not completed
	xor t2, t1, t1			# xor , this is used to add data dependency 

	# Get the latest 
	la t0, payload			# Get the latest payload address
	lw t1, (t0)			# Get the latest payload data
	add t3, t1, t2			# we are just adding with t3 (zero) from xor operation, this is done so that
					# hart1 speculatively doesn't try to compute payload before checking all harts have
					# completed their work. we are using PPO Rule 10 of data dependency

print:
	li t4, 10			
	div t5, t3, t4
	rem t6, t3, t4

	addi a0, t5, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

	addi a0, t6, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall
	j park

park:
	wfi
	j park
