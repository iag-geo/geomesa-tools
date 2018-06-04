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
ip_address="<your EMR master server IP address>"

# set the path to your EC2 key pair's pem file
pem_file="<full path to your pem file>"

# get this script's directory
file_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# copy the following files to EMR master server
#   geomesa_convert.py : Pyspark script to load, convert and query the data
#   gdelt.conf         : GeoMesa SimpleFeatureType and Converter definitions for the data
#   install-geomesa.sh : GeoMesa FileSystem Datastore & GeoMesa Spark install script
scp -i ${pem_file} ${file_dir}/master_server_files/* hadoop@${ip_address}:~/

# ssh into master EMR server
ssh -i ${pem_file} hadoop@${ip_address}
