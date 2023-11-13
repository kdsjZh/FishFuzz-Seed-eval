FROM ubuntu:22.04

# for binutils & llvm-15 dependencies
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC \
    apt install git gcc g++ make cmake wget \
        libgmp-dev libmpfr-dev texinfo bison python3 -y 

# build clang-15 with gold plugin
RUN apt install -y lsb-release wget software-properties-common

# build clang-15
RUN mkdir -p /build && \
    git clone \
        https://github.com/llvm/llvm-project /llvm && \
    cd /llvm/ && git checkout bf7f8d6fa6f460bf0a16ffec319cd71592216bf4 && \
    wget https://github.com/kdsjZh/FishFuzz/raw/no_asan/FF_AFL++/asan_patch/llvm-15.0/llvm-15-asan.diff && \
    wget https://github.com/kdsjZh/FishFuzz/raw/no_asan/FF_AFL++/asan_patch/llvm-15.0/FishFuzzAddressSanitizer.cpp && \
    sed -i '110d' llvm/lib/Transforms/Instrumentation/FishFuzzAddressSanitizer.cpp && \
    git apply llvm-15-asan.diff && \
    mv FishFuzzAddressSanitizer.cpp llvm/lib/Transforms/Instrumentation/ && \
    cd /llvm/ && mkdir build && cd build &&\
    CFLAGS="" CXXFLAGS="" CC=gcc CXX=g++ \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DLLVM_ENABLE_PROJECTS="compiler-rt;clang" \
          -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" ../llvm && \
    make -j$(nproc) 

ENV PATH="/llvm/build/bin:${PATH}"
ENV LD_LIBRARY_PATH="/llvm/build/lib/x86_64-unknown-linux-gnu/"


# for fishfuzz dependencies
RUN apt-get update && \
    apt-get install libboost-all-dev libjsoncpp-dev libgraphviz-dev \
    pkg-config libglib2.0-dev gcc-$(gcc --version|head -n1|sed 's/\..*//'|sed 's/.* //')-plugin-dev -y

RUN apt install python3-pip -y && \
    pip3 install networkx pydot r2pipe

RUN git clone https://github.com/kdsjZh/FishFuzz \
              --branch no_asan /ff_repo && \
    mv /ff_repo/FF_AFL++ /Fish++ && rm -r /ff_repo 

RUN cd /Fish++/ && \
    NO_NYX=1 make source-only && chmod +x scripts/*.py 

RUN git clone https://github.com/AFLplusplus/AFLplusplus /AFL++ && \
    cd /AFL++ && git checkout 40947508037b874020c8dd1251359fecaab04b9d && \
    NO_NYX=1 NO_X86=1 make source-only 

