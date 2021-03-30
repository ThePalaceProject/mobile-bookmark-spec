#!/bin/sh

WRONG_RESULTS=0
FAILED_FILES=""

expectFailure()
{
  FILE="$1"
  ./validate.sh "${FILE}"
  if [ $? -eq 0 ]
  then
    WRONG_RESULTS=$(expr ${WRONG_RESULTS} + 1)
    echo "expected ${FILE} to fail but it succeeded"
    FAILED_FILES="${FAILED_FILES} ${FILE}"
  fi
}

expectSuccess()
{
  FILE="$1"
  ./validate.sh "${FILE}"
  if [ $? -ne 0 ]
  then
    WRONG_RESULTS=$(expr ${WRONG_RESULTS} + 1)
    echo "expected ${FILE} to succeed but it failed"
    FAILED_FILES="${FAILED_FILES} ${FILE}"
  fi
}

expectSuccess valid-locator-0.json
expectSuccess valid-locator-1.json
expectFailure invalid-locator-1.json
expectFailure invalid-locator-2.json
expectFailure invalid-locator-3.json
expectFailure invalid-locator-4.json

echo
echo "Summary"
echo "---"

if [ ! -z "${FAILED_FILES}" ]
then
  for FILE in ${FAILED_FILES}
  do
    echo "Failed file: ${FILE}"
  done
else
  echo "Everything is fine."
fi
