#!/bin/bash

export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:/usr/local/ddlog/bin
export DDLOG_HOME=/usr/local/ddlog

ddlog -i playpen.dl
cd playpen_ddlog && cargo build --release && cd ../
./playpen_ddlog/target/release/playpen_cli < playpen.dat

rm -rf playpen_ddlog
