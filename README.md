
## 

This repository includes more complex targets for evaluating FishFuzz seed selection.

### Build Docker Image

```bash

cd $REPO

# build the base image with aflpp/ffapp
docker build -t fishfuzz/eval-large:base .

# build the target wireshark (dissector fuzzshark)
docker build -t fishfuzz/eval-large:wireshark target/wireshark

```

### Usage

```bash

export WORKDIR=./work
export TIMEOUT=24h

mkdir -p "$WORKDIR"
# if you have enough memory, mount tmpfs to allow in-memory fuzzing
sudo mount -t tmpfs -o size=50g,uid=$(id -u),gid=$(id -g) \
        tmpfs "$WORKDIR"

# run python script to generate the command 
python3 scripts/generate_docker_cmd.py -w $WORKDIR -t $TIMEOUT -n 5
# or some manual alteratives
docker run -dt \
  --cpuset-cpu 0 \
  --name test_wireshark_aflpp_0 \
  --volume="$WORKDIR/wireshark/aflpp/0":/out/ \
  fishfuzz/eval-large:wireshark \
  "timeout -s KILL --preserve-status $TIMEOUT /out/aflpp/run.sh"

docker run -dt \
  --cpuset-cpu 1 \
  --name test_wireshark_ffapp_0 \
  --volume="$WORKDIR/wireshark/ffapp/0":/out/ \
  fishfuzz/eval-large:wireshark \
  "timeout -s KILL --preserve-status $TIMEOUT /out/ffapp/run.sh"

```
