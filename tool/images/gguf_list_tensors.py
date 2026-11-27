# SPDX-License-Identifier: GPL-3.0-or-later
"""Lists the tensors of a GGUF file by name prefix (standard library only; reads the header, not the data).

    python -I -X utf8 gguf_list_tensors.py model.gguf [--fail-on PREFIX ...]

Prints, per top-level name prefix (first two dotted parts): tensor count and bytes. With --fail-on, exits 1 if any
tensor name starts with one of the given prefixes (used to prove the full VAE is gone).
"""
import os
import struct
import sys

# gguf type id -> (block size in elements, bytes per block)
TYPES = {
    0: (1, 4), 1: (1, 2), 2: (32, 18), 3: (32, 20), 6: (32, 22), 7: (32, 24), 8: (32, 34), 9: (32, 36),
    10: (256, 84), 11: (256, 110), 12: (256, 144), 13: (256, 176), 14: (256, 210), 15: (256, 292),
    24: (1, 1), 25: (1, 2), 26: (1, 4), 27: (1, 8), 28: (1, 8), 30: (1, 2),
}
NAMES = {0: "f32", 1: "f16", 2: "q4_0", 3: "q4_1", 6: "q5_0", 7: "q5_1", 8: "q8_0", 9: "q8_1", 30: "bf16"}
SCALARS = {0: "B", 1: "b", 2: "H", 3: "h", 4: "I", 5: "i", 6: "f", 7: "B", 10: "Q", 11: "q", 12: "d"}


def read_value(f, vtype):
    if vtype in SCALARS:
        fmt = "<" + SCALARS[vtype]
        return struct.unpack(fmt, f.read(struct.calcsize(fmt)))[0]
    if vtype == 8:
        (n,) = struct.unpack("<Q", f.read(8))
        return f.read(n).decode("utf-8", "replace")
    if vtype == 9:
        (et,) = struct.unpack("<I", f.read(4))
        (n,) = struct.unpack("<Q", f.read(8))
        return [read_value(f, et) for _ in range(n)]
    raise ValueError("unknown metadata type %d" % vtype)


def read_header(path):
    with open(path, "rb") as f:
        if f.read(4) != b"GGUF":
            raise ValueError("not a GGUF file")
        version, n_tensors, n_kv = struct.unpack("<IQQ", f.read(20))
        kv = {}
        for _ in range(n_kv):
            (kl,) = struct.unpack("<Q", f.read(8))
            key = f.read(kl).decode("utf-8")
            (vt,) = struct.unpack("<I", f.read(4))
            kv[key] = read_value(f, vt)
        tensors = []
        for _ in range(n_tensors):
            (nl,) = struct.unpack("<Q", f.read(8))
            name = f.read(nl).decode("utf-8")
            (nd,) = struct.unpack("<I", f.read(4))
            dims = struct.unpack("<%dQ" % nd, f.read(8 * nd))
            ttype, offset = struct.unpack("<IQ", f.read(12))
            elems = 1
            for d in dims:
                elems *= d
            block, size = TYPES[ttype]
            tensors.append((name, ttype, offset, elems // block * size))
    return version, kv, tensors


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    path = argv[1]
    fail_on = argv[argv.index("--fail-on") + 1:] if "--fail-on" in argv else []
    version, kv, tensors = read_header(path)
    groups = {}
    for name, ttype, _, size in tensors:
        key = ".".join(name.split(".")[:2])
        g = groups.setdefault(key, [0, 0, set()])
        g[0] += 1
        g[1] += size
        g[2].add(NAMES.get(ttype, str(ttype)))
    print("%s: GGUF v%d, %d tensors, file %d bytes, tensor data %d bytes"
          % (path, version, len(tensors), os.path.getsize(path), sum(t[3] for t in tensors)))
    for key in sorted(groups):
        n, size, types = groups[key]
        print("  %-40s %5d tensors %12d bytes  %s" % (key, n, size, ",".join(sorted(types))))
    bad = [t[0] for t in tensors if any(t[0].startswith(p) for p in fail_on)]
    if bad:
        print("FAIL: %d tensors start with %s, e.g. %s" % (len(bad), fail_on, bad[0]))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
