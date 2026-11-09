bats_require_minimum_version 1.5.0

SPECS="$BATS_TEST_DIRNAME/specs"
E2E_SHELL=${E2E_SHELL:-bash}
case $E2E_SHELL in
  zsh) E2E_SHELL_CMD=(zsh -f) ;;
  *) E2E_SHELL_CMD=("$E2E_SHELL") ;;
esac

# clap SPEC [ARGS...]
# Runs clap4shell with SPEC on stdin and prints its raw output.
clap() {
  local spec=$1
  shift
  clap4shell "$@" < "$SPECS/$spec"
}

# parse SPEC SNIPPET [ARGS...]
# Evals the output of clap4shell in $E2E_SHELL, the way a user script does,
# then evals SNIPPET in the same shell to report the resulting state.
# Variable names are prefixed so that they do not collide with names in SPEC.
# PATH is passed explicitly because zsh always reads /etc/zshenv, which may reset it.
parse() {
  local spec=$1 snippet=$2
  shift 2
  "${E2E_SHELL_CMD[@]}" -c '
    PATH=$1 __e2e_spec=$2 __e2e_snippet=$3
    shift 3
    __e2e_out=$(clap4shell "$@" < "$__e2e_spec") || exit
    eval "$__e2e_out"
    eval "$__e2e_snippet"
  ' e2e "$PATH" "$SPECS/$spec" "$snippet" "$@"
}

expect_output() {
  if [ "$output" != "$1" ]; then
    printf 'expected: %q\nactual:   %q\n' "$1" "$output" >&2
    return 1
  fi
}

# Values that must survive the round trip through clap4shell and eval unchanged.
TRICKY_VALUES=(
  ''
  ' '
  'plain'
  'two words'
  "it's"
  "'"
  "''"
  '"'
  '\'
  'trailing\'
  '\n'
  '$HOME'
  '$(echo injected)'
  '`echo injected`'
  '*'
  '!'
  ';'
  '&& echo injected'
  '#'
  $'tab\there'
  $'line1\nline2'
  '-dash'
  '--double-dash'
  '日本語'
)
