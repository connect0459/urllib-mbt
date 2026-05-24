#!/usr/bin/env python3
"""Generate a sorted-range table of Unicode Mark code points (Mn, Mc, Me)
for use by the V6 leading-combining-mark check in IDNA validation.

Usage: python3 tools/gen_combining_mark.py
"""
import unicodedata
ranges = []
start = None
end = None
for cp in range(0, 0x110000):
    try:
        cat = unicodedata.category(chr(cp))
    except ValueError:
        cat = 'Cn'
    if cat in ('Mn', 'Mc', 'Me'):
        if start is None:
            start = cp
        end = cp
    else:
        if start is not None:
            ranges.append((start, end))
            start = None
if start is not None:
    ranges.append((start, end))

with open('src/internal/idna/combining_mark.mbt', 'w') as f:
    f.write('// AUTO-GENERATED FILE — do not edit by hand.\n')
    f.write(f'// Unicode {unicodedata.unidata_version}: Mark (Mn|Mc|Me) ranges.\n')
    f.write('\n')
    f.write('///|\n')
    f.write('let combining_mark_ranges : Array[(Int, Int)] = [\n')
    for s, e in ranges:
        f.write(f'  ({s}, {e}),\n')
    f.write(']\n')
    f.write('\n')
    f.write('///|\n')
    f.write('fn is_combining_mark_table(cp : Int) -> Bool {\n')
    f.write('  let arr = combining_mark_ranges\n')
    f.write('  let mut lo = 0\n')
    f.write('  let mut hi = arr.length()\n')
    f.write('  while lo < hi {\n')
    f.write('    let mid = (lo + hi) / 2\n')
    f.write('    let (s, e) = arr[mid]\n')
    f.write('    if cp < s {\n')
    f.write('      hi = mid\n')
    f.write('    } else if cp > e {\n')
    f.write('      lo = mid + 1\n')
    f.write('    } else {\n')
    f.write('      return true\n')
    f.write('    }\n')
    f.write('  }\n')
    f.write('  false\n')
    f.write('}\n')
