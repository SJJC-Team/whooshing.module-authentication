#!/bin/bash

set -e

./deploy.sh

/root/projects/whooshing-module-manager/wsm-ctl/.build/x86_64-unknown-linux-gnu/debug/wsm '/root/projects/whooshing.module-authentication/service/configure.yaml'