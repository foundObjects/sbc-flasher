#!/usr/bin/env bash
set -euo pipefail

_url="https://raw.githubusercontent.com/foundObjects/sbc-flasher/master/flasher.sh"
_script="flasher.sh"
_target="/usr/local/sbin/flasher.sh"

crapout() { echo "$@" >&2 && exit 1; }

if [[ ! -r "$_script" ]]; then
  _script=$(mktemp) && trap "[[ -f $_script ]] && rm -f $_script >&/dev/null" EXIT
  echo "Fetching script from GitHub..."
  wget "$_url" -qO "$_script" ||
    crapout "Couldn't fetch script :("
fi

echo "Installing to $_target"
if sudo install -o root "$_script" "$_target"; then
  printf "Success\n\n"
  /usr/local/sbin/flasher.sh --help
else
  crapout "Install failed :("
fi

exit 0
