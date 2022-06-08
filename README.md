# GCP on-demand container scan

This repository contains script which can run GCP on-demand container vulnerability scan.

It solves the problem of being not able to know how secure or vulnerable your image is before pushing to Artifactory and deploying. It also sends findings summary to preferred Slack channel. Please see prerequisites section for more details.

By design this script is made to be easily integrated with any Github Actions Workflows, where container build step exists.

> Note: Google charge for Successful Scans, more information can be found here [Container Analysis]

## Github Action Integration
The ease of usage is explained below:

- Add the below code in to Github Actions workflow yaml/yml file, just after container build step:

````
    - name: Container Scan
      uses: victorbiga/container-scan@master
      with:
        containerTag: ${{ env.IMAGE_NAME }}
        slackWebhook: ${{ secrets.CONTAINER_SCAN_SLACK_WEBHOOK }}
        githubUrl: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
````
> Note: Align indentation with your workflow, as this varies from project to project

## Variables
`githubUrl` - Full path to your Github Actions run

`containerTag` - Image name reference to what your docker build command tag the container you are intending to scan. Please see [sample.yml] in this repo for usage example

`slackWebhook` - This is Slack webhook url which will remain secret and can be accessed in Repository > Settings > Actions > Secrets
> Note: In order to access Repository Settings section you would require special permissions such as - Organization administrators, repository administrators, and teams with the security manager role


## Prerequisites
### GCP
- GCP On-Demand Scanning API enabled
- service account with the key and relevant permissions to perform container push to GCR and mainly the below "cherry-picked" roles provided in terraform resource format:
````
# Google Cloud IAM role for container scanning using GCP ondemand service.
resource "google_project_iam_custom_role" "ondemandscanning_analyze_packages" {
  permissions = [
    "ondemandscanning.scans.analyzePackages",
    "ondemandscanning.scans.listVulnerabilities",
    "ondemandscanning.operations.get"
  ]
  project = local.google_project
  role_id = "ondemandScanningScansAnalyzePackages"
  title   = "On-demand Container Scan Lister"
}
````

### Github
- Existing Github Actions workflow with Docker build
- Ubuntu 22.04 LTS Github runner with jq tool pre-installed
- containerTag is set in env or as string value
- githubUrl is set to ```${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}```. This is required to have the link in Slack notification to Github Actions job. 
- Slack webhook added to your repository secrets. Name your secret CONTAINER_SCAN_SLACK_WEBHOOK 
- GCP service account key added to your repository secrets. Name your secret GCP_SERVICE_ACCOUNT_KEY


### Slack
- Slack app Container-Scan installed in Slack workspace
- Slack webhook with your preferred channel
> Note: You will need to create Slack webhook for your preferred notification channel in Slack workspace. To access App configuration page link would look ```https://api.slack.com/apps/{{ slack_org_id }}/incoming-webhooks```. New webhook can be created only by Workspace admins.

## Features

- Scan container image using GCP CVE database
- Obtain scan results and output in the Github Actions Workflow
- Count the results and provide results summary
- Fail Github Actions Workflow if CRITICAL or/and HIGH vulnerabilities are found
- Send notification to your preferred Slack channel when CRITICAL or/and HIGH vulnerabilities are found (contains only summary of results and link to Github job accordingly)

## Support

If you are having issues, please report them in  "issue" section.

[Container Analysis]: <https://cloud.google.com/container-analysis/pricing>
[sample.yml]: <http://github.com/victorbiga/container-scan/sample.yml>