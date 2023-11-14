FROM fishfuzz/eval-large:base 

RUN wget https://raw.githubusercontent.com/kdsjZh/FishFuzz-Seed-eval/main/target/wireshark/wireshark.sh && \
    chmod +x /wireshark.sh && \
    FUZZER=ffapp OUT=/out ./wireshark.sh && \
    FUZZER=aflpp OUT=/out ./wireshark.sh 

RUN mkdir -p /out/seeds && \
    find /repo -name "*.pcap" -exec cp {} /out/seeds/ \;

RUN cp -r /out/ffapp /out/ffexp && \
    echo "#!/bin/bash" > /out/ffexp/run.sh  && \
    echo "FF_NO_EXPLOIT=1 TMP_DIR=/out/ffexp/TEMP FUZZSHARK_TARGET=tcp AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 \\" >> /out/ffexp/run.sh  && \
    echo "\t/Fish++/afl-fuzz -i /out/seeds/ -o /work/ -m none -t 1000+ \\" >> /out/ffexp/run.sh  && \
    echo "\t-- /out/ffapp/fuzzshark \$@" >> /out/ffexp/run.sh 

RUN echo "#!/bin/bash" > /out/ffapp/run.sh  && \
    echo "TMP_DIR=/out/ffapp/TEMP FUZZSHARK_TARGET=tcp AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 \\" >> /out/ffapp/run.sh  && \
    echo "\t/Fish++/afl-fuzz -i /out/seeds/ -o /work/ -m none -t 1000+ \\" >> /out/ffapp/run.sh  && \
    echo "\t-- /out/ffapp/fuzzshark \$@" >> /out/ffapp/run.sh 

RUN echo "#!/bin/bash" > /out/aflpp/run.sh  && \
    echo "FUZZSHARK_TARGET=tcp AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 \\" >> /out/aflpp/run.sh  && \
    echo "\t/AFL++/afl-fuzz -i /out/seeds/ -o /work/ -m none -t 1000+ \\" >> /out/aflpp/run.sh  && \
    echo "\t-- /out/aflpp/fuzzshark \$@" >> /out/aflpp/run.sh 

RUN chmod +x /out/*/run.sh

