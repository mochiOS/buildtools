#!/usr/bin/env python3
"""Validate pinned external System components and export a producer-owned tree."""
import json
import os
from pathlib import Path
import shutil
import sys
import tomllib

from component_validation import stage_components

root = Path(os.environ['MDP_CONTEXT']).resolve()
output = Path(__file__).resolve().parents[1] / 'out/mdp/system-components'
if output.exists():
    shutil.rmtree(output)
output.mkdir(parents=True)
stage_components(root, root / 'build/system-libraries.toml', output, root / 'out/mmake/host-tools/release/msign')
metadata = output / 'manifests'
metadata.mkdir()
records = []
for package in sorted((output / 'system/packages').iterdir()):
    name = package.name
    shutil.copyfile(package / 'manifest.toml', metadata / (name + '.toml'))
    records.append(dict(manifest=name + '.toml', directory=name))
shutil.rmtree(output / 'system/packages')
(metadata / 'components.json').write_text(json.dumps({'builtins':records},indent=2)+'\n')
# A native link prefix is a development output, separate from installed paths.
link = root / 'out/mdp/webkit-sdk/usr/lib'
link.mkdir(parents=True,exist_ok=True)
for file in (output / 'system/libraries').rglob('*'):
    if file.is_file() and '.so' in file.name:
        target = link / file.name
        if not target.exists() or target.stat().st_mtime_ns != file.stat().st_mtime_ns:
            shutil.copy2(file,target)
for file in list(link.glob('*.so.*')):
    short = link / (file.name.split('.so.',1)[0]+'.so')
    if not short.exists():
        short.symlink_to(file.name)
if not (link/'libwebkit.so').is_file():
    raise SystemExit('The pinned System component does not export libwebkit.so')
