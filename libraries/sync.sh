#!/bin/sh

echo
echo
echo "Fetching dependencies (this may take a long time, the first time)"
echo
echo
# First sync deps without running hooks
gclient sync --shallow --no-history -D -R --force --nohooks

if [ $? -ne 0 ]; then
  echo
  echo FAILED
  exit 1
fi

echo
echo "Running hooks"
echo
# Now run hooks after all deps are cloned
gclient runhooks

if [ $? -ne 0 ]; then
  echo
  echo FAILED
  exit 1
fi

echo
echo "FINISHED -- ready to build"
