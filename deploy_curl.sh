#!/bin/bash

APIGEE_APIURL=https://apigee.googleapis.com
PROXY_NAME=${PROXY_NAME}
APIGEE_ORG=${APIGEE_ORG}
APIGEE_ENV=${APIGEE_ENV}
APIGEE_BASEURL="${APIGEE_APIURL}/v1/organizations/${APIGEE_ORG}"
echo $APIGEE_BASEURL

TOKEN=${GCLOUD_TOKEN}
echo $TOKEN

# Create/Update the proxy and get the revision
PROXY_REV=$(curl -X POST "${APIGEE_BASEURL}/apis?name=${PROXY_NAME}&action=import" \
    -H "Content-Type: multipart/form-data" \
    -H "Authorization: Bearer ${TOKEN}" \
    -F "file=@./${PROXY_NAME}/apiproxy.zip" | jq ".revision | tonumber")

if [[ $PROXY_REV = "" ]]
then
    echo Exists and error with you proxy bundle.
    exit 0
fi

echo "New revision: ${PROXY_REV}"
# Deploy new revision
curl -X POST "${APIGEE_BASEURL}/environments/${APIGEE_ENV}/apis/${PROXY_NAME}/revisions/${PROXY_REV}/deployments?override=true" \
    -H "Authorization: Bearer ${TOKEN}"

# Check if status was ready, for deployment complete
STATUS=""
echo -n "Deploying..."
while [[ $STATUS != "READY" ]]
do
    sleep 15
    STATUS=$(curl -s "${APIGEE_BASEURL}/environments/${APIGEE_ENV}/apis/${PROXY_NAME}/revisions/${PROXY_REV}/deployments" \
        -X GET \
        -H "Authorization: Bearer ${TOKEN}" | jq -r ".state")
    echo $STATUS
    echo -n "..."
done
echo "The revision ${PROXY_REV} was deployed"