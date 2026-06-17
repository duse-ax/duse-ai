---
name: seminar-archive
description: "Tiro로 녹음한 세미나·외부행사 인사이트를 노션 'AX - 세미나 및 행사 인사이트' DB에 적재한다. Tiro '한 페이지 문서'(요약)를 본문에 그대로 복사하고, 공개 공유 링크를 생성해 원본 링크로 건다. 트리거 — '세미나 정리', '세미나 노션에 추가', '세미나 인사이트 적재', 'tiro 세미나 아카이브', '행사 인사이트 노션', 'seminar archive'."
version: 0.1.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [notion, tiro, seminar, meeting-notes, archive, knowledge]
    category: knowledge
---

# seminar-archive — Tiro 세미나 → Notion 인사이트 DB

AX팀이 참여한 세미나·컨퍼런스·웨비나를 팀 자산으로 쌓는다. 원본 녹취는 Tiro에 두고, 노션에는 **Tiro 한 페이지 문서(요약)를 그대로 복사한 본문** + 스캔용 컬럼만 남긴다.

> 필요한 MCP: **Tiro MCP**(`mcp__tiro__*`, 읽기 전용) + **Notion MCP**(`duse-connectors`의 notion connector — `notion-fetch`/`notion-create-pages`/`notion-update-data-source` 등). 공유 링크 생성은 Tiro REST API(쓰기 키) 사용.

## 핵심 원칙 (반드시 지킬 것)

1. **본문은 직접 작성하지 않는다.** Tiro 노트의 **한 페이지 문서(= AI 요약)를 마크다운 그대로 복사**해 노션 본문에 넣는다. 시사점/액션 등을 지어내지 않는다.
2. **원본 링크는 반드시 공개 공유 링크(`https://tiro.ooo/s/{shareId}`)** 를 건다. 내부 링크(`https://tiro.ooo/n/{id}`)는 로그인해야 열리므로 **절대 쓰지 않는다.**
3. **컬럼은 최소 구성 유지.** 아래 6개(제목 포함) 외에 함부로 늘리지 않는다.
4. **API 키는 어디에도 저장하지 않는다.** (스킬·메모리·노션·파일) 이번 호출에만 사용하고 사용 후 폐기 안내.

## 대상 DB (고정값)

| 항목 | 값 |
|------|----|
| DB 페이지 | "AX - 세미나 및 행사" `381d4aa3cb27806ea47fe207c096fd2d` |
| data_source_id | `381d4aa3-cb27-80dc-911f-000b38885475` |
| 위치 | (주)두꺼비세상 AX팀 → AX Labs 하위 |

### 컬럼 스키마

| 속성명 | 타입 | 채우는 방법 |
|--------|------|------------|
| `이름` | title | 세미나/행사명 (간결·설명형, 예: "AWS 기반 Claude 기업 도입 (Bedrock · Claude.ai on AWS · Enterprise)") |
| `일자` | date | 개최일. `date:일자:start` 에 `YYYY-MM-DD` |
| `유형` | select | `세미나` `컨퍼런스` `웨비나` `밋업` `사내 공유회` `아티클/리포트` 중 1 |
| `주제` | multi_select | `AI` `데이터` `프로덕트` `세일즈` `마케팅` `CS/리텐션` `클라우드/인프라` `조직/문화` 중 다수. JSON 배열 문자열로 전달 (예: `["AI", "클라우드/인프라"]`) |
| `핵심 인사이트` | text | **유일하게 손으로 쓰는 필드.** 한 페이지 문서를 1~2문장 so-what 으로 압축한 스캔용 한 줄 |
| `원본 링크` | url | **공개 공유 링크** `https://tiro.ooo/s/{shareId}` |

새 주제/유형 옵션이 필요하면 Notion `update-data-source` 의 `ALTER COLUMN ... SET` 로 추가하되, 색은 도메인별 그룹 컬러(AI계열=blue, 영업/마케팅/CS=green, 인프라=purple, 조직/기타=gray)로 통일한다(레인보우 금지).

## 워크플로

### 1) Tiro 노트 찾기
- 오늘/특정 세미나: `mcp__tiro__list_notes` (size 15) 또는 `mcp__tiro__search_notes` (keyword).
- 결과에서 `noteGuid`, `createdAt`(→ 일자), `recordingDurationSeconds`, `webUrl` 확보.

### 2) 한 페이지 문서(본문) 가져오기
- `mcp__tiro__get_note` with `include: ["summary"]`.
- **`summary.content` 가 곧 한 페이지 문서**다. (별도 `documents` 배열은 보통 비어 있음 — summary 가 기본 자동 생성 한 페이지 문서)
- 이 마크다운을 **그대로** 노션 본문으로 쓴다 (`##` 헤더, `---` 구분선, 표 모두 노션 호환).

### 3) 공개 공유 링크 생성 (쓰기 권한 필요)
- Tiro **MCP 는 읽기 전용** → 생성 도구 없음 (`get_share_link` 는 조회만, 미생성 시 NOT_FOUND).
- 생성은 **REST API** 로:
  ```bash
  curl -sS -X PUT "https://api.tiro.ooo/v1/external/notes/{noteGuid}/share-link" \
    -H "Authorization: Bearer {id}.{secret}" \
    -H "Content-Type: application/json" \
    -d '{}'
  # 응답: {"shareId":"...","shareUrl":"https://tiro.ooo/s/{shareId}","hasPassword":false}
  # body {} = 비밀번호 없음(링크 있는 누구나). 비번 원하면 {"usePassword": true} → sharePassword 즉시 보관(재조회 불가)
  ```
- **API 키 받는 법**: platform.tiro.ooo/dashboard/api-keys 에서 쓰기 scope 키(`id.secret`) 발급. 키는 채팅에 남기지 말고 임시 파일(`/tmp/...`)에 저장→읽기→삭제 권장. 사용 후 키 폐기(rotate) 안내.
- 검증: `curl -sS -o /dev/null -w "%{http_code}\n" -L "https://tiro.ooo/s/{shareId}"` → 200 이면 OK.

### 4) 노션에 항목 추가
Notion `create-pages` 로 `parent: {type: "data_source_id", data_source_id: "381d4aa3-cb27-80dc-911f-000b38885475"}`:
- `properties`: 이름 / `date:일자:start` / 유형 / 주제(JSON 배열 문자열) / 핵심 인사이트 / 원본 링크(공개 링크)
- `content`: 2)의 한 페이지 문서 마크다운 그대로
- `icon`: 내용에 맞는 이모지 1개(선택)

## 체크리스트
- [ ] 본문 = Tiro 한 페이지 문서 verbatim (지어내지 않음)
- [ ] 원본 링크 = `/s/{shareId}` 공개 링크 (200 확인), `/n/{id}` 아님
- [ ] 컬럼 6개만, 주제/유형은 기존 옵션 사용
- [ ] API 키 미저장 + 폐기 안내
- [ ] (선택) 기존 항목과 중복 아닌지 확인

## 메모
- 현행 go-forward DB = 위 `381d4aa3…`. (구 DB `dd543fc8…` 는 비활성)
- 적재 예시: 「AWS 기반 Claude 기업 도입」 세미나 (Tiro `5PK8kkUkURbJi` → 공개 링크 `https://tiro.ooo/s/5PK8kkUkURbJi`).
