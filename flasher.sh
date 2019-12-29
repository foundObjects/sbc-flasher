#!/usr/bin/env bash
#
# flasher.sh -- SBC image writer script with media verification
#
# source:  https://github.com/foundObjects/sbc-flasher
# contact: Arglebargle @ forum.pine64.org or https://github.com/foundObjects/
# license: https://github.com/foundObjects/sbc-flasher/blob/master/LICENSE
#
# usage: flasher.sh (--flags) image target

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

set -euo pipefail
unalias -a

# set debug trace early so we catch argument parsing
#[[ $* =~ (^|[[:blank:]])(-x|--debug)($|[[:blank:]]) ]] && set -x

__main() {
  verify_only=''
  write_only=''
  debug=''
  nopv=''
  PARAMS=()
  while (("$#")); do
    [[ $1 == --*=* ]] || [[ $1 == -?=* ]] &&
      set -- "${1%%=*}" "${1#*=}" "${@:2}"
    case "$1" in
      -x | --debug)
        debug='true'
        shift
        ;;
      --no-pv)
        nopv='true'
        shift
        ;;
      -V | --verify | --verify-only)
        verify_only='true'
        shift
        ;;
      -W | --write | --write-only)
        write_only='true'
        shift
        ;;
      --help)
        _usage
        exit 0
        ;;
      --) # end argument parsing
        shift
        break
        ;;
      -*) # unsupported flags
        echo "Error: Unsupported flag $1" >&2
        _usage
        exit 1
        ;;
      *) # preserve positional arguments
        PARAMS+=("$1")
        shift
        ;;
    esac
  done
  set -- "${PARAMS[@]}"

  # set debug trace after argument parsing
  [[ $debug ]] && set -x

  # verify $1 is a readable file, $2 is a block device, not trying to do two --only things
  if (("$#" < "2")) ||
    ! { [[ -r "$1" ]] && [[ -b "$2" ]]; } ||
    [[ $write_only && $verify_only ]]; then
    #echo "YUO DUN GOOFED"
    _usage
    exit 1
  fi

  # check for pv :|
  [[ $nopv ]] || if ! type -p pv >&/dev/null; then
    _warn "pv not found in path. Install pv ('sudo apt install pv' on Debian) for progress meters."
    nopv='true'
  fi

  # write image, then verify; if --(thing)-only flag passed then just (thing)

  [[ $verify_only ]] || if _write "$1" "$2"; then
    echo "Write successful"
  else
    echo "Write failed"
    exit 1
  fi

  [[ $write_only ]] || if _verify "$1" "$2"; then
    echo "Image verified successfully"
  else
    echo "Verify failed"
    exit 1
  fi

  exit 0
}

_usage() {
  cat <<-END
		Usage: $(basename $0) (--flags) image(.img|.xz) /dev/target_block_device

		Flags:
		  -W | --write-only  | --write    Write pass only, no verification
		  -V | --verify-only | --verify   Verify only
		  -x | --debug                    Extremely verbose output (like bash -x ...)
		       --no-pv                    Don't use pipeviewer

END
}

_verify() (
  case "$(file -bz "$1")" in
    "DOS/MBR boot sector;"*"(XZ compressed data)")
      echo "Verifying xz image"
      _size="$(xz --robot --list "$1" | awk '/totals/ { print $5 }')"
      if [[ $nopv ]]; then
        xz -T0 -dkqc "$1" | cmp -bl -n "$_size" "$2"
      else
        pv -s "$_size" <(xz -T0 -dkqc "$1") | cmp -s -n "$_size" "$2"
      fi
      ;;
    "DOS/MBR boot sector;"*)
      echo "Verifying raw image"
      _size="$(stat -c '%s' "$1")"
      if [[ $nopv ]]; then
        cmp -bl -n "$_size" "$1" "$2"
      else
        pv -s "$_size" "$1" | cmp -s -n "$_size" "$2"
      fi
      ;;
    *)
      echo "Unknown image type"
      return 1
      ;;
  esac
)

_write() (
  case "$(file -bz "$1")" in
    "DOS/MBR boot sector;"*"(XZ compressed data)")
      echo "Writing xz compressed image to $2"
      _size="$(xz --robot --list "$1" | awk '/totals/ { print $5 }')"
      if [[ $nopv ]]; then
        xz -T0 -dkqc "$1" | dd of="$2" bs=4M conv=fsync status=progress
      else
        pv -s "$_size" <(xz -T0 -dkqc "$1") | dd of="$2" bs=4M conv=fsync
      fi
      ;;
    "DOS/MBR boot sector;"*)
      echo "Writing raw image to $2"
      _size="$(stat -c '%s' "$1")"
      if [[ $nopv ]]; then
        dd if="$1" of="$2" bs=4M conv=fsync status=progress
      else
        pv -s "$_size" "$1" | dd of="$2" bs=4M conv=fsync
      fi
      ;;
    *)
      echo "Unknown image type"
      return 1
      ;;
  esac
)

_warn() { echo "Warning: $*" >&2; }

__main "$@"

# TODO Notes:
#
# add support for other archive types:
#   bz2     it's not possible to get compressed size without a full decompression pass:
#           https://unix.stackexchange.com/questions/546465/bzip2-check-files-decompressed-size-without-actually-decompressing-it
#   gzip    reported sizes can be wrong
#           https://superuser.com/questions/619591/how-can-i-get-the-uncompressed-size-of-gzip-file-without-actually-decompressing
#   tar.*   getting a single file out of an archive adds a whole new layer of complexity
#   zip     ^
