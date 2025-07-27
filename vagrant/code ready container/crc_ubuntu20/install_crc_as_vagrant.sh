#!/bin/bash
set -e

# CRC config et start
crc config set pull-secret-file /home/vagrant/pull-secret.txt
crc config set consent-telemetry yes
crc config set skip-check-root-user true
crc setup
crc start
