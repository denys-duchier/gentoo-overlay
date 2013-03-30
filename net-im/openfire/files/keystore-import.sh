#!/bin/bash
# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2


##########  F u n c t i o n s  ##########

# Creates temp directory
create_temp() {
	tmpdir=`mktemp -q -d /tmp/${scriptname}.XXXX`

	if [ $? -ne 0 ]; then
		echo "${scriptname}: Can't create temp directory, exiting..." 1>&2
		exit 1
	fi
}

# Cleans temp directory
cleanup() {
	if [ ! -z "${tmpdir}" -a -d ${tmpdir} ]; then
		rm -rf ${tmpdir}
	fi
}

# Prints usage help
usage() {
	cat <<- EOF
		This script is used to import a key/certificate pair into a Java keystore.

		REQUIRED:
		  -s, --keystore	 Keystore to import certificate to
		  -k, --key		  Private key file to import
		  -c, --cert		 Certificate file to import
		  -a, --alias		Unique alias of the certificate

		OPTIONAL:
		  -p, --passphrase   Passphrase of the keystore (readed from stdin if not specified)
		  -i, --int-cert	 Intermediate certificates file
		  -h, --help		 Show this message
	EOF
}


##########  S e t u p  ##########

scriptname=`basename $0`

while [ $# -gt 0 ]; do
	case $1
	in
		-s | --keystore)
			keystore=$2
			shift 2
	;;
		-k | --key)
			key=$2
			shift 2
	;;
		-c | --cert)
			cert=$2
			shift 2
	;;
		-a | --alias)
			alias=$2
			shift 2
	;;
		-p | --passphrase)
			passphrase=$2
			shift 2
	;;
		-i | --int-cert)
			int_cert=$2
			shift 2
	;;
		-h | --help)
			usage
			exit 0
	;;
		*)
			echo "${scriptname}: Unknown option $1, exiting" 1>&2
			usage
			exit 1
	;;
	esac
done

if [ -z "${key}" -o -z "${cert}" -o -z "${alias}" ]; then
   echo "${scriptname}: Missing option, exiting..." 1>&2
   usage
   exit 1
fi

for f in ${key} ${cert}; do
	if [ ! -f $f ]; then
	   echo "${scriptname}: Can't find file $f, exiting..." 1>&2
	   exit 2
	fi
done

if [ ! -f ${keystore} ]; then
   storedir=`dirname ${keystore}`
   if [ ! -d ${storedir} -o ! -w ${storedir} ]; then
	  echo "${scriptname}: Can't write to ${storedir}, exiting..." 1>&2
	  exit 2
   fi
fi

if [ -z "${passphrase}" ]; then
   # request a passphrase
  read -p "Enter a passphrase: " -s passphrase
  echo ""
fi


##########  M a i n  ##########

create_temp
pkcs12="${tmpdir}/pkcs12"

# bundle cert and key in pkcs12
openssl pkcs12 \
	-export \
	-in ${cert} \
	-inkey ${key} \
	-out ${pkcs12} \
	-password "pass:${passphrase}" \
	-name ${alias} \
	${int_cert:+-certfile ${int_cert}}

# print cert
echo -n "Importing \"${alias}\" with "
openssl x509 -noout -fingerprint -in ${cert}

# import PKCS12 to keystore
keytool \
	-importkeystore \
	-deststorepass ${passphrase} \
	-destkeystore ${keystore} \
	-srckeystore ${pkcs12} \
	-srcstoretype 'PKCS12' \
	-srcstorepass ${passphrase} 

cleanup

