function Build-Openssl {
    param (
        [string[]]$Arch,
        [string[]]$Target
    )

    cd openssl
    git clean -dfx
    git restore .

    if ($Arch -eq "x64") {
        $ConfigureTarget = "VC-WIN64A"

        if ($Target -eq "Debug") {
            $ConfigureFlags = "--debug"
            $suffix = "_64_d"
        }
        else {
            $ConfigureFlags = ""
            $suffix = "_64"
        }
        # Replace the -x64 suffix with _64 or _64_d
        (Get-Content Configurations\10-main.conf) -replace 'multilib         => "-x64"', ('multilib         => "' + $suffix + '"') | Out-File -encoding ASCII Configurations\10-main.conf
    }
    elseif ($Target -eq "Debug") {
        $ConfigureTarget = "VC-WIN32"
        $ConfigureFlags = "--debug"
        $suffix = "_d"

        # Add a _d suffix (we can't use multilib for x86)
        (Get-Content build.info) -replace 'our \$sover_filename = \$sover;', 'our $sover_filename = $sover . "_d";' | Out-File -encoding ASCII build.info
    }
    else {
        $ConfigureTarget = "VC-WIN32"
        $ConfigureFlags = ""
        $suffix = ""
    }

    perl Configure $ConfigureTarget $ConfigureFlags
    nmake

    cd ..
    Copy-Item openssl\libcrypto.lib -Destination bin\libcrypto$suffix.lib
    Copy-Item openssl\libcrypto.exp -Destination bin\libcrypto$suffix.exp
    Copy-Item openssl\libssl.lib -Destination bin\libssl$suffix.lib
    Copy-Item openssl\libssl.exp -Destination bin\libssl$suffix.exp
    Copy-Item openssl\libcrypto-1_1$suffix.dll -Destination bin\libcrypto-1_1$suffix.dll
    Copy-Item openssl\libcrypto-1_1$suffix.pdb -Destination bin\libcrypto-1_1$suffix.pdb
    Copy-Item openssl\libssl-1_1$suffix.dll -Destination bin\libssl-1_1$suffix.dll
    Copy-Item openssl\libssl-1_1$suffix.pdb -Destination bin\libssl-1_1$suffix.pdb
}

function Build-FriBidi {
    param (
        [string[]]$Arch,
        [string[]]$Target
    )

    cd fribidi
    git restore lib\meson.build
    Remove-Item build -Recurse

    if ($Arch -eq "x64") {
        if ($Target -eq "Debug") {
            $suffix = "_64_d"
        }
        else {
            $suffix = "_64"
        }
    }
    elseif ($Target -eq "Debug") {
        $suffix = "_d"
    }
    else {
        $suffix = ""
    }
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
    Remove-Item fribidi_includes -Recurse -ErrorAction SilentlyContinue
    New-Item fribidi_includes -ItemType Directory
    Copy-Item -Recurse fribidi\build\out\include\fribidi -Destination fribidi_includes\fribidi
}

Build-Openssl -Arch $Env:VSCMD_ARG_TGT_ARCH -Target Debug
Build-Openssl -Arch $Env:VSCMD_ARG_TGT_ARCH -Target Release
Build-FriBidi -Arch $Env:VSCMD_ARG_TGT_ARCH -Target Debug
Build-FriBidi -Arch $Env:VSCMD_ARG_TGT_ARCH -Target Release
