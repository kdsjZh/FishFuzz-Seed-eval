
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
