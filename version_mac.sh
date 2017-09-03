#!/usr/bin/env bash
plutil -replace CFBundleShortVersionString -string $1 "macOS/Info.plist"
plutil -replace CFBundleVersion -string $1 "macOS/Info.plist"
