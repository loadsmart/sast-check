#!/bin/bash

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
cat "${TMP_REPORT}"

if [ -z "$DD_CLIENT_API_KEY"] || [ -z "$GITHUB_REPOSITORY" ]
then
  echo "\$DD_CLIENT_API_KEY or \$SGITHUB_REPOSITORY are empty. I can't send metrics to DataDog without this information!"
else
  # Reading metrics and save to variables
  read confidence_high confidence_medium severity_high severity_medium loc \
  < <(echo $(cat ${TMP_REPORT} | jq -r '.metrics._totals."CONFIDENCE.HIGH", .metrics._totals."CONFIDENCE.MEDIUM", \
  .metrics._totals."SEVERITY.HIGH", .metrics._totals."SEVERITY.MEDIUM", .metrics._totals.loc'))

  # Sending metrics to DataDog
  curl -X POST "https://api.datadoghq.com/api/v1/series?api_key=${DD_CLIENT_API_KEY}" \
  -H "Content-Type: application/json" \
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
        "tags":[
            "repo:${GITHUB_REPOSITORY}"
        ]
      },
      {
        "metric": "security.sast.results.confidence_high",
        "points": [
          [
            "${NOW}",
            ${confidence_high}
          ],
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
            ${confidence_medium}
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
            ${severity_high}
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
            ${severity_medium}
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
            ${loc}
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
rm -rf "${TMP_REPORT}"
