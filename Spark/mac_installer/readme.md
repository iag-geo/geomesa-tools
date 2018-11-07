# GeoMesa Standalone on Mac
A simplified way to get GeoMesa running standalone on your Mac.

Contains install scripts and a Python script for loading, converting & querying [GDELT](https://www.gdeltproject.org/) data in S3 using GeoMesa on Spark.

## The Platform

This guide & code will deploy the following stack on your Mac:

- Hadoop with YARN
- Spark with Pyspark
- GeoMesa FileSystem Datastore
- GeoMesa Spark & PySpark

It's been tested on High Sierra (MacOS v10.13).

## Install Process

### Step 1 - Pre-requisites
On your Mac:
1. Go to [python.org](https://www.python.org/downloads/mac-osx/) and download the **macOS 64-bit installer** for the latest Python 2.7.x version or higher *(2.7.15 or higher is required to avoid the TLS issue with [PyPI](https://pypi.org/))*
1. Install Python to the default directory (`/Library/Frameworks/Python.framework/Versions/2.7`)
1. Enable Remote Login on your Mac: go to **System Preferences > Sharing** and Check the *Remote Login* box. This will enable remoting into Hadoop using SSH.
1. Make a backup copy of your `~./bash_profile` file. Then edit the original version and add your AWS keys to enable access to the GDELT data on S3:

```bash
export AWS_ACCESS_KEY_ID=<yourAccessKeyId>
export AWS_SECRET_ACCESS_KEY=<yourSecretAccessKey>
```

### Step 2 - Install everything

**Note:** The install process will add environment variables to your `~/.bash_profile` file. Hadoop, Spark and GeoMesa all get installed in a new, disposable folder for ease of removal `~/geomesa`

1. Open your preferred command line tool (Terminal, iTerm, emacs, etc...) and go to the directory containing this README
1. Run `. install-geomesa.sh`
1. You may be prompted to override your `id_rsa` SSH key file. Choose 'n' unless you have a reason to replace the key. Your choice won't affect the install script
1. Wait 4-10 mins depending on your Internet connection and check the on-screen log for success

### Step 3 - Do something with GeoMesa
1. Go to the directory containing this README
1. Edit the following command for the path to the `geomesa_convert.py` file
1. Run the command (takes 2-4 mins):

```bash
spark-submit --master local[4] \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar \
--conf spark.executorEnv.GEOMESA_FS_HOME=${GEOMESA_FS_HOME} \
--conf spark.executorEnv.GEOMESA_VERSION=${GEOMESA_VERSION} \
--conf spark.executorEnv.HDFS_PATH=${HDFS_PATH} \
${HOME}/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-directory ${HOME}/tmp/geomesa_test
```

**If all goes well, the script will:**
1. Load GDELT data from S3
1. Filter it to Australia
1. Output it in GeoMesa Parquet format to a local directory *~/tmp/geomesa_test*
1. Run a basic spatial query on the local GeoMesa dataset and show the results on screen to prove Geomesa is working

# Stopping/Starting Hadoop

To stop Hadoop, run these commands:

```bash
cd ${HADOOP_HOME}
sbin/stop-dfs.sh
sbin/stop-yarn.sh
cd ${HOME}
```

To start Hadoop (e.g. after rebooting), run:

```bash
# initialise hadoop file store (HDFS)
cd ${HADOOP_HOME}
bin/hdfs namenode -format

# start hadoop
sbin/start-dfs.sh
sbin/start-yarn.sh
cd ${HOME}
```
