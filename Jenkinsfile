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

        stage('Setup Tools') {
            steps {
                script {
                    echo "Setting up Terraform and Checkov..."

                    // -------- Terraform --------
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
                        error("Terraform not found. Please install Terraform.")
                    }

                    env.PATH = "${terraformPath}:${env.PATH}"
                    sh 'terraform version'

                    // -------- Checkov --------
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
                        error("Checkov not found. Please install Checkov.")
                    }

                    env.PATH = "${checkovPath}:${env.PATH}"
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
                        script: 'terraform fmt -check -recursive -diff projects/',
                        returnStatus: true
                    )

                    if (fmtResult != 0) {
                        echo "⚠ Terraform formatting issues detected"
                        currentBuild.result = 'UNSTABLE'
                    } else {
                        echo "✓ Terraform formatting is correct"
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
                    echo "Running Checkov scan on: ${projectPath}"

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
            echo "✓ Pipeline completed successfully"
        }
        unstable {
            echo "⚠ Pipeline completed with warnings"
        }
        failure {
            echo "✗ Pipeline failed"
        }
    }
}
