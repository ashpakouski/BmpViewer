proc    fillBmpParams, image
        locals
                bytesPtr    dd      ?
        endl

        mov     EAX, [image]
        mov     EAX, [EAX + Image.bytesPtr]
        mov     [bytesPtr], EAX

        mov     EBX, [image] ; Functions below don't modify EBX

        stdcall getBmpOffset, [bytesPtr]
        mov     [EBX + Image.offset], EAX
        
        stdcall getBmpWidth, [bytesPtr]
        mov     [EBX + Image.width], EAX

        stdcall getBmpHeight, [bytesPtr]
        mov     [EBX + Image.height], EAX
        ret
endp


proc    getBmpOffset, bmpBytes
        stdcall getBmpParam, [bmpBytes], 0x0A
        ret
endp


proc    getBmpWidth, bmpBytes
        stdcall getBmpParam, [bmpBytes], 0x12
        ret
endp


proc    getBmpHeight, bmpBytes
        stdcall getBmpParam, [bmpBytes], 0x16
        ret
endp


proc    getBmpParam, bmpBytes, paramOffset
        mov     EAX, [bmpBytes]
        add     EAX, [paramOffset]
        mov     EAX, [EAX]
        ret
endp


        ; Result: xx BB RR GG
        ;                  ^^ AL
proc    getPixel, image, pixelX, pixelY
        mov     ECX, [image]

        mov     EAX, [ECX + Image.height]
        dec     EAX
        sub     EAX, [pixelY]
        mul     [ECX + Image.width]
        add     EAX, [pixelX]
        mov     EBX, 3
        mul     EBX
        add     EAX, [ECX + Image.offset]
        add     EAX, [ECX + Image.bytesPtr]
        mov     EAX, [EAX] ; FIXME: Access violation?
        ret
endp


        ; Function returns index of corresponding color in provided color table.
        ; Color table has to be filled as array of BRG entries (1 byte per component)
proc    convertPixel, pixel, colorTable, tableSize
        locals
                b           db      ?
                g           db      ?
                r           db      ?
                minSum      dd      0xEFFFFFFF
                minColorId  dd      ?
                currentSum  dd      ?
        endl

        mov     EAX, [pixel]
        mov     [b], AL
        shr     EAX, 8
        mov     [g], AL
        shr     EAX, 8
        mov     [r], AL

        mov     ECX, 0
tableLoop:
        mov     EAX, 3
        mul     ECX
        add     EAX, [colorTable]
        mov     EBX, EAX

        mov     [currentSum], 0

        movzx   EAX, [b]
        movzx   EDX, byte[EBX]
        sub     EAX, EDX
        mul     EAX
        add     [currentSum], EAX
        inc     EBX

        movzx   EAX, [g]
        movzx   EDX, byte[EBX]
        sub     EAX, EDX
        mul     EAX
        add     [currentSum], EAX
        inc     EBX

        movzx   EAX, [r]
        movzx   EDX, byte[EBX]
        sub     EAX, EDX
        mul     EAX
        add     [currentSum], EAX

        mov     EAX, [currentSum]
        cmp     EAX, [minSum]
        jae     @F
        mov     [minSum], EAX
        mov     [minColorId], ECX
@@:

        inc     ECX
        cmp     ECX, [tableSize]
        jb      tableLoop

        mov     EAX, [minColorId]
        ret
endp