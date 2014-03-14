#include "amber_registers.h"

	.section .text
	.globl	main        
main:
	ldr r0, AdrTestBase
	ldr r1, [r0]
/*	mov r4, #0xFFFFFFFF
	str r4, [r2]
	ldr r3, [r2]
	mov r5, #0x5
	str r5, [r2]
	ldr r3, [r2] */

testpass:             
        ldr     r11, AdrTestStatus
        mov     r10, #17
        str     r10, [r11]
        b       testpass



/* Write 17 to this address to generate a Test Passed message */
AdrTestStatus:              .word ADR_AMBER_TEST_STATUS
AdrTestBase  :              .word 0x0020E900
AdrTestBase2 :		    .word 0x00200040
AdrTestBase3 :		    .word 0x00200060
