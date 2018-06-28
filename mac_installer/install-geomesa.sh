#!/usr/bin/env bash

#----------------------------------------------------------------------------------------------------------------------
#
#  THIS DOES NOT WORK (YET)
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

# record how long this script takes (8-10 mins usually)
SECONDS=0

# setup SSH key pair for hadoop to connect to localhost
echo | ssh-keygen -t rsa -P ""
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# use wget to download files
brew install wget

# create new directory to put geomesa in
mkdir ~/geomesa
cd ~/geomesa

echo -e "\n# -----------------------------------------------------------------------" >> ~/.bash_profile
echo "# GEOMESA SETTINGS - start" >> ~/.bash_profile
echo "# -----------------------------------------------------------------------" >> ~/.bash_profile

echo -e "\n# version numbers" >> ~/.bash_profile
echo "export GEOMESA_VERSION=2.0.2" >> ~/.bash_profile
echo "export MAVEN_VERSION=3.5.3" >> ~/.bash_profile
echo "export HADOOP_VERSION=2.8.4" >> ~/.bash_profile
source ~/.bash_profile

echo "-------------------------------------------------------------------------"
echo "Installing Apache Spark and Python modules"
echo "-------------------------------------------------------------------------"
brew cask install java8
brew install scala@2.11
brew install apache-spark

/Library/Frameworks/Python.framework/Versions/2.7/bin/python -m pip install --upgrade pip
/Library/Frameworks/Python.framework/Versions/2.7/bin/python -m pip install py4j
#/Library/Frameworks/Python.framework/Versions/2.7/bin/python -m pip install -I py4j==0.10.4
#/Library/Frameworks/Python.framework/Versions/2.7/bin/python -m pip install pytz
#/Library/Frameworks/Python.framework/Versions/2.7/bin/python -m pip install pyspark

echo "-------------------------------------------------------------------------"
echo "Setting server environment"
echo "-------------------------------------------------------------------------"

# add paths to ~/.bash_profile

echo -e "\n# Java & Scala paths" >> ~/.bash_profile
echo "export JAVA_HOME=/library/Java/Home" >> ~/.bash_profile
echo "export SCALA_HOME=/usr/local/opt/scala@2.11" >> ~/.bash_profile

echo -e "\n# Spark path" >> ~/.bash_profile
echo "export SPARK_HOME=/usr/local/Cellar/apache-spark/2.3.1/libexec" >> ~/.bash_profile
#echo "export PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip" >> ~/.bash_profile
source ~/.bash_profile

# reduce Spark logging to warnings and above (i.e no INFO or DEBUG messages)
cp $SPARK_HOME/conf/log4j.properties.template $SPARK_HOME/conf/log4j.properties
sed -i -e "s/log4j.rootCategory=INFO, console/log4j.rootCategory=WARN, console/g" $SPARK_HOME/conf/log4j.properties

echo "-------------------------------------------------------------------------"
echo "Installing Hadoop"
echo "-------------------------------------------------------------------------"
wget http://apache.mirror.amaze.com.au/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz
tar xzf hadoop-$HADOOP_VERSION.tar.gz
rm hadoop-$HADOOP_VERSION.tar.gz

echo -e "\n# Hadoop paths" >> ~/.bash_profile
echo "export HADOOP_HOME=~/geomesa/hadoop-$HADOOP_VERSION" >> ~/.bash_profile
source ~/.bash_profile
echo "export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop" >> ~/.bash_profile
source ~/.bash_profile

# set Hadoop environment
sed -i -e "s%</configuration>%<property><name>fs.defaultFS</name><value>hdfs://localhost/</value></property></configuration>%g" $HADOOP_CONF_DIR/core-site.xml
sed -i -e "s%</configuration>%<property><name>dfs.replication</name><value>1</value></property></configuration>%g" $HADOOP_CONF_DIR/hdfs-site.xml
sed -i -e "s%</configuration>%<property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property></configuration>%g" $HADOOP_CONF_DIR/yarn-site.xml
cp $HADOOP_CONF_DIR/mapred-site.xml.template $HADOOP_CONF_DIR/mapred-site.xml
sed -i -e "s%</configuration>%<property><name>mapreduce.framework.name</name> <value>yarn</value></property></configuration>%g" $HADOOP_CONF_DIR/mapred-site.xml

#. $HADOOP_CONF_DIR/hadoop-env.sh
#. $HADOOP_CONF_DIR/yarn-env.sh

# download and install GeoMesa FileSystem Datastore
echo "-------------------------------------------------------------------------"
echo "Installing GeoMesa FileSystem Datastore"
echo "-------------------------------------------------------------------------"
wget "https://github.com/locationtech/geomesa/releases/download/geomesa_2.11-$GEOMESA_VERSION/geomesa-fs_2.11-$GEOMESA_VERSION-bin.tar.gz"
tar xzf geomesa-fs_2.11-$GEOMESA_VERSION-bin.tar.gz
#sudo mv geomesa-fs_2.11-$GEOMESA_VERSION /usr/local/geomesa-fs_2.11-$GEOMESA_VERSION
rm geomesa-fs_2.11-$GEOMESA_VERSION-bin.tar.gz
echo -e "\n# Geomesa FileStore path" >> ~/.bash_profile
echo "export GEOMESA_FS_HOME=~/geomesa/geomesa-fs_2.11-$GEOMESA_VERSION" >> ~/.bash_profile
#source ~/.bash_profile
#echo "export PATH=$GEOMESA_FS_HOME/bin:${PATH}" >> ~/.bash_profile
source ~/.bash_profile

# install maven to build GeoMesa Spark
echo "-------------------------------------------------------------------------"
echo "Installing Maven"
echo "-------------------------------------------------------------------------"
wget "http://mirror.olnevhost.net/pub/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz"
tar xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
#sudo mv apache-maven-$MAVEN_VERSION /usr/local/apache-maven-$MAVEN_VERSION
rm apache-maven-$MAVEN_VERSION-bin.tar.gz
echo -e "\n# maven home" >> ~/.bash_profile
echo "export MAVEN_HOME=~/geomesa/apache-maven-$MAVEN_VERSION/bin" >> ~/.bash_profile
source ~/.bash_profile

echo "-------------------------------------------------------------------------"
echo "Downloading GeoMesa Source Code"
echo "-------------------------------------------------------------------------"
wget "https://github.com/locationtech/geomesa/archive/geomesa_2.11-$GEOMESA_VERSION.tar.gz"
tar xzf geomesa_2.11-$GEOMESA_VERSION.tar.gz
rm geomesa_2.11-$GEOMESA_VERSION.tar.gz

# copy license info to geomesa-spark directory to enable maven build
cd ~/geomesa/geomesa-geomesa_2.11-$GEOMESA_VERSION/geomesa-spark
cp -R ~/geomesa/geomesa-geomesa_2.11-$GEOMESA_VERSION/build ./build/

echo "-------------------------------------------------------------------------"
echo "Building GeoMesa Spark (~5-10 mins)"
echo "-------------------------------------------------------------------------"
$MAVEN_HOME/mvn clean install -D skipTests -P python > ~/geomesa/maven_geomesa_spark_build.log

echo "-------------------------------------------------------------------------"
echo "Installing geomesa_pyspark"
echo "-------------------------------------------------------------------------"
/Library/Frameworks/Python.framework/Versions/2.7/bin/python -m pip install ~/geomesa/geomesa-geomesa_2.11-$GEOMESA_VERSION/geomesa-spark/geomesa_pyspark/target/geomesa_pyspark-$GEOMESA_VERSION.tar.gz

echo -e "\n# -----------------------------------------------------------------------" >> ~/.bash_profile
echo "# GEOMESA SETTINGS - end" >> ~/.bash_profile
echo "# -----------------------------------------------------------------------" >> ~/.bash_profile

echo "-------------------------------------------------------------------------"
echo "Starting Hadoop"
echo "-------------------------------------------------------------------------"

# create hadoop file store (HDFS)
cd $HADOOP_HOME
bin/hdfs namenode -format

# start hadoop
cd $HADOOP_HOME/sbin
. start-dfs.sh
. start-yarn.sh

# create folders in HDFS
$HADOOP_HOME/bin/hdfs dfs -mkdir /user
$HADOOP_HOME/bin/hdfs dfs -mkdir /user/temp

# get HDFS path
TEMP_HDFS_PATH="$($HADOOP_HOME/bin/hdfs getconf -confKey fs.defaultFS)"
echo "export HDFS_PATH=${TEMP_HDFS_PATH}" >> ~/.bash_profile
source ~/.bash_profile

cd ~

duration=$SECONDS
echo "-------------------------------------------------------------------------"
echo "GeoMesa install finished in $(($duration / 60))m $(($duration % 60))s"
echo "-------------------------------------------------------------------------"


