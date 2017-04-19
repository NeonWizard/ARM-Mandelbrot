        .global writeHeader

        .text
@ writeHeader(buffer, x, y) -> number of bytes written
writeHeader:
	push	{r4, r5, r6, lr}

	mov	r4, r0		@ backup buffer
	mov	r5, r2		@ backup y
	mov	r6, #0		@ byte counter

	@ ------
	@ "P3\n"
	@ ------
	mov	r3, #'P'
	strb	r3, [r4, r6]
	add	r6, r6, #1

	mov	r3, #'3'
	strb	r3, [r4, r6]
	add	r6, r6, #1

	mov	r3, #'\n'
	strb	r3, [r4, r6]
	add	r6, r6, #1

	@ ------------------
	@ x + " " + y + "\n"
	@ ------------------
	@ === write x argument ===
	add	r0, r4, r6	@ set buffer to correct offset
	@ x argument already in register 1
	bl	itoa		@ r0 is now bytes written, r1-r3 scratched
	add	r6, r6, r0	@ add bytes written to byte counter

	mov	r3, #' '
	strb	r3, [r4, r6]
	add	r6, r6, #1

	@ === write y argument ===
	add	r0, r4, r6	@ set buffer to correct offset
	mov	r1, r5		@ pass in y argument
	bl	itoa		@ r0 is now bytes written, r1-r3 scratched
	add	r6, r6, r0	@ add bytes written to byte counter

	mov	r3, #'\n'
	strb	r3, [r4, r6]
	add	r6, r6, #1

	@ -------
	@ "255\n"
	@ -------
	mov	r3, #'2'
	str	r3, [r4, r6]
	add	r6, r6, #1

	mov	r3, #'5'
	str	r3, [r4, r6]
	add	r6, r6, #1

	mov	r3, #'5'
	str	r3, [r4, r6]
	add	r6, r6, #1

	mov	r3, #'\n'
	str	r3, [r4, r6]
	add	r6, r6, #1

	@ return byte count in r0
	mov	r0, r6

	pop	{r4, r5, r6, pc}
