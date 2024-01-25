REM copy D:\PROJETOS\MMSJ300\%1.hex . /Y
mot2bin -p 0 %1.hex
REM move /Y %1.bin BKP_HD_NEW
