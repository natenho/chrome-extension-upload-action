#!/bin/sh

set -e

refresh_token=$1
client_id=$2
file_name=$3
app_id=$4
should_publish=$5

token=`curl \
--silent \
--fail \
--location --request POST 'https://oauth2.googleapis.com/token' \
--form client_id="$client_id" \
--form grant_type="refresh_token" \
--form redirect_uri="urn:ietf:wg:oauth:2.0:oob" \
--form refresh_token="$refresh_token" \
| \
jq -r '.access_token'`

response=`curl \
--silent \
--show-error \
--fail \
-H "Authorization: Bearer $token" \
-H "x-goog-api-version: 2" \
-X PUT \
-T $file_name \
-v https://www.googleapis.com/upload/chromewebstore/v1.1/items/$app_id`

upload_state=`echo $response | jq -r '.uploadState'`

if [ "$upload_state" = "FAILURE" ]; then
  echo $response
  exit 1
fi

if [ "$should_publish" = "true" ]; then
  response=`curl \
  --silent \
  --show-error \
  --fail \
  -H "Authorization: Bearer $token" \
  -H "x-goog-api-version: 2" \
  -X POST \
  -v https://www.googleapis.com/chromewebstore/v1.1/items/$app_id/publish \
  -d publishTarget=default`

  publish_state=`echo $response | jq -r '.uploadState'`

  if [ "$publish_state" = "FAILURE" ]; then
    echo $response
    exit 1
  fi
fi

exit 0