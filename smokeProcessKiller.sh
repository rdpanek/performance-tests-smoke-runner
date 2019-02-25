#!/bin/bash

pkill -f smokeRunner
pkill -f smartmeter

SLACK_CHANNEL="#perf-smoke-status"

( curl -s POST --data-urlencode 'payload={"channel": "'${SLACK_CHANNEL}'", "username": "Skript: smokeProcessCleaner.sh", "text": "-- All processes smokeRunnerQueueX.sh was killed --"}' https://hooks.slack.com/services/xxx )
