.global divide

.text

@ write your code here
@ divide (numerator, denominator) -> quotient
divide:
	push	{r4, lr}

	mov	r4, #0		@ quotient = 0
	@ if n < d: return quotient
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
	add	r4, r4, r4	@ quotient = quotient + quotient
	mov	r3, r1, lsl r2	@ r3 = d << shift
	cmp	r0, r3
	blt	2f
	sub	r0, r0, r3	@ n = n - d<<shift
	add	r4, r4, #1	@ quotient = quotient + 1
2:
	sub	r2, r2, #1	@ shift = shift - 1

	cmp	r2, #0
	bge	1b

3:
	mov	r0, r4
	pop	{r4, pc}
