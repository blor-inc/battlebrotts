#!/bin/bash
# Run BattleBrotts test suite headlessly
# Requires: godot --editor --quit to have been run once for class_name registration
set -e
cd "$(dirname "$0")/.."

# Ensure game code is synced to godot project
cp -r game/* godot/game/

# Run editor import (registers class_names)
godot --headless --path godot/ --editor --quit 2>/dev/null || true

# Run tests via scene
godot --headless --path godot/ res://tests/test_scene.tscn 2>&1
