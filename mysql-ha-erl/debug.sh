#!/bin/bash

make clean
make debug

erl -name 'master@python.seriema-systems.com' &
erl -name 'slave@python.seriema-systems.com' -s debugger 
