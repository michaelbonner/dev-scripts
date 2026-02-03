#!/bin/bash

# Sometimes next projects slow down and eat way too much memory. 
# This script will help you clean out the extra bloat and speed things up, hopefully.

echo "🧹 Starting clean install process..."
echo ""

echo "[1/4] Removing node_modules..."
rm -rf node_modules
echo "      ✓ node_modules removed"
echo ""

echo "[2/4] Clearing bun cache..."
bun pm cache rm
echo "      ✓ bun cache cleared"
echo ""

echo "[3/4] Removing .next build folder..."
rm -rf .next
echo "      ✓ .next removed"
echo ""

echo "[4/4] Installing dependencies..."
bun install
echo ""

echo "✅ Clean install complete!"
