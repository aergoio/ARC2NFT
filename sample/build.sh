#!/bin/bash

echo > output.lua

process_file() {
  cat ../src/ARC2-$1.lua >> output.lua
}

process_file "Core"
process_file "Mintable"
process_file "Burnable"
process_file "Approval"
process_file "Metadata"
process_file "Searchable"
process_file "Pausable"
process_file "Blacklist"

cat mintable_arc2.lua >> output.lua
