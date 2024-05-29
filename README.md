# thcrap external dependecies

This repo is used to pull and build external dependencies for the [Touhou Community Reliant Automatic Patcher](https://github.com/thpatch/thcrap). 
You should never need to clone it directly. Instead, clone thcrap using `git clone --recursive https://github.com/thpatch/thcrap.git` and this repository (and its depeendencies) will be downloaded automatically.

## Build instructions
Note that this repository already contains prebuilt binaries. If you just want to build thcrap, you don't need to build this. Just build thcrap, and it will use the prebuilt binaries.

### Get thcrap
`git clone --recursive https://github.com/thpatch/thcrap.git`

### Build OpenSSL and FriBidi
1. Install [Perl](https://www.perl.org/get.html) (I'm using Strawberry Perl, it works for me), make sure it have been added to the PATH.
2. Install [NASM](https://www.nasm.us/), add it to the PATH.
3. Install [Meson](https://github.com/mesonbuild/meson/releases)
4. Open a Visual Studio x86 comand prompt. If you use Visual Studio 2019 with the v141_xp tools installed, you can find "x86 Native Tools Command Prompt for VS 2019" in the Start menu.
5. `cd ........\thcrap\libs\external_deps`
6. `.\build.bat`
4. Open a Visual Studio x64 comand prompt. If you use Visual Studio 2019 with the v141_xp tools installed, you can find "x64 Native Tools Command Prompt for VS 2019" in the Start menu.
5. `cd ........\thcrap\libs\external_deps`
6. `.\build.bat`

### Build everything else
1. Go to thcrap\libs\external_deps
2. Open thcrap_external_deps.sln
3. Build all
