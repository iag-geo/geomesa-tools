#!/usr/bin/env bash


#spark-submit \
#--master yarn \
#--deploy-mode cluster \
#--conf spark.GEOMESA_VERSION=$GEOMESA_VERSION \
#--conf spark.SPARK_HOME=SPARK_HOME \
#--conf spark$GEOMESA_FS_HOME.=$GEOMESA_FS_HOME \
#--conf spark.$HDFS_PATH=$HDFS_PATH \
#--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar \
#--py-files ~/geomesa/geomesa-geomesa_2.11-$GEOMESA_VERSION/geomesa-spark/geomesa_pyspark/target/geomesa_pyspark-$GEOMESA_VERSION.tar.gz \
#/Users/hugh.saalmans/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ~/tmp/geomesa_test



spark-submit \
--master local \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar \
~/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ~/tmp/geomesa_test



spark-submit \
--master local \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar,$SPARK_HOME/jars/hadoop-aws-$HADOOP_VERSION.jar,$SPARK_HOME/jars/aws-java-sdk-1.7.4.jar \
--py-files ~/geomesa/geomesa-geomesa_2.11-$GEOMESA_VERSION/geomesa-spark/geomesa_pyspark/target/geomesa_pyspark-$GEOMESA_VERSION.tar.gz \
~/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ~/tmp/geomesa_test


spark-submit \
--master yarn \
--deploy-mode cluster \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar,$SPARK_HOME/jars/hadoop-aws-$HADOOP_VERSION.jar,$SPARK_HOME/jars/aws-java-sdk-1.7.4.jar \
--py-files ~/geomesa/geomesa-geomesa_2.11-$GEOMESA_VERSION/geomesa-spark/geomesa_pyspark/target/geomesa_pyspark-$GEOMESA_VERSION.tar.gz \
~/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ~/tmp/geomesa_test


--class org.apache.hadoop.fs.s3a.S3AFileSystem \


spark-submit --master yarn --deploy-mode client --jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar /Users/hugh.saalmans/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ~/tmp/geomesa_test

spark-submit --master local --jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar /Users/hugh.saalmans/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ~/tmp/geomesa_test

# PI test - works!
spark-submit --class org.apache.spark.examples.SparkPi --master local $SPARK_HOME/examples/jars/spark-examples_2.11-2.3.1.jar 10

spark-submit --class org.apache.spark.examples.SparkPi --master yarn --deploy-mode cluster $SPARK_HOME/examples/jars/spark-examples_2.11-2.3.1.jar 10

# check hadoop is ok
$HADOOP_HOME/bin/hadoop fs -ls

