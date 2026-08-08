	.option norelax

	# SBI Extension constants
	.equ SBI_CONSOLE_PUTCHAR, 1
	.equ SBI_EXT_DBCN, 0x4442434E
	.equ SBI_DBCN_WRITE, 0

	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	.section .data
	.align 3
flag_var:
	.word 0
var1:
	.word 25
var2:
	.word 32
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

	#=========== adding two variables =============
	la t0, var1		# store var1 address in t0
	lw t1, 0(t0)		# store value stored in var1 in t1
	la t0, var2		# store var 2 address in t0
	lw t2, 0(t0)		# store value stored in var in t2
	add t2, t1, t2		# add values stored in t1, and t2 and store in t2
	la t0, sum		# Get address of sum variable and store in t0
	sw t2, 0(t0)		# store the sum in memory address i.e sum's address

	la t3, flag_var		# Get address of flag_var and store it in t3
	li t4, 1		# store value 1 in t4
	
flag_loop:
	lr.w zero, (t3)		# store the current value stored in address(t3) in t5  and also set reservation 
	sc.w.rl t6, t4, (t3)	# copy the value 1 in memory address (t3) and the result of the operation in t6
	bnez t6, flag_loop	# retry if sc failed
	j park			

hart1_entry:
	la t2, flag_var		# load address of flag_var in t2
spin_wait:
	lr.w.aq t3, 0(t2)		# get the current value of flag_var in t3 
	beqz t3, spin_wait	# check if value stored in flag is zero , 

	la t0, sum		# load address of sum to t0
	lw t4, 0(t0)		# load the value stored in the memory addres stored in t0 in t4

	li t5, 10		
	div t1, t4, t5
	rem t2, t4, t5

	addi a0, t1, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

	addi a0, t2, 48
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

park:
	wfi
	j park	
