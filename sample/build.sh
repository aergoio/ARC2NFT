#!/bin/bash

echo >> output.lua

process_file() {
  cat ../src/ARC2-$1.lua >> output.lua
}

process_file "Core"
process_file "Burnable"
process_file "Mintable"
process_file "Pausable"
process_file "Blacklist"
process_file "Approval"

cat mintable_arc2.lua >> output.lua
