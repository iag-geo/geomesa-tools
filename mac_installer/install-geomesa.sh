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
#----------------------------------------------------------------------------------------------------------------------

# record how long this script takes (8-10 mins usually)
SECONDS=0

echo -e "\n# -----------------------------------------------------------------------" >> ~/.bash_profile
echo "# GEOMESA SETTINGS - start" >> ~/.bash_profile
echo "# -----------------------------------------------------------------------" >> ~/.bash_profile

echo "-------------------------------------------------------------------------"
echo "Installing Apache Spark and Python modules"
echo "-------------------------------------------------------------------------"
brew cask install java8
brew install scala
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

echo -e "\n# Java home" >> ~/.bash_profile
echo "export JAVA_HOME=/library/Java/Home" >> ~/.bash_profile

echo -e "\n# Spark path" >> ~/.bash_profile
echo "export SPARK_HOME=/usr/local/Cellar/apache-spark/2.3.1/libexec" >> ~/.bash_profile
#echo "export PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip" >> ~/.bash_profile
source ~/.bash_profile

#echo -e "\n# Hadoop paths" >> ~/.bash_profile
#echo "export HADOOP_HOME=/usr/lib/hadoop" >> ~/.bash_profile
#echo "export HADOOP_CONF_DIR=/etc/hadoop/conf" >> ~/.bash_profile

## get HDFS path
#TEMP_HDFS_PATH="$(hdfs getconf -confKey fs.defaultFS)"
#echo "export HDFS_PATH=${TEMP_HDFS_PATH}" >> ~/.bash_profile

echo -e "\n# GeoMesa variables" >> ~/.bash_profile
echo "export GEOMESA_VERSION=2.0.2" >> ~/.bash_profile
echo "export MAVEN_VERSION=3.5.3" >> ~/.bash_profile
source ~/.bash_profile

## set Hadoop environment
#. /etc/hadoop/conf/hadoop-env.sh
#. /etc/hadoop/conf/yarn-env.sh

# reduce Spark logging to warnings and above (i.e no INFO or DEBUG messages)
cp $SPARK_HOME/conf/log4j.properties.template $SPARK_HOME/conf/log4j.properties
sed -i -e "s/log4j.rootCategory=INFO, console/log4j.rootCategory=WARN, console/g" $SPARK_HOME/conf/log4j.properties

# create new directory to put geomesa in
mkdir ~/geomesa
cd ~/geomesa

# download and install GeoMesa FileSystem Datastore
echo "-------------------------------------------------------------------------"
echo "Installing GeoMesa FileSystem Datastore"
echo "-------------------------------------------------------------------------"
curl -L "https://github.com/locationtech/geomesa/releases/download/geomesa_2.11-$GEOMESA_VERSION/geomesa-fs_2.11-$GEOMESA_VERSION-bin.tar.gz" -o "geomesa-fs_2.11-$GEOMESA_VERSION-bin.tar.gz"
tar xzf geomesa-fs_2.11-$GEOMESA_VERSION-bin.tar.gz
#sudo mv geomesa-fs_2.11-$GEOMESA_VERSION /usr/local/geomesa-fs_2.11-$GEOMESA_VERSION
rm geomesa-fs_2.11-$GEOMESA_VERSION-bin.tar.gz
echo "export GEOMESA_FS_HOME=~/geomesa/geomesa-fs_2.11-$GEOMESA_VERSION" >> ~/.bash_profile
#source ~/.bash_profile
#echo "export PATH=$GEOMESA_FS_HOME/bin:${PATH}" >> ~/.bash_profile
source ~/.bash_profile

# install maven to build GeoMesa Spark
echo "-------------------------------------------------------------------------"
echo "Installing Maven"
echo "-------------------------------------------------------------------------"
curl -L "http://mirror.olnevhost.net/pub/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" -o "apache-maven-$MAVEN_VERSION-bin.tar.gz"
tar xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
#sudo mv apache-maven-$MAVEN_VERSION /usr/local/apache-maven-$MAVEN_VERSION
rm apache-maven-$MAVEN_VERSION-bin.tar.gz
echo -e "\n# maven home" >> ~/.bash_profile
echo "export MAVEN_HOME=~/geomesa/apache-maven-$MAVEN_VERSION/bin" >> ~/.bash_profile
source ~/.bash_profile

echo "-------------------------------------------------------------------------"
echo "Downloading GeoMesa Source Code"
echo "-------------------------------------------------------------------------"
curl -L "https://github.com/locationtech/geomesa/archive/geomesa_2.11-$GEOMESA_VERSION.tar.gz" -o "geomesa_2.11-$GEOMESA_VERSION.tar.gz"
tar xzf geomesa_2.11-$GEOMESA_VERSION.tar.gz
rm geomesa_2.11-$GEOMESA_VERSION.tar.gz

# copy license info to geomesa-spark directory to enable maven build
cd ~/geomesa/geomesa-geomesa_2.11-$GEOMESA_VERSION/geomesa-spark
cp -R ~/geomesa/geomesa-geomesa_2.11-$GEOMESA_VERSION/build ./build/

echo "-------------------------------------------------------------------------"
echo "Building GeoMesa Spark (~3 mins)"
echo "-------------------------------------------------------------------------"
$MAVEN_HOME/mvn clean install -D skipTests -P python > ~/geomesa/maven_geomesa_spark_build.log

echo "-------------------------------------------------------------------------"
echo "Installing geomesa_pyspark"
echo "-------------------------------------------------------------------------"
/Library/Frameworks/Python.framework/Versions/2.7/bin/python -m pip install ~/geomesa/geomesa-geomesa_2.11-$GEOMESA_VERSION/geomesa-spark/geomesa_pyspark/target/geomesa_pyspark-$GEOMESA_VERSION.tar.gz

echo -e "\n# -----------------------------------------------------------------------" >> ~/.bash_profile
echo "# GEOMESA SETTINGS - end" >> ~/.bash_profile
echo "# -----------------------------------------------------------------------" >> ~/.bash_profile

cd ~

duration=$SECONDS
echo "-------------------------------------------------------------------------"
echo "GeoMesa install finished in $(($duration / 60))m $(($duration % 60))s"
echo "-------------------------------------------------------------------------"
