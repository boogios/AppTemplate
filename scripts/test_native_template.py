#!/usr/bin/env python3
"""Generator contract tests; creates only temporary local apps, no SDK network."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import tempfile
import unittest
from xml.etree import ElementTree as ET
from native_template import generate, copy_template, configure, validate_identity

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('checker', Path(__file__).with_name('check-native-template.py'))
checker = importlib.util.module_from_spec(spec); spec.loader.exec_module(checker)

class GeneratorTests(unittest.TestCase):
    def test_both_generators_and_display_names(self):
        for platform in ['ios', 'android']:
            with self.subTest(platform=platform), tempfile.TemporaryDirectory() as tmp:
                template = ROOT / ('ios' if platform == 'ios' else 'android')
                args = argparse.Namespace(platform=platform, name='FoundationCheck', identifier='com.example.foundationcheck',
                    display='A & B "한글" $price \\ path', category='Utilities', template=str(template), workspace=tmp)
                generate(args)
                app = Path(tmp)/('FoundationCheck' + ('-Android' if platform=='android' else ''))
                manifest=json.loads((app/'template-manifest.json').read_text())
                self.assertEqual(manifest['template_version'],'1.1.1')
                self.assertEqual(manifest['application_id'], args.identifier)
                self.assertEqual(checker.check(app)[0], [])
                if platform=='ios':
                    self.assertEqual(plistlib.loads((app/'FoundationCheck/Info.plist').read_bytes())['CFBundleDisplayName'],args.display)
                    self.assertEqual(json.loads((app/'AppStoreScreenshots/screenshot.config.json').read_text())['appName'],args.display)
                else:
                    self.assertTrue((app/'app/src/main/java/com/example/foundationcheck/MainActivity.kt').exists())
                    self.assertIn('A & B', ET.parse(app/'app/src/main/res/values/strings.xml').find("string[@name='app_name']").text)
                with self.assertRaises(ValueError): generate(args)  # no overwrite
                for display in ['Normal App','한글 앱']:
                    configure(app,args.name,display,args.category,platform)
                    self.assertEqual(checker.check(app)[0], [])
    def test_invalid_identifiers(self):
        for platform in ['ios','android']:
            for name, identifier in [('1App','com.test.app'),('../App','com.test.app'),('class','com.test.app'),('App','com..app'),('App','com.app/escape'),('App','not-an-id')]:
                with self.subTest(platform=platform,name=name,identifier=identifier), self.assertRaises(ValueError):
                    validate_identity(name,identifier,platform)
        with self.assertRaises(ValueError): validate_identity('App','com.class.app','android')
    def test_secrets_builds_git_and_symlinks_never_copy(self):
        with tempfile.TemporaryDirectory() as tmp:
            source=Path(tmp)/'source'; source.mkdir(); dest=Path(tmp)/'dest'
            paths=['.git/config','.gradle/state','build/archive','Pods/lib','node_modules/lib','vendor/lib','.env','.env.production','Configs/AppSecrets.xcconfig','local.properties','cert.p8','cert.p12','test.keystore','test.jks','private.key','private.pem','GoogleService-Info.plist','google-services.json','key.properties','keystore.properties','output.ipa','output.aab','output.apk','Release.xcarchive/Info.plist','Test.xcresult/info.json']
            for name in paths:
                p=source/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text('SENTINEL_DO_NOT_COPY')
            (source/'.env.example').write_text('PLACEHOLDER')
            (source/'link').symlink_to(source/'.env')
            for platform in ['ios','android']:
                target=dest/platform;copy_template(source,target,'Check','com.example.check',platform)
                self.assertEqual([p.relative_to(target).as_posix() for p in target.rglob('*') if p.is_file()],['.env.example'])
    def test_regional_fallback_and_event_parity(self):
        import re
        swift=(ROOT/'ios/AppTemplate/Infrastructure/AppDependencies.swift').read_text()
        kotlin=(ROOT/'android/app/src/main/java/com/boogios/template/core/foundation/Contracts.kt').read_text()
        events=lambda s:set(re.findall(r'"((?:onboarding|purchase|premium|rewarded_ad)_[a-z_]+)"',s))
        self.assertEqual(events(swift),events(kotlin))
        self.assertEqual(len(events(swift)),13)
        for platform in ['ios','android']:
            self.assertEqual(checker.check(ROOT/platform)[0],[])
            self.assertTrue(checker.check(ROOT/platform,'release')[0])

if __name__=='__main__': unittest.main()
