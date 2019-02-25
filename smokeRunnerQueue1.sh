#!/bin/bash

# revisino;TPfile;testPlanName
revisionsTP=(
"sha1;testPlanName;name"
)

ELASTIC_URI="http://tea.comm.equabank.loc"
ELASTIC_PORT=9200
ELASTIC_INDEX="performance-tests"
ELASTIC_INDEX_DATE=$(date +"%Y-%m-%d")

SLACK_CHANNEL="#perf-smoke-status"
PATH_TO_SMARTMETER="/opt/smartmeter/SmartMeter_1.6.0_linux/"
PATH_TO_PERF_REPO="/opt/smartmeter/smoke/"

( curl -s POST --data-urlencode 'payload={"channel": "'${SLACK_CHANNEL}'", "username": "Skript: smokeRunner.sh", "text": ">>> Start smokeRunnerQueue1"}' https://hooks.slack.com/services/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 )

for i in "${revisionsTP[@]}"
do
	SECONDS=0
	START_HOUR=$(date -d '-2 hour' +"%H")
	START_MIN=$(date +"%M")
	START_SEC=$(date +"%S")

	IFS=';' read -a item <<< $i
	echo "rev: ${item[0]}, tp: ${item[1]}, testPlanName: ${item[2]}"

	( sed -i -r -f smoke.sed ${item[1]} )

	( curl -s POST --data-urlencode 'payload={"channel": "'${SLACK_CHANNEL}'", "username": "Skript: smokeRunner.sh", "text": "Smoke `'${item[1]}'`, rev.: `'${item[0]}'`, testPlanName: `'${item[2]}'` prave startuje..."}' https://hooks.slack.com/services/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 )
	( exec ${PATH_TO_SMARTMETER}/SmartMeter.sh runTestNonGui ${PATH_TO_PERF_REPO}${item[1]} )

	duration=$SECONDS

	# get data from elasticsearch
	COUNT_TRANSACTIONS=$(curl -s ${ELASTIC_URI}:${ELASTIC_PORT}/${ELASTIC_INDEX}-${ELASTIC_INDEX_DATE}"/_count?filter_path=count" -d'
	{
	  "query": {
	    "bool": {
	      "must": [
	        {
	          "term": {
	            "testPlanName": {
	              "value": "'${item[2]}'"
	            }
	          }
	        },
	        {
	          "range": {
	            "timestamp" : {
	              "gte": "now-'$(($duration / 60))'m-'$(($duration % 60))'s",
	              "lte": "now"
	            }
	          }
	        }
	      ]
	    }
	  }
	}' | sed 's/{"count"://g' | sed 's/}//g')


	COUNT_OF_ERRORS=$(curl -s ${ELASTIC_URI}:${ELASTIC_PORT}/${ELASTIC_INDEX}-${ELASTIC_INDEX_DATE}"/_count?filter_path=count" -d'
	{
  "query": {
    "bool": {
      "must": [
				{
					"term": {
						"testPlanName": {
							"value": "'${item[2]}'"
						}
					}
				},
        {
          "term": {
            "Success": false
          }
        },
        {
          "range": {
            "timestamp" : {
              "gte": "now-'$(($duration / 60))'m-'$(($duration % 60))'s",
              "lte": "now"
            }
          }
        }
      ]
    }
  }
	}' | sed 's/{"count"://g' | sed 's/}//g')

	if [ $COUNT_OF_ERRORS == 0 ] ; then
		COLOR="good"
	else
		COLOR="danger"
	fi

	KIBANA_DASHBOARD="http://kube-minion3.dev1.equabank.loc:31159/app/kibana#/dashboard/Performance-tests-analysis-summary?_g=(refreshInterval%3A(display%3AOff%2Cpause%3A!f%2Cvalue%3A0)%2Ctime%3A(from%3A'${ELASTIC_INDEX_DATE}T${START_HOUR}%3A${START_MIN}%3A${START_SEC}.000Z'%2Cmode%3Aabsolute%2Cto%3A'${ELASTIC_INDEX_DATE}T$(date -d '-2 hour' +"%H")%3A$(date +"%M")%3A$(date +"%S").000Z'))"

	( curl -s POST --data-urlencode "payload={\"channel\": \"${SLACK_CHANNEL}\", \"username\": \"Skript: smokeRunner.sh\", \"text\": \"Smoke \`${item[1]}\` skoncil\",
	    \"attachments\": [
					{
							\"title\":\"Otevrit detail v dashboardu\",
							\"title_link\": \"${KIBANA_DASHBOARD}\"
					},
	        {
	            \"fields\": [
	                {
	                    \"title\": \"Transactions\",
	                    \"value\": \"${COUNT_TRANSACTIONS}\",
	                    \"short\": true
	                },
	                {
	                    \"title\": \"Errors\",
	                    \"value\": \"${COUNT_OF_ERRORS}\",
	                    \"short\": true
	                },
									{
	                    \"title\": \"Duration\",
	                    \"value\": \"$(($duration / 60))min. a $(($duration % 60))sec\",
	                    \"short\": true
	                }
	            ],
	            \"color\": \"${COLOR}\",
							\"footer\": \"More info: Confluence > Zatezove testy > Performance tests: Infrastructure\"
	        }
	    ]
	}" https://hooks.slack.com/services/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 )

	sleep 10
done
exit 0
