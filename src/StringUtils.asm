proc    stringLength, string
        xor     EAX, EAX
        mov     EBX, [string]
@@:
        cmp     byte[EBX], 0
        je      return_stringLength
        inc     EAX
        inc     EBX
        jmp     @B
return_stringLength:
        ret
endp