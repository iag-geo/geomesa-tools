#!/usr/bin/env bash

#----------------------------------------------------------------------------------------------------------------------
#
# Purpose: Installs GeoMesa FileSystem Datastore and GeoMesa Spark on AWS Elastic Map Reduce
#
# Organisation: IAG
# Author: Hugh Saalmans, Product Innovation
# GitHub: iag-geo
#
# Copyright:
#  - Code is copyright IAG - licensed under an Apache License, version 2.0
#
#----------------------------------------------------------------------------------------------------------------------

# record how long this script takes (8-10 mins usually)
SECONDS=0

echo "-------------------------------------------------------------------------"
echo "Setting server environment"
echo "-------------------------------------------------------------------------"

# install tmux (for keeping a session going after logging out)
#   - 'tmux' to create a new session
#   - 'Ctrl-b' and then 'd' to disconnect and keep the session running
#   - 'tmux attach' to get back in
sudo yum -y install tmux

# add paths to .bashrc
cd ~

echo -e "\n# Pyspark paths" >> .bashrc
echo "export SPARK_HOME=/usr/lib/spark" >> .bashrc
source .bashrc

#echo "export PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.4-src.zip" >> .bashrc

echo -e "\n# Hadoop paths" >> .bashrc
echo "export HADOOP_HOME=/usr/lib/hadoop" >> .bashrc
echo "export HADOOP_CONF_DIR=/etc/hadoop/conf" >> .bashrc

# get HDFS path
TEMP_HDFS_PATH="$(hdfs getconf -confKey fs.defaultFS)"
echo "export HDFS_PATH=${TEMP_HDFS_PATH}" >> .bashrc

echo -e "\n# GeoMesa variables" >> .bashrc
echo "export GEOMESA_VERSION=2.0.1" >> .bashrc
echo "export MAVEN_VERSION=3.5.3" >> .bashrc
source .bashrc

# set Hadoop environment
. /etc/hadoop/conf/hadoop-env.sh
. /etc/hadoop/conf/yarn-env.sh

# reduce Spark logging to warnings and above (i.e no INFO or DEBUG messages)
sudo cp $SPARK_HOME/conf/log4j.properties.template $SPARK_HOME/conf/log4j.properties
sudo sed -i -e "s/log4j.rootCategory=INFO, console/log4j.rootCategory=WARN, console/g" $SPARK_HOME/conf/log4j.properties

# download and install GeoMesa FileSystem Datastore
echo "-------------------------------------------------------------------------"
echo "Installing GeoMesa FileSystem Datastore"
echo "-------------------------------------------------------------------------"
wget "https://github.com/locationtech/geomesa/releases/download/geomesa_2.11-$GEOMESA_VERSION/geomesa-fs_2.11-$GEOMESA_VERSION-bin.tar.gz"
tar xzf geomesa-fs_2.11-$GEOMESA_VERSION-bin.tar.gz
sudo mv geomesa-fs_2.11-$GEOMESA_VERSION /usr/local/geomesa-fs_2.11-$GEOMESA_VERSION
rm geomesa-fs_2.11-$GEOMESA_VERSION-bin.tar.gz
echo "export GEOMESA_FS_HOME=/usr/local/geomesa-fs_2.11-$GEOMESA_VERSION" >> .bashrc
source .bashrc
echo "export PATH=$GEOMESA_FS_HOME/bin:$PATH" >> .bashrc
source .bashrc

# install maven to build GeoMesa Spark
echo "-------------------------------------------------------------------------"
echo "Installing Maven"
echo "-------------------------------------------------------------------------"
wget "http://mirror.olnevhost.net/pub/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz"
tar xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
sudo mv apache-maven-$MAVEN_VERSION /usr/local/apache-maven-$MAVEN_VERSION
rm apache-maven-$MAVEN_VERSION-bin.tar.gz
echo -e "\n# add maven to PATH" >> .bashrc
echo "export PATH=/usr/local/apache-maven-$MAVEN_VERSION/bin:$PATH" >> .bashrc
source .bashrc

echo "-------------------------------------------------------------------------"
echo "Downloading GeoMesa Source Code"
echo "-------------------------------------------------------------------------"
wget "https://github.com/locationtech/geomesa/archive/geomesa_2.11-$GEOMESA_VERSION.tar.gz"
tar xzf geomesa_2.11-$GEOMESA_VERSION.tar.gz
rm geomesa_2.11-$GEOMESA_VERSION.tar.gz

# copy license info to geomesa-spark directory to enable maven build
cd /home/hadoop/geomesa-geomesa_2.11-$GEOMESA_VERSION/geomesa-spark
cp -R /home/hadoop/geomesa-geomesa_2.11-$GEOMESA_VERSION/build ./build/

echo "-------------------------------------------------------------------------"
echo "Building GeoMesa Spark"
echo "-------------------------------------------------------------------------"
mvn clean install -P python > ~/maven_geomesa_spark_build.log

echo "-------------------------------------------------------------------------"
echo "Installing geomesa_pyspark"
echo "-------------------------------------------------------------------------"
sudo pip install /home/hadoop/geomesa-geomesa_2.11-$GEOMESA_VERSION/geomesa-spark/geomesa_pyspark/target/geomesa_pyspark-$GEOMESA_VERSION.tar.gz

cd ~

duration=$SECONDS
echo "-------------------------------------------------------------------------"
echo "GeoMesa install finished in $(($duration / 60))m $(($duration % 60))s"
echo "-------------------------------------------------------------------------"
