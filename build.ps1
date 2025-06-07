# Stop the script when a cmdlet or a native command fails
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

function Get-Suffix {
    param (
        [string[]]$Arch,
        [string[]]$Target
    )
    if ($Arch -eq "x64") {
        if ($Target -eq "Debug") {
            return "_64_d"
        }
        else {
            return "_64"
        }
    }
    elseif ($Target -eq "Debug") {
        return "_d"
    }
    else {
        return ""
    }
}

function Build-Openssl {
    param (
        [string[]]$Arch,
        [string[]]$Target
    )

    cd openssl
    git clean -dfx
    git restore .

    $suffix = Get-Suffix -Arch $Arch -Target $Target
    $suffix
    if ($Arch -eq "x64") {
        $ConfigureTarget = "VC-WIN64A"

        if ($Target -eq "Debug") {
            $ConfigureFlags = "--debug"
        }
        else {
            $ConfigureFlags = ""
        }
        # Replace the -x64 suffix with _64 or _64_d
        (Get-Content Configurations\10-main.conf) -replace 'multilib         => "-x64"', ('multilib         => "' + $suffix + '"') | Out-File -encoding ASCII Configurations\10-main.conf
    }
    elseif ($Target -eq "Debug") {
        $ConfigureTarget = "VC-WIN32"
        $ConfigureFlags = "--debug"

        # Add a _d suffix (we can't use multilib for x86)
        (Get-Content Configurations\10-main.conf) |
            Foreach-Object {
                $_
                if ($_ -match '"VC-WIN32" => {')
                {
                    '        multilib         => "_d",'
                }
            } | Out-File -encoding ASCII Configurations\10-main.conf
    }
    else {
        $ConfigureTarget = "VC-WIN32"
        $ConfigureFlags = ""
    }

    perl Configure $ConfigureTarget $ConfigureFlags
    nmake

    cd ..
    Copy-Item openssl\libcrypto.lib -Destination bin\libcrypto$suffix.lib
    Copy-Item openssl\libcrypto.exp -Destination bin\libcrypto$suffix.exp
    Copy-Item openssl\libssl.lib -Destination bin\libssl$suffix.lib
    Copy-Item openssl\libssl.exp -Destination bin\libssl$suffix.exp
    Copy-Item openssl\libcrypto-3$suffix.dll -Destination bin\libcrypto-3$suffix.dll
    Copy-Item openssl\libcrypto-3$suffix.pdb -Destination bin\libcrypto-3$suffix.pdb
    Copy-Item openssl\libssl-3$suffix.dll -Destination bin\libssl-3$suffix.dll
    Copy-Item openssl\libssl-3$suffix.pdb -Destination bin\libssl-3$suffix.pdb
}

function Build-FriBidi {
    param (
        [string[]]$Arch,
        [string[]]$Target
    )

    cd fribidi
    git restore lib\meson.build
    Remove-Item build -Recurse

    $suffix = Get-Suffix -Arch $Arch -Target $Target
    (Get-Content lib\meson.build). `
        Replace("libfribidi = library('fribidi',", "libfribidi = library('fribidi" + $suffix + "',") `
        -notlike '  version: libversion,' -notlike '  soversion: soversion,' | `
        Out-File -encoding ASCII lib\meson.build

    meson setup build -Ddocs=false -Dbin=false --buildtype $Target.ToLower()
    meson compile -C build
    meson install -C build --destdir out

    cd ..
    Copy-Item fribidi\build\out\bin\fribidi$suffix.dll -Destination bin\fribidi$suffix.dll
    Copy-Item fribidi\build\out\lib\fribidi$suffix.lib -Destination bin\fribidi$suffix.lib
    if ($Target -eq "Debug") {
        Copy-Item fribidi\build\out\bin\fribidi$suffix.pdb -Destination bin\fribidi$suffix.pdb
    }
    
    # The generated includes are the same for every build target, so we just overwrite what is there.
    Remove-Item include\fribidi -Recurse -ErrorAction SilentlyContinue
    New-Item include -ItemType Directory -ErrorAction SilentlyContinue
    Copy-Item -Recurse fribidi\build\out\include\fribidi -Destination include\fribidi
}

function Build-Libcurl {
    param (
        [string[]]$Arch,
        [string[]]$Target
    )

    $RootDir = Get-Location

    cd curl
    Remove-Item build -Recurse -ErrorAction SilentlyContinue
    Remove-Item out -Recurse -ErrorAction SilentlyContinue

    $suffix = Get-Suffix -Arch $Arch -Target $Target

    $CmakeAdditionalParams = ""
    if ($Arch -eq "x64") {
        $CmakeArch = "x64"
        $CmakeAdditionalParams = "-DLIBCURL_OUTPUT_NAME=libcurl_64"
    }
    else {
        $CmakeArch = "Win32"
    }
    if ($Target -eq "Debug") {
        $CmakeBuildType = "Debug"
    }
    else {
        $CmakeBuildType = "RelWithDebInfo"
    }

    cmake -B build `
        "-DCMAKE_INSTALL_PREFIX=.\out" `
        "-DBUILD_CURL_EXE=off" `
        "-DBUILD_EXAMPLES=off" `
        "-DBUILD_LIBCURL_DOCS=off" `
        "-DBUILD_MISC_DOCS=off" `
        "-DCURL_DEFAULT_SSL_BACKEND=openssl" `
        "-DHTTP_ONLY=on" `
        "-DCMAKE_DEBUG_POSTFIX=_d" `
        "-DCURL_ZLIB=on" `
        "-DOPENSSL_ROOT_DIR=$RootDir\openssl" `
        "-DZLIB_INCLUDE_DIR=..\include" `
        "-DZLIB_LIBRARY=$RootDir\bin\zdll-ng$suffix.lib" `
        "-DCURL_USE_OPENSSL=on" `
        "-DCURL_USE_LIBPSL=off" `
        -T v141_xp `
        -A $CmakeArch `
        $CmakeAdditionalParams
    cmake --build .\build --config $CmakeBuildType
    cmake --install .\build --config $CmakeBuildType
    
    cd ..
    Copy-Item curl\out\bin\libcurl$suffix.dll -Destination bin\libcurl$suffix.dll
    Copy-Item curl\out\lib\libcurl${suffix}_imp.lib -Destination bin\libcurl$suffix.lib
    Copy-Item curl\build\lib\$CmakeBuildType\libcurl$suffix.pdb -Destination bin\libcurl$suffix.pdb
    
    # The generated includes are the same for every build target, so we just overwrite what is there.
    Remove-Item include\curl -Recurse -ErrorAction SilentlyContinue
    New-Item include -ItemType Directory -ErrorAction SilentlyContinue
    Copy-Item -Recurse curl\out\include\curl -Destination include\curl
}

if ($Env:VSCMD_ARG_TGT_ARCH -eq "x64") {
    $MsBuildPlatform = "x64"
} else {
    $MsBuildPlatform = "Win32"
}

msbuild /target:Rebuild /property:Configuration=Debug /property:Platform=$MsBuildPlatform thcrap_external_deps.sln
if ($LASTEXITCODE -gt 0) { exit 1 }
Build-Openssl -Arch $Env:VSCMD_ARG_TGT_ARCH -Target Debug
Build-Libcurl -Arch $Env:VSCMD_ARG_TGT_ARCH -Target Debug
Build-FriBidi -Arch $Env:VSCMD_ARG_TGT_ARCH -Target Debug

msbuild /target:Rebuild /property:Configuration=Release /property:Platform=$MsBuildPlatform thcrap_external_deps.sln
if ($LASTEXITCODE -gt 0) { exit 1 }
Build-Openssl -Arch $Env:VSCMD_ARG_TGT_ARCH -Target Release
Build-Libcurl -Arch $Env:VSCMD_ARG_TGT_ARCH -Target Release
Build-FriBidi -Arch $Env:VSCMD_ARG_TGT_ARCH -Target Release
