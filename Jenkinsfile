#!groovy

workerNode = "xp-build-i01"

pipeline {
	agent {label workerNode}
	environment {
		DOCKER_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
		GITLAB_PRIVATE_TOKEN = credentials("ai-gitlab-api-token")
		LOWELL_URL = credentials("lowell_db_connection_string")
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
					recommender_image = docker.image("docker-xp.dbc.dk/simple-search")
					recommender_image.pull()
					// Run the container like this to be able to run it in the foreground
					sh "curl -L https://artifactory.dbc.dk/artifactory/ai-generic/simple-search/773000.pids -o pid-list"
					docker.script.sh(script: "docker run --rm -v ${WORKSPACE}/pid-list:/pid-list -e LOWELL_URL=${LOWELL_URL} --net host ${recommender_image.id} solr-indexer /pid-list http://${solr_container.port(8983)}/solr/simple-search", returnStdout: true).trim()
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
