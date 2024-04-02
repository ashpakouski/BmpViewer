proc    getFirstLaunchArgument
        locals
                pLaunchArgs  dd  ?  
                pFirstArg    dd  ?
        endl

        invoke  getCommandLine
        mov     [pLaunchArgs], EAX
        invoke  pathGetArgs, EAX
        mov     [pFirstArg], EAX
        stdcall stringLength, [pLaunchArgs]
        add     EAX, [pLaunchArgs]
        cmp     EAX, [pFirstArg]
        jne     @F
        mov     EAX, NULL
        jmp     return_getFirstLaunchArgument
@@:
        mov     EAX, [pFirstArg]
return_getFirstLaunchArgument:
        ret
endp



proc    setConsoleSize, stdoutHandle, width, height
        locals
                windowSize  dw      4 dup ?     ; https://learn.microsoft.com/en-us/windows/console/small-rect-str
                bufferSize  dw      2 dup ?     ; https://learn.microsoft.com/en-us/windows/console/coord-str
        endl

        xor     EAX, EAX
        mov     dword[windowSize], EAX ; Fills 4 bytes
        mov     EAX, [width]
        mov     EBX, 2
        mul     EBX
        mov     [bufferSize], AX
        dec     EAX
        mov     [windowSize + 4], AX

        mov     EAX, [height]
        mov     [bufferSize + 2], AX
        dec     EAX
        mov     [windowSize + 6], AX

        lea     EAX, [windowSize]
        invoke  setConsoleWindowInfo, [stdoutHandle], 1, EAX
        lea     EAX, [bufferSize]
        invoke  setConsoleScreenBufferSize, [stdoutHandle], EAX
        ret
endp