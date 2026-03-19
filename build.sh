#!/bin/bash
curl -fsSL https://github.com/lune-org/lune/releases/download/v0.8.9/lune-0.8.9-linux-x86_64.zip -o lune.zip
unzip lune.zip
chmod +x lune
mkdir -p bin
mv lune bin/
export PATH="$PWD/bin:$PATH"
