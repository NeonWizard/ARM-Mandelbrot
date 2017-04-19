        .global mandel

        .text

@ mandel(maxiters, x, y) -> iters
mandel:
	@ x and y are passed in to the d0 and d1 registers

	fldd	d7, escape_amount
	mov	r1, r0			@ keep track of maxiters
	mov	r0, #1			@ set # of iterations = 1

	@ copy x and y into a and b
	fcpyd	d2, d0
	fcpyd	d3, d1

@ 'forever'
1:
	@ compute a^2, b^2, and a^2 + b^2
	fmuld	d4, d2, d2		@ d4 = a^2
	fmuld	d5, d3, d3		@ d5 = b^2
	faddd	d6, d4, d5		@ d6 = a^2 + b^2

	@ if a^2 + b^2 >= 4.0, return iterations
	fcmpd	d6, d7
	fmstat				@ copy flags to integer status register
	bge	3f

	@ increment iterations count
	add	r0, r0, #1

	@ if iterations > maxIterations, return 0
	cmp	r0, r1
	bgt	2f

	@ compute b = 2ab + y
	faddd	d3, d3, d3		@ b = b + b (2b)
	fmuld	d3, d2, d3		@ b = b * a (2b*a)
	faddd	d3, d3, d1		@ b = b + y (2b*a + y)

	@ compute a = a^2 - b^2 + x
	fsubd	d2, d4, d5		@ a = a^2 - b^2
	faddd	d2, d2, d0		@ a = a + x (a^2 - b^2 + x)	

	b	1b			@ continue loop

2:
	mov	r0, #0
3:
	bx	lr

escape_amount: .double 4.0
