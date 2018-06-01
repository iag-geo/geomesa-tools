#!/usr/bin/env bash

# RUN THESE ON THE EMR MASTER SERVER, ONE AT A TIME

# install GeoMesa and it's dependencies (takes 8-10 mins)
. install-geomesa.sh

# run the pyspark script to convert GDELT raw data into GeoMesa parquet
spark-submit \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar \
geomesa_convert.py --target-s3-bucket <your output s3 bucket>



# USEFUL DEBUGGING STUFF

## look at the filtered temp file on HDFS
#hadoop fs -cat /tmp/geomesa_ingest/*.csv | head -20
