load test_helper

@test "default_values are joined and survive eval" {
  run parse clap4.yaml 'printf "[%s]" "$preset"'
  [ "$status" -eq 0 ]
  expect_output "[it's
b]"
}

@test "num_args 0..=1 uses default_missing_value for a bare flag" {
  run parse clap4.yaml 'printf "[%s]" "$color"'
  [ "$status" -eq 0 ]
  expect_output "[never]"

  run parse clap4.yaml 'printf "[%s]" "$color"' --color
  [ "$status" -eq 0 ]
  expect_output "[auto]"

  run parse clap4.yaml 'printf "[%s]" "$color"' --color always
  [ "$status" -eq 0 ]
  expect_output "[always]"
}

@test "num_args requires exactly that many values" {
  run parse clap4.yaml 'printf "[%s]" "$pair"' --pair x y
  [ "$status" -eq 0 ]
  expect_output "[x
y]"

  run --separate-stderr clap clap4.yaml --pair x
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "num_args range accepts its bounds and rejects fewer" {
  run parse clap4.yaml 'printf "[%s]" "$item"' --item a b c
  [ "$status" -eq 0 ]
  expect_output "[a
b
c]"

  run --separate-stderr clap clap4.yaml --item a
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "number_of_values still sets an exact count" {
  run parse clap4.yaml 'printf "[%s]" "$legacy"' --legacy a b
  [ "$status" -eq 0 ]
  expect_output "[a
b]"
}

@test "min_values and max_values bound the accepted values" {
  run parse clap4.yaml 'printf "[%s]" "$bounded"' --bounded a b
  [ "$status" -eq 0 ]
  expect_output "[a
b]"

  run --separate-stderr clap clap4.yaml --bounded a b c
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "action append joins repeated options" {
  run parse clap4.yaml 'printf "[%s]" "$tag"' --tag a --tag "b c"
  [ "$status" -eq 0 ]
  expect_output "[a
b c]"
}

@test "value_delimiter splits one option and keeps quotes" {
  run parse clap4.yaml 'printf "[%s]" "$hosts"' --hosts "a'b,c"
  [ "$status" -eq 0 ]
  expect_output "[a'b
c]"
}

@test "bool values are printed as 1 and 0" {
  run parse clap4.yaml 'printf "[%s]" "$on"' --on yes
  [ "$status" -eq 0 ]
  expect_output "[1]"

  run parse clap4.yaml 'printf "[%s]" "$on"' --on no
  [ "$status" -eq 0 ]
  expect_output "[0]"

  run --separate-stderr clap clap4.yaml --on maybe
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "numeric parsers accept their range and reject the rest" {
  run parse clap4.yaml 'printf "[%s][%s]" "$small" "$ratio"' --small 255 --ratio 1.5
  [ "$status" -eq 0 ]
  expect_output "[255][1.5]"

  run parse clap4.yaml 'printf "[%s]" "$offset"' --offset -3
  [ "$status" -eq 0 ]
  expect_output "[-3]"

  run --separate-stderr clap clap4.yaml --small 256
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "requires rejects a missing partner" {
  run --separate-stderr clap clap4.yaml --name a
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"--host <host>"* ]]

  run parse clap4.yaml 'printf "[%s][%s]" "$name" "$host"' --name a --host h
  [ "$status" -eq 0 ]
  expect_output "[a][h]"
}

@test "an alias assigns the canonical variable" {
  run parse clap4.yaml 'printf "[%s][%s]" "$host" "${hostname-unset}"' --hostname h
  [ "$status" -eq 0 ]
  expect_output "[h][unset]"
}

@test "ignore_case accepts another case of a possible value" {
  run parse clap4.yaml 'printf "[%s]" "$mode"' --mode Herbivore
  [ "$status" -eq 0 ]
  expect_output "[Herbivore]"

  run --separate-stderr clap clap4.yaml --mode plant
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "allow_hyphen_values accepts a leading dash" {
  run parse clap4.yaml 'printf "[%s]" "$msg"' --msg -n
  [ "$status" -eq 0 ]
  expect_output "[-n]"

  run --separate-stderr clap clap4.yaml --host -n
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "conflicts_with rejects the two options together" {
  run --separate-stderr clap clap4.yaml --json --yaml
  [ "$status" -eq 1 ]
  [ -z "$output" ]

  run parse clap4.yaml 'printf "[%s][%s]" "$json" "$yaml"' --json
  [ "$status" -eq 0 ]
  expect_output "[1][0]"
}

@test "a group given as a list is mutually exclusive" {
  run --separate-stderr clap group.yaml --json --yaml
  [ "$status" -eq 1 ]
  [ -z "$output" ]

  run parse group.yaml 'printf "[%s][%s]" "$json" "$yaml"' --yaml
  [ "$status" -eq 0 ]
  expect_output "[0][1]"
}

@test "global options are visible from either side of a subcommand" {
  run parse clap4.yaml 'printf "[%s][%s][%s]" "$verbose" "$config" "$1"' -v --config example.com ls
  [ "$status" -eq 0 ]
  expect_output "[1][example.com][ls]"

  run parse clap4.yaml 'printf "[%s][%s][%s]" "$verbose" "$config" "$1"' ls -vv
  [ "$status" -eq 0 ]
  expect_output "[2][localhost][ls]"
}

@test "args and subcommands may be maps" {
  run parse map.yaml 'printf "[%s][%s][%s]" "$host" "$entity" "$1"' --host h ls item
  [ "$status" -eq 0 ]
  expect_output "[h][item][ls]"
}

@test "an external subcommand keeps its words" {
  run parse external.yaml 'printf "[%s][%s][%s]" "$1" "$2" "$3"' plugin "it's" "b c"
  [ "$status" -eq 0 ]
  expect_output "[plugin][it's][b c]"
}

@test "default_value and default_values together are rejected" {
  run --separate-stderr clap4shell <<'YAML'
name: demo
args:
  - host:
      long: host
      default_value: a
      default_values: [b]
YAML
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"both default_value and default_values"* ]]
}

@test "number_of_values combined with min_values is rejected" {
  run --separate-stderr clap4shell <<'YAML'
name: demo
args:
  - item:
      long: item
      number_of_values: 2
      min_values: 1
YAML
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"combines number_of_values with min_values"* ]]
}
