#!/usr/bin/env bash

for line in {0..11}; do for col in {0..19}; do code=$(( $col * 12 + $line + 16 )); printf $'\e[38;05;%dm %03d' $code $code ;done; echo ;done
