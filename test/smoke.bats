setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  MCLI="$DIR/../mcli"
  TMPDIR_ROOT=$(mktemp -d)
  export XDG_CONFIG_HOME="$TMPDIR_ROOT"
}

teardown() {
  rm -rf "$TMPDIR_ROOT"
}

@test "help exits non-zero and prints usage" {
  run "$MCLI" help
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Usage: mcli"
}

@test "list returns two fake services sorted" {
  local tmpdir
  tmpdir=$(mktemp -d)
  pushd "$tmpdir" >/dev/null || exit 1

  mkdir zulu alpha
  touch zulu/docker-compose.yml alpha/docker-compose.yml

  run "$MCLI" list --plain
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" = "alpha" ]
  [ "${lines[1]}" = "zulu" ]

  popd >/dev/null || exit 1
  rm -rf "$tmpdir"
}

@test "disable foo then list marks disabled; enable restores" {
  local tmpdir
  tmpdir=$(mktemp -d)
  pushd "$tmpdir" >/dev/null || exit 1

  mkdir foo
  touch foo/docker-compose.yml

  run "$MCLI" list --json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"name":"foo","enabled":true'

  run "$MCLI" disable foo
  [ "$status" -eq 0 ]

  run "$MCLI" list --json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"name":"foo","enabled":false'

  run "$MCLI" enable foo
  [ "$status" -eq 0 ]

  run "$MCLI" list --json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"name":"foo","enabled":true'

  popd >/dev/null || exit 1
  rm -rf "$tmpdir"
}

@test "start --dry-run prints docker compose up -d and exits 0" {
  local tmpdir
  tmpdir=$(mktemp -d)
  pushd "$tmpdir" >/dev/null || exit 1

  mkdir myservice
  touch myservice/docker-compose.yml

  run "$MCLI" start myservice --dry-run
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "docker compose.*up -d"

  popd >/dev/null || exit 1
  rm -rf "$tmpdir"
}

@test "backup foo --dry-run prints expected sequence" {
  local tmpdir
  tmpdir=$(mktemp -d)
  pushd "$tmpdir" >/dev/null || exit 1

  mkdir foo
  touch foo/docker-compose.yml

  run "$MCLI" backup foo --dry-run
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "docker compose.*down"
  echo "$output" | grep -q "Backing up"

  popd >/dev/null || exit 1
  rm -rf "$tmpdir"
}
