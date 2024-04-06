format  PE console 4.0

entry   start

include "win32a.inc"

DEFAULT_CONSOLE_WIDTH_CHARS = 120
DEFAULT_CONSOLE_WIDTH_PIXELS = DEFAULT_CONSOLE_WIDTH_CHARS / (string.pixel_ - string.pixel)

section ".code" code readable executable

include "utils/Utils.inc"
include "presentation/Presentation.inc"

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
        invoke  readConsole, [handle.stdin], console.readBuffer, 2, console.charsRead, NULL
        invoke  setConsoleCursorPosition, [handle.stdout], 0
@@:

        stdcall drawImage, [handle.stdout], image, string.pixel

exit:
        invoke  readConsole, [handle.stdin], console.readBuffer, 2, console.charsRead, NULL
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

section ".data" data readable writeable

include "model/Model.inc"

string:
        .pixel          db      2 dup 219
        .pixel_:
        .pixel_null_    db      0
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
        .charsRead      dd      ?

handle:
        .stdin          dd      ?
        .stdout         dd      ?
        .file           dd      ?

image   Image

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