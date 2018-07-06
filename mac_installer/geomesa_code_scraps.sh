#!/usr/bin/env bash


spark-submit --master local[4] \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar \
--conf spark.executorEnv.GEOMESA_FS_HOME=${GEOMESA_FS_HOME} \
--conf spark.executorEnv.GEOMESA_VERSION=${GEOMESA_VERSION} \
--conf spark.executorEnv.HDFS_PATH=${HDFS_PATH} \
${HOME}/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ${HOME}/tmp/geomesa_test



spark-submit --master local[4] \
--conf spark.executorEnv.GEOMESA_FS_HOME=${GEOMESA_FS_HOME} \
--conf spark.executorEnv.GEOMESA_VERSION=${GEOMESA_VERSION} \
${HOME}/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ${HOME}/tmp/geomesa_test

spark-submit --master local[4] \
${HOME}/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ${HOME}/tmp/geomesa_test



spark-submit --master yarn \
--deploy-mode cluster \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar \
${HOME}/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ${HOME}/tmp/geomesa_test


# check hadoop is ok
$HADOOP_HOME/bin/hadoop fs -ls




spark-submit --master local \
--conf spark.executorEnv.GEOMESA_VERSION="${GEOMESA_VERSION}" \
${HOME}/git/iag_geo/geomesa_tools/mac_installer/test.py




--conf spark.executorEnv.GEOMESA_VERSION=hello \
