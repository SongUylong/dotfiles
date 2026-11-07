#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
swiftc -O -o menubar main.swift
echo "built -> $PWD/menubar"
