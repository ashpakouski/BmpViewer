:: Make sure you set:
::   - PATH variable to wherever FASM.EXE is
::   - INCLUDE variable to wherever the FASM includes are

cd ../build
del BmpViewer.exe
cd ..
fasm src/BmpViewer.asm build/BmpViewer.exe
cd build
BmpViewer.exe
cd ../script