#!/bin/bash
set -e

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Usage: ./build_release.sh <version>"
  echo "Example: ./build_release.sh 0.2"
  exit 1
fi

REPO="razscarl/metal_tracker"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

echo ""
echo "========================================="
echo "  Metal Tracker v$VERSION"
echo "========================================="

# 1. Update pubspec.yaml and config.json version
python -c "
import re, json

# Update pubspec.yaml
with open('pubspec.yaml', 'r') as f:
    content = f.read()
content = re.sub(r'^version: .*', 'version: ${VERSION}+1', content, flags=re.MULTILINE)
with open('pubspec.yaml', 'w') as f:
    f.write(content)

# Update APP_VERSION in config.json
with open('config.json', 'r') as f:
    config = json.load(f)
config['APP_VERSION'] = '${VERSION}'
with open('config.json', 'w') as f:
    json.dump(config, f, indent=2)

print('Version updated to ${VERSION}')
"

# 2. Build APK
echo ""
echo "--- Building Android APK ---"
flutter build apk --release --dart-define-from-file=config.json
echo "APK built successfully"

# 3. Build web
echo ""
echo "--- Building Web ---"
flutter build web --release --no-tree-shake-icons --dart-define-from-file=config.json 2>&1
echo "Web built successfully"

# 4. Apply custom icons to web build
echo ""
echo "--- Applying custom icons ---"
python -c "
from PIL import Image
img = Image.open('assets/logo.png').convert('RGBA')
sizes = {
    'build/web/icons/Icon-192.png': 192,
    'build/web/icons/Icon-512.png': 512,
    'build/web/icons/Icon-maskable-192.png': 192,
    'build/web/icons/Icon-maskable-512.png': 512,
    'build/web/favicon.png': 32,
}
for path, size in sizes.items():
    img.resize((size, size), Image.LANCZOS).save(path)
    print(f'  {path}')
"

# 5. Commit version bump
echo ""
echo "--- Committing version bump ---"
git add pubspec.yaml
git commit -m "Bump version to v${VERSION}"

# 6. Tag and push
git tag "v${VERSION}"
git push origin master
git push origin "v${VERSION}"
echo "Tagged v${VERSION} and pushed"

# 7. Get GitHub token
TOKEN=$(printf "protocol=https\nhost=github.com\n" | git credential fill | grep ^password | cut -d= -f2-)

# 8. Create GitHub release
echo ""
echo "--- Creating GitHub release ---"
RELEASE_RESPONSE=$(curl -s -X POST "https://api.github.com/repos/${REPO}/releases" \
  -H "Authorization: token ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"tag_name\": \"v${VERSION}\",
    \"name\": \"v${VERSION}\",
    \"body\": \"Metal Tracker v${VERSION}\",
    \"draft\": false,
    \"prerelease\": true
  }")

RELEASE_ID=$(echo "$RELEASE_RESPONSE" | python -c "import sys,json; d=json.load(sys.stdin); print(d.get('id','ERROR: ' + d.get('message','unknown')))")
echo "Release ID: ${RELEASE_ID}"

# 9. Upload APK to release
echo "Uploading APK..."
curl -s -X POST "https://uploads.github.com/repos/${REPO}/releases/${RELEASE_ID}/assets?name=metal-tracker-v${VERSION}.apk" \
  -H "Authorization: token ${TOKEN}" \
  -H "Content-Type: application/vnd.android.package-archive" \
  --data-binary @"${APK_PATH}" | python -c "import sys,json; d=json.load(sys.stdin); print('APK upload:', d.get('state','error'))"

# 10. Deploy web to gh-pages
echo ""
echo "--- Deploying to GitHub Pages ---"

# Clean up any stale worktree
git worktree prune 2>/dev/null || true
git worktree add -f ../metal_tracker_ghpages gh-pages
rm -rf ../metal_tracker_ghpages/*
cp -r build/web/* ../metal_tracker_ghpages/

cd ../metal_tracker_ghpages
git add -A
git commit -m "Deploy v${VERSION} to GitHub Pages"
git push origin gh-pages
cd -

git worktree prune 2>/dev/null || true

echo ""
echo "========================================="
echo "  Release v${VERSION} complete!"
echo "  GitHub: https://github.com/${REPO}/releases/tag/v${VERSION}"
echo "  Web:    https://razscarl.github.io/metal_tracker/"
echo "========================================="
