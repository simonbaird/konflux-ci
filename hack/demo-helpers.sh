
# Output a fancy section heading. Assume you want to add a pause
# at the end of the current section before starting a new one
function h1() {
  if [ "${_first:-1}" = 1 ]; then
    _first=0
  else
    pause
  fi

  local text="$1"
  local line=$(sed 's/./─/g' <<< "$text")
  clear
  echo "╭─$line─╮"
  echo "┝ $text ┥"
  echo "╰─$line─╯"
}

# Show a command, then run it after the user hits enter
function pause-then-run() {
  pause "$(show-cmd "$1")"
  run-cmd "$1"
}

# Show a command, then run it immediately
function show-then-run() {
  show-cmd "$1"
  run-cmd "$1"
}

# Output some text and wait for the user to press enter
function pause() {
  local default_msg="$(ansi darkgray "Press Enter to continue...")"
  local msg="${1:-$default_msg}"
  read -p "$msg"
  nl
}

# Eval a command line
function run-cmd() {
  set +e
  eval "$1"
  set -e
  nl
}

# Pretty-print a command line
function show-cmd() {
  printf "%s %s\n" "$(ansi yellow \$)" "$1"
}

# Pretty-print variable names and values
function show-vars() {
  for v in $@; do
    printf "%-16s %s\n" "$v:" "${!v}"
  done
  nl
}

# Pretty-print a message
function show-msg() {
  printf "💬 %s\n\n" "$1" | fold -s -w 100
}

# Output a line break
function nl() {
  printf "\n"
}

# Output color text
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
