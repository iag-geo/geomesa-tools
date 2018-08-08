""" -------------------------------------------------------------------------------------------------------------------

Purpose: Takes GDELT data on S3, filters it & converts it to GeoMesa Parquet using Pyspark on a standalone instance

Workflow:
  1. create Spark dataframe from delimited text files on S3
  2. filter data using SparkSQL and output to temp HDFS directory as delimited text
  3. convert temp HDFS data into GeoMesa parquet format and output to a local directory

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
import os
import logging

from pyspark.sql import SparkSession
from subprocess import check_output


def main():
    start_time = datetime.datetime.now()

    parser = argparse.ArgumentParser(
        description='Takes GDELT data on S3, filters it & converts it to GeoMesa Parquet format '
                    'using Pyspark on a standalone instance')

    parser.add_argument(
        '--target-directory', help='A local directory for the output GeoMesa Parquet files')

    args = parser.parse_args()

    settings = dict()

    # 1 - create a Spark session
    spark = get_spark_session(settings)
    logger.info("Pyspark session initiated : {}".format(datetime.datetime.now() - start_time,))

    # -----------------------------------------------------------------------------------------------------------------
    # Edit these to taste (feel free to convert these to runtime arguments)
    # -----------------------------------------------------------------------------------------------------------------

    # software versions (must match the ones in install-geomesa.sh)
    # settings["geomesa_version"] = "2.0.2"

    # environment settings - can't use Mac env vars as Spark env is different
    # settings["user_home"] = os.environ["HOME"]
    settings["home"] = os.path.dirname(os.path.realpath(__file__))
    # settings["geomesa_fs_home"] = "~/geomesa/geomesa-fs_2.11-{}".format(settings["geomesa_version"],)
    # settings["hdfs_path"] = "hdfs://127.0.0.1"

    # name of the GeoMesa schema, aka feature name
    settings["geomesa_schema"] = "speedband"

    # SimpleFeatureType & Converter - can be an existing sft or a config file
    settings["sft_config"] = "file://{}/speedband.conf".format(settings["home"],)
    settings["sft_converter"] = "file://{}/speedband.conf".format(settings["home"],)

    # GeoMesa partition schema to use, note: leaf storage is set to true
    settings["partition_schema"] = "z2-4bit"

    # file format settings
    settings["source_format"] = "csv"
    settings["source_delimiter"] = ";"
    settings["source_header"] = "false"

    # data files
    settings["source_local_directory"] = "file://{}/part-00000-f853dc72-b871-4fa1-9b7b-98940fb0505b-c000.csv".format(settings["home"])
    settings["target_local_directory"] = "file://" + args.target_directory

    # number of reducers for GeoMesa ingest (determines how the reduce tasks get split up)
    settings["num_reducers"] = 16

    # the name of the view created from the input dataframe
    settings["input_view"] = "raw_data"

    # filter data by Australia
    settings["sql"] = """SELECT * FROM {}""".format(settings["input_view"],)

    # -----------------------------------------------------------------------------------------------------------------

    # set HDFS path
    settings["temp_hdfs_path"] = "{}/user/temp/geomesa_ingest".format(settings["hdfs_path"], )

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
                                            --run-mode local \
                                            '{7}/*.csv'""" \
        .format(settings["geomesa_fs_home"], settings["target_local_directory"], settings["geomesa_schema"],
                settings["sft_config"], settings["sft_converter"], settings["partition_schema"],
                settings["num_reducers"], settings["temp_hdfs_path"])

    # logger.info("Geomesa ingest command : {}".format(settings["ingest_command_line"], ))

    # 3 - convert text files on S3 to GeoMesa parquet files on S3
    convert_to_geomesa_parquet(settings, spark)

    # # 4 - create a geomesa dataframe and run a spatial query on it
    # run_geomesa_query(settings, spark)

    spark.stop()


def get_spark_session(settings):
    # create the SparkSession
    spark = SparkSession.builder \
        .master("local") \
        .appName("Geomesa conversion test") \
        .config("spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version", "2") \
        .config("spark.speculation", "false") \
        .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
        .config("spark.kryo.registrator", "org.locationtech.geomesa.spark.GeoMesaSparkKryoRegistrator") \
        .getOrCreate()

    # get environment variables from spark config settings
    spark_config = spark.sparkContext._conf

    # Geomesa Spark environment vars
    settings["geomesa_version"] = spark_config.get("spark.executorEnv.GEOMESA_VERSION")
    settings["geomesa_fs_home"] = spark_config.get("spark.executorEnv.GEOMESA_FS_HOME")
    settings["hdfs_path"] = spark_config.get("spark.executorEnv.HDFS_PATH")

    return spark


def convert_to_geomesa_parquet(settings, spark):
    start_time = datetime.datetime.now()
    logger.info("START")

    get_dataframe_and_view(settings, settings["source_local_directory"], spark)
    filter_and_output_view(settings, spark)
    convert_data_to_geomesa(settings)

    logger.info("DONE : {}".format(datetime.datetime.now() - start_time))


def get_dataframe_and_view(settings, source_file_path, spark):
    start_time = datetime.datetime.now()

    # create input dataframe and a temporary view of it
    input_data_frame = spark \
        .read \
        .load(source_file_path,
              format=settings["source_format"],
              delimiter=settings["source_delimiter"],
              header=settings["source_header"])

    from pyspark.sql import functions as F
    # df3 = df2.withColumn('datetimeGMT', F.from_utc_timestamp(df2.datetimeGMT, "America/New_York"))

    # df2 = input_data_frame.withColumn('datetimeGMT', input_data_frame._c6.cast('timestamp'))

    df2 = input_data_frame.withColumn("_c6", F.regexp_replace("_c6", "T", " "))
    df3 = df2.withColumn("_c6", F.regexp_replace("_c6", "Z", ""))

    df3.show()

    df3.createOrReplaceTempView(settings["input_view"])

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
        .option("fs.path", settings["target_local_directory"]) \
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
