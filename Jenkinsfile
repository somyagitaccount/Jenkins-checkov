pipeline {
  agent any

  options {
    timeout(time: 20, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  stages {

    /* ---------------- INSTALL ---------------- */
    stage('Install Checkov') {
      steps {
        sh '''
          set +x
          echo "▶ Ensuring Checkov is available"

          PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
          USER_BIN="$HOME/Library/Python/${PYTHON_VERSION}/bin"
          export PATH="$PATH:$USER_BIN"

          if ! command -v checkov >/dev/null 2>&1; then
            pip3 install --user checkov --quiet
          fi

          echo "✔ Checkov ready: $(checkov --version)"
        '''
      }
    }

    /* ---------------- FULL SCAN ---------------- */
    stage('Run Checkov Terraform Scan') {
      steps {
        sh '''
          set +x
          echo "▶ Running Checkov Terraform scan"

          PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
          USER_BIN="$HOME/Library/Python/${PYTHON_VERSION}/bin"
          export PATH="$PATH:$USER_BIN"

          checkov \
            --directory . \
            --framework terraform \
            --compact \
            --summary-position top || true
        '''
      }
    }

    /* ---------------- PR DECORATION ---------------- */
    stage('Decorate Pull Request') {
      when {
        expression { env.CHANGE_ID != null }
      }
      steps {
        withCredentials([
          string(credentialsId: 'github-pat', variable: 'GITHUB_TOKEN')
        ]) {
          sh '''
            set +x
            echo "▶ Decorating PR with Checkov results"

            PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
            USER_BIN="$HOME/Library/Python/${PYTHON_VERSION}/bin"
            export PATH="$PATH:$USER_BIN"

            REPO_URL="${GIT_URL%.git}"
            OWNER_REPO="${REPO_URL##*/github.com/}"

            checkov \
              --directory . \
              --repo-id "$OWNER_REPO" \
              --pr-number "${CHANGE_ID}" \
              --github-token "$GITHUB_TOKEN" \
              --quiet
          '''
        }
      }
    }

  }

  post {
    success {
      echo "✅ Checkov completed successfully"
    }
    failure {
      echo "❌ Checkov detected policy violations"
    }
  }
}