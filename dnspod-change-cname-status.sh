#!/bin/bash

DOMAIN=$1
API_TOKEN="$DNSPOD_API_TOKEN"
PARAMS="login_token=$API_TOKEN&format=json"

if [ -z "$DOMAIN" ]; then
echo "\
Exit:        Miss Domain"
    exit
fi

if [ -z "$API_TOKEN" ]; then
echo "\
Exit:        Miss dnspod api token"
    exit
fi

CNAME_RECORDS=$(curl -s -X POST "https://dnsapi.cn/Record.List" \
    -d "$PARAMS&domain=$DOMAIN&keyword=@" \
| python -c "import sys,json;ret=json.load(sys.stdin);records=ret.get('records',{});cname_array=[];
for idx,val in enumerate(records):
  if records[idx].get('enabled')=='1':cname_array.append(records[idx].get('id'))
print(','.join(cname_array))")

echo "\
DOMAIN:         $DOMAIN
CNAME_RECORDS:  $CNAME_RECORDS"

if [ -n "$CNAME_RECORDS" ]; then
    for i in ${CNAME_RECORDS//,/ }; do
        CNAME_RECORD_ID=$i
        CNAME_RECORD_ID=$(curl -s -X POST "https://dnsapi.cn/Record.Status" \
            -d "$PARAMS&domain=$DOMAIN&record_id=$CNAME_RECORD_ID&status=disable" \
        | python -c "import sys,json;ret=json.load(sys.stdin);print(ret.get('record',{}).get('id',ret.get('status',{}).get('message','error')))")
echo "\
Disable CNAME record id:        $CNAME_RECORD_ID"
    done
fi

sleep 300

if [ -n "$CNAME_RECORDS" ]; then
    for i in ${CNAME_RECORDS//,/ }; do
        CNAME_RECORD_ID=$i
        CNAME_RECORD_ID=$(curl -s -X POST "https://dnsapi.cn/Record.Status" \
            -d "$PARAMS&domain=$DOMAIN&record_id=$CNAME_RECORD_ID&status=enable" \
        | python -c "import sys,json;ret=json.load(sys.stdin);print(ret.get('record',{}).get('id',ret.get('status',{}).get('message','error')))")
echo "\
Enable CNAME record id:        $CNAME_RECORD_ID"
    done
fi

echo "\
Change CNAME status finished"