#!/bin/bash
#this is a test-cmd for safe_cmd.sh

echo "hello, world"
sleep 4 
kill $PPID
echo "just killed dad, world, now i'll be going"

