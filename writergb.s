.global writeRGB

.text

@ writeRGB(buffer, rgb) -> number of bytes written
writeRGB:
	push	{r4, r5, r6, lr}

	mov	r4, r0		@ backup buffer
	mov	r5, r1		@ backup rgb
	mov	r6, #0		@ bytes written counter

	@ -- Blue --
	mov	r1, #0xff	@ 8-bit bitmask
	and	r1, r1, r5, lsr #16
	add	r0, r4, r6	@ pass in offset buffer
	bl	itoa		@ blue already in r1 :)
	add	r6, r6, r0	@ increment byte counter

	mov	r2, #' '
	strb	r2, [r4, r6]
	add	r6, r6, #1

	@ -- Green --
	mov	r1, #0xff	@ 8-bit bitmask
	and	r1, r1, r5, lsr #8
	add	r0, r4, r6	@ pass in offset buffer
	bl	itoa		@ green already in r1 :)
	add	r6, r6, r0	@ increment byte counter

	mov	r2, #' '
	strb	r2, [r4, r6]
	add	r6, r6, #1

	@ -- Red --
	mov	r1, #0xff	@ 8-bit bitmask
	and	r1, r1, r5
	add	r0, r4, r6	@ pass in offset buffer
	bl	itoa		@ red already in r1 :)
	add	r6, r6, r0	@ increment byte counter

	mov	r0, r6		@ return byte counter

	pop	{r4, r5, r6, pc}
