# KSwitch (맥한영) — 불편해서 내토내만 🇰🇷⌨️

맥 미니(Mac mini)나 맥북에 일반 윈도우(PC) 키보드를 연결했을 때 생기는 **한/영 전환·복붙·단축키 불편을 클릭 한 번으로 해결**해 주는 초경량 순수 Swift 네이티브 메뉴바 앱입니다.
> **"불편해서 내토내만 (내 토큰 써서 내가 만듦)"** — Karabiner-Elements 같은 무거운 가상 드라이버 없이 macOS 내장 `hidutil`과 Carbon API를 사용해 CPU/메모리 점유율이 극도로 낮습니다.

---

## 주요 기능

1. **일반 키보드 `한/영` 키 즉시 전환** (`Lang1` / `Right Alt` → 0ms 전환, **보안 권한 불필요**)
2. **일반 키보드 `한자` 키 지원** (`Lang2` / `Right Ctrl` → macOS 한자 변환 `Option + Return`)
3. **`Caps Lock` 대문자(`A ↔ a`) 전환 전용 고정** (`TISSetRomanSwitchState(0)` 적용)
4. **윈도우식 `왼쪽 Ctrl` ↔ `왼쪽 Win(Command)` 교환** (`Ctrl + C / V / X / Z / A / F / T / W`)
5. **윈도우 키(`Win`) 고유 단축키 4종**
   * `Win + E`: Finder(파일 탐색기) 열기
   * `Win + D`: 바탕화면 바로 보기
   * `Win + L`: 맥 화면 즉시 잠금
   * `Win + Shift + S`: 화면 캡처 (`Screenshot.app`)
6. **윈도우식 `Home / End` 줄 맨 앞/뒤 이동 보정** (`DefaultKeyBinding.dict` 자동 관리)
7. **플로팅 전환 알림 (HUD)** — 한/영 전환 시 화면에 깔끔한 `[한]` / `[A]` 배지 표시
8. **키 눌러서 테스트 / 직접 지정** & **맥 로그인 시 자동 실행**

---

## 사용자 설치 및 최초 실행 방법

1. [GitHub Releases](https://github.com/NAETOKENNAEGAMAKE/KSwhitch/releases) (또는 저장소의 `KSwitch_v1.2.1.dmg`)에서 설치 파일을 다운로드해 열고, `KSwitch.app`을 **`응용 프로그램(Applications)`** 폴더로 드래그합니다.
2. 개인 무료 오픈 배포(애플 공증 미적용) 앱이므로 최초 1회 실행 시 macOS 보안 경고가 뜰 수 있습니다:
   * **방법 A**: 실행 후 경고가 뜨면 `시스템 설정 > 개인정보 보호 및 보안` 하단에서 **"확인 없이 열기"**를 클릭합니다.
   * **방법 B**: 터미널에서 아래 명령어 실행 후 앱을 엽니다.
     ```bash
     xattr -cr /Applications/KSwitch.app
     ```
3. 상단 메뉴바의 **`한` / `A`** 아이콘을 클릭해 `설정 및 키 테스트 열기...`에서 원하는 옵션을 켜고 끄세요.

---

## 직접 빌드 및 DMG 패키징 (개발자용)

```bash
chmod +x build.sh package_dmg.sh
./package_dmg.sh
```

* 후원 URL 설정: `Info.plist`의 `KSwitchDonationURL` (`https://buymeacoffee.com/bli1103`)
* 후원 QR 이미지: `Resources/donation_qr.png` (빌드 시 앱 번들 내부에 자동 포함)

---

## 후원하기 ☕

KSwitch로 편해지셨다면 다음 업데이트를 위해 태울 토큰값(커피 한 잔)으로 응원해 주세요!
* **Buy Me a Coffee**: https://buymeacoffee.com/bli1103
* 앱 내 `[☕ 개발자에게 커피 한 잔 후원하기]` 버튼에서 아이폰 QR 스캔(Apple Pay / 카드)도 지원합니다.

---

## 커뮤니티 공유용 글 양식 (복사해서 바로 사용)

```markdown
제목: [불편해서 내토내만] 맥 미니 일반 키보드 한영/윈도우키 초경량 패치 앱 'KSwitch' 무료 공유합니다

맥 미니에 기존에 쓰던 일반 윈도우 키보드를 꽂아 쓰다 보니
한/영 키 먹통, Caps Lock 씹힘, Ctrl 복붙 위치, Home/End 줄 이동 때문에 답답해서
Karabiner 없이 가볍게 돌아가는 순수 Swift 메뉴바 앱을 직접 만들어 봤습니다.
(100% 내토내만 — 내 토큰 써서 내가 만듦 😅)

[주요 기능]
- 일반 키보드 '한/영' 키 즉시 전환 (보안 권한 팝업 없음)
- Caps Lock은 대문자 전환 전용으로 고정
- 왼쪽 Ctrl ↔ Win 키 교환 (Ctrl+C/V/Z 그대로 사용)
- Win+E(파인더), Win+D(바탕화면), Win+L(화면 잠금), Win+Shift+S(캡처)
- Home/End 줄 맨 앞/뒤 이동 보정
- 한/영 전환 시 화면에 [한] / [A] 플로팅 HUD 표시
- 상단 메뉴바에서 모든 옵션 개별 ON/OFF 및 로그인 자동 실행 지원

[설치 방법]
1. GitHub에서 KSwitch_v1.2.1.dmg 다운로드 후 응용 프로그램 폴더로 복사
   - 다운로드: https://github.com/NAETOKENNAEGAMAKE/KSwhitch/releases
2. 개인 제작 무료 앱이라 최초 실행 시 [시스템 설정 > 개인정보 보호 및 보안 > 확인 없이 열기] 1회 클릭 필요
   (또는 터미널에서 `xattr -cr /Applications/KSwitch.app`)

유용하게 쓰셨다면 앱 내 [커피 한 잔 후원하기]로 토큰 충전비 보태주시면 감사하겠습니다!
- GitHub: https://github.com/NAETOKENNAEGAMAKE/KSwhitch
- Buy Me a Coffee: https://buymeacoffee.com/bli1103
```

---

## 라이선스 및 면책 조항 (MIT License)

본 소프트웨어는 [MIT License](LICENSE)에 따라 무료로 제공됩니다.
본 프로그램은 있는 그대로("AS IS") 제공되며, 사용으로 인해 발생하는 모든 결과에 대한 책임은 사용자 본인에게 있습니다.
