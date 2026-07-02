# 네이버 카페 내부 API 정리 (navercafe-crawl 근거)

> 신형 카페(`cafe.naver.com/f-e/cafes/{cafeId}/menus/{menuId}`) 기준. Base: `https://apis.naver.com/cafe-web`.
> 헤더: `User-Agent`(브라우저) + `Referer`(해당 글/게시판). 인증은 쿠키 `NID_AUT`+`NID_SES`.

## 1. 게시글 목록 — 비로그인 가능 ✅
```
GET /cafe2/ArticleListV2dot1.json
    ?search.clubid={cafeId}&search.menuid={menuId}
    &search.queryType=lastArticle&search.page={n}&search.perPage=50
```
- 응답 `message.result.articleList[]` : articleId, subject, writerNickname, readCount,
  commentCount, likeItCount, writeDateTimestamp, attachImage/File/Movie/Poll… 플래그.
- `message.result.hasNext` 로 페이지네이션. `cafeName` 도 여기 있음.
- **totalCount 필드는 없음** → hasNext=false 까지 페이지를 돈다.

## 2. 게시글 본문 — 로그인 필수 🔒
```
GET /cafe-articleapi/v3/cafes/{cafeId}/articles/{articleId}
    ?query=&menuId={menuId}&boardType=L&useCafeId=true&requestFrom=A
```
- 비로그인 → `401 로그인하지 않았습니다`. 로그인했으나 카페 비회원 → `403 카페 멤버만 읽을 수 있는 게시글입니다`.
- 응답 `result.article` : subject, writer.nick, writeDate(ms), readCount, commentCount,
  **contentHtml**(스마트에디터 HTML), isNotice, isBlind …
- `result.user.isCafeMember` 로 회원 여부 확인 가능.
- `result.attaches[]` : 첨부(type "I"=이미지 url/name 등).
- **레거시/[공유] 글**: `contentHtml`이 비고 대신 `result.article.scrap` 에 내용:
  - `scrap.contentHtml` (본문, `[[[CONTENT-ELEMENT-N]]]` 자리표시자 포함)
  - `scrap.contentElements[N]` : `{type:"IMAGE"|"LINK", json:{...}}` (자리표시자 치환용)
    - IMAGE → `json.image.url`
    - LINK → `json.truncatedTitle/desc/linkUrl/domain` (title/desc는 HTML 엔티티 인코딩)
  - `scrap.titleHtml`/`scrap.linkHtml` : 출처 제목·링크

## 3. 댓글 — 로그인 필수, 페이지네이션 🔒
본문 API의 `result.comments.items` 는 **처음 10개만** 준다(초과 시 `comments.next` 커서 존재).
전량은 아래 v2 엔드포인트로:
```
GET /cafe-articleapi/v2/cafes/{cafeId}/articles/{articleId}/comments/pages/{page}
    ?requestFrom=A&orderBy=asc
```
- 응답 `result.comments.items[]` : writer.nick, content, updateDate(ms),
  isDeleted, isRef(답글), isArticleWriter.
- `result.hasNext` 따라 page++ 반복. (v2.1/v3 comments 경로는 500 — v2 가 정답)

## 로그인/쿠키 획득 (chromux)
- 네이버는 JS로 필드 값만 세팅하면 거부(키보드 보안) → chromux `fill`(CDP 신뢰 입력) 사용.
- 헤드리스·헤드풀 모두 **영수증 판독형 이미지 캡차**가 뜰 수 있음 → 이미지를 읽어 답을 채워 통과.
- 로그인 성공 후 `deviceConfirm`(새 기기 등록) → `등록안함`.
- 쿠키: `Network.getAllCookies` 응답 최상위가 `{"cookies":[...]}` (⚠ `result.cookies` 아님).
  `naver.com` 도메인의 `NID_AUT/NID_SES` 필수(둘 다 httpOnly라 document.cookie로는 안 보임).
- **세션 쿠키(NID_SES)는 `chromux kill` 후 사라짐** → 재사용하려면 로그인 시 '로그인 상태 유지' 체크(프로필 영속).

## chromux 함정
- 데몬은 Node **21+** 의 전역 WebSocket 필요. 기본 node가 v20이면 `WebSocket is not defined` → Node22 bin을 PATH 앞에.
- 무거운 SPA(카페 본문 페이지)에서 CDP가 timeout날 수 있음 → 쿠키 추출은 가벼운 페이지에서.

## 미확정
- 캡차가 계정/IP에 따라 매 로그인 반복될 수 있고, 강한 2차인증이 걸리면 사람이 직접 로그인 필요.
- 목록 perPage 상한(50 확인). 매우 큰 게시판(수만 건)에서의 rate-limit 미검증.
