        .global remainder

        .text
@ remainder(numerator, denominator) -> remainder
remainder:
	push	{r4, lr}

	@ if n < d: return n
	cmp	r0, r1
	blt	3f

	@ shift = (# leading zeros in d) - (# leading zeros in n)
	clz	r2, r0
	clz	r3, r1
	sub	r2, r3, r2

@ r2 - shift
@ r3 - d << shift

@ while shift >= 0
1:
	@ if n >= d<<shift
	mov	r3, r1, lsl r2
	cmp	r0, r3
	blt	2f
	@ n = n - d<<shift
	sub	r0, r0, r3

2:
	sub	r2, r2, #1
	
	# if shift >=0 continue while loop
	cmp	r2, #0
	bge	1b

3:
	pop	{r4, pc}	
