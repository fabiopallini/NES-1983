  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring

;; VARIABLES 
  .rsset $0000  ;;start variables at ram location 0

_frameCount .rs 1
_animationCount .rs 1
_animationTimer .rs 1
_input .rs 1
  
;; RESET  
  .bank 0
  .org $C000 

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
gamepad_LEFT_done

gamepad_RIGHT: 
  LDA $4016
  AND #%00000001
  BEQ gamepad_RIGHT_done
  LDA #$01
  STA _input
  ; move
  LDA $0203
  CLC       
  ADC #$01
  STA $0203 
  LDA $0207
  CLC       
  ADC #$01
  STA $0207
  LDA $020B
  CLC       
  ADC #$01
  STA $020B  
  LDA $020F
  CLC       
  ADC #$01
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

; *** DATA ***

  .bank 1
  .org $E000

character_legLeft:
  .db $34, $3B, $38

character_legRight:    
  .db $35, $3C, $39 

palette:
  .db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F ;background palette
  .db $22,$16,$28,$19,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F ; Mario colors
  ;.db $22,$30,$38,$19,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F ; Luigi colors

sprites:
     ;vert tile attr horiz
  .db $80, $32, $00, $80   ;sprite 0
  .db $80, $33, $00, $88   ;sprite 1
  .db $88, $4F, $00, $80   ;sprite 2
  .db $88, $4F, %01000000, $88   ;sprite 3 
  
  .include "background.s" 

  .org $FFFA     ; first of the three vectors starts here
  .dw NMI        ; jump to the label NMI:                 
  .dw RESET      ; jump to reset                  
  .dw 0          ;external interrupt IRQ   
  
  .bank 2
  .org $0000
  .incbin "marioTileset.chr"