#lang racket

(provide (all-defined-out))

(define (seq . xs)
  (foldr (λ (x xs) (if (list? x) (append x xs) (cons x xs))) '() xs))

;; ASSEMBLER THINGS
(struct Label (lbl) #:prefab)
(struct Comment (str) #:prefab)
(struct Org (add) #:prefab)
(struct Pushpc () #:prefab)
(struct Pullpc () #:prefab)
(struct Data8 (data) #:prefab)
;; INSTRUCTIONS
(struct Adc (x) #:prefab)
(struct Sbc (x) #:prefab)
(struct Cmp (x) #:prefab)
(struct Cpx (x) #:prefab)
(struct Cpy (x) #:prefab)
(struct Dec (x) #:prefab)
(struct Dex (x) #:prefab) ;count only
(struct Dey (x) #:prefab) ;count only
(struct Inc (x) #:prefab)
(struct Inx (x) #:prefab) ;count only
(struct Iny (x) #:prefab) ;count only
(struct And (x) #:prefab)
(struct Eor (x) #:prefab)
(struct Ora (x) #:prefab)
(struct Bit (x) #:prefab)
(struct Trb (x) #:prefab)
(struct Tsb (x) #:prefab)
(struct Asl (x) #:prefab)
(struct Lsr (x) #:prefab)
(struct Rol (x) #:prefab)
(struct Ror (x) #:prefab)
(struct Bcc (x) #:prefab) ;string label
(struct Bcs (x) #:prefab) ;string label
(struct Beq (x) #:prefab) ;string label
(struct Bmi (x) #:prefab) ;string label
(struct Bne (x) #:prefab) ;string label
(struct Bpl (x) #:prefab) ;string label
(struct Bra (x) #:prefab) ;string label
(struct Bvc (x) #:prefab) ;string label
(struct Bvs (x) #:prefab) ;string label
(struct Brl (x) #:prefab) ;string label
(struct Jmp (x) #:prefab) ;string label
(struct Jsl (x) #:prefab) ;string label
(struct Jsr (x) #:prefab) ;string label
(struct Rts () #:prefab)
(struct Rtl () #:prefab)
(struct Brk () #:prefab)
(struct Cop (x) #:prefab) ;imm8 only
(struct Rti () #:prefab)
(struct Clc () #:prefab)
(struct Cld () #:prefab)
(struct Cli () #:prefab)
(struct Clv () #:prefab)
(struct Sec () #:prefab)
(struct Sed () #:prefab)
(struct Sei () #:prefab)
(struct Rep (x) #:prefab) ;imm8 only
(struct Sep (x) #:prefab) ;imm8 only
(struct Lda (x) #:prefab)
(struct Ldx (x) #:prefab)
(struct Ldy (x) #:prefab)
(struct Sta (x) #:prefab)
(struct Stx (x) #:prefab)
(struct Sty (x) #:prefab)
(struct Stz (x) #:prefab)
(struct Mvn (x) #:prefab)
(struct Mvp (x) #:prefab)
(struct Nop (x) #:prefab) ;count only
(struct Wdm (x) #:prefab) ;illegal instruction
(struct Pea (x) #:prefab)
(struct Pei (x) #:prefab)
(struct Per (x) #:prefab)
(struct Pha () #:prefab)
(struct Phx () #:prefab)
(struct Phy () #:prefab)
(struct Pla () #:prefab)
(struct Plx () #:prefab)
(struct Ply () #:prefab)
(struct Phb () #:prefab)
(struct Phd () #:prefab)
(struct Phk () #:prefab)
(struct Php () #:prefab)
(struct Plb () #:prefab)
(struct Pld () #:prefab)
(struct Plp () #:prefab)
(struct Stp () #:prefab)
(struct Wai () #:prefab)
(struct Tax () #:prefab)
(struct Tay () #:prefab)
(struct Tsx () #:prefab)
(struct Txa () #:prefab)
(struct Txs () #:prefab)
(struct Txy () #:prefab)
(struct Tya () #:prefab)
(struct Tyx () #:prefab)
(struct Tcd () #:prefab)
(struct Tcs () #:prefab)
(struct Tdc () #:prefab)
(struct Tsc () #:prefab)
(struct Xba () #:prefab)
(struct Xce () #:prefab)

(define (instr->string ins)
  (match ins
    [(Org a) (string-append "ORG " a)]
    [(Pushpc) "pushpc"]
    [(Pullpc) "pullpc"]
    [(Label l) (string-append (~a l) ":")]
    [(Comment s) (string-append ";" s)]
    [(Data8 s) (string-append "    db " (addr-mode->string s))]
    [(Adc x) (string-append "    ADC" (addr-mode->string x))]
    [(Sbc x) (string-append "    SBC" (addr-mode->string x))]
    [(Cmp x) (string-append "    CMP" (addr-mode->string x))]
    [(Cpx x) (string-append "    CPX" (addr-mode->string x))]
    [(Cpy x) (string-append "    CPY" (addr-mode->string x))]
    [(Dec x) (string-append "    DEC" (addr-mode->string x))]
    [(Dex (Acc c)) (string-append "    DEX" (addr-mode->string (Acc c)))]
    [(Dey (Acc c)) (string-append "    DEY" (addr-mode->string (Acc c)))]
    [(Inc x) (string-append "    INC" (addr-mode->string x))]
    [(Inx (Acc c)) (string-append "    INX" (addr-mode->string (Acc c)))]
    [(Iny (Acc c)) (string-append "    INY" (addr-mode->string (Acc c)))]
    [(And x) (string-append "    AND" (addr-mode->string x))]
    [(Eor x) (string-append "    EOR" (addr-mode->string x))]
    [(Ora x) (string-append "    ORA" (addr-mode->string x))]
    [(Bit x) (string-append "    BIT" (addr-mode->string x))]
    [(Trb x) (string-append "    TRB" (addr-mode->string x))]
    [(Tsb x) (string-append "    TSB" (addr-mode->string x))]
    [(Asl x) (string-append "    ASL" (addr-mode->string x))]
    [(Lsr x) (string-append "    LSR" (addr-mode->string x))]
    [(Rol x) (string-append "    ROL" (addr-mode->string x))]
    [(Ror x) (string-append "    ROR" (addr-mode->string x))]
    [(Bcc l) (string-append "    BCC   " (~a l))]
    [(Bcs l) (string-append "    BCS   " (~a l))]
    [(Beq l) (string-append "    BEQ   " (~a l))]
    [(Bmi l) (string-append "    BMI   " (~a l))]
    [(Bne l) (string-append "    BNE   " (~a l))]
    [(Bpl l) (string-append "    BPL   " (~a l))]
    [(Bra l) (string-append "    BRA   " (~a l))]
    [(Bvc l) (string-append "    BVC   " (~a l))]
    [(Bvs l) (string-append "    BVS   " (~a l))]
    [(Brl l) (string-append "    BRL   " (~a l))]
    [(Jmp l) (string-append "    JMP   " (~a l))]
    [(Jsl l) (string-append "    JSL   " (~a l))]
    [(Jsr l) (string-append "    JSR   " (~a l))]
    [(Rts) "    RTS"]
    [(Rtl) "    RTL"]
    [(Brk) "    BRK"]
    [(Cop (Imm8 i)) (string-append "    COP" (addr-mode->string (Imm8 i)))]
    [(Rti) "    RTI"]
    [(Clc) "    CLC"]
    [(Cld) "    CLD"]
    [(Cli) "    CLI"]
    [(Clv) "    CLV"]
    [(Sec) "    SEC"]
    [(Sed) "    SED"]
    [(Sei) "    SEI"]
    [(Rep (Imm8 i)) (string-append "    REP" (addr-mode->string (Imm8 i)))]
    [(Sep (Imm8 i)) (string-append "    SEP" (addr-mode->string (Imm8 i)))]
    [(Lda x) (string-append "    LDA" (addr-mode->string x))]
    [(Ldx x) (string-append "    LDX" (addr-mode->string x))]
    [(Ldy x) (string-append "    LDY" (addr-mode->string x))]
    [(Sta x) (string-append "    STA" (addr-mode->string x))]
    [(Stx x) (string-append "    STX" (addr-mode->string x))]
    [(Sty x) (string-append "    STY" (addr-mode->string x))]
    [(Stz x) (string-append "    STZ" (addr-mode->string x))]
    [(Mvn (Mov d s)) (string-append "    MVN" (addr-mode->string (Mov d s)))]
    [(Mvp (Mov d s)) (string-append "    MVP" (addr-mode->string (Mov d s)))]
    [(Nop (Acc c)) (string-append "    NOP" (addr-mode->string (Acc c)))]
    [(Wdm x) (string-append "    WDM" (addr-mode->string x))]
    [(Pea x) (string-append "    PEA" (addr-mode->string x))]
    [(Pei x) (string-append "    PEI" (addr-mode->string x))]
    [(Per x) (string-append "    PER" (addr-mode->string x))]
    [(Pha) "    PHA"]
    [(Phx) "    PHX"]
    [(Phy) "    PHY"]
    [(Pla) "    PLA"]
    [(Plx) "    PLX"]
    [(Ply) "    PLY"]
    [(Phb) "    PHB"]
    [(Phd) "    PHD"]
    [(Phk) "    PHK"]
    [(Php) "    PHP"]
    [(Plb) "    PLB"]
    [(Pld) "    PLD"]
    [(Plp) "    PLP"]
    [(Stp) "    STP"]
    [(Wai) "    WAI"]
    [(Tax) "    TAX"]
    [(Tay) "    TAY"]
    [(Tsx) "    TSX"]
    [(Txa) "    TXA"]
    [(Txs) "    TXS"]
    [(Txy) "    TXY"]
    [(Tya) "    TYA"]
    [(Tyx) "    TYX"]
    [(Tcd) "    TCD"]
    [(Tcs) "    TCS"]
    [(Tdc) "    TDC"]
    [(Tsc) "    TSC"]
    [(Xba) "    XBA"]
    [(Xce) "    XCE"]))

;; ADDRESSING MODES
; Note: not all instructions support all the addressing modes (nor do all these
; structs cover all the addressing modes). The assembler will shout at you when
; you try to use an instruction with an unsupported addressing mode. We're not
; gonna check that; it's your fault.
(struct Imm (num) #:prefab) ; like #$1234
(struct Imm8 (num) #:prefab) ; like #$12  (used only for certain instructions)
(struct Abs (addr) #:prefab) ; like $1234
(struct AbsX (addr) #:prefab) ; like $1234,X
(struct AbsY (addr) #:prefab) ; like $1234,Y
(struct AbsInd (addr)) ; like [$1234]
(struct AbsInd16 (addr)) ; like ($1234)
(struct Zp (addr) #:prefab) ; like $12
(struct ZpX (addr) #:prefab) ; like $12,X
(struct ZpY (addr) #:prefab) ; like $12,Y
(struct ZpInd (addr)) ; like [$12]
(struct ZpIndY (addr)) ;like [$12],Y
(struct Acc (count) #:prefab) ; for special instructions like LSR #4
(struct Long (addr) #:prefab) ; like $123456
(struct LongX (addr) #:prefab) ; like $123456,X
(struct Stk (offset) #:prefab) ; like $12,S
(struct Mov (src dest) #:prefab) ; like $12,$34
(struct Quote (str) #:prefab)

(define (addr-mode->string mode)
  (match mode
    [(Imm n) (string-append ".W #" (~a n))]
    [(Imm8 n) (string-append "   #" (~a n))]
    [(Abs a) (string-append ".W " (~a a))]
    [(AbsX a) (string-append ".W " (~a a) ",X")]
    [(AbsY a) (string-append ".W " (~a a) ",Y")]
    [(AbsInd a) (string-append ".W [" (~a a) "]")]
    [(AbsInd16 a) (string-append ".W (" (~a a) ")")]
    [(Zp a) (string-append ".B " (~a a))]
    [(ZpX a) (string-append ".B " (~a a) ",X")]
    [(ZpY a) (string-append ".B " (~a a) ",Y")]
    [(ZpInd a) (string-append ".B [" (~a a) "]")]
    [(ZpIndY a) (string-append ".B [" (~a a) "],Y")]
    [(Long a) (string-append ".L " (~a a))]
    [(LongX a) (string-append ".L " (~a a) ",X")]
    [(Acc c) (string-append "   #" (~a c))]
    [(Stk s) (string-append ".B " (~a s) ",S")]
    [(Mov d s) (string-append "   " (~a d) "," (~a s))]
    [(Quote s) (string-append "\"" (string-escape s) "\"")]
    [(Label l) (string-append "   " (~a l))]
    [n (~a n)])) ;dangerous wildcard

(define (comp->string lst)
  (foldr (lambda (ins rst) (string-append (instr->string ins) "\n" rst))
         ""
         lst))

(define (printer lst)
  (display (comp->string lst)))

(define (string-escape s)
  (string-replace (string-replace (string-replace (~a s) "\"" "\"\"") "!" "\\!")
                  "\n"
                  "\\n"))
