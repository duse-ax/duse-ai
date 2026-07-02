#!/usr/bin/env bash
# navercafe-crawl 의존성 점검 & 자동 설치.
# 성공 시 마지막 줄에 "PREFLIGHT_OK" 와, 사용할 chromux 실행에 필요한 PATH 를
# 담은 env 파일 경로를 출력한다. 사용자 조치가 필요한 항목(Chrome/Node 설치)은
# 명확한 메시지와 함께 non-zero 로 종료한다.
set -uo pipefail

WORKDIR="${1:-$PWD}"
ENVFILE="$WORKDIR/.navercafe_env.sh"
mkdir -p "$WORKDIR"
: > "$ENVFILE"

say() { printf '%s\n' "$*"; }
fail() { printf 'PREFLIGHT_FAIL: %s\n' "$*" >&2; exit 1; }

# ---------- 1) Node >= 22 확보 (chromux 데몬은 global WebSocket 필요 = node>=21) ----------
node_major() { "$1" -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/'; }

NODE22=""
# a) 현재 PATH 의 node 가 22+ 면 그대로
if command -v node >/dev/null 2>&1 && [ "$(node_major node)" -ge 22 ] 2>/dev/null; then
  NODE22="$(dirname "$(command -v node)")"
fi
# b) nvm 설치본 중 22+ 탐색
if [ -z "$NODE22" ] && [ -d "$HOME/.nvm/versions/node" ]; then
  for d in $(ls -1 "$HOME/.nvm/versions/node" 2>/dev/null | sort -Vr); do
    bin="$HOME/.nvm/versions/node/$d/bin"
    if [ -x "$bin/node" ] && [ "$(node_major "$bin/node")" -ge 22 ] 2>/dev/null; then
      NODE22="$bin"; break
    fi
  done
fi
# c) homebrew node 22
if [ -z "$NODE22" ]; then
  for cand in /opt/homebrew/opt/node@22/bin /usr/local/opt/node@22/bin /opt/homebrew/bin /usr/local/bin; do
    if [ -x "$cand/node" ] && [ "$(node_major "$cand/node")" -ge 22 ] 2>/dev/null; then
      NODE22="$cand"; break
    fi
  done
fi

if [ -z "$NODE22" ]; then
  fail "Node.js 22+ 가 필요합니다(현재 없음/버전 낮음). 설치 후 다시 실행하세요:
   - nvm 사용:   nvm install 22 && nvm use 22
   - Homebrew:   brew install node@22
   (chromux 데몬은 Node 21+ 의 전역 WebSocket 이 있어야 동작합니다)"
fi
say "Node 22+ : $NODE22/node ($("$NODE22/node" -v))"
echo "export PATH=\"$NODE22:\$PATH\"" >> "$ENVFILE"
export PATH="$NODE22:$PATH"

# ---------- 2) Google Chrome (chromux 는 로컬 크롬을 구동) ----------
CHROME=""
for p in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
         "$(command -v google-chrome 2>/dev/null)" \
         "$(command -v google-chrome-stable 2>/dev/null)" \
         "$(command -v chromium 2>/dev/null)"; do
  [ -n "$p" ] && [ -x "$p" ] && CHROME="$p" && break
done
if [ -z "$CHROME" ]; then
  fail "Google Chrome 가 필요합니다. 설치 후 다시 실행하세요: https://www.google.com/chrome/"
fi
say "Chrome   : $CHROME"

# ---------- 3) chromux CLI ----------
if ! command -v chromux >/dev/null 2>&1; then
  say "chromux 미설치 → 설치 시도(npm i -g @team-attention/chromux)…"
  if npm install -g @team-attention/chromux >/tmp/chromux_install.log 2>&1; then
    say "chromux 설치 완료(npm)."
  else
    say "npm 레지스트리 실패 → GitHub 에서 설치 시도…"
    INSTALL_DIR="${CHROMUX_DIR:-$HOME/team-attention/chromux}"
    if [ -d "$INSTALL_DIR/.git" ]; then (cd "$INSTALL_DIR" && git pull --ff-only) ; \
      else mkdir -p "$(dirname "$INSTALL_DIR")" && git clone https://github.com/team-attention/chromux "$INSTALL_DIR"; fi
    (cd "$INSTALL_DIR" && npm install -g .) || fail "chromux 설치 실패. /tmp/chromux_install.log 확인."
  fi
fi
CHROMUX="$(command -v chromux)"
[ -z "$CHROMUX" ] && fail "chromux 설치 후에도 PATH 에서 찾지 못했습니다."
say "chromux  : $CHROMUX"
echo "export CHROMUX=\"$CHROMUX\"" >> "$ENVFILE"

# ---------- 4) Python 3 + 라이브러리 ----------
PY="$(command -v python3 || command -v python)"
[ -z "$PY" ] && fail "python3 가 필요합니다."
if ! "$PY" -c "import bs4, lxml, openpyxl" >/dev/null 2>&1; then
  say "python 라이브러리 설치(beautifulsoup4 lxml openpyxl)…"
  "$PY" -m pip install --user beautifulsoup4 lxml openpyxl >/tmp/pip_install.log 2>&1 \
    || "$PY" -m pip install beautifulsoup4 lxml openpyxl >/tmp/pip_install.log 2>&1 \
    || fail "python 라이브러리 설치 실패. /tmp/pip_install.log 확인."
fi
say "Python   : $PY ($("$PY" -c 'import bs4,lxml,openpyxl;print("bs4/lxml/openpyxl OK")'))"
echo "export PYBIN=\"$PY\"" >> "$ENVFILE"

say "ENVFILE  : $ENVFILE"
say "PREFLIGHT_OK"
