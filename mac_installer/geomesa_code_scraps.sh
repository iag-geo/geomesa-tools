#!/usr/bin/env bash


spark-submit --master local[4] \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar \
~/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ~/tmp/geomesa_test


spark-submit --master yarn \
--deploy-mode cluster \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar \
~/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ~/tmp/geomesa_test


# check hadoop is ok
$HADOOP_HOME/bin/hadoop fs -ls

