
## 

This repository includes more complex targets for evaluating FishFuzz seed selection.

### Build Docker Image

```bash

cd /path/to/repo

# build the base image with aflpp/ffapp
docker build -t fishfuzz/eval-large:base .

# build the target Wireshark (dissector fuzzshark)
docker build -t fishfuzz/eval-large:wireshark target/wireshark

# build the target FFmpeg (no libfuzzer driver, fuzz ffmpeg)
docker build -t fishfuzz/eval-large:ffmpeg target/ffmpeg

# build the target PDFium (chromium PDF component, with v8 and xfa enabled)
docker build -t fishfuzz/eval-large:pdfium target/pdfium

# build the target v8 (chromium js engine)
docker build -t fishfuzz/eval-large:v8 target/v8

```

### Usage

```bash

export WORKDIR=$PWD/work
export RESULT=./results
export TIMEOUT=24h

mkdir -p "$WORKDIR"
# if you have enough memory, mount tmpfs to allow in-memory fuzzing
sudo mount -t tmpfs -o size=50g,uid=$(id -u),gid=$(id -g) \
        tmpfs "$WORKDIR"

# run python script to generate the command 
# the benchmark's name is hardcoded, edit the script to change for now
python3 scripts/generate_docker_cmd.py -w $WORKDIR -t $TIMEOUT -n 5
# or some manual alteratives
# docker run -dt \
#   --cpuset-cpu 0 \
#   --name test_wireshark_aflpp_0 \
#   --volume="$WORKDIR/wireshark/aflpp/0":/out/ \
#   fishfuzz/eval-large:wireshark \
#   "/out/aflpp/run.sh"

# now we didn't embed timeout into the script, so kill it after 24h manually
# copy the results to results folder
mkdir $RESULT && python3 scripts/extract_results.py -r $RESULT -n 5

docker rm -f $(docker ps -q)  

# after we're done, plot based on the aflpp's plug-in log 
# ffapp have additional function instrumentation, but is shared via another shm (not the trace_bits)
# therefore the logs are equivalent, ofcourse we can replay the seeds with the llvm-cov as well
# by default the script will plot the best/worst in dashed line and the average. 
# aflpp is baseline AFL++, ffapp is full FishFuzz, ffexp is FishFuzz-noexploit (AFL++ algorithm + FishFuzz exploration)
python3 scripts/plot_results.py -r $RESULT -n 5 -t cov -b wireshark


# after the campaign, umount the disk
sudo umount $WORKDIR
```

### results

We evaluate FishFuzz against AFL++ on 2 server equipped with Xeon Gold 5218 and 64GB memory. 
The 10 round's results are available at https://drive.google.com/file/d/1Ojs-YEwniTmy_qLX--bndVZZ-o58qUR1/view?usp=sharing.