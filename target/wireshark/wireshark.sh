#!/bin/bash

##
# Pre-requirements:
# - env TARGET: path to target work dir
# - env OUT: path to directory where artifacts are stored
# - env CC, CXX, FLAGS, LIBS, etc...
# - env FUZZER: specify the fuzzer
##

# preinstall 

apt install gnupg lsb-release software-properties-common pkg-config \
        python3-pip libgtk-3-dev unzip pax-utils file cpio ninja-build cmake \
        libgcrypt20-dev libc-ares-dev libpcre2-dev flex inotify-tools \
        libboost-dev -y

# fetch

if [ ! -d "$TARGET/repo" ]; then

  git clone https://gitlab.com/wireshark/wireshark "$TARGET/repo" 
  git -C "$TARGET/repo" checkout 36a9f423

else
  
  echo "repo already exits, we assume it's correct"

fi

## ~94K total functions, therefore need overwrite the FUNC_SIZE from 64K to 128K
if [ "$FUZZER" = "ffapp" ]; then

  pushd /llvm
  sed -i 's/#define FUNC_SIZE_POW2 16/#define FUNC_SIZE_POW2 17/'  llvm/lib/Transforms/Instrumentation/FishFuzzAddressSanitizer.cpp
  pushd build && make -j && popd 
  popd 
  pushd /Fish++ 
  sed -i 's/#define FUNC_SIZE_POW2 16/#define FUNC_SIZE_POW2 17/' include/config.h 
  make clean && NO_NYX=1 NO_X86=1 make source-only 
  popd 
  echo "[+] Successfully Reset FUNC_SIZE!"

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

if [ "$FUZZER" = "ffapp" ]; then

  export LIB_FUZZING_ENGINE="/Fish++/utils/aflpp_driver/aflpp_driver.o"

elif [ "$FUZZER" = "aflpp" ]; then

  export LIB_FUZZING_ENGINE="/AFL++/libAFLDriver.a"
  
fi

pushd "$TARGET/repo"


unset CFLAGS CXXFLAGS LDFLAGS LIBS
mkdir build && cd build

# export LIB_FUZZING_ENGINE="$FUZZER/src/libfuzzer.a"
# custom_flags='-DCUSTOM_FUZZ=ON'
cmake -G Ninja .. \
    -DENABLE_STATIC=ON \
    -DOSS_FUZZ=ON \
    -DINSTRUMENT_DISSECTORS_ONLY=ON \
    -DBUILD_fuzzshark=ON \
    -DBUILD_wireshark=OFF \
    -DBUILD_sharkd=OFF \
    -DENABLE_PCAP=OFF \
    -DENABLE_ZLIB=OFF \
    -DENABLE_MINIZIP=OFF \
    -DENABLE_LZ4=OFF \
    -DENABLE_BROTLI=OFF \
    -DENABLE_SNAPPY=OFF \
    -DENABLE_ZSTD=OFF \
    -DENABLE_NGHTTP2=OFF \
    -DENABLE_NGHTTP3=OFF \
    -DENABLE_LUA=OFF \
    -DENABLE_SMI=OFF \
    -DENABLE_GNUTLS=OFF \
    -DENABLE_NETLINK=OFF \
    -DENABLE_KERBEROS=OFF \
    -DENABLE_SBC=OFF \
    -DENABLE_SPANDSP=OFF \
    -DENABLE_BCG729=OFF \
    -DENABLE_AMRNB=OFF \
    -DENABLE_ILBC=OFF \
    -DENABLE_LIBXML2=OFF \
    -DENABLE_OPUS=OFF \
    -DENABLE_SINSP=OFF

ninja fuzzshark
cp run/fuzzshark "$OUT/$FUZZER"
cd .. && rm -r build/
popd




if [ "$FUZZER" = "ffapp" ]; then

  python3 /Fish++/distance/match_function.py -i $FF_TMP_DIR
  python3 /Fish++/distance/calculate_all_distance.py -i $FF_TMP_DIR

fi

#
unset TMP_DIR FF_TMP_DIR USE_FF_INST CC CXX LIB_FUZZING_ENGINE
