@ write your code here
	.global blendColors

	.text
@ blendColors (colorList, count) -> RGB
blendColors:
	push	{r4, r5, r6, r7, r8, lr}

	@ r0 - colorList
	@ r1 - count
	@ r2 - red
	@ r3 - green
	@ r4 - blue
	@ r5 - iteration count
	@ r6 - color

	mov	r2, #0
	mov	r3, #0
	mov	r4, #0
	mov r5, #0

@ while i < count
1:
	mov	r7, #4
	mul	r8, r5, r7
	ldr	r6, [r0, r8]
	mov	r7, #0xff	@ 8-bit bitmask

	@ Red
	and	r8, r7, r6, lsr #16
	add	r2, r2, r8
	@ Green
	and	r8, r7, r6, lsr #8
	add	r3, r3, r8
	@ Blue
	and	r8, r7, r6
	add	r4, r4, r8

	add	r5, r5, #1
	cmp	r5, r1
	blt	1b

	mov	r5, r2
	mov	r6, r3
	mov	r7, r4
	mov	r4, r1

	@ Divide red
	mov	r0, r5
	mov	r1, r4
	bl	divide
	mov	r5, r0

	@ Divide green
	mov	r0, r6
	mov	r1, r4
	bl	divide
	mov	r6, r0

	@ Divide blue	
	mov	r0, r7
	mov	r1, r4
	bl	divide
	mov	r7, r0

	@ Merge colors back into single register
	mov	r0, r5, lsl #16
	orr	r0, r0, r6, lsl #8
	orr	r0, r0, r7

	pop	{r4, r5, r6, r7, r8, pc}

