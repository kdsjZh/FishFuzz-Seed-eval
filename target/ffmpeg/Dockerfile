FROM fishfuzz/eval-large:base 

RUN wget https://raw.githubusercontent.com/kdsjZh/FishFuzz-Seed-eval/main/target/ffmpeg/ffmpeg.sh && \
    chmod +x /ffmpeg.sh && \
    FUZZER=ffapp OUT=/out ./ffmpeg.sh && \
    FUZZER=aflpp OUT=/out ./ffmpeg.sh 

RUN mkdir -p /out/seeds && \
    find /repo -name *.mp4 -exec cp {} /out/seeds \; && \
    find /repo -name *.mov -exec cp {} /out/seeds \; && \
    find /repo -name *.wav -exec cp {} /out/seeds \; && \
    find /Fish++ -name *.mp4 -exec cp {} /out/seeds \;

RUN cp -r /out/ffapp /out/ffexp && \
    echo "#!/bin/bash" > /out/ffexp/run.sh  && \
    echo "FF_NO_EXPLOIT=1 TMP_DIR=/out/ffexp/TEMP AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 \\" >> /out/ffexp/run.sh  && \
    echo "\t/Fish++/afl-fuzz -i /out/seeds/ -o /work/ -m none -t 1000+ \\" >> /out/ffexp/run.sh  && \
    echo "\t-- /out/ffexp/ffmpeg -y -i @@ test.mp4" >> /out/ffexp/run.sh 

RUN echo "#!/bin/bash" > /out/ffapp/run.sh  && \
    echo "TMP_DIR=/out/ffapp/TEMP AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 \\" >> /out/ffapp/run.sh  && \
    echo "\t/Fish++/afl-fuzz -i /out/seeds/ -o /work/ -m none -t 1000+ \\" >> /out/ffapp/run.sh  && \
    echo "\t-- /out/ffapp/ffmpeg -y -i @@ test.mp4" >> /out/ffapp/run.sh 

RUN echo "#!/bin/bash" > /out/aflpp/run.sh  && \
    echo "AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_SKIP_CPUFREQ=1 AFL_NO_AFFINITY=1 \\" >> /out/aflpp/run.sh  && \
    echo "\t/AFL++/afl-fuzz -i /out/seeds/ -o /work/ -m none -t 1000+ \\" >> /out/aflpp/run.sh  && \
    echo "\t-- /out/aflpp/ffmpeg -y -i @@ test.mp4" >> /out/aflpp/run.sh 

RUN chmod +x /out/*/run.sh

