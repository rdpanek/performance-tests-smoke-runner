#!/bin/bash

# Delete all documents with flag: smoke from smartmeterv2-* index
# by Query API https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html

ELASTIC_URI="http://elasticClusterUri"
ELASTIC_PORT=9200
ELASTIC_INDEX="performance-tests"
ELASTIC_INDEX_DATE=${ELASTIC_INDEX}-$(date --date="14 days ago" +"%Y-%m-%d")

SLACK_CHANNEL="#elasticsearch"

# Get info about index
INDEX_INFO=$( curl -s ${ELASTIC_URI}:${ELASTIC_PORT}"/_cat/indices/${ELASTIC_INDEX_DATE}?v" )

# get count of documents with flag smoke
BEFORE_COUNT_SMOKE_DOCUMENTS=$(curl -s ${ELASTIC_URI}:${ELASTIC_PORT}/${ELASTIC_INDEX_DATE}"/_count?filter_path=count" -d'
{
  "query": {
    "bool": {
      "must": [
        {
          "term": {
            "flag": "smoke"
          }
        }
      ]
    }
  }
}' | sed 's/{"count"://g' | sed 's/}//g')

# get count of documents with flag regression
BEFORE_COUNT_REGRESSION_DOCUMENTS=$(curl -s ${ELASTIC_URI}:${ELASTIC_PORT}/${ELASTIC_INDEX_DATE}"/_count?filter_path=count" -d'
{
  "query": {
    "bool": {
      "must": [
        {
          "term": {
            "flag": "regression"
          }
        }
      ]
    }
  }
}' | sed 's/{"count"://g' | sed 's/}//g')

# Deleting documents only flags these as deleted, so they would not be searched
DELETE_DOCUMENTS=$(curl -s -XPOST ${ELASTIC_URI}:${ELASTIC_PORT}/${ELASTIC_INDEX_DATE}"/_delete_by_query" -d'
{
  "query": {
    "bool": {
      "must": [
        {
          "term": {
            "flag": "smoke"
          }
        }
      ]
    }
  }
}' | sed 's/\"//g' | sed 's/{//g' | sed 's/}//g')

# get count of documents with flag smoke
AFTER_COUNT_SMOKE_DOCUMENTS=$(curl -s ${ELASTIC_URI}:${ELASTIC_PORT}/${ELASTIC_INDEX_DATE}"/_count?filter_path=count" -d'
{
  "query": {
    "bool": {
      "must": [
        {
          "term": {
            "flag": "smoke"
          }
        }
      ]
    }
  }
}' | sed 's/{"count"://g' | sed 's/}//g')

# get count of documents with flag regression
AFTER_COUNT_REGRESSION_DOCUMENTS=$(curl -s ${ELASTIC_URI}:${ELASTIC_PORT}/${ELASTIC_INDEX_DATE}"/_count?filter_path=count" -d'
{
  "query": {
    "bool": {
      "must": [
        {
          "term": {
            "flag": "regression"
          }
        }
      ]
    }
  }
}' | sed 's/{"count"://g' | sed 's/}//g')


# Should the merge process only expunge segments with deletes in it. In Lucene,
# a document is not deleted from a segment, just marked as deleted.
# During a merge process of segments, a new segment is created that does not have
# those deletes. This flag allows to only merge segments that have deletes.
# Defaults to false. Note that this won’t override the
MERGE_PROCESS=$(curl -s -XPOST ${ELASTIC_URI}:${ELASTIC_PORT}"/_forcemerge?only_expunge_deletes=true" | sed 's/\"//g' | sed 's/{//g' | sed 's/}//g')


( curl -s POST --data-urlencode "payload={\"channel\": \"${SLACK_CHANNEL}\", \"username\": \"Skript: smokeCleaner.sh\", \"text\": \"Clean old documents from Elasticsearch index *${ELASTIC_INDEX_DATE}* contains perf-smoke-test results\n*Index - before cleaning*\n\`\`\`${INDEX_INFO}\`\`\`\",
    \"attachments\": [
        {
            \"text\": \"Count of documents before cleaning:\",
            \"fields\": [
                {
                    \"title\": \"flag: smoke\",
                    \"value\": \"${BEFORE_COUNT_SMOKE_DOCUMENTS}\",
                    \"short\": true
                },
                {
                    \"title\": \"flag: regression\",
                    \"value\": \"${BEFORE_COUNT_REGRESSION_DOCUMENTS}\",
                    \"short\": true
                }
            ],
            \"color\": \"good\"
        },
        {
            \"title\":\"Mark a documents for deletion - response\",
            \"text\": \"${DELETE_DOCUMENTS}\",
        },
        {
            \"title\":\"Merge process - response\",
            \"text\": \"${MERGE_PROCESS}\",
        },
        {
            \"text\": \"Count of documents after cleaning:\",
            \"fields\": [
                {
                    \"title\": \"flag: smoke\",
                    \"value\": \"${AFTER_COUNT_SMOKE_DOCUMENTS}\",
                    \"short\": true
                },
                {
                    \"title\": \"flag: regression\",
                    \"value\": \"${AFTER_COUNT_REGRESSION_DOCUMENTS}\",
                    \"short\": true
                }
            ],
            \"color\": \"good\"
        }
    ]
}" https://hooks.slack.com/services/xxx )

# Get info about index
INDEX_INFO=$( curl -s ${ELASTIC_URI}:${ELASTIC_PORT}"/_cat/indices/${ELASTIC_INDEX_DATE}?v" )

( curl -s POST --data-urlencode "payload={\"channel\": \"${SLACK_CHANNEL}\", \"username\": \"Skript: smokeCleaner.sh\", \"text\": \"*Index - after cleaning*\n\`\`\`${INDEX_INFO}\`\`\`\"}" https://hooks.slack.com/services/xxx )

# Delete index if smoke and regressing is 0
if [ $AFTER_COUNT_SMOKE_DOCUMENTS == $AFTER_COUNT_REGRESSION_DOCUMENTS ] ; then
  DELETE_INDEX=$( curl -s -X DELETE ${ELASTIC_URI}:${ELASTIC_PORT}"/${ELASTIC_INDEX_DATE}" | sed 's/\"//g' | sed 's/{//g' | sed 's/}//g')

  ( curl -s POST --data-urlencode "payload={\"channel\": \"${SLACK_CHANNEL}\", \"username\": \"Skript: smokeCleaner.sh\", \"text\": \"*Delete index*\n\`\`\`${DELETE_INDEX}\`\`\`\"}" https://hooks.slack.com/services/xxx )
fi
