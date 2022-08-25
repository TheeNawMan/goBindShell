#!/usr/bin/env bash
# Based on https://github.com/CyberSecurityN00b/star build script for STAR

type setopt >/dev/null 2>&1

# Delete existing binaries
rm -r ./shells

# Post-build function
post_build () {
    echo "--- Performing post-build actions on $1"
    upx -9 $1
}

# Build agents for all targets
FAILURES=""
REMOVEDS=""

while IFS= read -r target; do
    GOOS=${target%/*}
    GOARCH=${target#*/}
    BIN_FILENAME="./shells/${GOOS}-${GOARCH}"
    if [[ "${GOOS}" == "windows" ]]; then BIN_FILENAME="${BIN_FILENAME}.exe"; fi
    CMD="GOOS=${GOOS} GOARCH=${GOARCH} go build -ldflags \"-s -w\" -trimpath -o ${BIN_FILENAME} ./main.go"
    echo "--- Building ${BIN_FILENAME}"
    eval "${CMD}" || FAILURES="${FAILURES} agent:${GOOS}/${GOARCH}"
    post_build "${BIN_FILENAME}"
    echo ""
done <<< "$(go tool dist list)"

# No point in that wasm...
rm ./shells/js-wasm
REMOVEDS="${REMOVEDS} agent:js/wasm"

if [[ "${FAILURES}" != "" ]]; then
    echo ""
    echo "Your Shells failed to build on: ${FAILURES}"
    echo "Shells deleted : ${REMOVEDS}"
    exit 1
fi

