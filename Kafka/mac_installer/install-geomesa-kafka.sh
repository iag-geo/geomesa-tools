#!/usr/bin/env bash

#----------------------------------------------------------------------------------------------------------------------
#
# Purpose: Installs Kafka and GeoMesa Kafka on a standalone Mac
#
# Organisation: IAG
# Author: Hugh Saalmans, Product Innovation
# GitHub: iag-geo
#
# Copyright:
#  - Code is copyright IAG - licensed under an Apache License, version 2.0
#
#----------------------------------------------------------------------------------------------------------------------

# record how long this script takes (6-10 mins with a good Internet connection)
SECONDS=0

echo "-------------------------------------------------------------------------"
echo "Updating Homebrew and installing wget"
echo "-------------------------------------------------------------------------"

cd ~
brew update

# install wget for downloading files
brew reinstall wget

# create new directory to install Kafka & Geomesa in
INSTALL_DIR=${HOME}/kafka
mkdir ${INSTALL_DIR}
cd ${INSTALL_DIR}


echo -e "\n# -----------------------------------------------------------------------" >> ${HOME}/.bash_profile
echo "# GEOMESA KAFKA SETTINGS - start" >> ${HOME}/.bash_profile
echo "# -----------------------------------------------------------------------" >> ${HOME}/.bash_profile

# set your version numbers here - IMPORTANT: you need to know which combinations are compatible
MAVEN_VERSION="3.6.0"
SCALA_VERSION="2.11"
KAFKA_VERSION="2.0.1"
GEOMESA_KAFKA_VERSION="2.0.2"

echo -e "\n# version numbers" >> ${HOME}/.bash_profile
echo "export MAVEN_VERSION=\"${MAVEN_VERSION}\"" >> ${HOME}/.bash_profile
echo "export SCALA_VERSION=\"${SCALA_VERSION}\"" >> ${HOME}/.bash_profile
echo "export KAFKA_VERSION=\"${KAFKA_VERSION}\"" >> ${HOME}/.bash_profile
echo "export GEOMESA_KAFKA_VERSION=\"${GEOMESA_KAFKA_VERSION}\"" >> ${HOME}/.bash_profile


echo "-------------------------------------------------------------------------"
echo "Installing Java 8"  # & Scala"
echo "-------------------------------------------------------------------------"

# will require your password on install
brew cask reinstall java8
#brew install scala@${SCALA_VERSION}


echo "-------------------------------------------------------------------------"
echo "Installing Maven"
echo "-------------------------------------------------------------------------"

MAVEN_FILENAME=apache-maven-${MAVEN_VERSION}
MAVEN_HOME="${INSTALL_DIR}/${MAVEN_FILENAME}"
echo -e "\n# maven home" >> ${HOME}/.bash_profile
echo "export MAVEN_HOME=\"${MAVEN_HOME}\"" >> ${HOME}/.bash_profile
echo "export PATH=${PATH}:${MAVEN_HOME}/bin" >> ${HOME}/.bash_profile


wget --quiet "http://mirror.olnevhost.net/pub/apache/maven/maven-3/${MAVEN_VERSION}/binaries/${MAVEN_FILENAME}-bin.tar.gz"
tar xzf ${MAVEN_FILENAME}-bin.tar.gz
rm ${MAVEN_FILENAME}-bin.tar.gz


echo "-------------------------------------------------------------------------"
echo "Installing Kafka"
echo "-------------------------------------------------------------------------"

KAFKA_FILENAME=kafka_${SCALA_VERSION}-${KAFKA_VERSION}
KAFKA_HOME="${INSTALL_DIR}/${KAFKA_FILENAME}"
ZK_HOSTS=localhost:2181
KAFKA_BROKERS=localhost:9092
echo -e "\n# Kafka vars" >> ${HOME}/.bash_profile
echo "export KAFKA_HOME=\"${KAFKA_HOME}\"" >> ${HOME}/.bash_profile
echo "export ZK_HOSTS=\"${ZK_HOSTS}\"" >> ${HOME}/.bash_profile
echo "export KAFKA_BROKERS=\"${KAFKA_BROKERS}\"" >> ${HOME}/.bash_profile

wget --quiet "http://apache.mirror.serversaustralia.com.au/kafka/${KAFKA_VERSION}/${KAFKA_FILENAME}.tgz"
tar xzf ${KAFKA_FILENAME}.tgz
rm ${KAFKA_FILENAME}.tgz

# enable deletion of topics
echo -e "\n# enable topics to be deleted" >> ${KAFKA_HOME}/config/server.properties
echo "delete.topic.enable=true" >> ${KAFKA_HOME}/config/server.properties

# create tmp folders
mkdir ${HOME}/tmp/kafka-logs
mkdir ${HOME}/tmp/zookeeper


echo "-------------------------------------------------------------------------"
echo "Installing GeoMesa Kafka Datastore"
echo "-------------------------------------------------------------------------"

#https://github.com/locationtech/geomesa/releases/download/geomesa_2.11-2.0.2/geomesa-kafka_2.11-2.0.2-bin.tar.gz

GEOMESA_FILENAME=geomesa-kafka_${SCALA_VERSION}-${GEOMESA_KAFKA_VERSION}
GEOMESA_KAFKA_HOME="${INSTALL_DIR}/${GEOMESA_FILENAME}"
echo -e "\n# Geomesa Kafka path" >> ${HOME}/.bash_profile
echo "export GEOMESA_KAFKA_HOME=\"${GEOMESA_KAFKA_HOME}\"" >> ${HOME}/.bash_profile
echo "export GEOMESA_KAFKA_HOME=\"${GEOMESA_KAFKA_HOME}\"" >> ${HOME}/.bash_profile
echo "export PATH=${PATH}:${GEOMESA_KAFKA_HOME}/bin" >> ${HOME}/.bash_profile

wget --quiet "https://github.com/locationtech/geomesa/releases/download/geomesa_${SCALA_VERSION}-${GEOMESA_KAFKA_VERSION}/${GEOMESA_FILENAME}-bin.tar.gz"
tar xzf ${GEOMESA_FILENAME}-bin.tar.gz
rm ${GEOMESA_FILENAME}-bin.tar.gz

# delete duplicate log4j JARs (keep the ones in the Kafka classpath
rm ${GEOMESA_KAFKA_HOME}/lib/log4j-1.2.17.jar
rm ${GEOMESA_KAFKA_HOME}/lib/slf4j-log4j12-1.7.21.jar


echo "-------------------------------------------------------------------------"
echo "Set Java paths"
echo "-------------------------------------------------------------------------"

JAVA_HOME="/Library/Java/Home"
#SCALA_HOME="/usr/local/opt/scala@${SCALA_VERSION}"
echo -e "\n# Java paths" >> ${HOME}/.bash_profile
echo "export JAVA_HOME=\"${JAVA_HOME}\"" >> ${HOME}/.bash_profile
#echo "export SCALA_HOME=\"${SCALA_HOME}\"" >> ${HOME}/.bash_profile

# test if CLASSPATH environment var exists and append if true
if [[ -z "${CLASSPATH}" ]]; then
  echo "export CLASSPATH=\"${KAFKA_HOME}/libs/:${GEOMESA_KAFKA_HOME}/lib/\"" >> ${HOME}/.bash_profile
else
  echo "export CLASSPATH=\"${CLASSPATH}:${KAFKA_HOME}/libs/:${GEOMESA_KAFKA_HOME}/lib/\"" >> ${HOME}/.bash_profile
fi


echo -e "\n# -----------------------------------------------------------------------" >> ${HOME}/.bash_profile
echo "# GEOMESA KAFKA SETTINGS - end" >> ${HOME}/.bash_profile
echo "# -----------------------------------------------------------------------" >> ${HOME}/.bash_profile

source ${HOME}/.bash_profile

duration=${SECONDS}

echo "-------------------------------------------------------------------------"
echo "GeoMesa Kafka install finished in $((${duration} / 60))m $((${duration} % 60))s"
echo "-------------------------------------------------------------------------"


echo "-------------------------------------------------------------------------"
echo "Starting Zookeeper and Kafka as daemons"
echo "-------------------------------------------------------------------------"

$KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties
$KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties

echo "-------------------------------------------------------------------------"
echo "Zookeeper and Kafka started"
echo "-------------------------------------------------------------------------"



