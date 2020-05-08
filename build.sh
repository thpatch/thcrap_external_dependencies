#!/bin/sh

source ./env.sh

"$MSBUILD" thcrap_external_deps.sln /target:Clean
"$MSBUILD" thcrap_external_deps.sln /target:Build /property:Configuration=Debug
"$MSBUILD" thcrap_external_deps.sln /target:Build /property:Configuration=Release
