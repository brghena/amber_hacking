/*----------------------------------------------------------------
//                                                              //
//  boot-loader-ethmac.c                                        //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  The main functions for the boot loader application. This    //
//  application is embedded in the FPGA's SRAM and is used      //
//  to load larger applications into the DDR3 memory on         //
//  the development board.                                      //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2011-2013 Authors and OPENCORES.ORG            //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
----------------------------------------------------------------*/

#include "line-buffer.h"
#include "timer.h"
#include "utilities.h"
#include "packet.h"
#include "ethmac.h"
#include "tcp.h"
#include "udp.h"
#include "telnet.h"
#include "serial.h"
#include "stdio.h"
#include "amber_registers.h"

#define CACHE_ADDR 0x00200000
#define DLY_1S          1000

void parse (char* buf);

int main ( void ) {
    int c, esc = 0;
    char buf  [20]; /* current line */
    char lbuf [20]; /* last line    */
    int i = 0;
    int li = 0;
    int j;

    /* Enable the serial debug port */
    init_serial();
    print_serial("\n\rImportant Terminal For Important Things\n\r");
    print_serial("Ready\n\r> ");
    
    /* display the contents of cache memory to find our trojan message */
    //print_serial((char *)0x0020E900);

    /* initialize the memory allocation system */
    init_malloc();

    /* Enable the hardware timer to generate interrrupts 100 timer per second,
       current time will start incrementing from this point onwards */
    init_timer();

    /* Create a timer to flash a led periodically */
    init_led();

    /* initialize the PHY and MAC and listen for connections
       This is the last init because packets will be received from this point
       onwards. */
    init_ethmac();

    /* create a tcp socket for listening on port 23 */
    //listen_telnet();

    /* initialize the tftp stuff */
    //init_tftp();

    /* Process loop. Everything is timer, interrupt and queue driven from here on down */
    while (1) {

        /* flash an led */
        process_led();

        if ((c = _inbyte (DLY_1S)) >= 0) {
        
            /* Escape Sequence ? */
            if (c == 0x1b) esc = 1;
            else if (esc == 1 && c == 0x5b) esc = 2;  
            else if (esc == 2) {
                esc = 0;
                if (c == 'A') {
                    /* Erase current line using backspaces */
                    for (j=0;j<i;j++)  _outbyte(0x08);
                    
                    /* print last line and
                       make current line equal to last line  */
                    for (j=0;j<li;j++) _outbyte(buf[j] = lbuf[j]);
                    i = li;
                }
                continue;    
            }
            else esc = 0;
            
            /* Character not part of escape sequence so print it 
               and add it to the buffer
            */   
            if (!esc) {
                _outbyte (c);            
                /* Backspace ? */
                if (c == 8 && i > 0) { i--; }
                else                 { buf[i++] = c; }
            }
                        
            /* End of line ? */    
            if (c == '\r' || c == '\n' || i >= 19) { 
                if (i>1) { 
                    /* Copy current line buffer to last line buffer */
                    for (j=0;j<20;j++) lbuf[j] = buf[j]; 
                    li = i-1;
                }
                buf[i] = 0; i = 0; 
                
                /* Process line */
                parse( buf ); 
                print_serial("\n\r> ");
            }
        }
        

        /* Check for received tftp files and reboot */
        //process_tftp();

        /* Process all socket traffic */
        //process_sockets();
    }
}


void parse (char* buf) {

    // expected syntax is "led #"
    if (buf[0] == 'l') {
        // toggle LED
        switch (buf[4]) {
            case 0x31:
                led_flip(1);
                break;
            case 0x32:
                led_flip(2);
                break;
            case 0x33:
                led_flip(3);
                break;
            case 0x34:
                led_flip(4);
                break;
            default:
                led_flip(1);
                break;
        }

    // expected syntax is "motor"
    //Note: the motor is connected as if the 4th LED
    } else if (buf[0] == 'm') {
        // toggle motor
        led_flip(4);
    }
}

