format  PE console 4.0

entry   start

include "win32a.inc"

DEFAULT_CONSOLE_WIDTH_CHARS = 120
DEFAULT_CONSOLE_WIDTH_PIXELS = DEFAULT_CONSOLE_WIDTH_CHARS / (string.pixel_ - string.pixel)

section ".code" code readable executable

include "StringUtils.asm"
include "ConsoleUtils.asm"
include "FileUtils.asm"

start:
        stdcall loadIoHandles
        invoke  setConsoleTitle, string.appTitle

        ; Get image path, which is passed in the first launch argument
        ; or show error message, if there is no path provided
        stdcall getFirstLaunchArgument
        cmp     EAX, NULL
        jne     @F
        invoke  writeConsole, [handle.stdout], error.noFileSelected, error.noFileSelected_ - error.noFileSelected, NULL, NULL
        jmp     exit
@@:
        mov     [image.path], EAX

        ; Get file handle or show error message, if handle couldn't be obtained
        invoke  createFile, [image.path], GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        cmp     EAX, INVALID_HANDLE_VALUE
        jne     @F
        invoke  writeConsole, [handle.stdout], error.cantOpenFile, error.cantOpenFile_ - error.cantOpenFile, NULL, NULL
        stdcall stringLength, [image.path]
        invoke  writeConsole, [handle.stdout], [image.path], EAX, NULL, NULL
        jmp     exit
@@:
        mov     [handle.file], EAX

        stdcall readBytes, [handle.file], image.bytesPtr, image.size, TRUE
        stdcall fillBmpParams, image

        ; Show warning message, if selected image is wider than a console.
        ; For some reason, I couldn't increase console size programmatically
        ; and I'm not even sure if it's possible
        cmp     [image.width], DEFAULT_CONSOLE_WIDTH_PIXELS
        jbe     @F
        invoke  writeConsole, [handle.stdout], error.imageTooWide, error.imageTooWide_ - error.imageTooWide, NULL, NULL
        invoke  readConsole, [handle.stdin], console.readBuffer, 2, console.lpCharsRead, NULL
        invoke  setConsoleCursorPosition, [handle.stdout], 0
@@:

        stdcall setConsoleSize, [handle.stdout], [image.width], [image.height]

        xor     EAX, EAX
outerLoop:
        xor     EBX, EBX
innerLoop:
        pushad
        stdcall getPixel, [image.bytesPtr], [image.offset], [image.width], [image.height], EBX, EAX
        stdcall convertPixel, EAX, ColorTable, (ColorTable_ - ColorTable) / 3

        invoke  setConsoleTextAttribute, [handle.stdout], EAX
        invoke  writeConsole, [handle.stdout], string.pixel, string.pixel_ - string.pixel, NULL, NULL
        popad

        inc     EBX
        cmp     EBX, [image.width]
        jb      innerLoop

        pushad
        stdcall addCrlfIfNeeded
        popad

        inc     EAX
        cmp     EAX, [image.height]
        jb      outerLoop

exit:
        invoke  readConsole, [handle.stdin], console.readBuffer, 2, console.lpCharsRead, NULL
        stdcall closeIoHandles
        invoke  exitProcess, 0

proc    loadIoHandles
        invoke  getStdHandle, STD_OUTPUT_HANDLE
        mov     [handle.stdout], EAX
        invoke  getStdHandle, STD_INPUT_HANDLE
        mov     [handle.stdin], EAX
        ret
endp

proc    closeIoHandles
        invoke  closeHandle, [handle.stdout]
        invoke  closeHandle, [handle.stdin]
        ret
endp

proc    addCrlfIfNeeded
        mov     EAX, [image.width]
        mov     EBX, 2
        mul     EBX
        cmp     EAX, DEFAULT_CONSOLE_WIDTH_PIXELS
        jae     @F
        invoke  writeConsole, [handle.stdout], string.crlf, string.crlf_ - string.crlf, NULL, NULL
@@:
        ret
endp

proc    fillBmpParams, imagePtr
        locals
                bytesPtr    dd      ?
        endl

        mov     EAX, [imagePtr]
        mov     EAX, [EAX + Image.bytesPtr]
        mov     [bytesPtr], EAX

        mov     EBX, [imagePtr] ; Functions below don't modify EBX

        stdcall getBmpOffset, [bytesPtr]
        mov     [EBX + Image.offset], EAX
        
        stdcall getBmpWidth, [bytesPtr]
        mov     [EBX + Image.width], EAX

        stdcall getBmpHeight, [bytesPtr]
        mov     [EBX + Image.height], EAX
        ret
endp

proc    getBmpOffset, bmpBytesPtr
        stdcall getBmpParam, [bmpBytesPtr], 0x0A
        ret
endp

proc    getBmpWidth, bmpBytesPtr
        stdcall getBmpParam, [bmpBytesPtr], 0x12
        ret
endp

proc    getBmpHeight, bmpBytesPtr
        stdcall getBmpParam, [bmpBytesPtr], 0x16
        ret
endp

proc    getBmpParam, bmpBytesPtr, paramOffset
        mov     EAX, [bmpBytesPtr]
        add     EAX, [paramOffset]
        mov     EAX, [EAX]
        ret
endp

        ; Result: xx BB RR GG
        ;                  ^^ AL
proc    getPixel, bmpBytesPtr, bmpOffset, bmpWidth, bmpHeight, pixelX, pixelY
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



section ".data" data readable writeable

include "Image.asm"

string:
        .pixel          db      2 dup 219
        .pixel_:
        .crlf           db      13, 10
        .crlf_:
        .appTitle       db      "Pixel Viewer", 0

error:
        .noFileSelected db      "No file selected. To use this app drop your BMP right on the app launcher icon."
        .noFileSelected_:
        .cantOpenFile   db      "Can't open file: "
        .cantOpenFile_:
        .imageTooWide   db      "Selected image is too wide. You'll have to resize console manually. Press Enter to continue."
        .imageTooWide_:

app:
        .launchArgs     dd      ?

console:
        .readBuffer     dw      ?
        .lpCharsRead    dd      ?

handle:
        .stdin          dd      ?
        .stdout         dd      ?
        .file           dd      ?

image   Image

include 'ColorTable.asm'



section ".idata" import data readable
 
library         Kernel32, "Kernel32.dll",\
                Shlwapi, "Shlwapi.dll"
 
import          Kernel32,\
                getStdHandle, "GetStdHandle",\
                writeConsole, "WriteConsoleA",\
                readConsole, "ReadConsoleA",\
                exitProcess, "ExitProcess",\
                setConsoleTitle, "SetConsoleTitleA",\
                createFile, "CreateFileA",\
                readFile, "ReadFile",\
                setConsoleTextAttribute, "SetConsoleTextAttribute",\
                getFileSize, "GetFileSize",\
                getProcessHeap, "GetProcessHeap",\
                heapAlloc, "HeapAlloc",\
                setConsoleWindowInfo, "SetConsoleWindowInfo",\
                setConsoleScreenBufferSize, "SetConsoleScreenBufferSize",\
                getCommandLine, "GetCommandLineA",\
                closeHandle, "CloseHandle",\
                setConsoleCursorPosition, "SetConsoleCursorPosition"

import          Shlwapi,\
                pathGetArgs, "PathGetArgsA"