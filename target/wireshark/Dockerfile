FROM fishfuzz/eval-large:base 

RUN wget https://raw.githubusercontent.com/kdsjZh/FishFuzz-Seed-eval/main/target/wireshark/wireshark.sh && \
    chmod +x /wireshark.sh && \
    FUZZER=ffapp OUT=/out ./wireshark.sh && \
    FUZZER=aflpp OUT=/out ./wireshark.sh 

RUN mkdir -p /out/seeds && \
    find /repo -name "*.pcap" -exec cp {} /out/seeds/ \;

RUN echo "#!/bin/bash" > /out/ffapp/run.sh  && \
    echo "TMP_DIR=/out/ffapp/TEMP FUZZSHARK_TARGET=tcp AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 \\" >> /out/ffapp/run.sh  && \
    echo "\t/Fish++/afl-fuzz -i /out/seeds/ -o /out/ffapp/corpus -m none -t 1000+ \\" >> /out/ffapp/run.sh  && \
    echo "\t-- /out/ffapp/fuzzshark \$@" >> /out/ffapp/run.sh 

RUN echo "#!/bin/bash" > /out/aflpp/run.sh  && \
    echo "FUZZSHARK_TARGET=tcp AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 \\" >> /out/aflpp/run.sh  && \
    echo "\t/AFL++/afl-fuzz -i /out/seeds/ -o /out/aflpp/corpus -m none -t 1000+ \\" >> /out/aflpp/run.sh  && \
    echo "\t-- /out/aflpp/fuzzshark \$@" >> /out/aflpp/run.sh 

RUN chmod +x /out/*/run.sh

