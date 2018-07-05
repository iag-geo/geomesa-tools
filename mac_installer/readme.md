# GeoMesa Standalone on Mac
A simplified way to get GeoMesa running standalone on your Mac.

Contains install scripts and a Python script for loading, converting & querying [GDELT](https://www.gdeltproject.org/) data in S3 using GeoMesa on Spark.

## The Platform

This guide & code will deploy the following stack on your Mac:

- Hadoop with YARN
- Spark with Pyspark
- GeoMesa FileSystem Datastore
- GeoMesa Spark & PySpark

## Install Process

### Step 1 - Pre-requisites
On your Mac:
1. Go to [python.org](https://www.python.org/downloads/release/python-2715/) and download the **macOS 64-bit installer** for the latest Python 2.7.x version or higher *(2.7.15 or higher is required to avoid the TLS issue with [PyPI](https://pypi.org/))*
1. Install Python to the default directory (`/Library/Frameworks/Python.framework/Versions/2.7`)
1. Enable Remote Login on your Mac: go to **System Preferences > Sharing** and Check the *Remote Login* box. This will enable remoting into Hadoop using SSH.
1. Make a backup copy of your `~./bash_profile` file. Edit the original version and add your AWS keys to enable access to the GDELT data on S3:

```bash
export AWS_ACCESS_KEY_ID=<yourAccessKeyId>
export AWS_SECRET_ACCESS_KEY=<yourSecretAccessKey>
```

### Step 2 - Install everything
1. Open your preferred command line tool (Terminal, iTerm, emacs, etc...) and go to the directory containing this file
1. Run `. install-geomesa.sh`
1. You may be prompted to override your `id_rsa` SSH key file. Choose 'n' unless you have a reason to replace the key. Your choice won't affect the install script
1. Wait 6-10 mins depending on your Internet connection and check the on-screen log for success

### Step 3 - Do something with GeoMesa
1. Go to the directory containing this file
2. Run this command:

```bash
spark-submit --master local[4] \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar \
geomesa_convert.py --target-directory ~/tmp/geomesa_test
```

**If all goes well, the script will:**
1. Load GDELT data from S3
1. Filter it to Australia
1. Output it in GeoMesa Parquet format to a local directory *~/tmp/geomesa_test*
1. Run a basic spatial query on the local GeoMesa dataset and show the results on screen to prove Geomesa is working
