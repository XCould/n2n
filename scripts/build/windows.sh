#!/bin/bash
cd ../../
git submodules init
git submodules update
mkdir build && cd build
cmake -G "Unix Makefiles" \
  -DCMAKE_VERBOSE_MAKEFILE=ON \
  -DCMAKE_EXE_LINKER_FLAGS="-static" \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DCMAKE_FIND_ROOT_PATH=${MINGW} \
  -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
  -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
  -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
  -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
  -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres \
  -B ./ -S ../
cmake --build ./
