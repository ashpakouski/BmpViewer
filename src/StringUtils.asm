proc    StringLength, string
        xor     EAX, EAX
        mov     EBX, [string]
@@:
        cmp     byte[EBX], 0
        je      return_StringLength
        inc     EAX
        inc     EBX
        jmp     @B
return_StringLength:
        ret
endp