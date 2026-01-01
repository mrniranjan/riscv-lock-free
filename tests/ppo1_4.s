	.section .data
	.align 3
data:
	.dword 0x1234567890ABCDEF
flag:
	.word 0
	.section .text
	.globl _writer
writer:
	la t0, data
	li t1, 0xFEEDFACEDEADBEEF
	sd t1, 0(t0)

	# Rule 4: fence w, w all previous stores must complete
	# before any later stores
	fence w, w

	# set flag = 1
	la t0, flag
	li t1, 1
	sw t1, 0(t0)

	ret

	.globl _reader
_reader:
	la t0, flag
	la t1, data

spin:
	lw t2, 0(t0)
	beqz t2, spin

	# now safe to read data
	ld a0, 0(t1)

	ret
