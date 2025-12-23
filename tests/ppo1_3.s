	.section .data
n1:
	.long 42, 43
	
	.section .text
	.globl _start
_start:
	lui t0, %hi(n1)
	addi t0, t0, %lo(n1)
	li a0, 0

	lw t1, 0(t0)
	lw t2, 4(t0)

	# the below instruction causes the value 43
	# be stored in memory and will not run
	# lw instruction until the value is committed
	# to memory
	amoswap.w t1, t2, (t0)
	lw a0, 0(t0)
	
	
exit:
	li x17,93
	ecall
