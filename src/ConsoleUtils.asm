proc    GetFirstLaunchArgument
        locals
                pLaunchArgs  dd  ?  
                pFirstArg    dd  ?
        endl

        invoke  GetCommandLine
        mov     [pLaunchArgs], EAX
        invoke  PathGetArgs, EAX
        mov     [pFirstArg], EAX
        stdcall StringLength, [pLaunchArgs]
        add     EAX, [pLaunchArgs]
        cmp     EAX, [pFirstArg]
        jne     @F
        mov     EAX, NULL
        jmp     return_GetFirstLaunchArgument
@@:
        mov     EAX, [pFirstArg]
return_GetFirstLaunchArgument:
        ret
endp