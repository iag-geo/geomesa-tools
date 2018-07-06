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
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# install wget for downloading files
brew install wget

# create new directory to install Spark, Hadoop and Geomesa in
mkdir ~/geomesa
cd ~/geomesa

echo -e "\n# -----------------------------------------------------------------------" >> ~/.bash_profile
echo "# GEOMESA SETTINGS - start" >> ~/.bash_profile
echo "# -----------------------------------------------------------------------" >> ~/.bash_profile

# set your preferred version numbers here - IMPORTANT: before editing - you need to know which combinations are compatible
echo -e "\n# version numbers" >> ~/.bash_profile
echo "export MAVEN_VERSION=3.5.3" >> ~/.bash_profile
echo "export GEOMESA_VERSION=2.0.2" >> ~/.bash_profile
echo "export HADOOP_VERSION=2.7.6" >> ~/.bash_profile
echo "export SPARK_VERSION=2.2.1" >> ~/.bash_profile
source ~/.bash_profile

echo "-------------------------------------------------------------------------"
echo "Installing Java 8, Scala 2.11 and Python modules"
echo "-------------------------------------------------------------------------"
brew cask install java8
brew install scala@2.11
/Library/Frameworks/Python.framework/Versions/2.7/bin/python -m pip install --upgrade pip
/Library/Frameworks/Python.framework/Versions/2.7/bin/python -m pip install py4j

echo -e "\n# Java & Scala paths" >> ~/.bash_profile
#echo "export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_172.jdk/Contents/Home" >> ~/.bash_profile
echo "export JAVA_HOME=/Library/Java/Home" >> ~/.bash_profile
echo "export SCALA_HOME=/usr/local/opt/scala@2.11" >> ~/.bash_profile
source ~/.bash_profile

echo "-------------------------------------------------------------------------"
echo "Installing Hadoop"
echo "-------------------------------------------------------------------------"
wget http://apache.mirror.amaze.com.au/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
tar xzf hadoop-${HADOOP_VERSION}.tar.gz
rm hadoop-${HADOOP_VERSION}.tar.gz

echo -e "\n# Hadoop paths" >> ~/.bash_profile
echo "export HADOOP_HOME=${HOME}/geomesa/hadoop-\${HADOOP_VERSION}" >> ~/.bash_profile
source ~/.bash_profile
echo "export HADOOP_CONF_DIR=\${HADOOP_HOME}/etc/hadoop" >> ~/.bash_profile
source ~/.bash_profile

# configure Hadoop environment
sed -i -e "s%export HADOOP_OPTS=\"\${HADOOP_OPTS} -Djava.net.preferIPv4Stack=true\"%export HADOOP_OPTS=\"\${HADOOP_OPTS} -Djava.net.preferIPv4Stack=true -Djava.security.krb5.realm= -Djava.security.krb5.kdc=\"%g" ${HADOOP_CONF_DIR}/hadoop-env.sh
sed -i -e "s%</configuration>%<property><name>fs.defaultFS</name><value>hdfs://127.0.0.1</value></property></configuration>%g" ${HADOOP_CONF_DIR}/core-site.xml
sed -i -e "s%</configuration>%<property><name>dfs.replication</name><value>1</value></property></configuration>%g" ${HADOOP_CONF_DIR}/hdfs-site.xml
sed -i -e "s%</configuration>%<property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property></configuration>%g" ${HADOOP_CONF_DIR}/yarn-site.xml
cp ${HADOOP_CONF_DIR}/mapred-site.xml.template ${HADOOP_CONF_DIR}/mapred-site.xml
sed -i -e "s%</configuration>%<property><name>mapreduce.framework.name</name><value>yarn</value></property></configuration>%g" ${HADOOP_CONF_DIR}/mapred-site.xml

# fix for Mac (for Hadoop 2.8.x and 2.9.x)
sed -i -e "s%export JAVA_HOME=(\${(/usr/libexec/java_home))%export JAVA_HOME=\${(/usr/libexec/java_home)%g" ${HADOOP_HOME}/libexec/hadoop-config.sh
sed -i -e "s%export JAVA_HOME=(/Library/Java/Home)%export JAVA_HOME=/Library/Java/Home%g" ${HADOOP_HOME}/libexec/hadoop-config.sh

echo "-------------------------------------------------------------------------"
echo "Installing Spark"
echo "-------------------------------------------------------------------------"
wget http://apache.mirror.amaze.com.au/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz
tar -xzf spark-${SPARK_VERSION}-bin-hadoop2.7.tgz
rm spark-${SPARK_VERSION}-bin-hadoop2.7.tgz

echo -e "\n# Spark paths" >> ~/.bash_profile
echo "export SPARK_HOME=${HOME}/geomesa/spark-\${SPARK_VERSION}-bin-hadoop2.7" >> ~/.bash_profile
source ~/.bash_profile
#echo "export PATH=\${JAVA_HOME}/bin:\${SCALA_HOME}/bin:\${SPARK_HOME}:\${SPARK_HOME}/bin:\${SPARK_HOME}/sbin:\${HADOOP_HOME}:\${HADOOP_HOME}/bin:\${HADOOP_HOME}/sbin:\${PATH}" >> ~/.bash_profile
source ~/.bash_profile

# add required jar files
cd ${SPARK_HOME}/jars
cp ${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-${HADOOP_VERSION}.jar .
wget http://central.maven.org/maven2/com/amazonaws/aws-java-sdk/1.7.4/aws-java-sdk-1.7.4.jar

# reduce Spark logging to warnings and above (i.e no INFO or DEBUG messages) - to avoid the default belch of logging
cp ${SPARK_HOME}/conf/log4j.properties.template ${SPARK_HOME}/conf/log4j.properties
sed -i -e "s/log4j.rootCategory=INFO, console/log4j.rootCategory=WARN, console/g" ${SPARK_HOME}/conf/log4j.properties

cd ~/geomesa

# download and install GeoMesa FileSystem Datastore
echo "-------------------------------------------------------------------------"
echo "Installing GeoMesa FileSystem Datastore"
echo "-------------------------------------------------------------------------"
wget "https://github.com/locationtech/geomesa/releases/download/geomesa_2.11-${GEOMESA_VERSION}/geomesa-fs_2.11-${GEOMESA_VERSION}-bin.tar.gz"
tar xzf geomesa-fs_2.11-${GEOMESA_VERSION}-bin.tar.gz
rm geomesa-fs_2.11-${GEOMESA_VERSION}-bin.tar.gz
echo -e "\n# Geomesa FileStore path" >> ~/.bash_profile
echo "export GEOMESA_FS_HOME=${HOME}/geomesa/geomesa-fs_2.11-\${GEOMESA_VERSION}" >> ~/.bash_profile
source ~/.bash_profile

# copy Snappy JAR file to allow Geomesa FS to support it
cp ${SPARK_HOME}/jars/snappy-java-1.1.2.6.jar ${GEOMESA_FS_HOME}/lib

# install Maven to build GeoMesa Spark
echo "-------------------------------------------------------------------------"
echo "Installing Maven"
echo "-------------------------------------------------------------------------"
wget "http://mirror.olnevhost.net/pub/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
tar xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
rm apache-maven-${MAVEN_VERSION}-bin.tar.gz

echo -e "\n# maven home" >> ~/.bash_profile
echo "export MAVEN_HOME=${HOME}/geomesa/apache-maven-\${MAVEN_VERSION}/bin" >> ~/.bash_profile
source ~/.bash_profile

echo "-------------------------------------------------------------------------"
echo "Downloading GeoMesa Source Code"
echo "-------------------------------------------------------------------------"
wget "https://github.com/locationtech/geomesa/archive/geomesa_2.11-${GEOMESA_VERSION}.tar.gz"
tar xzf geomesa_2.11-${GEOMESA_VERSION}.tar.gz
rm geomesa_2.11-${GEOMESA_VERSION}.tar.gz

# copy license info to geomesa-spark directory to enable maven build
cd ~/geomesa/geomesa-geomesa_2.11-${GEOMESA_VERSION}/geomesa-spark
cp -R ~/geomesa/geomesa-geomesa_2.11-${GEOMESA_VERSION}/build ./build/

echo "-------------------------------------------------------------------------"
echo "Building GeoMesa Spark (~2-5 mins)"
echo "-------------------------------------------------------------------------"
${MAVEN_HOME}/mvn clean install -D skipTests -P python > ~/geomesa/maven_geomesa_spark_build.log

echo "-------------------------------------------------------------------------"
echo "Installing geomesa_pyspark"
echo "-------------------------------------------------------------------------"
/Library/Frameworks/Python.framework/Versions/2.7/bin/python -m pip install ~/geomesa/geomesa-geomesa_2.11-${GEOMESA_VERSION}/geomesa-spark/geomesa_pyspark/target/geomesa_pyspark-${GEOMESA_VERSION}.tar.gz

echo "-------------------------------------------------------------------------"
echo "Starting Hadoop"
echo "-------------------------------------------------------------------------"

# initialise hadoop file store (HDFS)
cd ${HADOOP_HOME}
bin/hdfs namenode -format

# start hadoop
sbin/start-dfs.sh
sbin/start-yarn.sh
cd ~

# get HDFS path
TEMP_HDFS_PATH="$(${HADOOP_HOME}/bin/hdfs getconf -confKey fs.defaultFS)"
echo -e "\n# local HDFS path (for temp files)" >> ~/.bash_profile
echo "export HDFS_PATH=${TEMP_HDFS_PATH}" >> ~/.bash_profile
source ~/.bash_profile

echo -e "\n# -----------------------------------------------------------------------" >> ~/.bash_profile
echo "# GEOMESA SETTINGS - end" >> ~/.bash_profile
echo "# -----------------------------------------------------------------------" >> ~/.bash_profile

duration=${SECONDS}

echo "-------------------------------------------------------------------------"
echo "GeoMesa install finished in $((${duration} / 60))m $((${duration} % 60))s"
echo "-------------------------------------------------------------------------"

## commands to stop Hadoop + YARN
#cd ${HADOOP_HOME}
#sbin/stop-dfs.sh
#sbin/stop-yarn.sh
#cd ~
