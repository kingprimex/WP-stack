FROM ubuntu:latest
RUN  apt-get update \
  && apt-get install -y dialog wget apt-utils  git  libreadline6 libreadline6-dev unzip
