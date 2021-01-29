#!/bin/sh

export NOW="$(date +%s)"
TMP_REPORT="$(mktemp)"

# Run Bandit and save report on temporary folder
set -euo pipefail
bandit --version
bandit -r -a vuln -ii -ll -x .git,.svn,.mvn,.idea,dist,bin,obj,backup,docs,tests,test,tmp,reports,venv "$@" -f json -o "${TMP_REPORT}"

# EXITCODE=$?
# RESULT="${RESULT//'%'/'%25'}"
# RESULT="${RESULT//$'\n'/'%0A'}"
# RESULT="${RESULT//$'\r'/'%0D'}"
# echo "::set-output name=result::${RESULT}"
# exit ${EXITCODE}

# Print Report on screen to developers
#cat "${TMP_REPORT}"

if [ -z ${DD_CLIENT_API_KEY}] || [ -z ${GITHUB_REPOSITORY} ]; then
  echo "\$DD_CLIENT_API_KEY or \$SGITHUB_REPOSITORY are empty. I can't send metrics to DataDog without this information!"
else
  CONFIDENCE_HIGH=`cat ${TMP_REPORT} | jq -r '.metrics._totals."CONFIDENCE.HIGH"'`
  CONFIDENCE_MEDIUM=`cat ${TMP_REPORT} | jq -r '.metrics._totals."CONFIDENCE.MEDIUM"'`
  SEVERITY_HIGH=`cat ${TMP_REPORT} | jq -r '.metrics._totals."SEVERITY.HIGH"'`
  SEVERITY_MEDIUM=`cat ${TMP_REPORT} | jq -r '.metrics._totals."SEVERITY.MEDIUM"'`
  LOC=`cat ${TMP_REPORT} | jq -r '.metrics._totals.loc'`
fi

# Removing temporary files
rm -rf "${TMP_REPORT}"
