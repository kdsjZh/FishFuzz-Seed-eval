FROM fishfuzz/eval-large:base 

RUN wget https://raw.githubusercontent.com/kdsjZh/FishFuzz-Seed-eval/main/target/pdfium/pdfium.sh && \
    chmod +x /pdfium.sh && \
    FUZZER=ffapp OUT=/out ./pdfium.sh && \
    FUZZER=aflpp OUT=/out ./pdfium.sh 

RUN mkdir -p /out/seeds && \
    git clone https://github.com/strongcourage/fuzzing-corpus && \
    find fuzzing-corpus -name *.pdf -exec cp {} /out/seeds \; && \
    rm -r fuzzing-corpus 

RUN cp -r /out/ffapp /out/ffexp && \
    echo "#!/bin/bash" > /out/ffexp/run.sh  && \
    echo "FF_NO_EXPLOIT=1 TMP_DIR=/out/ffexp/TEMP AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 \\" >> /out/ffexp/run.sh  && \
    echo "\t/Fish++/afl-fuzz -i /out/seeds/ -o /work/ -m none -t 1000+ \\" >> /out/ffexp/run.sh  && \
    echo "\t-- /out/ffexp/pdfium_test @@" >> /out/ffexp/run.sh 

RUN echo "#!/bin/bash" > /out/ffapp/run.sh  && \
    echo "TMP_DIR=/out/ffapp/TEMP AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 \\" >> /out/ffapp/run.sh  && \
    echo "\t/Fish++/afl-fuzz -i /out/seeds/ -o /work/ -m none -t 1000+ \\" >> /out/ffapp/run.sh  && \
    echo "\t-- /out/ffapp/pdfium_test @@" >> /out/ffapp/run.sh 

RUN echo "#!/bin/bash" > /out/aflpp/run.sh  && \
    echo "AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 \\" >> /out/aflpp/run.sh  && \
    echo "\t/AFL++/afl-fuzz -i /out/seeds/ -o /work/ -m none -t 1000+ \\" >> /out/aflpp/run.sh  && \
    echo "\t-- /out/aflpp/pdfium_test @@" >> /out/aflpp/run.sh 

RUN chmod +x /out/*/run.sh

