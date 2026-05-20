# duse-ai-plugin 운영 규칙 (AI agents용)

본 repo에서 작업하는 Claude/Codex/Gemini 등 AI agent는 아래 규칙을 반드시 지킬 것.

## 🔴 MANDATORY — README 동기화

**plugin 또는 skill을 추가/변경/삭제할 때마다, 반드시 top-level `README.md`도 함께 업데이트한다.**

체크리스트 (`README.md`의 "새 플러그인 추가 (내부 가이드)" 섹션 그대로):

1. [ ] `plugins/<plugin-name>/` 폴더 생성
2. [ ] `plugins/<plugin-name>/.claude-plugin/plugin.json` 작성 (name, version, description은 **한국어**)
3. [ ] `plugins/<plugin-name>/skills/<skill-name>/SKILL.md` 작성 (description은 **한국어**, frontmatter에 trigger 예시 포함)
4. [ ] **루트 `.claude-plugin/marketplace.json`의 `plugins` 배열에 항목 추가** ← 빠뜨리지 말 것
5. [ ] **루트 `README.md`의 "## 플러그인 목록" 섹션에 ### 카드 추가** ← 빠뜨리지 말 것
6. [ ] (선택) `assets/<plugin-name>-demo.gif`
7. [ ] 사내 `#ax-daily` 슬랙 채널에 1줄 소개 + GIF

기존 plugin에 **새 skill만 추가**하는 경우에도:
- [ ] 해당 plugin 카드의 "현재 포함" / "skills 예시"에 새 skill 한 줄 추가
- [ ] 해당 plugin 폴더 안의 README.md도 업데이트

## ✍️ 작성 원칙

- 모든 user-facing 문구 **한국어** (영문 명사/기술 용어는 그대로 OK: API, MCP, skill, frontmatter, YAML)
- 사용 예시 1개 이상 필수
- "왜 만들었나" 1줄은 사내 사용자에게 동기 부여하는 톤
- 트리거 키워드는 자연어 그대로 (예: "구글 시트에 정리해줘")

## 🔀 Fork 정책

외부 repo의 skill을 fork할 경우:
- 본 plugin 폴더 안 `UPSTREAM_VERSION` 파일에 `<version>@<sha>` 기록
- 본 plugin `README.md`에 attribution + 상류 링크 + License 명시
- 분기별 점검으로 상류 변경 수동 sync

## 💬 Commit Convention

기존 패턴 (`9c091ea`, `7f70309`, `c00bfcd` 등) 따라가기:

- 형식: `<type>: <한 줄 한국어 요약>`
- type: `feat` (신규 plugin/skill), `docs`, `chore`, `fix`, `refactor`
- 본문: 한국어, 무엇을 + 왜
- `Co-Authored-By` 일반적으로 추가 안 함 (기존 커밋에 없음)

## 🔐 Secrets

- `credentials.json` (개인 OAuth) → `.gitignore`
- `credentials_<domain>.json` (사내 공용 OAuth, Internal type + Desktop App) → 의도된 공개로 git에 포함 OK
  - GitHub Push Protection 발생 시 unblock URL 사유 "False positive" 또는 "Used in tests"
- 토큰 파일 (`~/.config/gspread/authorized_user*.json`) → 절대 commit 금지 (각 사용자 PC 로컬)

## 🚀 Push 전 체크

- `git pull --rebase origin main` 으로 원격 최신화
- public repo이므로 secrets 노출 항상 의식
- 무엇이 변경됐는지 `git diff --stat HEAD~1` 한 번 확인 권장
