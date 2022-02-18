#!/usr/bin/env bash

#gcc -shared -o libwrapper.so wrapper.c \
gcc -shared -o wrapper.so wrapper.c \
    -std=c99 \
    -I ~/projects/Chipmunk2D/include/chipmunk \
    -I /usr/include/lua5.1/ \
    -L ~/projects/Chipmunk2D/src \
    -lchipmunk 
