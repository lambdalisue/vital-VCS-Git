#!/bin/bash
echo "Input your name: "
read NAME
echo "Hello $NAME and good bye."
if [[ $NAME == "BUG" ]]; then
    exit 1
fi
