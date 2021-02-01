#!/bin/sh

export NOW="$(date +%s)"
TMP_REPORT="$(mktemp)"

# Run Bandit and save report on temporary folder
set -euo pipefail
bandit --version
bandit -r -a vuln -ii -ll -x .git,.svn,.mvn,.idea,dist,bin,obj,backup,docs,tests,test,tmp,reports,venv "$@" -f json -o report.json

EXITCODE=$?
# RESULT="${RESULT//'%'/'%25'}"
# RESULT="${RESULT//$'\n'/'%0A'}"
# RESULT="${RESULT//$'\r'/'%0D'}"
# echo "::set-output name=result::${RESULT}"
echo "${EXITCODE}"

sleep 5

# Print Report on screen to developers
cat "${TMP_REPORT}"

if [ -z ${DD_CLIENT_API_KEY} ] || [ -z ${GITHUB_REPOSITORY} ]
then
  echo "\$DD_CLIENT_API_KEY or \$SGITHUB_REPOSITORY are empty. I can't send metrics to DataDog without this information!"
else
  CONFIDENCE_HIGH=$(cat ${TMP_REPORT} | jq -r '.metrics._totals."CONFIDENCE.HIGH"')
  CONFIDENCE_MEDIUM=$(cat ${TMP_REPORT} | jq -r '.metrics._totals."CONFIDENCE.MEDIUM"')
  SEVERITY_HIGH=$(cat ${TMP_REPORT} | jq -r '.metrics._totals."SEVERITY.HIGH"')
  SEVERITY_MEDIUM=$(cat ${TMP_REPORT} | jq -r '.metrics._totals."SEVERITY.MEDIUM"')
  LOC=$(cat ${TMP_REPORT} | jq -r '.metrics._totals.loc')

  # Sending metrics to DataDog
  curl -s -X POST "https://api.datadoghq.com/api/v1/series?api_key=${DD_CLIENT_API_KEY}" -H "Content-Type: application/json" \
  -d @- << EOF
  {
    "series": [
      {
        "metric": "security.sast.execution",
        "points": [
          [
            "${NOW}",
            1
          ]
        ],
        "tags": [
            "repo:${GITHUB_REPOSITORY}"
        ]
      },
      {
        "metric": "security.sast.results.confidence_high",
        "points": [
          [
            "${NOW}",
            "${CONFIDENCE_HIGH}"
          ]
        ],
        "tags":[
            "repo:${GITHUB_REPOSITORY}"
        ]
      },
      {
        "metric": "security.sast.results.confidence_medium",
        "points": [
          [
            "${NOW}",
            "${CONFIDENCE_MEDIUM}"
          ]
        ],
        "tags":[
            "repo:${GITHUB_REPOSITORY}"
        ]
      },
      {
        "metric": "security.sast.results.severity_high",
        "points": [
          [
            "${NOW}",
            "${SEVERITY_HIGH}"
          ]
        ],
        "tags":[
            "repo:${GITHUB_REPOSITORY}"
        ]
      },
      {
        "metric": "security.sast.results.severity_medium",
        "points": [
          [
            "${NOW}",
            "${SEVERITY_MEDIUM}"
          ]
        ],
        "tags":[
            "repo:${GITHUB_REPOSITORY}"
        ]
      },
      {
        "metric": "security.sast.results.loc",
        "points": [
          [
            "${NOW}",
            "${LOC}"
          ]
        ],
        "tags":[
            "repo:${GITHUB_REPOSITORY}"
        ]
      }
    ]
  }
EOF

fi

# Removing temporary files
#rm -rf "${TMP_REPORT}"
rm -rf report.json
