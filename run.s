        .global run

        .equ    flags, 577
        .equ    mode, 0644

        .equ    sys_write, 4
        .equ    sys_open, 5
        .equ    sys_close, 6

        .equ    fail_open, 1
        .equ    fail_writeheader, 2
        .equ    fail_close, 4
		.equ	fail_writerow, 8

        .text

@ run() -> exit code
run:
@ Open file
	push	{r4, r5, r6, r7, r8, lr}
	
	@ open the file
	ldr	r0, =filename
	ldr	r1, =flags
	ldr	r2, =mode
	mov	r7, #sys_open
	svc	#0

	@ if fd >= 0 then success
	cmp	r0, #0
	bge	1f

	mov	r0, #fail_close
	b	9f

@ Write header
1:
	mov	r4, r0 		@ store file descriptor	

	@ --- write the header ---
	@ header -> buffer
	ldr	r0, =buffer
	ldr	r1, =xsize
	ldr	r1, [r1]
	ldr	r2, =ysize
	ldr	r2, [r2]
	bl	writeHeader

	@ buffer -> file
	mov	r2, r0		@ pass in bytes to write
	ldr	r1, =buffer
	mov	r0, r4
	mov	r7, #sys_write
	svc	#0
	
	@ if writing succeeded, continue
	cmp	r0, #0
	bge	2f

	mov	r0, #fail_writeheader
	b	9f

2:
@ Generate subpixel array
	ldr	r0, =antialias
	ldr	r0, [r0]
	bl	setupSubpixel

@ Write lines
	mov	r8, #0		@ row counter
3:	
	@ for row in range(ysize)
	mov	r5, #0		@ column counter
	mov	r6, #0		@ buffer counter
4:
	@ for column in range(xsize):
	ldr	r7, =buffer	
	@ color = row << 16 + column << 8	
	@mov	r1, r8, lsl #16		@ color = row << 16
	@add	r1, r1, r5, lsl #8	@ color = color + column << 8

	@ calculate color
	ldr	r0, =iters
	ldr	r0, [r0]	@ maxiters
	mov	r1, r5		@ column
	mov	r2, r8		@ row

	@ allocate stack space
	sub	sp, sp, #8

	@ put ysize on stack
	ldr	r3, =ysize
	ldr	r3, [r3]
	str	r3, [sp]

	@ put antialias on stack
	ldr	r3, =antialias
	ldr	r3, [r3]
	str	r3, [sp, #4]

	@ float args
	ldr	r3, =xcenter
	fldd	d0, [r3]
	ldr	r3, =ycenter
	fldd	d1, [r3]
	ldr	r3, =mag
	fldd	d2, [r3]

	@ pass xsize in through r3
	ldr	r3, =xsize
	ldr	r3, [r3]

	bl	calcPixel
	add	sp, sp, #8

	@ call writeRGB(buffer, color)
	mov	r1, r0
	add	r0, r7, r6	@ offset buffer by bytes already written
	bl	writeRGB
	add	r6, r0, r6	@ increase buffer counter by bytes written
	
	@ add space separator
	mov		r1, #' '
	strb 	r1, [r7, r6]
	add		r6, r6, #1

	@ If column < xsize, execute loop again
	ldr	r7, =xsize
	ldr	r7, [r7]
	add	r5, r5, #1
	cmp	r5, r7
	blt	4b

	@ ---------------
	@ If done writing row to buffer, continue
	@ Replace last space with newline
	ldr		r1, =buffer
	mov		r0, #'\n'
	sub		r2, r6, #1
	strb	r0, [r1, r2]
	
	@ Write results to file
	mov	r2, r6
	mov	r0, r4
	mov	r7, #sys_write
	svc	#0

	@ if writing succeeded, continue
	cmp	r0, #0
	bge	5f

	mov	r0, #fail_writerow
	b	9f

5:
	@ Go back to outer for loop if not done
	ldr	r7, =ysize
	ldr	r7, [r7]
	add	r8, r8, #1
	cmp	r8, r7
	blt	3b

@ Close file
6:
	@ close the file
	mov	r0, r4
	mov	r7, #sys_close
	svc	#0

	@ if closing succeeded, end program
	cmp	r0, #0
	bge	7f

	mov	r0, #fail_close
	b	9f

@ Success
7:
	mov	r0, #0

9:	
	pop	{r4, r5, r6, r7, r8, pc}

.bss
buffer: .space 64*1024

