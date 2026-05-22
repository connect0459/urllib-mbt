#!/usr/bin/env python3
"""Generate a sorted-range table of Unicode Mark code points (Mn, Mc, Me)
for use by the V6 leading-combining-mark check in IDNA validation."""
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

print('// AUTO-GENERATED FILE — do not edit by hand.')
print(f'// Unicode {unicodedata.unidata_version}: Mark (Mn|Mc|Me) ranges.')
print('')
print('///|')
print('let combining_mark_ranges : Array[(Int, Int)] = [')
for s, e in ranges:
    print(f'  ({s}, {e}),')
print(']')
print('')
print('///|')
print('fn is_combining_mark_table(cp : Int) -> Bool {')
print('  let arr = combining_mark_ranges')
print('  let mut lo = 0')
print('  let mut hi = arr.length()')
print('  while lo < hi {')
print('    let mid = (lo + hi) / 2')
print('    let (s, e) = arr[mid]')
print('    if cp < s {')
print('      hi = mid')
print('    } else if cp > e {')
print('      lo = mid + 1')
print('    } else {')
print('      return true')
print('    }')
print('  }')
print('  false')
print('}')
