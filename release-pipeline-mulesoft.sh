#!/bin/bash
#set -x
#source /etc/profile

SCRIPT_ENVIRONMENT="${1}"
ANYPOINT_CLIENT_ID="${2}"
ANYPOINT_CLIENT_SECRET="${3}"
MULE_KEY="${4}"
WORKER_NUMBER="${5}"
WORKER_TYPE="${6}"
GROUP_ID="${7}"
VERSION="${8}"
CLOUDHUB_APP_NAME="${9}"
NEXUS_DOMAIN="${10}"
GITHUB_REPO="${11}"
PACKAGING="${12}"
GIT_BRANCH="${13}"
ENVIRONMENT="${14}"
MULE_USERNAME="${15}"
MULE_PASSWORD="${16}"
ReleasePrefixOrTagName="${17}"
STASH_REPO="${18}"
ADDITIONAL_PARAMS="${19}"

echo "manual checkout starting..."
if [ -d "${GITHUB_REPO}" ]; then rm -Rf ${GITHUB_REPO}; fi

codeToCheckoutFrom=${GIT_BRANCH}
MULE_PROXY_HOST=""
MULE_PROXY_HOST_PORT=""

#EK variables - START
ELK_SYS_URL_NON_PROD="https://digital-core2-system-elk.apps.gnp.aws.optus.com.au/mule-logs/_doc"
ELK_SYS_PWD_NON_PROD="bXVsZXNvZnQtdXNlcjpGamlzT3MyOSVhVw=="
ELK_SAAS_URL_NON_PROD="https://digital-core2-process-elk.apps.gnp.aws.optus.com.au/mule-logs/_doc"
ELK_SAAS_PWD_NON_PROD="bXVsZXNvZnQtdXNlcjpGamlzT3MyOSVhVw=="

ELK_SYS_URL_PROD="https://digital-core2-system-api.apps.aws.optus.com.au/mule-logs/_doc"
ELK_SYS_PWD_PROD="bXVsZXNvZnQtdXNlcjpSVmNlV1gyNCUj"

ELK_SAAS_URL_PROD="https://digital-core2-process-api.apps.aws.optus.com.au/mule-logs/_doc"
ELK_SAAS_PWD_PROD="bXVsZXNvZnQtdXNlcjpSVmNlV1gyNCUj"
#EK variables - END



if [[ "${SCRIPT_ENVIRONMENT}" == "LHS" ]]; then
        echo "##################################STEP1==================================="
        MULE_PROXY_HOST="proxy.apps.springdigital-devisland.com.au"
    		MULE_PROXY_HOST_PORT="3128"
    		x=`grep -zoP "Host github.com\n\tStrictHostKeyChecking no\n" ~/.ssh/config | wc -l`
    		echo $x
    		if [[ $x == 0 ]]; then
      			echo "Adding github.com configuration into ssh profile"
      			echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
      			echo -e "Host github.com\n\tProxyCommand nc -X connect -x ${MULE_PROXY_HOST}:${MULE_PROXY_HOST_PORT} %h %p\n\tServerAliveInterval 30\n" >> ~/.ssh/config
    		else
    			echo "ssh configuration already exists for github.com"
    		fi
		    git config --global --unset http.proxy
        git config --global http.proxy ${MULE_PROXY_HOST}:${MULE_PROXY_HOST_PORT}
		    git clone https://${bamboo_core2_github_username}:${bamboo_core2_github_password}@github.com/OptusCore2/${GITHUB_REPO}.git ${GITHUB_REPO}
    		if [[ "${VERSION}" != *"SNAPSHOT"* ]]; then
    			codeToCheckoutFrom=${ReleasePrefixOrTagName}
    		fi
    		NEXUS_RELEASE_REPO_ID="nexus-snapshots"
    		NEXUS_SNAPSHOT_REPO_ID="nexus-snapshots"
    		NEXUS_RELEASE_URL="https://${NEXUS_DOMAIN}/nexus/content/repositories/releases/"
    		NEXUS_SNAPSHOT_URL="https://${NEXUS_DOMAIN}/nexus/content/repositories/snapshots/"
        printenv
else
        echo "##################################STEP1##################################"
        echo "==============================Checkout repo from stash repo==========================="
  	    echo " RHS - Checkout from stash starting..... "
        git clone ${STASH_REPO}/dc/${GITHUB_REPO}.git ${GITHUB_REPO}
    		if [[ "${VERSION}" != *"SNAPSHOT"* ]]; then
    			codeToCheckoutFrom=${ReleasePrefixOrTagName}
    		fi
    		NEXUS_RELEASE_REPO_ID="server-id-internal-repo-libs-releases"
    		NEXUS_SNAPSHOT_REPO_ID="server-id-internal-repo-libs-snapshots"
    		NEXUS_RELEASE_URL="https://${NEXUS_DOMAIN}/repository/maven-releases/"
    		NEXUS_SNAPSHOT_URL="https://${NEXUS_DOMAIN}/repository/maven-snapshots/"
fi

cd ${GITHUB_REPO}
git checkout ${codeToCheckoutFrom}

if [ $? -ne 0 ]; then
	   echo "HElP ME !! Check Out has PROBLEM with Tag ${codeToCheckoutFrom}!!! Repo ${GITHUB_REPO}"
     exit 1
fi

echo "manual checkout done."
echo "$(git config --list --global)"
echo "whats in the pom.xml"
cat pom.xml


echo "###COMPOSING ENVIRONMENTS AND CLIENT_ID/SECRET### === START"
case ${ENVIRONMENT} in

    dev-sys)
    echo 'Starting deploying to DEV-SYS ...'
    ENVIRONMENT="dev-sys"
    MULE_ENV="dev"
    ELK_URL=${ELK_SYS_URL_NON_PROD}
    ELK_PWD=${ELK_SYS_PWD_NON_PROD}
    ;;

    dev-saas-proc)
    echo 'Starting deploying to dev-saas-proc ...'
    ENVIRONMENT="dev-saas-proc"
    MULE_ENV="dev"
    ELK_URL=${ELK_SAAS_URL_NON_PROD}
    ELK_PWD=${ELK_SAAS_PWD_NON_PROD}
    ;;

    sit-sys)
    echo 'Starting deploying to SIT-SYS ...'
    ENVIRONMENT="sit-sys"
    MULE_ENV="sit"
    ELK_URL=${ELK_SYS_URL_NON_PROD}
    ELK_PWD=${ELK_SYS_PWD_NON_PROD}
    ;;

    sit-saas-proc)
    echo 'Starting deploying to sit-saas-proc ...'
    ENVIRONMENT="sit-saas-proc"
    MULE_ENV="sit"
    ELK_URL=${ELK_SAAS_URL_NON_PROD}
    ELK_PWD=${ELK_SAAS_PWD_NON_PROD}
    ;;

    uat1-sys)
    echo 'Starting deploying to uat1-sys ...'
    ENVIRONMENT="uat1-sys"
    MULE_ENV="uat1"
    ELK_URL=${ELK_SYS_URL_NON_PROD}
    ELK_PWD=${ELK_SYS_PWD_NON_PROD}
    ;;

    uat1-saas-proc)
    echo 'Starting deploying to uat1-saas-proc ...'
    ENVIRONMENT="uat1-saas-proc"
    MULE_ENV="uat1"
    ELK_URL=${ELK_SAAS_URL_NON_PROD}
    ELK_PWD=${ELK_SAAS_PWD_NON_PROD}
    ;;

    uat2-sys)
    echo 'Starting deploying to uat2-sys ...'
    ENVIRONMENT="uat2-sys"
    MULE_ENV="uat2"
    ELK_URL=${ELK_SYS_URL_NON_PROD}
    ELK_PWD=${ELK_SYS_PWD_NON_PROD}
    ;;

    uat2-saas-proc)
    echo 'Starting deploying to uat2-saas-proc ...'
    ENVIRONMENT="uat2-saas-proc"
    MULE_ENV="uat2"
    ELK_URL=${ELK_SAAS_URL_NON_PROD}
    ELK_PWD=${ELK_SAAS_PWD_NON_PROD}
    ;;

    sit2-sys)
    echo 'Starting deploying to sit2-sys ...'
    ENVIRONMENT="sit2-sys"
    MULE_ENV="sit2"
    ELK_URL=${ELK_SYS_URL_NON_PROD}
    ELK_PWD=${ELK_SYS_PWD_NON_PROD}
    ;;

    sit2-saas-proc)
    echo 'Starting deploying to sit2-saas-proc ...'
    ENVIRONMENT="sit2-saas-proc"
    MULE_ENV="sit2"
    ELK_URL=${ELK_SAAS_URL_NON_PROD}
    ELK_PWD=${ELK_SAAS_PWD_NON_PROD}
    ;;

    uat3-sys)
    echo 'Starting deploying to uat3-sys ...'
    ENVIRONMENT="uat3-sys"
    MULE_ENV="uat3"
    ELK_URL=${ELK_SYS_URL_NON_PROD}
    ELK_PWD=${ELK_SYS_PWD_NON_PROD}
    ;;

    uat3-saas-proc)
    echo 'Starting deploying to uat3-saas-proc ...'
    ENVIRONMENT="uat3-saas-proc"
    MULE_ENV="uat3"
    ELK_URL=${ELK_SAAS_URL_NON_PROD}
    ELK_PWD=${ELK_SAAS_PWD_NON_PROD}
    ;;

    uat4-sys)
    echo 'Starting deploying to uat4-sys ...'
    ENVIRONMENT="uat4-sys"
    MULE_ENV="uat4"
    ELK_URL=${ELK_SYS_URL_NON_PROD}
    ELK_PWD=${ELK_SYS_PWD_NON_PROD}
    ;;

    uat4-saas-proc)
    echo 'Starting deploying to uat4-saas-proc ...'
    ENVIRONMENT="uat4-saas-proc"
    MULE_ENV="uat4"
    ELK_URL=${ELK_SAAS_URL_NON_PROD}
    ELK_PWD=${ELK_SAAS_PWD_NON_PROD}
    ;;

    ppt-sys)
    echo 'Starting deploying to ppt-sys ...'
    ENVIRONMENT="ppt-sys"
    MULE_ENV="ppt"
    ELK_URL=${ELK_SYS_URL_NON_PROD}
    ELK_PWD=${ELK_SYS_PWD_NON_PROD}
    ;;

    ppt-saas-proc)
    echo 'Starting deploying to ppt-saas-proc ...'
    ENVIRONMENT="ppt-saas-proc"
    MULE_ENV="ppt"
    ELK_URL=${ELK_SAAS_URL_NON_PROD}
    ELK_PWD=${ELK_SAAS_PWD_NON_PROD}
    ;;

    prod-sys)
    echo 'Starting deploying to prod-sys ...'
    ENVIRONMENT="prod-sys"
    MULE_ENV="prod"
    ELK_URL=${ELK_SYS_URL_PROD}
    ELK_PWD=${ELK_SYS_PWD_PROD}
    ;;

    prod-saas-proc)
    echo 'Starting deploying to prod-saas-proc ...'
    ENVIRONMENT="prod-saas-proc"
    MULE_ENV="prod"
    ELK_URL=${ELK_SAAS_URL_PROD}
    ELK_PWD=${ELK_SAAS_PWD_PROD}
    ;;
	
    *)
    echo 'Invalid env....${ENVIRONMENT}'
    exit 1
    ;;

esac
echo "CLIENT ID = ${ANYPOINT_CLIENT_ID}"
echo "CLIENT SECRET = ${ANYPOINT_CLIENT_SECRET}"
echo "###COMPOSING ENVIRONMENTS AND CLIENT_ID/SECRET### === END"


echo "##################################STEP2##################################"
echo "==============================DOWNLOAD FROM NEXUS STARTED==========================="
echo "mvn dependency:copy -U -Dartifact=${GROUP_ID}:${GITHUB_REPO}:${VERSION}:jar:${PACKAGING} \
        -DdistributionManagement.releaseRepository.repoId=${NEXUS_RELEASE_REPO_ID} \
        -DdistributionManagement.snapshotRepository.repoId=${NEXUS_SNAPSHOT_REPO_ID} \
        -DdistributionManagement.repository.releaseURL=${NEXUS_RELEASE_URL} \
        -DdistributionManagement.repository.snapshotURL=${NEXUS_SNAPSHOT_URL} -DoutputDirectory=."

mvn dependency:copy -U -Dartifact=${GROUP_ID}:${GITHUB_REPO}:${VERSION}:jar:${PACKAGING} \
        -DdistributionManagement.releaseRepository.repoId=${NEXUS_RELEASE_REPO_ID} \
        -DdistributionManagement.snapshotRepository.repoId=${NEXUS_SNAPSHOT_REPO_ID} \
        -DdistributionManagement.repository.releaseURL=${NEXUS_RELEASE_URL} \
        -DdistributionManagement.repository.snapshotURL=${NEXUS_SNAPSHOT_URL} -DoutputDirectory=.
if [[ "$?" -ne 0 ]] ; then
    echo 'Error with download package from Nexus!!!'
    exit 1
fi
echo "==============================DOWNLOAD FROM NEXUS COMPLETED==========================="
echo "WHAT IS IN THE BEFORE RENAMING FOLDER"
ls -1

echo "==============================RENAMING THE JAR====================================="
JARFILE=$(ls -1 *.jar|tail -1)
echo "jar file nameee JARFILE"
echo $JARFILE
echo "jar file nameee end"

echo "WHAT IS IN THE FOLDER AFTER RENAMING"
ls -1

echo "==============================RENAMING THE JAR COMPLETED==========================="


echo "##################################STEP3##################################"
echo 'started deploying to cloudhub'

echo "==============================DEPLOY TO CLOUDHUB STARTED==========================="
echo "mvn --batch-mode mule:deploy -Dusername=${MULE_USERNAME} \
        -Dpassword=${MULE_PASSWORD} \
        -Denvironment=${ENVIRONMENT} \
        -Dmule.env=${MULE_ENV} \
        -Dhttps.proxyHost=${MULE_PROXY_HOST} \
        -Dhttps.proxyPort=${MULE_PROXY_HOST_PORT} \
        -Dmule.key=${MULE_KEY} \
        -Danypoint.platform.client_id=${ANYPOINT_CLIENT_ID} \
        -Danypoint.platform.client_secret=${ANYPOINT_CLIENT_SECRET} \
        -Dworkers=${WORKER_NUMBER} \
        -DworkerType=${WORKER_TYPE} \
        -DskipMunitTests=true \
        -Dcloudhub.application.name=${CLOUDHUB_APP_NAME} \
        -Dmule.artifact=${JARFILE} \
        -Delk.url=${ELK_URL} \
        -Delk.pwd=${ELK_PWD} \
        -Dlog4j2.AsyncQueueFullPolicy=Discard \
        ${ADDITIONAL_PARAMS}"

mvn --batch-mode mule:deploy -Dusername=${MULE_USERNAME} \
        -Dpassword=${MULE_PASSWORD} \
        -Denvironment=${ENVIRONMENT} \
        -Dmule.env=${MULE_ENV} \
        -Dhttps.proxyHost=${MULE_PROXY_HOST} \
        -Dhttps.proxyPort=${MULE_PROXY_HOST_PORT} \
        -Dmule.key=${MULE_KEY} \
        -Danypoint.platform.client_id=${ANYPOINT_CLIENT_ID} \
        -Danypoint.platform.client_secret=${ANYPOINT_CLIENT_SECRET} \
        -Dworkers=${WORKER_NUMBER} \
        -DworkerType=${WORKER_TYPE} \
        -DskipMunitTests=true \
        -Dcloudhub.application.name=${CLOUDHUB_APP_NAME} \
        -Dmule.artifact=${JARFILE} \
        -Delk.url=${ELK_URL} \
        -Delk.pwd=${ELK_PWD} \
        -Dlog4j2.AsyncQueueFullPolicy=Discard \
        ${ADDITIONAL_PARAMS}

#Need to fix the artifactId to match.
if [[ "$?" -ne 0 ]] ; then
    echo 'Error with deploy package into Cloudhub !!!'
    exit 1
fi
echo "==============================DEPLOY TO CLOUDHUB COMPLETE==========================="
