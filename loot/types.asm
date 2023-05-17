;  Bit layout of values
;
;  Type          ends in
;  - Integers:         0
;  - Pointers:        01
;  - Characters:     011
;  - True:         01111
;  - False:        11111
;  - Eof:         101111
;  - Void:        111111
;  - Empty:      1001111

!int_shift        #= 1
!int_type_mask    #= ((1<<!int_shift)-1)
!int_type_tag     #= (0<<(!int_shift-1))
!nonint_type_tag  #= (1<<(!int_shift-1))

!ptr_shift        #= (!int_shift+1)
!ptr_type_mask    #= ((1<<!ptr_shift)-1)
!ptr_type_tag     #= ((0<<(!ptr_shift-1))|!nonint_type_tag)
!nonptr_type_tag  #= ((1<<(!ptr_shift-1))|!nonint_type_tag)

!char_shift       #= (!ptr_shift+1)
!char_type_mask   #= ((1<<!char_shift)-1)
!char_type_tag    #= ((0<<(!char_shift-1))|!nonptr_type_tag)
!nonchar_type_tag #= ((1<<(!char_shift-1))|!nonptr_type_tag)

!val_true         #= ((0<<!char_shift)|!nonchar_type_tag)
!val_false        #= ((1<<!char_shift)|!nonchar_type_tag)
!val_eof          #= ((2<<!char_shift)|!nonchar_type_tag)
!val_void         #= ((3<<!char_shift)|!nonchar_type_tag)
!val_empty        #= ((4<<!char_shift)|!nonchar_type_tag)

; Pointer type indicators

!box_type_tag     #= 0
!cons_type_tag    #= 1
!vector_type_tag  #= 2
!string_type_tag  #= 3
!proc_type_tag    #= 4
