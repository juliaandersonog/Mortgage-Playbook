#!/bin/bash
set -e

APP_NAME="MortgagePlaybook"
APP_BUNDLE="${APP_NAME}.app"
BUILD_DIR="build"
DESKTOP="$HOME/Desktop"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║      Building Mortgage Playbook      ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── Clean ──────────────────────────────────────────────────────────────────────
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${BUILD_DIR}/${APP_BUNDLE}/Contents/Resources"

# ── Compile Swift ──────────────────────────────────────────────────────────────
echo "▶  Compiling Swift…"
swiftc \
  Sources/main.swift \
  Sources/AppDelegate.swift \
  -o "${BUILD_DIR}/${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" \
  -framework Cocoa \
  -framework WebKit \
  -O \
  -strict-concurrency=minimal

echo "✓  Swift compiled successfully"

# ── Copy resources ─────────────────────────────────────────────────────────────
echo "▶  Copying resources…"
cp Sources/Info.plist "${BUILD_DIR}/${APP_BUNDLE}/Contents/"
cp Resources/index.html "${BUILD_DIR}/${APP_BUNDLE}/Contents/Resources/"
chmod +x "${BUILD_DIR}/${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

echo "✓  Resources copied"

# ── Deploy to Desktop ──────────────────────────────────────────────────────────
echo "▶  Installing to Desktop…"
rm -rf "${DESKTOP}/${APP_BUNDLE}"
cp -r "${BUILD_DIR}/${APP_BUNDLE}" "${DESKTOP}/"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅  Done! Mortgage Playbook is on your Desktop.         ║"
echo "║      Double-click it to launch — no Terminal needed.    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
