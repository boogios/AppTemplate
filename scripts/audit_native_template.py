#!/usr/bin/env python3
"""Read-only native template drift inventory; legacy structures are candidates, not errors."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
from native_template import EXCLUDED_DIRS

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('checker',Path(__file__).with_name('check-native-template.py'))
checker=importlib.util.module_from_spec(spec);spec.loader.exec_module(checker)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--strict',action='store_true');parser.add_argument('--all',action='store_true')
    parser.add_argument('apps',nargs='*');args=parser.parse_args()
    policy=json.loads((ROOT/'scripts/template-audit-policy.json').read_text())
    errors=warnings=audited=0;matched=set()
    for app in sorted(ROOT.iterdir()):
        if not app.is_dir() or app.is_symlink() or app.name in EXCLUDED_DIRS: continue
        if args.apps and app.name not in args.apps: continue
        if (app/'package.json').exists():
            # Native host folders in RN projects are explicitly outside this audit.
            try:
                package=json.loads((app/'package.json').read_text())
                if 'react-native' in package.get('dependencies',{}): continue
            except ValueError: continue
        candidates=[]
        if (app/'project.yml').exists(): candidates.append((app,'ios'))
        if (app/'app/build.gradle.kts').exists() or (app/'app/build.gradle').exists(): candidates.append((app,'android'))
        for nested in ('android','Android'):
            path=app/nested
            if (path/'app/build.gradle.kts').exists() or (path/'app/build.gradle').exists(): candidates.append((path,'android'))
        if not candidates: continue
        if not (args.all or args.apps or app.name in ('ios','android') or (app/'.git').exists()): continue
        matched.add(app.name)
        if app.name in policy['exclude']:
            print(f'{app.name}: excluded — {policy["exclude"][app.name]}');continue
        for path,platform in candidates:
            audited+=1
            label=str(path.relative_to(ROOT))
            if (path/'template-manifest.json').exists():
                issues,notes=checker.check(path)
                errors+=len(issues);warnings+=len(notes)
                print(f'{label} [{platform}]: {len(issues)} error(s), {len(notes)} note(s)')
                for issue in issues: print('  ERROR:',issue)
                for note in notes: print('  NOTE:',note)
            else:
                # Do not label intentional custom architecture or internal validation apps as product defects.
                print(f'{label} [{platform}]: adoption candidate (no version manifest; no baseline enforced)')
            for source in checker.files(path):
                if source.suffix in ('.swift','.kt'):
                    count=len(source.read_text(errors='replace').splitlines())
                    if count>800: print(f'  INFO: {source.relative_to(path)}: {count} lines; review responsibilities')
    unknown=set(args.apps)-matched
    for name in sorted(unknown): print(f'ERROR: native project not found: {name}')
    errors+=len(unknown)
    print(f'Audited {audited} native project(s): {errors} error(s), {warnings} note(s). No files changed.')
    return 1 if errors or (args.strict and warnings) else 0
if __name__=='__main__':raise SystemExit(main())
