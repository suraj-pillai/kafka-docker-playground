#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

${DIR}/../../environment/plaintext/start.sh "${PWD}/docker-compose.plaintext.yml"

mkdir -p ${DIR}/upload/input
mkdir -p ${DIR}/upload/error
mkdir -p ${DIR}/upload/finished

echo $'{"id":1,"first_name":"Roscoe","last_name":"Brentnall","email":"rbrentnall0@mediafire.com","gender":"Male","ip_address":"202.84.142.254","last_login":"2018-02-12T06:26:23Z","account_balance":1450.68,"country":"CZ","favorite_color":"#4eaefa"}\n{"id":2,"first_name":"Gregoire","last_name":"Fentem","email":"gfentem1@nsw.gov.au","gender":"Male","ip_address":"221.159.106.63","last_login":"2015-03-27T00:29:56Z","account_balance":1392.37,"country":"ID","favorite_color":"#e8f686"}' > ${DIR}/upload/input/json-sftp-source.json

echo -e "\033[0;33mCreating JSON (with shema) SFTP Source connector\033[0m"
docker exec connect \
     curl -X PUT \
     -H "Content-Type: application/json" \
     --data '{
               "topics": "test_sftp_sink",
               "tasks.max": "1",
               "connector.class": "io.confluent.connect.sftp.SftpJsonSourceConnector",
               "cleanup.policy":"NONE",
               "behavior.on.error":"IGNORE",
               "input.path": "/upload/input",
               "error.path": "/upload/error",
               "finished.path": "/upload/finished",
               "input.file.pattern": "json-sftp-source.json",
               "sftp.username":"foo",
               "sftp.password":"pass",
               "sftp.host":"sftp-server",
               "sftp.port":"22",
               "kafka.topic": "sftp-testing-topic",
               "key.schema": "{\"name\" : \"com.example.users.UserKey\",\"type\" : \"STRUCT\",\"isOptional\" : false,\"fieldSchemas\" : {\"id\" : {\"type\" : \"INT64\",\"isOptional\" : false}}}",
               "value.schema": "{\"name\" : \"com.example.users.User\",\"type\" : \"STRUCT\",\"isOptional\" : false,\"fieldSchemas\" : {\"id\" : {\"type\" : \"INT64\",\"isOptional\" : false},\"first_name\" : {\"type\" : \"STRING\",\"isOptional\" : true},\"last_name\" : {\"type\" : \"STRING\",\"isOptional\" : true},\"email\" : {\"type\" : \"STRING\",\"isOptional\" : true},\"gender\" : {\"type\" : \"STRING\",\"isOptional\" : true},\"ip_address\" : {\"type\" : \"STRING\",\"isOptional\" : true},\"last_login\" : {\"type\" : \"STRING\",\"isOptional\" : true},\"account_balance\" : {\"name\" : \"org.apache.kafka.connect.data.Decimal\",\"type\" : \"BYTES\",\"version\" : 1,\"parameters\" : {\"scale\" : \"2\"},\"isOptional\" : true},\"country\" : {\"type\" : \"STRING\",\"isOptional\" : true},\"favorite_color\" : {\"type\" : \"STRING\",\"isOptional\" : true}}}"
          }' \
     http://localhost:8083/connectors/sftp-source | jq .

sleep 5

echo -e "\033[0;33mVerifying topic sftp-testing-topic\033[0m"
docker exec schema-registry kafka-avro-console-consumer -bootstrap-server broker:9092 --topic sftp-testing-topic --from-beginning --max-messages 2