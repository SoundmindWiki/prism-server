#!/usr/bin/env bash
# Prism DB 하루치 덤프. cron 이 매일 부르고, 맥에서 가져갈 때도 한 번 더 부른다.
# 같은 날 두 번 돌아도 그날 파일을 새로 쓸 뿐이라 안전하다.
set -euo pipefail

DIR=/srv/prism/backups
KEEP_DAYS=14

set -a; . /srv/prism/shared/prism.env; set +a
mkdir -p "$DIR"

stamp=$(date +%Y%m%d)
out="$DIR/prism-$stamp.dump"

# -Fc 는 압축된 custom 형식. pg_restore 로 테이블만 골라 되살릴 수도 있다.
# 임시 이름으로 받아 두었다가 다 끝난 뒤에 옮긴다 — 도중에 끊긴 파일을 온전한 백업으로 착각하지 않게.
pg_dump "$DATABASE_URL" -Fc -f "$out.part"
mv "$out.part" "$out"

find "$DIR" -name 'prism-*.dump' -mtime +$((KEEP_DAYS - 1)) -delete
find "$DIR" -name '*.part' -mmin +120 -delete

echo "$(date '+%F %T') 백업 완료 $(basename "$out") ($(du -h "$out" | cut -f1))"
