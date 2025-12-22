pipeline {
  agent any

  options {
    timeout(time: 20, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    CHECKOV_OUTPUT = "checkov-results.json"
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
    stage('Run Full Checkov Scan') {
      steps {
        sh '''
          set +x
          echo "▶ Running full Checkov scan (all frameworks)"

          PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
          USER_BIN="$HOME/Library/Python/${PYTHON_VERSION}/bin"
          export PATH="$PATH:$USER_BIN"

          # Run scan and capture output
          checkov \
            --directory . \
            --output json \
            --output-file-path . \
            --quiet || true

          echo "✔ Scan completed"
        '''
      }
    }

    /* ---------------- SUMMARY ---------------- */
    stage('Checkov Scan Summary') {
      steps {
        sh '''
          set +x
          echo "▶ Checkov Scan Summary"

          python3 - << 'EOF'
import json

with open("checkov-results.json") as f:
    data = json.load(f)

summary = data.get("summary", {})

print(f"✅ Passed : {summary.get('passed', 0)}")
print(f"❌ Failed : {summary.get('failed', 0)}")
print(f"⏭ Skipped: {summary.get('skipped', 0)}")
print(f"ℹ️  Parsing Errors: {summary.get('parsing_errors', 0)}")
EOF
        '''
      }
    }

    /* ---------------- PR DECORATION ---------------- */
    stage('Decorate Pull Request') {
      when {
        expression { env.CHANGE_ID != null }
      }
      steps {
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

  post {
    success {
      echo "✅ Checkov completed successfully"
    }
    failure {
      echo "❌ Checkov detected policy violations"
    }
  }
}