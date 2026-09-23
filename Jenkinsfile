// =============================================================================
// CliXX Retail — Terraform Deployment Pipeline
//
// Stages: validate -> scan -> init -> plan -> approve -> apply -> post-deploy
//
// Design notes:
//   - The plan produced in the Plan stage is the exact plan applied later.
//     Nothing re-plans at apply time.
//   - Every gate is fail-closed: an unanswered or negative response stops
//     the build rather than falling through.
//   - State recovery (-migrate-state / -reconfigure) is opt-in via a build
//     parameter, never automatic.
// =============================================================================

pipeline {
    agent any

    parameters {
        // CHANGED: was a free-text ENGINEER_NAME defaulting to ''. Attribution is
        // now taken from the Jenkins build cause (see resolveTriggeredBy below),
        // so it can't be left blank or spoofed by typing someone else's name.
        booleanParam(
            name: 'ALLOW_STATE_RECOVERY',
            defaultValue: false,
            description: 'Permit "terraform init -migrate-state" / "-reconfigure" if a plain init fails. ' +
                         'These rewrite backend state — only enable when you have reviewed the backend change.'
        )
        booleanParam(
            name: 'SKIP_SECURITY_SCAN',
            defaultValue: false,
            description: 'Skip the Checkov policy scan. Use only when the scanner itself is broken.'
        )
    }

    options {
        // A stuck approval used to hang forever. Nothing runs longer than this.
        timeout(time: 2, unit: 'HOURS')
        timestamps()
        disableConcurrentBuilds()          // two applies against one state file is how state gets corrupted
        buildDiscarder(logRotator(numToKeepStr: '30'))
    }

    environment {
        // CHANGED: tool was "terraform-14" (Terraform 0.14) while the README
        // requires >= 1.3.0. Point this at the matching tool installation name
        // configured in Manage Jenkins > Tools.
        PATH         = "${PATH}:${tool(name: 'terraform-1.9', type: 'terraform')}"
        TF_IN_AUTOMATION = 'true'          // quiets the "next steps" chatter in CI logs
        TF_INPUT     = '0'                 // never block on an interactive prompt
    }

    stages {

        stage('Notify Start') {
            steps {
                script {
                    env.TRIGGERED_BY = resolveTriggeredBy()
                    notify('#439FE0', 'TERRAFORM DEPLOYMENT PIPELINE STARTED')
                }
            }
        }

        // NEW: cheap correctness checks before anything touches AWS. Catching a
        // malformed variable block here costs seconds; catching it at plan time
        // costs an init, a backend lock, and a round trip.
        stage('Validate') {
            steps {
                sh 'terraform fmt -check -recursive -diff'
                sh 'terraform init -backend=false'   // no backend: validate only needs the provider schema
                sh 'terraform validate'
            }
            post {
                failure {
                    notify('#FF0000', 'FORMAT / VALIDATE FAILED — run "terraform fmt -recursive" locally')
                }
            }
        }

        // NEW: static policy scan. This is what makes a "quality and vulnerability
        // checks" claim concrete. soft-fail keeps it advisory at first; flip to
        // hard failure once the findings are triaged.
        stage('Security Scan') {
            when { expression { !params.SKIP_SECURITY_SCAN } }
            steps {
                sh 'checkov --directory . --framework terraform --soft-fail --output cli --output junitxml --output-file-path console,checkov-report.xml'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'checkov-report.xml'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    // CHANGED: removed the bare `sh 'sleep 60'`. If a real wait is
                    // needed (agent bootstrap, credential propagation), wait on the
                    // condition, not on the clock — see waitForCredentials() below.
                    waitForCredentials()

                    try {
                        sh 'terraform init -input=false'
                    } catch (err) {
                        // CHANGED: the old pipeline silently ran -migrate-state and
                        // then -reconfigure on any init failure. Both rewrite where
                        // state lives, and doing that unattended can detach or
                        // clobber state. Now it stops unless a human opted in by
                        // setting ALLOW_STATE_RECOVERY on this build.
                        if (!params.ALLOW_STATE_RECOVERY) {
                            notify('#FF0000', "TERRAFORM INIT FAILED\\nBackend recovery not authorised for this build.\\n" +
                                              "Review the backend change, then re-run with ALLOW_STATE_RECOVERY.\\nERROR: ${err.getMessage()}")
                            error("terraform init failed: ${err.getMessage()}")
                        }

                        notify('#FFFF00', 'INIT FAILED — ALLOW_STATE_RECOVERY is set, attempting state migration')
                        try {
                            sh 'terraform init -migrate-state -input=false'
                        } catch (migrateErr) {
                            notify('#FF9900', 'MIGRATION FAILED — attempting reconfigure')
                            sh 'terraform init -reconfigure -input=false'
                        }
                        notify('#439FE0', 'TERRAFORM INIT COMPLETED AFTER BACKEND RECOVERY')
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=tfplan -input=false -lock-timeout=5m'

                // NEW: render the plan in a readable form and keep it. Previously the
                // approver clicked Proceed with no idea what was about to change.
                sh 'terraform show -no-color tfplan > tfplan.txt'
                script {
                    env.PLAN_SUMMARY = sh(
                        script: "grep -E '^Plan:' tfplan.txt || echo 'Plan: no changes'",
                        returnStdout: true
                    ).trim()
                }
                archiveArtifacts artifacts: 'tfplan.txt', fingerprint: true
            }
            post {
                success {
                    notify('#FFFF00', "PLAN COMPLETE — AWAITING APPROVAL\\n`${env.PLAN_SUMMARY}`\\nFull plan: ${env.BUILD_URL}artifact/tfplan.txt")
                }
                failure {
                    notify('#FF0000', 'TERRAFORM PLAN FAILED')
                }
            }
        }

        stage('Deployment Approval') {
            options {
                // Bounded so an ignored approval can't hold an executor all weekend.
                timeout(time: 30, unit: 'MINUTES')
            }
            steps {
                script {
                    def approval
                    try {
                        approval = input(
                            id: 'confirm',
                            message: "Apply this plan?  ${env.PLAN_SUMMARY}",
                            ok: 'Submit',
                            submitterParameter: 'approver',   // records WHO approved, from Jenkins auth
                            parameters: [
                                booleanParam(
                                    name: 'confirm',
                                    defaultValue: false,
                                    description: 'I have reviewed the plan output and authorise this apply'
                                )
                            ]
                        )
                    } catch (err) {
                        // Covers both an explicit Abort and the 30-minute timeout.
                        notify('#FF0000', 'DEPLOYMENT CANCELLED OR TIMED OUT — nothing applied')
                        error('Deployment not approved')
                    }

                    // ===== THE BUG FIX =====
                    // The old code assigned input(...) to userInput and never looked
                    // at it. With a single parameter, input() returns that parameter's
                    // value — so an approver who left the box UNCHECKED and clicked
                    // Proceed got a `false` back, the pipeline ignored it, and the
                    // apply ran anyway. Only Abort actually stopped it.
                    //
                    // Two parameters are requested above (confirm + submitterParameter),
                    // so input() now returns a Map. Read the flag explicitly and fail
                    // closed if it isn't true.
                    if (!approval?.confirm) {
                        notify('#FF0000', 'APPROVAL DECLINED — confirmation box was not checked. Nothing applied.')
                        error('Apply not confirmed')
                    }

                    env.APPROVED_BY = approval.approver ?: 'unknown'
                    notify('#FF9900', "MANUAL APPROVAL GRANTED\\nAPPROVED BY: `${env.APPROVED_BY}`")
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                // Applies the saved plan file — not a fresh plan. What was approved
                // is exactly what gets applied.
                sh 'terraform apply -input=false -lock-timeout=5m tfplan'
            }
            post {
                success { notify('#36a64f', "TERRAFORM APPLY SUCCEEDED\\nAPPROVED BY: `${env.APPROVED_BY}`") }
                failure { notify('#FF0000', 'TERRAFORM APPLY FAILED — state may be partially applied, check before re-running') }
            }
        }

        stage('Post-Deployment Options') {
            options {
                timeout(time: 30, unit: 'MINUTES')
            }
            steps {
                script {
                    def postAction
                    try {
                        postAction = input(
                            id: 'post-deploy-action',
                            message: 'Deployment successful. Next action?',
                            parameters: [
                                choice(
                                    name: 'action',
                                    choices: ['finish-and-keep', 'destroy-infrastructure'],
                                    description: 'Keep the stack, or tear it down'
                                )
                            ]
                        )
                    } catch (err) {
                        // Timeout or abort here must never destroy. Keeping the
                        // infrastructure is the safe default.
                        notify('#36a64f', 'POST-DEPLOYMENT STAGE CANCELLED — infrastructure preserved')
                        return
                    }

                    if (postAction != 'destroy-infrastructure') {
                        notify('#36a64f', 'DEPLOYMENT COMPLETE — INFRASTRUCTURE PRESERVED')
                        return
                    }

                    notify('#FF9900', 'DESTROY SELECTED — requesting final confirmation')

                    def destroyConfirm
                    try {
                        destroyConfirm = input(
                            id: 'destroy-confirmation',
                            message: 'FINAL WARNING: this destroys ALL infrastructure in this state. Cannot be undone.',
                            submitterParameter: 'destroyer',
                            parameters: [
                                string(name: 'confirmation_text', defaultValue: '',
                                       description: 'Type exactly: DESTROY'),
                                booleanParam(name: 'final_confirm', defaultValue: false,
                                             description: 'I understand this destroys all infrastructure')
                            ]
                        )
                    } catch (err) {
                        notify('#36a64f', 'DESTROY CANCELLED — infrastructure preserved')
                        return
                    }

                    // This gate was already correct in the original — both conditions
                    // are read off the returned Map. Kept as-is.
                    if (destroyConfirm.confirmation_text == 'DESTROY' && destroyConfirm.final_confirm) {
                        notify('#FF0000', "DESTRUCTION CONFIRMED BY `${destroyConfirm.destroyer}` — starting teardown")
                        sh 'terraform plan -destroy -out=tfdestroy -input=false'
                        sh 'terraform apply -input=false tfdestroy'   // applies the reviewed destroy plan
                        notify('#FF0000', "INFRASTRUCTURE DESTROYED BY `${destroyConfirm.destroyer}`")
                    } else {
                        notify('#36a64f', 'DESTROY CANCELLED — confirmation did not match. Infrastructure preserved.')
                    }
                }
            }
        }
    }

    post {
        failure { notify('#FF0000', 'PIPELINE FAILED') }
        success { notify('#36a64f', 'PIPELINE COMPLETED SUCCESSFULLY') }
        always {
            // Plan files can contain resource attributes; don't leave them on the agent.
            sh 'rm -f tfplan tfdestroy'
            cleanWs()
        }
    }
}

// =============================================================================
// Helpers
// =============================================================================

// Attribution from Jenkins itself rather than a typed-in name. Falls back
// sensibly for timer- and webhook-triggered builds.
def resolveTriggeredBy() {
    def userCause = currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')
    if (userCause) {
        return userCause[0].userName ?: userCause[0].userId
    }
    if (currentBuild.getBuildCauses('hudson.triggers.TimerTrigger$TimerTriggerCause')) {
        return 'scheduled trigger'
    }
    return 'automated trigger'
}

// Replaces the old `sh 'sleep 60'`. Waits on the actual precondition — the AWS
// credentials/role being usable — instead of guessing at a duration. Fails fast
// if they never become available.
def waitForCredentials() {
    timeout(time: 3, unit: 'MINUTES') {
        waitUntil(initialRecurrencePeriod: 5000) {
            script {
                return sh(script: 'aws sts get-caller-identity > /dev/null 2>&1', returnStatus: true) == 0
            }
        }
    }
}

def notify(String color, String message) {
    slackSend(
        color: color,
        message: "*${message}*\nTRIGGERED BY: `${env.TRIGGERED_BY ?: 'unknown'}`\n" +
                 "${env.JOB_NAME} [${env.BUILD_NUMBER}] (${env.BUILD_URL})"
    )
}
