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

# Comment out the fp.h include - it's for Classic Mac OS only
# Original: #  include <fp.h>
# The regex handles various whitespace/comment scenarios
new_content = re.sub(
    r'(#\s*include\s*<fp\.h>)',
    r'/* \1 */ /* disabled for modern macOS */',
    content
)

if new_content != content:
    with open(filepath, 'w') as f:
        f.write(new_content)
    print(f"Patched {filepath} to disable fp.h include")
else:
    print(f"No changes needed in {filepath}")
