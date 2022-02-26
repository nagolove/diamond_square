#!/usr/bin/env bash

#gcc -shared -o libwrapper.so wrapper.c \
gcc -shared -o wrapper.so wrapper.c \
    -g3 \
    -std=c99 \
    -I ~/projects/Chipmunk2D/include/ \
    -I /usr/include/lua5.1/ \
    -L ~/projects/Chipmunk2D/src \
    -fPIC \
    -lchipmunk \
    -lluajit-5.1 
#echo $?
