import argparse
import datetime
import os
import logging

from pyspark.sql import SparkSession
from subprocess import check_output


def main():
    fred = os.environ["HOME"]
    logger.info(fred)

    spark = SparkSession.builder \
        .master("local") \
        .appName("Geomesa conversion test") \
        .config("spark.jars", "file:///Users/s57405/geomesa/geomesa-fs_2.11-2.0.2/dist/spark/geomesa-fs-spark-runtime_2.11-2.0.2.jar") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version", "2") \
        .config("spark.speculation", "false") \
        .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
        .config("spark.kryo.registrator", "org.locationtech.geomesa.spark.GeoMesaSparkKryoRegistrator") \
        .getOrCreate()

    jim = spark.sparkContext._conf.get("spark.executorEnv.GEOMESA_VERSION")
    # jim = spark.sparkContext._conf.getAll()
    # jim = os.environ["GEOMESA_VERSION"]
    logger.info(jim)


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
