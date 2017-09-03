#!/usr/bin/env bash
plutil -replace CFBundleShortVersionString -string $1 "iOS/Info.plist"
