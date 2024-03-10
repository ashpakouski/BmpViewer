format      PE console 4.0

entry       start

include     "win32a.inc"

section     ".text" code readable executable
 
start:
        invoke  SetConsoleTitle, title
        invoke  GetStdHandle, STD_OUTPUT_HANDLE
        mov     [Handle.stdout], EAX
        invoke  GetStdHandle, STD_INPUT_HANDLE
        mov     [Handle.stdin], EAX

        invoke  CreateFileA, TestFile.path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        mov     [Handle.file], EAX

        cmp     EAX, INVALID_HANDLE_VALUE
        jne     noError
        invoke  WriteConsole, [Handle.stdout], Error.cantOpenFile, Error.cantOpenFile_ - Error.cantOpenFile, NULL, NULL
        invoke  WriteConsole, [Handle.stdout], TestFile.path, TestFile.path_ - TestFile.path, NULL, NULL
        jmp     exit
noError:

        invoke  GetFileSize, [Handle.file], NULL
        mov     [Image.size], EAX

        invoke  GetProcessHeap
        mov     [Handle.processHeap], EAX

        invoke  HeapAlloc, [Handle.processHeap], HEAP_ZERO_MEMORY, [Image.size]
        mov     [Image.bytesPtr], EAX

        invoke  ReadFile, [Handle.file], [Image.bytesPtr], [Image.size], NULL, NULL
        stdcall GetBmpOffset, [Image.bytesPtr]
        mov     [Image.offset], EAX
        stdcall GetBmpWidth, [Image.bytesPtr], Image.width
        mov     [Image.width], EAX
        stdcall GetBmpHeight, [Image.bytesPtr], Image.height
        mov     [Image.height], EAX

        stdcall SetConsoleSize, [Handle.stdout], [Image.width], [Image.height]

@@:
        xor     EAX, EAX
outerLoop:
        xor     EBX, EBX
innerLoop:
        pushad
        stdcall GetPixel, [Image.bytesPtr], [Image.offset], [Image.width], [Image.height], EBX, EAX
        stdcall ConvertPixel, EAX, ColorTable, (ColorTable_ - ColorTable) / 3

        invoke  SetConsoleTextAttribute, [Handle.stdout], EAX
        invoke  WriteConsole, [Handle.stdout], sampleText, sampleText_ - sampleText, NULL, NULL

        popad

        inc     EBX
        cmp     EBX, [Image.width]
        jb      innerLoop

        inc     EAX
        cmp     EAX, [Image.height]
        jb      outerLoop

exit:
        invoke  ReadConsole, [Handle.stdin], lpBuffer, 1, lpCharsRead, NULL
        invoke  ExitProcess, 0

proc    SetConsoleSize, stdoutHandle, width, height
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
        invoke  SetConsoleWindowInfo, [stdoutHandle], 1, EAX
        lea     EAX, [bufferSize]
        invoke  SetConsoleScreenBufferSize, [stdoutHandle], EAX
        ret
endp

proc    GetBmpOffset, bmpBytesPtr
        stdcall GetBmpParam, [bmpBytesPtr], 0x0A
        ret
endp

proc    GetBmpWidth, bmpBytesPtr
        stdcall GetBmpParam, [bmpBytesPtr], 0x12
        ret
endp

proc    GetBmpHeight, bmpBytesPtr
        stdcall GetBmpParam, [bmpBytesPtr], 0x16
        ret
endp

proc    GetBmpParam, bmpBytesPtr, paramOffset
        mov     EAX, [bmpBytesPtr]
        add     EAX, [paramOffset]
        mov     EAX, [EAX]
        ret
endp

        ; Result: xx BB RR GG
        ;                  ^^ AL
proc    GetPixel, bmpBytesPtr, bmpOffset, bmpWidth, bmpHeight, pixelX, pixelY
        mov     EAX, [bmpHeight]
        dec     EAX
        sub     EAX, [pixelY]
        mul     [bmpWidth]
        add     EAX, [pixelX]
        mov     EBX, 3
        mul     EBX
        add     EAX, [bmpOffset]
        add     EAX, [bmpBytesPtr]
        mov     EAX, [EAX] ; FIXME: Access violation?
        ret
endp

proc    ConvertPixel, pixel, colorTable, tableSize
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

; ======== Data ========
section         ".data" data readable writeable

sampleText      db      2 dup 219
sampleText_:

Error:
        .cantOpenFile   db      "Can't open file: "
        .cantOpenFile_:

TestFile:
        .path           db      "file\path\image.bmp", 0
        .path_:

Const:
title           db      "Pixel Viewer", 0
lpBuffer        db      10 dup (0)
lpCharsRead     dd      ?

Handle:
        .stdin          dd      ?
        .stdout         dd      ?
        .file           dd      ?
        .processHeap    dd      ?

Image:
        .width          dd      ?
        .height         dd      ?
        .offset         dd      ?
        .size           dd      ?
        .bytesPtr       dd      ?

include 'ColorTable.asm'

; ======== Imports ========
section         ".idata" import data readable
 
library         Kernel32, "Kernel32.dll"
 
import          Kernel32,\
                GetStdHandle, "GetStdHandle",\
                WriteConsole, "WriteConsoleA",\
                ReadConsole, "ReadConsoleA",\
                ExitProcess, "ExitProcess",\
                SetConsoleTitle, "SetConsoleTitleA",\
                CreateFileA, "CreateFileA",\
                ReadFile, "ReadFile",\
                SetConsoleTextAttribute, "SetConsoleTextAttribute",\
                GetFileSize, "GetFileSize",\
                GetProcessHeap, "GetProcessHeap",\
                HeapAlloc, "HeapAlloc",\
                SetConsoleWindowInfo, "SetConsoleWindowInfo",\
                SetConsoleScreenBufferSize, "SetConsoleScreenBufferSize"