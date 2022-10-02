FROM ubuntu:20.04
MAINTAINER aztecher

WORKDIR /workspace

RUN apt-get update && apt-get install -y wget curl gcc \
 && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
 && echo 'export PATH=$PATH:$HOME/.cargo/bin' >> /etc/bash.bashrc \
 && wget https://github.com/vmware/differential-datalog/releases/download/v1.2.3/ddlog-v1.2.3-20211213235218-Linux.tar.gz \
 && tar -C /usr/local -xzf ddlog-v1.2.3-20211213235218-Linux.tar.gz  \
 && echo 'export PATH=$PATH:/usr/local/ddlog/bin' >> /etc/bash.bashrc \
 && echo 'export DDLOG_HOME=/usr/local/ddlog' >> /etc/bash.bashrc \
 && rm ddlog-v1.2.3-20211213235218-Linux.tar.gz 
