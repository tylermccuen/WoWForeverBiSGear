#!/usr/bin/env python3
"""Make Data/PatchNotes.lua from CHANGELOG.md (the About tab shows it).
Run from the repo root before every release:  python3 tools/gen_patchnotes.py"""
import re

text = open("CHANGELOG.md", encoding="utf-8").read()
versions = []
for block in re.split(r"^## ", text, flags=re.M)[1:]:
    head, _, body = block.partition("\n")
    items = []
    for line in body.splitlines():
        line = line.rstrip()
        if line.startswith("- "):
            items.append(line[2:])
        elif line.startswith("  ") and items:          # continuation of a bullet
            items[-1] += " " + line.strip()
        elif line.strip() and not line.startswith("#"):
            items.append(line.strip())
    versions.append((head.strip(), items))

def lua_str(s):
    # long string that can't be closed early by the text
    eq = "="
    while ("]" + eq + "]") in s:
        eq += "="
    return "[" + eq + "[" + s + "]" + eq + "]"

out = ["local _, ns = ...", "",
       "-- Made by tools/gen_patchnotes.py from CHANGELOG.md. Don't edit by hand.",
       "ns.PatchNotes = {"]
for version, items in versions:
    out.append("    { version = %s, notes = {" % lua_str(version))
    for it in items:
        out.append("        %s," % lua_str(it))
    out.append("    } },")
out.append("}")
open("Data/PatchNotes.lua", "w", encoding="utf-8").write("\n".join(out) + "\n")
print("Data/PatchNotes.lua: %d versions" % len(versions))
