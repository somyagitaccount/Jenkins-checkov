pipeline {
    agent {
        docker {
            image 'hashicorp/terraform:1.5'
            args '--entrypoint=""'
        }
    }

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

        stage('Install Tools') {
            steps {
                sh '''
                    apk add --no-cache python3 py3-pip git
                    pip3 install --no-cache-dir checkov
                    terraform version
                    checkov --version
                '''
            }
        }

        stage('Terraform Format Check') {
            when {
                expression { params.RUN_TERRAFORM_FMT }
            }
            steps {
                sh 'terraform fmt -check -recursive -diff projects/'
            }
        }

        stage('Terraform Validate') {
            when {
                expression { params.RUN_TERRAFORM_VALIDATE }
            }
            steps {
                dir("projects/nonprod/${params.ENVIRONMENT}") {
                    sh '''
                        terraform init -backend=false
                        terraform validate
                    '''
                }
            }
        }

        stage('Checkov Security Scan') {
            when {
                expression { params.RUN_CHECKOV }
            }
            steps {
                sh """
                    checkov -d projects/nonprod/${params.ENVIRONMENT} \
                      --framework terraform \
                      --config-file .checkov.yml \
                      --output cli \
                      --compact
                """
            }
        }
    }

    post {
        success {
            echo "✓ Pipeline completed successfully"
        }
        failure {
            echo "✗ Pipeline failed due to Terraform or security violations"
        }
    }
}