; ====================================================================
; ----------------------------------------------------------------
; ROM HEAD
; 
; Genesis
; ----------------------------------------------------------------

		dc.l 0				; Stack point (at end of RAM, goes backwards)
		dc.l MD_Entry			; Entry point
		dc.l MD_ErrBus			; Bus error
		dc.l MD_ErrAddr			; Address error
		dc.l MD_ErrIll			; ILLEGAL Instruction
		dc.l MD_ErrZDiv			; Divide by 0
		dc.l MD_ErrChk			; CHK Instruction
		dc.l MD_ErrTrapV		; TRAPV Instruction
		dc.l MD_ErrPrivl		; Privilege violation
		dc.l MD_Trace			; Trace
		dc.l MD_Line1010		; Line 1010 Emulator
		dc.l MD_Line1111		; Line 1111 Emulator
		dc.l MD_ErrorEx			; Error exception
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx	
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx		
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_HBlank			; VDP HBlank interrupt
		dc.l MD_ErrorTrap
		dc.l MD_VBlank			; VDP VBlank interrupt
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.b "SEGA GENESIS    "					; System name, the "SEGA" word is required
		dc.b "(C)NAME 2019.JAN"					; "(C)[company] [year].[month]"
		dc.b "PulseMini driver de sonido                      " ; Your game title in your country
		dc.b "PulseMini sound driver                          "	; Your game title outside of your country
		dc.b "GM 00000000-00"					; Serial number and version
		dc.w 0							; Checksum, leave it zero if not needed
		dc.b "J               "					; Peripherals supported, "J" is 3-button controller
		dc.l 0							; ROM Start address, always 0
		dc.l ROM_END-1						; ROM End address - 1
		dc.l $FF0000						; RAM Start address, always $FF0000
		dc.l $FFFFFF						; RAM Start address, always $FFFFFF
		dc.b "RA",$F8,$20
		dc.l $200001
		dc.l $20FFFF
		dc.l $20202020						; Modem data, not used
		dc.l $20202020
		dc.l $20202020
		dc.b "Driver name might get changed later.    "		; Memo
		dc.b "JUE             "					; Allowed regions: Japan, United states and Europe

; ====================================================================
; ----------------------------------------------------------------
; Error handlers
; 
; all these do nothing currently
; ----------------------------------------------------------------

MD_ErrBus:				; Bus error
MD_ErrAddr:				; Address error
MD_ErrIll:				; ILLEGAL Instruction
MD_ErrZDiv:				; Divide by 0
MD_ErrChk:				; CHK Instruction
MD_ErrTrapV:				; TRAPV Instruction
MD_ErrPrivl:				; Privilege violation
MD_Trace:				; Trace
MD_Line1010:				; Line 1010 Emulator
MD_Line1111:				; Line 1111 Emulator
MD_ErrorEx:				; Error exception
MD_ErrorTrap:
		rte			; Return from Exception

; ====================================================================
; ----------------------------------------------------------------
; Entry point
; ----------------------------------------------------------------

MD_Entry:
	; --------------------------------
	; Check if the system has TMSS
		move	#$2700,sr			; Disable interrputs
		move.b	(sys_io).l,d0			; Read IO port
		andi.b	#%1111,d0			; Get version, right 4 bits
		beq.s	.oldmd				; If == 0, skip this part
		move.l	($100).l,(sys_tmss).l		; Write "SEGA" to port sys_tmss
.oldmd:
		tst.w	(vdp_ctrl).l			; Random VDP test, to unlock it
		
	; --------------------------------
		moveq	#0,d0				; d0 = 0
		movea.l	d0,a6				; a6 = d0
		move.l	a6,usp				; move a6 to usp
.waitframe:	move.w	(vdp_ctrl).l,d0			; Wait for VBlank
		btst	#bitVint,d0
		beq.s	.waitframe
		move.l	#$80048144,(vdp_ctrl).l		; VDP: Set special bits, and keep Display (TMSS screen stays on)
		lea	($FFFF0000),a0			; a0 - RAM Address
		move.w	#($F000/4)-1,d0			; d0 - Bytes to clear / 4, minus 1
.clrram:
		clr.l	(a0)+				; Clear 4 bytes, and increment by 4
		dbf	d0,.clrram			; Loop until d0 == 0
		movem.l	($FF0000),d0-a6			; Trick: Grab clean RAM memory to clear all registers except a7 (Stack point)
		bra	MD_Main				; Branch to MD_Main
