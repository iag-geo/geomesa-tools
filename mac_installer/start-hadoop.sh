#!/usr/bin/env bash

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
