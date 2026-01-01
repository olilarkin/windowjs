# This script is executed by 'gclient sync' or 'gclient runhooks' after
# pulling in dependencies.

import os

# This file could be patched in, but then subsequent syncs won't remove it
# and subsequent patching via hooks fails.
config_dir = 'libraries/v8/build/config'
os.makedirs(config_dir, exist_ok=True)
with open(os.path.join(config_dir, 'gclient_args.gni'), 'w') as f:
  f.write('checkout_fuchsia_for_arm64_host = false\n')
