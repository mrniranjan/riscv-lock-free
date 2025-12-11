	.section .data
n1:
	.word 100
	.section .text
	.globl  _start
_start:
	li a0, 42  # immediate value to t0
	la t1, n1  # load address n1
	sw a0, 0(t1)	# overwrite the value in memory (n1) with 42
	lr.w.aq a0, (t1)	# load the value to a0 with acquire
	                        # respecting load value axiom with
                                # acquire semantic ordered

exit:
	li x17, 93
	ecall
