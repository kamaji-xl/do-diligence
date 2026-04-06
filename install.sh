#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create directories
mkdir -p "$HOME/bin"
mkdir -p "$HOME/.config/systemd/user"
mkdir -p "$HOME/.config/autostart"

# Link script
ln -sf "$PROJECT_DIR/bin/do_diligence.sh" \
       "$HOME/bin/do_diligence.sh"

# Link systemd service
ln -sf "$PROJECT_DIR/systemd/user/do_diligence.service" \
       "$HOME/.config/systemd/user/do_diligence.service"

# Link autostart file
ln -sf "$PROJECT_DIR/autostart/do_diligence.desktop" \
       "$HOME/.config/autostart/do_diligence.desktop"

# Reload systemd
systemctl --user daemon-reload
systemctl --user start do_diligence.service
