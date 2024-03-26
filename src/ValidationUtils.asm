; proc    StringLength, string
;         xor     EAX, EAX
;         mov     EBX, [string]
; @@:
;         cmp     byte[EBX], 0
;         je      return
;         inc     EAX
;         inc     EBX
;         jmp     @B
; return:
;         ret
; endp