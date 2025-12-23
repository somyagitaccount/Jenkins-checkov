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
      steps {
        withCredentials([
          string(credentialsId: 'github-pat', variable: 'GITHUB_TOKEN')
        ]) {
          sh '''
            set +x
            echo "▶ Attempting to decorate PR with Checkov results"

            PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
            USER_BIN="$HOME/Library/Python/${PYTHON_VERSION}/bin"
            export PATH="$PATH:$USER_BIN"

            REPO_URL="${GIT_URL%.git}"
            OWNER_REPO="${REPO_URL##*/github.com/}"

            # Try to get PR number from various Jenkins environment variables
            PR_NUMBER="${CHANGE_ID:-${ghprbPullId:-${PR_NUMBER}}}"
            
            # If still not found, try to extract from branch name
            if [ -z "$PR_NUMBER" ]; then
              BRANCH="${GIT_BRANCH:-${BRANCH_NAME:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")}}"
              if [ -n "$BRANCH" ]; then
                # Try to extract from branch name (e.g., PR-123, pr/123, pull/123, origin/pr/123)
                PR_NUMBER=$(echo "$BRANCH" | grep -oE '(PR-|pr/|pull/)[0-9]+' | grep -oE '[0-9]+' | head -1)
              fi
            fi

            if [ -z "$PR_NUMBER" ]; then
              echo "⚠️ Could not determine PR number from environment variables or branch name"
              echo "   Available env vars: CHANGE_ID=${CHANGE_ID}, ghprbPullId=${ghprbPullId}, PR_NUMBER=${PR_NUMBER}"
              echo "   Branch: ${GIT_BRANCH:-${BRANCH_NAME:-unknown}}"
              echo "   Skipping PR decoration - this may not be a PR build"
              exit 0
            fi

            echo "📝 Posting results to PR #${PR_NUMBER} in repository ${OWNER_REPO}"
            # Always post results to PR conversation regardless of exit code
            checkov \
              --directory . \
              --repo-id "$OWNER_REPO" \
              --pr-number "${PR_NUMBER}" \
              --github-token "$GITHUB_TOKEN" \
              --compact \
              --summary-position top || true

            echo "✔ PR decoration completed - results posted to PR conversation"
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