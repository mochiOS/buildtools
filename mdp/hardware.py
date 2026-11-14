#!/usr/bin/env python3
"""Publish only the hardware image already supplied by a verified mBoot MDP."""
import argparse
import json
from pathlib import Path
import shutil
from image import artifact_tree,check

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--root',type=Path,required=True)
args=parser.parse_args();root=args.root.resolve()
tree,manifests,files=artifact_tree(root,root/'mdp.assembly.lock',{'hardware-media'})
check(files.get('hardware-media/mochiOS.img',(None,))[0]=='mboot','Build mBoot after composing the OS image: mdp workspace build --select mboot')
source=tree/'hardware-media/mochiOS.img';target=root/'out/mochiOS.img'
shutil.copyfile(source,target)
