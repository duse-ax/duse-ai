# navercafe-crawl

네이버 카페 게시판 URL 하나로 **모든 게시글 + 전체 댓글**을 엑셀(정보/게시글/댓글 3시트)로 뽑는 스킬. `duse-tools` 플러그인에 포함되어 있어, 같은 플러그인의 **chromux**로 로그인까지 처리한다.

수집 항목: 제목 · 본문(원문 그대로, 이미지/표/스크랩 출처 보존) · 작성자 · 작성일 · 조회수 · 댓글수 · 추천수 · 첨부 · **전체 댓글** · 원문링크.

---

## 설치

### 방법 A — 플러그인 설치 (권장). Claude Code에 아래 두 줄을 그대로 입력
```
/plugin marketplace add duse-ax/duse-ai
/plugin install duse-tools@duse-ai-plugin
```
> 이건 **Claude Code 세션 안에서** 입력하는 명령입니다(일반 터미널 아님).
> `duse-tools`를 깔면 chromux + navercafe-crawl 이 함께 들어옵니다.

### 방법 B — 프롬프트로 직접 설치 (복사해서 Claude Code에 붙여넣기)
플러그인 마켓플레이스를 안 쓰고 스킬만 바로 깔고 싶을 때. 아래 블록을 **그대로 복사해 Claude Code 대화창에 붙여넣기**:

```
duse-ax/duse-ai 레포에서 navercafe-crawl 스킬(과 의존하는 chromux)을 내 Claude Code에 설치해줘. 아래대로 진행하고, 끝나면 사용법 한 줄로 알려줘:

TMP=$(mktemp -d)
git clone --depth 1 --filter=blob:none --sparse https://github.com/duse-ax/duse-ai "$TMP"
git -C "$TMP" sparse-checkout set plugins/duse-tools/skills/navercafe-crawl plugins/duse-tools/skills/chromux
mkdir -p ~/.claude/skills
rm -rf ~/.claude/skills/navercafe-crawl ~/.claude/skills/chromux
cp -R "$TMP/plugins/duse-tools/skills/navercafe-crawl" ~/.claude/skills/
cp -R "$TMP/plugins/duse-tools/skills/chromux" ~/.claude/skills/
chmod +x ~/.claude/skills/navercafe-crawl/scripts/*.sh
rm -rf "$TMP"

그다음 Claude Code를 재시작하면 navercafe-crawl 스킬이 뜬다고 안내해줘. (사내 레포라 git 접근 권한 필요)
```

---

## 사용
설치 후 Claude Code에 자연어로:
```
이 네이버 카페 게시판 전부 크롤링해서 엑셀로 만들어줘
https://cafe.naver.com/f-e/cafes/24646884/menus/30
```
스킬이 자동으로: **의존성 점검·설치 → 로그인 → 전수 수집 → 엑셀 생성**.

## 사전 준비물 (스킬이 자동 설치 못 하는 것)
- **Google Chrome** (chromux가 실제 크롬을 구동)
- **Node.js 22+** (chromux 데몬 요건)

나머지(chromux CLI, Python 라이브러리 bs4/lxml/openpyxl)는 스킬의 preflight가 자동 설치한다.

## 반드시 알아야 할 전제
- 로그인 계정이 **대상 카페의 "회원"** 이어야 본문이 보인다(비회원이면 목록만, 본문 401/403).
- 로그인 시 네이버 **이미지 캡차**가 뜰 수 있음(스킬이 이미지를 읽어 통과 시도). 강한 2차 인증이면 사람이 직접 로그인.
- 비밀번호를 대화에 남기지 않으려면 **로그인 창에서 직접 로그인 + ‘로그인 상태 유지’ 체크**(권장). 이후 실행은 로그인 생략.

## 구성
```
navercafe-crawl/
├── SKILL.md                     # Claude 실행 절차(로그인·캡차·쿠키·수집·정리) + 함정 기록
├── README.md                    # (이 파일) 설치/사용
├── scripts/
│   ├── preflight.sh             # 의존성 점검·자동 설치, Node22 경로 확보
│   └── crawl.py                 # 열거→병렬수집→파싱→엑셀 (자체완결, stdlib+bs4+openpyxl)
└── references/naver-cafe-api.md  # 네이버 카페 내부 API 근거(재분석 불필요)
```
