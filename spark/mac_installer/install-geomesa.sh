#!/usr/bin/env bash

#----------------------------------------------------------------------------------------------------------------------
#
# Purpose: Installs GeoMesa FileSystem Datastore and GeoMesa Spark on a standalone Mac
#
# Organisation: IAG
# Author: Hugh Saalmans, Product Innovation
# GitHub: iag-geo
#
# Copyright:
#  - Code is copyright IAG - licensed under an Apache License, version 2.0
#
# IMPORTANT: requires Python 2.7.15 to avoid TLS issue with pypi
#
# May require 127.0.0.1	localhost to be added to your /etc/hosts file
#
#----------------------------------------------------------------------------------------------------------------------

# record how long this script takes (6-10 mins with a good Internet connection)
SECONDS=0

# setup an SSH key pair for hadoop to connect to localhost
echo | ssh-keygen -t rsa -P ""
cat ${HOME}/.ssh/id_rsa.pub >> ${HOME}/.ssh/authorized_keys

# install wget for downloading files
brew reinstall wget

# create new directory to install Spark, Hadoop and Geomesa in
mkdir ${HOME}/geomesa
cd ${HOME}/geomesa


echo -e "\n# -----------------------------------------------------------------------" >> ${HOME}/.bash_profile
echo "# GEOMESA SETTINGS - start" >> ${HOME}/.bash_profile
echo "# -----------------------------------------------------------------------" >> ${HOME}/.bash_profile

# set your preferred version numbers here - IMPORTANT: before editing - you need to know which combinations are compatible
MAVEN_VERSION="3.6.1"
GEOMESA_VERSION="2.3.0"
HADOOP_VERSION="2.7.3"
SPARK_VERSION="2.3.3"
AWS_JAVA_SDK_VERSION="1.7.4"

echo -e "\n# version numbers" >> ${HOME}/.bash_profile
echo "export MAVEN_VERSION=\"${MAVEN_VERSION}\"" >> ${HOME}/.bash_profile
echo "export GEOMESA_VERSION=\"${GEOMESA_VERSION}\"" >> ${HOME}/.bash_profile
echo "export HADOOP_VERSION=\"${HADOOP_VERSION}\"" >> ${HOME}/.bash_profile
echo "export SPARK_VERSION=\"${SPARK_VERSION}\"" >> ${HOME}/.bash_profile

# Java and Scala homes
JAVA_HOME="/Library/Java/Home"
SCALA_HOME="/usr/local/opt/scala@2.11"

echo -e "\n# Java & Scala paths" >> ${HOME}/.bash_profile
echo "export JAVA_HOME=\"${JAVA_HOME}\"" >> ${HOME}/.bash_profile
echo "export SCALA_HOME=\"${SCALA_HOME}\"" >> ${HOME}/.bash_profile

# Hadoop and Spark vars
HADOOP_HOME="${HOME}/geomesa/hadoop-${HADOOP_VERSION}"
HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
SPARK_HOME="${HOME}/geomesa/spark-${SPARK_VERSION}-bin-hadoop2.7"

echo -e "\n# Hadoop and Spark vars" >> ${HOME}/.bash_profile
echo "export HADOOP_HOME=\"${HADOOP_HOME}\"" >> ${HOME}/.bash_profile
echo "export HADOOP_CONF_DIR=\"${HADOOP_CONF_DIR}\"" >> ${HOME}/.bash_profile
echo "export SPARK_HOME=\"${SPARK_HOME}\"" >> ${HOME}/.bash_profile

# Geomesa build and runtime vars
GEOMESA_FS_HOME="${HOME}/geomesa/geomesa-fs_2.11-${GEOMESA_VERSION}"
MAVEN_HOME="${HOME}/geomesa/apache-maven-${MAVEN_VERSION}/bin"

echo -e "\n# Geomesa FileStore path" >> ${HOME}/.bash_profile
echo "export GEOMESA_FS_HOME=\"${GEOMESA_FS_HOME}\"" >> ${HOME}/.bash_profile
echo -e "\n# maven home" >> ${HOME}/.bash_profile
echo "export MAVEN_HOME=\"${MAVEN_HOME}\"" >> ${HOME}/.bash_profile


echo "-------------------------------------------------------------------------"
echo "Installing Java 8, Scala 2.11 and Python modules"
echo "-------------------------------------------------------------------------"

brew cask reinstall java8
brew reinstall scala@2.11
/Library/Frameworks/Python.framework/Versions/3.7/bin/python3.7 -m pip install --upgrade pip
/Library/Frameworks/Python.framework/Versions/3.7/bin/python3.7 -m pip install --upgrade pyspark
/Library/Frameworks/Python.framework/Versions/3.7/bin/python3.7 -m pip install --upgrade pyspark-stubs
#/Library/Frameworks/Python.framework/Versions/3.7/bin/python3.7 -m pip install --upgrade py4j


echo "-------------------------------------------------------------------------"
echo "Installing Hadoop"
echo "-------------------------------------------------------------------------"

wget https://archive.apache.org/dist/hadoop/core//hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
tar xzf hadoop-${HADOOP_VERSION}.tar.gz
rm hadoop-${HADOOP_VERSION}.tar.gz

# configure Hadoop environment
sed -i -e "s%export HADOOP_OPTS=\"\${HADOOP_OPTS} -Djava.net.preferIPv4Stack=true\"%export HADOOP_OPTS=\"\${HADOOP_OPTS} -Djava.net.preferIPv4Stack=true -Djava.security.krb5.realm= -Djava.security.krb5.kdc=\"%g" ${HADOOP_CONF_DIR}/hadoop-env.sh
sed -i -e "s%</configuration>%<property><name>fs.defaultFS</name><value>hdfs://127.0.0.1</value></property></configuration>%g" ${HADOOP_CONF_DIR}/core-site.xml
sed -i -e "s%</configuration>%<property><name>dfs.replication</name><value>1</value></property></configuration>%g" ${HADOOP_CONF_DIR}/hdfs-site.xml
sed -i -e "s%</configuration>%<property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property></configuration>%g" ${HADOOP_CONF_DIR}/yarn-site.xml
cp ${HADOOP_CONF_DIR}/mapred-site.xml.template ${HADOOP_CONF_DIR}/mapred-site.xml
sed -i -e "s%</configuration>%<property><name>mapreduce.framework.name</name><value>yarn</value></property></configuration>%g" ${HADOOP_CONF_DIR}/mapred-site.xml

# fix for Mac (Hadoop 2.8.x and 2.9.x issue)
sed -i -e "s%export JAVA_HOME=(\${(/usr/libexec/java_home))%export JAVA_HOME=\${(/usr/libexec/java_home)%g" ${HADOOP_HOME}/libexec/hadoop-config.sh
sed -i -e "s%export JAVA_HOME=(/Library/Java/Home)%export JAVA_HOME=/Library/Java/Home%g" ${HADOOP_HOME}/libexec/hadoop-config.sh


echo "-------------------------------------------------------------------------"
echo "Installing Spark"
echo "-------------------------------------------------------------------------"

wget http://apache.mirror.amaze.com.au/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz
tar -xzf spark-${SPARK_VERSION}-bin-hadoop2.7.tgz
rm spark-${SPARK_VERSION}-bin-hadoop2.7.tgz

# add required jar files
cd ${SPARK_HOME}/jars
cp ${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-${HADOOP_VERSION}.jar .
wget http://central.maven.org/maven2/com/amazonaws/aws-java-sdk/${AWS_JAVA_SDK_VERSION}/aws-java-sdk-${AWS_JAVA_SDK_VERSION}.jar

# reduce Spark logging to warnings and above (i.e no INFO or DEBUG messages) - to avoid the default belch of logging
cp ${SPARK_HOME}/conf/log4j.properties.template ${SPARK_HOME}/conf/log4j.properties
sed -i -e "s/log4j.rootCategory=INFO, console/log4j.rootCategory=WARN, console/g" ${SPARK_HOME}/conf/log4j.properties

cd ${HOME}/geomesa


echo "-------------------------------------------------------------------------"
echo "Installing GeoMesa FileSystem Datastore"
echo "-------------------------------------------------------------------------"

wget "https://github.com/locationtech/geomesa/releases/download/geomesa_2.11-${GEOMESA_VERSION}/geomesa-fs_2.11-${GEOMESA_VERSION}-bin.tar.gz"
tar xzf geomesa-fs_2.11-${GEOMESA_VERSION}-bin.tar.gz
rm geomesa-fs_2.11-${GEOMESA_VERSION}-bin.tar.gz

# copy JAR file to allow Geomesa FS to support Snappy compression
cp ${SPARK_HOME}/jars/snappy-java-1.1.2.6.jar ${GEOMESA_FS_HOME}/lib


echo "-------------------------------------------------------------------------"
echo "Installing Maven"
echo "-------------------------------------------------------------------------"

wget "http://mirror.olnevhost.net/pub/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
tar xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
rm apache-maven-${MAVEN_VERSION}-bin.tar.gz


echo "-------------------------------------------------------------------------"
echo "Downloading GeoMesa Source Code"
echo "-------------------------------------------------------------------------"

wget "https://github.com/locationtech/geomesa/archive/geomesa_2.11-${GEOMESA_VERSION}.tar.gz"
tar xzf geomesa_2.11-${GEOMESA_VERSION}.tar.gz
rm geomesa_2.11-${GEOMESA_VERSION}.tar.gz

# copy license info to geomesa-spark directory to enable maven build
cd ${HOME}/geomesa/geomesa-geomesa_2.11-${GEOMESA_VERSION}/geomesa-spark
cp -R ${HOME}/geomesa/geomesa-geomesa_2.11-${GEOMESA_VERSION}/build ./build/


echo "-------------------------------------------------------------------------"
echo "Building GeoMesa Spark (2-5 mins)"
echo "-------------------------------------------------------------------------"
${MAVEN_HOME}/mvn clean install -D skipTests -P python > ${HOME}/geomesa/maven_geomesa_spark_build.log


echo "-------------------------------------------------------------------------"
echo "Installing geomesa_pyspark"
echo "-------------------------------------------------------------------------"
/Library/Frameworks/Python.framework/Versions/3.7/bin/python3.7 -m pip install ${HOME}/geomesa/geomesa-geomesa_2.11-${GEOMESA_VERSION}/geomesa-spark/geomesa_pyspark/target/geomesa_pyspark-${GEOMESA_VERSION}.tar.gz


echo "-------------------------------------------------------------------------"
echo "Starting Hadoop"
echo "-------------------------------------------------------------------------"

# initialise Hadoop file store (HDFS)
cd ${HADOOP_HOME}
bin/hdfs namenode -format

# start Hadoop
sbin/start-dfs.sh
sbin/start-yarn.sh
cd ${HOME}

# get HDFS path
HDFS_PATH="$(${HADOOP_HOME}/bin/hdfs getconf -confKey fs.defaultFS)"
echo -e "\n# local HDFS path (for temp files)" >> ${HOME}/.bash_profile
echo "export HDFS_PATH=\"${HDFS_PATH}\"" >> ${HOME}/.bash_profile

echo -e "\n# -----------------------------------------------------------------------" >> ${HOME}/.bash_profile
echo "# GEOMESA SETTINGS - end" >> ${HOME}/.bash_profile
echo "# -----------------------------------------------------------------------" >> ${HOME}/.bash_profile

source ${HOME}/.bash_profile

duration=${SECONDS}

echo "-------------------------------------------------------------------------"
echo "GeoMesa install finished in $((${duration} / 60))m $((${duration} % 60))s"
echo "-------------------------------------------------------------------------"

## commands to stop Hadoop + YARN
#cd ${HADOOP_HOME}
#sbin/stop-dfs.sh
#sbin/stop-yarn.sh
#cd ${HOME}
