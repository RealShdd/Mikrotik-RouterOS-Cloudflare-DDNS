#!/bin/bash
# This bash script can help you get the record id

# Cloudflare credentials
ZONE_ID="REPLACE_WITH_YOUR_ZONE_ID"
EMAIL="YOUR_CLOUDFLARE_EMAIL"
API_KEY="API_KEY"

# record you wanna look for
RECORD_NAME="XXX.example.com"



# Get DNS record
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
     -H "X-Auth-Email: $EMAIL" \
     -H "X-Auth-Key: $API_KEY" \
     -H "Content-Type: application/json")

# Parse the response to get the record ID
RECORD_ID=$(echo $RESPONSE | jq -r '.result[0].id')

echo $RECORD_ID
