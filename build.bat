@if %VSCMD_ARG_TGT_ARCH% == x64 (
    @rem call build-openssl-x64.bat
) else (
    @rem call build-openssl-x86.bat
)

@rem call build-fribidi.bat

powershell -ExecutionPolicy Bypass -File build.ps1
