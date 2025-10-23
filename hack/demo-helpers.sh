
_first_h1=0

function h1() {
  if [ $_first_h1 = "0" ]; then
    _first_h1=1
  else
    pause
  fi

  local text="$1"
  local line=$(sed 's/./─/g' <<< "$text")
  echo "╭─$line─╮"
  echo "┝ $text ┥"
  echo "╰─$line─╯"
}

function show-var() {
  printf "%-16s %s\n" "$1:" "${!1}"
}

function show-msg() {
  printf "💬 %s\n" "$1"
}

function pause() {
  local default_msg="$(ansi darkgray "Enter to continue...")"
  local msg="${1:-$default_msg}"
  echo ""
  read -p "$msg"
  echo ""
}

function pause-h1() {
  title "$1"
}

function pause-then-run() {
  local cmd="$1"
  pause "$(printf "$(ansi yellow)\$$(ansi reset) %s" "$cmd")"
  set +e
  eval "$cmd"
  set -e
}

function show-then-run() {
  local cmd="$1"
  echo "$(printf "$(ansi yellow)\$$(ansi reset) %s" "$cmd")"
  set +e
  eval "$cmd"
  set -e
}

function nl() {
  printf "\n"
}

ansi() {
  local code="$1"
  local text="${2:-""}"

  case "$code" in
    reset)        code="0"    ;;
    black)        code="0;30" ;;
    red)          code="0;31" ;;
    green)        code="0;32" ;;
    orange)       code="0;33" ;;
    blue)         code="0;34" ;;
    purple)       code="0;35" ;;
    cyan)         code="0;36" ;;
    lightgray)    code="0;37" ;;
    darkgray)     code="1;30" ;;
    lightred)     code="1;31" ;;
    lightgreen)   code="1;32" ;;
    yellow)       code="1;33" ;;
    lightblue)    code="1;34" ;;
    lightpurple)  code="1;35" ;;
    lightcyan)    code="1;36" ;;
    white)        code="1;37" ;;
  esac

  if [ -n "$text" ]; then
    # Wrap provided text
    printf '\e[%sm%s\e[0m' "$code" "$text"
  else
    # Just emit the code
    printf '\e[%sm' "$code"
  fi
}
