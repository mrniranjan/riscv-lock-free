	# example of preserved program order Rule 1
	# b is a store and a and b access overlapping memory address

	.section .data
	.align 3

var:
	.dword 43
	.section .text
	.globl _start
_start:
	la t0, var
	lw a0, 0(t0)
	sw a0, 2(t0)
exit:
	li x17, 93
	ecall 
	
