#########################################################################
##
##    Convert All CUDA codes to HIP codes using hipify-clang tool
##
#########################################################################

# Usage:
# 1. `convertAllCuda` (non-recursive) only deals with the *.cu in current directory
# 2. `convertAllCuda -r` deals with all *.cu recursively. Use it carefully
# 3. `convertAllCuda SINGLE_FILE` deals with the certain CUDA code

# Note:
# A symbolic link of this script was created to /usr/bin/convertAllCuda 
# during the docker build, so just use `convertAllCuda` for convenience.

#!/bin/bash
 
if [ ! "$1" ];then
  fileList=`find . -maxdepth 1 -type f | grep -e *.cu`
elif [ "$1" = "-r" ];then
  fileList=`find . -name '*'.cu`
elif [ ! -f "$1" ];then
  fileList=$1
fi

for file in $fileList
do
  prefix=${file%%.cu}
  echo -e "\033[32m $file -> $prefix.hip.cpp \033[0m"
  hipify-clang $file \
    --cuda-path=/usr/local/cuda \
    -I /usr/local/cuda/samples/common/inc \
    -o ${prefix}.hip.cpp
done
