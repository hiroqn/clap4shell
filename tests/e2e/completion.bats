load test_helper

@test "completion -o writes a script for each shell" {
  for shell in bash zsh fish elvish powershell; do
    clap basic.yaml clap4shell-completion "$shell" -o "$BATS_TEST_TMPDIR/$shell"
    [ -s "$BATS_TEST_TMPDIR/$shell" ]
  done
}

@test "completion without -o prints the same script through eval" {
  for shell in bash zsh fish elvish powershell; do
    clap basic.yaml clap4shell-completion "$shell" -o "$BATS_TEST_TMPDIR/expected"
    run parse basic.yaml 'echo unreachable' clap4shell-completion "$shell"
    [ "$status" -eq 0 ]
    expect_output "$(cat "$BATS_TEST_TMPDIR/expected")"
  done
}

@test "completion rejects an unknown shell" {
  run --separate-stderr clap basic.yaml clap4shell-completion tcsh
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}
