#include "amber_registers.h"

	.section .text
	.globl	main        
main:
	nop

	@ Since this is an interrupt routine, store the registers being used	
	stmfd   sp!, {r0-r5, lr}

	ldr     r1, AdrUARTDR
        ldr     r3, AdrUARTFR
	mov	r4, #0
	ldr	r5, =Message

loop:	
	ldr 	r0, [r5], #1
	add	r4, r4, #1
        @ Check the tx_full flag
1:      ldr     r2, [r3]
        and     r2, r2, #0x20
        cmp     r2, #0
        streqb  r0, [r1]
        bne     1b
	
	@ Check if full message has been printed
	cmp	r4, #9
	bne	loop

        @ Restore all registers from the stack
        ldmfd   sp!, {r0-r5, lr}

        @ Jump straight back to normal execution
        subs    pc, lr, #4

	nop

@ testpass:             
@       ldr     r11, AdrTestStatus
@       mov     r10, #17
@       str     r10, [r11]
@       b       testpass

@ AdrTestStatus:              	.word ADR_AMBER_TEST_STATUS
AdrUARTDR:                  	.word ADR_AMBER_UART0_DR
AdrUARTFR:                  	.word ADR_AMBER_UART0_FR
Message:			.ascii "HACKED!\n"
