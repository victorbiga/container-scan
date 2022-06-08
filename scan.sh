touch scanResults
scanResults="scanResults"
vulnerabilitySeverityRating=(CRITICAL HIGH MEDIUM LOW)
metaDataTableFormat='table(vulnerability.effectiveSeverity, vulnerability.cvssScore, vulnerability.packageIssue[0].affectedPackage, vulnerability.packageIssue[0].affectedVersion.name, vulnerability.packageIssue[0].fixedVersion.name, noteName)'
githubUrl="${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"

function gcloud() {
  command gcloud artifacts docker images scan --format='value(response.scan)' "$containerTag" > scan_id.txt
  command gcloud artifacts docker images list-vulnerabilities "$(cat scan_id.txt)" --format="$metaDataTableFormat" > "$scanResults" &&\
   echo "Here are the scan results" && \
   cat "$scanResults"
}

function resultCount {
  if [ -s $scanResults ]; then
    CRITICAL=$(grep -c "${vulnerabilitySeverityRating[0]}" < "$scanResults")
    HIGH=$(grep -c "${vulnerabilitySeverityRating[1]}" < "$scanResults")
    MEDIUM=$(grep -c "${vulnerabilitySeverityRating[2]}" < "$scanResults")
    LOW=$(grep -c "${vulnerabilitySeverityRating[3]}" < "$scanResults")
    echo "Found vulnerabilities summary:"
    echo "CRITICAL: $CRITICAL"
    echo "HIGH: $HIGH"
    echo "MEDIUM: $MEDIUM"
    echo "LOW: $LOW"
    jsonString=$( jq -nr \
        --arg jqMarkdownMessageGeneral "<$githubUrl|Github Actions Failure - Container Scan>" \
        --arg jqMarkdownMessageWhy "This container has vulnerabilities" \
        --arg jqMarkdownMessageCritical ":space_invader: CRITICAL : $CRITICAL" \
        --arg jqMarkdownMessageHigh ":lobster: HIGH : $HIGH" \
        --arg jqMarkdownMessageMedium ":ladybug: MEDIUM : $MEDIUM" \
        --arg jqMarkdownMessageLow ":v: LOW : $LOW" \
        '{
            blocks: [
                {
                    type: "section",
                    text: {
                        type: "mrkdwn",
                        text: $jqMarkdownMessageGeneral
                    }
                },
                {
                    type: "section",
                    text: {
                        type: "mrkdwn",
                        text: $jqMarkdownMessageWhy
                    }
                },
                {
                    type: "section",
                    text: {
                        type: "mrkdwn",
                        text: $jqMarkdownMessageCritical
                    }
                },
                {
                    type: "section",
                    text: {
                        type: "mrkdwn",
                        text: $jqMarkdownMessageHigh
                    }
                },
                {
                    type: "section",
                    text: {
                        type: "mrkdwn",
                        text: $jqMarkdownMessageMedium
                    }
                },
                {
                    type: "section",
                    text: {
                        type: "mrkdwn",
                        text: $jqMarkdownMessageLow
                    }
                }
            ]
        }')
    fail
  else echo "Scan results returned 0 vulnerabilities"
  fi
}

function fail() {
  if grep -qE 'CRITICAL|HIGH' $scanResults;
    then
      echo ""
      echo 'Workflow Failed Vulnerability Check' && postMessageSlack && exit 1;
  else exit 0
  fi
}

function postMessageSlack() {
  curl --silent --output /dev/null -X POST -H 'Content-type: application/json' --data "$jsonString" "$slackWebhook"
}

echo "Running container scanning in GCP"
gcloud
echo ""
echo "Counting results and doing fail check"
echo ""
resultCount
echo ""
