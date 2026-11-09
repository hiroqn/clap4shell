load test_helper

EXAMPLE="$BATS_TEST_DIRNAME/../../example.sh"

@test "example.sh runs with a subcommand" {
  run bash "$EXAMPLE" -v --host h ls a b
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "subcommands: ls" ]
}
