#!/bin/bash

while read line; do
    if [[ $line == *"mapped ("* ]]; then
        tmp=${line#*mapped (}
        res=${tmp%\%*}
        echo -e "$res"
    fi
done