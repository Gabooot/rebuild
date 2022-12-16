#!/bin/sh
echo -ne '\033c\033]0;rebuild\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/buggy.x86_64" "$@"
