        .global itoa
        .equ div10_magic, 0xcccccccd
        .text

@ itoa(buffer, n) -> number of bytes written
itoa:
        push    {r4,r5,r6,r7,r8,lr}
        @ r0: buffer
        @ r1: n
        @ r2: length of output
        @ r3: division magic number
        @ r4: digit
        @ r5: new n
        ldr     r3, =div10_magic
        mov     r2, #0
1:
        @ do a division by 10
        umull   r4, r5, r3, r1          @ multiply by magic number
        mov     r5, r5, lsr #3          @ shift: new_n is in r5
        add     r4, r5, r5, lsl #2      @ compute new_n*5
        sub     r4, r1, r4, lsl #1      @ remainder = n - new_n*5*2
        add     r4, r4, #'0'            @ convert to digit
        strb    r4, [r0,r2]             @ store in buffer
        add     r2, r2, #1              @ length++
        subs    r1, r5, #0              @ n = newn and compare with 0
        bgt     1b

	@ r3: first index
	@ r4: last index
	@ r5: temp char storage
	@ r6: temp char storage
	mov	r4, #0
	sub	r5, r2, #1
2:
	ldrb	r6, [r0, r4]	@ swap values
	ldrb	r7, [r0, r5]
	strb	r6, [r0, r5]
	strb	r7, [r0, r4]
	add	r4, #1		@ increase/decrease start/end indexes
	sub	r5, #1
	cmp	r4, r5		@ check if start/end overlapped
	blt	2b

        mov     r0, r2
        pop     {r4,r5,r6,r7,r8,pc}
