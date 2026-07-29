	### Basic load reserved and store conditional example
	
	.option norelax				# Disable linker relaxation for bare-metal
	
	# SBI Extention constants
	.equ SBI_CONSOLE_PUTCHAR, 1      	# Legacy SBI putchar function
	.equ SBI_EXT_DBCN, 0x4442434E		# Debug console extension
	.equ SBI_DBCN_WRITE, 0			# Console write function ID

	.equ SBI_EXT_HSM, 0x48534D		# Hart state mgmt ext
	.equ SBI_HSM_HART_START, 0		# Hart state function id

	.section .data
	.align 3
	
counter_var:
	.word 0					# The shared counter variable
	
	.section .text
	.globl _start

_start:
	mv s0, a0				# save Hart ID (passed by opensbi in a0)
	bnez s0, common_entry

hart0_entry:
	li a0, 1				# Target Hart ID = 1
	la a1, _start				# jump address for Hart 1
	li a2, 0				# opaque parameter
	li a7, SBI_EXT_HSM              	# EID = 0x48534D
	li a6, SBI_HSM_HART_START       	# FID = 0
	ecall

common_entry:
	la t0, counter_var
	
retry_increment:
	lr.w t1, (t0)

	addi t1, t1, 1
	sc.w t2, t1, (t0)
	bnez t2, retry_increment

	fence rw, rw
	li t3, 65 		# Prints ASCII A
	add a0, s0, t3 		# A + Hart ID
	li a7, SBI_CONSOLE_PUTCHAR
	ecall

park:
	wfi
	j park
