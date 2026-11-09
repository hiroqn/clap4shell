load test_helper

@test "flags default to their initial values" {
  run parse basic.yaml 'echo "$verbose $quiet $count $enable $disable"'
  [ "$status" -eq 0 ]
  expect_output "0 0 0 0 1"
}

@test "flags are set when given" {
  run parse basic.yaml 'echo "$verbose $quiet $count $enable $disable"' \
    -v -q -c --enable --disable
  [ "$status" -eq 0 ]
  expect_output "1 1 1 1 0"
}

@test "multiple_occurrences flag counts occurrences" {
  run parse basic.yaml 'echo "$verbose"' -vvv --verbose
  [ "$status" -eq 0 ]
  expect_output "4"
}

@test "count action counts occurrences" {
  run parse basic.yaml 'echo "$count"' -ccc
  [ "$status" -eq 0 ]
  expect_output "3"
}

@test "set_true flag rejects repetition" {
  run --separate-stderr clap basic.yaml -qq
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "help and version are not assigned" {
  run parse basic.yaml 'printf "[%s][%s]" "${help-unset}" "${version-unset}"'
  [ "$status" -eq 0 ]
  expect_output "[unset][unset]"
}
