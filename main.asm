.segment "HEADER"

.byte "NES"
.byte $1a
.byte $02 ; 2 * 16KB PRG ROM
.byte $01 ; 1 * 8KB CHR ROM
.byte %00000001 ; mapper and mirroring
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00, $00, $00, $00, $00 ; filler bytes

.segment "ZEROPAGE"

timer: .res 1
player_x: .res 1
player_x_sub: .res 1

_frameCount: .res 1
_animationCount: .res 1
_animationTimer: .res 1
_input: .res 1

audio_index: .res 1

.segment "STARTUP"
  
;; RESET  

RESET:
	SEI          ; disable IRQs
	CLD          ; disable decimal mode
	LDX #$40
	STX $4017    ; disable APU frame IRQ
	LDX #$FF
	TXS          ; Set up stack
	INX          ; now X = 0
	STX $2000    ; disable NMI
	STX $2001    ; disable rendering
	STX $4010    ; disable DMC IRQs

	JSR init_apu

vblankwait1:       ; First wait for vblank to make sure PPU is ready
	BIT $2002
	BPL vblankwait1

clrmem:
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0300, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	LDA #$FE
	STA $0200, x
	INX
	BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
	BIT $2002
	BPL vblankwait2

; *** LOAD ***

loadPalettes:
	LDA $2002             ; read PPU status to reset the high/low latch
	LDA #$3F
	STA $2006             ; write the high byte of $3F00 address
	LDA #$00
	STA $2006             ; write the low byte of $3F00 address
	LDX #$00          

loadPalettesLoop:
	LDA palette, x                         
	STA $2007 ; write to PPU
	INX                   
	CPX #$20              
	BNE loadPalettesLoop                        

loadSprites:
	LDX #$00              

loadSpritesLoop:
	LDA sprites, x       
	STA $0200, x          
	INX              
	CPX #$10             
	BNE loadSpritesLoop                                            
                                  
initBackground:
	LDA $2002             ; read PPU status to reset the high/low latch
	LDA #$20
	STA $2006             ; write the high byte of $2000 address
	LDA #$00
	STA $2006             ; write the low byte of $2000 address
	LDX #$00

loadBackground_1:
	LDA background_1, x  
	STA $2007 ; write to PPU             
	INX                  
	CPX #$FF             
	BNE loadBackground_1  
	ldx #$00  
                     
loadBackground_2:
	LDA background_2, x    
	STA $2007 ; write to PPU           
	INX                   
	CPX #$FF              
	BNE loadBackground_2  
	ldx #$00

loadBackground_3:
	LDA background_3, x  
	STA $2007 ; write to PPU             
	INX                  
	CPX #$FF             
	BNE loadBackground_3  
	ldx #$00  
                     
loadBackground_4:
	LDA background_4, x    
	STA $2007 ; write to PPU           
	INX                   
	CPX #$FF              
	BNE loadBackground_4 
	ldx #$00  
                                      
initBackgroundAttributes:
	LDA $2002
	LDA #$23
	STA $2006             
	LDA #$C0
	STA $2006          
	LDX #$00            

loadBackgroundAttributes:
	LDA background_attributes, x
	STA $2007 ; write to PPU
	INX                  
	CPX #$40        
	BNE loadBackgroundAttributes  

; *** ENABLE NMI ***

	LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	STA $2000
	LDA #%00011110   ; enable sprites, enable background, no clipping on left side
	STA $2001

; *** LOOP ***

loop:
	JSR play_tri_scale
	JSR play_pulse_scale
	jmp loop 
  
NMI:
	LDA #$00
	STA $2003 ; set the low byte (00) of the RAM address
	LDA #$02
	STA $4014 ; set the high byte (02) of the RAM address, start the transfer

; *** INPUT ***

initController:
	LDA #$01
	STA $4016
	LDA #$00
	STA $4016

gamepad_A:
	LDA $4016
	AND #%00000001
	BEQ gamepad_A_done
gamepad_A_done:

gamepad_B:
	LDA $4016
	AND #%00000001
	BEQ gamepad_B_done
gamepad_B_done:

gamepad_SELECT:
	LDA $4016
	AND #%00000001
	BEQ gamepad_SELECT_done
gamepad_SELECT_done:

gamepad_START:
	LDA $4016
	AND #%00000001
	BEQ gamepad_START_done
gamepad_START_done:

gamepad_UP:
	LDA $4016
	AND #%00000001
	BEQ gamepad_UP_done
gamepad_UP_done:

gamepad_DOWN:
	LDA $4016
	AND #%00000001
	BEQ gamepad_DOWN_done
gamepad_DOWN_done:

gamepad_LEFT: 
	LDA $4016
	AND #%00000001  
	BEQ gamepad_LEFT_done  
	LDA #$01
	STA _input
	; move
	LDA $0203
	CLC       
	SBC #$01
	STA $0203 
	LDA $0207
	CLC       
	SBC #$01
	STA $0207
	LDA $020B
	CLC       
	SBC #$01
	STA $020B  
	LDA $020F
	CLC       
	SBC #$01
	STA $020F
	; turn head left
	LDA #%01000000
	STA $0202
	STA $0206
	LDA #$33
	STA $0201
	LDA #$32
	STA $0205
	; turn legs left
	LDA #%01000000
	STA $020A
	STA $020E

	; legs animation

	INC _animationTimer
	LDA _animationTimer
	CMP #5
	BNE gamepad_LEFT_done
	LDA #00
	STA _animationTimer  

	LDX _animationCount
	LDA character_legRight, x 
	STA $0209
	LDA character_legLeft, x
	STA $020D  

	INC _animationCount
	LDA _animationCount
	CMP #3
	BNE gamepad_LEFT_done

	LDA #$00
	STA _animationCount  
gamepad_LEFT_done:

gamepad_RIGHT: 
	LDA $4016
	AND #%00000001
	BEQ gamepad_RIGHT_done
	LDA #$01
	STA _input
	; move
	LDA $0203
	CLC       
	ADC #$02
	STA $0203 
	LDA $0207
	CLC       
	ADC #$02
	STA $0207
	LDA $020B
	CLC       
	ADC #$02
	STA $020B  
	LDA $020F
	CLC       
	ADC #$02
	STA $020F
	; turn head right
	LDA #$00
	STA $0202
	STA $0206
	LDA #$32
	STA $0201
	LDA #$33
	STA $0205
	; legs animation 
	INC _animationTimer
	LDA _animationTimer
	CMP #5
	BNE gamepad_RIGHT_done
	LDA #00
	STA _animationTimer
	LDX _animationCount
	LDA character_legLeft, x 
	STA $0209
	LDA character_legRight, x
	STA $020D
	LDA #$00
	STA $020E
	INC _animationCount
	LDA _animationCount
	CMP #3
	BNE gamepad_RIGHT_done
	LDA #$00
	STA _animationCount
gamepad_RIGHT_done:

animation_stand:
	LDA _input
	CMP #$01
	BEQ animationDone
	LDA #$00
	STA $020A
	LDA #%01000000
	STA $020E  
	LDA #$4F
	STA $0209  
	STA $020D

animationDone:    
	LDA #$00
	STA _input

	;;This is the PPU clean up section, so rendering the next frame starts properly.
	LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	STA $2000
	LDA #%00011110   ; enable sprites, enable background, no clipping on left side
	STA $2001
	LDA #$00        ;;tell the ppu there is no background scrolling
	STA $2005
	STA $2005

	RTI             ; return from interrupt

play_pulse_scale:
	LDA #20
	STA audio_index

:	TAX
	JSR play_pulse_note

	LDA audio_index
	CLC
	ADC #01
	STA audio_index

	LDA audio_index
	CMP #32
	BNE :-

	RTS

play_pulse_note:
	lda periodTableHi,x
	sta $4003
	
	lda periodTableLo,x
	sta $4002
	
	; Fade volume from 15 to 0
	ldy #15
:       tya
	ora #%10110000
	sta $4000
	jsr delay_frame
	dey
	bpl :-
	
	rts

play_tri_scale:
	LDA #20 
	STA audio_index 

:	TAX
	JSR play_tri_note

	LDA audio_index
	CLC
	ADC #01
	STA audio_index

	LDA audio_index
	CMP #32
	BNE :-

	RTS 

play_tri_note:
	; Halve period, since triangle is octave lower
	lda periodTableHi,x
	lsr a
	sta $400B
	
	lda periodTableLo,x
	ror a
	sta $400A
	
	; Play for 8 frames, then silence for 8 frames
	lda #%11000000
	sta $4008
	sta $4017
	
	ldy #8
	jsr delay_y_frames
	
	lda #%10000000
	sta $4008
	sta $4017
	
	ldy #8
	jsr delay_y_frames
	
	rts

; Initializes APU registers and silences all channels
init_apu:
	lda #$0F
	sta $4015
	
	ldy #0
:       lda @regs,y
	sta $4000,y
	iny
	cpy #$18
	bne :-
	
	rts
@regs:
	.byte $30,$7F,$00,$00
	.byte $30,$7F,$00,$00
	.byte $80,$00,$00,$00
	.byte $30,$00,$00,$00
	.byte $00,$00,$00,$00
	.byte $00,$0F,$00,$C0

; Delays Y/60 second
delay_y_frames:
:       jsr delay_frame
	dey
	bne :-
	rts

; Delays 1/60 second
delay_frame:
	; delay 29816
	lda #67
:       pha
	lda #86
	sec
:       sbc #1
	bne :-
	pla
	sbc #1
	bne :--
	rts

; *** DATA ***

character_legLeft:
	.byte $34, $3B, $38

character_legRight:    
	.byte $35, $3C, $39 

palette:
	.byte $0F, $27, $17, $0D, $0F, $27, $17, $0D,$0F, $27, $17, $0D, $0F, $27, $17, $0D
	.byte $22,$16,$28,$19,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F ; Mario colors
	;.byte $22,$30,$38,$19,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F ; Luigi colors

sprites:
	;vert tile attr horiz
	.byte $80, $32, $00, $80   ;sprite 0
	.byte $80, $33, $00, $88   ;sprite 1
	.byte $88, $4F, $00, $80   ;sprite 2
	.byte $88, $4F, %01000000, $88   ;sprite 3 

; NTSC period table generated by mktables.py. See
; http://wiki.nesdev.com/w/index.php/APU_period_table
periodTableLo:
	.byte $f1,$7f,$13,$ad,$4d,$f3,$9d,$4c,$00,$b8,$74,$34
	.byte $f8,$bf,$89,$56,$26,$f9,$ce,$a6,$80,$5c,$3a,$1a
	.byte $fb,$df,$c4,$ab,$93,$7c,$67,$52,$3f,$2d,$1c,$0c
	.byte $fd,$ef,$e1,$d5,$c9,$bd,$b3,$a9,$9f,$96,$8e,$86
	.byte $7e,$77,$70,$6a,$64,$5e,$59,$54,$4f,$4b,$46,$42
	.byte $3f,$3b,$38,$34,$31,$2f,$2c,$29,$27,$25,$23,$21
	.byte $1f,$1d,$1b,$1a,$18,$17,$15,$14

periodTableHi:
	.byte $07,$07,$07,$06,$06,$05,$05,$05,$05,$04,$04,$04
	.byte $03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02
	.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00

.include "background.asm" 

.segment "VECTORS"
	.word NMI
	.word RESET 
	; 
.segment "CHARS"
	.incbin "mario.chr"
