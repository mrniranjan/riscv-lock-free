	#The 3-Hart Relay Pipeline (Hart 0→ Hart 1→ Hart 2)
	.option norelax
	# SBI Extension constants
	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_DBCN, 0x4442434E
	.equ SBI_DBCN_WRITE, 0

	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.align 3

stage1_data:	.word 0
stage2_data:	.word 0
flag_1:	 	.word 0
flag_2:		.word 0

	.section .text
	.globl _start
_start:
	mv s0, a0
	beq s0, zero, hart0_entry
decide_hart:
	li t0, 1
	beq s0, t0, hart1_entry
	j hart2_entry
	
hart0_entry:
	# wake up hart1
	li a0, 1
	la a1, _start
	li a2, 0
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START
	ecall
	
	# wake up hart 2
	li a0, 2
	la a1, _start
	li a2, 0
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START
	ecall

set_values:
	la t0, stage1_data	# Get stage1_data address
	la t1, stage2_data	# Get stage2_data address
	la t2, flag_1		# Get flag_1 address
	la t3, flag_2		# Get flag_2 address

	li t4, 10		# set initial value 10
	sw t4, 0(t0)		# store the value in stage1_data
	fence w, w		# add barrier to avoid reorder
	li t5, 1		# set t5 to 1 
	sw t5, (t2)		# store 1 in flag_1
	j park			# sleep 

hart1_entry:
	la t0, flag_1		# Get flag_1 address
	la t1, stage1_data	# Get stage1_data address
	la t2, stage2_data	# Get stage2_data address
	la t3, flag_2		# Get flag_2 address
hart1_loop:
	lw t4, (t0)		# Get curret value flag and store in t4
	beqz t4, hart1_loop	# if it's zero we wait
	fence r, rw		# add barrier to avoid reorder
	lw t5, (t1)		# Get stage1_Data value in to t5
	addi t5, t5, 15		# add 15 to the current value of t5, t5= 15 + 10 
	sw t5, (t2)		# store the result in stage2_data variable
	li t6, 1		# set t6 to 1
	fence w, w
	sw t6, (t3)		# store 1 in flag_2
	j park			# sleep
	
hart2_entry:
	la t0, flag_2		# Get address of flag2 in t0
	la t1, stage2_data	# Get address of stage2_data 

hart2_loop:
	lw t2, (t0)		# get current value of flag_2
	beqz t2, hart2_loop	# we wait till it's zero
	fence r, r		# add barrier
	lw t3, (t1)		# Get the value of stage2_data
	
print:
	li t4, 10		# set 10 to t4
	div t1, t3, t4		
	rem s1, t3, t4

	addi a0, t1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

	addi a0, s1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

park:
	wfi
	j park
	
	
	

	
	
	
