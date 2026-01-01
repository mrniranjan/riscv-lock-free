	#------------Constants to write to terminal---------#
	.equ SBI_EXT_DBCN, 0x4442434E
	.equ SBI_DBCN_WRITE, 0

	#------------Constants for Hart Management----------#
	.equ SBI_EXT_HSM, 0x48534D
	.equ SBI_HSM_HART_START, 0

	# Rule 
	.section .data
	.align 3
data:
	.dword 0x1234567890ABCDEF

writer_msg:
	.ascii "FOO\n"
reader_msg:
	.ascii "BAR\n"
flag:
	.word 0
	.section .text
	.globl _start
_start:
	# when opensbi starts Hart0, a0 contains hart 0
	# when Hart 0 wakes Hart 1(later), Hart 1 see its Hart ID in a0
	mv t0, a0
	beqz t0, producer
	li t1, 1
	beq t0, t1, consumer
	j park

producer:
	# wake up consumer(hart1)
	li a0, 1	# set a0 to Hart1 id
	la a1, _start	# set the address of the start function
	li a2, 0	# some opaque data
	li a7, SBI_EXT_HSM
	li a6, SBI_HSM_HART_START

	# write data
	la t2, data
	li t3, 0xFEEDFACEDEADBEEF
	sd t3, 0(t2)

	# Rule 4: Fence w, w all previous stores must comlete
	fence w, w

	# set flag = 1
	la t4, flag
	li t5, 1
	sw t1, 0(t4)

	# Print writer message
	la a1, writer_msg
	li a0, 4
	li a6, SBI_DBCN_WRITE
	li a7, SBI_EXT_DBCN
	ecall 
	j park

consumer:
	la t4, flag
spin_wait:
	lw t5, 0(t4)
	beqz t5, spin_wait

	fence r, r
	la a1, data
	ld a2, 0(a1)

	la a1, reader_msg
	li a0, 3
	li a6, SBI_DBCN_WRITE
	li a7, SBI_EXT_DBCN
	ecall
	j park

park:
	wfi
	j park
	

	
