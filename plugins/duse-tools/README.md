# duse-tools (두꺼비세상 사내 유틸리티 모음)

매일 쓰는 작은 도구들

## 현재 포함된 skills

### `chromux` — Real Chrome 브라우저 자동화
사용자의 실제 Chrome을 사용 (로그인 유지, 봇 감지 회피). Playwright/Puppeteer 같은 별도 Chromium 안 쓰고 Chrome DevTools Protocol 직접 호출. 0 의존성 단일 파일 CLI.

### `chromux-work` — 브라우저 작업 오케스트레이션
chromux 위에서 동작하는 워크플로우 — profile 선택, recon, 병렬 작업, 정리, 도메인 노트. 일반 브라우저 작업의 표준 절차.

> 위 두 skill(chromux, chromux-work)은 [team-attention/chromux](https://github.com/team-attention/chromux) 의 fork (MIT License). 상류 버전은 `UPSTREAM_VERSION` 참고.

### `seminar-archive` — Tiro 세미나 → Notion 인사이트 DB
Tiro로 녹음한 세미나·외부행사의 '한 페이지 문서'(AI 요약)를 노션 `AX - 세미나 및 행사 인사이트` DB에 적재한다. 본문은 지어내지 않고 Tiro 요약을 **그대로(verbatim) 복사**하며, 내부 링크 대신 **공개 공유 링크**(`tiro.ooo/s/...`)를 원본으로 건다. 필요 MCP: Tiro(`mcp__tiro__*`) + Notion connector(`duse-connectors`). 공유 링크 생성만 Tiro REST API 쓰기 키 사용.

```
"오늘 세미나 노션에 정리해줘"
"이 Tiro 녹음 세미나 인사이트 DB에 추가해줘"
```

## 설치

### 1. plugin install
```
/plugin install duse-tools@duse-ai-plugin
```

### 2. chromux CLI 설치 (1회)

chromux는 npm CLI 형태라 별도 글로벌 설치가 필요합니다:

```bash
# 사전 조건: Node.js >= 22 + Google Chrome
git clone https://github.com/team-attention/chromux ~/team-attention/chromux
cd ~/team-attention/chromux
npm install -g .

# 확인
chromux help
```

### 3. 사용

skill에 자동으로 등록되므로 Claude에게 자연어로 요청:

```
"이 페이지 스크린샷 찍어줘: https://aptner.com"
"실제 Chrome 띄워서 콘솔 로그인하고 단지 검색 결과 가져와줘"
"3개 탭 병렬로 띄워서 각각 다른 단지 데이터 수집해줘"
```

## 향후 추가 예정 skills

라이트 유틸리티 — 매일 쓰는 작은 도구는 모두 여기에 모일 예정:
- 텍스트 변환 (csv/json/yaml 상호 변환)
- 파일 일괄 처리 (이름 변경, 압축, OCR 등)
- 사내 콘솔 매크로 (반복 작업 자동화)
- 기타 직원이 자주 쓰는 일회용 자동화

새 skill 추가 시 `skills/<skill-name>/SKILL.md`만 생성하면 자동 등록.

## 라이선스 (fork)

- 본 plugin의 `skills/chromux/`, `skills/chromux-work/`, `snippets/_builtin/`은 [team-attention/chromux](https://github.com/team-attention/chromux) v0.7.0 (커밋 `00536b4`) 의 fork
- 상류: **MIT License** (team-attention)
- 상류 업데이트 시 수동 sync (분기별 점검)
- 두꺼비세상 자체 추가 skill은 본 repo License 적용
