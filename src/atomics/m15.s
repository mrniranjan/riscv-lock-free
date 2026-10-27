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

	.section .text
	.globl _start
	
_start:
	mv s0, a0		# save the current hart-ID to s0
	beq s0,zero, hart0_entry
decide_hart:
	li t0, 1
	beq s0, t0, hart1_entry
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

	lw t2, (t1)			# Get the current value of accum in to t2
	addi t2, t2, 5			# add 5 to the current value 
	sw t2, (t1)			# store the result back to accum

release_lock_0:
	lr.w.aq t3, (t0)
	addi t3, t3, 1			# update the value to 1
	sc.w.rl t4, t3, (t0)		# write back the updated value to baton
	bnez t4, release_lock_0		# if reservation is not valid we wait
	j park
	
hart1_entry:
	# initialize
	la t0, baton
	la t1, accum
	li t2, 1
check_lock_1:
	lr.w.aq t3, (t0)		# Get the current value of baton in to t1
	bne t3, t2, check_lock_1	# if t3 !=1 we wait
	
	lw t2, (t1)			# Get the current value of accum
	slli t2, t2, 1			# multiply by 2
	sw t2, (t1)			# save the value back to accum

update_baton_1:
	lr.w t2, (t0)
	addi t2, t2, 1			# update the value to 2
	sc.w.rl t3, t2, (t0)		# write back the updated value to baton
	bnez t3, update_baton_1
	j park	

hart2_entry:
	#initialize
	la t0, baton
	la t1, accum
	li t2, 2

check_lock_2:
	lr.w.aq t3, (t0)
	bne t3, t2, check_lock_2
	
	lw t2, (t1)
	addi t2, t2, 3
	sw t2, (t1)
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
