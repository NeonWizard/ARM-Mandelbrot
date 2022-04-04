@ The code starting here is just to help you test your code in a
@ standalone program. It is not part of the assignment.

.global _start
.equ		sys_exit, 1

.text

_start:
	bl		run
	mov		r7, #sys_exit
	svc		#0
