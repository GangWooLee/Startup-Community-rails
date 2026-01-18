#!/bin/bash
# Tailwind CDN으로 롤백
# 사용법: ./scripts/rollback-to-cdn.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

LAYOUT_FILE="$PROJECT_ROOT/app/views/layouts/application.html.erb"
BACKUP_FILE="$LAYOUT_FILE.cdn-backup"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ 백업 파일이 없습니다: $BACKUP_FILE"
    exit 1
fi

cp "$BACKUP_FILE" "$LAYOUT_FILE"
echo "✅ CDN 버전으로 롤백 완료"
echo "   서버 재시작 필요: bin/rails server"
