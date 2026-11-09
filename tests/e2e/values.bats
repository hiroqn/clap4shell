load test_helper

@test "option value is assigned" {
  run parse basic.yaml 'printf "[%s]" "$host"' --host example.com
  [ "$status" -eq 0 ]
  expect_output "[example.com]"
}

@test "option value with = is assigned" {
  run parse basic.yaml 'printf "[%s]" "$host"' --host=example.com
  [ "$status" -eq 0 ]
  expect_output "[example.com]"
}

@test "absent option leaves the variable unset" {
  run parse basic.yaml 'printf "[%s]" "${host-unset}"'
  [ "$status" -eq 0 ]
  expect_output "[unset]"
}

@test "default_value is used when the option is absent" {
  run parse basic.yaml 'printf "[%s]" "$port"'
  [ "$status" -eq 0 ]
  expect_output "[80]"
}

@test "default_value is overridden by the option" {
  run parse basic.yaml 'printf "[%s]" "$port"' --port 8080
  [ "$status" -eq 0 ]
  expect_output "[8080]"
}

@test "multiple_occurrences option joins values with newlines" {
  run parse basic.yaml 'printf "[%s]" "$tag"' --tag a --tag 'b c'
  [ "$status" -eq 0 ]
  expect_output "[a
b c]"
}

@test "positional arguments are assigned" {
  run parse basic.yaml 'printf "[%s][%s]" "$cmd" "$rest"' run x 'y z'
  [ "$status" -eq 0 ]
  expect_output "[run][x
y z]"
}

@test "values after -- are positional" {
  run parse basic.yaml 'printf "[%s][%s]" "$cmd" "$rest"' -- --host -v
  [ "$status" -eq 0 ]
  expect_output "[--host][-v]"
}

@test "possible_values accepts a listed value" {
  run parse basic.yaml 'printf "[%s]" "$mode"' --mode omnivore
  [ "$status" -eq 0 ]
  expect_output "[omnivore]"
}

@test "possible_values rejects an unlisted value" {
  run --separate-stderr clap basic.yaml --mode vegan
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"possible values: herbivore, carnivore, omnivore"* ]]
}

@test "env provides the value when the option is absent" {
  E2E_TOKEN=from-env run parse basic.yaml 'printf "[%s]" "$token"'
  [ "$status" -eq 0 ]
  expect_output "[from-env]"
}

@test "option takes precedence over env" {
  E2E_TOKEN=from-env run parse basic.yaml 'printf "[%s]" "$token"' --token from-arg
  [ "$status" -eq 0 ]
  expect_output "[from-arg]"
}
