#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$ROOT_DIR/Info.plist")
APP_BUNDLE="$ROOT_DIR/KSwitch.app"
DMG_NAME="KSwitch_v${VERSION}.dmg"
DMG_PATH="$ROOT_DIR/$DMG_NAME"
STAGING_DIR="$ROOT_DIR/.dmg_staging"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

echo "[1/3] Building KSwitch.app v${VERSION}..."
"$ROOT_DIR/build.sh"

echo "[2/3] Staging DMG contents..."
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

cp -R "$APP_BUNDLE" "$STAGING_DIR/KSwitch.app"
xattr -cr "$STAGING_DIR/KSwitch.app" 2>/dev/null || true
ln -s /Applications "$STAGING_DIR/응용 프로그램"

cat <<'EOF' > "$STAGING_DIR/설치 및 실행 안내.txt"
========================================================
  KSwitch (맥한영) - 일반 PC 키보드 맥 미니 필수 유틸리티
========================================================

[설치 방법]
1. 왼쪽의 'KSwitch.app' 아이콘을 오른쪽 '응용 프로그램' 폴더로 드래그하세요.
2. '응용 프로그램' 폴더에서 KSwitch를 실행하세요.

[최초 실행 시 "확인되지 않은 개발자" 경고가 뜰 때]
무료 오픈 배포 앱(미공증)이므로 최초 1회 보안 허용이 필요합니다.
- 방법 1: 앱 실행 후 경고가 뜨면 [시스템 설정 > 개인정보 보호 및 보안] 하단에서
          "확인 없이 열기" 버튼을 클릭하세요.
- 방법 2: 터미널에서 아래 명령어를 입력한 뒤 실행하세요.
          xattr -cr /Applications/KSwitch.app

[주요 기능]
- 일반 키보드 '한/영' 키 즉시 전환 (보안 권한 불필요)
- '한자' 키 지원 (한자 키 사용 시에만 손쉬운 사용 권한 1회 허용)
- Caps Lock 대문자 잠금(A↔a) 전용 고정
- 윈도우식 왼쪽 Ctrl ↔ Win(Command) 교환 (Ctrl+C/V/Z 복붙)
- Win+E(파인더), Win+D(바탕화면), Win+L(잠금), Win+Shift+S(캡처)
- Home / End 줄 맨 앞/뒤 이동 보정
- 상단 메뉴바(한/A)에서 '로그인 시 자동 실행' 켜기/끄기 가능
EOF

echo "[3/3] Creating compressed DMG: $DMG_NAME..."
hdiutil create \
  -volname "KSwitch v${VERSION}" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "DMG created successfully: $DMG_PATH"
