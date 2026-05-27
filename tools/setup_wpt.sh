#!/usr/bin/env bash
# Initialize the WPT submodule at the commit pinned in the superproject tree,
# materialising only url/resources and urlpattern/resources via sparse checkout.
set -euo pipefail

COMMIT=$(git ls-tree HEAD wpt | awk '{print $3}')
if [ ! -e wpt/.git ]; then
    git clone --filter=blob:none --no-checkout --depth=1 \
        https://github.com/web-platform-tests/wpt wpt
fi
git -C wpt fetch --depth=1 origin "$COMMIT"
git -C wpt sparse-checkout set url/resources urlpattern/resources
git -C wpt checkout "$COMMIT"
