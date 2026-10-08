"""Structural checks only; run xcodebuild on macOS to check Swift compilation."""
from pathlib import Path
import json
import re
import unicodedata
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
catalog = json.loads((root / 'ProbePsy/Languages.json').read_text())
assert set(catalog) == {'de', 'en', 'tr'}
keys = set(catalog['de'])
for language, strings in catalog.items():
    assert set(strings) == keys, language
    assert all(isinstance(s, str) and s.strip() for s in strings.values())
source = '\n'.join(p.read_text() for p in (root / 'ProbePsy').glob('*.swift'))
used = set(re.findall(r'\bt\("([^"]+)"\)', source)) | {'languageName', 'riskPhrases'}
assert used <= keys, used - keys
project = (root / 'ProbePsy.xcodeproj/project.pbxproj').read_text()
for path in (root / 'ProbePsy').iterdir():
    assert f'path = {path.name};' in project, path.name
ET.parse(root / 'ProbePsy.xcodeproj/xcshareddata/xcschemes/ProbePsy.xcscheme')
assert 'URLSession' not in source and 'CloudKit' not in source.replace('CloudKit,', '')
assert 'kSecAttrAccessibleWhenUnlockedThisDeviceOnly' in source
assert 'isExcludedFromBackup = true' in source
assert 'AES.GCM.seal' in source and '.completeFileProtection' in source
# Mirror phrase normalization to catch missing multilingual examples. This does not test Swift execution.
def normalize(value):
    value = unicodedata.normalize('NFKD', value.replace('ı', 'i').casefold())
    value = ''.join(c for c in value if not unicodedata.combining(c))
    return ' '.join(re.findall(r'\w+', value))
phrases = [normalize(p) for strings in catalog.values() for p in strings['riskPhrases'].split('|')]
for sample in ['ich will nicht mehr aufwachen', 'Es hat keinen Sinn mehr', "I don't want to wake up", 'uyanmak istemiyorum', 'ich werde ihn töten', 'İNTİHAR']:
    assert any(p in normalize(sample) for p in phrases), sample
print(f'PASS: {len(keys)} keys × 3 languages; project resources, scheme, privacy markers and crisis examples.')
print('Not a Swift build or a clinical validation. Next: xcodebuild on macOS.')
