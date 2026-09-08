#!/bin/bash
# Integration check in a separate Quickshell instance, with temporary state and
# simulated forecasts. Briefly opens the picker in the current desktop session.
set -euo pipefail
plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d /tmp/rain-radar-test.XXXXXX)
trap 'rm -rf -- "$test_dir"' EXIT
mkdir -p "$test_dir/bin"
cp "$plugin_dir/tests/panel.qml" "$test_dir/shell.qml"
cp "$plugin_dir/tests/curl-fixture" "$test_dir/bin/curl"
chmod +x "$test_dir/bin/curl"
ln -s "$plugin_dir" "$test_dir/Plugin"
for module in Commons Ui services; do
  ln -s "$OMARCHY_PATH/shell/$module" "$test_dir/$module"
done
PATH="$test_dir/bin:$PATH" XDG_STATE_HOME="$test_dir/state" \
  timeout 15s quickshell -p "$test_dir" --no-color
