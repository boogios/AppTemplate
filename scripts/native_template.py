#!/usr/bin/env python3
"""Create an independent native app without copying local credentials or build state."""
import argparse
import json
import os
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path
from xml.etree import ElementTree as ET
from xml.sax.saxutils import escape

EXCLUDED_DIRS = {'.git', '.gradle', '.cxx', '.idea', '.bundle', '.build', '.swiftpm', 'build', 'DerivedData', 'SourcePackages', 'Pods', 'node_modules', 'vendor', 'artifacts', 'outputs', 'output', '__pycache__', 'xcuserdata', '.store-assets', '.screenshot-state'}
EXCLUDED_FILES = {'google-services.json', 'GoogleService-Info.plist', 'credentials.json', 'key.properties', 'keystore.properties', 'secrets.properties','.DS_Store', 'local.properties', 'AppSecrets.xcconfig', 'report.xml', '.xcode.env.local'}
TEXT_EXTENSIONS = {'.swift', '.kt', '.kts', '.yml', '.yaml', '.plist', '.xcconfig', '.strings', '.json', '.html', '.mjs', '.sh', '.md', '.xml', '.pro', '.storekit', '.xcprivacy'}
TEXT_NAMES = {'Fastfile', 'Appfile', 'Gemfile', '.env.example', '.gitignore'}

def excluded(path):
    name = path.name
    return (name in EXCLUDED_DIRS or name in EXCLUDED_FILES or name.endswith(('.xcodeproj', '.xcworkspace', '.xcarchive', '.xcresult', '.dSYM'))
            or name.endswith(('.p8', '.p12', '.mobileprovision', '.keystore', '.jks', '.xcuserstate', '.pem', '.key', '.ipa', '.aab', '.apk', '.pfx', '.cer'))
            or (name.startswith('.env') and name != '.env.example'))

def validate_identity(name, identifier, platform):
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*', name): raise ValueError('Invalid app identifier name')
    pattern = r'[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+' if platform == 'android' else r'[A-Za-z][A-Za-z0-9-]*(?:\.[A-Za-z][A-Za-z0-9-]*)+'
    if name in {'class','struct','enum','interface','object','package','import','fun','val','var','let','return','public','private','internal','switch','when'}: raise ValueError('Reserved app identifier name')
    if platform == 'android' and any(part in {'class','interface','object','package','import','fun','val','var','return','public','private','internal','when','in','is','as'} for part in identifier.split('.')): raise ValueError('Reserved package segment')
    if not re.fullmatch(pattern, identifier): raise ValueError('Invalid bundle/application ID')

def copy_template(source, dest, name, identifier, platform):
    old = 'AppTemplateAndroid' if platform == 'android' else 'AppTemplate'
    package = identifier.replace('.', '/')
    for base, dirs, files in os.walk(source):
        dirs[:] = [d for d in dirs if not excluded(Path(base) / d) and not (Path(base) / d).is_symlink()]
        relative = Path(base).relative_to(source)
        mapped = str(relative).replace(old, name)
        if platform == 'android': mapped = mapped.replace('com/boogios/template', package)
        target = dest / mapped
        target.mkdir(parents=True, exist_ok=True)
        for filename in files:
            original = Path(base) / filename
            if excluded(original) or original.is_symlink(): continue
            output = target / filename.replace(old, name)
            if original.suffix in TEXT_EXTENSIONS or filename in TEXT_NAMES:
                text = original.read_text()
                text = text.replace(old, name).replace('AppTemplate', name).replace('com.boogios.template', identifier)
                text = text.replace('apptemplate-ios', name.lower().replace('_', '-') + '-ios')
                output.write_text(text)
                shutil.copymode(original, output)
            else: shutil.copy2(original, output)

def configure(dest, name, display, category, platform):
    if platform == 'ios':
        info = dest / name / 'Info.plist'
        contents = plistlib.loads(info.read_bytes()); contents['CFBundleDisplayName'] = display
        info.write_bytes(plistlib.dumps(contents, sort_keys=False))
        literal = json.dumps(display, ensure_ascii=False)
        for strings in (dest / name / 'Global/Localizing').glob('*.lproj/InfoPlist.strings'):
            text = re.sub(r'"CFBundleDisplayName"\s*=\s*"(?:\\.|[^"\\])*";', lambda _: '"CFBundleDisplayName" = '+literal+';', strings.read_text())
            strings.write_text(text)
        config = dest / name / 'Global/Config.swift'
        config.write_text(re.sub(r'static let appName = "(?:\\.|[^"\\])*"', lambda _: 'static let appName = '+literal, config.read_text()))
        screenshot = dest / 'AppStoreScreenshots/screenshot.config.json'
        data = json.loads(screenshot.read_text()); data['appName'] = display
        screenshot.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n')
        env = dest / 'fastlane/.env.example'
        text = re.sub(r'^APP_STORE_NAME=.*$', lambda _: 'APP_STORE_NAME='+literal, env.read_text(), flags=re.M)
        text = re.sub(r'^APP_STORE_PRIMARY_CATEGORY=.*$', lambda _: 'APP_STORE_PRIMARY_CATEGORY='+category, text, flags=re.M)
        env.write_text(text)
        shutil.copy2(dest/'Configs/AppSecrets.xcconfig.example', dest/'Configs/AppSecrets.xcconfig')
    else:
        # Android resources require both XML and Android string escaping.
        value = escape(display.replace('\\', '\\\\').replace("'", "\\'").replace('"', '\\"'))
        for strings in (dest/'app/src/main/res').glob('values*/strings.xml'):
            text = re.sub(r'<string name="app_name">.*?</string>', lambda _: '<string name="app_name">"'+value+'"</string>', strings.read_text(), flags=re.S)
            strings.write_text(text); ET.parse(strings)
        config = next((dest/'app/src/main/java').rglob('AppConfig.kt'))
        config.write_text(re.sub(r'const val appName = "(?:\\.|[^"\\])*"', lambda _: 'const val appName = '+json.dumps(display,ensure_ascii=False).replace('$','\\$'), config.read_text()))
        shutil.copy2(dest/'local.properties.example', dest/'local.properties')


def generate(args):
    validate_identity(args.name,args.identifier,args.platform)
    if any(ord(c) < 32 for c in args.display): raise ValueError('Display name must not contain control characters')
    if not args.display.strip(): raise ValueError('Display name must not be empty')
    source=Path(args.template).resolve(); workspace=Path(args.workspace).resolve()
    if not source.is_dir(): raise ValueError('Template directory missing')
    dest=workspace/(args.name+('-Android' if args.platform=='android' else ''))
    if dest.exists(): raise ValueError('Destination already exists')
    workspace.mkdir(parents=True,exist_ok=True)
    # Stage privately, then publish the directory only after format validation.
    with tempfile.TemporaryDirectory(prefix='.native-template-',dir=workspace) as tmp:
        staged=Path(tmp)/dest.name
        copy_template(source,staged,args.name,args.identifier,args.platform)
        configure(staged,args.name,args.display,args.category,args.platform)
        for fixture in staged.rglob('*.storekit'):
            data=json.loads(fixture.read_text())
            data['identifier']=str(uuid.uuid5(uuid.NAMESPACE_URL, args.identifier + '/' + fixture.name)).upper()
            fixture.write_text(json.dumps(data, indent=2)+'\n')
        manifest=json.loads((source/'template-manifest.json').read_text())
        manifest.update(app_name=args.name, application_id=args.identifier)
        (staged/'template-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
        if args.platform=='ios':
            subprocess.run(['xcodegen','generate','--spec',str(staged/'project.yml')],check=True,stdout=subprocess.DEVNULL)
        subprocess.run([sys.executable,str(Path(__file__).with_name('check-native-template.py')),str(staged),'--mode','local'],check=True)
        staged.rename(dest)
    print(f'Created {dest}')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform',choices=['ios','android'],required=True)
    for key in ['name','identifier','display','template','workspace']: parser.add_argument('--'+key,required=True)
    parser.add_argument('--category',default='Utilities')
    try: generate(parser.parse_args())
    except (ValueError,OSError,subprocess.CalledProcessError) as error:
        print(f'Generation failed: {error}',file=sys.stderr);return 1
    return 0
if __name__=='__main__': sys.exit(main())
