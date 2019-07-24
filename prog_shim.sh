#!/usr/bin/env bash

set -uex pipefail

sudo /usr/bin/apt install -y python3 python3-pip
pip3 install ansible

exit 0
