#!/usr/bin/env python3
"""Read-only local/release checks. Does not contact stores or print credentials."""
import hashlib
import argparse
import json
import plistlib
import re
import sys
from pathlib import Path
from xml.etree import ElementTree as ET

sys.path.insert(0,str(Path(__file__).parent))
from native_template import EXCLUDED_DIRS, excluded

LOCALES=['ko','ja','en-US','en-GB','en-CA','en-AU','de-DE','fr-FR','pt-BR','vi']

def files(root):
    import os
    for base,dirs,names in os.walk(root):
        dirs[:]=[x for x in dirs if x not in EXCLUDED_DIRS and not x.endswith(('.xcodeproj','.xcworkspace')) and not (Path(base)/x).is_symlink()]
        for name in names:
            p=Path(base)/name
            if not p.is_symlink(): yield p

def check(root,mode='local'):
    errors=[];warnings=[]
    def need(condition,message):
        if not condition: errors.append(message)
    try: manifest=json.loads((root/'template-manifest.json').read_text())
    except (OSError,ValueError): return ['Missing/invalid template-manifest.json'],[]
    platform=manifest.get('platform'); need(platform in ('ios','android'),'Unknown platform')
    need(manifest.get('schema_version')==1,'Unsupported manifest schema')
    need(bool(re.fullmatch(r'\d+\.\d+\.\d+',manifest.get('template_version',''))),'Invalid template version')
    need(all(x in manifest.get('modules',{}) for x in ['foundation','settings','onboarding','purchases','ads','analytics','localization']),'Missing module versions')
    if manifest.get('template_version') in {'1.1.0', '1.1.1', '1.1.2'}:
        need(manifest.get('modules',{}).get('store_assets') in {'1.0.0', '1.0.1', '1.0.2'},'Missing store asset contract version')
        for relative in ['fastlane/store_assets.Fastfile','fastlane/lib/store_screenshots.py','fastlane/lib/store_screenshot_sync.rb','fastlane/lib/requirements.txt','Gemfile','Gemfile.lock']:
            need((root/relative).is_file(),f'Missing store asset tool: {relative}')
        gemfile=root/'Gemfile'
        need(gemfile.is_file() and '2.241.2' in gemfile.read_text(),'Store asset Fastlane version must match validated 2.241.2')
    allfiles=list(files(root))
    generated=bool(manifest.get('app_name'))
    if platform=='ios':
        project=(root/'project.yml').read_text(); name=re.search(r'^name:\s*(\w+)',project,re.M).group(1)
        source=root/name; config=source/'Global/Config.swift'
        need('type: bundle.unit-test' in project and 'type: bundle.ui-testing' in project,'Missing test targets')
        for p in [source/'Info.plist',source/'PrivacyInfo.xcprivacy']:
            try: plistlib.loads(p.read_bytes())
            except Exception: errors.append(f'Invalid/missing plist: {p.relative_to(root)}')
        need('MyPageView()' in (source/'Global/Managers/MainView.swift').read_text(),'Settings tab missing')
        for locale in LOCALES: need((source/f'Global/Localizing/{locale}.lproj/InfoPlist.strings').exists(),f'Missing locale {locale}')
        need('preferredColorScheme' in (source/f'{name}App.swift').read_text(),'Root theme handling missing')
        need((root/'Configs/AppSecrets.xcconfig.example').exists(),'Missing safe config example')
        # Require full non-English translations in shared template L10n calls; regional English intentionally falls back.
        for p in (source/'Global/Localization').glob('*L10n.swift'):
            text=p.read_text()
            for match in re.finditer(r'L10n\.text\(',text):
                start=match.end(); i=start; depth=1; quoted=False; escaped=False
                while i<len(text) and depth:
                    c=text[i]
                    if quoted:
                        if escaped: escaped=False
                        elif c=='\\': escaped=True
                        elif c=='"': quoted=False
                    elif c=='"': quoted=True
                    elif c=='(': depth+=1
                    elif c==')': depth-=1
                    i+=1
                block=text[start:i-1]
                labels=set(re.findall(r'\b(en|ko|ja|deDE|frFR|ptBR|vi)\s*:',block))
                need(labels=={'en','ko','ja','deDE','frFR','ptBR','vi'},f'Missing translation: {p.name}:{text[:start].count(chr(10))+1}')
                literals=dict(re.findall(r'\b(en|ko|ja|deDE|frFR|ptBR|vi|enGB|enCA|enAU)\s*:\s*"((?:\\.|[^"\\])*)"',block))
                def arguments(value):
                    return sorted(re.findall(r'\\\(([^)]+)\)',value) + re.findall(r'%(?:\d+\$)?[sdif@]',value))
                if 'en' in literals:
                    for locale,value in literals.items():
                        need(arguments(value)==arguments(literals['en']),f'Format arguments differ: {p.name}/{locale}:{text[:start].count(chr(10))+1}')

        if mode=='release':
            need('ASSETCATALOG_COMPILER_APPICON_NAME: ""' not in project,'App icon is not configured')
            need('appStoreID = "0000000000"' not in config.read_text(),'App Store ID is not configured')
            warnings.append('Verify final archive privacy data declarations and App Store product registration against enabled services.')
    elif platform=='android':
        source=root/'app/src/main'
        config=next(source.rglob('AppConfig.kt'))
        base=ET.parse(source/'res/values/strings.xml').getroot()
        def strings(tree): return {node.attrib['name']: ''.join(node.itertext()) for node in tree if node.tag=='string'}
        reference=strings(base)
        for p in (source/'res').glob('values*/strings.xml'):
            try:
                values=strings(ET.parse(p).getroot())
                regional_english = p.parent.name.startswith('values-en-r')
                need(set(values) <= set(reference) if regional_english else set(values)==set(reference),f'Localization key mismatch: {p.parent.name}')
                for key,value in reference.items():
                    tokens=lambda s: sorted(re.findall(r'%(?:\d+\$)?[sdif]',s))
                    need(tokens(value)==tokens(values.get(key,value) if regional_english else values.get(key,'')),f'Format arguments differ: {p.parent.name}/{key}')
            except ET.ParseError: errors.append(f'Invalid XML: {p.relative_to(root)}')
        gradle=(root/'app/build.gradle.kts').read_text()
        need('billing-ktx:9.1.0' in gradle,'Billing version must match validated 9.1.0 baseline')
        need((root/'local.properties.example').exists(),'Missing safe properties example')
        if mode=='release':
            launcher=source/'res/drawable/ic_launcher_foreground.xml'
            need(not launcher.exists() or hashlib.sha256(launcher.read_bytes()).hexdigest() != 'e9d8e20c010b815c46447075113dfc2c7e16eac9151a7c0025e71b6ac08a1142','Launcher icon is still the template artwork')
            warnings.append('Verify release signing, privacy declarations and Play product registration.')
    else: return errors,warnings
    for p in allfiles:
        if p.suffix=='.json':
            try: json.loads(p.read_text())
            except (ValueError,UnicodeDecodeError): errors.append(f'Invalid JSON: {p.relative_to(root)}')
        if p.suffix=='.xml':
            try: ET.parse(p)
            except ET.ParseError: errors.append(f'Invalid XML: {p.relative_to(root)}')
        if generated and p.suffix in ('.swift','.kt','.kts','.yml','.plist','.strings','.json','.xml'):
            text=p.read_text(errors='replace')
            if 'com.boogios.template' in text: errors.append(f'Template application ID remains: {p.relative_to(root)}')
            if p.suffix in ('.swift','.kt','.kts','.yml','.plist') and 'AppTemplate' in text: errors.append(f'Template name remains: {p.relative_to(root)}')
    if mode=='release':
        text=config.read_text()
        need('https://example.com/' not in text,'Terms/privacy URL is still an example')
        need('com.boogios.template' not in text,'Application/product identity is still the template default')
        warnings.append('This check cannot prove store readiness, real purchases, ad delivery, or public availability.')
    return list(dict.fromkeys(errors)),warnings

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('root',type=Path);parser.add_argument('--mode',choices=['local','release'],default='local')
    args=parser.parse_args()
    try: errors,warnings=check(args.root.resolve(),args.mode)
    except (OSError,ValueError,StopIteration,AttributeError) as error: errors=[f'Invalid project structure: {type(error).__name__}'];warnings=[]
    for message in errors: print('ERROR:',message)
    for message in warnings: print('NOTE:',message)
    print(f'{args.root.name}: {args.mode}: {len(errors)} error(s), {len(warnings)} note(s)')
    return 1 if errors else 0
if __name__=='__main__':sys.exit(main())
