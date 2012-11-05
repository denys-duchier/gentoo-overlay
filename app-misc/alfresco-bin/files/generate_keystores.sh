#!/bin/bash
#
# Author: Jakub Jirutka <jakub@jirutka.cz>
#

# The directory containing the alfresco keystores, as referenced by 
# keystoreFile and truststoreFile attributes in tomcat/conf/server.xml
ALFRESCO_KEYSTORE=@CONF_DIR@/keystore

# SOLR installation directory
SOLR_KEYSTORE=/tmp/solr-keystore

# Temp location in which new keystore files will be generated
TEMP=/tmp/solrkeys

# The repository server certificate subject name, as specified in 
# tomcat-users.xml with roles="repository"
REPO_CERT_DNAME="CN=Alfresco Repository, OU=Unknown, O=Alfresco Software Ltd., \
L=Maidenhead, ST=UK, C=GB"

# The SOLR client certificate subject name, as specified in 
# tomcat-users.xml with roles="repoclient"
SOLR_CLIENT_CERT_DNAME="CN=Alfresco Repository Client, OU=Unknown, O=Alfresco \
Software Ltd., L=Maidenhead, ST=UK, C=GB"

# The number of days before the certificate expires
VALID_DAYS=36525

# Password to secure keystores
KEYPASS=kT9X6oe68t



##########  F u n c t i o n s  ##########

genkeypair() {
	local keystore="$1"
	local alias="$2"
	local dname="$3"
	local cert="${alias}.crt"

	/usr/bin/keytool -genkeypair \
		-keyalg RSA \
		-dname "${dname}" \
		-validity ${VALID_DAYS} \
		-alias "${alias}" \
		-keypass "${KEYPASS}" \
		-keystore "${keystore}" \
		-storetype JCEKS \
		-storepass "${KEYPASS}"

	/usr/bin/keytool -exportcert \
		-alias "${alias}" \
		-file "${cert}" \
		-keystore "${keystore}" \
		-storetype JCEKS \
		-storepass "${KEYPASS}"
}

importcert() {
	local keystore="$1"
	local alias="$2"
	local cert="${alias}.crt"

	/usr/bin/keytool -importcert \
		-noprompt \
		-alias "${alias}" \
		-file "${TEMP}/${cert}" \
		-keystore "${keystore}" \
		-storetype JCEKS \
		-storepass "${KEYPASS}"
}

checkdir() {
	local dir="$1"

	if [ ! -d "${dir}" ]; then
		echo "${dir} does not exist"
		exit 1
	fi
}

backup() {
	local dir="$1"

	# if not empty
	if [ "$(ls -A ${dir})" ]; then
		mkdir "${dir}/backup"
		local tfile; for tfile in "${dir}"/*; do
			cp "${tfile}" "${dir}/backup/" 2>/dev/null
		done
	fi
}



##########  S e t u p  ##########

# Ask for paths...

echo -n "Path to Alfresco keystore [${ALFRESCO_KEYSTORE}]: "
read input
if [ -n "${input}" ]; then
	ALFRESCO_KEYSTORE="${input}"
fi
checkdir "${ALFRESCO_KEYSTORE}"

echo -n "Path to Solr keystore [${SOLR_KEYSTORE}]: "
read input
if [ -n "${input}" ]; then
	SOLR_KEYSTORE="${input}"
fi
checkdir "${SOLR_KEYSTORE}"

# Ensure certificate output dir exists and is empty
mkdir -p "${TEMP}"
if [ "$(ls -A ${TEMP})" ]; then
	echo "Temp directory ${TEMP} must be empty!"
	exit 1
fi

cd "${TEMP}"



##########  M a i n  ##########

echo "Creating certificates and keystores..."

# Generate new self-signed certificates for the repository and solr
genkeypair "ssl.keystore" "ssl.repo" "${REPO_CERT_DNAME}"
genkeypair "ssl.repo.client.keystore" "ssl.repo.client" "${SOLR_CLIENT_CERT_DNAME}"

# Create trust relationship between repository and solr
importcert "ssl.truststore" "ssl.repo.client"

# Create trust relationship between repository and itself - used for searches
importcert "ssl.truststore" "ssl.repo"

# Create trust relationship between solr and repository
importcert "ssl.repo.client.truststore" "ssl.repo"

# Export repository keystore to pkcs12 format for browser compatibility
/usr/bin/keytool -importkeystore \
	-srckeystore "ssl.keystore" \
	-srcstorepass "${KEYPASS}" \
	-srcstoretype JCEKS \
	-srcalias ssl.repo \
	-srckeypass "${KEYPASS}" \
	-destkeystore "browser.p12" \
	-deststoretype pkcs12 \
	-deststorepass alfresco \
	-destalias ssl.repo \
	-destkeypass alfresco


echo
echo "Creating passwords files"

cat > ssl-keystore-passwords.properties <<-EOL
	aliases=ssl.alfresco.ca,ssl.repo
	keystore.password=${KEYPASS}
	ssl.repo.password=${KEYPASS}
	ssl.alfresco.ca.password=${KEYPASS}
EOL
cat > ssl-keystore-passwords.client.properties <<-EOL
	aliases=ssl.alfresco.ca,ssl.repo.client
	keystore.password=${KEYPASS}
	ssl.repo.client.password=${KEYPASS}
	ssl.alfresco.ca.password=${KEYPASS}
EOL
cat > ssl-truststore-passwords.properties <<-EOL
	aliases=alfresco.ca
	keystore.password=${KEYPASS}
	alfresco.ca.password=${KEYPASS}
EOL


echo
echo "Backuping old files if there are any..."

backup "${ALFRESCO_KEYSTORE}"
backup "${SOLR_KEYSTORE}"


echo
echo "Copying new files to ${ALFRESCO_KEYSTORE}..."

# Install the new files to alfresco
cp -v ssl.{key,trust}store browser.p12 "${ALFRESCO_KEYSTORE}"
cp -v ssl-{key,trust}store-passwords.properties "${ALFRESCO_KEYSTORE}"

echo
echo "Copying new files to ${SOLR_KEYSTORE}..."

# Install new files to solr
cp -v ssl.repo.client.{key,trust}store "${SOLR_KEYSTORE}"
cp -v ssl-truststore-passwords.properties "${SOLR_KEYSTORE}"
cp -v ssl-keystore-passwords.client.properties "${SOLR_KEYSTORE}/ssl-keystore-passwords.properties"

# Clean
rm -Rf "${TEMP}"

echo
echo "Certificate update completed"
echo "Please ensure that you set dir.keystore=${ALFRESCO_KEYSTORE} in alfresco-global.properties"
