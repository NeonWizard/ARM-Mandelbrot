.global run

.equ	flags, 577
.equ	mode, 0644

.equ	sys_fork, 2
.equ	sys_read, 3
.equ	sys_write, 4
.equ	sys_open, 5
.equ	sys_close, 6
.equ	sys_pipe, 42

.equ	fail_open, 1
.equ	fail_writeheader, 2
.equ	fail_close, 4
.equ	fail_writerow, 8
.equ	fail_openpipe, 16

.text

@ run() -> exit code
run:
@ Open file
	push	{r4, r5, r6, r7, r8, r9, r10, lr}

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
	b	13f

@ Write header
1:
	mov	r4, r0		@ store file descriptor

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
	b	13f

2:
@ Generate subpixel array
	ldr	r0, =antialias
	ldr	r0, [r0]
	bl	setupSubpixel

@ -- Create the finished pipe --
	ldr	r0, =finished
	mov	r7, #sys_pipe
	svc	#0

	@ prepare these variables ahead of time before jumping into loop (prevents me from having to make another label :P)
	mov	r9, #0
	ldr	r10, =workercount
	ldr r10, [r10]

	@ if opening the pipe succeeded, continue
	cmp	r0, #0
	bge 3f

	mov	r0, #fail_openpipe
	b	13f

@ -- Prepare and launch the workers --
@ for n in range(worker_count):
3:
	@ -- create a pipe for worker n --
	ldr	r0, =finished
	mov	r2, #8
	mul	r1, r9, r2		@ address offset = n * 8 (size of pipe data)
	add r0, r0, r1

	mov	r7, #sys_pipe
	svc	#0

	@ -- fork a new worker --
	mov	r7, #sys_fork
	svc	#0

	@ if this is the child, jump to start of worker code
	cmp	r0, #0
	beq	4f

	@ else if this is the parent, continue the loop
	add	r9, r9, #1
	ldr	r1, =workercount
	ldr	r1, [r1]
	cmp	r9, r1
	blt	3b

@ parent: jump to code to coordinate worker
	b	8f

@ -- start of worker code --
4:
@ Write lines
	mov	r8, r9		@ row counter
5:
	@ for row in range(ysize)
	mov	r5, #0		@ column counter
	mov	r6, #0		@ buffer counter
6:
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
	strb	r1, [r7, r6]
	add		r6, r6, #1

	@ If column < xsize, execute loop again
	ldr	r7, =xsize
	ldr	r7, [r7]
	add	r5, r5, #1
	cmp	r5, r7
	blt	6b

	@ ---------------
	@ If done writing row to buffer, continue
	@ Replace last space with newline
	ldr		r1, =buffer
	mov		r0, #'\n'
	sub		r2, r6, #1
	strb	r0, [r1, r2]

	@ -- read a single byte from worker pipe n --
	@ sys_read(fd, buffer, count)

	@ get pipe address
	ldr	r0, =pipes
	mov	r2, #8
	mul	r1, r9, r2
	ldr	r0, [r0, r1]

	ldr	r1, =junk		@ load junk buffer
	mov	r2, #1

	mov	r7, #sys_read
	svc	#0

	@ -- write results to file --
	mov	r2, r6
	mov	r0, r4
	mov	r7, #sys_write
	svc	#0

	@ if writing succeeded, continue
	cmp	r0, #0
	bge	7f

	mov	r0, #fail_writerow
	b	13f

7:
	@ -- write a single byte to shared finished channel --
	@ sys_write(fd, buffer, count) returns the number of bytes written, or negative to signal an error.

	@ get pipe address
	ldr	r0, =finished
	ldr	r0, [r0]

	ldr	r1, =junk	@ load junk buffer
	mov	r2, #1

	mov	r7, #sys_write
	svc	#0

	@ If row < ysize, execute outer loop again
	ldr	r7, =ysize
	ldr	r7, [r7]
	add	r8, r8, r9		@ add worker count
	cmp	r8, r7
	blt	5b

@ -- when child is done, return a success --
	b	10f

@ -- parent coordinate code --
8:
	mov	r5, #0	@ n = 0
	mov r6, #0	@ i = 0
9:
	@ write a byte to worker pipe
	ldr	r0, =pipes
	mov	r2, #8
	mul r1, r5, r2
	add	r1, #4		@ add 4 bytes to address to get write address of pipe
	ldr	r0, [r0, r1]
	ldr r1, =junk
	mov	r2, #1

	mov	r7, #sys_write
	svc #0

	@ read a byte from finished pipe
	ldr	r0, =finished
	ldr	r0, [r0]

	ldr	r1, =junk
	mov	r2, #1

	mov	r7, #sys_write
	svc	#0

	add r5, r5, #1	@ n++
	add	r6, r6, #1	@ i++
	ldr	r7, =workercount
	ldr	r7, [r7]

	@ if n >= worker count: n = 0
	cmp	r5, r7
	blt	10f
	mov	r5, #0

10:

	cmp	r6, r7
	blt	9b

@ Close file
11:
	@ close the file
	mov	r0, r4
	mov	r7, #sys_close
	svc	#0

	@ if closing succeeded, end program
	cmp	r0, #0
	bge	12f

	mov	r0, #fail_close
	b	13f

@ Success
12:
	mov	r0, #0

13:
	pop	{r4, r5, r6, r7, r8, r9, r10, pc}

.bss
	buffer:		.space 64*1024
	finished:	 .space 8
	pipes:		.space 8*4
	junk:		.space 4
