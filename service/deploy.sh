#!/bin/bash

set -e

swift build -c release

cp pm2.config.json .build/x86_64-unknown-linux-gnu/release