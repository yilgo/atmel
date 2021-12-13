/*
 * vga.asm
 *
 *  Created: 26.06.2013 22:10:17
 *   Author: tonyukuk
     Ben bir yonca öldüm ben solunca :(

	 VGA Project ATmega328P @20MHz.......

	 VGA PORT Connection 
	 -----------------------------------------------------------------------------|
	 1>>>>>>>>Red                  6,7,8,10,11>>>>>>>>>>>GND                      |
	 2>>>>>>>>Green                13>>>>>>H-SYNC                                 |
	 3>>>>>>>>Blue                 14>>>>>>V-SYNC                                 |
	 -----------------------------------------------------------------------------|
	 ATMEGA328P Connection
	 -----------------------------------------------------------------------------|
	 PC0(23)>>>>>R          PB2(26)>>>>>H-SYNC        oc1b                            |
	 PC1(24)>>>>>G          PC3(27)>>>>>V-SYNC                                    |
	 PC2(25)>>>>>B                                                                |
     -----------------------------------------------------------------------------|
	  .equ R = 0x00
  .equ G = 0x01
  .equ B = 0x02
  .equ HSYNC = 0x03
  .equ VSYNC = 0x04
 */ 
 //-------------------------------------------------------------------------------------------------------------------------
 //H-SYNC pulse 3.77/0.05=75.4
 //Total time for per row 31.77/0.05 = 635,4 
 //------------------------------------------------------
 //Definitions
 #define R  0x00   ; PC0
 #define G  0x01   ; PC1
 #define B  0x02   ; PC2
 #define VSYNC  0x03 ;PC3
 //***********************
 #define HSYNC  0x02 ; OC1B PB2
// #define maxLineL 0x0D; //
// #define maxLineH 0x02; // 525 line
 #define tempL  R16
 #define tempH  R17
 #define tempG  R18
 #define temp16L R24
 #define temp16H R25
 #define lineCounterL R26
 #define lineCounterH R27
//---------------------------------------------------------------------------------------------------------------------------

 .cseg
 .org 0x0000
  rjmp reset

  .org 0x001A
  rjmp TMR1_OVF

//----------------------------------------------------------------------------------------------------------------------------
   TMR1_OVF:
      
	  mov temp16L,lineCounterL
	  mov temp16H,lineCounterH

	  cp  temp16L,tempL
	  cpc temp16H,tempH
	  brne PC+3

	  clr lineCounterL
	  clr lineCounterH

	  adiw lineCounterH:lineCounterL,1
// MaxLineControl above max=525
//-------------------------------------------------	  
   reti
//-----------------------------------------------------------------------------------------------------------------------------

//init Stack Pointer
reset: 

ldi tempL,HIGH(RAMEND)
out SPH,tempL
ldi tempL,LOW(RAMEND)
out SPL,tempL
rcall setup
rjmp PC
//---------------------------------------------------------------------
setup:

ldi tempL,((1 << R)|(1 << G)|(1 << B)|(1 << VSYNC))
out DDRC,tempL

ldi tempL,((0 << R)|(0 << G)|(0 << B)|(0 << VSYNC))
out PORTC,tempL

ldi tempL,(1 << HSYNC)
out DDRB,tempL

ldi tempL,(0 << HSYNC)
out PORTB,tempL
                                                          
ldi tempL, ((1<<WGM13)|(1<<WGM12)|(1<<CS10)) // clk/1 ----|------
sts TCCR1B, tempL
ldi tempL,((1<<COM1B1)|(1<<COM1B0)|(1<<WGM11)) ;//mode 14, set on compare match clear at TOP
sts TCCR1A,tempL

//H-SYNC pulse 3.77/0.05=75.4  HEX 0x004B
 ldi tempL,0x4B
 ldi tempH,0x00
 sts OCR1BH,tempH
 sts OCR1BL,tempL
//-------------------------------------------------------------------------
//total time for per row (HSYNC) 31.77/0.05 = 635.4 HEX 0x027B
  ldi tempL,0x7B
  ldi tempH,0x02
  sts ICR1H,tempH
  sts ICR1L,tempL
//---------------------------------------------------------------------------TMR1 OVF INT EN.
ldi tempL,(1<<TOIE1)
sts TIMSK1,tempL
//---------------------------------------------------------------------------
 clr lineCounterL
 clr lineCounterH

 ldi tempL, 0x0D
 ldi tempH, 0x02 
 sei   //Enable Global interrupts.
ret
