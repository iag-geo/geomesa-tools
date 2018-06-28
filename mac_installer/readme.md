# WORKS IN PROGRESS - DOESN'T YET WORK: GeoMesa Standalone on Mac
A simplified way to get GeoMesa running standalone on your Mac.

ETC...


Contains install scripts and a Python script for loading, converting & querying [GDELT](https://www.gdeltproject.org/) data in S3 using GeoMesa on Spark.

## The Platform

This guide & code will deploy the following stack on your Mac:

- EMRFS using AWS S3
- Hadoop with YARN & Hive
- Spark with Pyspark
- GeoMesa FileSystem Datastore
- GeoMesa Spark & PySpark

## Install Process

### Step 1 - Pre-requisites
On your Mac:
1. Go to [python.org](https://www.python.org/downloads/release/python-2715/) and download the **macOS 64-bit installer** for Python 2.7.15 *(2.7.15 is required to avoid TLS issue with [PyPI](https://pypi.org/))*
1. Install Python to the default directory (`/Library/Frameworks/Python.framework/Versions/2.7`)

### Step 2 - Install everything
1. Open your preferred command line tool (Terminal, iTerm, emacs, etc...)
1. Run `. ~/install-geomesa.sh`
1. Wait 3-4 mins and check the on-screen log for success

### Step 3 - Do something with GeoMesa

1. Edit this command to add the S3 bucket you want to output the GeoMesa data to: `spark-submit --jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar geomesa_convert.py --target-s3-bucket <your_output_s3_bucket_name>`
1. Run the command!

**If all goes well, the script will:**
1. Load GDELT data from S3
1. Filter it to Australia
1. Output it in GeoMesa Parquet format to S3
1. Run a spatial query on the GeoMesa S3 dataset and show the results on screen
