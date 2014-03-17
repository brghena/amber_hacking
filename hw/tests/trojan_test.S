#include "amber_registers.h"

	.section .text
	.globl	main        
main:
    @ Enable the cache with region 24 uncached
    mov r0, #0xfeffffff
    mcr 15, 0, r0, cr3, cr0, 0 @ cacheable area
    mov r0, #1
    mcr 15, 0, r0, cr2, cr0, 0 @ cache enable
	nop
	nop
	ldr r0, AdrTestBase
	ldr r1, [r0]
	ldr r2, AdrTestBase2
	ldr r3, [r2]
	ldr r4, AdrTestBase3
	ldr r5, [r4]

testpass:             
        ldr     r11, AdrTestStatus
        mov     r10, #17
        str     r10, [r11]
        b       testpass



/* Write 17 to this address to generate a Test Passed message */
AdrTestStatus:              .word ADR_AMBER_TEST_STATUS
AdrTestBase  :              .word 0x00200000
AdrTestBase2 :		    .word 0x00200010
AdrTestBase3 :		    .word 0x00200020
