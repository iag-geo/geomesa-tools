#!/usr/bin/env bash


# Add Geoserver environment vars for hadoop user
cd ~
echo -e "\n# Geoserver variables" >> .bashrc
echo "export GEOSERVER_VERSION=2.13.1" >> .bashrc
source ~/.bashrc
echo "export GEOSERVER_HOME=/usr/share/geoserver-$GEOSERVER_VERSION" >> .bashrc
source ~/.bashrc

# Add Geoserver home to service file (won't be able to use any user vars)
sudo sed -i -e "s|case |export JAVA_HOME=${JAVA_HOME}\nexport GEOSERVER_HOME=${GEOSERVER_HOME}\n\ncase |g" geoserver

# download and unzip
wget "https://sourceforge.net/projects/geoserver/files/GeoServer/$GEOSERVER_VERSION/geoserver-$GEOSERVER_VERSION-bin.zip"
unzip geoserver-$GEOSERVER_VERSION-bin.zip
sudo mv geoserver-$GEOSERVER_VERSION $GEOSERVER_HOME
rm geoserver-$GEOSERVER_VERSION-bin.zip

# set ownership of directory
sudo chown -R hadoop $GEOSERVER_HOME

# change port number from the default - already in use
sudo sed -i -e "s/jetty.port=8080/jetty.port=2040/g" $GEOSERVER_HOME/start.ini

# move the service file to init.d and set permissions
# NOT WORKING - doesn't run as a daemon
sudo mv geoserver /etc/init.d/
chmod 0755 /etc/init.d/geoserver
sudo service geoserver start




#. $GEOSERVER_HOME/bin/startup.sh



#
# Copyright (c) 2013-2016 Commonwealth Computer Research, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0 which
# accompanies this distribution and is available at
# http://www.opensource.org/licenses/apache2.0.php.
#

# This script will attempt to install the client dependencies for hadoop
# into a given directory. Usually this is used to install the deps into either the
# geomesa tools lib dir or the WEB-INF/lib dir of geoserver.

hadoop_version="2.8.3"
hadoop_version_min="2.8.3"

# for hadoop 2.5 and 2.6 to work we need these
# These should match up to what the hadoop version desires
guava_version="11.0.2"
com_log_version="1.1.3"
aws_sdk_version="1.11.267"
commons_config_version="1.6"
htrace_version="4.0.1-incubating"

# this should match the parquet desired version
snappy_version="1.0.4.1"

# Load common functions and setup
if [ -z "${GEOMESA_FS_HOME}" ]; then
  export GEOMESA_FS_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi
. $GEOMESA_FS_HOME/bin/common-functions.sh

install_dir="${1:-${GEOMESA_FS_HOME}/lib}"

# Resource download location
base_url="${GEOMESA_MAVEN_URL:-https://search.maven.org/remotecontent?filepath=}"

declare -a urls=(
  "${base_url}org/apache/hadoop/hadoop-auth/${hadoop_version}/hadoop-auth-${hadoop_version}.jar"
  "${base_url}org/apache/hadoop/hadoop-client/${hadoop_version}/hadoop-client-${hadoop_version}.jar"
  "${base_url}org/apache/hadoop/hadoop-common/${hadoop_version}/hadoop-common-${hadoop_version}.jar"
  "${base_url}org/apache/hadoop/hadoop-hdfs/${hadoop_version}/hadoop-hdfs-${hadoop_version}.jar"
  "${base_url}org/apache/hadoop/hadoop-aws/${hadoop_version}/hadoop-aws-${hadoop_version}.jar"
  "${base_url}org/apache/htrace/htrace-core4/${htrace_version}/htrace-core-${htrace_version}.jar"
  "${base_url}com/amazonaws/aws-java-sdk/${aws_sdk_version}/aws-java-sdk-${aws_sdk_version}.jar"
  "${base_url}org/xerial/snappy/snappy-java/${snappy_version}/snappy-java-${snappy_version}.jar"
  "${base_url}commons-configuration/commons-configuration/${commons_config_version}/commons-configuration-${commons_config_version}.jar"
  "${base_url}commons-logging/commons-logging/${com_log_version}/commons-logging-${com_log_version}.jar"
  "${base_url}commons-cli/commons-cli/1.2/commons-cli-1.2.jar"
  "${base_url}com/google/protobuf/protobuf-java/2.5.0/protobuf-java-2.5.0.jar"
  "${base_url}commons-io/commons-io/2.5/commons-io-2.5.jar"
  "${base_url}org/apache/httpcomponents/httpclient/4.3.4/httpclient-4.3.4.jar"
  "${base_url}org/apache/httpcomponents/httpcore/4.3.3/httpcore-4.3.3.jar"
  "${base_url}commons-httpclient/commons-httpclient/3.1/commons-httpclient-3.1.jar"
)

# if there's already a guava jar (e.g. geoserver) don't install guava to avoid conflicts
if [ -z "$(find $install_dir -maxdepth 1 -name 'guava-*' -print -quit)" ]; then
  urls+=("${base_url}com/google/guava/guava/${guava_version}/guava-${guava_version}.jar")
fi

downloadUrls "$install_dir" urls[@]