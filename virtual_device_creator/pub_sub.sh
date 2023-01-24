#/bin/bash

num_devices=$1
device_name=$2

readarray -t s_array </home/ec2-user/device_simulator/package/certificates/fixed_data.txt

vendor_id="${s_array[0]}"
vendor_name="${s_array[1]}"

# Describe custom endpoint associated with AWS account and specific region
iot_ats_endpoint=$(aws iot describe-endpoint --endpoint-type iot\:Data-ATS | jq -r '.endpointAddress')

# MQTT topic name
mqtt_topic=$(echo "healthMonitors/readings/")

i=1
# Run a loop over all devices, to publish data to them for each run
for j in "${s_array[@]:2}"; do
  # Generate fake data (dynami data per simulation)
  heart_rate=$(shuf -i 25-200 -n 1)
  diastolic=$(shuf -i 80-200 -n 1)
  systolic=$(shuf -i 50-140 -n 1)
  blood_pressure="${diastolic}"/"${systolic}"
  body_temp=$(shuf -i 35-43 -n 1)

  # MQTT publish to topic using mosquitto MQTT client
  mosquitto_pub --cafile "/home/ec2-user/device_simulator/package/certificates/root.ca.bundle.pem" --cert "/home/ec2-user/device_simulator/package/certificates/$device_name$i.pem.crt" --key "/home/ec2-user/device_simulator/package/certificates/$device_name$i.private.key" \
    -h $iot_ats_endpoint -p 8883 -q 0 \
    -t $mqtt_topic -i $device_name$i \
    -m "{\"bloodPressure\": \"$blood_pressure\", \"heartRate\": \"$heart_rate\", \"bodyTemperature\": \"$body_temp\", \"vendorID\": \"$vendor_id\", \"vendorName\": \"$vendor_name\", \"serialNumber\": "$j", \"UTCtimestamp\": $(date +%s)}" -d
  ((i += 1))
done
