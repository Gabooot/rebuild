#!/bin/sh
echo -ne '\033c\033]0;fourpointoh\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/fourpointoh.x86_64" "$@"
