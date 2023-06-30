#!/usr/bin/env bash

set -euo pipefail
SOURCE_BIN=/nbi/software/testing/bin/nbi-slurm
DEST_DIR=/nbi/software/testing/
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

if [[ ! -e $DEST_DIR ]]; then

  echo -e "\e[31m---- ERROR ----\e[0m"
  echo "Destination directory $DEST_DIR does not exist"
  exit 1
fi
echo "#!/bin/bash" > $SOURCE_BIN
echo "export PATH=\"\$PATH\":$DEST_DIR/NBI-Slurm/bin" >> $SOURCE_BIN
echo "export PERL5LIB=\"$DEST_DIR\"/NBI-Slurm/lib:\$PERL5LIB" >> $SOURCE_BIN


mkdir -p $DEST_DIR/NBI-Slurm/
cp -vr "$SOURCE_DIR"/* "$DEST_DIR"/NBI-Slurm/
chmod +x "$DEST_DIR"/NBI-Slurm/bin/*

echo "Installation complete to $DEST_DIR/NBI-Slurm"
