load test_helper

@test "no subcommand leaves positional parameters empty" {
  run parse subcommands.yaml 'echo "$# [$*]"'
  [ "$status" -eq 0 ]
  expect_output "0 []"
}

@test "subcommand is bound to positional parameters" {
  run parse subcommands.yaml 'echo "$# [$1]"' ls
  [ "$status" -eq 0 ]
  expect_output "1 [ls]"
}

@test "subcommand and parent arguments are both assigned" {
  run parse subcommands.yaml 'printf "[%s][%s][%s]" "$verbose" "$all" "$entity"' -v ls -a e1 e2
  [ "$status" -eq 0 ]
  expect_output "[1][1][e1
e2]"
}

@test "nested subcommands are bound in order" {
  run parse subcommands.yaml 'echo "$# [$1] [$2] [$name] [$url]"' remote add origin https://example.com
  [ "$status" -eq 0 ]
  expect_output "2 [remote] [add] [origin] [https://example.com]"
}

@test "missing required argument of a nested subcommand fails" {
  run --separate-stderr clap subcommands.yaml remote add origin
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"<url>"* ]]
}
