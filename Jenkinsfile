pipeline {
  agent any

  parameters {
    string(name: 'PR_NUMBER', defaultValue: '', description: 'GitHub Pull Request number (leave empty to auto-detect from branch)')
  }

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

            # Try to get PR number from build parameter first
            PR_NUMBER="${params.PR_NUMBER}"

            # If not provided as parameter, try environment variables
            if [ -z "$PR_NUMBER" ] || [ "$PR_NUMBER" = "" ]; then
              PR_NUMBER="${CHANGE_ID:-${ghprbPullId}}"
            fi

            # If still not found, try to extract from branch name
            if [ -z "$PR_NUMBER" ] || [ "$PR_NUMBER" = "" ]; then
              BRANCH="${GIT_BRANCH:-${BRANCH_NAME:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")}}"
              # Remove origin/ prefix if present
              BRANCH=$(echo "$BRANCH" | sed 's|^origin/||')
              
              if [ -n "$BRANCH" ]; then
                # Try to extract from branch name (e.g., PR-123, pr/123, pull/123)
                PR_NUMBER=$(echo "$BRANCH" | grep -oE '(PR-|pr/|pull/)[0-9]+' | grep -oE '[0-9]+' | head -1)
              fi
            fi

            # If still not found, try to find PR using GitHub API
            if [ -z "$PR_NUMBER" ] || [ "$PR_NUMBER" = "" ]; then
              echo "🔍 PR number not found, attempting to find PR via GitHub API..."
              
              BRANCH="${GIT_BRANCH:-${BRANCH_NAME:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")}}"
              BRANCH=$(echo "$BRANCH" | sed 's|^origin/||')
              
              if [ -n "$BRANCH" ] && [ -n "$OWNER_REPO" ]; then
                # Extract owner from OWNER_REPO (format: owner/repo)
                OWNER=$(echo "$OWNER_REPO" | cut -d'/' -f1)
                REPO=$(echo "$OWNER_REPO" | cut -d'/' -f2)
                
                # Query GitHub API to find open PRs for this branch
                API_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                  "https://api.github.com/repos/${OWNER_REPO}/pulls?head=${OWNER}:${BRANCH}&state=open" || echo "")
                
                if [ -n "$API_RESPONSE" ] && [ "$API_RESPONSE" != "[]" ] && [ "$API_RESPONSE" != "null" ]; then
                  PR_NUMBER=$(echo "$API_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data[0]['number'] if data and len(data) > 0 else '')" 2>/dev/null || echo "")
                  if [ -n "$PR_NUMBER" ]; then
                    echo "✅ Found PR #${PR_NUMBER} for branch ${BRANCH}"
                  fi
                fi
              fi
            fi

            if [ -z "$PR_NUMBER" ] || [ "$PR_NUMBER" = "" ]; then
              echo "⚠️ Could not determine PR number"
              echo "   Branch: ${BRANCH:-unknown}"
              echo "   Repository: ${OWNER_REPO:-unknown}"
              echo "   💡 Tip: Set PR_NUMBER as a build parameter when triggering the job"
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