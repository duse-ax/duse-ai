---
name: navercafe-crawl
description: 네이버 카페 게시판의 모든 게시글(제목·본문·작성자·작성일·조회수·댓글·첨부)을 전수 크롤링해 엑셀로 만든다. 로그인이 필요한 카페도 chromux(실제 Chrome)로 로그인해 처리하며, 필요한 도구(chromux/Python 라이브러리)가 없으면 자동 설치한다. 트리거 — "네이버 카페 크롤링", "카페 게시글 엑셀로", "카페 공지 크롤링", "navercafe crawl", 또는 cafe.naver.com URL + 엑셀 추출 요청.
version: 0.1.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [naver, cafe, crawl, excel, scraping]
    category: automation
---

# navercafe-crawl

네이버 카페 게시판 URL을 받아 **모든 게시글의 제목·본문·작성자·작성일·조회수·댓글수·추천수·첨부·전체 댓글·원문링크**를 수집해 엑셀(정보/게시글/댓글 3시트)로 만든다.

## 핵심 원리 (재발견 금지 — `references/naver-cafe-api.md` 참고)
- **목록 API는 비로그인 조회 가능**, **본문·댓글 API는 로그인 쿠키 필수**.
- 쿠키 계정은 **해당 카페의 "회원"이어야** 본문이 보인다(비회원 401/403).
- 댓글은 10개씩 **페이지네이션** — 별도 v2 댓글 엔드포인트로 전량 수집해야 누락 없음.
- `[공유]`/스크랩 글은 본문이 `article.contentHtml`이 아니라 **`article.scrap`**에 있다.
- 이 로직은 `scripts/crawl.py`에 전부 구현돼 있으니 **직접 API를 재분석하지 말고 그대로 사용**한다.

---

## 절차

### 0단계 — 사용자 입력 받기
사용자에게 확인한다(모르면 질문):
1. **게시판 URL** (예: `https://cafe.naver.com/f-e/cafes/24646884/menus/30`)
2. **로그인 방식**:
   - (기본·권장) **수동**: 열리는 Chrome 창에서 사용자가 직접 로그인. 이때 **‘로그인 상태 유지’ 체크**를 안내 → 프로필이 유지돼 다음 실행부턴 로그인 생략.
   - **자동**: 사용자가 네이버 아이디/비번을 제공하면 스킬이 대신 로그인(캡차는 이미지 판독으로 처리). 비번이 대화기록에 남는 점을 사용자에게 고지.
3. **주의 안내**: 그 계정이 **해당 카페 회원**이어야 본문이 수집된다.

작업 디렉토리를 하나 만들어 이후 모든 산출물을 여기 둔다:
```bash
WORKDIR="$(mktemp -d -t navercafe-XXXX)"; echo "$WORKDIR"
```

### 1단계 — 의존성 점검·설치 (preflight)
이 스킬 디렉토리의 `scripts/preflight.sh`를 실행한다(경로는 이 SKILL.md와 같은 폴더). 없는 것(Node22+/chromux/Python 라이브러리)은 자동 설치하고, 사용자 조치가 필요한 것(Chrome 미설치, Node22 미설치)은 메시지로 안내한다.
```bash
bash "<이 스킬 폴더>/scripts/preflight.sh" "$WORKDIR"
```
- 출력 마지막에 `PREFLIGHT_OK`가 보이면 성공. 이어서 **반드시 env를 로드**한다(chromux를 올바른 Node로 실행하기 위함):
```bash
source "$WORKDIR/.navercafe_env.sh"   # PATH(Node22), $CHROMUX, $PYBIN 설정
```
- `PREFLIGHT_FAIL`이면 메시지대로 사용자에게 설치를 요청하고 중단.

> **함정**: 기본 `node`가 v20이면 chromux 데몬이 `WebSocket is not defined`로 죽는다. preflight가 Node22+ 경로를 PATH 앞에 넣어주므로, **모든 chromux 호출 전에 위 `source`를 먼저** 하라. 이후 chromux는 `"$CHROMUX"`로 호출.

### 2단계 — 네이버 로그인 (chromux, 실제 Chrome)
헤드풀(창 보이게)로 띄운다:
```bash
"$CHROMUX" launch default            # headless:false 확인
"$CHROMUX" open nvlogin "https://nid.naver.com/nidlogin.login?mode=form"
```

**수동 모드**: 사용자에게 "열린 창에서 로그인('로그인 상태 유지' 체크) 후 알려달라"고 요청하고 대기.

**자동 모드**: (네이버는 JS로 값만 넣으면 거부하므로 chromux `fill`=CDP 신뢰 입력 사용)
```bash
"$CHROMUX" fill nvlogin "#id" '<아이디>'
"$CHROMUX" fill nvlogin "#pw" '<비번>'
"$CHROMUX" click nvlogin "#log\\.login"
```
- **캡차 대응**: 로그인 후 페이지에 `#captcha`(영수증 이미지)가 뜨면:
  1. 이미지와 질문을 파일로 추출:
     ```bash
     "$CHROMUX" run nvlogin - > "$WORKDIR/cap.json" <<'JS'
     return await js("(function(){var c=document.querySelector('#captchaimg');return {src:c?c.src:'',q:document.querySelector('#captcha_info')?.innerText||''};})()");
     JS
     ```
  2. `cap.json`의 `src`(data:image base64)를 파일로 디코드 후 **Read 툴로 이미지를 직접 보고** 질문(`q`)에 답을 구한다(예: "분말 비오틴 개당 가격"→영수증 표에서 700).
  3. `"$CHROMUX" fill nvlogin "#captcha" '<정답>'` → 아이디/비번 다시 fill → 다시 click 로그인.
- **새 기기 등록** 화면(`deviceConfirm`)이 뜨면 `등록안함`을 클릭:
  ```bash
  "$CHROMUX" run nvlogin - <<'JS'
  await js("(function(){var a=[...document.querySelectorAll('a,button')].find(x=>x.innerText.trim()==='등록안함');if(a)a.click();})()"); return 'ok';
  JS
  ```
- 로그인 성공 확인: `location.href`가 카페/네이버 메인으로 이동.

### 3단계 — 쿠키 추출
카페 도메인 쿠키를 CDP로 뽑아 `cookie_header.txt` 생성.
> **함정**: `Network.getAllCookies` 응답은 `{"cookies":[...]}` (최상위)다. `result.cookies`가 아님. `naver.com` 도메인의 `NID_AUT/NID_SES/NNB/nid_inf`만 추린다.
```bash
"$CHROMUX" cdp nvlogin Network.getAllCookies '{}' > "$WORKDIR/cookies_raw.json"
"$PYBIN" - "$WORKDIR" <<'PY'
import json,sys
w=sys.argv[1]
d=json.load(open(f"{w}/cookies_raw.json"))
cks=d.get("result",{}).get("cookies") or d.get("cookies") or []
want=["NID_AUT","NID_SES","NNB","nid_inf"]
got={c["name"]:c["value"] for c in cks if c["name"] in want and c.get("domain","").endswith("naver.com")}
open(f"{w}/cookie_header.txt","w").write("; ".join(f"{k}={v}" for k,v in got.items()))
print("auth_ok" if ("NID_AUT" in got and "NID_SES" in got) else "NO_AUTH_COOKIE", list(got))
PY
```
`NO_AUTH_COOKIE`가 나오면 로그인이 안 된 것 — 2단계 재시도.

### 4단계 — 크롤링 실행 (열거→병렬 수집→파싱→엑셀, 전부 crawl.py)
```bash
"$PYBIN" "<이 스킬 폴더>/scripts/crawl.py" \
  --url "<게시판 URL>" \
  --cookie "$WORKDIR/cookie_header.txt" \
  --out "<원하는 저장경로>.xlsx" \
  --workers 8
```
- crawl.py가 목록 전량 열거 → 본문/댓글 **병렬 fetch** → 원문 그대로 파싱(스크랩·이미지·표 보존) → 3시트 엑셀 생성까지 수행하고 정합성(본문없음/실패/401·403)을 리포트한다.
- 출력에 `401/403 다수` 경고가 나오면 그 계정이 **카페 회원이 아니거나 쿠키 만료** → 사용자에게 안내.

### 5단계 — 정리 & 보고
```bash
"$CHROMUX" kill default          # 브라우저 종료(수동 로그인·프로필 유지를 원하면 생략 가능)
rm -f "$WORKDIR/cookie_header.txt" "$WORKDIR/cookies_raw.json" "$WORKDIR/cap.json" "$WORKDIR"/captcha.*
```
- 사용자에게 **엑셀 경로(클릭 링크)** 와 요약(게시글 N건·댓글 M건, 실패/본문없음 건수)을 보고한다.
- 민감정보(쿠키·캡차 이미지·비번)는 삭제했음을 명시한다.

---

## 참고
- 병렬 수집은 crawl.py 내부 ThreadPool로 처리하므로 Claude Code의 Workflow 기능이 없어도 동작한다. (대규모라면 Workflow로 배치 분산도 가능하나 필수 아님)
- API 상세·엔드포인트·엣지케이스는 `references/naver-cafe-api.md`.
