#include "amber_registers.h"

	.section .text
	.globl	main        
main:
    mov r0, #0xE
    ldr r1, AdrLEDTEST
    str r0, [r1]
    b main
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

AdrLEDTEST:         .word ADR_AMBER_TEST_LED
