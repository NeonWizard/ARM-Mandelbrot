@ write your code here
	.global setupSubpixel
	.global subpixelOffsets

	.text
@ setupSubpixel(antialias) -> None
setupSubpixel:
	push	{r4, lr}

	mov	r4, #0
	ldr	r1, =subpixelOffsets
1:
	@ d0 = float(i)
	vmov	s0, r4
	fsitod	d0, s0

	@ d1 = float(antialias)
	vmov	s2, r0
	fsitod	d1, s2

	@ d2 = 0.5
	fldd	d2, float_half

	@ d0 += d2 (0.5)
	faddd	d0, d0, d2

	@ d0 = d0 / d1 (antialias)
	fdivd	d0, d0, d1

	@ d0 = d0 - 0.5
	fsubd	d0, d0, d2

	fstd	d0, [r1]
	add	r1, r1, #8	@ offset subpixelOffsets address

	add	r4, r4, #1
	@ if r4 (i) < r0 (antialias)
	cmp	r4, r0
	blt	1b

	pop	{r4, pc}


float_half: .double 0.5

.bss
subpixelOffsets: .space 8*64

