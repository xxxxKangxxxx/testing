#!/bin/bash

# OpenAI API 키 확인
if [ -z "$OPENAI_API_KEY" ]; then
  echo "❌ Need to export OPENAI_API_KEY"
  exit 1
fi

# log 파일 선정 (stderr 우선, 없으면 stdout)
if [ -s /tmp/thehelp_err.log ]; then
  LOG_FILE="/tmp/thehelp_err.log"
else
  LOG_FILE="/tmp/thehelp_out.log"
fi

# 로그 확인 (마지막 20줄)
LOG_CONTENT=$(tail -n 20 "$LOG_FILE")

# 인자 여부에 따라 프롬프트 설정
if [ $# -eq 0 ]; then
  PROMPT="다음은 터미널 로그입니다. 문제 원인과 해결책을 알려줘:\n$LOG_CONTENT"
else
  CMD_OUTPUT=$("$@" 2>&1)
  PROMPT="명령어 '$*' 실행 결과:\n$CMD_OUTPUT\n위 명령어의 문제점과 해결 방법을 알려줘."
fi

# GPT 요청용 JSON 생성
JSON_BODY=$(jq -n --arg msg "$PROMPT" '{
  model: "gpt-3.5-turbo",
  messages: [{ role: "user", content: $msg }]
}')

# API 호출 및 응답 출력
curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_BODY" | jq -r '.choices[0].message.content'

