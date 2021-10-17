#!/usr/bin/env bash

set -eu

TEMPS_DIRECTORY="temps"
mkdir -p $TEMPS_DIRECTORY

KEYSTORE_POSTFIX="keystore.jks"
KEYSTORE_FILENAME="kafka.keystore.jks"
VALIDITY_IN_DAYS=3650
DEFAULT_TRUSTSTORE_FILENAME="kafka.truststore.jks"
TRUSTSTORE_WORKING_DIRECTORY="truststore"
KEYSTORE_WORKING_DIRECTORY="keystore"

CA_CERT_FILE="$TEMPS_DIRECTORY/ca-cert"
KEYSTORE_SIGN_REQUEST="$TEMPS_DIRECTORY/cert-file"
KEYSTORE_SIGN_REQUEST_SRL="$TEMPS_DIRECTORY/ca-cert.srl"
KEYSTORE_SIGNED_CERT="$TEMPS_DIRECTORY/cert-signed"

COUNTRY=$COUNTRY
STATE=$STATE
OU=$ORGANIZATION_UNIT
TRUSTSTORE_CN=$TRUSTSTORE_CN

KAFKA_BROKER_KEYSTORE_CN="broker.$TRUSTSTORE_CN"
KAFKA_ZOOKEEPER_KEYSTORE_CN="zookeeper.$TRUSTSTORE_CN"

# CN=$HOSTNAME
LOCATION=$CITY
PASS=$PASSWORD

function file_exists_and_exit() {
  echo "'$1' cannot exist. Move or delete it before"
  echo "re-running this script."
  exit 1
}

if [ -e "$KEYSTORE_WORKING_DIRECTORY" ]; then
  file_exists_and_exit $KEYSTORE_WORKING_DIRECTORY
fi

if [ -e "$CA_CERT_FILE" ]; then
  file_exists_and_exit $CA_CERT_FILE
fi

if [ -e "$KEYSTORE_SIGN_REQUEST" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST
fi

if [ -e "$KEYSTORE_SIGN_REQUEST_SRL" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST_SRL
fi

if [ -e "$KEYSTORE_SIGNED_CERT" ]; then
  file_exists_and_exit $KEYSTORE_SIGNED_CERT
fi

echo "Welcome to the Kafka SSL keystore and trust store generator script."

trust_store_file=""
trust_store_private_key_file=""

  if [ -e "$TRUSTSTORE_WORKING_DIRECTORY" ]; then
    file_exists_and_exit $TRUSTSTORE_WORKING_DIRECTORY
  fi

  mkdir $TRUSTSTORE_WORKING_DIRECTORY
  echo
  echo "OK, we'll generate a trust store and associated private key."
  echo
  echo "First, the private key."
  echo

  openssl req -new -x509 -keyout $TRUSTSTORE_WORKING_DIRECTORY/ca-key \
    -out $TRUSTSTORE_WORKING_DIRECTORY/ca-cert -days $VALIDITY_IN_DAYS -nodes \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$OU/CN=*.$TRUSTSTORE_CN"

  trust_store_private_key_file="$TRUSTSTORE_WORKING_DIRECTORY/ca-key"

  echo
  echo "Two files were created:"
  echo " - $TRUSTSTORE_WORKING_DIRECTORY/ca-key -- the private key used later to"
  echo "   sign certificates"
  echo " - $TRUSTSTORE_WORKING_DIRECTORY/ca-cert -- the certificate that will be"
  echo "   stored in the trust store in a moment and serve as the certificate"
  echo "   authority (CA). Once this certificate has been stored in the trust"
  echo "   store, it will be deleted. It can be retrieved from the trust store via:"
  echo "   $ keytool -keystore <trust-store-file> -export -alias CARoot -rfc"

  echo
  echo "Now the trust store will be generated from the certificate."
  echo

  keytool -keystore $TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME \
    -alias CARoot -import -file $TRUSTSTORE_WORKING_DIRECTORY/ca-cert \
    -noprompt -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$TRUSTSTORE_CN" -keypass $PASS -storepass $PASS

  trust_store_file="$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME"

  echo
  echo "$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME was created."

  # don't need the cert because it's in the trust store.
  # rm $TRUSTSTORE_WORKING_DIRECTORY/$CA_CERT_FILE

echo
echo "Continuing with:"
echo " - trust store file:        $trust_store_file"
echo " - trust store private key: $trust_store_private_key_file"

mkdir $KEYSTORE_WORKING_DIRECTORY

echo
echo "Now, a keystore will be generated. Each broker and logical client needs its own"
echo "keystore. This script will create only one keystore. Run this script multiple"
echo "times for multiple keystores."
echo
echo "     NOTE: currently in Kafka, the Common Name (CN) does not need to be the FQDN of"
echo "           this host. However, at some point, this may change. As such, make the CN"
echo "           the FQDN. Some operating systems call the CN prompt 'first / last name'"

# To learn more about CNs and FQDNs, read:
# https://docs.oracle.com/javase/7/docs/api/javax/net/ssl/X509ExtendedTrustManager.html

for i in broker1 broker2 broker3 zookeeper producer consumer
do
  keytool -keystore $KEYSTORE_WORKING_DIRECTORY/$i.$KEYSTORE_POSTFIX \
    -alias localhost -validity $VALIDITY_IN_DAYS -genkey -keyalg RSA \
    -noprompt -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$i.$TRUSTSTORE_CN" -keypass $PASS -storepass $PASS

  keytool -keystore $trust_store_file -export -alias CARoot -rfc -file $CA_CERT_FILE -keypass $PASS -storepass $PASS

  keytool -keystore $KEYSTORE_WORKING_DIRECTORY/$i.$KEYSTORE_POSTFIX -alias localhost \
    -certreq -file $KEYSTORE_SIGN_REQUEST -keypass $PASS -storepass $PASS

  openssl x509 -req -CA $CA_CERT_FILE -CAkey $trust_store_private_key_file \
    -in $KEYSTORE_SIGN_REQUEST -out $KEYSTORE_SIGNED_CERT \
    -days $VALIDITY_IN_DAYS -CAcreateserial

  keytool -keystore $KEYSTORE_WORKING_DIRECTORY/$i.$KEYSTORE_POSTFIX -alias CARoot \
    -import -file $CA_CERT_FILE -keypass $PASS -storepass $PASS -noprompt
  rm $CA_CERT_FILE # delete the trust store cert because it's stored in the trust store.

  keytool -keystore $KEYSTORE_WORKING_DIRECTORY/$i.$KEYSTORE_POSTFIX -alias localhost -import \
    -file $KEYSTORE_SIGNED_CERT -keypass $PASS -storepass $PASS
 
  rm $KEYSTORE_SIGN_REQUEST_SRL
  rm $KEYSTORE_SIGN_REQUEST
  rm $KEYSTORE_SIGNED_CERT

done