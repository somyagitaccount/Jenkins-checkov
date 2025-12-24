pipeline {
  agent any

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  environment {
    CHECKOV_IMAGE = "bridgecrew/checkov:latest"
    GITHUB_TOKEN = credentials('github-token')
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Run Checkov') {
      steps {
        sh '''
docker run --rm \
  -v "$PWD:/tf" \
  -w /tf \
  ${CHECKOV_IMAGE} \
  checkov -d . \
  --framework terraform \
  --output json \
  --soft-fail \
  > checkov.json
'''
      }
    }

    stage('Generate Summary') {
      steps {
        sh '''
PASSED=$(jq '.summary.passed' checkov.json)
FAILED=$(jq '.summary.failed' checkov.json)
SKIPPED=$(jq '.summary.skipped' checkov.json)

cat <<EOF > checkov.txt
Passed checks: $PASSED
Failed checks: $FAILED
Skipped checks: $SKIPPED
EOF
'''
      }
    }

    stage('Decorate PR') {
      when {
        expression { env.CHANGE_ID != null }
      }
      steps {
        sh '''
OWNER=$(echo "$GIT_URL" | sed -E 's#.*/([^/]+)/([^/.]+)(\\.git)?#\\1#')
REPO=$(echo "$GIT_URL" | sed -E 's#.*/([^/]+)/([^/.]+)(\\.git)?#\\2#')

SUMMARY=$(cat checkov.txt)

COMMENT=$(cat <<EOF
### Checkov Terraform Scan Results

Repository: $REPO
PR: #$CHANGE_ID

$SUMMARY

Full report available in Jenkins artifacts.
EOF
)

curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  https://api.github.com/repos/$OWNER/$REPO/issues/$CHANGE_ID/comments \
  -d "$(jq -nc --arg body "$COMMENT" '{body: $body}')"
'''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'checkov.json, checkov.txt'
    }
  }
}
