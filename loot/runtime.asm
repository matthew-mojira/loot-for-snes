fastrom
hirom

;;    IMPORTANT FILES

incsrc "types.asm"    ; type system definitions
incsrc "registers.asm"; hardware registers and bitmasks

;;    RUNTIME DEFINITIONS

; I/O
tile_pointer = $7E0012    ; long
tilemap      = $7E2000    ; $800/2K bytes

; Heap
heap_pointer = $7E0030  ; long pointer
deref_area   = $7E0033  ; long pointer
!HEAP_START  = $7E8000

;; end of program spot
end_of_program = $002000
err_of_program = $002001

; Graphics and tilemaps
!GRAPHICS_FILE  = "graphics.bin"
!GRAPHICS_SIZE #= filesize("!GRAPHICS_FILE")
!TILEMAP_FILE   = "tilemap.bin"
!TILEMAP_SIZE  #= filesize("!TILEMAP_FILE")

;;    COMPILED CODE

ORG $C00000 ; program code

reset bytes

incsrc !CODE_FILE     ; compiled code

; debug information regarding how big your program is
print "Compiled code usage: ", bytes, " bytes"

warnpc $C08000-1  ; ensure code is not too big

;;    ROM HEADER INFORMATION

ORG $00FFB0
    db    "  "        ; MAKER CODE (2 Bytes)
    db    "MGL "      ; GAME CODE (4 Bytes)
    db    $00, $00, $00, $00, $00, $00, $00    ; hardcoded
    db    $00         ; EXPANSION RAM SIZE
    db    $00         ; SPECIAL VERSION (normally $00)
    db    $00         ; CARTRIDGE SUB-NUMBER (normally $00)
    db    "CMSC 430 FINALPROJECT"    ; GAME TITLE (21 Bytes)
          ;|-------------------|;
    db    $31         ; MAP MODE (fastrom, hirom)
    db    $00         ; CARTRIDGE TYPE (ROM only)
    db    $06         ; ROM SIZE (2^6 KB = 64KB) -- corresponds to bank C0 only
    db    $00         ; RAM SIZE (0 means 0KB)
    db    $01         ; DESTINATION CODE (north america)
    db    $33         ; hardcoded
    db    $00         ; MASK ROM VERSION (Ver 1.0)

;;    INTERRUPT VECTOR INFORMATION

ORG $00FFE0
    ;;  N/A    N/A    COP    BRK   ABORT   NMI    RESET    IRQ
    dw $0000, $0000, I_COP, I_BRK, $0000, I_NMI, I_RESET, I_IRQ      ; NATIVE
    dw $0000, $0000, I_COP, I_BRK, $0000, I_NMI, I_RESET, I_IRQ      ; EMULATION

;;    INITIALIZATION ROUTINES

ORG $C08000       ; bank 0 mirror starts at $008000
I_RESET:
    SEI           ; set interrupt disable
    CLC           ; clear carry flag
    XCE           ; exchange carry and emulation (turns off emulation mode)
    JML   F_RESET
F_RESET:
    REP   #$30    ; accumulator 16-bit
    LDX.W #$1FFF
    TXS           ; initialize stack pointer
    SEP   #$20    ; accumulator 8-bit
    LDA.B #$01
    STA.W MEMSEL  ; sets FastROM
    JSR   clear_regs
    JSR   clear_memory
    LDA.B #$C0    ; automatic read of the SNES read the first pair of JoyPads
    STA.W WRIO    ; IO Port Write Register

    JSR   initialize  ; more specialized initialization routine

    SEP   #$20

    LDA.B #$80
    STA.W NMITIMEN

    REP   #$30  ; 16-bit AXY

    JSL   entry    ; CALL THE COMPILED CODE!!

    SEP   #$20

    LDA.B #$00
    STA.W NMITIMEN

    ;; display stuff to the screen
    LDA.B #!DISP_FBlank
    STA.W INIDISP  ; begin F-blank

    ; palette (green)
    STZ.W CGADD
    ; pal transfer (no DMA, hardcoded few colors)
    STZ.W CGDATA
    STZ.W CGDATA
    LDA.B #%11100010
    STA.W CGDATA
    LDA.B #%00010010
    STA.W CGDATA

    JSR   dma_tilemap

    LDA.B #!DISP_NoBlank
    STA.W INIDISP  ; end F-blank

    ;; Done with everything!

    SEP   #$20
    STZ.W end_of_program

-   BRA   - ;loop forever

; this should never run
I_NMI:
    PHA
    PHX
    PHY
    PHP

    LDA.W RDNMI  ; read for NMI acknowledge

    ;; display stuff to the screen
    SEP   #$20    ; 8-bit A

    LDA.B #!DISP_FBlank
    STA.W INIDISP  ; begin F-blank
    JSR   dma_tilemap
    LDA.B #!DISP_NoBlank
    STA.W INIDISP  ; end F-blank

    PLP
    PLY
    PLX
    PLA
    RTI           ; ReTurn from Interrupt

; this should never run
I_IRQ:
    RTI           ; ReTurn from Interrupt

I_BRK:
    SEP   #$20    ; 8-bit A

    ; put 'err on the tilemap
    LDA.B #'e'
    JSR   putchar
    LDA.B #'r'
    JSR   putchar
    JSR   putchar

    LDA.B #$80
    STA.W INIDISP; begin F-blank

    ; palette
    STZ.W CGADD
    ; pal transfer (no DMA, hardcoded few colors)
    STZ.W CGDATA
    STZ.W CGDATA
    LDA.B #%11111111
    STA.W CGDATA
    LDA.B #%00011100
    STA.W CGDATA

    JSR   dma_tilemap  ; force display

    LDA.B #$0F
    STA.W INIDISP; end F-blank

    SEP   #$20
    STZ.W err_of_program

-   BRA   - ;loop forever

; this should never run
I_COP:
    BRK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CLEAR REGISTERS
;; Clears all the registers. This is a general clear of everything.
;; Initialization comes later.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clear_regs:
    PHP           ; push processor status register

    SEP   #$20    ; accumulator 8-bit
    LDA.B #$80    ; A = %1000 0000

    STA.W INIDISP
    STZ.W OBJSEL
    STZ.W OAMADD
    STZ.W OAMADD+1
    STZ.W OAMDATA
    STZ.W BGMODE
    STZ.W MOSAIC
    STZ.W BG1SC
    STZ.W BG2SC
    STZ.W BG3SC
    STZ.W BG4SC
    STZ.W BG12NBA
    STZ.W BG34NBA
    STZ.W BG1HOFS
    STZ.W BG1HOFS
    STZ.W BG1VOFS
    STZ.W BG1VOFS
    STZ.W BG2HOFS
    STZ.W BG2HOFS
    STZ.W BG2VOFS
    STZ.W BG2VOFS
    STZ.W BG3HOFS
    STZ.W BG3HOFS
    STZ.W BG3VOFS
    STZ.W BG3VOFS
    STZ.W BG4HOFS
    STZ.W BG4HOFS
    STZ.W BG4VOFS
    STZ.W BG4VOFS
    STA.W VMAINC
    STZ.W VMADD
    STZ.W VMADD+1
    STZ.W M7SEL
    LDA.B #$01
    STZ.W M7A
    STA.W M7A
    STZ.W M7B
    STZ.W M7B
    STZ.W M7C
    STZ.W M7C
    STZ.W M7D
    STA.W M7D
    STZ.W M7X
    STZ.W M7X
    STZ.W M7Y
    STZ.W M7Y
    STZ.W CGADD
    STZ.W W12SEL
    STZ.W W34SEL
    STZ.W WOBJSEL
    STZ.W WH0
    STZ.W WH1
    STZ.W WH2
    STZ.W WH3
    STZ.W WBGLOG
    STZ.W WOBJLOG
    STZ.W TM
    STZ.W TS
    STZ.W TMW
    STZ.W TSW
    LDA.B #$30
    STA.W CGSWSEL   ; WHY?
    STZ.W CGADSUB
    LDA.B #$E0
    STA.W COLDATA   ; WHY?
    STZ.W SETINI
    STZ.W NMITIMEN
    STZ.W WRMPYA
    STZ.W WRMPYB
    STZ.W WRDIV
    STZ.W WRDIV+1
    STZ.W WRDIVB
    STZ.W HTIME
    STZ.W HTIME+1
    STZ.W VTIME
    STZ.W VTIME+1
    STZ.W MDMAEN
    STZ.W HDMAEN

    PLP
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CLEAR MEMORY
;; Clears all of WRAM and VRAM (except WRAM stack area). This is a general
;; clean and will be initialized with useful stuff later.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clear_memory:
    PHP
    PHB

    SEP #$20
    REP #$10

    STZ.B $00
    STZ.W VMAINC
    LDX.W #0
    STX.W VMADD
    STX.W OAMADD
    STZ.W CGADD
    STX.W DMAADDR
    STX.W $4312
    STX.W $4322
    LDA.B #$7E
    STA.W $4304
    STA.W $4314
    STA.W $4324

    STX.W $4305
    LDX.W #$200
    STX.W $4315
    LDX.W #$220
    STX.W $4325

    LDA.B #$18
    STA.W $4301
    LDA.B #$22
    STA.W $4311
    LDA.B #$04
    STA.W $4321

    LDA.B #$09
    STA.W $4300
    LDA.B #$9A
    STA.W $4310
    STA.W $4320

    LDA.B #7
    STA.W $420B

    ; clear WRAM

    REP   #$30
    LDA.W #$0000
    LDX.W #$0FFE
-   STA.L $7E0000,X
    STA.L $7E1000-4,X
    STA.L $7E2000,X
    STA.L $7E3000,X
    STA.L $7E4000,X
    STA.L $7E5000,X
    STA.L $7E6000,X
    STA.L $7E7000,X
    STA.L $7E8000,X
    STA.L $7E9000,X
    STA.L $7EA000,X
    STA.L $7EB000,X
    STA.L $7EC000,X
    STA.L $7ED000,X
    STA.L $7EE000,X
    STA.L $7EF000,X
    STA.L $7F0000,X
    STA.L $7F1000,X
    STA.L $7F2000,X
    STA.L $7F3000,X
    STA.L $7F4000,X
    STA.L $7F5000,X
    STA.L $7F6000,X
    STA.L $7F7000,X
    STA.L $7F8000,X
    STA.L $7F9000,X
    STA.L $7FA000,X
    STA.L $7FB000,X
    STA.L $7FC000,X
    STA.L $7FD000,X
    STA.L $7FE000,X
    STA.L $7FF000,X
    DEX   #2
    BMI   +
    BRL   -

+   PLB
    PLP
    RTS




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; INITIALIZATION SEQUENCE
;; prepares graphics/PPU registers for display
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

initialize:
    PHP

    SEP   #$20
    REP   #$10

    LDA.B #$00
    STA.W NMITIMEN   ; disable NMI interrupt (we're running main game loop)

    LDA.B #!DISP_FBlank
    STA.W INIDISP    ; begin F-blank

    LDA.B #$10
    STA.W BG1SC    ; bg1 tilemap starts at $1000 in VRAM

    STZ.W BG12NBA

    JSR   upload_graphics

    LDA.B #$FF
    STA.W BG1VOFS
    STA.W BG1VOFS
    STZ.W BG1HOFS
    STZ.W BG1HOFS
    ; more background scroll?

    ; set background mode
    LDA.B #!BG_Mode1
    STA.W BGMODE
    LDA.B #!Through_BG1
    STA.W TM ; enable BG1 main screen

    ; clear tilemap
    REP   #$30

    ; blank out tilemap
    LDA.W #$0080
    LDX.W #$0800
-   STA.L tilemap,X
    DEX   #2
    BNE   -
    STA.L tilemap

    ; import tilemap from file
    SEP   #$20      ; 8-bit A

;    LDX.W #tilemap_data
;    STX.W $4302
;    LDA.B #<:tilemap_data
;    STA.W $4304
;    LDX.W #!TILEMAP_SIZE
;    STX.W $4305
;    LDX.W #tilemap_layer1
;    STX.W $2181
;    LDA.B #<:tilemap_layer1
;    STA.W $2183
;    LDA.B #$80
;    STA.W $4301
;    STZ.W $4300
;    LDA.B #$01
;    STA.W $420B

    JSR   dma_tilemap ; for loading screen purposes

    LDA.B #!DISP_NoBlank
    STA.W INIDISP    ; end F-blank

    ; set up pointer for drawing text to screen
    LDA.B #<:tilemap
    LDX.W #tilemap
    STA.B tile_pointer+2
    STX.B tile_pointer

    ; initialize heap pointer
    LDA.B #<:!HEAP_START
    LDX.W #!HEAP_START

    STA.B heap_pointer+2     ; set up heap pointer
    STX.B heap_pointer
    STA.B deref_area+2    ; set up dereferencing area

    PLP
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UPLOAD GRAPHICS ROUTINE
;; uploads the ASCII graphics and the palette to VRAM/CGRAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

upload_graphics:
    PHP
    SEP   #$20    ;8-bit A
    REP   #$10    ;16-bit XY

    ; gfx
    LDA.B #!VINC_IncOnHi
    STA.W VMAINC
    LDX.W #$0000
    STX.W VMADD

    ; gfx dma

    LDA.B #<:graphics_data
    STA.W $4304
    LDX.W #graphics_data
    STX.W $4302
    LDA.B #$18
    STA.W $4301
    LDY.W #!GRAPHICS_SIZE
    STY.W $4305
    LDA.B #$01
    STA.W $4300
    STA.W $420B   ; DMA enable

    ; palette
    STZ.W CGADD

    ; pal transfer (no DMA, hardcoded few colors)
    STZ.W CGDATA
    STZ.W CGDATA
    LDA.B #%11101100
    STA.W CGDATA
    LDA.B #%11000101
    STA.W CGDATA
    ; previously blue, then became gray by a bug but i liked it more

    PLP
    RTS




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; TILEMAP UPLOAD ROUTINE
;; uploads tilemap from copy in RAM to VRAM
;; F-Blank is not enabled here, so you will have to do it yourself
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dma_tilemap:
    ; display stuff now!
    ; DMA tilemap
    PHP

    ; the actual DMA stuff
    SEP   #$20      ; A 8-bit
    REP   #$10      ; XY 16-bit

    LDA.B #$80
    STA.W VMAINC
    LDX.W #$1000
    STX.W VMADD

    LDA.B #<:tilemap
    STA.W $4304
    LDX.W #tilemap
    STX.W $4302
    LDA.B #$18
    STA.W $4301
    LDY.W #$0800
    STY.W $4305
    LDA.B #$01
    STA.W $4300
    LDA.B #$01
    STA.W $420B

    PLP
    RTS



;; input character expected to be in ASCII
putchar:
    PHP

    SEP   #$20    ; 8-bit A
    STA.B [tile_pointer]
    REP   #$20    ; 16-bit A
    INC.B tile_pointer
    INC.B tile_pointer

    PLP
    RTS

print_bool:
    PHP

    PHA
    SEP   #$20
    LDA.B #'#'
    JSR   putchar
    REP   #$20
    PLA

    CMP.W #!val_true
    SEP   #$20
    BEQ   .true
    ; false
    LDA.B #'f'
    JSR   putchar
    BRA   .done
.true:
    LDA.B #'t'
    JSR   putchar
.done:

    PLP
    RTL

print_char:
    PHP

    LSR   #!char_shift
    JSR   putchar

    PLP
    RTL

print_int:
    PHP

    ; sign information
    BPL   +

    ; negative
    PHA
    LDA.W #'-'
    JSR   putchar
    PLA

    EOR.W #$FFFF  ; flip the bits
    INC           ; add 1
+
    LSR   #!int_shift
    BEQ   .zero

    ; why initialize? should be overwritten always!
    STZ.B $00
    STZ.B $02
    STZ.B $04
    STZ.B $06
    STZ.B $08

    LDX.W #8

    ; loop to get digits
-   STA.W WRDIV   ; score in dividend
    SEP   #$20    ; 8-bit A
    LDA.B #10
    STA.W WRDIVB  ; store in divisor, starts process
    NOP   #8      ; need to wait 16 cycles
    LDA.W RDMPY   ; remainder of the divison by 10
    CLC
    ADC.B #$30    ; ASCII correction
    STA.B $00,X   ; store in digit
    REP   #$20    ; 16-bit A
    LDA   RDDIV   ; result of the division

    ; invariant
    DEX   #2      ; start over
    BPL   -

    ; move scratch to tilemap
    LDX.W #0
    ; get rid of trailing zeros
-   LDA.B $00,X
    CMP.W #'0'
    BNE   +
    INX   #2
    BRA   -
+
-   LDA.W $00,X
    STA.B [tile_pointer]
    INC.B tile_pointer
    INC.B tile_pointer
    INX   #2
    CPX.W #10
    BNE   -

    PLP
    RTL

.zero:
    LDA.W #'0'
    JSR   putchar

    PLP
    RTL


;;    GRAPHICS AND TILEMAP DATA

graphics_data: incbin !GRAPHICS_FILE
tilemap_data:  incbin !TILEMAP_FILE

; tilemap data is currently unused, decide if this should be changed

warnpc $C0FFB0-1  ; ensure codes does not clobber ROM header
