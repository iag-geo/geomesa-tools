""" -------------------------------------------------------------------------------------------------------------------

Purpose: Takes GDELT data on S3, filters it & converts it to GeoMesa Parquet using Pyspark on an AWS EMR instance

Workflow:
  1. create Spark dataframe from delimited text files on S3
  2. filter data using SparkSQL and output to temp HDFS directory as delimited text
  3. convert temp HDFS data into GeoMesa parquet format and output to S3

Organisation: IAG
Author: Hugh Saalmans, Product Innovation
GitHub: iag-geo

Copyright:
  - Code is copyright IAG - licensed under an Apache License, version 2.0

Notes:
  - Code loads the data one day at a time; for testing on small EMR instances (e.g. 1 master, 2 core servers)
  - Takes 3-4 mins per day of data on a 3 server cluster (1 master, 2 core servers)

------------------------------------------------------------------------------------------------------------------- """

import argparse
import datetime
import geomesa_pyspark
import os
import logging

from pyspark.sql import SparkSession
from subprocess import check_output


def main():
    start_time = datetime.datetime.now()

    parser = argparse.ArgumentParser(
        description='Takes GDELT data on S3, filters it & converts it to GeoMesa Parquet format '
                    'using Pyspark on an AWS EMR instance')

    parser.add_argument(
        '--target-s3-bucket', help='The S3 bucket for the output GeoMesa Parquet files')

    args = parser.parse_args()

    settings = dict()

    # Spark & GeoMesa environment vars
    settings["home"] = os.environ["HOME"]
    settings["spark_home"] = os.environ["SPARK_HOME"]
    settings["hdfs_path"] = os.environ["HDFS_PATH"]
    settings["geomesa_version"] = os.environ["GEOMESA_VERSION"]
    settings["geomesa_fs_home"] = os.environ["GEOMESA_FS_HOME"]

    # -----------------------------------------------------------------------------------------------------------------
    # Edit these to taste (feel free to convert these to runtime arguments)
    # -----------------------------------------------------------------------------------------------------------------

    # date range of data to convert
    settings["start_date"] = "2017-05-01"
    settings["end_date"] = "2017-05-02"

    # name of the GeoMesa schema, aka feature name
    settings["geomesa_schema"] = "gdelt"

    # SimpleFeatureType & Converter - can be an existing sft or a config file
    settings["sft_config"] = "{}/gdelt.conf".format(settings["home"],)
    settings["sft_converter"] = "{}/gdelt.conf".format(settings["home"],)

    # GeoMesa partition schema to use, note: leaf storage is set to true
    settings["partition_schema"] = "daily,z2-4bit"

    # file format settings
    settings["source_format"] = "csv"
    settings["source_delimiter"] = "\t"
    settings["source_header"] = "false"

    # AWS S3 & EMR settings
    settings["source_s3_bucket"] = "gdelt-open-data"
    settings["source_s3_directory"] = "events"

    settings["target_s3_bucket"] = args.target_s3_bucket
    settings["target_s3_directory"] = "geomesa_test"

    # number of reducers for GeoMesa ingest (determines how the reduce tasks get split up)
    settings["num_reducers"] = 16

    # the name of the view created from the input dataframe
    settings["input_view"] = "raw_data"

    # filter data by Australia
    settings["sql"] = """SELECT * FROM {}
                           WHERE _c39 > -43.9 AND _c39 < -9.1
                           AND _c40 > 112.8 AND _c40 < 154.0""".format(settings["input_view"],)

    # -----------------------------------------------------------------------------------------------------------------

    # set path to GeoMesa FileSystem Datastore Spark JAR
    settings["geomesa_fs_spark_jar"] = "{}/dist/spark/geomesa-fs-spark-runtime_2.11-{}.jar"\
        .format(settings["geomesa_fs_home"], settings["geomesa_version"])

    # set S3 and HDFS paths - must use the s3a:// prefix for S3 files
    settings["source_s3_path"] = "s3a://{}/{}".format(settings["source_s3_bucket"], settings["source_s3_directory"])
    settings["temp_hdfs_path"] = "{}/tmp/geomesa_ingest".format(settings["hdfs_path"], )
    settings["target_s3_path"] = "s3a://{}/{}".format(settings["target_s3_bucket"], settings["target_s3_directory"])

    # The GeoMesa ingest Bash command
    settings["ingest_command_line"] = """{0}/bin/geomesa-fs ingest \
                                            --path '{1}' \
                                            --encoding parquet \
                                            --feature-name {2} \
                                            --spec {3} \
                                            --converter {4} \
                                            --partition-scheme {5} \
                                            --leaf-storage true \
                                            --num-reducers {6} \
                                            '{7}/*.csv'""" \
        .format(settings["geomesa_fs_home"], settings["target_s3_path"], settings["geomesa_schema"],
                settings["sft_config"], settings["sft_converter"], settings["partition_schema"],
                settings["num_reducers"], settings["temp_hdfs_path"])

    # 1 - create a Spark session
    spark = get_spark_session(settings)
    logger.info("Pyspark session initiated : {}".format(datetime.datetime.now() - start_time,))

    # 2 - convert text files on S3 to GeoMesa parquet files on S3
    convert_to_geomesa_parquet(settings, spark)

    # 3 - create a geomesa dataframe and run a spatial query on it
    run_geomesa_query(settings, spark)

    spark.stop()


def get_spark_session(settings):
    # set Spark config
    conf = geomesa_pyspark.configure(
        jars=[settings["geomesa_fs_spark_jar"]],
        packages=["geomesa_pyspark", "pytz"],
        spark_home=settings["spark_home"]) \
        .setAppName("geoMesa conversion test")

    conf.set("spark.hadoop.fs.s3.fast.upload", "true")
    conf.set("spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version", "2")
    conf.set("spark.speculation", "false")
    conf.set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
    conf.set("spark.kryo.registrator", "org.locationtech.geomesa.spark.GeoMesaSparkKryoRegistrator")
    # conf.set("spark.shuffle.service.enabled", "true")
    # conf.set("spark.dynamicAllocation.enabled", "true")

    conf.get("spark.master")

    # create the SparkSession
    spark = SparkSession \
        .builder \
        .config(conf=conf) \
        .enableHiveSupport() \
        .getOrCreate()

    return spark


def convert_to_geomesa_parquet(settings, spark):
    # convert start and end date strings to dates
    start_date = datetime.datetime.strptime(settings["start_date"], '%Y-%m-%d')
    end_date = datetime.datetime.strptime(settings["end_date"], '%Y-%m-%d')

    current_date = start_date

    # for each day...
    # create a view of the input data, filter it, output it to HDFS, convert into to GeoMesa parquet and output to S3
    while current_date <= end_date:
        day_start_time = datetime.datetime.now()

        date_string = current_date.strftime('%Y-%m-%d')
        yyyy_mm_dd = date_string.split("-")

        logger.info("{} : START".format(date_string, ))

        # e.g. 's3a://gdelt-open-data/events/20180301*'
        source_file_path = "{}/{}{}{}*" \
            .format(settings["source_s3_path"], yyyy_mm_dd[0], yyyy_mm_dd[1], yyyy_mm_dd[2])

        get_dataframe_and_view(settings, source_file_path, spark)
        filter_and_output_view(settings, spark)
        convert_data_to_geomesa(settings)

        logger.info("{} : DONE : {}".format(date_string, datetime.datetime.now() - day_start_time))

        current_date += datetime.timedelta(days=1)


def get_dataframe_and_view(settings, source_file_path, spark):
    start_time = datetime.datetime.now()

    # create input dataframe and a temporary view of it
    input_data_frame = spark \
        .read \
        .load(source_file_path,
              format=settings["source_format"],
              delimiter=settings["source_delimiter"],
              header=settings["source_header"])

    input_data_frame.createOrReplaceTempView(settings["input_view"])

    logger.info("\t- view of input data created : {}".format(datetime.datetime.now() - start_time, ))


def filter_and_output_view(settings, spark):
    start_time = datetime.datetime.now()

    # run a SQL statement to prep the data and output result to temp location (HDFS in this example)
    spark.sql(settings["sql"]) \
        .write \
        .save(settings["temp_hdfs_path"],
              mode='overwrite',
              format=settings["source_format"],
              delimiter=settings["source_delimiter"],
              header=settings["source_header"])

    logger.info("\t- data transformed, filtered & written to HDFS : {}".format(datetime.datetime.now() - start_time, ))


def convert_data_to_geomesa(settings):
    start_time = datetime.datetime.now()

    logger.info("\t- start GeoMesa ingest")

    # run GeoMesa command-line ingest
    result = check_output(settings["ingest_command_line"], shell=True).split("\n")

    # log any output - no output=all good!
    for line in result:
        line = line.strip()
        if line is not None and line != "":
            logger.warning(line)

    logger.info("\t- data converted to GeoMesa parquet & written to S3 : {}"
                .format(datetime.datetime.now() - start_time, ))


def run_geomesa_query(settings, spark):
    logger.info("querying GeoMesa dataframe")

    start_time = datetime.datetime.now()

    # create input dataframe and a temporary view of it
    geomesa_data_frame = spark \
        .read \
        .format("geomesa") \
        .option("geomesa.feature", settings["geomesa_schema"]) \
        .option("fs.path", settings["target_s3_path"]) \
        .load()

    geomesa_data_frame.createOrReplaceTempView("points")

    logger.info("\t- points data view created : {}".format(datetime.datetime.now() - start_time, ))
    start_time = datetime.datetime.now()

    spatial_query = """SELECT globalEventId,
                         dtg,
                         actor1Name,
                         actor2Name,
                         st_bufferPoint(geom, 100) AS geom
                         FROM points"""

    # show the query results
    spark.sql(spatial_query).show()

    logger.info("\t- query done : {}".format(datetime.datetime.now() - start_time, ))

    # remove data frame from cache (not sure if required to clean up memory)
    geomesa_data_frame.unpersist()


if __name__ == '__main__':
    full_start_time = datetime.datetime.now()

    logger = logging.getLogger()

    # set logger
    log_file = os.path.abspath(__file__).replace(".py", ".log")
    logging.basicConfig(filename=log_file,
                        level=logging.DEBUG,
                        format="%(asctime)s %(message)s",
                        datefmt="%m/%d/%Y %I:%M:%S %p")
    logging.getLogger('py4j').setLevel(logging.WARNING)
    logging.getLogger('pyspark').setLevel(logging.WARNING)

    # setup logger to write to screen as well as writing to log file
    # define a Handler which writes INFO messages or higher to the sys.stderr
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    # set a format which is simpler for console use
    formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
    # tell the handler to use this format
    console.setFormatter(formatter)
    # add the handler to the root logger
    logging.getLogger('').addHandler(console)

    task_name = "GeoMesa convert"

    logger.info("Start {}".format(task_name))

    main()

    time_taken = datetime.datetime.now() - full_start_time

    logger.info("{0} finished : {1}".format(task_name, time_taken))
