#!/usr/bin/env bash

cd "$(dirname "$0")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -d src ]; then
  git clone https://github.com/fracz/supla-core.git --single-branch --branch supla-filesensors src > /dev/null
  ln -s "$BIN_FILENAME" ./supla-filesensors
fi

cd src/supla-dev/Release && git pull >/dev/null && make all >/dev/null
cd "$(dirname "$0")"

if [ ! -f supla-filesensors ]; then
  ln -s src/supla-dev/Release/supla-filesensors supla-filesensors
fi

echo -e "${GREEN}OK!${NC}"
./supla-filesensors -v

if [ ! -f supla-filesensors.cfg ]; then
  cp supla-filesensors.cfg.sample supla-filesensors.cfg
  echo -e "${YELLOW}Sample configuration has been created for you (${NC}supla-filesensors.cfg${YELLOW})${NC}"
  echo -e "${YELLOW}Adjust it to your needs before launching.${NC}"
fi
