#!/bin/bash
cd $(dirname "$0")
source test-utils.sh

# Template specific tests
check "distro" lsb_release -c
check "git" git --version
check "gh" gh --version
check "node" node --version
check "npm" npm --version
check "opencode" opencode --version
check "non-root user" test "$(id -u)" != "0"
check "no host docker socket" test ! -e /var/run/docker.sock

# Report result
reportResults
