pipeline {
  agent any

  options {
    timestamps()
    timeout(time: 20, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  stages {

    stage('Install Checkov') {
      steps {
        sh '''
          python3 --version
          pip3 install --user checkov
          export PATH=$PATH:$HOME/Library/Python/3.9/bin
          checkov --version
        '''
      }
    }

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

          REPO_URL="${GIT_URL%.git}"
          OWNER_REPO="${REPO_URL##*/github.com/}"

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
