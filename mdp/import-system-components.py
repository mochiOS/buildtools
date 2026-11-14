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
