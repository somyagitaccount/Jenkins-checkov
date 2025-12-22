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
          set +e
          python3 --version
          
          # Check if checkov is already installed
          if command -v checkov &> /dev/null; then
            echo "✅ Checkov is already installed"
            checkov --version
          else
            echo "📦 Checkov not found. Installing..."
            
            # Detect Python version for user bin path
            PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
            USER_BIN_PATH="$HOME/Library/Python/${PYTHON_VERSION}/bin"
            
            # Install checkov
            pip3 install --user checkov
            
            # Add to PATH for this session
            export PATH="$PATH:$USER_BIN_PATH"
            
            # Verify installation
            if [ -f "$USER_BIN_PATH/checkov" ]; then
              echo "✅ Checkov installed successfully"
              "$USER_BIN_PATH/checkov" --version
            else
              echo "❌ Checkov installation failed"
              exit 1
            fi
          fi
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

          # Ensure checkov is in PATH (in case it was just installed)
          PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
          USER_BIN_PATH="$HOME/Library/Python/${PYTHON_VERSION}/bin"
          export PATH="$PATH:$USER_BIN_PATH"

          # Verify checkov is available
          if ! command -v checkov &> /dev/null; then
            echo "❌ Error: checkov command not found"
            exit 1
          fi

          REPO_URL="${GIT_URL%.git}"
          OWNER_REPO="${REPO_URL##*/github.com/}"

          echo "Running Checkov PR scan on $OWNER_REPO PR #${CHANGE_ID}"

          checkov \
            --directory . \
            --framework terraform \
            --repo-id "$OWNER_REPO" \
            --pr-number "${CHANGE_ID}" \
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
