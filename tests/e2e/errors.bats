load test_helper

@test "unknown option fails without stdout" {
  run --separate-stderr clap basic.yaml --bogus
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"unexpected argument '--bogus'"* ]]
}

@test "option missing its value fails" {
  run --separate-stderr clap basic.yaml --host
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"a value is required"* ]]
}

@test "missing required option fails" {
  run --separate-stderr clap required.yaml
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"--host <host>"* ]]
}

@test "required option is accepted" {
  run parse required.yaml 'printf "[%s]" "$host"' --host h
  [ "$status" -eq 0 ]
  expect_output "[h]"
}

@test "invalid YAML fails" {
  run --separate-stderr clap4shell <<< 'args: ['
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == "clap4shell: "* ]]
}

@test "unknown field in the spec fails" {
  run --separate-stderr clap4shell <<< $'name: t\nargs:\n  - a:\n      bogus: true'
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"unknown field \`bogus\`"* ]]
}

@test "--help prints usage to stderr and fails" {
  run --separate-stderr clap basic.yaml --help
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"Usage:"* ]]
}

@test "--version prints the version to stderr and fails" {
  run --separate-stderr clap basic.yaml --version
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"basic 1.2.3"* ]]
}
