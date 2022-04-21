#!/bin/bash
#set -x
#source /etc/profile

MULE_PROXY_HOST="${1}"
MULE_PROXY_HOST_PORT="${2}"
GITHUB_REPO="${3}"
VERSION="${4}"
GIT_BRANCH="${5}"
ReleasePrefixOrTagName="${6}"

#rm -rf **
echo "##################################TAGGING==================================="
echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
echo -e "Host github.com\n\tProxyCommand nc -X connect -x proxy.apps.springdigital-devisland.com.au:3128 %h %p\n\tServerAliveInterval 30\n" >> ~/.ssh/config

git config --global --unset http.proxy
printenv

echo "manual checkout starting..."

git config --global http.proxy ${MULE_PROXY_HOST}:${MULE_PROXY_HOST_PORT}

git clone https://${bamboo_core2_github_username}:${bamboo_core2_github_password}@github.com/OptusCore2/${GITHUB_REPO}.git ${GITHUB_REPO}
cd ${GITHUB_REPO}
git checkout ${GIT_BRANCH}
git pull 
if [[ "${VERSION}" != *"SNAPSHOT"* ]]; then
tagname=${ReleasePrefixOrTagName}_${VERSION}
echo "$tagname"
git tag -a ${tagname} -m "created tag from ${GIT_BRANCH} branch"
git push --tags
echo "tagname=$tagname"
else
echo "NO TAG CREATED"
fi
cd ..

echo "manual checkout done."
