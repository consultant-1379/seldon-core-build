#!/usr/bin/env groovy

def bob = "./bob/bob"

def LOCKABLE_RESOURCE_LABEL = "bob-ci-patch-lcm"

def SLAVE_NODE = null

node(label: 'docker') {
    stage('Nominating build node') {
        SLAVE_NODE = "${NODE_NAME}"
        echo "Executing build on ${SLAVE_NODE}"
    }
}

pipeline {
    agent {
        node {
            label "${SLAVE_NODE}"
        }
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '50', artifactNumToKeepStr: '50'))
    }

    environment {
        TEAM_NAME = "${teamName}"
        KUBECONFIG = "${WORKSPACE}/.kube/config"
        DOCKER_CONFIG_FILE = "${WORKSPACE}"
        MAVEN_CLI_OPTS = "-Duser.home=${env.HOME} -B -s ${env.SETTINGS_CONFIG_FILE_NAME}"
        GIT_AUTHOR_NAME = "mxecifunc"
        GIT_AUTHOR_EMAIL = "PDLMMECIMM@pdl.internal.ericsson.com"
        GIT_COMMITTER_NAME = "${USER}"
        GIT_COMMITTER_EMAIL = "${GIT_AUTHOR_EMAIL}"
        GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GSSAPIAuthentication=no -o PubKeyAuthentication=yes"
        GERRIT_CREDENTIALS_ID = 'gerrit-http-password-mxecifunc'
        DOCKER_CONFIG = "${WORKSPACE}"
        // enable this during next seldon uplift
        FOSSA_ENABLED = "true"
    }

    // Stage names (with descriptions) taken from ADP Microservice CI Pipeline Step Naming Guideline: https://confluence.lmera.ericsson.se/pages/viewpage.action?pageId=122564754
    stages {
        stage('Commit Message Check') {
            steps {
                script {
                    def final commitMessage = new String(env.GERRIT_CHANGE_COMMIT_MESSAGE.decodeBase64())
                    if (commitMessage ==~ /(?ms)((Revert)|(\[MEE\-[0-9]+\])|(\[MXE\-[0-9]+\])|(\[MXESUP\-[0-9]+\])|(\[NoJira\]))+\s\S.*/) {
                        gerritReview labels: ['Commit-Message': 1]
                    } else {
                        def final message = 'Commit message check has failed'
                        def final link = 'https://confluence.lmera.ericsson.se/display/MXE/Code+review+WoW'
                        addWarningBadge text: message, link: link
                        addShortText text: 'malformed commit-msg', link: link, border: 0
                        gerritReview labels: ['Commit-Message': -1], message: message + ', see ' + link
                    }
                }
            }
        }

        stage('Submodule Init'){
            steps{
                sshagent(credentials: ['ssh-key-mxecifunc']) {
                    sh 'git clean -xdff'
                    sh 'git submodule sync'
                    sh 'git submodule update --init --recursive'
                }
            }
        }

        stage('Clean') {
            steps {
                script{
                    sh "${bob} clean"
                }
            }
        }

        stage('Init') {
            steps {
                sh "${bob} init-precodereview"
                script {
                    authorName = sh(returnStdout: true, script: 'git show -s --pretty=%an')
                    currentBuild.displayName = currentBuild.displayName + ' / ' + authorName
                    withCredentials([file(credentialsId: 'ARM_DOCKER_CONFIG', variable: 'DOCKER_CONFIG_FILE')]) {
                        writeFile file: 'config.json', text: readFile(DOCKER_CONFIG_FILE)
                    }
                }
            }
        }

        stage('Lint') {
            steps {
                sh "${bob} lint-license-check"
            }
            post {
                success {
                    gerritReview labels: ['Code-Format': 1]
                }
                unsuccessful {
                    gerritReview labels: ['Code-Format': -1]
                }
            }
        }

        stage('Images') {
            environment{
                ARM_API_TOKEN = credentials('arm-api-token-mxecifunc')
                SERO_ARM_TOKEN = credentials ('SERO_ARM_TOKEN')
            }
            steps {
                    sshagent(credentials: ['ssh-key-mxecifunc']) {
                                sh "${bob} image"
                    }
            }
            post {
                always {
                    archiveArtifacts allowEmptyArchive: true, artifacts: '**/image-design-rule-check-report*'
                }
            }
        }
        
        stage('FOSSA Scan'){
            when {
                expression {  env.FOSSA_ENABLED == "true" }
            }
            environment{
                FOSSA_API_KEY = credentials('FOSSA_API_KEY_PROD')
            }
            stages{                    
                stage('FOSSA Server Status Check') {
                    steps {
                        sh "${bob} fossa-server-check"
                    }
                }

                stage('FOSSA Analyze') {
                    when {
                        expression { readFile('.bob/var.fossa-available').trim() == "true" }
                    }
                    steps {
                        parallel(
                            "Seldon-Operator" : {
                                script {
                                    sh "${bob} fossa-seldon-operator-analyze"
                                }
                            },
                            "Seldon-Executor" : {
                                script {
                                    sh "${bob} fossa-seldon-executor-analyze"
                                }
                            },
                            "Seldon-Python" : {
                                script {
                                    sh "${bob} fossa-seldon-python-module-analyze"
                                }
                            }
                        )
                    }
                }
                stage('Fossa Scan Status Check'){
                    when {
                        expression { readFile('.bob/var.fossa-available').trim() == "true" }
                    }
                    steps {
                        parallel(
                            "Seldon-Operator" : {
                                script {
                                    sh "${bob} fossa-seldon-operator-scan-status-check"
                                }
                            },
                            "Seldon-Executor" : {
                                script {
                                    sh "${bob} fossa-seldon-executor-scan-status-check"
                                }
                            },
                            "Seldon-Python" : {
                                script {
                                    sh "${bob} fossa-seldon-python-module-scan-status-check"
                                }
                            }
                        )
                    }
                }
                stage('FOSSA Fetch Report') {
                    when {
                        expression {  readFile('.bob/var.fossa-available').trim() == "true" }
                    }
                    steps {
                        parallel(
                            "Seldon-Operator" : {
                                retry(5) {
                                    sh "${bob} fetch-seldon-operator-fossa-report-attribution"
                                    archiveArtifacts '*fossa-seldon-operator-report.json'
                                }
                            },
                            "Seldon-Executor" : {
                                retry(5) {
                                    sh "${bob} fetch-seldon-executor-fossa-report-attribution"
                                    archiveArtifacts '*fossa-seldon-executor-report.json'
                                }
                            },
                            "Seldon-Python" : {
                                retry(5) {
                                    sh "${bob} fetch-seldon-python-module-fossa-report-attribution"
                                    archiveArtifacts '*fossa-seldon-operator-python-module-report.json'
                                }
                            },
                        )
                    }
                }
            }
        }

        stage('FOSSA Dependency Validate') {
            steps {
                sh "${bob} dependency-validate-seldon-operator"
                sh "${bob} dependency-validate-seldon-executor"
                sh "${bob} dependency-validate-seldon-python-module"
            }
        }

        stage('Generate Input Files') {
            environment{
                MUNIN_TOKEN = credentials('MUNIN_TOKEN')
            }
            steps {
                parallel(
                    "Seldon Operator Dependency File for Registration": {
                        script {
                            sh "${bob} check-foss-in-mimer-seldon-operator"
                        }
                    },
                    "Seldon Executor Dependency File for Registration": {
                        script {
                            sh "${bob} check-foss-in-mimer-seldon-executor"
                        }
                    },
                    "Seldon Python Module Dependency File for Registration": {
                        script {
                            sh "${bob} check-foss-in-mimer-seldon-python-module"
                        }
                    }
                )
            }
            post {
                always {
                    archiveArtifacts allowEmptyArchive: true, artifacts: 'config/fossa/dependencies.seldon-operator.yaml'
                    archiveArtifacts allowEmptyArchive: true, artifacts: 'config/fossa/dependencies.seldon-executor.yaml'
                }
            }
        }
    }
    post {
        success {
            script {
                modifyBuildDescription()
                cleanWs()
            }
        }
    }
}

def modifyBuildDescription() {

    def DOCKER_IMAGE_NAME = "eric-aiml-model-lcm-seldon-core"
    def VERSION = readFile('.bob/var.version').trim()
    def SELDON_OPERATOR_DOCKER_IMAGE_LINK = "https://armdocker.rnd.ericsson.se/artifactory/proj-mlops-ci-internal-docker-global/proj-mlops-ci-internal/${DOCKER_IMAGE_NAME}-operator/${VERSION}/"
    def SELDON_EXECUTOR_DOCKER_IMAGE_LINK = "https://armdocker.rnd.ericsson.se/artifactory/proj-mlops-ci-internal-docker-global/proj-mlops-ci-internal/${DOCKER_IMAGE_NAME}-executor/${VERSION}/"

    currentBuild.description = "Seldon Operator Docker Image: <a href=${SELDON_OPERATOR_DOCKER_IMAGE_LINK}>${DOCKER_IMAGE_NAME}-operator-${VERSION}</a><br>Seldon Executor Docker Image: <a href=${SELDON_EXECUTOR_DOCKER_IMAGE_LINK}>${DOCKER_IMAGE_NAME}-executor-${VERSION}</a><br>Gerrit: <a href=${env.GERRIT_CHANGE_URL}>${env.GERRIT_CHANGE_URL}</a><br>"
}