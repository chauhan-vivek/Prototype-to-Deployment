#!/bin/bash

set -e

s3_bucket_name=$1

# Copy the JSON file containing IoT details to local system from S3
aws s3 cp s3://$s3_bucket_name/simulation_details.json ./ --quiet

# Parsing the JSON file to get the required IoT device details
device_type_name=$(jq -r '.deviceName' simulation_details.json)
num_devices=$(jq -r '.numDevices' simulation_details.json)
iot_provisioning_role_arn=$(jq -r '.iotRoleArn' simulation_details.json)
heartRate=$(jq -r '.payloadAttributes.heartRate' simulation_details.json)
bloodPressure=$(jq -r '.payloadAttributes.bloodPressure' simulation_details.json)
body_temp=$(jq -r '.payloadAttributes.bodyTemperature' simulation_details.json)
vendor_id=$(jq -r '.payloadAttributes.vendorID' simulation_details.json)
vendor_name=$(jq -r '.payloadAttributes.vendorName' simulation_details.json)
interval=$(jq -r '.interval' simulation_details.json)
duration=$(jq -r '.duration' simulation_details.json)
utc_timestamp=$(jq -r '.UTCtimestamp' simulation_details.json)
serial_number=$(jq -r '.serialNumber' simulation_details.json)

device_regex="^[a-zA-Z0-9_-]+"
vendor_regex="^[a-zA-Z0-9]+"

#Check the variable is set or not
# Syntax and range checks for each value also included
if [ -z ${num_devices} ]; then
  echo "'numDevices' has an empty value in JSON"
  if [[ $num_devices =~ ^[0-9]+$ ]]; then
    echo "Please enter valid value for 'numDevices'"
    if (($num_devices >= 1 && $num_devices <= 50)); then
      :
    else
      echo "Please enter a value between 1 and 50 for 'numDevices'"
      exit 1
    fi
  fi
  exit 1
fi

if [ -z ${interval} ]; then
  echo "'interval' has an empty value in JSON. Please enter valid value"
  if [[ $interval =~ ^[0-9]+$ ]]; then
    echo "Please enter valid numeric value for 'interval'"
    if (($interval > 1 && $interval <= 59)); then
      :
    else
      echo "Please enter a value between 1 and 59 minutes for 'interval'"
      exit 1
    fi
  fi
  exit 1
fi

if [ -z ${duration} ]; then
  echo "'duration' has an empty value in JSON. Please enter valid value"
  if [[ $interval =~ ^[0-9]+$ ]]; then
    echo "Please enter valid numeric value for 'duration'"
    if (($duration >= $interval && $duration <= 60)); then
      :
    else
      echo "Please enter a value between your 'interval' value and 3600 seconds for 'duration'. Value of duration must be >= interval"
      exit 1
    fi
  fi
  exit 1
fi

if [ -z ${device_type_name} ]; then
  echo "'deviceName' has an empty value in JSON"
  if [[ $device_type_name =~ $device_regex ]]; then
    echo "'deviceName' can only contain a-z, A-Z or 0-9, _ or -. Please enter valid value"
    exit 1
  fi
  exit 1
fi

if [ -z ${vendor_id} ]; then
  echo "'vendorID' has an empty value in JSON"
  if [[ $vendor_id =~ $vendor_regex ]]; then
    echo "'vendorID' can only contain a-z, A-Z or 0-9. Please enter valid value"
    exit 1
  fi
  exit 1
fi

if [ -z ${vendor_name} ]; then
  echo "'vendorName' has an empty value in JSON"
  if [[ $vendor_name =~ $vendor_regex ]]; then
    echo "'vendorName' can only contain a-z, A-Z or 0-9. Please enter valid value"
    exit 1
  fi
  exit 1
fi

if [ -z ${heartRate} ]; then
  echo "'heartRate' has an empty value in JSON"
  if [[ $heartRate =~ ^[0-9]+$ ]]; then
    echo "Please enter valid value for 'heartRate'"
    exit 1
    if (($heartRate >= 25 && $heartRate <= 200)); then
      :
    else
      echo "Please enter a value between 25 and 200 for 'heartRate'"
      exit 1
    fi
  fi
  exit 1
fi

if [ -z ${bloodPressure} ]; then
  echo "'bloodPressure' has an empty value in JSON"
  if [[ $bloodPressure =~ ^\d{2,3}\/\d{2,3}$ ]]; then
    echo "Please enter valid value for 'bloodPressure'. The format should be like '120/80'"
    exit 1
  fi
  exit 1
fi

if [ -z ${body_temp} ]; then
  echo "'bodyTemperature' has an empty value in JSON"
  if [[ $body_temp =~ ^\d{2}$ ]]; then
    echo "Please enter valid value for 'bloodPressure'"
    exit 1
    if (($body_temp >= 36 && $body_temp < 43)); then
      :
    else
      echo "Please enter a value between 36 and 42 degree Celsius for 'bodyTemperature'"
      exit 1
    fi
  fi
  exit 1
fi

if [ "${utc_timestamp}" = "null" ]; then
  :
else
  echo "UTCtimestamp value is generated automatically. Please keep it blank"
  exit 1
fi

if [ "${serial_number}" = "null" ]; then
  :
else
  echo "'serialNumber' value is generated automatically. Please keep it blank"
  exit 1
fi

# Create certificates directory
certs_dir=certificates
device_sim_dir=device_simulator

# # Curl command to download the Amazon Root CA certificate.
# curl -o /home/ec2-user/$device_sim_dir/package/$certs_dir/root.crt https://www.amazontrust.com/repository/AmazonRootCA1.pem
# chmod 644 /home/ec2-user/$device_sim_dir/package/$certs_dir/root.crt

# Enable device logging
aws iot set-v2-logging-options --default-log-level INFO --role-arn $iot_provisioning_role_arn

# Enable all IoT AWS events
aws iot update-event-configurations --cli-input-json \
  '{
    "eventConfigurations": {
        "THING_TYPE": {
            "Enabled": true
        },
        "JOB_EXECUTION": {
            "Enabled": true
        },
        "THING_GROUP_HIERARCHY": {
            "Enabled": true
        },
        "CERTIFICATE": {
            "Enabled": true
        },
        "THING_TYPE_ASSOCIATION": {
            "Enabled": true
        },
        "THING_GROUP_MEMBERSHIP": {
            "Enabled": true
        },
        "CA_CERTIFICATE": {
            "Enabled": true
        },
        "THING": {
            "Enabled": true
        },
        "JOB": {
            "Enabled": true
        },
        "POLICY": {
            "Enabled": true
        },
        "THING_GROUP": {
            "Enabled": true
        }
    }
}'

# Turn indexing on
aws iot update-indexing-configuration \
  --thing-indexing-configuration thingIndexingMode=REGISTRY_AND_SHADOW,thingConnectivityIndexingMode=STATUS \
  --thing-group-indexing-configuration thingGroupIndexingMode=ON

thing_group_name=HealthMonitors
thing_type_name=HealthMonitor

# Create thing group for provisioning template first
aws iot delete-thing –thing-group $thing_group_name || aws iot create-thing-group --thing-group-name $thing_group_name

# Create thing type for provisioning template first
if aws iot deprecate-thing-type --thing-type-name $thing_type_name; then
sleep 300
aws iot delete-thing-type $thing_type_name
else
:
fi

aws iot create-thing-type --thing-type-name "$thing_type_name" --thing-type-properties "thingTypeDescription=Health monitor payload attributes, searchableAttributes=serialNumber,UTCtimestamp,vendorID"


# Create one policy for all things
POLICY_NAME=AllThingsPolicy
if [ aws iot delete-policy --policy-name $POLICY_NAME ]; then
aws iot create-policy --policy-name $POLICY_NAME \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action": "iot:*","Resource":"*"}]}'
else
aws iot create-policy --policy-name $POLICY_NAME \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action": "iot:*","Resource":"*"}]}'
fi

total_num_things=$(aws iot list-things --thing-type-name $thing_type_name --max-items 50 | jq -r '.things')

for i in $(seq 1 $num_devices); do

  aws iot create-thing --thing-name $device_type_name$i --thing-type-name $thing_type_name \
    --attribute-payload "{\"attributes\": {\"UTCtimestamp\": \"\", \"vendorID\": \"\", \"serialNumber\": \"\", \"bloodPressure\": \"\", \"heartRate\": \"\", \"bodyTemparature\": \"\", \"vendorName\": \"\"}}"

  aws iot add-thing-to-thing-group \
    --thing-name $device_type_name$i \
    --thing-group-name $thing_group_name

  aws iot create-keys-and-certificate \
    --certificate-pem-outfile "/home/ec2-user/$device_sim_dir/package/$certs_dir/$device_type_name$i.pem.crt" \
    --public-key-outfile "/home/ec2-user/$device_sim_dir/package/$certs_dir/$device_type_name$i.public.key" \
    --private-key-outfile "/home/ec2-user/$device_sim_dir/package/$certs_dir/$device_type_name$i.private.key" \
    --set-as-active >/tmp/create_cert_and_keys_response

  cat /tmp/create_cert_and_keys_response

  CERTIFICATE_ARN=$(jq -r ".certificateArn" /tmp/create_cert_and_keys_response)
  CERTIFICATE_ID=$(jq -r ".certificateId" /tmp/create_cert_and_keys_response)

  aws iot attach-policy --policy-name $POLICY_NAME --target $CERTIFICATE_ARN

  aws iot attach-thing-principal --thing-name $device_type_name$i --principal $CERTIFICATE_ARN

done

# fixed set of random data

rm /home/ec2-user/$device_sim_dir/package/$certs_dir/fixed_data.txt

echo "$vendor_id" >>/home/ec2-user/$device_sim_dir/package/$certs_dir/fixed_data.txt
echo "$vendor_name" >>/home/ec2-user/$device_sim_dir/package/$certs_dir/fixed_data.txt
for i in $(seq 1 $num_devices); do
  echo $RANDOM >>/home/ec2-user/$device_sim_dir/package/$certs_dir/fixed_data.txt
done

chown -R ec2-user:ec2-user /home/ec2-user/$device_sim_dir/*

# Create cron expression for simulation to run at specific intervals
exp_syntax="rate($interval minutes)"

aws cloudformation create-stack --stack-name DeviceSimulatorStack \
  --template-url https://$s3_bucket_name.s3.amazonaws.com/device_simulator/runSimulation.json \
  --parameters ParameterKey=numDevices,ParameterValue=$num_devices ParameterKey=cronExpression,ParameterValue="$exp_syntax" ParameterKey=deviceName,ParameterValue=$device_type_name \
  --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM"

aws cloudformation wait stack-create-complete --stack-name DeviceSimulatorStack

sleep $duration

aws cloudformation delete-stack --stack-name DeviceSimulatorStack
aws cloudformation wait stack-delete-complete --stack-name DeviceSimulatorStack
