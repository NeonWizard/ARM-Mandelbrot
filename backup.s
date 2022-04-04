.global calcPixel

.text

@ calcPixel(maxiters, col, row, xsize, ysize, antialias, xcenter, ycenter, magnification) -> rgb
calcPixel:
	@ passed in values:
	@ r0 - maxiters
	@ r1 - col
	@ r2 - row
	@ r3 - xsize
	@ stack1 - ysize
	@ stack2 - antialias
	@ d0 - xcenter
	@ d1 - ycenter
	@ d2 - mag
	push	{r4, r5, r6, lr}

	@ move xcenter/ycenter to d3/d4 to get out of way of float x/y
	fcpyd	d3, d0
	fcpyd	d4, d1

	@ convert x and y to floats to prepare for float division
	vmov	s0, r1
	fsitod	d0, s0
	vmov	s2, r2
	fsitod	d1, s2

	@ convert xsize and ysize to floats
	vmov	s10, r3
	fsitod	d5, s10
	ldr		r3, [sp, #16]
	vmov	s12, r3
	fsitod	d6, s12

	@ load antialias into r4
	ldr		r4, [sp, #20]

	@ d registers structure:
	@ d0 - col		-> x
	@ d1 - row		-> y
	@ d2 - mag		-> (minsize-1) * mag
	@ d3 - xcenter
	@ d4 - ycenter
	@ d5 - xsize	-> col - xsize/2
	@ d6 - ysize	-> row - ysize/2

	@ int registers structure:
	@ r4 - antialias
	@ r5 - yi
	@ r6 - xi

	@ -- calc (mag * (minsize - 1)) --
	fcmpd	d5, d6		@ compare xsize with ysize
	fmstat
	fcpyd	d7, d6		@ d7 (minsize) = ysize UNLESS
	bgt		1f			@ if xsize > ysize, keep minsize = ysize
	fcpyd	d7, d5		@ else set d7 (minsize) as xsize
1:
	fldd	d8, float_one
	fsubd	d7, d7, d8	@ minsize = minsize - 1
	fmuld	d2, d7, d2	@ const = (minsize-1) * mag

	@ -- calc other things that stay the same throughout subpixel computation --
	fldd	d8, float_two
	fdivd	d5, d5, d8		@ xsize = xsize/2
	fdivd	d6, d6, d8		@ ysize = ysize/2
	fsubd	d5, d0, d5		@ d5 = col - xsize/2
	fsubd	d6, d1, d6		@ d6 = row - ysize/2

	@ -- save values to stack so they survive function jumping --
	sub		sp, sp, #44		@ reserve space on the stack
	add		ip, sp, #0		@ first slot address
	fstd	d2, [ip]		@ - store: denominator
	add		ip, sp, #8		@ second slot address
	fstd	d3, [ip]		@ - store: xcenter
	add		ip, sp, #16		@ and so on
	fstd	d4, [ip]		@ - store: ycenter
	add		ip, sp, #24
	fstd	d5, [ip]		@ - store: col - xsize/2
	add		ip, sp, #32
	fstd	d6, [ip]		@ - store: row - ysize/2
	add		ip, sp, #40
	str		r0, [ip]		@ - store: maxiters

	@ [-- subpixel for loops --]
	mov		r5, #0			@ yi = 0
2:							@ for (y < antialias) {
	mov		r6, #0			@ xi = 0
3:							@ for (x < antialias) {
	@ [-- actual code here --]
	@ -- load values in from stack --
	add		ip, sp, #0
	fldd	d2, [ip]
	add		ip, sp, #8
	fldd	d3, [ip]
	add		ip, sp, #16
	fldd	d4, [ip]
	add		ip, sp, #24
	fldd	d5, [ip]
	add		ip, sp, #32
	fldd	d6, [ip]
	add		ip, sp, #40
	ldr		r0, [ip]

	@ -- add subpixelOffsets[xi/yi] to d5/d6 and store in d0/d1 --
	ldr		r1, =subpixelOffsets
	mov		r3, #8

	@ d0 = subpixelOffsets[xi]
	mul		r2, r6, r3		@ compute offset
	add		r2, r1, r2		@ offset the address
	fldd	d0, [r2]		@ load from offset address

	@ d1 = subpixelOffsets[yi]
	mul		r2, r5, r3		@ compute offset
	add		r2, r1, r2		@ offset the address
	fldd	d1, [r2]		@ load from offset address

	faddd	d0, d0, d5		@ add (col - xsize/2.0)
	faddd	d1, d1, d6		@ add (row - ysize/2.0)

	@ d0/d1 = [d0/d1] / denominator
	fdivd	d0, d0, d2
	fdivd	d1, d1, d2

	@ xcenter + d0
	faddd	d0, d3, d0
	@ ycenter - d1
	fsubd	d1, d4, d1

	bl	mandel				@ maxiters already in r0
	bl	getColor

	@ -- store color in color list --
	@ compute address offset
	mul		r3, r5, r4		@ r3 = yi * antialias
	add		r3, r3, r6		@ r3 = r3 (yi * antialias) + xi
	mov		r1, #4
	mul		r2, r3, r1		@ offset = r3 (yi * antialias + xi) * 4 (int size)

	ldr		r1, =colors
	str		r0, [r1, r2]

	@ -- go back to inner loop if x <= antialias --
	add		r6, r6, #1
	cmp		r6, r4
	blt		3b

	@ -- go back to outer loop if y <= antialias --
	add		r5, r5, #1
	cmp		r5, r4
	blt		2b

	@ -- finally, blend the colors --
	ldr		r0, =colors
	mul		r1, r4, r4
	bl		blendColors

	add		sp, sp, #44
	pop		{r4, r5, r6, pc}

float_one: .double 1.0
float_two: .double 2.0

.bss
colors: .space 64*64*4
