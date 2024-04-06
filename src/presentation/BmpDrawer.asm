        ; pixelString is null-terminated
proc    drawImage, stdoutHandle, image, pixelString
        mov     EDX, [image]
        push    EDX
        stdcall setConsoleSize, [stdoutHandle], [EDX + Image.width], [EDX + Image.height]
        pop     EDX

        xor     EAX, EAX
lineLoop:

        xor     EBX, EBX
columnLoop:
        pushad
        stdcall getPixel, [image], EBX, EAX
        stdcall convertPixel, EAX, ColorTable, (ColorTable_ - ColorTable) / 3
        invoke  setConsoleTextAttribute, [stdoutHandle], EAX
        stdcall stringLength, [pixelString]
        invoke  writeConsole, [stdoutHandle], [pixelString], EAX, NULL, NULL
        popad

        inc     EBX
        cmp     EBX, [EDX + Image.width]
        jb      columnLoop

        pushad
        stdcall addCrlfIfNeeded, [EDX + Image.width], [stdoutHandle]
        popad

        inc     EAX
        cmp     EAX, [EDX + Image.height]
        jb      lineLoop
        ret
endp


proc    addCrlfIfNeeded, imageWidth, stdoutHandle
        locals
                crlf    db      13, 10      
        endl

        mov     EAX, [imageWidth]
        mov     EBX, 2
        mul     EBX
        cmp     EAX, DEFAULT_CONSOLE_WIDTH_PIXELS
        jae     @F
        lea     EAX, [crlf]
        invoke  writeConsole, [stdoutHandle], EAX, 2, NULL, NULL
@@:
        ret
endp