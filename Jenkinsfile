#!groovy

workerNode = "xp-build-i01"

pipeline {
	agent {label workerNode}
	environment {
		DOCKER_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
		GITLAB_PRIVATE_TOKEN = credentials("ai-gitlab-api-token")
		LOWELL_URL = credentials("ny-lowell-prod")
	}
	triggers {
		pollSCM("H/02 * * * *")
		cron("0 23 * * 7")
	}
	stages {
		stage("docker build model") {
			steps {
				script {
					solr_container = docker.build("simple-search-solr", "--no-cache .").run("-P")
					sh """#!/usr/bin/env bash
						set -xe
						rm -rf env pid-list work_to_holdings.joblib miniconda miniconda.sh env
						curl -L https://artifactory.dbc.dk/artifactory/ai-generic/simple-search/773000.pids -o pid-list
						curl -L https://artifactory.dbc.dk/artifactory/ai-generic/simple-search/work_to_holdings.joblib -o work_to_holdings.joblib
						curl -L https://artifactory.dbc.dk/artifactory/ai-generic/simple-search/synonyms.txt -o synonyms.txt
						curl -L https://artifactory.dbc.dk/artifactory/ai-generic/simple-search/popularity-2018-2020.count.gz -o popularity-2018-2020.count.gz
						curl -k https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh
						bash miniconda.sh -b -p miniconda
						source miniconda/bin/activate
						python3 -m venv env
						source env/bin/activate
						pip install -U pip
						pip install simple-search
						solr-indexer pid-list http://${solr_container.port(8983)}/solr/simple-search work_to_holdings.joblib popularity-2018-2020.count.gz synonyms.txt
					"""
					sh "rm -r data"
					// take data from the temporary solr container to include in the final solr image
					docker.script.sh(script: "docker cp ${solr_container.id}:/opt/solr/server/solr/simple-search/data data")
					image = docker.build("docker-xp.dbc.dk/simple-search-solr:${DOCKER_TAG}", "--no-cache .")
					image.push()
					if(env.BRANCH_NAME == "master") {
						image.push("latest")
					}
					// clean up indexed data to avoid it being used in the next build
					sh "rm -r data"
					solr_container.stop()
				}
			}
		}
		stage("update staging version number") {
			agent {
				docker {
					label workerNode
					image "docker.dbc.dk/build-env"
					alwaysPull true
				}
			}
			when {
				branch "master"
			}
			steps {
				sh "set-new-version simple-search-solr-1-0.yml ${env.GITLAB_PRIVATE_TOKEN} ai/simple-search-solr-secrets ${env.DOCKER_TAG} -b staging"
				build job: "ai/simple-search/simple-search-solr-deploy/staging", wait: true
			}
		}
		stage("validate staging") {
			agent {
				docker {
					label workerNode
					image "docker.dbc.dk/build-env"
					alwaysPull true
				}
			}
			when {
				branch "master"
			}
			steps {
				sh "webservice_validation.py http://simple-search-solr-1-0.mi-staging.svc.cloud.dbc.dk deploy/validation.yml"
			}
		}
		stage("update prod version number") {
			agent {
				docker {
					label workerNode
					image "docker.dbc.dk/build-env"
					alwaysPull true
				}
			}
			when {
				branch "master"
			}
			steps {
				sh "set-new-version simple-search-solr-1-0.yml ${env.GITLAB_PRIVATE_TOKEN} ai/simple-search-solr-secrets ${env.DOCKER_TAG} -b prod"
				build job: "ai/simple-search/simple-search-solr-deploy/prod", wait: true
			}
		}
		stage("validate prod") {
			agent {
				docker {
					label workerNode
					image "docker.dbc.dk/build-env"
					alwaysPull true
				}
			}
			when {
				branch "master"
			}
			steps {
				sh "webservice_validation.py http://simple-search-solr-1-0.mi-prod.svc.cloud.dbc.dk deploy/validation.yml"
			}
		}
	}
}
