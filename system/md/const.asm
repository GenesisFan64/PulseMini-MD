; ====================================================================
; ----------------------------------------------------------------
; Settings
; ----------------------------------------------------------------

; If you want to set your RAM structure below $FF8000, you will
; need to modify the instructions that locate RAM as a WORD:
; ($8000-$FFFF)
; 
; from (ram_label).w to (ram_label).l

MDRAM_START	equ	$FFFF8000		; MD RAM Start, keep the first $FF (Available: $FF0000-$FFFFFF)
MAX_LOCRAM	equ	$2000			; Maximum local RAM for the current screen
MAX_PRNTLIST	equ	16			; Maximum print values

varNullVram	equ	$7FF			; Blank VRAM cell, for some video routines

; ====================================================================
; ----------------------------------------------------------------
; Variables
; ----------------------------------------------------------------

; --------------------------------------------------------
; System
; --------------------------------------------------------

; ------------------------------------------------
; vdp_ctrl READ bits
; ------------------------------------------------

bitVInt 	equ 7			; If a VBlank interrupt started
bitSprOvr	equ 6			; Sprite overflow
bitSprCol	equ 5			; Sprite collision (leftover from MS)
bitOdd		equ 4			; if we are in a Odd frame
bitVBlnk	equ 3			; VBlank
bitHBlnk	equ 2			; HBlank
bitDma		equ 1			; DMA Busy
bitPal		equ 0			; PAL flag (from VDP)

; ------------------------------------------------
; VDP register variables
; ------------------------------------------------

; Register $80
HVStop		equ $02
HintEnbl	equ $10
bitHVStop	equ 1
bitHintEnbl	equ 4

; Register $81
DispEnbl 	equ $40
VintEnbl 	equ $20
DmaEnbl		equ $10
bitDispEnbl	equ 6
bitVintEnbl	equ 5
bitDmaEnbl	equ 4
bitV30		equ 3
	
; ------------------------------------------------
; Controller buttons
; ------------------------------------------------

JoyUp		equ $0001
JoyDown		equ $0002
JoyLeft		equ $0004
JoyRight	equ $0008
JoyB		equ $0010
JoyC		equ $0020
JoyA		equ $0040
JoyStart	equ $0080
JoyZ		equ $0100
JoyY		equ $0200
JoyX		equ $0400
JoyMode		equ $0800

; right byte only
bitJoyUp	equ 0
bitJoyDown	equ 1
bitJoyLeft	equ 2
bitJoyRight	equ 3
bitJoyB		equ 4
bitJoyC		equ 5
bitJoyA		equ 6
bitJoyStart	equ 7

; left byte only
bitJoyZ		equ 0
bitJoyY		equ 1
bitJoyX		equ 2
bitJoyMode	equ 3

; ====================================================================
; ----------------------------------------------------------------
; Structures
; ----------------------------------------------------------------

; Controller
		struct 0
pad_id		ds.b 1
pad_ver		ds.b 1
on_hold		ds.w 1
on_press	ds.w 1
sizeof_input	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; Alias
; ----------------------------------------------------------------

Controller_1	equ RAM_InputData
Controller_2	equ RAM_InputData+sizeof_input

VDP_PALETTE	equ $C0000000				; Palette
VDP_VSRAM	equ $40000010				; Vertical scroll

; ====================================================================
; ----------------------------------------------------------------
; MD RAM
; ----------------------------------------------------------------

; This looks bad but it works as intended

		struct MDRAM_START		; Set struct at start of our base RAM

	; --------------------------------
	; First pass, empty sizes
	if MOMPASS=1
RAM_Global	ds.l 0
RAM_Local	ds.l 0
RAM_MdSystem	ds.l 0
RAM_MdVideo	ds.l 0
sizeof_mdram	ds.l 0
	else
	
	; --------------------------------
	; Second pass, sizes are set
RAM_Global	ds.b sizeof_global-RAM_Global
RAM_Local	ds.b MAX_LOCRAM
RAM_MdSystem	ds.b sizeof_mdsys-RAM_MdSystem
RAM_MdVideo	ds.b sizeof_mdvid-RAM_MdVideo
sizeof_mdram	ds.l 0
	endif					; end this section
	
	; --------------------------------
	; Report RAM usage on pass 5
	if MOMPASS=5
		message "MD RAM ends at: \{((sizeof_mdram)&$FFFFFF)}"
	endif
		finish

; ====================================================================
; ----------------------------------------------------------------
; System RAM
; ----------------------------------------------------------------

		struct RAM_MdSystem
RAM_InputData	ds.b sizeof_input*2			; 2 controller buffers
sizeof_mdsys	ds.l 0
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; Video cache RAM
; ----------------------------------------------------------------

		struct RAM_MdVideo
RAM_VdpCache	ds.b 24				; List of VDP register data copies
RAM_VidPrntList	ds.w MAX_PRNTLIST*3		; VDP address (2 WORDS), value type (WORD)
RAM_VidPrntVram	ds.w 1				; Current VRAM address for the Print routines
sizeof_mdvid	ds.l 0
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; Sound buffer RAM (68k and Z80)
; ----------------------------------------------------------------

; 		struct RAM_MdSound
; 		finish

; ====================================================================
