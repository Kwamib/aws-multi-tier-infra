pipeline {
    agent any

    parameters {
        string(name: 'ENGINEER_NAME', defaultValue: '', description: 'Engineer responsible for this build')
    }

    environment {
        PATH = "${PATH}:${getTerraformPath()}"
    }

    stages {
        stage('Notify Start') {
            steps {
                slackSend color: '#439FE0', message: "*TERRAFORM DEPLOYMENT PIPELINE STARTED*\nINITIATED BY: *`${params.ENGINEER_NAME}`*\n${env.JOB_NAME} [${env.BUILD_NUMBER}] (${env.BUILD_URL})"
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    try {
                        sh 'sleep 60'
                        sh 'terraform init'
                        slackSend color: '#439FE0', message: "*TERRAFORM INIT COMPLETED*\nENGINEER: *`${params.ENGINEER_NAME}`*\n${env.JOB_NAME} [${env.BUILD_NUMBER}] (${env.BUILD_URL})"
                    } catch (err) {
                        slackSend color: '#FFFF00', message: "*TERRAFORM INIT DETECTED STATE ISSUES*\nAttempting state migration...\n${env.JOB_NAME} [${env.BUILD_NUMBER}]"

                        try {
                            sh 'terraform init -migrate-state'
                            slackSend color: '#439FE0', message: "*TERRAFORM INIT COMPLETED AFTER MIGRATION*"
                        } catch (migrateErr) {
                            slackSend color: '#FF9900', message: "*MIGRATION FAILED - ATTEMPTING RECONFIGURE*"

                            try {
                                sh 'terraform init -reconfigure'
                                slackSend color: '#439FE0', message: "*TERRAFORM INIT COMPLETED AFTER RECONFIGURE*"
                            } catch (reconfigErr) {
                                slackSend color: '#FF0000', message: "*TERRAFORM INIT FAILED*\nAll recovery attempts failed\nERROR: ${reconfigErr.getMessage()}"
                                error("Terraform init failed after all recovery attempts: ${reconfigErr.getMessage()}")
                            }
                        }
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    try {
                        sh 'terraform plan -out=tfplan -input=false'
                        slackSend color: '#FFFF00', message: "*TERRAFORM PLAN COMPLETED - READY FOR APPROVAL*\nENGINEER: *`${params.ENGINEER_NAME}`*"
                    } catch (err) {
                        slackSend color: '#FF0000', message: "*TERRAFORM PLAN FAILED*\nERROR: ${err.getMessage()}"
                        error("Terraform plan failed")
                    }
                }
            }
        }

        stage('Deployment Approval') {
            steps {
                script {
                    try {
                        def userInput = input(
                            id: 'confirm',
                            message: 'Apply Terraform?',
                            parameters: [
                                [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply terraform?', name: 'confirm']
                            ]
                        )
                        slackSend color: '#FF9900', message: "*MANUAL APPROVAL GRANTED*\nAPPROVED BY: *`${params.ENGINEER_NAME}`*"
                    } catch (err) {
                        slackSend color: '#FF0000', message: "*DEPLOYMENT CANCELLED*\nCANCELLED BY: *`${params.ENGINEER_NAME}`*"
                        error("Deployment cancelled by user")
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    try {
                        sh 'terraform apply -input=false tfplan'
                        slackSend color: '#36a64f', message: "*TERRAFORM APPLY SUCCEEDED*\nAPPLIED BY: *`${params.ENGINEER_NAME}`*"
                    } catch (err) {
                        slackSend color: '#FF0000', message: "*TERRAFORM APPLY FAILED*\nERROR: ${err.getMessage()}"
                        error("Terraform apply failed")
                    }
                }
            }
        }

        stage('Post-Deployment Options') {
            steps {
                script {
                    try {
                        slackSend color: '#36a64f', message: "*DEPLOYMENT COMPLETE - Awaiting post-deployment decision...*"

                        def postAction = input(
                            id: 'post-deploy-action',
                            message: 'Deployment Successful! What would you like to do next?',
                            parameters: [
                                [$class: 'ChoiceParameterDefinition',
                                 choices: ['finish-and-keep', 'destroy-infrastructure'],
                                 description: 'Choose your next action',
                                 name: 'action']
                            ]
                        )

                        if (postAction == 'destroy-infrastructure') {
                            slackSend color: '#FF9900', message: "*DESTROY OPTION SELECTED*\nRequesting final confirmation..."

                            def destroyConfirm = input(
                                id: 'destroy-confirmation',
                                message: 'FINAL WARNING: This will DESTROY ALL infrastructure. This action CANNOT be undone.',
                                parameters: [
                                    [$class: 'StringParameterDefinition',
                                     defaultValue: '',
                                     description: 'Type exactly "DESTROY" to confirm',
                                     name: 'confirmation_text'],
                                    [$class: 'BooleanParameterDefinition',
                                     defaultValue: false,
                                     description: 'I understand this will destroy all infrastructure',
                                     name: 'final_confirm']
                                ]
                            )

                            if (destroyConfirm.confirmation_text == 'DESTROY' && destroyConfirm.final_confirm) {
                                slackSend color: '#FF0000', message: "*DESTRUCTION CONFIRMED*\nStarting teardown..."
                                sh 'terraform plan -destroy'
                                sh 'terraform destroy -auto-approve'
                                slackSend color: '#FF0000', message: "*INFRASTRUCTURE DESTROYED*\nDESTROYED BY: *`${params.ENGINEER_NAME}`*"
                            } else {
                                slackSend color: '#36a64f', message: "*DESTROY CANCELLED*\nInfrastructure preserved"
                            }
                        } else {
                            slackSend color: '#36a64f', message: "*DEPLOYMENT COMPLETE - INFRASTRUCTURE PRESERVED*"
                        }
                    } catch (err) {
                        slackSend color: '#36a64f', message: "*POST-DEPLOYMENT STAGE CANCELLED*\nInfrastructure remains deployed"
                        echo "User cancelled post-deployment options - keeping infrastructure"
                    }
                }
            }
        }
    }

    post {
        failure {
            slackSend color: '#FF0000', message: "*PIPELINE FAILED*\nENGINEER: *`${params.ENGINEER_NAME}`*\n${env.JOB_NAME} [${env.BUILD_NUMBER}] (${env.BUILD_URL})"
        }
        success {
            slackSend color: '#36a64f', message: "*PIPELINE COMPLETED SUCCESSFULLY*\nENGINEER: *`${params.ENGINEER_NAME}`*\n${env.JOB_NAME} [${env.BUILD_NUMBER}] (${env.BUILD_URL})"
        }
        always {
            sh 'rm -f tfplan'
        }
    }
}

def getTerraformPath() {
    def tfHome = tool name: "terraform-14", type: "terraform"
    return tfHome
}
