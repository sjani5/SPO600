; zero-page variable locations
define ROW		$20	; current row
define COL		$21	; current column
define DELTAX		$30	; current Delta X
define DELTAY		$31	; current Delta Y 
define BOUNCEX		$35	; checks if X has bounced
define BOUNCEY		$36	; checks if Y has bounced
define VELX		$38
define VELY		$39	
define	POINTER		$10	; ptr start of row
define	POINTER_H	$11
define PADDLEL	$40
define PADDLER		$41	
define SCORE		$24
define HIT		$23

; constants
define	DOT		$01	; dot colour
define	PADDLE		$07	; black colour
 
 
	ldy #$00	; put help text on screen
print:	lda help,y
	beq setup
	sta $f000,y
	iny
	bne print
 
setup:	lda #$0f	; set initial ROW,COL
 	sta ROW
	lda #$00
 	sta COL
	lda #$20
	sta VELX
	lda #$20
	sta VELY
	lda #$0B
	sta PADDLEL
	lda #$15
	sta PADDLER
	lda #$00
	sta SCORE
	

 
draw:	lda ROW		; ensure ROW is in range 031
 	and #$1f
 	sta ROW
 
 	lda COL		; ensure COL is in range 031
 	and #$1f
 	sta COL
 
 	ldy ROW		; load POINTER with start-of-row
 	lda table_low,y
 	sta POINTER
 	lda table_high,y
 	sta POINTER_H
 
 	ldy COL		; store CURSOR at POINTER plus COL
 	lda #DOT
 	sta (POINTER),y

	
drawPaddle:
 	ldy #$1f	; load POINTER with start-of-row
 	lda table_low,y
 	sta POINTER
 	lda table_high,y
 	sta POINTER_H
 
 	ldy PADDLEL	; store CURSOR at POINTER plus COL
 	lda #PADDLE
	
paddleLoop:
 	sta (POINTER),y
	iny 
	cpy PADDLER
	bne paddleLoop


colidR:	lda COL
	cmp #$1F
	bne colidL
	sta BOUNCEY

colidL:	lda COL
	cmp #$00
	bne colidD
	sta BOUNCEY
	
colidD:	lda ROW
	cmp #$1F
	bne colidU
	CLC
	jmp gameover

colidU:	lda ROW
	cmp #$00
	bne colidP
	sta BOUNCEX

colidP:	CLC
	lda ROW
	cmp #$1E
	bne incScore
	
	lda COL
	cmp PADDLEL

	bcc incScore
	
	cmp PADDLER
	bcs incScore

	sta BOUNCEX
	inc HIT
	
	lda $fe		;randomize vel when hitting paddle
	cmp #$80	;ensure vel isn't too high
	bcc velx
	adc #$81
	

velx:
	sta VELX
	lda $fe
	sta VELY

incScore:
	CLC
	lda ROW
	cmp #$1D
	bne delaya
	lda HIT
	cmp #$00
	beq delaya
	lda #$00
	sta HIT
	SED
	CLC
	lda SCORE
	adc #$01
	sta SCORE
	CLD      

delaya:	ldy #$00 	; Delay processor to slow down game
	ldx #$00
delay:	iny
	cpy #$FF
	bne delay

	ldy #$00
	inx
	cpx #$06
	bne delay


ballX:	lda VELX
	adc DELTAX
	sta DELTAX
	bcc ballY

	ldy ROW		; load POINTER with start-of-row
 	lda table_low,y
 	sta POINTER
 	lda table_high,y
 	sta POINTER_H
 
 	ldy COL		; store CURSOR at POINTER plus COL
 	lda #00
 	sta (POINTER),y

	CLC

	lda BOUNCEX
	cmp #$00
	bne decROW


incROW:	inc ROW
	CLC
	bcc ballY

decROW:	dec ROW

ballY:	
	lda VELY
	adc DELTAY
	sta DELTAY
	
	bcc getkey

	ldy ROW		; load POINTER with start-of-row
 	lda table_low,y
 	sta POINTER
 	lda table_high,y
 	sta POINTER_H
 
 	ldy COL		; store CURSOR at POINTER plus COL
 	lda #00
 	sta (POINTER),y

	CLC

	lda BOUNCEY
	cmp #$00
	bne decCOL

incCOL:	inc COL
	CLC
	bcc getkey

decCOL:	dec COL

	
getkey:	lda $ff		; get a keystroke
 
 	ldx #$00	; clear out the key buffer
 	stx $ff

 	cmp #$83	; check key == LEFT
 	bne checkR

	ldy PADDLEL
	cpy #$00
	beq checkR
 
	ldy #$1f	; load POINTER with start-of-row
 	lda table_low,y
 	sta POINTER
 	lda table_high,y
 	sta POINTER_H
 
 	ldy PADDLER	; store CURSOR at POINTER plus COL
	dey
 	lda #00
 	sta (POINTER),y

 	dec PADDLEL
	dec PADDLER
 	jmp done

checkR:	cmp #$81	; check key == RIGHT
 	bne done
 
	ldy PADDLER
	cpy #$20
	beq done

	ldy #$1f	; load POINTER with start-of-row
 	lda table_low,y
 	sta POINTER
 	lda table_high,y
 	sta POINTER_H
 
 	ldy PADDLEL	; store CURSOR at POINTER plus COL
 	lda #00
 	sta (POINTER),y

 	inc PADDLEL
	inc PADDLER




	


done:	
	ldy #$0
scorePrint:
	lda score,y
	beq scoreNum
	sta $f0F0,y
	iny
	bne scorePrint

scoreNum:
	lda SCORE
	and #$F0
	LSR
	LSR
	LSR
	LSR
	TAY
	lda number,y
	sta $f0f8

	lda SCORE
	and #$0F
	TAY
	lda number,y
	sta $f0f9
	
	lda SCORE

	clc		; repeat
 	jmp draw
 
gameover:

	brk

 clear:	lda table_low	; clear the screen
 	sta POINTER
 	lda table_high
 	sta POINTER_H
 
 	ldy #$00
 	tya
 
 c_loop:	sta (POINTER),y
 	iny
 	bne c_loop
 
 	inc POINTER_H
 	ldx POINTER_H
 	cpx #$06
 	bne c_loop

	jmp setup


; these two tables contain the high and low bytes
; of the addresses of the start of each row
 
table_high:
dcb $02,$02,$02,$02,$02,$02,$02,$02
dcb $03,$03,$03,$03,$03,$03,$03,$03
dcb $04,$04,$04,$04,$04,$04,$04,$04
dcb $05,$05,$05,$05,$05,$05,$05,$05,
 
table_low:
dcb $00,$20,$40,$60,$80,$a0,$c0,$e0
dcb $00,$20,$40,$60,$80,$a0,$c0,$e0
dcb $00,$20,$40,$60,$80,$a0,$c0,$e0
dcb $00,$20,$40,$60,$80,$a0,$c0,$e0
 
; help message on character screen
 
 help:
 dcb "A","r","r","o","w",32,"k","e","y","s"
 dcb 32,"C","o","n","t","r","o","l",32,"p","a","d"
 dcb "d","l","e"
 dcb 00

score:
dcb "S","C","O","R","E",":",32
dcb 00

number:
dcb "0","1","2","3","4","5","6","7"
dcb "8","9","A","B","C","D","E","F"
dcb 00
