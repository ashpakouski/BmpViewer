proc    readBytes, fileHandle, outBufferPtr, outFileSize, shouldAutoCloseHandle
        locals
                processHeapHandle     dd    ?
                imageSize             dd    ?
        endl

        invoke  getFileSize, [fileHandle], NULL
        mov     [imageSize], EAX
        mov     EBX, [outFileSize]
        mov     [EBX], EAX

        invoke  getProcessHeap
        mov     [processHeapHandle], EAX

        invoke  heapAlloc, [processHeapHandle], HEAP_ZERO_MEMORY, [imageSize]
        mov     EBX, [outBufferPtr]
        mov     [EBX], EAX

        invoke  readFile, [fileHandle], EAX, [imageSize], NULL, NULL
        invoke  closeHandle, [processHeapHandle]

        cmp     [shouldAutoCloseHandle], TRUE
        jne     @F
        invoke  closeHandle, [fileHandle]
@@:
        ret
endp