#!/bin/bash

##
# Pre-requirements:
# - env TARGET: path to target work dir
# - env OUT: path to directory where artifacts are stored
# - env CC, CXX, FLAGS, LIBS, etc...
# - env FUZZER: specify the fuzzer
##

if [ ! -d "$TARGET/repo" ]; then

  git clone https://github.com/FFmpeg/FFmpeg "$TARGET/repo" 
  git -C "$TARGET/repo" checkout fa81de4

else
  
  echo "repo already exits, we assume it's correct"

fi


mkdir -p "$OUT/$FUZZER"

if [ "$FUZZER" = "ffapp" ]; then

  export TMP_DIR="$OUT/$FUZZER/TEMP"
  export FF_TMP_DIR=$TMP_DIR 
  mkdir -p $TMP_DIR
  pushd $TMP_DIR && mkdir cg fid idlog 
  pushd idlog && touch fid targid && popd && popd
  export USE_FF_INST=1 
  export CC=/Fish++/afl-cc
  export CXX=/Fish++/afl-c++

elif [ "$FUZZER" = "aflpp" ]; then 

  export CC=/AFL++/afl-cc
  export CXX=/AFL++/afl-c++

fi

pushd "$TARGET/repo"
./configure --disable-shared --disable-x86asm --cc=$CC --cxx=$CXX && make -j
cp ffmpeg "$OUT/$FUZZER/" && make distclean
popd

if [ "$FUZZER" = "ffapp" ]; then

  python3 /Fish++/distance/match_function.py -i $FF_TMP_DIR
  python3 /Fish++/distance/calculate_all_distance.py -i $FF_TMP_DIR 

fi



# AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 ./afl-fuzz -i /out/seeds/ -o /out/aflpp/corpus -m none -t 1000+ -- /out/aflpp/ffmpeg -y -i @@ test.mp4
# TMP_DIR=/out/ffapp/TEMP AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 ./afl-fuzz -i /out/seeds/ -o /out/ffapp/corpus -m none -t 1000+ -- /out/ffapp/ffmpeg -y -i @@ test.mp4
unset TMP_DIR FF_TMP_DIR USE_FF_INST CC CXX
