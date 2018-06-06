#!/usr/bin/env bash

#----------------------------------------------------------------------------------------------------------------------
#
# Purpose: copies required files to the EMR master server and logs in via SSH
#
# Organisation: IAG
# Author: Hugh Saalmans, Product Innovation
# GitHub: iag-geo
#
# Copyright:
#  - Code is copyright IAG - licensed under an Apache License, version 2.0
#
#----------------------------------------------------------------------------------------------------------------------

# set your IP address
#ip_address="<your EMR master server IP address>"
ip_address="18.204.9.33"

# set the path to your EC2 key pair's pem file
#pem_file="<full path to your pem file>"
pem_file="/Users/hugh/.ssh/aws/life360-emr-us.pem"

# get this script's directory
file_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# copy the following files to EMR master server
#   geomesa_convert.py : Pyspark script to load, convert and query the data
#   gdelt.conf         : GeoMesa SimpleFeatureType and Converter definitions for the data
#   install-geomesa.sh : GeoMesa FileSystem Datastore & GeoMesa Spark install script
scp -i ${pem_file} ${file_dir}/master_server_files/* hadoop@${ip_address}:~/

# TESTING ONLY - copy geoserver install and service files
#   geoserver            : Geoserver service file
#   install-geoserver.sh : Geoserver install script
scp -i ${pem_file} ${file_dir}/geoserver_files/* hadoop@${ip_address}:~/

# ssh into master EMR server
ssh -i ${pem_file} hadoop@${ip_address}




spark-submit --master yarn --jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar geomesa_convert.py --target-s3-bucket loceng-life360-us