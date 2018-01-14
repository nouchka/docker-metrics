#!/bin/bash

if [[ -z "$GITHUB_TOKEN" ]]; then
	echo "Set the GITHUB_TOKEN env variable."
	exit 1
fi
if [[ -z "$HUB_USER" ]]; then
	echo "Set the HUB_USER env variable."
	exit 1
fi

URI=https://api.github.com
API_VERSION=v3
API_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

GITHUB_STARS=0
DOCKERHUB_STARS=0
DOCKERHUB_PULLS=0

get_repos() {
	local url=${URI}/users/$HUB_USER/repos?page=$1
	local resp=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${url}")
	local stars=$(echo $resp | jq -e --raw-output 'reduce .[].stargazers_count as $item (0; . + $item)')
	GITHUB_STARS=$(expr $stars + $GITHUB_STARS)
}

github_info() {
	local resp=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/users/$HUB_USER")
	local followers=$(echo $resp | jq -e --raw-output '.followers')
	echo -e "\e[36mGithub followers:\e[39m ${followers}"
	local repos=$(echo $resp | jq -e --raw-output '.public_repos')
	local iterate=$(expr $repos / 30 + 1)
	for (( i=1; i<=$iterate; i++ ))
	do
		get_repos $i
	done
	echo -e "\e[36mGithub stars:\e[39m ${GITHUB_STARS}"
}

dockerhub_info() {
	if [ "$1" ]; then
		PAGE=$1
	else
		PAGE=1
	fi
	local url=https://hub.docker.com/v2/repositories/$HUB_USER/?page=$PAGE
	local resp=$(curl -sSL $url)
	local stars=$(echo $resp | jq -e --raw-output 'reduce  .results [] .star_count as $item (0; . + $item)')
	local pulls=$(echo $resp | jq -e --raw-output 'reduce  .results [] .pull_count as $item (0; . + $item)')
	local next=$(echo $resp | jq -e --raw-output '.next')
	DOCKERHUB_STARS=$(expr $stars + $DOCKERHUB_STARS)
	DOCKERHUB_PULLS=$(expr $pulls + $DOCKERHUB_PULLS)
	if [[ "$next" == "null" ]] || [[ "$next" == "" ]]; then
		echo -e "\e[36mDockerhub stars:\e[39m ${DOCKERHUB_STARS}"
		echo -e "\e[36mDockerhub pulls:\e[39m ${DOCKERHUB_PULLS}"
	else
		dockerhub_info $(expr $PAGE + 1)
	fi
}

github_info
dockerhub_info
