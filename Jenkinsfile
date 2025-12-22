pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev'],
            description: 'Select the environment to validate'
        )
        booleanParam(
            name: 'RUN_TERRAFORM_FMT',
            defaultValue: true,
            description: 'Run terraform fmt check'
        )
        booleanParam(
            name: 'RUN_TERRAFORM_VALIDATE',
            defaultValue: true,
            description: 'Run terraform validate'
        )
        booleanParam(
            name: 'RUN_CHECKOV',
            defaultValue: true,
            description: 'Run Checkov security scan'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    // Checkout from GitHub repository
                    try {
                        // Try SCM checkout first (if configured in Jenkins job)
                        checkout scm
                        echo "✓ Code checked out from SCM"
                    } catch (Exception e) {
                        // Fallback: explicit Git checkout from GitHub
                        echo "SCM not configured, checking out directly from GitHub..."
                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: '*/dev']],
                            doGenerateSubmoduleConfigurations: false,
                            extensions: [],
                            submoduleCfg: [],
                            userRemoteConfigs: [[
                                url: 'https://github.com/somyagitaccount/Jenkins-checkov.git'
                            ]]
                        ])
                        echo "✓ Code checked out from GitHub repository (dev branch)"
                    }
                }
            }
        }
        
        stage('Setup Tools') {
            steps {
                script {
                    echo "Setting up Terraform and Checkov..."
                    
                    // Setup Terraform - check for local installation
                    def terraformPath = sh(
                        script: '''
                            if [ -f /opt/homebrew/bin/terraform ]; then
                                echo "/opt/homebrew/bin"
                            elif [ -f /usr/local/bin/terraform ]; then
                                echo "/usr/local/bin"
                            elif command -v terraform &> /dev/null; then
                                dirname $(command -v terraform)
                            else
                                echo "notfound"
                            fi
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    if (terraformPath == 'notfound') {
                        error("Terraform not found. Please ensure Terraform is installed and available in PATH.")
                    } else {
                        env.PATH = "${terraformPath}:${env.PATH}"
                        echo "Found Terraform at: ${terraformPath}/terraform"
                    }
                    
                    // Verify Terraform
                    sh 'terraform version'
                    
                    // Setup Checkov - check for local installation
                    def checkovPath = sh(
                        script: '''
                            if [ -f /opt/homebrew/bin/checkov ]; then
                                echo "/opt/homebrew/bin"
                            elif [ -f /usr/local/bin/checkov ]; then
                                echo "/usr/local/bin"
                            elif command -v checkov &> /dev/null; then
                                dirname $(command -v checkov)
                            else
                                echo "notfound"
                            fi
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    if (checkovPath == 'notfound') {
                        error("Checkov not found. Please ensure Checkov is installed and available in PATH.")
                    } else {
                        env.PATH = "${checkovPath}:${env.PATH}"
                        echo "Found Checkov at: ${checkovPath}/checkov"
                    }
                    
                    // Verify Checkov
                    sh 'checkov --version'
                }
            }
        }
        
        stage('Terraform Format Check') {
            when {
                expression { params.RUN_TERRAFORM_FMT }
            }
            steps {
                script {
                    echo "Checking Terraform formatting..."
                    def fmtResult = sh(
                        script: 'terraform fmt -check -recursive -diff',
                        returnStatus: true
                    )
                    
                    if (fmtResult != 0) {
                        echo "⚠ Warning: Terraform formatting issues detected"
                        echo "Run 'terraform fmt -recursive' to fix formatting issues"
                        currentBuild.result = 'UNSTABLE'
                    } else {
                        echo "✓ All Terraform files are properly formatted"
                    }
                }
            }
        }
        
        stage('Terraform Validate') {
            when {
                expression { params.RUN_TERRAFORM_VALIDATE }
            }
            steps {
                script {
                    def projectPath = "projects/nonprod/${params.ENVIRONMENT}"
                    echo "Validating Terraform in: ${projectPath}"
                    
                    dir(projectPath) {
                        sh '''
                            terraform init -backend=false
                            terraform validate
                        '''
                    }
                }
            }
        }
        
        stage('Checkov Security Scan') {
            when {
                expression { params.RUN_CHECKOV }
            }
            steps {
                script {
                    def projectPath = "projects/nonprod/${params.ENVIRONMENT}"
                    echo "Running Checkov security scan on: ${projectPath}"
                    
                    // Run checkov from root to use .checkov.yml config file
                    // Pipeline will fail if vulnerabilities are found
                    sh """
                        checkov -d ${projectPath} \
                            --framework terraform \
                            --config-file .checkov.yml \
                            --output cli \
                            --compact
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✓ Pipeline completed successfully!"
        }
        failure {
            echo "✗ Pipeline failed. Please check the logs for details."
        }
    }
}
