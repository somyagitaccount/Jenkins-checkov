pipeline {
  agent {
    docker {
      image 'bridgecrew/checkov:latest'
      args '--entrypoint=""'
    }
  }

  options {
    timestamps()
    timeout(time: 20, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    GITHUB_TOKEN = credentials('github-token')
    PATH = "${env.PATH}:/usr/local/bin:/opt/homebrew/bin"
  }

  stages {

    stage('Validate PR Context') {
      when {
        expression { env.CHANGE_ID != null }
      }
      steps {
        echo """
        Pull Request detected
        PR Number : ${CHANGE_ID}
        Source    : ${CHANGE_BRANCH}
        Target    : ${CHANGE_TARGET}
        """
      }
    }

    stage('Run Checkov & Decorate PR') {
      when {
        expression { env.CHANGE_ID != null }
      }
      steps {
        sh '''
          set -e

          # Extract owner/repo from GIT_URL
          REPO_URL="${GIT_URL%.git}"
          OWNER_REPO="${REPO_URL##*/github.com/}"

          echo "Running Checkov PR scan on $OWNER_REPO PR #${CHANGE_ID}"

          checkov \
            --directory . \
            --framework terraform \
            --repo-id "$OWNER_REPO" \
            --pr-number "${CHANGE_ID}" \
            --github-token "${GITHUB_TOKEN}" \
            --quiet
        '''
      }
    }
  }

  post {
    success {
      echo "✅ Checkov completed — results posted directly to PR"
    }
    failure {
      echo "❌ Checkov failed — see PR comments for findings"
    }
  }
}
