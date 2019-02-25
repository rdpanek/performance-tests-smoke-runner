#!/bin/bash

# revisino;pathToTPfile;testPlanName
revisionsTP=(
"c491e6b;testPlan.jmx;testPlan"
)

ELASTIC_URI="http://192.168.1.237"
ELASTIC_PORT=9200
ELASTIC_INDEX="performance-tests"
ELASTIC_INDEX_DATE=$(date +"%Y-%m-%d")

SLACK_CHANNEL="#perf-smoke-status"
SLACK_WEBHOOK="https://hooks.slack.com/services/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"
PATH_TO_SMARTMETER="/Users/rdpanek/HTDOCS/test-tools/SmartMeter_1.8.2_macos"
PATH_TO_PERF_REPO="/Users/rdpanek/HTDOCS/test-stack/performance-tests"
PATH_TO_GIT_REPOSITORY="https://github.com/rdpanek/performance-tests.git"

( curl -s POST --data-urlencode 'payload={"channel": "'${SLACK_CHANNEL}'", "username": "Skript: smokeRunnerQueue.sh", "text": ">>> Start smokeRunnerQueue1"}' $SLACK_WEBHOOK )

#rm -rf $PATH_TO_PERF_REPO && git clone $PATH_TO_GIT_REPOSITORY $PATH_TO_PERF_REPO

for testInstruction in "${revisionsTP[@]}"
do
	SECONDS=0
	START_HOUR=$(date +"%H")
	START_MIN=$(date +"%M")
	START_SEC=$(date +"%S")

	#IFS=';' read -ra instructionItem <<< $testInstruction
	while IFS=';' read -ra instructionItem; do
		echo "rev: ${instructionItem[0]}, tp: ${instructionItem[1]}, testPlanName: ${instructionItem[2]}"

		# select version of test by revision
		( cd ${PATH_TO_PERF_REPO} && git reset --hard HEAD && git checkout ${instructionItem[0]} )

		# minifi values
		echo ${PATH_TO_PERF_REPO}/${instructionItem[1]}
		( sed -i -r -f smoke.sed ${PATH_TO_PERF_REPO}/${instructionItem[1]} )

		# notifi
		( curl -s POST --data-urlencode 'payload={"channel": "'${SLACK_CHANNEL}'", "username": "Skript: smokeRunner.sh", "text": "Smoke `'${instructionItem[1]}'`, rev.: `'${instructionItem[0]}'`, testPlanName: `'${instructionItem[2]}'` prave startuje..."}' $SLACK_WEBHOOK )

		# test execution
		( exec ${PATH_TO_SMARTMETER}/SmartMeter.sh runTestNonGui ${PATH_TO_PERF_REPO}/${instructionItem[1]} )
	sleep 5
	done <<< "$testInstruction"

	sleep 0
done
exit 0
