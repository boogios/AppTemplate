import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from PIL import Image
from store_screenshots import build_manifest, image_info, stage

class ScreenshotTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'source'
        self.root.mkdir()

    def png(self, name, size=(1206, 2622), color='blue', mode='RGB'):
        p = self.root / name
        p.parent.mkdir(parents=True, exist_ok=True)
        Image.new(mode, size, color).save(p)
        return p

    def test_ios_accepted_sizes_and_landscape(self):
        for size in [(1206,2622),(1290,2796),(1398,2034),(2034,1398),(2007,2853),(2853,2007),(2048,2732)]:
            with self.subTest(size=size):
                self.assertIsNotNone(image_info(self.png('check.png',size),'ios')['display_type'])

    def test_duo_is_one_ordered_set(self):
        for i in [1,2]:
            self.png(f'en-US/{i:02d}_duoInner_home.png',(2007,2853),f'#{i}23456')
            self.png(f'en-US/{i:02d}_duoOuter_home.png',(1398,2034),f'#{i}34567')
        rows=build_manifest(self.root,'ios',devices=['APP_IPHONE_DUO'])['sets']
        self.assertEqual(len(rows),1)
        self.assertEqual([x['width'] for x in rows[0]['images']],[1398,2007,1398,2007])

    def test_six_outer_plus_six_inner_exceeds_shared_limit(self):
        for i in range(6):
            for key,size in [('duoOuter',(1398,2034)),('duoInner',(2007,2853))]:
                self.png(f'en-US/{i:02d}_{key}.png',size,f'#{i+1}abcde')
        with self.assertRaisesRegex(ValueError,'12 images'):
            build_manifest(self.root,'ios',devices=['APP_IPHONE_DUO'])

    def test_missing_duo_posture(self):
        self.png('en-US/01_duoOuter.png',(1398,2034))
        with self.assertRaisesRegex(ValueError,'outer and inner'):
            build_manifest(self.root,'ios',devices=['APP_IPHONE_DUO'])

    def test_invalid_dimensions_alpha_extension_and_duplicates(self):
        for size,mode in [((100,200),'RGB'),((1206,2622),'RGBA')]:
            with self.subTest(size=size,mode=mode),self.assertRaises(ValueError):
                image_info(self.png('invalid.png',size,mode=mode),'ios')
        p=self.png('en-US/01.png')
        (p.parent/'02.png').write_bytes(p.read_bytes())
        with self.assertRaisesRegex(ValueError,'Duplicate'):
            build_manifest(self.root,'ios')
        fake=self.root/'fake.jpg';fake.write_bytes(p.read_bytes())
        with self.assertRaisesRegex(ValueError,'mismatch'):image_info(fake,'ios')

    def test_explicit_missing_locale_and_empty_folder_fail(self):
        self.png('en-US/01.png')
        with self.assertRaisesRegex(ValueError,'Missing locale'):
            build_manifest(self.root,'ios',['en-US','ja'])
        (self.root/'ko').mkdir()
        with self.assertRaises(ValueError):build_manifest(self.root,'ios')

    def test_android_categories_counts_and_conditional_wear(self):
        for i in range(4):self.png(f'ko-KR/ten-inch/{i}.png',(1920,1080),f'#{i+1}12345')
        rows=build_manifest(self.root,'android',devices=['ten-inch'])['sets']
        self.assertEqual(rows[0]['display_type'],'tenInchScreenshots')
        with self.assertRaisesRegex(ValueError,'Missing device'):
            build_manifest(self.root,'android',devices=['phone','ten-inch'])
        image_info(self.png('wear.png',(384,384)),'android','wear')
        with self.assertRaises(ValueError):image_info(self.png('wear.png',(1080,1920)),'android','wear')

    def test_android_phone_limits_and_large_screen_are_separate(self):
        image_info(self.png('large.png',(4320,7680)),'android','ten-inch')
        with self.assertRaises(ValueError):image_info(self.root/'large.png','android','phone')
        with self.assertRaises(ValueError):image_info(self.png('ratio.png',(1080,2400)),'android','phone')
        with self.assertRaises(ValueError):image_info(self.png('ratio.png',(1080,1600)),'android','ten-inch')

    def test_android_minimum_and_maximum(self):
        self.png('en-US/phone/01.png',(1080,1920))
        with self.assertRaisesRegex(ValueError,'at least two'):build_manifest(self.root,'android')
        for i in range(2,10):self.png(f'en-US/phone/{i:02d}.png',(1080,1920),f'#{i}12345')
        with self.assertRaisesRegex(ValueError,'maximum 8'):build_manifest(self.root,'android')

    def test_provenance_blocks_placeholder_and_draft_exports(self):
        self.png('en-US/01.png')
        (self.root/'export-status.json').write_text(json.dumps({'production_ready':False,'locales':['en-US']}))
        with self.assertRaisesRegex(ValueError,'real captures'):build_manifest(self.root,'ios',provenance=True)

    def test_staging_only_images_preserves_other_sets_and_order(self):
        self.png('en-US/01.png')
        (self.root/'en-US/work.html').write_text('not uploadable')
        dest=Path(self.temp.name)/'upload'
        (dest/'en-US').mkdir(parents=True)
        Image.new('RGB',(2048,2732),'red').save(dest/'en-US/ipad.png')
        result=stage(build_manifest(self.root,'ios'),dest)
        self.assertTrue((dest/'en-US/ipad.png').exists())
        self.assertFalse((dest/'en-US/work.html').exists())
        self.assertTrue((dest/result['sets'][0]['images'][0]['path']).exists())

if __name__=='__main__':unittest.main()
