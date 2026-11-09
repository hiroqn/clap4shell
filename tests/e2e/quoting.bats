load test_helper

# Each value is checked separately so that a failure names the offending value.
check_round_trip() {
  local snippet=$1 value=$2
  shift 2
  run parse basic.yaml "$snippet" "$@"
  if [ "$status" -ne 0 ] || [ "$output" != "[$value]" ]; then
    printf 'value:  %q\nstatus: %s\noutput: %q\n' "$value" "$status" "$output" >&2
    return 1
  fi
}

@test "option values round-trip through eval" {
  for value in "${TRICKY_VALUES[@]}"; do
    check_round_trip 'printf "[%s]" "$host"' "$value" --host="$value"
  done
}

@test "positional values round-trip through eval" {
  for value in "${TRICKY_VALUES[@]}"; do
    check_round_trip 'printf "[%s]" "$cmd"' "$value" -- "$value"
  done
}

@test "env values round-trip through eval" {
  for value in "${TRICKY_VALUES[@]}"; do
    # An empty environment variable counts as absent in clap.
    [ -n "$value" ] || continue
    E2E_TOKEN=$value check_round_trip 'printf "[%s]" "$token"' "$value"
  done
}

@test "eval of the output runs no injected command" {
  run parse basic.yaml 'printf "[%s]" "$host"' --host='$(echo injected)' -- '`echo injected`'
  [ "$status" -eq 0 ]
  expect_output '[$(echo injected)]'
}
