format      PE console 4.0

entry       start

include     'win32a.inc'

section     '.text' code readable executable
 
start:
        stdcall GetStdout
        stdcall GetStdin

        invoke  CreateFileA, TestFile.path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        mov     [fileHandle], EAX

        cmp     EAX, INVALID_HANDLE_VALUE
        jne     noError
        invoke  WriteConsole, [stdout], Error.cantOpenFile, Error.cantOpenFile_ - Error.cantOpenFile, NULL, NULL
        invoke  WriteConsole, [stdout], TestFile.path, TestFile.path_ - TestFile.path, NULL, NULL
        jmp     exit
noError:

exit:
        invoke  ReadConsole, [stdin], lpBuffer, 1, lpCharsRead, NULL
        invoke  ExitProcess, 0

proc    GetStdout
        invoke  GetStdHandle, STD_OUTPUT_HANDLE
        mov     [stdout], EAX
        ret
endp

proc    GetStdin
        invoke  GetStdHandle, STD_INPUT_HANDLE
        mov     [stdin], EAX
        ret
endp

; ======== Data ========
section         '.data' data readable writeable

Error:
        .cantOpenFile   db      "Can't open file: "
        .cantOpenFile_:


TestFile:
        .path           db      "file\path\person.bmp", 0
        .path_:

Const:
lpBuffer        db      10 dup (0)
lpCharsRead     dd      ?

stdin           dd      ?
stdout          dd      ?
fileHandle      dd      ?

; ======== Imports ========
section         '.idata' import data readable
 
library         Kernel32, 'Kernel32.dll'
 
import          Kernel32,\
                GetStdHandle, 'GetStdHandle',\
                WriteConsole, 'WriteConsoleA',\
                ReadConsole, 'ReadConsoleA',\
                ExitProcess, 'ExitProcess',\
                SetConsoleTitle, 'SetConsoleTitleA',\
                CreateFileA, 'CreateFileA'