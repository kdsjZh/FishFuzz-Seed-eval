#!/bin/bash

##
# Pre-requirements:
# - env TARGET: path to target work dir
# - env OUT: path to directory where artifacts are stored
# - env CC, CXX, FLAGS, LIBS, etc...
# - env FUZZER: specify the fuzzer
##

# preinstall 

apt install -y sudo vim ninja-build curl

if [ ! -d "/depot_tools" ]; then 

  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /depot_tools
  export PATH=/depot_tools:$PATH

else
  
  export PATH=/depot_tools:$PATH
  echo "reuse the /depot_tools"

fi 

# v8_fuzzer will generate ~72K functions, expand the limit to 128K
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

# rebuild with lld
if [ ! command -v lld &> /dev/null ]; then 

  echo "lld not enabled, rebuild"
  pushd /llvm/build 
  CFLAGS="" CXXFLAGS="" CC=gcc CXX=g++ \
  cmake -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_PROJECTS="compiler-rt;clang;lld" \
        -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" ../llvm
  make -j && popd

fi

# fetch
if [ ! -d "$TARGET/repo" ]; then

  mkdir $TARGET/repo
  pushd $TARGET/repo
  fetch v8 && cd v8  
  # for this version it's clang-14, we could try later version that use clang before 15.0.0 (bf7f8d6fa6f460bf0a16ffec319cd71592216bf4) 
  git checkout origin/chromium/4903
  gclient sync 
  ./build/install-build-deps.sh
  popd

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
  mkdir -p /fake_clang/bin
  ln -s /Fish++/afl-cc /fake_clang/bin/clang 
  ln -s /Fish++/afl-c++ /fake_clang/bin/clang++ 
  ln -s $(which llvm-ar) /fake_clang/bin/llvm-ar
  export AFL_PATH=/Fish++/

elif [ "$FUZZER" = "aflpp" ]; then 

  mkdir -p /fake_clang/bin
  ln -s /AFL++/afl-cc /fake_clang/bin/clang 
  ln -s /AFL++/afl-c++ /fake_clang/bin/clang++
  ln -s $(which llvm-ar) /fake_clang/bin/llvm-ar
  export AFL_PATH=/AFL++/

fi

pushd $TARGET/repo/v8
# gn args out/$FUZZER
# wget https://raw.githubusercontent.com/kdsjZh/FishFuzz-Seed-eval/main/target/pdfium/config/pdfium.gn.tar.gz 
# tar xzf pdfium.gn.tar.gz -C $PWD/ && mv out/aflpp out/$FUZZER/
echo "use_goma = false" >> args.gn
echo "is_debug = false" >> args.gn
echo "clang_base_path=\"/fake_clang\"" >> args.gn
echo "clang_use_chrome_plugins=false" >> args.gn
mkdir -p "out/$FUZZER" && mv args.gn "out/$FUZZER/"
gn gen "out/$FUZZER" 
# ninja -C "out/$FUZZER" v8_fuzzer
ninja -C "out/$FUZZER" d8
# cp "out/$FUZZER/v8_simple_*_fuzzer" $OUT/$FUZZER/
cp "out/$FUZZER/d8" $OUT/$FUZZER/
cp "out/$FUZZER/snapshot_blob.bin" $OUT/$FUZZER/
rm -r out/$FUZZER/


if [ "$FUZZER" = "ffapp" ]; then

  python3 /Fish++/distance/match_function.py -i $FF_TMP_DIR
  python3 /Fish++/distance/calculate_all_distance.py -i $FF_TMP_DIR

fi

#
unset TMP_DIR FF_TMP_DIR USE_FF_INST CC CXX LIB_FUZZING_ENGINE
rm -r /fake_clang

