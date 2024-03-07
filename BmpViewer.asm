format      PE console 4.0

entry       start

include     'win32a.inc'

section     '.text' code readable executable
 
start:
        stdcall GetStdout
        stdcall GetStdin

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

        stdcall GetBmpOffset, [Image.bytesPtr], Image.offset
        stdcall GetBmpOffset, [Image.bytesPtr], Image.offset   ; TODO: FOLLOW CALL CONVENTION!
        stdcall GetBmpWidth, [Image.bytesPtr], Image.width
        stdcall GetBmpHeight, [Image.bytesPtr], Image.height

;        mov     EBX, 0
;@@:
;        invoke  SetConsoleTextAttribute, [stdout], EBX
;        invoke  WriteConsole, [stdout], sampleText, sampleText_ - sampleText, NULL, NULL
;        inc     EBX
;        cmp     EBX, 256
;        jne     @B

exit:
        invoke  ReadConsole, [Handle.stdin], lpBuffer, 1, lpCharsRead, NULL
        invoke  ExitProcess, 0

proc    GetStdout
        invoke  GetStdHandle, STD_OUTPUT_HANDLE
        mov     [Handle.stdout], EAX
        ret
endp

proc    GetStdin
        invoke  GetStdHandle, STD_INPUT_HANDLE
        mov     [Handle.stdin], EAX
        ret
endp

proc    GetBmpOffset, bmpBytesPtr, resultDwordPtr
        stdcall GetBmpParam, [bmpBytesPtr], [resultDwordPtr], 0x0A
        ret
endp

proc    GetBmpWidth, bmpBytesPtr, resultDwordPtr
        stdcall GetBmpParam, [bmpBytesPtr], [resultDwordPtr], 0x12
        ret
endp

proc    GetBmpHeight, bmpBytesPtr, resultDwordPtr
        stdcall GetBmpParam, [bmpBytesPtr], [resultDwordPtr], 0x16
        ret
endp

proc    GetBmpParam, bmpBytesPtr, resultPtr, paramOffset
        mov     EAX, [bmpBytesPtr]
        add     EAX, [paramOffset]
        mov     EBX, [EAX]
        mov     EDX, [resultPtr]
        mov     [EDX], EBX
        ret
endp

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
        mov     EAX, [EAX]
        ret
endp

; ======== Data ========
section         '.data' data readable writeable

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

include 'Colors.asm'

; ======== Imports ========
section         '.idata' import data readable
 
library         Kernel32, 'Kernel32.dll'
 
import          Kernel32,\
                GetStdHandle, 'GetStdHandle',\
                WriteConsole, 'WriteConsoleA',\
                ReadConsole, 'ReadConsoleA',\
                ExitProcess, 'ExitProcess',\
                SetConsoleTitle, 'SetConsoleTitleA',\
                CreateFileA, 'CreateFileA',\
                ReadFile, 'ReadFile',\
                SetConsoleTextAttribute, 'SetConsoleTextAttribute',\
                GetFileSize, 'GetFileSize',\
                GetProcessHeap, 'GetProcessHeap',\
                HeapAlloc, 'HeapAlloc'