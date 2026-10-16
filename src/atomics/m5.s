	#The Two-Way Ping-Pong Handshake
	.option norelax
	# SBI Extension constants

	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXTG_DBCN, 0x4442434E
	.equ SBI_DBCN_WRITE, 0

	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.align 3

flag_1:		.word 0
flag_2:		.word 0
data:		.word 10
result:		.word 0

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

	#==============ping=========#
	la t0, data		# Get address of data
	la t1, result
	la t2, flag_1
	lw t3, 0(t0)		# get value and store in t1
	addi t3, t3, 5		# add 5 to the data
	sw t3, 0(t1)		# store to the result
	fence w, w		# add barrier
	li t3, 1
	sw t3, 0(t2)		# set flag_1
	#----- wait for flag_2-----#
	la t3, flag_2		# Get flag
hart0_loop:
	lw t4, 0(t3)		# get the current value of flag_2
	beqz t4, hart0_loop	# wait till flag_2 is 1
	fence r, rw
	
	la t2, result		# read the result address
	lw t3, 0(t2)		# get the value from result
	
	li t5, 10		# print the value 
	div t1, t3, t5
	rem s1, t3, t5

	addi a0, t1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall
	addi a0, s1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall
park:
	wfi
	j park
	#================pong============#
hart1_entry:
	la t0, result
	la t1, flag_1
	la t2, flag_2
hart1_loop:
	lw t3, (t1)			# check flag
	beqz t3, hart1_loop		# if t2==0 , wait
	fence r, rw
	lw t4, 0(t0)			# get the current result
	addi t4, t4, 5			# update the value with 5
	sw t4, 0(t0)			# store the result to result
	fence w, w
	li t5, 1			#
	sw t5, 0(t2)			# set flag to 1
	j park
