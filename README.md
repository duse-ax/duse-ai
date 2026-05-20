# 두꺼비세상 AI 플러그인 마켓플레이스

두꺼비세상 AX팀이 만들고 큐레이션하는 Claude Code 플러그인 모음입니다.
**한국어 기반**, 한국 SME 도메인에 특화된 도구를 매주 추가합니다.

---

## 설치

### 1단계 — 마켓플레이스 추가 (1회만)

Claude Code 안에서 다음 명령을 입력합니다:

```
/plugin marketplace add mjkwon-aptner/duse-ai-plugin
```

> ⚠️ 이 명령은 Claude Code 인터페이스 안에서 실행하는 것입니다.
> 일반 터미널(zsh/bash)에 그대로 치면 `no such file` 에러가 나니, 반드시 Claude Code 세션 안에서 입력하세요.

성공하면 "Marketplace 'duse-ai-plugin' added" 메시지가 뜹니다.

### 2단계 — 원하는 플러그인 설치

```
/plugin install retrospect@duse-ai-plugin          # 데일리 회고
/plugin install duse-connectors@duse-ai-plugin     # 사내 자원 통합 액세스 (Sheets 등)
```

각 플러그인은 별도로 install 가능. 모두 설치해도 OK.

### 3단계 — 플러그인별 추가 셋업

플러그인에 따라 의존성 설치·인증 등 추가 셋업이 필요할 수 있습니다. 각 플러그인 카드의 "사용법" 섹션 참고:
- [retrospect](#retrospect--데일리-회고) — 첫 실행 시 저장 경로 prompt
- [duse-connectors](#duse-connectors--사내-자원-통합-액세스) — `pip install` + OAuth 1회 동의

---

## 플러그인 목록

### `retrospect` — 데일리 회고

매일 퇴근 전 5분 안에 끝나는 minimal 회고 도구입니다. 단순 일기가 아니라 **방향성 자가검열 + comfort zone 강제 이탈**을 시스템적으로 박아넣는 ritual.

- 5개 질문 (핵심 한 일 / **불편한 행동** / 시행착오 / 방향성 점검 / 내일 액션)
- YAML frontmatter 자동 생성 → 향후 대시보드·aggregation 가능
- AX 본업 vs ASOS 시간 비율 강제 수치 입력
- 3일 연속 comfort zone 상태일 때 자동 alert
- 첫 실행 시 저장 경로 사용자 지정 (이후 변경 가능)

**사용법**:

```
/retrospect:daily
```

첫 실행:
1. 저장 폴더 경로 prompt → 사용자 입력 (기본값 제공)
2. `~/.retrospect/config.json` 자동 생성
3. 바로 오늘 회고 시작

일상 사용:
- 5문항에 답하면 `{base_dir}/YYYY-MM-DD.md` 로 저장
- 방향성과 성장이 매일 누적되는 raw material 확보

상세 → [plugins/retrospect/](./plugins/retrospect/)

### `duse-connectors` — 사내 자원 통합 액세스

검색이 아니라 **실제 작업까지** — 두꺼비세상 사내 자원에 Claude가 자연어로 직접 read+write 액세스. Sheets·Notion·Slack·Drive·콘솔·DB 등 매일 쓰는 도구를 한 곳에서 묶어 처리합니다.

- 멀티 Google Workspace 자동 분기 (@aptner.com / @duse.kr)
- OAuth Loopback Flow — 첫 사용 1클릭 동의로 끝, 이후 자동 토큰 갱신
- 사내 직원 1인1계정 (각자 본인 Google 계정으로 인증, 감사 가능)
- skill 단위 확장 — 첫 skill `google-sheets` 시작, 향후 Notion/Slack/Drive 등 추가 예정

**사용법**:

```
/plugin install duse-connectors@duse-ai-plugin
```

첫 셋업 (1회만):
1. `pip install -r <plugin>/skills/google-sheets/scripts/requirements.txt`
2. `python <plugin>/skills/google-sheets/scripts/auth.py` → 브라우저 자동 → 본인 회사 계정 로그인 → 끝

OAuth Client (credentials JSON)는 plugin에 이미 포함되어 있어 직원이 별도로 받을 필요 없음.

자연어 사용:
```
"이 시트 A1:D10 읽어줘: https://docs.google.com/..."
"방금 분석 결과 새 시트로 정리해줘"
"Sheet1 첫 행 굵게 + 회색 배경"
"새 탭 '시나리오' 추가해서 [[...]] 써줘"
```

상세 → [plugins/duse-connectors/](./plugins/duse-connectors/)

### `duse-tools` — 사내용 라이트 유틸리티 모음

매일 쓰는 작은 도구들의 집합. 시스템 통합(`duse-connectors`)이나 회고(`retrospect`) 영역에 들어가지 않는 라이트 유틸은 모두 여기로.

**현재 포함**:
- **`chromux`** — Real Chrome 브라우저 자동화 ([team-attention/chromux](https://github.com/team-attention/chromux) fork, MIT)
- **`chromux-work`** — chromux 위 워크플로우 오케스트레이션

**향후 추가 예정**: 텍스트 변환·파일 일괄 처리·OCR·사내 콘솔 매크로 등

**사용법**:

```
/plugin install duse-tools@duse-ai-plugin
```

추가 셋업 — chromux CLI 글로벌 설치 (1회):

```bash
git clone https://github.com/team-attention/chromux ~/team-attention/chromux
cd ~/team-attention/chromux && npm install -g .
```

(Node.js >= 22 + Google Chrome 필요)

자연어 사용:
```
"이 페이지 스크린샷 찍어줘: https://..."
"실제 Chrome 띄워서 ASOS 로그인하고 데이터 가져와줘"
```

상세 → [plugins/duse-tools/](./plugins/duse-tools/)

---

## 마켓플레이스 구조

이 저장소는 [Claude Code 공식 plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces) 규격을 따릅니다. [team-attention/plugins-for-claude-natives](https://github.com/team-attention/plugins-for-claude-natives) 의 구조를 참고했습니다.

```
duse-ai-plugin/
├── .claude-plugin/
│   └── marketplace.json          # 마켓플레이스 manifest
├── plugins/
│   └── retrospect/               # 첫 플러그인
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/
│           └── daily/
│               └── SKILL.md
├── assets/                        # 데모 GIF·이미지
├── README.md                      # 본 문서 (한국어 마스터)
└── LICENSE                        # MIT
```

---

## 새 플러그인 추가 (내부 가이드)

새 플러그인을 마켓플레이스에 등록할 때 따라야 할 절차입니다.

### 체크리스트

1. [ ] `plugins/<plugin-name>/` 폴더 생성
2. [ ] `plugins/<plugin-name>/.claude-plugin/plugin.json` 작성 (name, version, description은 **한국어**)
3. [ ] `plugins/<plugin-name>/skills/<skill-name>/SKILL.md` 작성 (description은 **한국어**, frontmatter에 trigger 예시 포함)
4. [ ] 마스터 `.claude-plugin/marketplace.json`의 `plugins` 배열에 항목 추가
5. [ ] 본 `README.md`의 "## 플러그인 목록" 섹션에 ### 카드 추가
6. [ ] (선택) `assets/<plugin-name>-demo.gif` 추가
7. [ ] 사내 `#ax-daily` 슬랙 채널에 신규 플러그인 1줄 소개 + GIF

### 카드 양식

새 플러그인을 README에 추가할 때 다음 양식을 따릅니다:

```markdown
### `<plugin-name>` — <한국어 한 줄 요약>

<2-3줄 본문 — "왜 만들었나" 1줄 + "무엇이 가능해지나" 1-2줄>

- <feature 1>
- <feature 2>
- <feature 3>

**사용법**:
\`\`\`
/<plugin-name>:<skill-name>
\`\`\`

상세 → [plugins/<plugin-name>/](./plugins/<plugin-name>/)
```

### 설명 작성 원칙

- 모든 문구 **한국어** (영문 명사·기술 용어는 그대로 OK: API, MCP, skill, frontmatter, YAML 등)
- 사용 예시 1개 이상 필수
- "왜 만들었나" 1줄은 사내 사용자에게 동기 부여하는 톤으로

---

## 운영 원칙

이 마켓플레이스는 다음 원칙을 따릅니다:

1. **매주 최소 1개 push** — AX팀이 주 1회 이상 새 플러그인 또는 기존 플러그인 개선
2. **한국어 우선** — 사내 사용자를 1차 대상, 영문 README 추후 필요시
3. **사내 사용량으로 검증** — 외부 공개 전 사내에서 N명 이상 사용 검증
4. **사례 컨텐츠화** — 모든 신규 플러그인은 사내 슬랙·노션에 사용 후기 1편 이상 동반

---

## License

[MIT](./LICENSE)

---

## 만든 사람

**두꺼비세상 AX팀**
- 메인: 권민재 ([@mjkwon-aptner](https://github.com/mjkwon-aptner))

문의·기여·이슈는 [GitHub Issues](https://github.com/mjkwon-aptner/duse-ai-plugin/issues) 또는 사내 `#ax-daily` 슬랙 채널로.
