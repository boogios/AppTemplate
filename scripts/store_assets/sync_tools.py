#!/usr/bin/env python3
"""Maintain app-local and personal-skill copies of the tested store tools."""
import argparse
from pathlib import Path
import shutil

def targets():
    source=Path(__file__).resolve().parent
    workspace=source.parents[1]
    skills=workspace/'skills'
    pairs=[]
    for app in ['ios','android']:
        for name in ['store_screenshots.py','store_screenshot_sync.rb','requirements.txt']:
            pairs.append((source/name,workspace/app/'fastlane/lib'/name))
        pairs.append((source/'store_assets.Fastfile',workspace/app/'fastlane/store_assets.Fastfile'))
    pairs.append((source/'app-store-screenshots.md',workspace/'ios/fastlane/STORE_SCREENSHOTS.md'))
    for skill in ['ios-fastlane-release','android-fastlane-release','screenshot-ios','screenshot-android']:
        folder=skills/skill
        for name in ['store_screenshots.py','requirements.txt']:
            pairs.append((source/name,folder/'scripts'/name))
        if 'fastlane' in skill:
            name='app_store_screenshot_sync.rb' if skill.startswith('ios') else 'play_store_screenshot_sync.rb'
            pairs.append((source/'store_screenshot_sync.rb',folder/'scripts'/name))
            pairs.append((source/'store_assets.Fastfile',folder/'scripts/store_assets.Fastfile'))
        else:
            name='validate_app_store_screenshots.py' if skill.endswith('ios') else 'validate_google_play_screenshots.py'
            pairs.append((source/name,folder/'scripts'/name))
        if skill in ['ios-fastlane-release','screenshot-ios']:
            pairs.append((source/'app-store-screenshots.md',folder/'references/app-store-screenshots.md'))
    return pairs

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args()
    errors=[]
    for source,target in targets():
        if args.check:
            if not target.is_file() or source.read_bytes()!=target.read_bytes():errors.append(str(target))
        else:
            target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
    if errors:raise SystemExit('Copies differ:\n'+'\n'.join(errors))
    print('Store tool copies match' if args.check else 'Store tool copies updated')
