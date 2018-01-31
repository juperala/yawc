; YAWC - Yeat Another WORM Clone

BITS 16							; Use 16 bit registers ???

segment mystack stack			; STACK SEGMENT - MYSTACK
	resb 0200h					; Reserve 512 byte
stacktop:

segment mydata data				; DATA SEGMENT - MYDATA

	; VARIABLES
	wormarray		resb	60000
	oldintmask		resw	1	; 1 word to save old mouse interrupt mask
	oldintseg		resw	1	; 1 word to save mouse interrupt routine segment
	oldintoff		resw	1	; 1 word to save mouse interrupt routine offset
	lastwormhead	resw	1	; 1 word to save worm's last position
	printflag		db		0	; 1 byte to save direction, initial value 0
	foodflag		db		0	; 1 byte to tell did the worm eat, initial value 0
	deadflag		db		0	; 1 byte to tell did the worm die, initial value 0
	level			db		1	; 1 byte to tell which level, initial value 1
	foodleft		db		0	; 1 byte to tell how much food left, initial value 0
	tempbyte		db		0	; 1 byte to save misc. stuff, initial value 0
	menuflag		db		0	; 1 byte to tell what the worm eat, initial value 0
	headindex		dw		0	; 1 word to tell wheres your tail, initial value 0
	tailindex		dw		0	; 1 word to tell wheres your head, initial value 0
	tailconst		dw		150	; 1 word to tell your initial length, initial value 150
	tailflag		dw		0	; 1 byte to tell do we cut your tail, initial value 0
	tempword		dw		0	; 1 word to save mics. stuff, initial value 0
	delay			dw		0	; 1 byte to adjust game speed
	delayconst		dw		0	; 1 byte to adjust game speed
	background		db		219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,"$"
	upperline1		db		201,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,187,"$"
	gamename1		db		186," YAWC: Yet Another WORM Clone ",186,"$"
	gamename2		db		186,"    Copyright",184," Juho Perala    ",186,"$"
	lowerline1		db		200,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,188,"$"
	upperline2		db		201,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,187,"$"
	menu1			db		186," TODAY'S MENU:                                                        ",186,"$"
	menu2			db		186," Apples = Lot's of carbohydrates. Boost's you up and keeps you short. ",186,"$"
	menu3			db		186," Hamburgers = Pure fat! Slows you down and grows your tail.           ",186,"$"
	menu4			db		186," Diet pills = Reduces your length. Too many of these and you go wild! ",186,"$"
	lowerline2		db		200,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,188,"$"
	upperline3		db		201,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,187,"$"
	pressany		db		186,"              Select speed: (S)low, (N)ormal or (F)ast?               ",186,"$"
	thatsall		db		186,"       That's all folks       ",186,"$"
	playagain		db		186,"   Play again? (Y)es or (N)o  ",186,"$"
	gameover		db		186,"     Game over! You died!     ",186,"$"
	lowerline3		db		200,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,188,"$"
	
	; CONSTANTS
	right			EQU	1		; Coordinates to move right in videomemory
	left			EQU	-1		; Coordinates to move left in videomemory
	down			EQU 320		; Coordinates to move dowm in videomemory
	up				EQU	-320	; Coordinates to move up in videomemory

	videobase		EQU 0a000h	; Segment address of video memory
	scrwidth		EQU 320		; Width of the screen in pixels
;	xcoord			EQU 50		; X-axis start coordinate
;	ycoord			EQU 30		; Y-axis start coordinate
	black			EQU 00h		; Black color
	blue			EQU 01h		; Blue color
	green			EQU 02h		; Green color
	wormgreen		EQU 30h		; Worm Green!!!
	red				EQU 04h		; Red color
	brown			EQU 06h		; Brown color
	gray			EQU 07h		; Gray color
	orange			EQU 29h		; Orange
	yellow			EQU 2ah		; Hamburger yellow
	white			EQU 0fh		; White color
	
segment mycode code				; CODE SEGMENT - MYCODE

	MouseInt:						; Mouse interrupt subroutine
		mov	cx, mydata				;
		mov	ds, cx					; Data Segment == mydata
		mov	byte [printflag], bl 	; Save information about mousekey
		retf						; Return from MouseInt (retf = return far)

	Intro:
		mov byte [tempbyte], 0
	.one:
		mov ah, 02h
		mov bh, 0h
		mov dh, byte [tempbyte]
		mov dl,	0
		int 10h						; INT 10h,2h - Set cursor
		mov dx, background
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		inc	byte [tempbyte]
		cmp	byte [tempbyte], 80
		jne	.one
		cmp word [tempword], 1		; What should we print
		jne .intro					; Print welcome message
		jmp .end					; Print end message
	.intro:
		mov ah, 02h
		mov bh, 0h
		mov dh, 3
		mov dl, 23
		int 10h						; INT 10h,2h - Set cursor
		mov dx, upperline1
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 4
		mov dl, 23
		int 10h						; INT 10h,2h - Set cursor
		mov dx, gamename1
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 5
		mov dl, 23
		int 10h						; INT 10h,2h - Set cursor
		mov dx, gamename2
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 6
		mov dl, 23
		int 10h						; INT 10h,2h - Set cursor
		mov dx, lowerline1
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 10
		mov dl, 4
		int 10h						; INT 10h,2h - Set cursor
		mov dx, upperline2
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 11
		mov dl, 4
		int 10h						; INT 10h,2h - Set cursor
		mov dx, menu1
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 12
		mov dl, 4
		int 10h						; INT 10h,2h - Set cursor
		mov dx, menu2
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 13
		mov dl, 4
		int 10h						; INT 10h,2h - Set cursor
		mov dx, menu3
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 14
		mov dl, 4
		int 10h						; INT 10h,2h - Set cursor
		mov dx, menu4
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 15
		mov dl, 4
		int 10h						; INT 10h,2h - Set cursor
		mov dx, lowerline2
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 19
		mov dl, 4
		int 10h						; INT 10h,2h - Set cursor
		mov dx, upperline2
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 20
		mov dl, 4
		int 10h						; INT 10h,2h - Set cursor
		mov dx, pressany
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 21
		mov dl, 4
		int 10h						; INT 10h,2h - Set cursor
		mov dx, lowerline2
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
	.setspeed:
		mov word [delayconst], 300
		mov	ah,8h
  		int	21h						; INT 21h,8h - Get character without echo
  		or	al,20h					; Force char to lower case	
		cmp al, 's'					; S == Slow, delay == 350
		je .setslow
		cmp al, 'f'					; F == Fast, delay == 150
		je	.setfast	
		ret
	.setslow:
		mov word [delayconst], 425
		ret
	.setfast:
		mov word [delayconst], 175
		ret
	.end:
		mov ah, 02h
		mov bh, 0h
		mov dh, 10
		mov dl, 25
		int 10h						; INT 10h,2h - Set cursor
		mov dx, upperline3
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 13
		mov dl, 25
		int 10h						; INT 10h,2h - Set cursor
		mov dx, lowerline3
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 11
		mov dl, 25
		int 10h						; INT 10h,2h - Set cursor
		mov dx, gameover
		cmp byte [deadflag], 1
		je .three
		mov dx, thatsall		
	.three:		
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
		mov ah, 02h
		mov bh, 0h
		mov dh, 12
		mov dl, 25
		int 10h						; INT 10h,2h - Set cursor
		mov dx, playagain
		mov ah, 09h
		int 21h						; INT 21h,9h - Print string	
	.newgame:
		mov word [tempword], 1
		mov	ah,8h
  		int	21h						; INT 21h,8h - Get character without echo
  		or	al,20h					; Force char to lower case	
		cmp al, 'n'					; No == Exit, tempword == 0
		je .exit
		cmp al, 'y'					; Yes == Start new game, tempword == 1
		jne .newgame	
		mov word [tempword], 0
	.exit:
		ret

	Delay:
		mov	dx, word [delay]
	.pause1:
		mov	cx, 55000
	.pause2:
		dec	cx
		jne	.pause2
		dec	dx
		jne	.pause1
		ret
	
	PrintBorders:
		mov di, 0					; Set video memory index = 0
		mov cx, 320
	.one:
		mov	byte [es:di], blue
		inc di
		loop .one					; Print upper border
		mov	byte [es:di], blue
		mov cx, 75
	.two:
		add di, 319
		mov	byte [es:di], blue
		inc di
		mov	byte [es:di], blue
		loop .two					; Print upper side borders
		add di, 16000				; Make hole to side border, height 50 rows
		mov cx, 73
	.three:
		add di, 319
		mov	byte [es:di], blue
		inc di
		mov	byte [es:di], blue
		loop .three					; Print lower side borders
		mov cx, 320
	.four:
		mov	byte [es:di], blue
		inc di
		loop .four					; Print lower border
		cmp byte [level], 1			; Is it 2. level?
		je .exit
		mov di, 16100
		mov cx, 120
	.five:
		mov	byte [es:di], blue
		inc di
		loop .five	
		mov di, 48100
		mov cx, 120
	.six:
		mov	byte [es:di], blue
		inc di
		loop .six	
		cmp byte [level], 2			; Is it 3. level?
		je .exit
		mov di, 32245
		mov cx, 150
	.seven:
		mov	byte [es:di], blue
		inc di
		loop .seven	
		cmp byte [level], 3			; Is it 4. level?
		je .exit
		mov di, 19444
		mov cx, 80
	.eight:
		mov	byte [es:di], blue
		add di, 150
		mov	byte [es:di], blue
		add di, 170
		loop .eight
	.exit
		ret	

	PrintDietPill:	; Start x-coord between 2-310 and y-coord between 1-193
		mov cx, 4
	.one:
		mov	byte [es:di], orange
		inc di
		loop .one
		mov cx, 4
	.two:
		mov	byte [es:di], white
		inc di
		loop .two
		add di, 311
		mov cx, 5
	.three:
		mov	byte [es:di], orange
		inc di
		loop .three
		mov cx, 5
	.four:
		mov	byte [es:di], white
		inc di
		loop .four
		add di, 310
		mov cx, 5
	.five:
		mov	byte [es:di], orange
		inc di
		loop .five
		mov cx, 5
	.six:
		mov	byte [es:di], white
		inc di
		loop .six
		add di, 311
		mov cx, 4
	.seven:
		mov	byte [es:di], orange
		inc di
		loop .seven
		mov cx, 4
	.eight:
		mov	byte [es:di], white
		inc di
		loop .eight
		ret	
	
	PrintHamburger:	; Start x-coord between 2-310 and y-coord between 1-193
		mov cx, 8
	.one:
		mov	byte [es:di], yellow
		inc di
		loop .one
		add di, 311
		mov cx, 10
	.two:
		mov	byte [es:di], yellow
		inc di
		loop .two
		add di, 310
		mov cx, 10
	.three:
		mov	byte [es:di], green
		inc di
		loop .three
		add di, 310
		mov cx, 10
	.four:
		mov	byte [es:di], brown
		inc di
		loop .four
		add di, 310
		mov cx, 10
	.five:
		mov	byte [es:di], yellow
		inc di
		loop .five
		add di, 310
		mov cx, 10
	.six:
		mov	byte [es:di], yellow
		inc di
		loop .six
		ret		

	PrintApple: ; Start x-coord between 3-312 and y-coord between 1-191
		mov cx, 3
	.one:
		mov	byte [es:di], green
		inc di
		loop .one
		inc di
		mov cx, 3
	.two:
		mov	byte [es:di], brown
		inc di
		loop .two
		add di, 312
		mov cx, 5
	.three:
		mov	byte [es:di], green
		inc di
		loop .three
		mov	byte [es:di], brown
		add di, 314
		mov cx, 3
	.four:
		mov	byte [es:di], green
		inc di
		loop .four
		mov cx, 2
	.five:
		mov	byte [es:di], red
		inc di
		loop .five
		mov	byte [es:di], green
		inc di
		mov cx, 2
	.six:
		mov	byte [es:di], red
		inc di
		loop .six
		add di, 312
		mov cx, 2
	.seven
		mov	byte [es:di], green
		inc di
		loop .seven
		mov	byte [es:di], red
		inc di
		mov	byte [es:di], white
		inc di
		mov	byte [es:di], gray
		inc di
		mov cx, 4
	.eight:
		mov	byte [es:di], red
		inc di
		loop .eight
		add di, 313
		mov	byte [es:di], red
		inc di
		mov cx, 2
	.nine:
		mov	byte [es:di], gray
		inc di
		loop .nine
		mov cx, 4
	.ten:
		mov	byte [es:di], red
		inc di
		loop .ten
		add di, 313
		mov cx, 7
	.eleven:
		mov	byte [es:di], red
		inc di
		loop .eleven
		add di, 314
		mov cx, 5
	.twelve:
		mov	byte [es:di], red
		inc di
		loop .twelve
		add di, 316
		mov cx, 3
	.thirteen:
		mov	byte [es:di], red
		inc di
		loop .thirteen
		ret
	
	ClearFood:							; Clears 20x20 pixel are near food!
		mov word [lastwormhead], di		; Save worm's position
		sub di, 3210
		mov ax, 20
	.three:
		mov cx, 20
	.one:
		cmp byte [es:di], wormgreen		; If pixel is wormgreen, don�t clear
		je .two
		cmp byte [es:di], blue			; If pixel is borderblue, don�t clear
		je .two
		cmp byte [es:di], orange
		jne .four
		mov byte [menuflag], 1			; You ate dietpill, menuflag == 1
	.four:
		cmp byte [es:di], yellow
		jne .five
		mov byte [menuflag], 2			; You ate hamburger, menuflag == 2
	.five:
		mov	byte [es:di], black
	.two:
		inc	di
		loop .one						; Jump to next pixel
		add di, 300
		dec ax
		cmp ax, 0
		jne .three						; Jump to next row
		cmp byte [menuflag], 1
		jne .six
		sub word [delay], 40			; Dietpill, increase worm speed by 40
		sub word [tailflag], 50			; Dietpill, removes length by 50 pixel	
		jmp .exit
	.six:
		cmp byte [menuflag], 2
		jne .seven
		add word [delay], 20			; Hamburger, decrease worm speed by 25
		add word [tailflag], 75			; Hamburger, grow by with 100 pixel
		jmp .exit
	.seven:
		sub word [delay], 10			; Apple, increase worm speed by 10
		add word [tailflag], 25			; Apple, grow tail by 25 pixel
	.exit:
		mov byte [menuflag], 0
		mov byte [foodflag], 0
		mov di, word [lastwormhead]		; Restore worm�s position
		dec byte [foodleft]				; One food eaten
		ret
		
	
	PrintFood:
		mov	ax, word [delayconst]
		mov word [delay], ax					; Set start speed
		mov	ax, word [tailconst]
		mov word [tailflag], ax					; Set start lengt
		mov di, (scrwidth * 5) + 5
		call PrintApple
		mov di, (scrwidth * 90) + 160
		call PrintApple
		mov di, (scrwidth * 65) + 250
		call PrintHamburger
		cmp byte [level], 4						; Is is 2. level?
		je .jmphere4
		mov di, (scrwidth * 130) + 300
		call PrintApple
	.jmphere4:
		mov di, (scrwidth * 180) + 175
		call PrintApple
		mov byte [foodleft], 5					; Set 6 pcs. food
		mov di, (scrwidth * 30) + 50			; Set snake start coordinates
		mov bx, 1								; Snake direction init, go right
		cmp byte [level], 1						; Is is 2. level?
		jne .jmphere1
		jmp	FAR .exit
	.jmphere1:
		sub word [delay], 20					; Decrease speed by 20
		add word [tailflag], 30					; Increase tail length by 30 pixel
		add byte [foodleft], 3					; Set 8 pcs. food!
		mov di, (scrwidth * 170) + 3
		call PrintHamburger
		mov di, (scrwidth * 3) + 250
		call PrintHamburger
		mov di, (scrwidth * 80) + 40
		call PrintDietPill
		mov di, (scrwidth * 30) + 270			; Set snake start coordinates
		mov bx, -1								; Snake direction init, go right
		cmp byte [level], 2						; Is it 3. level?
		je .exit
		sub word [delay], 20					; Decrease speed by 20
		add word [tailflag], 30					; Increase tail length by 30 pixel
		add byte [foodleft], 3					; Set 11 pcs. food!
		mov di, (scrwidth * 130) + 130
		call PrintHamburger
		mov di, (scrwidth * 125) + 270
		call PrintHamburger
		mov di, (scrwidth * 180) + 25
		call PrintDietPill
		mov di, (scrwidth * 50) + 175			; Set snake start coordinates
		mov bx, 320								; Snake direction init, go right

		cmp byte [level], 3						; Is it 4. level?
		je .exit
		add word [delay], 40					; Increase speed by 40
		add word [tailflag], 30					; Increase tail length by 30 pixel
		add byte [foodleft], 1					; Set 12 pcs. food!
		mov di, (scrwidth * 15) + 305
		call PrintDietPill
		mov di, (scrwidth * 70) + 110
		call PrintHamburger
		mov di, (scrwidth * 175) + 235			; Set snake start coordinates
		mov bx, -320							; Snake direction init, go right
	.exit
		ret
	
	PrintPixel:									; Print next worm-pixel
		add	di, bx
		cmp	byte [es:di], wormgreen
		je .hit									; Hit to tail
		cmp byte [es:di], blue
		je .hit									; Hit to border
		cmp byte [es:di], black
		je .paint								; No hit to anything
		mov byte [foodflag], 1					; Hit to Food, set foodflag
		jmp .paint
	.hit:
		mov byte [deadflag], 1					; Game over, set deadflag
	.paint:
		mov	byte [es:di], wormgreen				; Set next pixel to green
		mov word [tempword], bx					; Save old bx
		mov ax, di
		mov bx, wormarray
		add bx, word [headindex]
		mov byte [bx], ah
		inc bx
		inc	word [headindex]					; Move head one forward
		mov byte [bx], al
		inc	word [headindex]					; Move head one forward
		mov bx, word [tempword]
		cmp	word [headindex], 60000				; Check if wormarray full
		jne	.ok1
		mov	word [headindex], 0
	.ok1:
		cmp	word [tailflag], 0
		jle	.cleartail
		dec	word [tailflag]
		ret
	.cleartail:
		mov word [lastwormhead], di					; Save worm's position
		mov word [tempword], bx
		mov bx, wormarray
		add bx, word [tailindex]
		mov ah, byte [bx]
		inc bx
		inc	word [tailindex]						; Move tail one forward
		mov al, byte [bx]
		inc	word [tailindex]						; Move tail one forward
		cmp	word [tailindex], 60000					; Check if wormarray is in end
		jne	.ok2
		mov	word [tailindex], 0
	.ok2:
		mov di, ax
		mov	byte [es:di], black						; Clear tailpixel
		mov bx, word [tempword]
 		mov di, word [lastwormhead]					; Restore worm's position
 		cmp	word [tailflag], 0						; Should we cut more tail?
 		je	.exit
 		inc	word [tailflag]
 		jmp	.cleartail
 	.exit:
		ret
		
		
		
		
	ChangeDirection:				; Set the worms direction
		cmp	byte [printflag], 1		; Check where we want to go?
		je	.turnleft				; Goto left
		cmp	byte [printflag], 2		; Goto .exit if we want to go straight
		jne	.exit                 	; Else we want to goto right
	.turnright:						; If we are going left...
		cmp    bx, left				; Next direction is up
		je     .goup				; If we are going right...
		cmp    bx, right			; Next direction is down
		je     .godown				; If we are going up...
		cmp    bx, up				; Next direction is right
		je     .goright				; If we are going down...
		cmp    bx, down				; Next direction is left
		je     .goleft				; We want to *turn left*
	.turnleft:						; If we are going left...
		cmp    bx, left				; Next direction is down
		je     .godown				; If we are going right...
		cmp    bx, right			; Next direction is up
		je     .goup				; If we are going up...
		cmp    bx, up				; Next direction is left
		je     .goleft				; If we are going down...
		cmp    bx, down				; Next direction is right
		je     .goright
	.goup:							; Change direction to up
		mov    bx, up
		jmp    .exit
	.godown:						; Change direction to down
		mov    bx, down
		jmp    .exit
	.goleft:						; Change direction to left
		mov    bx, left
		jmp    .exit
	.goright:						; Change direction to right
		mov    bx, right
		jmp    .exit
	.exit:
		ret

	ClearScreen:					; Clear screen in 320x200x250 mode
		mov di, 0
		mov cx, 64000
	.one:
		mov	byte [es:di], black
		inc di
		loop .one
		mov di, 0
		ret

..start:						; Starting point of the program

Main:							; START OF MAIN PROGRAM

	mov ax, 0003h
	int 10h						; INT 10h,0h - Set video mode to 80x25x16 text

	mov	ax, mydata
	mov	ds, ax					; Data Segment == mydata
	mov	ax, mystack
	mov	ss, ax					; Stack Segment == mystack
	mov	sp, stacktop			; Stack Pointer == stacktop

	call Intro					; Print start text
	
	mov ax, 0
	int 33h						; INT 33h,0h - Mouse reset / Get mouse status
	cmp ax, 0
	jne .mousefound
	jmp FAR .exit				; Jump to Exit if AX == 0 (mouse not installed)

.mousefound:

	mov dx, MouseInt			; Offset of MouseInt
	mov cx, 1010b				; CX == 1010b, Interrupt on left & right keypresses
	mov ax, mycode
	mov es, ax					; Extra Segment == mycode	
	mov ax, 14h
	int 33h						; INT 33h,14h - Swap mouse interrupt subroutine

	mov word [oldintmask], cx	; Save old interrupt mask
	mov word [oldintseg], es	; Save old interrupt segment
	mov word [oldintoff], dx	; Save old interrupt offset
	
	mov ax, 0013h
	int 10h						; INT 10h,0h - Set video mode 320x200x256
	mov	ax, videobase
	mov	es, ax					; Set videomemory base
	
.nextlevel:

	call ClearScreen			; Clear videomode
	call PrintBorders			; Print borders
	call PrintFood				; Print food
			
.mainloop:

	call Delay					; Delay loop
	call ChangeDirection		; Check which direction to goto
	call PrintPixel				; Print next pixel to green

	cmp	byte [foodflag], 1		; Check did the worm eat?
	jne .nofood
	call ClearFood				; Erase last food from screen
	cmp byte [foodleft], 0		; Check is any food left
	jne .nofood
	cmp byte [level], 4			; Did you just pass the last level?	
	je .exit
	inc byte [level]
	mov	word [headindex], 0
	mov	word [tailindex], 0
	jmp .nextlevel				; Goto next level
	
.nofood:
	
	mov byte [printflag], 0		; Null the direction
	cmp byte [deadflag], 1		; Check if snake dies
	je	.exit					; Quit if snake dead
	jmp	.mainloop
	
.exit:

	mov ax, word [oldintseg]
	mov es, ax					; ES == old interrupt segment
	mov dx, word [oldintoff]	; DX == old interrupt offset
	mov cx, word [oldintmask]	; CX == old interrupt mask
	mov ax, 0ch					; AX == 0ch
	int 33h						; INT 33h,0ch - Set mouse subroutine and interrupt mask

	mov ax, 0003h
	int 10h						; INT 10h,0h - Set video mode to 80x25x16 text
	
	cmp byte [deadflag], 2		; Check if the user wants to exit immediately
	je	.gotoexit
	mov word [tempword], 1
	call Intro					; Print end text
	cmp	word [tempword], 1
	je	.gotoexit
	mov byte [level], 1			; Reset to 1. level
	mov byte [deadflag], 0
	mov byte [foodflag], 0
	mov word [tempword], 0
	mov	word [headindex], 0
	mov	word [tailindex], 0
	jmp	FAR Main
	
.gotoexit
	mov ax, 0003h
	int 10h						; INT 10h,0h - Set video mode to 80x25x16 text

	mov	ah, 4ch
	int	21h						; INT 21h,4Ch - Return to DOS
	
.end