#!/bin/sh

IFS="
"

cat <<EOF
|File|Type|Result|Reason|
|----|----|------|------|
EOF

for LINE in $(cat test-cases.txt)
do
  FILE=$(echo "${LINE}" | awk -F: '{print $1}') || exit 1
  TYPE=$(echo "${LINE}" | awk -F: '{print $2}') || exit 1
  RESULT=$(echo "${LINE}" | awk -F: '{print $3}') || exit 1
  REASON=$(echo "${LINE}" | awk -F: '{print $4}') || exit 1

  case "${RESULT}" in
    "success")
      RESULT_PRETTY="✅ success"
      ;;
    "failure")
      RESULT_PRETTY="❌ failure"
      ;;
    *)
      echo "invalid RESULT: ${RESULT}" 1>&2
      exit 1
      ;;
  esac

  cat <<EOF
|[${FILE}](${FILE})|${TYPE}|${RESULT_PRETTY}|${REASON}|
EOF
done
