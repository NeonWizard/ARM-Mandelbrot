        .global getColor

        .text
@ getColor(iters) -> rgb
getColor:
        push    {ip,lr}

	sub	r0, r0, #1
	ldr	r1, =palette_size
	ldr	r1, [r1]
	bl	remainder

	mov	r2, #4
	mul	r1, r0, r2
	ldr	r0, =palette
	ldr	r0, [r0, r1]

	pop     {ip,pc}
