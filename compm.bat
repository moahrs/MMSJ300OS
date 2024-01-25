rem copy C:\Ide68k\Examples\mmsj_os.hex . /Y
mot2bin -p 0 mmsj_os.hex
copy mmsj_os.bin MMSJ_OS.SYS
move /Y MMSJ_OS.SYS BKP_HD_NEW
