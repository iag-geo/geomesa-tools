#!/usr/bin/env bash


# stop Hadoop + YARN
cd ${HADOOP_HOME}
sbin/stop-dfs.sh
sbin/stop-yarn.sh
cd ${HOME}



# start Hadoop + YARN
cd ${HADOOP_HOME}
sbin/start-dfs.sh
sbin/start-yarn.sh
cd ${HOME}


spark-submit --master local[4] \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar \
--conf spark.executorEnv.GEOMESA_FS_HOME=${GEOMESA_FS_HOME} \
--conf spark.executorEnv.GEOMESA_VERSION=${GEOMESA_VERSION} \
--conf spark.executorEnv.HDFS_PATH=${HDFS_PATH} \
${HOME}/git/iag_geo/geomesa_tools/spark/mac_installer/install-geomesa.sh --target-directory ${HOME}/tmp/geomesa_test


spark-submit --master local[4] \
--conf spark.executorEnv.GEOMESA_FS_HOME=${GEOMESA_FS_HOME} \
--conf spark.executorEnv.GEOMESA_VERSION=${GEOMESA_VERSION} \
${HOME}/git/iag_geo/geomesa_tools/spark/mac_installer/geomesa_convert.py --target-directory ${HOME}/tmp/geomesa_test

spark-submit --master local[4] \
${HOME}/git/iag_geo/geomesa_tools/spark/mac_installer/geomesa_convert.py --target-directory ${HOME}/tmp/geomesa_test



spark-submit --master yarn \
--deploy-mode cluster \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar \
${HOME}/git/iag_geo/geomesa_tools/spark/mac_installer/geomesa_convert.py --target-directory ${HOME}/tmp/geomesa_test


# check hadoop files
$HADOOP_HOME/bin/hadoop fs -ls hdfs://127.0.0.1/user/temp/geomesa_ingest

$HADOOP_HOME/bin/hadoop fs -cat hdfs://127.0.0.1/user/temp/geomesa_ingest/part-00000-637ad761-6e55-4143-8130-8f8e3ab56446-c000.csv | head



# check file exists in AWS
aws --profile minus34 s3 cp s3://gdelt-open-data/events/20170501.export.csv ~/tmp

s3://gdelt-open-data/events/20170501.export.csv
s3://gdelt-open-data/events/20170501.export.csv

# get AWS IAM user ID
aws iam get-user --user-name USERNAME


spark-submit --master local \
--conf spark.executorEnv.GEOMESA_VERSION="${GEOMESA_VERSION}" \
${HOME}/git/iag_geo/geomesa_tools/spark/mac_installer/test.py




--conf spark.executorEnv.GEOMESA_VERSION=hello \
