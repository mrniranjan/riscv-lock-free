# example of preserved program order

	.section .data
n1:
	.word 52
	
	.section .text
	.globl _start
_start:
	li t0, 42
	la t1, n1 	# load address of n1 to t0
	sw t0, 0(t1) 	# we are overriting the value of memory from 52 to 42
	lw a0, 0(t1) 	# lets check if the value 
	
exit:
	li x17, 93
	ecall
