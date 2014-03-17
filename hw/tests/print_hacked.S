#include "amber_registers.h"

	.section .text
	.globl	main        
main:
	@ Since this is an interrupt routine, store the registers being used	
	stmfd   sp!, {r0-r5}

    ldr r1, AdrUARTLCRH
    mov r2, #0x10
    str r2, [r1]
	ldr r1, AdrUARTDR
    ldr r3, AdrUARTFR
	mov	r4, #0
	add r5, pc, #52

loop:	
	ldr r0, [r5], #1
	add	r4,  r4,  #1
    @ Check the tx_full flag
1:  ldr r2, [r3]
    and r2, r2, #0x20
    cmp r2, #0
    streqb  r0, [r1]
    bne     1b
	
	@ Check if full message has been printed
	cmp	r4, #8
	bne	loop

    @ Restore all registers from the stack
    ldmfd   sp!, {r0-r5}

    @ Jump straight back to normal execution
    @subs    pc, lr, #4
    b  main

AdrUARTLCRH:        .word ADR_AMBER_UART0_LCRH
AdrUARTDR:          .word ADR_AMBER_UART0_DR
AdrUARTFR:          .word ADR_AMBER_UART0_FR
Message:			.ascii "HACKED\n\r"
