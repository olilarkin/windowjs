#!/usr/bin/env python3
"""Fix libpng fp.h include issue for modern macOS."""
import re
import sys

filepath = 'libraries/skia/third_party/externals/libpng/pngpriv.h'

try:
    with open(filepath, 'r') as f:
        content = f.read()
except FileNotFoundError:
    print(f"File not found: {filepath}")
    sys.exit(0)

# Replace fp.h include with math.h - fp.h is for Classic Mac OS only,
# but it provided math functions. Modern macOS needs math.h instead.
new_content = re.sub(
    r'#\s*include\s*<fp\.h>',
    r'#  include <math.h> /* was fp.h - fixed for modern macOS */',
    content
)

if new_content != content:
    with open(filepath, 'w') as f:
        f.write(new_content)
    print(f"Patched {filepath} to use math.h instead of fp.h")
else:
    print(f"No changes needed in {filepath}")
