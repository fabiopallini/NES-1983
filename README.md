![](https://raw.githubusercontent.com/fabiopallini/NES-1983/master/assets/nes-console.jpg)

Il NES (Nintendo Entertainment System), conosciuto in Giappone come Famicom, è la console 8 bit lanciata nel 1983 da Nintendo, arrivata in Italia solo nel 1987.

La CPU è un microprocessore 8 bit a 1,79 MHz (NTSC) e 1,66 MHz (PAL), derivato direttamente dal MOS 6502, ovvero la CPU utilizzata dall’Apple II, ma anche dal Commodore VIC-20.

2 kB di RAM interna.

La PPU (Picture Processing Unit) genera un segnale video composito da 240 linee, con 2 kB di VRAM e una risoluzione video di 256×240.

Il segnale video del Famicom era di tipo RF (radiofrequenza), ma la versione americana ed europea è stata dotata (per fortuna) di un uscita RCA.

I giochi erano distribuiti su cartuccia, la maggior parte delle quali non avevano possibilità di memorizzare salvataggi, salvo alcuni casi tipo “The Legend of Zelda”, grazie ad una memoria alimentata da una batteria, ma per la maggior parte dei giochi invece si utilizzava uno stratagemma arcaico, ovvero ad ogni avanzamento rilevante del gioco si mostrava a schermo un codice segreto, utilizzandolo poi nella schermata principale del gioco si poteva ripartire da quel punto specifico.

Il bus degli indirizzi della CPU era a 16 bit e ogni indirizzo in memoria aveva un ruolo dedicato:

```
Address range 	Size 	Device

$0000-$07FF 	$0800 	2KB internal RAM

$0800-$0FFF 	$0800 	Mirrors of $0000-$07FF

$1000-$17FF 	$0800

$1800-$1FFF 	$0800

$2000-$2007 	$0008 	NES PPU registers

$2008-$3FFF 	$1FF8 	Mirrors of $2000-2007 (repeats every 8 bytes)

$4000-$401F 	$0020 	NES APU and I/O registers

$4020-$FFFF 	$BFE0 	Cartridge space: PRG ROM, PRG RAM, and mapper registers
```

La paletta dei colori per il background ($3F00 – $3F09) e quella per gli sprites ($3F10 – $3F1F)

![](https://raw.githubusercontent.com/fabiopallini/NES-1983/master/assets/nes-color-palette.png)

I giochi si programmavano in Assembly, quindi lo sforzo anche solo per fare cose banali era notevole, e richiedeva un sacco di lavoro.

La famosa pistola Zapper con cui si poteva giocare a Duck Hunt, aveva un funzionamento a dir poco ingegnoso, ovviamente non sparava niente, e il televisore non ha nessun sensore per poter calcolare o dare feedback degli oggetti a cui “sparavamo”, quindi come funzionava?

![](https://raw.githubusercontent.com/fabiopallini/NES-1983/master/assets/Duck-hunt-dog.jpg)

La pistola aveva un sensore per la luce (fotodiodo), quando si puntava la pistola verso il televisore e si “sparava”, veniva catturata la luce dello schermo, e per far funzionare il sensore, il gioco non disegnava più niente a schermo, ma disegnava solo un quadrato bianco nella posizione degli oggetti da colpire e uno sfondo tutto nero, il tutto per circa 500 millisecondi. Se la pistola era puntata verso un quadrato bianco, allora avevamo colpito il bersaglio, altrimenti niente!

![](https://raw.githubusercontent.com/fabiopallini/NES-1983/master/assets/duck-hunt-307x512.jpg)

![](https://raw.githubusercontent.com/fabiopallini/NES-1983/master/assets/duck-hunt-blackscreen.jpg)

Purtroppo la pistola non funziona più sugli schermi LCD, perché le tempistiche per far funzionare questo trucchetto sono state progettate per i televisori CRT, ormai obsoleti da diversi anni.

Ho voluto fare un piccolo progetto dimostrativo in Assembly, ovvero uno sfondo, e un personaggio (Mario) che si muove per la schermata, con tanto di animazione.

Ci serve prima di tutto un assembler, [ca65](https://www.cc65.org/) (fa parte del toolset di cc65), poi per testare quello che facciamo possiamo usare un NES reale, tramite [PowerPak](http://www.retrousb.com/product_info.php?products_id=34), oppure EverDriveN8, ma per risparmiare possiamo anche usare un emulatore del NES, [FCEUX](http://www.fceux.com/web/home.html) ad esempio.

**6502 Assembly**

```
- Directives
- Labels
- Opcodes
- Operands
- Comments
- Registers
```

**Labels e Opcodes**

I labels servono per organizzare il codice e renderlo più leggibile, si inseriscono sulla sinistra del codice e finiscono con ” : ”

```
MyFunction:
    JMP MyFunction
```

JMP è un opcode, e in questo caso dice al processore di fare un jump al label MyFunction.

**Operands**

Gli operandi sono le informazioni per gli opcodes, in questo caso viene inserito il valore 255 (FF in esadecimale) nell’accumulatore (LDA).

```
MyFunction:
    LDA #$FF
    JMP MyFunction
``` 

**Comments**

I commenti vengono completamente ignorati dall’assemblatore, si definiscono con “;”.

```
;code example
MyFunction:
    LDA #$FF ;load FF (255)
    JMP MyFunction
``` 

**Registers**

LDx, dove x sta per il registro che vogliamo utilizzare, istruzione Load. STx, dove x sta per il registro che vogliamo utilizzare, e ST è l’istruzione Store.

```
LDA #$40 ; inserisce 40 (esadecimale) in A
LDX #$50 ; inserisce 50 (esadecimale) in X
LDY #$60 ; inserisce 60 (esadecimale) in Y
LDA #%00100011 ; inserisce un valore (binario) in A
LDX #50 ; inserisce un valore (decimale) in X
LDY #$50 ; inserisce un valore (esadecimale) in Y
``` 

Se invece volessimo caricare un valore in A, direttamente da un indirizzo in memoria
	
```
LDA $2002 ; inserisce il valore presente all'indirizzo 2002 (esadecimale) in A
LDA 2002 ; inserisce il valore presente all'indirizzo 2002 (decimale) in A
STA $2002 ; inseriamo A all'indirizzo in memoria 2002 (esadecimale)
#50 $2002 ; ERRORE! non si può inserire direttamente in memoria un valore
``` 

Per caricare la sprite in memoria ($0200) ho creato questo loop: setto il registro X a #$00 (0 in decimale), poi carico nell’accumulatore (sprites + x), e faccio uno store all’indirizzo $0200 + x. Incremento x di 1 (INX), poi faccio un Compare del registro X (CPX) al valore #$10 (16 in decimale), se il Compare non è uguale (BNE) a quel valore (#$10) ritorna a loadSpritesLoop, e ripete le istruzioni.

```
LDX #$00              
loadSpritesLoop:
  LDA sprites, x       
  STA $0200, x          
  INX              
  CPX #$10             
  BNE loadSpritesLoop
``` 

come possiamo notare, la sprite di Mario non è composta da un unica sprite, ma bensì da più sprites, detta anche metasprite, in sostanza sono più sprite che compongono la grafica del personaggio.

```
sprites:
     ;vert tile attr horiz
  .byte $80, $32, $00, $80   ;sprite 0
  .byte $80, $33, $00, $88   ;sprite 1
  .byte $88, $4F, $00, $80   ;sprite 2
  .byte $88, $4F, %01000000, $88   ;sprite 3
```

![](https://raw.githubusercontent.com/fabiopallini/NES-1983/master/assets/mario-metasprite.png)

Quindi quando andremo ad animare il personaggio dovremmo tener conto di ogni singola sprite, e modificare correttamente ogni porzione della metasprite per creare l’animazione giusta.

Questo è il codice che si occupa dell’input (in questo caso il tasto sinistro) e che fa animare il personaggio (corsa verso sinistra), come possiamo vedere dai commenti del codice, “giro” la testa verso sinistra e anche le gambe, questo perchè il NES supporta il mirroring della grafica, in questo modo era possibile risparmiare preziosi bytes per grafica aggiuntiva.

```
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
```

ad animazione terminata, ovvero quando non si preme nessun tasto, riporto il personaggio ai frames di posizione statica.

```
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
```

![](https://raw.githubusercontent.com/fabiopallini/NES-1983/master/assets/result.gif)

### compilare il gioco

per compilare il gioco è sufficiente scaricare cc65 dal suo sito ufficiale, inserite la cartella  
di cc65 nel PATH di sistema, e adesso possiamo compilare lanciando il comando 
>./build

Il gioco riprodurrà delle note musicali.  
Attualmente è supportato l'input per muovere il personaggio a sinistra e a destra.
