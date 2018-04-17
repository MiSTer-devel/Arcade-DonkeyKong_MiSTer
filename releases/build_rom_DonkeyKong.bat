@echo off

set    zip=dkong.zip
set ifiles=c_5et_g.bin+c_5ct_g.bin+c_5bt_g.bin+c_5at_g.bin+c_5at_g.bin+c_5at_g.bin+v_3pt.bin+v_3pt.bin+v_5h_b.bin+v_5h_b.bin+c_5at_g.bin+c_5at_g.bin+l_4m_b.bin+l_4m_b.bin+l_4n_b.bin+l_4n_b.bin+l_4r_b.bin+l_4r_b.bin+l_4s_b.bin+l_4s_b.bin+s_3i_b.bin+s_3j_b.bin+c-2k.bpr+c-2j.bpr+v-5e.bpr+..\empty.bin+..\dk_wave.bin
set  ofile=a.dkong.rom

rem =====================================
setlocal ENABLEDELAYEDEXPANSION

set pwd=%~dp0
echo.
echo.

if EXIST %zip% (

	!pwd!7za x -otmp %zip%
	if !ERRORLEVEL! EQU 0 ( 
		cd tmp

		copy /b/y %ifiles% !pwd!%ofile%
		if !ERRORLEVEL! EQU 0 ( 
			echo.
			echo ** done **
			echo.
			echo Copy "%ofile%" into root of SD card
		)
		cd !pwd!
		rmdir /s /q tmp
	)

) else (

	echo Error: Cannot find "%zip%" file
	echo.
	echo Put "%zip%", "7za.exe" and "%~nx0" into the same directory
)

echo.
echo.
pause
