#!/bin/bash
mkdir -p certificates
cd certificates

set -o nounset \
    -o errexit \
    -o verbose \
    -o xtrace

globalPassword=your-password

# Generate CA key
openssl req -new -x509 -keyout snakeoil-ca-1.key -out snakeoil-ca-1.crt -days 365 -subj '/CN=ca1.dev.doitsu.tech/OU=DEV/O=DTECH/L=VN/S=HCM/C=VN' -passin pass:$globalPassword -passout pass:$globalPassword

# Generate Certificates for Brokers, Consumer, Producer
openssl genrsa -des3 -passout "pass:$globalPassword" -out kafkacat.client.key 2048
openssl req -passin "pass:$globalPassword" -passout "pass:$globalPassword" -key kafkacat.client.key -new -out kafkacat.client.req -subj '/CN=kafkacat.dev.doitsu.tech/OU=DEV/O=DTECH/L=VN/S=HCM/C=VN'
openssl x509 -req -CA snakeoil-ca-1.crt -CAkey snakeoil-ca-1.key -in kafkacat.client.req -out kafkacat-ca1-signed.pem -days 9999 -CAcreateserial -passin "pass:$globalPassword"

for i in broker1 broker2 broker3 producer consumer
do
	echo $
	# Create keystores
	keytool -genkey -noprompt \
				 -alias $i \
				 -dname "CN=$i.dev.doitsu.tech, OU=DEV, O=DTECH, L=VN, S=HCM, C=VN" \
				 -keystore kafka.$i.keystore.jks \
				 -keyalg RSA \
				 -storepass $globalPassword \
				 -keypass $globalPassword

	# Create CSR, sign the key and import back into keystore
	keytool -keystore kafka.$i.keystore.jks -alias $i -certreq -file $i.csr -storepass $globalPassword -keypass $globalPassword
	openssl x509 -req -CA snakeoil-ca-1.crt -CAkey snakeoil-ca-1.key -in $i.csr -out $i-ca1-signed.crt -days 9999 -CAcreateserial -passin pass:$globalPassword
	keytool -keystore kafka.$i.keystore.jks -alias CARoot -import -file snakeoil-ca-1.crt -storepass $globalPassword -keypass $globalPassword
	keytool -keystore kafka.$i.keystore.jks -alias $i -import -file $i-ca1-signed.crt -storepass $globalPassword -keypass $globalPassword

	# Create truststore and import the CA cert.
	keytool -keystore kafka.$i.truststore.jks -alias CARoot -import -file snakeoil-ca-1.crt -storepass $globalPassword -keypass $globalPassword
  echo "$globalPassword" > ${i}_sslkey_creds
  echo "$globalPassword" > ${i}_keystore_creds
  echo "$globalPassword" > ${i}_truststore_creds
done
