#!/usr/bin/env python3
"""Builds the placeholder 3D mascot: assets/3d/monkey.glb.

A simple low-poly "Auditor Monkey" (head, face, ears, eyes, body) in the
DESIGN.md palette, with the five named animation clips the app expects:
idle, happy, worried, celebrating, sleeping.

Only the Python standard library is used, so the file can be rebuilt
anywhere:  python3 tool/make_placeholder_glb.py

The owner's real model replaces assets/3d/monkey.glb; see DESIGN.md
("Mascot") for the exact requirements.
"""

import json
import math
import os
import struct

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "3d", "monkey.glb")


def hex_rgba(h):
    h = h.lstrip("#")
    # glTF base colours are linear; convert from sRGB.
    def lin(c):
        c = c / 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    return [lin(int(h[i : i + 2], 16)) for i in (0, 2, 4)] + [1.0]


# DESIGN.md tokens.
PRIMARY_DEEP = "#476E61"  # fur
LIME = "#E4E782"  # face and belly
INK = "#1E3B31"  # eyes
PRIMARY = "#70D0B2"  # inner ears


def sphere(rx, ry, rz, cx, cy, cz, seg=16, rings=10):
    pos, nor, idx = [], [], []
    for r in range(rings + 1):
        v = r / rings
        phi = v * math.pi
        for s in range(seg + 1):
            u = s / seg
            th = u * 2 * math.pi
            x, y, z = math.sin(phi) * math.cos(th), math.cos(phi), math.sin(phi) * math.sin(th)
            pos.append((cx + rx * x, cy + ry * y, cz + rz * z))
            n = (x / rx, y / ry, z / rz)
            ln = math.sqrt(sum(c * c for c in n)) or 1.0
            nor.append(tuple(c / ln for c in n))
    for r in range(rings):
        for s in range(seg):
            a = r * (seg + 1) + s
            b = a + seg + 1
            idx += [a, a + 1, b, b, a + 1, b + 1]
    return pos, nor, idx


class Builder:
    def __init__(self):
        self.bin = bytearray()
        self.views, self.accessors = [], []

    def _pad(self):
        while len(self.bin) % 4:
            self.bin.append(0)

    def add(self, fmt, rows, comp, typ, target=None, minmax=False):
        self._pad()
        off = len(self.bin)
        for row in rows:
            row = row if isinstance(row, (tuple, list)) else (row,)
            self.bin += struct.pack("<" + fmt * len(row), *row)
        view = {"buffer": 0, "byteOffset": off, "byteLength": len(self.bin) - off}
        if target:
            view["target"] = target
        self.views.append(view)
        acc = {"bufferView": len(self.views) - 1, "componentType": comp, "count": len(rows), "type": typ}
        if minmax:
            n = len(rows[0]) if isinstance(rows[0], (tuple, list)) else 1
            cols = [[(r if n == 1 else r[i]) for r in rows] for i in range(n)]
            acc["min"] = [min(c) for c in cols]
            acc["max"] = [max(c) for c in cols]
        self.accessors.append(acc)
        return len(self.accessors) - 1


def main():
    b = Builder()
    materials = [
        {"name": "fur", "pbrMetallicRoughness": {"baseColorFactor": hex_rgba(PRIMARY_DEEP), "metallicFactor": 0, "roughnessFactor": 0.8}},
        {"name": "face", "pbrMetallicRoughness": {"baseColorFactor": hex_rgba(LIME), "metallicFactor": 0, "roughnessFactor": 0.7}},
        {"name": "eye", "pbrMetallicRoughness": {"baseColorFactor": hex_rgba(INK), "metallicFactor": 0, "roughnessFactor": 0.3}},
        {"name": "ear", "pbrMetallicRoughness": {"baseColorFactor": hex_rgba(PRIMARY), "metallicFactor": 0, "roughnessFactor": 0.8}},
    ]
    meshes = []

    def mesh(name, parts):
        prims = []
        for (shape, mat) in parts:
            pos, nor, idx = shape
            p = b.add("f", pos, 5126, "VEC3", 34962, minmax=True)
            n = b.add("f", nor, 5126, "VEC3", 34962)
            i = b.add("H", idx, 5123, "SCALAR", 34963)
            prims.append({"attributes": {"POSITION": p, "NORMAL": n}, "indices": i, "material": mat})
        meshes.append({"name": name, "primitives": prims})
        return len(meshes) - 1

    # Body: around the origin of the body node (feet at y=0 on the root).
    body_mesh = mesh("body", [
        (sphere(0.28, 0.30, 0.24, 0, 0.30, 0), 0),
        (sphere(0.18, 0.20, 0.06, 0, 0.30, 0.20), 1),
        (sphere(0.08, 0.06, 0.08, -0.14, 0.03, 0.06, 10, 6), 0),
        (sphere(0.08, 0.06, 0.08, 0.14, 0.03, 0.06, 10, 6), 0),
    ])
    # Head: built around the neck pivot (y=0 here, placed at y=0.58).
    head_mesh = mesh("head", [
        (sphere(0.26, 0.24, 0.24, 0, 0.22, 0), 0),
        (sphere(0.19, 0.15, 0.08, 0, 0.18, 0.19), 1),
        (sphere(0.035, 0.045, 0.02, -0.08, 0.27, 0.235, 10, 6), 2),
        (sphere(0.035, 0.045, 0.02, 0.08, 0.27, 0.235, 10, 6), 2),
        (sphere(0.025, 0.018, 0.015, 0, 0.17, 0.27, 8, 5), 2),
    ])
    ear_mesh = mesh("ear", [
        (sphere(0.10, 0.10, 0.04, 0, 0, 0, 12, 8), 0),
        (sphere(0.065, 0.065, 0.02, 0, 0, 0.03, 12, 8), 3),
    ])

    nodes = [
        {"name": "monkey", "children": [1, 2]},                       # 0 root
        {"name": "body", "mesh": body_mesh},                           # 1
        {"name": "head", "mesh": head_mesh, "translation": [0, 0.55, 0], "children": [3, 4]},  # 2
        {"name": "ear_left", "mesh": ear_mesh, "translation": [-0.27, 0.26, 0]},   # 3
        {"name": "ear_right", "mesh": ear_mesh, "translation": [0.27, 0.26, 0]},   # 4
    ]

    def quat(axis, deg):
        a = math.radians(deg) / 2
        s = math.sin(a)
        return (axis[0] * s, axis[1] * s, axis[2] * s, math.cos(a))

    def qmul(q, r):
        x1, y1, z1, w1 = q
        x2, y2, z2, w2 = r
        return (w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
                w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
                w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2,
                w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2)

    X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)
    animations = []

    def clip(name, duration, fps, tracks):
        """tracks: list of (node, path, fn(t)->tuple)."""
        n = int(duration * fps) + 1
        times = [i / fps for i in range(n)]
        t_acc = b.add("f", times, 5126, "SCALAR", minmax=True)
        samplers, channels = [], []
        for node, path, fn in tracks:
            vals = [fn(t / duration) for t in times]
            typ = "VEC4" if path == "rotation" else "VEC3"
            v_acc = b.add("f", vals, 5126, typ)
            samplers.append({"input": t_acc, "output": v_acc, "interpolation": "LINEAR"})
            channels.append({"sampler": len(samplers) - 1, "target": {"node": node, "path": path}})
        animations.append({"name": name, "samplers": samplers, "channels": channels})

    sin = lambda p: math.sin(p * 2 * math.pi)
    head_rest = (0, 0.55, 0)

    clip("idle", 2.4, 24, [
        (2, "translation", lambda p: (0, 0.55 + 0.012 * sin(p), 0)),
        (2, "rotation", lambda p: quat(Z, 4 * sin(p))),
        (1, "scale", lambda p: (1, 1 + 0.015 * sin(p), 1)),
    ])
    clip("happy", 1.2, 30, [
        (0, "translation", lambda p: (0, 0.18 * math.sin(p * math.pi), 0)),
        (2, "rotation", lambda p: quat(Z, 12 * math.sin(p * 2 * math.pi))),
        (3, "rotation", lambda p: quat(Z, 20 * math.sin(p * 4 * math.pi))),
        (4, "rotation", lambda p: quat(Z, -20 * math.sin(p * 4 * math.pi))),
    ])
    clip("worried", 1.6, 24, [
        (2, "rotation", lambda p: qmul(quat(X, 8), quat(Y, 10 * sin(p * 2)))),
        (1, "scale", lambda p: (1, 0.97, 1)),
        (2, "translation", lambda p: (0, 0.53, 0)),
    ])
    clip("celebrating", 2.4, 30, [
        (0, "rotation", lambda p: quat(Y, 360 * min(1.0, p * 1.5))),
        (0, "translation", lambda p: (0, 0.22 * abs(math.sin(p * 3 * math.pi)), 0)),
        (0, "scale", lambda p: (1 + 0.06 * abs(math.sin(p * 3 * math.pi)),) * 3),
    ])
    clip("sleeping", 3.2, 20, [
        (2, "rotation", lambda p: qmul(quat(X, 22), quat(Z, 6))),
        (2, "translation", lambda p: (0, 0.52 + 0.01 * sin(p), 0.02)),
        (1, "scale", lambda p: (1 + 0.02 * sin(p), 1 + 0.03 * sin(p), 1)),
    ])
    _ = head_rest

    b._pad()
    gltf = {
        "asset": {"version": "2.0", "generator": "auditor_monkey make_placeholder_glb.py"},
        "scene": 0,
        "scenes": [{"name": "Scene", "nodes": [0]}],
        "nodes": nodes,
        "meshes": meshes,
        "materials": materials,
        "animations": animations,
        "accessors": b.accessors,
        "bufferViews": b.views,
        "buffers": [{"byteLength": len(b.bin)}],
    }
    js = json.dumps(gltf, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(b.bin)
    out = bytearray(struct.pack("<III", 0x46546C67, 2, total))
    out += struct.pack("<II", len(js), 0x4E4F534A) + js
    out += struct.pack("<II", len(b.bin), 0x004E4942) + b.bin
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "wb") as f:
        f.write(out)
    print(f"wrote {os.path.normpath(OUT)} ({len(out)} bytes)")


if __name__ == "__main__":
    main()
