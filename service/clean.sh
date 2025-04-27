#!/bin/bash

set -e

pm2 delete whooshing.module-authentication
/root/projects/whooshing-module-manager/wsm-ctl/.build/x86_64-unknown-linux-gnu/debug/wsm stop-pgservice whooshing.module-authentication -p 5
/root/projects/whooshing-module-manager/wsm-ctl/.build/x86_64-unknown-linux-gnu/debug/wsm delete-pgservice whooshing.module-authentication -p 5
/root/projects/whooshing-module-manager/wsm-ctl/.build/x86_64-unknown-linux-gnu/debug/wsm delete-module whooshing.module-authentication