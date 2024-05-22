@rem OpenSSL

@cd openssl
perl Configure VC-WIN32 AS="cl /Fx ..\safeseh.h nologo | ..\i686-w64-mingw32-as.exe" CFLAGS="/W3 /wd4090 /nologo /O2 /D _USING_V110_SDK71_ /D _WIN32_WINNT=0x0501"

@rem The following PowerShell commands edit the makefile after it has been generated for reasons explained below the command.
@rem In theory this would make it smarter to write a PowerShell script instead, but PowerShell doesn't let you run unsigned/selfsigned scripts by default.

@rem The Configure script doensn't let you remove the '-f win32' parameter from the Assembler command line.
@rem With NASM, this option sets the output format. With GAS, it makes it fail to recognize what a TAB character is.
powershell -Command "(gc makefile) -replace '-f win32', '' | Out-File -encoding ASCII makefile"

@rem OpenSSL doesn't have any asm files, it generates them at build time from Perl scripts that spell out Assembler instructions.
@rem These scripts can generate asm files for both NASM and GAS. Passing the win32n parameter to them will generate a NASM file, and gaswin will create a GAS file.
@rem The Configure script doesn't let you change win32n to gaswin, so it has to be done with PowerShell as well.
powershell -Command "(gc makefile) -replace 'win32n', 'gaswin' | Out-File -encoding ASCII makefile"

nmake
@cd ..
copy /y openssl\libcrypto.lib bin\libcrypto.lib
copy /y openssl\libssl.lib bin\libssl.lib
copy /y openssl\libcrypto-1_1.dll bin\libcrypto-1_1.dll
copy /y openssl\libssl-1_1.dll bin\libssl-1_1.dll


@rem FriBidi
@cd fribidi

meson setup build -Ddocs=false
meson compile -C build

@cd ..
copy /y fribidi\build\lib\fribidi.lib   bin\fribidi.lib
copy /y fribidi\build\lib\fribidi-0.dll bin\fribidi-0.dll
copy /y fribidi\build\lib\fribidi.exp   bin\fribidi.exp
copy /y fribidi\build\lib\fribidi-0.pdb bin\fribidi-0.pdb
if not exist fribidi_includes mkdir fribidi_includes
copy /y fribidi\build\lib\fribidi-config.h fribidi_includes\fribidi-config.h
copy /y fribidi\build\gen.tab\fribidi-unicode-version.h fribidi_includes\fribidi-unicode-version.h
