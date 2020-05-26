#!/bin/bash
set -o errexit -o nounset -o pipefail

# shellcheck source=src/constants.sh
source "$COSMWASM_VERIFY_SRC/constants.sh"

function sha256() {
  FILE="$1"

  if command -v sha256sum > /dev/null ; then
    sha256sum "$FILE" | head -c 64
    echo # linebreak
    return
  fi

  if command -v shasum > /dev/null ; then
    shasum -a 256 "$FILE" | head -c 64
    echo # linebreak
    return
  fi

  echo "No SHA-256 implementation found"
  return 6
}

function print_usage() {
  echo "Usage: cosmwasm-verify SOURCE_URL BUILDER_IMAGE EXPECTED_CHECKSUM"
}

if [ "${1:-}" == "--help" ]; then
  print_usage
  exit 0
fi

if [ "$#" -ne 3 ]; then
  echo "Error: Script must be called with exactly 3 arguments."
  echo ""
  print_usage
  exit 42
fi

SOURCE_URL="$1"
BUILDER_IMAGE="$2"
EXPECTED_CHECKSUM="$3"

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/cosmwasm_verify.XXXXXXXXX")
SOURCE_DIR="$TMP_DIR/source"
mkdir "$SOURCE_DIR"

(
  echo "Navigating into working directory $TMP_DIR ..."
  cd "$SOURCE_DIR"

  DOWNLOAD_FILE="$TMP_DIR/cosmwasm_verify_download.tar"
  echo "Downloading $SOURCE_URL ..."
  wget --no-verbose -O "$DOWNLOAD_FILE" "$SOURCE_URL"
  SOURCE_CHECKSUM=$(sha256 "$DOWNLOAD_FILE")
  echo "Source code checksum $SOURCE_CHECKSUM"
  tar -x --strip-components 1 -f "$DOWNLOAD_FILE"

  # echo "Files in working directory:"
  # ls .

  CACHE_KEY="cosmwasm_verify_cache_$(echo "$SOURCE_URL" | xxd -p -c 999999)"

  # TODO: make this call builder agnostic
  docker run --rm \
    -v "$(pwd):/$MOUNTPOINT_CODE" \
    --mount type=volume,source="$CACHE_KEY",target=/code/target \
    --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
    "$BUILDER_IMAGE"

  CHECKSUM=$(sha256 contract.wasm)

  echo ""
  echo "- - - - - - - - - - - - - - - - - - - -"
  echo ""

  if [ "$CHECKSUM" == "$EXPECTED_CHECKSUM" ]; then
    echo "👏 Verification succeeded"
    echo
    echo "Source URL:      $SOURCE_URL"
    echo "Source checksum: $SOURCE_CHECKSUM"
    echo "Builder:         $BUILDER_IMAGE"
    echo "Build checksum:  $CHECKSUM"
    return 0
  else
    echo "Oh no, something went wrong 😞"
    echo "Expected: $EXPECTED_CHECKSUM"
    echo "Actual:   $CHECKSUM"
    echo
    echo "A verification failure can have many different reasons, including a"
    echo "malicious code upload. Don't panic – most of the time it's a small"
    echo "mistake in the verification or code upload process. Please check the"
    echo "above output for hints on problems during the verification."
    echo "You can access the local copy of the downloaded source, which is in:"
    echo "$TMP_DIR"
    return 15
  fi
)
