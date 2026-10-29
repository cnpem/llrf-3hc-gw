#!/bin/bash

set -e

TESTBENCHES=()
TESTBENCHES+=("RandomResponse")

for testbench in "${TESTBENCHES[@]}"; do
  cd ${testbench}/nvc

  echo "** ${testbench}"
  echo ""

  hdlmake
  make

  echo ""

  cd ../..
done
