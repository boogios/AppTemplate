#!/usr/bin/env python3
"""Backward-compatible screenshot-android CLI with explicit completeness checks."""
import argparse
import json
from pathlib import Path
import sys
from PIL import Image
from store_screenshots import build_manifest

def graphic(path, size, icon=False):
    with Image.open(path) as image:
        image.load()
        if image.size != size:
            raise ValueError(f'Wrong graphic size: {path.name}; expected {size}')
        if icon:
            if image.format != 'PNG' or image.mode != 'RGBA' or path.stat().st_size > 1024 * 1024:
                raise ValueError('Icon needs 512px RGBA PNG, <=1MB')
        elif image.format not in {'PNG','JPEG'} or image.mode != 'RGB' or 'transparency' in image.info:
            raise ValueError('Feature graphic needs RGB PNG/JPEG without alpha')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,required=True)
    parser.add_argument('--require',action='append',default=[])
    parser.add_argument('--locales',help='Expected comma-separated Play locales')
    parser.add_argument('--devices',help='Expected comma-separated categories')
    parser.add_argument('--manifest',type=Path)
    parser.add_argument('--icon',type=Path)
    parser.add_argument('--feature-graphic',type=Path)
    args=parser.parse_args()
    try:
        require={}
        for item in args.require:
            device,count=item.split('=');require[device]=int(count)
            if require[device]<1:raise ValueError('Minimum image count must be positive')
        manifest=build_manifest(args.root,'android',args.locales.split(',') if args.locales else None,args.devices.split(',') if args.devices else None,require)
        if args.icon:graphic(args.icon,(512,512),True)
        if args.feature_graphic:graphic(args.feature_graphic,(1024,500))
        if args.manifest:
            args.manifest.parent.mkdir(parents=True,exist_ok=True)
            args.manifest.write_text(json.dumps(manifest,indent=2)+'\n')
        print(f"Google Play screenshot validation passed: {len(manifest['sets'])} sets")
        return 0
    except (ValueError,OSError) as error:
        print(f'ERROR: {error}',file=sys.stderr);return 1

if __name__=='__main__':sys.exit(main())
