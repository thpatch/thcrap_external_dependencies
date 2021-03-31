rem OpenSSL

cd openssl
perl Configure VC-WIN32 AS="cl /Fx ..\safeseh.h nologo | ..\i686-w64-mingw32-as.exe" CFLAGS="/W3 /wd4090 /nologo /O2 /D _USING_V110_SDK71_"

rem The following PowerShell commands edit the makefile after it has been generated for reasons explained below the command. In theory this would make it smarter to write a PowerShell script instead, but PowerShell doesn't let you run unsigned/selfsigned scripts by default.

powershell -Command "(gc makefile) -replace '-f win32', '' | Out-File -encoding ASCII makefile"
rem The Configure script doensn't let you remove the '-f win32' parameter from the Assembler command line. With NASM, this option sets the output format. With GAS, it makes it fail to recognize what a TAB character is. 

powershell -Command "(gc makefile) -replace 'win32n', 'gaswin' | Out-File -encoding ASCII makefile"
rem OpenSSL doesn't have any asm files, it generates them at build time from Perl scripts that spell out Assembler instructions. These scripts can generate asm files for both NASM and GAS. Passing the win32n parameter to them will generate a NASM file, and gaswin will create a GAS file. The Configure script doesn't let you change win32n to gaswin, so it has to be done with PowerShell as well.

powershell -Command "(gc crypto\rand\rand_win.c) -replace '#  define USE_BCRYPTGENRANDOM', '' | Out-File -encoding ASCII crypto\rand\rand_win.c"
rem Make sure OpenSSL does not use bcrypt, instead relying on the old wincrypt. This is absolutely crucial for Windows XP support

nmake
cd ..
copy openssl\libcrypto.lib bin\libcrypto.lib
copy openssl\libssl.lib bin\libssl.lib
copy openssl\libcrypto-1_1.dll bin\libcrypto-1_1.dll
copy openssl\libssl-1_1.dll bin\libssl-1_1.dll