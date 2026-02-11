#!/bin/sh
cd "$(dirname "$0")"

rm *.odin
odin run bindgen/src -- .
sed -ni '/^package/,$p' *.odin
