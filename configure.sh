#!/usr/bin/env bash

cd "$(dirname "$0")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ARCH_NAME="$(uname -s)-$(uname -m)"
BIN_FILENAME="bin/supla-filesensors-${ARCH_NAME}"

if [ ! -f $BIN_FILENAME ]; then
  echo -e "${RED}Could not find binary for your system (${ARCH_NAME}).${NC}"
  echo "Consider building it yourself from sources and sending me a Pull Request with it."
  exit 1
fi

if [ ! -f supla-filesensors ]; then
  ln -s "$BIN_FILENAME" ./supla-filesensors
fi

echo -e "${GREEN}OK!${NC}"

if [ ! -f supla-filesensors.cfg ]; then
  cp supla-filesensors.cfg.sample supla-filesensors.cfg
  echo -e "${YELLOW}Sample configuration has been created for you (${NC}supla-filesensors.cfg${YELLOW})${NC}"
  echo -e "${YELLOW}Adjust it to your needs before launching.${NC}"
fi
