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
        RELEASE = "true"
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
        FOSSA_ENABLED = "true"
    }

    // Stage names (with descriptions) taken from ADP Microservice CI Pipeline Step Naming Guideline: https://confluence.lmera.ericsson.se/pages/viewpage.action?pageId=122564754
    stages {
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
                sh "${bob} init-drop"
                script {
                    authorName = sh(returnStdout: true, script: 'git show -s --pretty=%an')
                    currentBuild.displayName = currentBuild.displayName + ' / ' + authorName
                    withCredentials([file(credentialsId: 'ARM_DOCKER_CONFIG', variable: 'DOCKER_CONFIG_FILE')]) {
                        writeFile file: 'config.json', text: readFile(DOCKER_CONFIG_FILE)
                    }
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

        stage('Publish'){
            steps{
                        sh "${bob} publish"
            }
        }

        stage('Create drop Git tag'){
            steps{
                    sshagent(credentials: ['ssh-key-mxecifunc']) {
                        sh "${bob} create-drop-git-tag"
                }
            }
        }

        stage('Push to Model-lcm'){
            steps{
                withCredentials([usernamePassword(credentialsId: 'gerrit-http-password-mxecifunc', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                    sshagent(credentials: ['ssh-key-mxecifunc']) {
                        sh "${bob} update-seldon-in-model-lcm"
                    }
                }
            }
            post {
                success {
                    script {
                            mail to: 'd386f28a.ericsson.onmicrosoft.com@emea.teams.ms, PDLMMECIMM@pdl.internal.ericsson.com',
                            subject: "[model-lcm-seldon] Changeset verified successfully in model-lcm for seldon image updation",
                            body: "<b>Refer:</b> ${env.BUILD_URL} <br><br>" +
                                  "<b>Note:</b> This mail was automatically sent as part of ${env.JOB_NAME} jenkins job.",
                            mimeType: 'text/html'
                        }
                }
                unsuccessful {
                    script {
                            mail to: 'd386f28a.ericsson.onmicrosoft.com@emea.teams.ms, PDLMMECIMM@pdl.internal.ericsson.com',
                            subject: "[model-lcm-seldon] Changeset verification failed in model-lcm for seldon image updation",
                            body: "<b>Refer:</b> ${env.BUILD_URL} <br><br>" +
                                  "<b>Note:</b> This mail was automatically sent as part of ${env.JOB_NAME} jenkins job.",
                            mimeType: 'text/html'
                    }
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
    def SELDON_OPERATOR_DOCKER_IMAGE_LINK = "https://armdocker.rnd.ericsson.se/artifactory/proj-mlops-drop-docker-global/proj-mlops-ci-internal/${DOCKER_IMAGE_NAME}-operator/${VERSION}/"
    def SELDON_EXECUTOR_DOCKER_IMAGE_LINK = "https://armdocker.rnd.ericsson.se/artifactory/proj-mlops-drop-docker-global/proj-mlops-ci-internal/${DOCKER_IMAGE_NAME}-executor/${VERSION}/"

    currentBuild.description = "Seldon Operator Docker Image: <a href=${SELDON_OPERATOR_DOCKER_IMAGE_LINK}>${DOCKER_IMAGE_NAME}-operator-${VERSION}</a><br>Seldon Executor Docker Image: <a href=${SELDON_EXECUTOR_DOCKER_IMAGE_LINK}>${DOCKER_IMAGE_NAME}-executor-${VERSION}</a><br>Gerrit: <a href=${env.GERRIT_CHANGE_URL}>${env.GERRIT_CHANGE_URL}</a><br>"
}
