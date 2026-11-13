#!/usr/bin/env python3
import sys


def usage():
    sys.exit(f'Usage: {sys.argv[0]} <recombination file | -> <window size (bp)>')


if len(sys.argv) != 3:
    usage()
try:
    window_size = int(sys.argv[2])
except ValueError:
    usage()
if window_size <= 0:
    usage()

# chrom -> {window index: [sum of rate * bp, covered bp]}; dicts keep input order
windows = {}
last_end = {}

in_file = sys.stdin if sys.argv[1] == '-' else open(sys.argv[1])
with in_file:
    for line in in_file:
        data = line.split()
        if not data:
            continue
        chrom, begin, end, rate = data[0], int(data[1]), int(data[2]), float(data[3])
        chrom_windows = windows.setdefault(chrom, {})
        last_end[chrom] = max(last_end.get(chrom, 0), end)

        # Split the interval at window boundaries
        pos = begin
        while pos < end:
            k = pos // window_size
            stop = min(end, (k + 1) * window_size)
            acc = chrom_windows.setdefault(k, [0.0, 0])
            acc[0] += rate * (stop - pos)
            acc[1] += stop - pos
            pos = stop

for chrom, chrom_windows in windows.items():
    for k in sorted(chrom_windows):
        rate_bp, covered = chrom_windows[k]
        if covered > 0:
            start = k * window_size
            stop = min((k + 1) * window_size, last_end[chrom])
            print('\t'.join([chrom, str(start), str(stop), str(rate_bp / covered)]))
