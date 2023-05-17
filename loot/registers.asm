;; Credit should be given to IsoFrieze (https://github.com/IsoFrieze) for
;; creating these definitions for all the hardware registers.

;--------------------;
; HARDWARE REGISTERS ;
;--------------------;

ORG $002100


; === $002100 ===
; 1 byte
; Screen brightness & F-blank control
; f---bbbb
; |   ++++ screen brightness
; +------- forced blanking when set
INIDISP: skip 1
; Valid values
!DISP_FBlank = %10000000
!DISP_NoBlank = %00001111

; === $002101 ===
; 1 byte
; Object size & object data location
; sssppbbb
; |||||+++ VRAM address where OBJ tile data is stored
; |||||    (bbb * w$2000) (upper bit redundant)
; |||++--- VRAM offset of second page of OBJ data
; |||      ((pp+1) * w$1000)
; +++----- OBJ size
OBJSEL: skip 1
; Valid values
!OBJ_Size_8_16 = %00000000
!OBJ_Size_8_32 = %00100000
!OBJ_Size_8_64 = %01000000
!OBJ_Size_16_32 = %01100000
!OBJ_Size_16_64 = %10000000
!OBJ_Size_32_64 = %10100000
!OBJ_Size_16R_32R = %11000000
!OBJ_Size_16R_32 = %11100000

; === $002102 ===
; 2 bytes
; Word address for OAM access
; OAM priority rotation flag
; p------aAAAAAAAa
; |      +++++++++ OAM word address
; |       +++++++- 7 bit OBJ index to set highest priority
; +--------------- Set to specify highest priority object
OAMADD: skip 2
; Valid values
!OAM_SetPriority = %10000000

; === $002104 ===
; 1 byte
; OAM data for write only
; WRITE TWICE
; 1st write = lower 8 bits of the data
; 2nd write = upper 8 bits of the data
OAMDATA: skip 1

; === $002105 ===
; 1 byte
; the background mode and layer character size settings
; 4321pmmm
; |||||+++ the background mode
; ||||+--- set if background layer 3 has high priority
; ++++---- set if background layer 1/2/3/4 has 16x16 characters, else 8x8
BGMODE: skip 1
; Valid values
!BG_Mode0 = %000
!BG_Mode1 = %001
!BG_Mode2 = %010
!BG_Mode3 = %011
!BG_Mode4 = %100
!BG_Mode5 = %101
!BG_Mode6 = %110
!BG_Mode7 = %111
!BG_BG3Pri = %1000

; === $002106 ===
; 1 byte
; enable mosaic effect and control its size
; ssss4321
; |||||||+ enable mosaic on BG1
; ||||||+- enable mosaic on BG2
; |||||+-- enable mosaic on BG3
; ||||+--- enable mosaic on BG4
; ++++---- size of mosaic blocks in pixels minus 1
MOSAIC: skip 1

; === $002107 ===
; 1 byte
; BG1 tilemap data location in VRAM, and background size
; aaaaaass
; ||||||++ BG1 size
; ++++++-- VRAM address where BG1 tilemap is stored
;          (aaaaaa * w$400) (upper bit redundant)
BG1SC: skip 1
; Valid values
!BGSC_Size_32x32 = %00000000
!BGSC_Size_64x32 = %00000001
!BGSC_Size_32x64 = %00000010
!BGSC_Size_64x64 = %00000011

; === $002108 ===
; 1 byte
; BG2 tilemap data location in VRAM, and background size
; aaaaaass
; ||||||++ BG2 size
; ++++++-- VRAM address where BG2 tilemap is stored
;          (aaaaaa * w$400) (upper bit redundant)
BG2SC: skip 1
; Valid values
!BGSC_Size_32x32 = %00000000
!BGSC_Size_64x32 = %00000001
!BGSC_Size_32x64 = %00000010
!BGSC_Size_64x64 = %00000011

; === $002109 ===
; 1 byte
; BG3 tilemap data location in VRAM, and background size
; aaaaaass
; ||||||++ BG3 size
; ++++++-- VRAM address where BG3 tilemap is stored
;          (aaaaaa * w$400) (upper bit redundant)
BG3SC: skip 1
; Valid values
!BGSC_Size_32x32 = %00000000
!BGSC_Size_64x32 = %00000001
!BGSC_Size_32x64 = %00000010
!BGSC_Size_64x64 = %00000011

; === $00210A ===
; 1 byte
; BG4 tilemap data location in VRAM, and background size
; aaaaaass
; ||||||++ BG4 size
; ++++++-- VRAM address where BG4 tilemap is stored
;          (aaaaaa * w$400) (upper bit redundant)
BG4SC: skip 1
; Valid values
!BGSC_Size_32x32 = %00000000
!BGSC_Size_64x32 = %00000001
!BGSC_Size_32x64 = %00000010
!BGSC_Size_64x64 = %00000011

; === $00210B ===
; 1 byte
; BG1 & BG2 character data location in VRAM
; 22221111
; ||||++++ Location of character data for BG1
; ||||     (1111 * w$1000) (upper bit redundant)
; ++++---- Location of character data for BG2
;          (2222 * w$1000) (upper bit redundant)
BG12NBA: skip 1

; === $00210C ===
; 1 byte
; BG3 & BG4 character data location in VRAM
; 44443333
; ||||++++ Location of character data for BG3
; ||||     (3333 * w$1000) (upper bit redundant)
; ++++---- Location of character data for BG4
;          (4444 * w$1000) (upper bit redundant)
BG34NBA: skip 1

; === $00210D ===
; 1 byte
; horizontal scroll value of BG1
; WRITE TWICE
; 1st write = lower 8 bits of the scroll value
; 2nd write = upper 2 (or upper 5) bits of the scroll value
BG1HOFS: skip 1

; === $00210E ===
; 1 byte
; vertical scroll value of BG1
; WRITE TWICE
; 1st write = lower 8 bits of the scroll value
; 2nd write = upper 2 (or upper 5) bits of the scroll value
BG1VOFS: skip 1

; === $00210F ===
; 1 byte
; horizontal scroll value of BG2
; WRITE TWICE
; 1st write = lower 8 bits of the scroll value
; 2nd write = upper 2 bits of the scroll value
BG2HOFS: skip 1

; === $002110 ===
; 1 byte
; vertical scroll value of BG2
; WRITE TWICE
; 1st write = lower 8 bits of the scroll value
; 2nd write = upper 2 bits of the scroll value
BG2VOFS: skip 1

; === $002111 ===
; 1 byte
; horizontal scroll value of BG3
; WRITE TWICE
; 1st write = lower 8 bits of the scroll value
; 2nd write = upper 2 bits of the scroll value
BG3HOFS: skip 1

; === $002112 ===
; 1 byte
; vertical scroll value of BG3
; WRITE TWICE
; 1st write = lower 8 bits of the scroll value
; 2nd write = upper 2 bits of the scroll value
BG3VOFS: skip 1

; === $002113 ===
; 1 byte
; horizontal scroll value of BG4
; WRITE TWICE
; 1st write = lower 8 bits of the scroll value
; 2nd write = upper 2 bits of the scroll value
BG4HOFS: skip 1

; === $002114 ===
; 1 byte
; vertical scroll value of BG4
; WRITE TWICE
; 1st write = lower 8 bits of the scroll value
; 2nd write = upper 2 bits of the scroll value
BG4VOFS: skip 1

; === $002115 ===
; 1 byte
; VRAM address increment options
; controls how VDADD changes as VRAM is accessed
; i---ggvv
; |   ||++ how much to increment by each access
; |   ||   (useful for tilemaps)
; |   ++-- address remapping
; |        (useful for character data)
; +------- 0 = increment on low byte access
;          1 = increment on high byte access
VMAINC: skip 1
; Valid values
!VINC_IncBy1 = %00000000
!VINC_IncBy32 = %00000001
!VINC_IncBy128 = %00000010
!VINC_IncBy8_32 = %00000100
!VINC_IncBy8_64 = %00001000
!VINC_IncBy8_128 = %00001100
!VINC_IncOnLo = %00000000
!VINC_IncOnHi = %10000000

; === $002116 ===
; 2 bytes
; Word address for VRAM access
VMADD: skip 2

; === $002118 ===
; 2 bytes
; VRAM data for write only
VMDATA: skip 2

; === $00211A ===
; 1 byte
; Background mode 7 display options
; ss----vh
; ||    |+ flip the screen horizontally
; ||    +- flip the screen vertically
; ++------ how to process tilemap out of bounds
M7SEL: skip 1
; Valid values
!M7SEL_Repeat = %00000000
!M7SEL_Color = %10000000
!M7SEL_Tile0 = %11000000

; === $00211B ===
; 1 byte
; A 16-bit value to be multiplied with 8-bit value in MPYB
; this multiplication is very fast since it uses the mode 7 hardware
; WRITE TWICE
; 1st write = lower 8 bits of the value
; 2nd write = upper 8 bits of the value
MPYA:

; === $00211B ===
; 1 byte
; the value of the A parameter for the mode 7 transformation matrix
; WRITE TWICE
; 1st write = lower 8 bits of the parameter value
; 2nd write = upper 8 bits of the parameter value
M7A: skip 1

; === $00211C ===
; 1 byte
; An 8-bit value to be multiplied with 16-bit value in MPYA
; this multiplication is very fast since it uses the mode 7 hardware
MPYB:

; === $00211C ===
; 1 byte
; the value of the B parameter for the mode 7 transformation matrix
; WRITE TWICE
; 1st write = lower 8 bits of the parameter value
; 2nd write = upper 8 bits of the parameter value
M7B: skip 1

; === $00211D ===
; 1 byte
; the value of the C parameter for the mode 7 transformation matrix
; WRITE TWICE
; 1st write = lower 8 bits of the parameter value
; 2nd write = upper 8 bits of the parameter value
M7C: skip 1

; === $00211E ===
; 1 byte
; the value of the D parameter for the mode 7 transformation matrix
; WRITE TWICE
; 1st write = lower 8 bits of the parameter value
; 2nd write = upper 8 bits of the parameter value
M7D: skip 1

; === $00211F ===
; 1 byte
; the horizontal co-ordinate of the mode 7 fixed point
; WRITE TWICE
; 1st write = lower 8 bits of the parameter value
; 2nd write = upper 5 bits of the parameter value
M7X: skip 1

; === $002120 ===
; 1 byte
; the vertical co-ordinate of the mode 7 fixed point
; WRITE TWICE
; 1st write = lower 8 bits of the parameter value
; 2nd write = upper 5 bits of the parameter value
M7Y: skip 1

; === $002121 ===
; 1 byte
; Word address for CGRAM access
CGADD: skip 1

; === $002122 ===
; 1 byte
; CGRAM data for write only
; WRITE TWICE
; 1st write = lower 8 bits of the data
; 2nd write = upper 7 bits of the data
CGDATA: skip 1

; === $002123 ===
; 1 byte
; window selection settings for BG1 and BG2
; 2i1i2i1i
; |||||||+ BG1, in/out bit for window 1
; ||||||+- BG1, enable bit for window 1
; |||||+-- BG1, in/out bit for window 2
; ||||+--- BG1, enable bit for window 2
; |||+---- BG2, in/out bit for window 1
; ||+----- BG2, enable bit for window 1
; |+------ BG2, in/out bit for window 2
; +------- BG2, enable bit for window 2
W12SEL: skip 1
; Valid values
!WSEL_BG1_W1_IO = %00000001
!WSEL_BG1_W1_En = %00000010
!WSEL_BG1_W2_IO = %00000100
!WSEL_BG1_W2_En = %00001000
!WSEL_BG2_W1_IO = %00010000
!WSEL_BG2_W1_En = %00100000
!WSEL_BG2_W2_IO = %01000000
!WSEL_BG2_W2_En = %10000000

; === $002124 ===
; 1 byte
; window selection settings for BG3 and BG4
; 2i1i2i1i
; |||||||+ BG3, in/out bit for window 1
; ||||||+- BG3, enable bit for window 1
; |||||+-- BG3, in/out bit for window 2
; ||||+--- BG3, enable bit for window 2
; |||+---- BG4, in/out bit for window 1
; ||+----- BG4, enable bit for window 1
; |+------ BG4, in/out bit for window 2
; +------- BG4, enable bit for window 2
W34SEL: skip 1
; Valid values
!WSEL_BG3_W1_IO = %00000001
!WSEL_BG3_W1_En = %00000010
!WSEL_BG3_W2_IO = %00000100
!WSEL_BG3_W2_En = %00001000
!WSEL_BG4_W1_IO = %00010000
!WSEL_BG4_W1_En = %00100000
!WSEL_BG4_W2_IO = %01000000
!WSEL_BG4_W2_En = %10000000

; === $002125 ===
; 1 byte
; window selection settings for OBJ and color window
; 2i1i2i1i
; |||||||+ OBJ, in/out bit for window 1
; ||||||+- OBJ, enable bit for window 1
; |||||+-- OBJ, in/out bit for window 2
; ||||+--- OBJ, enable bit for window 2
; |||+---- color window, in/out bit for window 1
; ||+----- color window, enable bit for window 1
; |+------ color window, in/out bit for window 2
; +------- color window, enable bit for window 2
WOBJSEL: skip 1
; Valid values
!WSEL_OBJ_W1_IO = %00000001
!WSEL_OBJ_W1_En = %00000010
!WSEL_OBJ_W2_IO = %00000100
!WSEL_OBJ_W2_En = %00001000
!WSEL_Color_W1_IO = %00010000
!WSEL_Color_W1_En = %00100000
!WSEL_Color_W2_IO = %01000000
!WSEL_Color_W2_En = %10000000

; === $002126 ===
; 1 byte
; horizontal position of the left side of window 1
WH0: skip 1

; === $002127 ===
; 1 byte
; horizontal position of the right side of window 1
WH1: skip 1

; === $002128 ===
; 1 byte
; horizontal position of the left side of window 2
WH2: skip 1

; === $002129 ===
; 1 byte
; horizontal position of the right side of window 2
WH3: skip 1

; === $00212A ===
; 1 byte
; window intersection logic for BG1, BG2, BG3, BG4
; 44332211
; ||||||++ intersection logic for BG1
; ||||++-- intersection logic for BG2
; ||++---- intersection logic for BG3
; ++------ intersection logic for BG4
WBGLOG: skip 1
; Valid values
!WLOG_OR = %00
!WLOG_AND = %01
!WLOG_XOR = %10
!WLOG_XNOR = %11

; === $00212B ===
; 1 byte
; window intersection logic for OBJ and color window
; ----ccoo
;     ||++ intersection logic for OBJ
;     ++-- intersection logic for color window
WOBJLOG: skip 1
; Valid values
!WLOG_OR = %00
!WLOG_AND = %01
!WLOG_XOR = %10
!WLOG_XNOR = %11

; === $00212C ===
; 1 byte
; background layers to enable on the main screen
; ----o4321
;     ||||+ enable BG1
;     |||+- enable BG2
;     ||+-- enable BG3
;     |+--- enable BG4
;     +---- enable OBJ
TM: skip 1
; Valid values
!Through_None = %00000
!Through_BG1 = %00001
!Through_BG2 = %00010
!Through_BG3 = %00100
!Through_BG4 = %01000
!Through_OBJ = %10000

; === $00212D ===
; 1 byte
; background layers to enable on the sub screen
; ----o4321
;     ||||+ enable BG1
;     |||+- enable BG2
;     ||+-- enable BG3
;     |+--- enable BG4
;     +---- enable OBJ
TS: skip 1
; Valid values
!Through_None = %00000
!Through_BG1 = %00001
!Through_BG2 = %00010
!Through_BG3 = %00100
!Through_BG4 = %01000
!Through_OBJ = %10000

; === $00212E ===
; 1 byte
; background layers to enable on the main screen window
; ----o4321
;     ||||+ enable BG1
;     |||+- enable BG2
;     ||+-- enable BG3
;     |+--- enable BG4
;     +---- enable OBJ
TMW: skip 1
; Valid values
!Through_None = %00000
!Through_BG1 = %00001
!Through_BG2 = %00010
!Through_BG3 = %00100
!Through_BG4 = %01000
!Through_OBJ = %10000

; === $00212F ===
; 1 byte
; background layers to enable on the sub screen window
; ----o4321
;     ||||+ enable BG1
;     |||+- enable BG2
;     ||+-- enable BG3
;     |+--- enable BG4
;     +---- enable OBJ
TSW: skip 1
; Valid values
!Through_None = %00000
!Through_BG1 = %00001
!Through_BG2 = %00010
!Through_BG3 = %00100
!Through_BG4 = %01000
!Through_OBJ = %10000

; === $002130 ===
; 1 byte
; color math enable and selection switch
; mmss--fd
; ||||  |+ set if direct color is enabled
; ||||  +- set for color math between subscreens, clear for fixed color math
; ||++---- color window sub screen
; ++------ color window main screen
CGSWSEL: skip 1
; Valid values
!CGSW_DirectColor = %00000001
!CGSW_FixedColor = %00000010
!CGSW_CW_On = %00
!CGSW_CW_In = %01
!CGSW_CW_Out = %10
!CGSW_CW_Off = %11

; === $002131 ===
; 1 byte
; color math settings
; shbo4321
; ||++++++ set if BG1/BG2/BG3/BG4/OBJ/back color should participate in color math
; |+------ set if color math result should be halved (e.g. average)
; +------- set if subtract subscreens, else add
CGADSUB: skip 1
; Valid values
!CMath_BG1 = %00000001
!CMath_BG2 = %00000010
!CMath_BG3 = %00000100
!CMath_BG4 = %00001000
!CMath_OBJ = %00010000
!CMath_Back = %00100000
!CMath_Half = %01000000
!CMath_Sub = %10000000

; === $002132 ===
; 1 byte
; the constant fixed color
; bgrvvvvv
; |||+++++ the value of the color component
; ||+----- write the value to the red component
; |+------ write the value to the green component
; +------- write the value to the blue component
COLDATA: skip 1
; Valid values
!COL_Red = %00100000
!COL_Green = %01000000
!COL_Blue = %10000000

; === $002133 ===
; 1 byte
; various technical screen options
; sx--hovi
; ||  |||+ enable interlace mode
; ||  ||+- interlace OBJ
; ||  |+-- enable overscan
; ||  +--- enable pseudo h512 mode
; |+------ external background via mode 7
; +------- external synchronization (not used)
SETINI: skip 1
; Valid values
!INI_Interlace = %00000001
!INI_ObjVert = %00000010
!INI_Overscan = %00000100
!INI_PseudoH512 = %00001000
!INI_ExtBG = %01000000
!INI_ExtSync = %10000000

; === $002134 ===
; 3 bytes
; The 24-bit product of multiplication via MPYA and MPYB
; this multiplication is very fast since it uses the mode 7 hardware
MPY: skip 3

; === $002137 ===
; 1 byte
; Register to latch the horizontal and vertical counter
; values OPHCT & OPVCT via software
; No data is read
SLHV: skip 1

; === $002138 ===
; 1 byte
; OAM data for read only
; READ TWICE
; 1st read = lower 8 bits of the data
; 2nd read = upper 8 bits of the data
ROAMDATA: skip 1

; === $002139 ===
; 2 bytes
; VRAM data for read only
RVMDATA: skip 2

; === $00213B ===
; 1 byte
; CGRAM data for read only
; READ TWICE
; 1st read = lower 8 bits of the data
; 2nd read = upper 7 bits of the data
RCGDATA: skip 1

; === $00213C ===
; 1 byte
; horizontal counter value
; latched via software at SLHV, or via hardware port 2 programmable I/O
; READ TWICE
; 1st read = lower 8 bits of the data
; 2nd read = upper 1 bit of the data
OPHCT: skip 1

; === $00213D ===
; 1 byte
; vertical counter value
; latched via software at SLHV, or via hardware port 2 programmable I/O
; READ TWICE
; 1st read = lower 8 bits of the data
; 2nd read = upper 1 bit of the data
OPVCT: skip 1

; === $00213E ===
; 1 byte
; PPU status and version number
; trp-vvvv
; ||| ++++ version number of 5C77 PPU chip
; ||+----- PPU primary/secondary flag
; |+------ set if more than 32 OBJ on one line
; +------- set if more than 34 8x8 OBJ pieces on one line
STAT77: skip 1

; === $00213F ===
; 1 byte
; PPU status and version number
; read this register to clear latch flag and reset OPHCT/OPVCT flip flops
; fl-rvvvv
; || |++++ version number of 5C78 PPU chip
; || +---- region (0=NTSC, 1=PAL)
; |+------ external latch activated flag (OPVCT/OPHCT)
; +------- parity of interlace field
STAT78: skip 1

; === $002140 ===
; 1 byte
; SPC700 I/O port 0
; Communicates with ARAM address $00F4
APUIO0: skip 1

; === $002141 ===
; 1 byte
; SPC700 I/O port 1
; Communicates with ARAM address $00F5
APUIO1: skip 1

; === $002142 ===
; 1 byte
; SPC700 I/O port 2
; Communicates with ARAM address $00F6
APUIO2: skip 1

; === $002143 ===
; 1 byte
; SPC700 I/O port 3
; Communicates with ARAM address $00F7
APUIO3: skip 1

ORG $002180


; === $002180 ===
; 1 byte
; WRAM data for read or write
WMDATA: skip 1

; === $002181 ===
; 3 bytes
; 17-bit address for WRAM access
WMADD: skip 3

ORG $004016


; === $004016 ===
; 1 byte
; Legacy controller port 1 I/O
; READ
; ------ba
;       |+ Controller port 1, Data1 line (player 1)
;       +- Controller port 1, Data2 line (player 3)
; WRITE
; -------s
;        + Strobe both controller ports, latching Data1 and Data2
JOY1: skip 1

; === $004017 ===
; 1 byte
; Legacy controller port 2 I/O
; ------ba
;       |+ Controller port 2, Data1 line (player 2)
;       +- Controller port 2, Data2 line (player 4)
JOY2: skip 1

ORG $004200

; === $004200 ===
; 1 byte
; special timer enable switches
; n-vh---c
; | ||   + Enable standard joypad read
; | |+---- Enable IRQ horizontal timer
; | +----- Enable IRQ vertical timer
; +------- Enable NMI interrupt
NMITIMEN: skip 1
; Valid values
!TIMEN_JoyRead = %00000001
!TIMEN_IRQH = %00010000
!TIMEN_IRQV = %00100000
!TIMEN_IRQHV = %00110000
!TIMEN_NMI = %10000000

; === $004201 ===
; 1 byte
; used to write to the programmable I/O lines
; ba------
; |+------ Controller port 1 programmable I/O
; +------- Controller port 2 programmable I/O
;          Also connected to external latch
WRIO: skip 1

; === $004202 ===
; 1 byte
; An 8-bit value to be multiplied with 8-bit value in WRMPYB
WRMPYA: skip 1

; === $004203 ===
; 1 byte
; An 8-bit value to be multiplied with 8-bit value in WRMPYA
; After writing, 16-bit product will be available in RDMPY after 8 cycles
WRMPYB: skip 1

; === $004204 ===
; 2 bytes
; A 16-bit value to be divided by 8-bit value in WRDIVB
WRDIV: skip 2

; === $004206 ===
; 1 byte
; An 8-bit value to divide 16-bit value in WRDIVA by
; After writing, 16-bit quotient will be available in RDDIV
; and 16-bit remainder will be available in RDMPY after 16 cycles
WRDIVB: skip 1

; === $004207 ===
; 2 bytes
; horizontal timer value for IRQ interrupt
HTIME: skip 2

; === $004209 ===
; 2 bytes
; vertical timer value for IRQ interrupt
VTIME: skip 2

; === $00420B ===
; 1 byte
; Enable DMA on each of the 8 DMA channels
MDMAEN: skip 1
; Valid values
!Ch0 = %00000001
!Ch1 = %00000010
!Ch2 = %00000100
!Ch3 = %00001000
!Ch4 = %00010000
!Ch5 = %00100000
!Ch6 = %01000000
!Ch7 = %10000000

; === $00420C ===
; 1 byte
; Enable HDMA on each of the 8 DMA channels
HDMAEN: skip 1
; Valid values
!Ch0 = %00000001
!Ch1 = %00000010
!Ch2 = %00000100
!Ch3 = %00001000
!Ch4 = %00010000
!Ch5 = %00100000
!Ch6 = %01000000
!Ch7 = %10000000

; === $00420D ===
; 1 byte
; High speed switch for FastROM
; -------s
;        + 0 = 2.68MHz, 1 = 3.58MHz
MEMSEL: skip 1

ORG $004210

; === $004210 ===
; 1 byte
; NMI status and CPU version number
; this register must be read during V-blank
; n---vvvv
; |   ++++ CPU version number
; +------- NMI has occurred flag
RDNMI: skip 1

; === $004211 ===
; 1 byte
; IRQ status
; this register must be read during IRQ
; t-------
; +------- IRQ has occurred flag
TIMEUP: skip 1

; === $004212 ===
; 1 byte
; blanking and joypad autoread statuses
; vh-----c
; ||     + joypad autoread is occurring flag
; |+------ H-blank is occurring flag
; +------- V-blank is occurring flag
HVBJOY: skip 1

; === $004213 ===
; 1 byte
; used to read from the programmable I/O lines
; ba------
; |+------ Controller port 1 programmable I/O
; +------- Controller port 2 programmable I/O
;          Also connected to external latch
RDIO: skip 1

; === $004214 ===
; 2 bytes
; 16-bit quotient result from WRDIV and WRDIVB
RDDIV: skip 2

; === $004216 ===
; 2 bytes
; 16-bit product result from WRMPYA and WRMPYB
; 16-bit remainder result from WRDIV and WRDIVB
RDMPY: skip 2

; === $004218 ===
; 2 bytes
; controller data for player 1 (port 1, Data1)
; byetudlraxLRxxxx
; ||||||||||||++++ controller signature
; ||||||||||++---- L and R shoulder buttons
; ||||||||++------ A and X face buttons
; ||||++++-------- up, down, left, and right on dpad
; ||++------------ select and start face buttons
; ++-------------- B and Y face buttons
CNTRL1: skip 2

; === $00421A ===
; 2 bytes
; controller data for player 2 (port 2, Data1)
; byetudlraxLRxxxx
; ||||||||||||++++ controller signature
; ||||||||||++---- L and R shoulder buttons
; ||||||||++------ A and X face buttons
; ||||++++-------- up, down, left, and right on dpad
; ||++------------ select and start face buttons
; ++-------------- B and Y face buttons
CNTRL2: skip 2

; === $00421C ===
; 2 bytes
; controller data for player 3 (port 1, Data2)
; byetudlraxLRxxxx
; ||||||||||||++++ controller signature
; ||||||||||++---- L and R shoulder buttons
; ||||||||++------ A and X face buttons
; ||||++++-------- up, down, left, and right on dpad
; ||++------------ select and start face buttons
; ++-------------- B and Y face buttons
CNTRL3: skip 2

; === $00421E ===
; 2 bytes
; controller data for player 2 (port 2, Data1)
; byetudlraxLRxxxx
; ||||||||||||++++ controller signature
; ||||||||||++---- L and R shoulder buttons
; ||||||||++------ A and X face buttons
; ||||++++-------- up, down, left, and right on dpad
; ||++------------ select and start face buttons
; ++-------------- B and Y face buttons
CNTRL4: skip 2

ORG $004300

; === $004300 ===
; 1 byte
; DMA transfer parameters
; bi-ffmmm
; || ||+++ number of bytes to transfer where
; || ++--- how much to inc/dec A bus address
; |+------ use indirect addressing for HDMA
; +------- direction of transfer (0=A->B, 1=B->A)
DMAPARAM: skip 1
; Valid values
!DMA_1Byte1Addr = %000
!DMA_2Byte2Addr = %001
!DMA_2Byte1Addr = %010
!DMA_4Byte2Addr = %011
!DMA_4Byte4Addr = %100
!DMA_ABusInc = %00000
!DMA_ABusDec = %10000
!DMA_ABusFix = %01000
!DMA_HDMAIndirect = %01000000
!DMA_AtoB = %00000000
!DMA_BtoA = %10000000

; === $004301 ===
; 1 byte
; the register on the B bus to transfer to/from ($0021xx)
DMAREG: skip 1

; === $004302 ===
; 3 bytes
; the 24-bit address on the A bus to transfer from/to
DMAADDR: skip 3

; === $004305 ===
; 2 bytes
; DMA
; the number of bytes to transfer (0 means $10000)
; HDMA
; the effective address of indirect address HDMA table
; (written automatically during transfer)
DMACNT: skip 2

; === $004307 ===
; 1 byte
; the bank of the effective address of indirect address HDMA table
HDMABANK: skip 1

; === $004308 ===
; 2 bytes
; the intermediate address of an HDMA transfer
; (written automatically during transfer)
DMAIDX: skip 2

; === $00430A ===
; 1 byte
; number of lines taken from HDMA table
; (written automatically during transfer)
HDMALINES: skip 1
