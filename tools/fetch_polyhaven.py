#!/usr/bin/env python3
# Download a PolyHaven CC0 model (glTF + its textures/bin) into a folder.
# Usage: fetch_polyhaven.py <AssetID> <res:1k|2k> <outdir>
import sys, os, json, urllib.request

UA = {"User-Agent": "Mozilla/5.0 (himyt-asset-fetch)"}

def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=UA))

def download(url, path):
    with get(url) as r, open(path, "wb") as f:
        f.write(r.read())

asset, res, outdir = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(get(f"https://api.polyhaven.com/files/{asset}"))
g = data["gltf"][res]["gltf"]
os.makedirs(outdir, exist_ok=True)
gltf_path = os.path.join(outdir, os.path.basename(g["url"].split("?")[0]))
download(g["url"], gltf_path)
print("gltf:", os.path.basename(gltf_path))
for rel, info in (g.get("include") or {}).items():
    p = os.path.join(outdir, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    download(info["url"], p)
    print("  +", rel)
print("DONE")
