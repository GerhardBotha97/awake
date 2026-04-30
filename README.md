# awake

Keep your Mac awake — native macOS menu bar app. Like [nosleep.page](https://nosleep.page), but lives in your menu bar.

Native Swift/SwiftUI app. 139KB binary. No deadlocks, no CGo, no frameworks.

## Build

```bash
./build.sh
```

Requires Xcode command line tools (macOS 13+).

## Run

```bash
open Awake.app
```

## Install

```bash
cp -r Awake.app /Applications/
```

## Features

- Menu bar dropdown with circular status indicator
- Countdown timer (shows `02m 30s` or `1h 00m 05s`)
- Duration presets: 30 min, 1 hr, 2 hr, infinite
- "Prevent display sleep" toggle
- Stop button
- Uses macOS `caffeinate` under the hood

## Uninstall

```bash
rm -rf /Applications/Awake.app
```