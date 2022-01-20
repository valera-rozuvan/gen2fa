#!/bin/bash

# gen2fa v1.0 | https://github.com/valera-rozuvan/gen2fa
# copyright (c) 2022 Valera Rozuvan
# license: MIT

set -o errexit
set -o pipefail

function hndl_SIGHUP() {
  echo "Unfortunately, the script received SIGHUP..."
  exit 1
}
function hndl_SIGINT() {
  echo "Unfortunately, the script received SIGINT..."
  exit 1
}
function hndl_SIGQUIT() {
  echo "Unfortunately, the script received SIGQUIT..."
  exit 1
}
function hndl_SIGABRT() {
  echo "Unfortunately, the script received SIGABRT..."
  exit 1
}
function hndl_SIGTERM() {
  echo "Unfortunately, the script received SIGTERM..."
  exit 1
}

trap hndl_SIGHUP SIGHUP
trap hndl_SIGINT SIGINT
trap hndl_SIGQUIT SIGQUIT
trap hndl_SIGABRT SIGABRT
trap hndl_SIGTERM SIGTERM

# ----------------------------------------------------------------------------------------------

LIST_MODE="false"
DEBUG_MODE="false"
CLIP_MODE="false"
VERSION_MODE="false"
HELP_MODE="false"
QUIET_MODE="false"

while [ -n "$1" ]; do
  case "$1" in
  -l | --list)
    LIST_MODE="true"
    ;;
  -d | --debug)
    DEBUG_MODE="true"
    ;;
  -c | --clipboard)
    CLIP_MODE="true"
    ;;
  --version)
    VERSION_MODE="true"
    ;;
  -h | --help)
    HELP_MODE="true"
    ;;
  -q | --quiet)
    QUIET_MODE="true"
    ;;
  --)
    shift
    break
    ;;
  *)
    echo "ERROR: '${1}' is not a valid option!"
    exit 1
    ;;
  esac

  shift
done

if [[ "$DEBUG_MODE" == "true" ]]; then
  echo "LIST_MODE = '${LIST_MODE}'"
  echo "DEBUG_MODE = '${DEBUG_MODE}'"
  echo "CLIP_MODE = '${CLIP_MODE}'"
  echo "VERSION_MODE = '${VERSION_MODE}'"
  echo "HELP_MODE = '${HELP_MODE}'"
  echo -e "QUIET_MODE = '${QUIET_MODE}'\n"
fi

if [[ "$VERSION_MODE" == "true" ]]; then
  echo -e "gen2fa v1.0\n"
  echo "source code: https://github.com/valera-rozuvan/gen2fa"
  echo "copyright (c) 2022 Valera Rozuvan"
  echo "license: MIT"

  if [[ "$HELP_MODE" == "false" ]]; then
    exit 0
  fi
fi

if [[ "$HELP_MODE" == "true" ]]; then
  if [[ "$VERSION_MODE" == "true" ]]; then
    echo ""
  fi

  echo -e "Requirements of the script:\n"

  echo "  - pass [https://www.passwordstore.org/]"
  echo "  - Python v3.3+ [https://www.python.org/]"
  echo "  - grep [https://www.gnu.org/software/grep/]"
  echo "  - Bash [https://www.gnu.org/software/bash/]"
  echo "  - xclip [https://github.com/astrand/xclip]"
  echo "  - sed [https://www.gnu.org/software/sed/]"

  echo -e "\nAvailable CLI arguments, understood by the script:\n"

  echo "  -l | --list       List available accounts to generate 2FA for."
  echo "  -c | --clipboard  Copy the 2FA code to clipboard using xclip."
  echo "  -q | --quiet      Try to be less verbose."
  echo "  -d | --debug      Print extra debugging information - contents of the script variables."
  echo "  -h | --help       Print help information; CLI usage."
  echo "       --version    Print version."

  exit 0
fi

if [[ "$LIST_MODE" == "true" ]]; then
  if [[ "$QUIET_MODE" == "false" ]]; then
    echo -e "Available accounts:\n"
  fi

  ####
  # Output the first part of each line (text is stored by pass in 'two_fa' entry). For example, given the line:
  #
  # google acc: personal/me@gmail.com
  #
  # The below sed expression will return:
  #
  #   - "google acc"
  ####
  pass two_fa | sed -e 's/: .*$/\"/g' | sed -e 's/^/  - \"/g'

  exit 0
fi

if [[ "$QUIET_MODE" == "false" ]]; then
  echo -n "Enter the account to generate 2FA: "
fi

read ACCOUNT

if [[ "$DEBUG_MODE" == "true" ]]; then
  echo -e "\nACCOUNT: '${ACCOUNT}'"
fi

PASS_ACCOUNT_RAW=$(pass two_fa | grep "${ACCOUNT}" || true)
PASS_ACCOUNT=""
if [[ -n "$PASS_ACCOUNT_RAW" && "$PASS_ACCOUNT_RAW" != " " ]]; then
  PASS_ACCOUNT=${PASS_ACCOUNT_RAW/"${ACCOUNT}: "/}
else
  echo -e "\nERROR! Unknown account \"${ACCOUNT}\"!"
  exit 1
fi

if [[ "$DEBUG_MODE" == "true" ]]; then
  echo -e "\nPASS_ACCOUNT_RAW: '${PASS_ACCOUNT_RAW}'"
  echo -e "PASS_ACCOUNT: '${PASS_ACCOUNT}'"
fi

####
# What is SCRIPT_DIR?
#
# We need to get the directory where this Bash script is located.
# Why? We need to call a Python script from this same directory.
# This allows us to execute this Bash script from any directory.
#
# Original code snippet found here:
#   https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel
####
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

if [[ "$DEBUG_MODE" == "true" ]]; then
  echo -e "\nSCRIPT_DIR: '${SCRIPT_DIR}'"
fi

TWO_FA_SECRET_RAW=$(pass "${PASS_ACCOUNT}" | grep "2FA secret" || true)
TWO_FA_SECRET=""

if [[ -n "$TWO_FA_SECRET_RAW" && "$TWO_FA_SECRET_RAW" != " " ]]; then
  TWO_FA_SECRET=${TWO_FA_SECRET_RAW/2FA secret: /}
else
  echo -e "ERROR! Could not get 2FA secret string for account \"${ACCOUNT}\"!"
  exit 1
fi

TWO_FA_CODE=$(TWO_FA_SECRET="${TWO_FA_SECRET}" python3 "${SCRIPT_DIR}"/otp.py)

if [[ "$DEBUG_MODE" == "true" ]]; then
  echo -e "\nTWO_FA_SECRET_RAW: '${TWO_FA_SECRET_RAW}'"
  echo "TWO_FA_SECRET: '${TWO_FA_SECRET}'"
  echo -e "TWO_FA_CODE: '${TWO_FA_CODE}'"
fi

if [[ "$CLIP_MODE" == "true" ]]; then
  echo "${TWO_FA_CODE}" | xclip -sel clip

  if [[ "$QUIET_MODE" == "false" ]]; then
    echo -e "\n2FA code '${TWO_FA_CODE}' was copied to clipboard. Will clear in 6 seconds..."
  else
    if [[ "$DEBUG_MODE" == "true" ]]; then
      echo ""
    fi

    echo "${TWO_FA_CODE}"
  fi

  sleep 6

  # If we reached here, clear clipboard state (set to empty string).
  echo "" | xclip -sel clip
else
  if [[ "$QUIET_MODE" == "false" ]]; then
    echo -e "\n2FA code is '${TWO_FA_CODE}'."
  else
    if [[ "$DEBUG_MODE" == "true" ]]; then
      echo ""
    fi

    echo "${TWO_FA_CODE}"
  fi
fi

exit 0
